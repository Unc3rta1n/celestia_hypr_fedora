"""CMF battery framing tests; no Bluetooth hardware required."""
import importlib.util
import struct
import unittest
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "cmf_battery", Path(__file__).resolve().parents[1] / "hypr-lua/scripts/cmf-battery.py",
)
cmf = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(cmf)


def frame(payload: bytes, command: int = 0x4007, control: int = 0x0160) -> bytes:
    return struct.pack("<BHHHB", 0x55, control, command, len(payload), 0) + payload + b"\0\0"


class BatteryTests(unittest.TestCase):
    def test_real_device_left_only_does_not_invent_other_levels(self) -> None:
        self.assertEqual(cmf.parse_battery(bytes.fromhex("010264")),
                         {"left": 100, "right": None, "case": None})

    def test_three_levels_and_charging_bit(self) -> None:
        self.assertEqual(cmf.parse_battery(bytes([3, 2, 0x80 | 90, 3, 50, 4, 25])),
                         {"left": 90, "right": 50, "case": 25})

    def test_unknown_sentinel_and_real_zero(self) -> None:
        self.assertEqual(cmf.parse_battery(bytes([3, 2, 0, 3, 127, 4, 255])),
                         {"left": 0, "right": None, "case": None})

    def test_invalid_pair_count(self) -> None:
        for payload in (b"", b"\x02\x02\x64", b"\x01\x02"):
            with self.subTest(payload=payload), self.assertRaises(ValueError):
                cmf.parse_battery(payload)

    def test_fragmented_and_coalesced_packets(self) -> None:
        data = frame(b"\x01\x02\x64")
        buffer = bytearray(frame(b"", command=0x401E) + data[:9])
        self.assertIsNone(cmf.take_response(buffer))
        buffer.extend(data[9:])
        self.assertEqual(cmf.take_response(buffer)["left"], 100)
        self.assertEqual(buffer, b"")

    def test_rejected_and_oversized_packets(self) -> None:
        for data in (frame(b"\x01\x02\x64", control=0x0161),
                     struct.pack("<BHHHB", 0x55, 0x0160, 0x4007, 513, 0)):
            with self.subTest(data=data), self.assertRaises(ValueError):
                cmf.take_response(bytearray(data))

    def test_case_notification_captured_from_real_device(self) -> None:
        packet = bytearray(frame(bytes.fromhex("0302640364040a"), command=0xE001))
        self.assertEqual(cmf.take_response(packet), {"left": 100, "right": 100, "case": 10})

    def test_response_and_notification_in_same_read(self) -> None:
        packet = bytearray(frame(bytes.fromhex("0202640364"))
                           + frame(bytes.fromhex("0302640364040a"), command=0xE001))
        self.assertEqual(cmf.take_response(packet)["case"], 10)
        self.assertEqual(packet, b"")

    def test_fragmented_notification_after_initial_response(self) -> None:
        update = frame(bytes.fromhex("0302640364040a"), command=0xE001)
        packet = bytearray(frame(bytes.fromhex("0202640364")) + update[:9])
        self.assertIsNone(cmf.take_response(packet)["case"])
        packet.extend(update[9:])
        self.assertEqual(cmf.take_response(packet)["case"], 10)

    def test_case_missing_from_next_snapshot_does_not_remain_current(self) -> None:
        packet = bytearray(frame(bytes.fromhex("0302640364040a"), command=0xE001)
                           + frame(bytes.fromhex("0202640364"), command=0xE001))
        self.assertIsNone(cmf.take_response(packet)["case"])
        self.assertEqual(packet, b"")

    def test_request_matches_protocol(self) -> None:
        self.assertEqual(cmf.battery_request().hex(), "55600107c00000006d1f")


if __name__ == "__main__":
    unittest.main()
