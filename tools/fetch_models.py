"""Poly Haven'dan (CC0) 3D modelleri ve HDRI'ları indirir.

- assets/models/catalog.json : tüm modellerin listesi (id, ad, kategori, etiket) — seçim yapmak için
- assets/models.txt          : indirilecek model kimlikleri -> assets/models/<id>/<id>.gltf (+ dokular, .bin)
- assets/hdris.txt           : indirilecek HDRI kimlikleri -> assets/hdri/<id>.hdr
Bulunamayan kimlikler atlanır.
"""
import json
import os
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HEADERS = {"User-Agent": "tasoTidyUp-github-actions (github.com/bogacavdar/tasoTidyUp)"}
RES = "1k"


def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=120).read()


def ids_from(name):
    path = os.path.join(ROOT, "assets", name)
    if not os.path.exists(path):
        return []
    return [l.split("#")[0].strip() for l in open(path, encoding="utf-8") if l.split("#")[0].strip()]


def catalog():
    out = os.path.join(ROOT, "assets", "models", "catalog.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    data = json.loads(get("https://api.polyhaven.com/assets?t=models"))
    slim = {}
    for k, v in data.items():
        slim[k] = {"name": v.get("name"), "cat": v.get("categories"), "tags": v.get("tags"),
                   "dim": v.get("dimensions"), "poly": v.get("polycount")}
    with open(out, "w", encoding="utf-8") as f:
        json.dump(slim, f, ensure_ascii=False, indent=0, sort_keys=True)
    print("katalog:", len(slim), "model")
    hd = json.loads(get("https://api.polyhaven.com/assets?t=hdris"))
    with open(os.path.join(ROOT, "assets", "models", "hdri_catalog.json"), "w", encoding="utf-8") as f:
        json.dump({k: {"name": v.get("name"), "cat": v.get("categories"), "tags": v.get("tags")} for k, v in hd.items()},
                  f, ensure_ascii=False, indent=0, sort_keys=True)


def model(mid):
    try:
        files = json.loads(get(f"https://api.polyhaven.com/files/{mid}"))
        g = files["gltf"][RES]["gltf"]
    except Exception as e:
        print(f"ATLA {mid}: {e}")
        return
    d = os.path.join(ROOT, "assets", "models", mid)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, f"{mid}.gltf"), "wb") as f:
        f.write(get(g["url"]))
    for rel, inc in (g.get("include") or {}).items():
        p = os.path.join(d, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "wb") as f:
            f.write(get(inc["url"]))
    print("OK model", mid)


def hdri(hid):
    try:
        files = json.loads(get(f"https://api.polyhaven.com/files/{hid}"))
        url = files["hdri"][RES]["hdr"]["url"]
    except Exception as e:
        print(f"ATLA {hid}: {e}")
        return
    d = os.path.join(ROOT, "assets", "hdri")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, f"{hid}.hdr"), "wb") as f:
        f.write(get(url))
    print("OK hdri", hid)


def main():
    catalog()
    for m in ids_from("models.txt"):
        model(m)
    for h in ids_from("hdris.txt"):
        hdri(h)


if __name__ == "__main__":
    main()
