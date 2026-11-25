"""Her set için 150 çizimi tek sayfada gösterir: tools/comfy/out/sheets/set_XX.jpg
Sayfada her görselin altında numarası yazar; kötüleri not alıp run_comfy.py --redo ile yeniden üretirsin.
Kullanım: python contact_sheet.py            (hepsi)   |   python contact_sheet.py 0 3   (yalnızca 0 ve 3. setler)
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
COLS, CELL = 15, 200


def font(sz):
    for p in ["C:/Windows/Fonts/arialbd.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def sheet(g, names):
    rows = 10
    im = Image.new("RGB", (COLS * CELL, rows * (CELL + 28) + 60), (28, 24, 22))
    d = ImageDraw.Draw(im)
    d.text((16, 14), f"Set {g:02d}  {names.get(g, '')}  —  sıra: 1-2-3 aynı türün evrimleri", fill=(255, 220, 140), font=font(30))
    have = 0
    for n in range(1, 151):
        x = ((n - 1) % COLS) * CELL
        y = 60 + ((n - 1) // COLS) * (CELL + 28)
        p = os.path.join(OUT, "set_%02d" % g, "%03d.png" % n)
        if os.path.exists(p):
            have += 1
            im.paste(Image.open(p).convert("RGB").resize((CELL - 8, CELL - 8)), (x + 4, y + 4))
        else:
            d.rectangle((x + 4, y + 4, x + CELL - 4, y + CELL - 4), outline=(90, 80, 70), width=2)
        d.text((x + CELL // 2, y + CELL + 12), str(n), fill=(240, 240, 240), anchor="mm", font=font(20))
    os.makedirs(os.path.join(OUT, "sheets"), exist_ok=True)
    dest = os.path.join(OUT, "sheets", "set_%02d.jpg" % g)
    im.save(dest, quality=85)
    print(dest, f"{have}/150")


def main():
    names = {}
    pj = os.path.join(HERE, "prompts.json")
    if os.path.exists(pj):
        for e in json.load(open(pj, encoding="utf-8")):
            names[e["set"]] = e["set_name"]
    sets = [int(x) for x in sys.argv[1:]] or [g for g in range(34) if os.path.isdir(os.path.join(OUT, "set_%02d" % g))]
    for g in sets:
        sheet(g, names)


if __name__ == "__main__":
    main()
