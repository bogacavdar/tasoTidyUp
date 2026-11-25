"""Üretilen çizimleri oyunun atlaslarına yerleştirir: assets/art/set_XX.jpg (13 x 12 hücre, numara = hücre + 1)
Eksik numaralar için eski atlastaki çizim korunur; yani yarım kalmış bir üretimi de aktarabilirsin.
Kullanım: python build_atlas.py   (sonra değişiklikleri GitHub'a gönder)
"""
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(HERE, "out")
ART = os.path.join(ROOT, "assets", "art")
COLS, ROWS, CELL = 13, 12, 192


def main():
    sets = [int(x) for x in sys.argv[1:]] or range(34)
    for g in sets:
        src = os.path.join(OUT, "set_%02d" % g)
        if not os.path.isdir(src):
            continue
        dest = os.path.join(ART, "set_%02d.jpg" % g)
        atlas = Image.new("RGB", (COLS * CELL, ROWS * CELL), (235, 230, 220))
        old = None
        if os.path.exists(dest):
            old = Image.open(dest).convert("RGB")
            oc = old.width // COLS
        n_new = 0
        for n in range(1, 151):
            c = n - 1
            box = ((c % COLS) * CELL, (c // COLS) * CELL)
            p = os.path.join(src, "%03d.png" % n)
            if os.path.exists(p):
                atlas.paste(Image.open(p).convert("RGB").resize((CELL, CELL), Image.LANCZOS), box)
                n_new += 1
            elif old is not None:
                cell = old.crop(((c % COLS) * oc, (c // COLS) * oc, (c % COLS + 1) * oc, (c // COLS + 1) * oc))
                atlas.paste(cell.resize((CELL, CELL), Image.LANCZOS), box)
        atlas.save(dest, quality=88)
        print(f"set {g:02d}: {n_new}/150 yeni çizim -> {dest}")


if __name__ == "__main__":
    main()
