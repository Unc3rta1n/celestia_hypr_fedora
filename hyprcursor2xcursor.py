#!/usr/bin/env python3
"""Rebuild an XCursor theme (cursors/ + index.theme) from a hyprcursor theme (hyprcursors/*.hlc).

Apps that don't speak cursor-shape-v1 (XWayland, Electron, some GTK/Qt widgets) fall back to
XCursor and showed the default GTK cursor because the theme only had hyprcursors.

usage: hyprcursor2xcursor.py ~/.icons/gruvbox-light
"""
import io
import re
import struct
import sys
import zipfile
from pathlib import Path

from PIL import Image

XCURSOR_IMAGE = 0xFFFD0002


def parse_meta(text: str):
    hot_x = float(re.search(r"hotspot_x\s*=\s*([\d.]+)", text).group(1))
    hot_y = float(re.search(r"hotspot_y\s*=\s*([\d.]+)", text).group(1))
    sizes = [
        (int(m.group(1)), m.group(2).strip(), int(m.group(3) or 0))
        for m in re.finditer(r"define_size\s*=\s*(\d+)\s*,\s*([^,\n]+?)\s*(?:,\s*(\d+))?\s*$", text, re.M)
    ]
    overrides = [m.group(1).strip() for m in re.finditer(r"define_override\s*=\s*(\S+)", text)]
    return hot_x, hot_y, sizes, overrides


def premultiplied_argb(img: Image.Image) -> bytes:
    rgba = img.convert("RGBA").tobytes()
    out = bytearray(len(rgba))
    for i in range(0, len(rgba), 4):
        r, g, b, a = rgba[i : i + 4]
        # XCursor pixels: premultiplied ARGB, little-endian -> B G R A in memory
        out[i : i + 4] = bytes((b * a // 255, g * a // 255, r * a // 255, a))
    return bytes(out)


def build_xcursor(frames) -> bytes:
    """frames: list of (nominal_size, PIL image, xhot, yhot, delay_ms)"""
    header_len, toc_len, chunk_header = 16, 12, 36
    pos = header_len + toc_len * len(frames)
    toc, chunks = b"", b""
    for size, img, xh, yh, delay in frames:
        w, h = img.size
        chunk = struct.pack("<9I", chunk_header, XCURSOR_IMAGE, size, 1, w, h, xh, yh, delay) + premultiplied_argb(img)
        toc += struct.pack("<3I", XCURSOR_IMAGE, size, pos)
        pos += len(chunk)
        chunks += chunk
    return b"Xcur" + struct.pack("<3I", header_len, 0x10000, len(frames)) + toc + chunks


def main(theme_dir: Path) -> None:
    src, dst = theme_dir / "hyprcursors", theme_dir / "cursors"
    dst.mkdir(exist_ok=True)
    made = links = 0
    for hlc in sorted(src.glob("*.hlc")):
        name = hlc.stem
        with zipfile.ZipFile(hlc) as z:
            hot_x, hot_y, sizes, overrides = parse_meta(z.read("meta.hl").decode())
            frames = []
            for size, png, delay in sizes:
                img = Image.open(io.BytesIO(z.read(png)))
                w, h = img.size
                frames.append((size, img, round(hot_x * (w - 1)), round(hot_y * (h - 1)), delay))
        (dst / name).write_bytes(build_xcursor(frames))
        made += 1
        for alias in overrides:
            link = dst / alias
            if alias != name and not link.exists():
                link.symlink_to(name)
                links += 1
    index = theme_dir / "index.theme"
    if not index.exists():
        index.write_text(f"[Icon Theme]\nName={theme_dir.name}\nComment=XCursor rebuilt from hyprcursor\n")
    print(f"{theme_dir.name}: {made} cursors, {links} aliases -> {dst}")


if __name__ == "__main__":
    main(Path(sys.argv[1]).expanduser())
