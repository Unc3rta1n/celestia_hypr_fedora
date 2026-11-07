#!/usr/bin/python3
"""Read-only CMF Buds Pro 2 battery query over Nothing's RFCOMM protocol.

Protocol reference: https://github.com/JScoder4005/cmf-control (MIT).
Only GET_BATTERY (0xC007) is sent; no audio or device settings are changed.
"""

import argparse
import json
import logging
import os
import re
import socket
import struct
import sys
from collections.abc import Callable

UUID = "aeac4a03-dff5-498f-843a-34487cf133eb"
PROFILE_PATH = "/org/caelestia/cmf_battery"
BATTERY_COMMAND = 0xC007
BATTERY_NOTIFICATION = 0xE001
POLL_SECONDS = 30
MAX_PAYLOAD = 512


def battery_request() -> bytes:
    """Encode the empty battery request with Nothing's CRC-16 variant."""
    body = struct.pack("<BHHHB", 0x55, 0x0160, BATTERY_COMMAND, 0, 0)
    crc = 0xFFFF
    for byte in body:
        crc ^= byte
        for _ in range(8):
            crc = (crc >> 1) ^ (0xA001 if crc & 1 else 0)
    return body + struct.pack("<H", crc)


def parse_battery(payload: bytes) -> dict:
    """Decode counted key/value pairs; absent/invalid levels stay unknown."""
    if not payload or len(payload) != 1 + payload[0] * 2:
        raise ValueError("Invalid battery pair count")
    result = dict.fromkeys(("left", "right", "case"))
    names = {2: "left", 3: "right", 4: "case"}
    for key, value in zip(payload[1::2], payload[2::2], strict=True):
        if key in names:
            level = value & 0x7F
            result[names[key]] = level if level <= 100 else None
    if all(value is None for value in result.values()):
        raise ValueError("No valid battery levels")
    return result


def take_response(buffer: bytearray) -> dict | None:
    """Handle fragmented/coalesced frames with bounded lengths.

    Device response CRC variant is undocumented, as in the protocol reference.
    Framing, response status, command, sequence, lengths and levels are checked.
    """
    latest = None
    while len(buffer) >= 8:
        if buffer[0] != 0x55:
            raise ValueError("Invalid frame marker")
        control, command, length, sequence = struct.unpack_from("<HHHB", buffer, 1)
        if length > MAX_PAYLOAD:
            raise ValueError("Oversized frame")
        size = 8 + length + (2 if control & 0x20 else 0)
        if len(buffer) < size:
            return latest
        payload = bytes(buffer[8:8 + length])
        del buffer[:size]
        if command == BATTERY_NOTIFICATION or (command == (BATTERY_COMMAND & 0x7FFF) and sequence == 0):
            if control & 0x1F:
                raise ValueError("Battery request rejected")
            latest = parse_battery(payload)
    return latest


def query(address: str, on_update: Callable[[dict], None] | None = None) -> dict:
    """Query once, or watch snapshots/notifications until disconnected."""
    import dbus
    import dbus.service
    from dbus.mainloop.glib import DBusGMainLoop
    from gi.repository import GLib

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus(private=True)
    loop = GLib.MainLoop()
    connection = None
    result = {}
    failure = []
    buffer = bytearray()
    sources = []

    def fail(error: object) -> bool:
        failure.append(str(error))
        loop.quit()
        return False

    def readable(_fd: int, _condition: int) -> bool:
        try:
            chunk = connection.recv(1024)
            if not chunk:
                raise ConnectionError("CMF closed the connection")
            buffer.extend(chunk)
            battery = take_response(buffer)
            if battery is not None:
                result.clear()
                result.update(battery)
                if on_update is None:
                    loop.quit()
                    return False
                if GLib.MainContext.default().find_source_by_id(timeout):
                    GLib.source_remove(timeout)
                on_update(result)
        except (OSError, ValueError) as error:
            return fail(error)
        return True

    def poll() -> bool:
        nonlocal timeout
        try:
            connection.sendall(battery_request())
            if GLib.MainContext.default().find_source_by_id(timeout):
                GLib.source_remove(timeout)
            timeout = GLib.timeout_add_seconds(8, lambda: fail("CMF battery response timed out"))
        except OSError as error:
            return fail(error)
        return True

    class Profile(dbus.service.Object):
        @dbus.service.method("org.bluez.Profile1", in_signature="oha{sv}", out_signature="")
        def NewConnection(self, device: str, fd: object, _properties: dict) -> None:
            nonlocal connection
            received = fd.take()
            if str(device) != device_path or connection is not None:
                os.close(received)
                fail("Unexpected CMF connection")
                return
            connection = socket.socket(fileno=received)
            connection.settimeout(2)
            try:
                connection.sendall(battery_request())
                sources.append(GLib.io_add_watch(
                    connection.fileno(), GLib.IO_IN | GLib.IO_HUP | GLib.IO_ERR, readable,
                ))
                if on_update is not None:
                    sources.append(GLib.timeout_add_seconds(POLL_SECONDS, poll))
            except OSError as error:
                fail(error)

        @dbus.service.method("org.bluez.Profile1", in_signature="o", out_signature="")
        def RequestDisconnection(self, _device: str) -> None:
            fail("CMF disconnected")

        @dbus.service.method("org.bluez.Profile1", in_signature="", out_signature="")
        def Release(self) -> None:
            fail("CMF profile released")

    objects = dbus.Interface(bus.get_object("org.bluez", "/"), "org.freedesktop.DBus.ObjectManager")
    device_path = next((str(path) for path, interfaces in objects.GetManagedObjects().items()
                        if str(interfaces.get("org.bluez.Device1", {}).get("Address", "")).upper() == address), None)
    if device_path is None:
        bus.close()
        raise ConnectionError("CMF device not found")
    profile = Profile(bus, PROFILE_PATH)
    manager = dbus.Interface(bus.get_object("org.bluez", "/org/bluez"), "org.bluez.ProfileManager1")
    registered = False
    timeout = GLib.timeout_add_seconds(8, lambda: fail("CMF battery query timed out"))
    try:
        manager.RegisterProfile(PROFILE_PATH, UUID, {"Name": "Caelestia CMF battery", "Role": "client"})
        registered = True
        device = dbus.Interface(bus.get_object("org.bluez", device_path), "org.bluez.Device1")
        device.ConnectProfile(UUID, reply_handler=lambda: None, error_handler=fail)
        loop.run()
        if failure:
            raise ConnectionError(failure[0])
        return result
    finally:
        # Callbacks may have removed their own sources already.
        for source in [timeout, *sources]:
            if GLib.MainContext.default().find_source_by_id(source):
                GLib.source_remove(source)
        if connection is not None:
            connection.close()
        if registered:
            try:
                manager.UnregisterProfile(PROFILE_PATH)
            except dbus.DBusException as error:
                logging.warning("CMF profile cleanup: %s", error)
        profile.remove_from_connection()
        bus.close()


def emit_result(result: dict) -> None:
    sys.stdout.write(json.dumps(result) + "\n")
    sys.stdout.flush()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--watch", action="store_true", help="Stream battery snapshots and notifications")
    parser.add_argument("address")
    args = parser.parse_args()
    if not re.fullmatch(r"(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}", args.address):
        parser.error("Expected a Bluetooth MAC address")
    try:
        result = query(args.address.upper(), emit_result if args.watch else None)
    except Exception as error:
        # D-Bus exceptions do not share a stdlib base beyond Exception.
        logging.error("CMF battery: %s", error)
        emit_result({})
        return 1
    if not args.watch:
        emit_result(result)
    return 0


if __name__ == "__main__":
    sys.exit(main())
