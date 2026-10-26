"""Screen OCR for the caelestia area picker: RapidOCR (PaddleOCR models), Russian + English.

Prints the recognised text. Run through ./screen-ocr (the venv lives in ~/.local/share/screen-ocr,
created by install-caelestia.sh).

Tesseract is trained on scans: on small light-on-dark screen text it read "https://www" as
"nttp:/Avww". Here the East Slavic model finds and reads every box; boxes with no Cyrillic-only
letters are re-read in one batch by the Latin model (it gets URLs right where the Cyrillic one
fumbles). Look-alike letters inside a word are folded into the word's script ("ForРost" ->
"ForPost") and boxes on the same row are joined, so table rows stay rows.
"""

import sys

import cv2
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


def fold_word(word: str) -> str:
    cyr = sum(ch in CYR for ch in word)
    lat = sum(is_lat(ch) for ch in word)
    if not cyr or not lat:
        return word
    acyr, alat = anchors(word)
    to_cyr = acyr > alat if acyr != alat else cyr > lat
    table = TO_CYR if to_cyr else TO_LAT
    return "".join(table.get(ch, ch) for ch in word)


def mostly_latin(text: str) -> bool:
    acyr, alat = anchors(text)
    return acyr == 0 and alat > 0


def recognise(path: str) -> list[list]:
    """[x0, y0, y1, text] per text box."""
    res = RapidOCR(params=ESLAV)(path)
    if res.boxes is None:
        return []

    img = cv2.imread(path)
    boxes, latin_idx, crops = [], [], []
    for box, text in zip(res.boxes, res.txts, strict=True):
        xs, ys = [p[0] for p in box], [p[1] for p in box]
        x0, y0, x1, y1 = min(xs), min(ys), max(xs), max(ys)
        if mostly_latin(text):
            latin_idx.append(len(boxes))
            crops.append(img[max(int(y0) - 2, 0) : int(y1) + 2, max(int(x0) - 2, 0) : int(x1) + 2])
        boxes.append([x0, y0, y1, text])

    if crops:
        rec = RapidOCR(params=COMMON)._load_rec_model()
        for k, text in zip(latin_idx, rec(TextRecInput(img=crops)).txts, strict=True):
            if text:
                boxes[k][3] = text

    for b in boxes:
        b[3] = " ".join(fold_word(w) for w in b[3].split(" "))
    return boxes


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
