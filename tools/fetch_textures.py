"""Poly Haven'dan (CC0) dokuları indirir: assets/textures.txt -> assets/tex/<id>_{diff,nor,rough}.jpg"""
import json
import os
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIST = os.path.join(ROOT, "assets", "textures.txt")
OUT = os.path.join(ROOT, "assets", "tex")
HEADERS = {"User-Agent": "tasoTidyUp-github-actions (github.com/bogacavdar/tasoTidyUp)"}
WANT = {"diff": ["Diffuse", "diffuse", "diff"], "nor": ["nor_gl", "Normal"], "rough": ["Rough", "rough", "roughness"]}


def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=60).read()


def main():
    os.makedirs(OUT, exist_ok=True)
    ids = [l.strip() for l in open(LIST, encoding="utf-8") if l.strip() and not l.startswith("#")]
    for asset in ids:
        try:
            files = json.loads(get(f"https://api.polyhaven.com/files/{asset}"))
        except Exception as e:  # bulunamadı ya da ağ hatası
            print(f"ATLA {asset}: {e}")
            continue
        for short, keys in WANT.items():
            for k in keys:
                try:
                    url = files[k]["1k"]["jpg"]["url"]
                except (KeyError, TypeError):
                    continue
                path = os.path.join(OUT, f"{asset}_{short}.jpg")
                with open(path, "wb") as f:
                    f.write(get(url))
                print(f"OK {asset} {short}")
                break


if __name__ == "__main__":
    main()
