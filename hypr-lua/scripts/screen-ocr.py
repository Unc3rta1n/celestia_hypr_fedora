"""Screen OCR for the caelestia area picker: RapidOCR (PaddleOCR models), Russian + English.

Prints the recognised text. Run through ./screen-ocr (the venv lives in ~/.local/share/screen-ocr,
created by install-caelestia.sh).

Tesseract is trained on scans: on small light-on-dark screen text it read "https://www" as
"nttp:/Avww". Here the East Slavic model finds and reads every box. One batched pass of the Latin
model then re-reads boxes with no Cyrillic-only letters (it gets URLs right where the Cyrillic one
fumbles) and, inside Russian text, the words that are Latin misread as Cyrillic: mixed-script words
("Fедога") and words with "і", which Russian doesn't use ("таіп" for "main"). Plain Russian words
are left alone: the Latin model reads "от" as "OT" just as confidently. Look-alike letters are
folded into each word's script ("ForРost" -> "ForPost", "піх" -> "nix") and boxes on the same row
are joined, so table rows stay rows.
"""

import re
import sys

import cv2
import numpy as np
from rapidocr import LangRec, ModelType, OCRVersion, RapidOCR
from rapidocr.ch_ppocr_rec import TextRecInput

# 4 threads are faster than all 12; no angle classifier (screen text is upright). Detector left at
# its defaults: it upscales small shots, and capping that or using a lighter detector drops small
# characters ("ww.youtube", single digits in table cells).
COMMON = {
    "Global.log_level": "error",
    "Global.use_cls": False,
    "EngineConfig.onnxruntime.intra_op_num_threads": 4,
}
ESLAV = {
    **COMMON,
    "Rec.lang_type": LangRec.ESLAV,
    "Rec.ocr_version": OCRVersion.PPOCRV5,
    "Rec.model_type": ModelType.MOBILE,
}

CYR = set("абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯіїєґІЇЄҐ")
# Cyrillic <-> Latin look-alikes, incl. the model's usual mix-ups (г/r, п/n, и/u)
PAIRS = "АA ВB ЕE КK МM НH ОO РP СC ТT ХX аa еe оo рp сc уy хx іi гr пn иu"
TO_LAT = dict(PAIRS.split())
TO_CYR = {lat: cyr for cyr, lat in PAIRS.split()}


def is_lat(ch: str) -> bool:
    return ch.isascii() and ch.isalpha()


def anchors(text: str) -> tuple[int, int]:
    """Letters that have no look-alike in the other script: (Cyrillic, Latin)."""
    return (
        sum(ch in CYR and ch not in TO_LAT for ch in text),
        sum(is_lat(ch) and ch not in TO_CYR for ch in text),
    )


def fold_part(part: str) -> str:
    cyr = sum(ch in CYR for ch in part)
    lat = sum(is_lat(ch) for ch in part)
    if not lat:
        # "піх": only look-alikes and an "і", which Russian doesn't have -> Latin read as Cyrillic
        if "і" in part.lower() and all(ch in TO_LAT for ch in part):
            return "".join(TO_LAT[ch] for ch in part)
        return part
    if not cyr:
        return part
    acyr, alat = anchors(part)
    to_cyr = acyr > alat if acyr != alat else cyr > lat
    table = TO_CYR if to_cyr else TO_LAT
    return "".join(table.get(ch, ch) for ch in part)


def fold_word(word: str) -> str:
    # per letter run, so "піх-флейка" folds "піх" and "флейка" separately
    return "".join(fold_part(p) for p in re.split(r"([\W\d_]+)", word))


def suspicious(word: str) -> bool:
    """A Latin word misread by the Cyrillic model: mixed scripts or an "і"."""
    return "і" in word.lower() or (any(ch in CYR for ch in word) and any(is_lat(ch) for ch in word))


def mostly_latin(text: str) -> bool:
    acyr, alat = anchors(text)
    return acyr == 0 and alat > 0


def better_latin(word: str, text: str, score: float) -> bool:
    """The Latin re-read of a suspicious word: plain ASCII, confident, about as long, same case.

    The case check rejects Russian words that were merely misread with a Latin letter: "oт" (Latin o)
    comes back as "OT", while a real Latin word keeps its case ("Fедога" -> "Fedora"). Lengths may
    differ by one (the Cyrillic model read "Operline" as "Орегіпе"); then only the first letter counts.
    """
    if not (text.isascii() and any(ch.isalpha() for ch in text) and score >= 0.9):
        return False
    if len(text) == len(word):
        pairs = zip(word, text, strict=True)
    elif abs(len(text) - len(word)) == 1:
        pairs = zip([c for c in word if c.isalpha()][:1], [c for c in text if c.isalpha()][:1], strict=False)
    else:
        return False
    return all(a.isupper() == b.isupper() for a, b in pairs if a.isalpha() and b.isalpha())


def bounds(box: list) -> tuple[float, float, float, float]:
    xs, ys = [p[0] for p in box], [p[1] for p in box]
    return min(xs), min(ys), max(xs), max(ys)


def crop(img: np.ndarray, box: list) -> np.ndarray:
    x0, y0, x1, y1 = bounds(box)
    return img[max(int(y0) - 2, 0) : int(y1) + 2, max(int(x0) - 2, 0) : int(x1) + 2]


def recognise(path: str) -> list[list]:
    """[x0, y0, y1, text] per text box."""
    res = RapidOCR(params=ESLAV)(path, return_word_box=True)
    if res.boxes is None:
        return []

    img = cv2.imread(path)
    # One batched Latin pass: whole boxes without Cyrillic-only letters + suspicious words of the rest
    lines, jobs, crops = [], [], []
    for i, (box, text, words) in enumerate(zip(res.boxes, res.txts, res.word_results, strict=True)):
        x0, y0, _, y1 = bounds(box)
        if mostly_latin(text) or not words:
            jobs.append((i, None))
            crops.append(crop(img, box))
            lines.append([x0, y0, y1, [text]])
            continue
        for j, (word, _, wbox) in enumerate(words):
            if suspicious(word):
                jobs.append((i, j))
                crops.append(crop(img, wbox))
        lines.append([x0, y0, y1, [w for w, *_ in words]])

    if crops:
        rec = RapidOCR(params=COMMON)._load_rec_model()
        out = rec(TextRecInput(img=crops))
        for (i, j), text, lscore in zip(jobs, out.txts, out.scores, strict=True):
            if j is None:
                if text:
                    lines[i][3] = [text]
            elif better_latin(lines[i][3][j], text, lscore):
                lines[i][3][j] = text

    return [[x0, y0, y1, " ".join(fold_word(w) for w in " ".join(ws).split(" "))] for x0, y0, y1, ws in lines]


def join_rows(boxes: list[list]) -> str:
    # a box joins the current row when it overlaps it vertically by half its height
    rows = []
    for b in sorted(boxes, key=lambda b: (b[1], b[0])):
        _, y0, y1, _ = b
        if rows and min(y1, rows[-1][1]) - max(y0, rows[-1][0]) > (y1 - y0) / 2:
            rows[-1][1] = max(rows[-1][1], y1)
            rows[-1][2].append(b)
        else:
            rows.append([y0, y1, [b]])
    return "\n".join(" ".join(t for *_, t in sorted(r[2])) for r in rows)


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("usage: screen-ocr IMAGE")
    sys.stdout.write(join_rows(recognise(sys.argv[1])) + "\n")


if __name__ == "__main__":
    main()
