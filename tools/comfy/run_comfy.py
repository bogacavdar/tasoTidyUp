"""prompts.json'daki istemleri yerel ComfyUI'ye gönderip taso çizimlerini üretir.

Çıktı: tools/comfy/out/set_XX/NNN.png (NNN = taso numarası, 001-150)
- Kaldığı yerden devam eder: var olan dosyalar atlanır. İstediğin an Ctrl+C ile durdurabilirsin.
- Evrim tutarlılığı: 1. evrim sıfırdan üretilir; 2. evrim 1.'den, 3. evrim 2.'den türetilir (img2img).

Örnekler:
  python run_comfy.py --test                  # 0. setten 7 tür (21 görsel) üret, süreyi ölç
  python run_comfy.py                         # hepsini üret (5100)
  python run_comfy.py --sets 0,1,2            # yalnızca bu setler
  python run_comfy.py --redo 3:5,17,22        # 3. setin 5, 17, 22 numaralarını yeniden üret (yeni tohumla)

Varsayılan model düzeni (Flux dev GGUF, 8 GB ekran kartı + 16 GB RAM için):
  ComfyUI/models/unet/flux1-dev-Q5_K_S.gguf      (ComfyUI-GGUF eklentisi gerekir)
  ComfyUI/models/clip/t5xxl_fp8_e4m3fn.safetensors
  ComfyUI/models/clip/clip_l.safetensors
  ComfyUI/models/vae/ae.safetensors
Dosya adları farklıysa --unet --t5 --clip --vae ile verilir.
"""
import argparse
import json
import os
import random
import sys
import time
import urllib.parse
import urllib.request
import uuid

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
NEG = "text, letters, watermark, signature, logo, frame, border, card frame, multiple creatures, human, person, blurry, lowres, cropped, deformed"


def args_parse():
    p = argparse.ArgumentParser()
    p.add_argument("--server", default="http://127.0.0.1:8188")
    p.add_argument("--mode", default="flux-gguf", choices=["flux-gguf", "flux-ckpt", "sdxl"])
    p.add_argument("--unet", default="flux1-dev-Q5_K_S.gguf")
    p.add_argument("--t5", default="t5xxl_fp8_e4m3fn.safetensors")
    p.add_argument("--clip", default="clip_l.safetensors")
    p.add_argument("--vae", default="ae.safetensors")
    p.add_argument("--ckpt", default="flux1-dev-fp8.safetensors", help="flux-ckpt / sdxl modunda tek dosya model")
    p.add_argument("--steps", type=int, default=20)
    p.add_argument("--guidance", type=float, default=3.5, help="Flux yönlendirme gücü")
    p.add_argument("--cfg", type=float, default=1.0, help="Flux için 1.0; SDXL için 5-7 (Lightning: 2)")
    p.add_argument("--sampler", default="euler")
    p.add_argument("--scheduler", default="simple")
    p.add_argument("--size", type=int, default=1024)
    p.add_argument("--evo2", type=float, default=0.62, help="2. evrimde değişim oranı (0-1)")
    p.add_argument("--evo3", type=float, default=0.68, help="3. evrimde değişim oranı (0-1)")
    p.add_argument("--sets", default="", help="virgülle set numaraları, boşsa hepsi")
    p.add_argument("--redo", default="", help="set:num,num,... yeniden üret")
    p.add_argument("--test", action="store_true", help="0. setten 21 görsel üret ve süreyi ölç")
    return p.parse_args()


# ---------- ComfyUI API ----------
def api(a, path, data=None, raw=False):
    url = a.server + path
    if data is not None and not isinstance(data, bytes):
        data = json.dumps(data).encode()
        req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    else:
        req = urllib.request.Request(url, data=data)
    with urllib.request.urlopen(req, timeout=600) as r:
        body = r.read()
    return body if raw else json.loads(body)


def upload(a, path):
    name = f"taso_{uuid.uuid4().hex[:10]}.png"
    boundary = uuid.uuid4().hex
    with open(path, "rb") as f:
        img = f.read()
    body = (f"--{boundary}\r\nContent-Disposition: form-data; name=\"overwrite\"\r\n\r\ntrue\r\n"
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"image\"; filename=\"{name}\"\r\n"
            f"Content-Type: image/png\r\n\r\n").encode() + img + f"\r\n--{boundary}--\r\n".encode()
    req = urllib.request.Request(a.server + "/upload/image", data=body,
                                 headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())["name"]


def graph(a, prompt, seed, init_image=None, denoise=1.0):
    g = {}
    if a.mode == "flux-gguf":
        g["m"] = {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": a.unet}}
        g["c"] = {"class_type": "DualCLIPLoader", "inputs": {"clip_name1": a.t5, "clip_name2": a.clip, "type": "flux"}}
        g["v"] = {"class_type": "VAELoader", "inputs": {"vae_name": a.vae}}
        model, clip, vae = ["m", 0], ["c", 0], ["v", 0]
    else:
        g["k"] = {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": a.ckpt}}
        model, clip, vae = ["k", 0], ["k", 1], ["k", 2]
    flux = a.mode.startswith("flux")
    g["pos"] = {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": clip}}
    g["neg"] = {"class_type": "CLIPTextEncode", "inputs": {"text": "" if flux else NEG, "clip": clip}}
    pos = ["pos", 0]
    if flux:
        g["guid"] = {"class_type": "FluxGuidance", "inputs": {"guidance": a.guidance, "conditioning": pos}}
        pos = ["guid", 0]
    if init_image:
        g["load"] = {"class_type": "LoadImage", "inputs": {"image": init_image}}
        g["lat"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["load", 0], "vae": vae}}
    else:
        g["lat"] = {"class_type": "EmptySD3LatentImage" if flux else "EmptyLatentImage",
                    "inputs": {"width": a.size, "height": a.size, "batch_size": 1}}
    g["ks"] = {"class_type": "KSampler", "inputs": {
        "seed": seed, "steps": a.steps, "cfg": a.cfg, "sampler_name": a.sampler, "scheduler": a.scheduler,
        "denoise": denoise, "model": model, "positive": pos, "negative": ["neg", 0], "latent_image": ["lat", 0]}}
    g["dec"] = {"class_type": "VAEDecode", "inputs": {"samples": ["ks", 0], "vae": vae}}
    g["save"] = {"class_type": "SaveImage", "inputs": {"filename_prefix": "taso/tmp", "images": ["dec", 0]}}
    return g


def run(a, g, dest):
    cid = uuid.uuid4().hex
    pid = api(a, "/prompt", {"prompt": g, "client_id": cid})["prompt_id"]
    while True:
        time.sleep(1.0)
        h = api(a, f"/history/{pid}")
        if pid in h:
            st = h[pid].get("status", {})
            if st.get("status_str") == "error":
                raise RuntimeError(json.dumps(st.get("messages", []))[:800])
            outs = h[pid].get("outputs", {})
            for node in outs.values():
                for im in node.get("images", []):
                    q = urllib.parse.urlencode({"filename": im["filename"], "subfolder": im["subfolder"], "type": im["type"]})
                    data = api(a, "/view?" + q, raw=True)
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    with open(dest, "wb") as f:
                        f.write(data)
                    return
            if st.get("completed"):
                raise RuntimeError("çıktı yok")


def path_of(e):
    return os.path.join(OUT, "set_%02d" % e["set"], "%03d.png" % e["num"])


def main():
    a = args_parse()
    with open(os.path.join(HERE, "prompts.json"), encoding="utf-8") as f:
        items = json.load(f)
    by_key = {(e["set"], e["num"]): e for e in items}

    # yeniden üretilecekler: 1. evrim silinirse ailesi de yeniden üretilir
    seed_bump = {}
    if a.redo:
        for part in a.redo.split(";"):
            s, nums = part.split(":")
            for n in nums.split(","):
                n = int(n)
                sp, st = (n - 1) // 3, (n - 1) % 3
                for k in range(st, 3):
                    num = sp * 3 + k + 1
                    pth = path_of(by_key[(int(s), num)])
                    if os.path.exists(pth):
                        os.remove(pth)
                    seed_bump[(int(s), num)] = random.randrange(1, 10 ** 6)
    sets = None
    if a.sets:
        sets = {int(x) for x in a.sets.split(",")}
    if a.test:
        sets = {0}
        items = [e for e in items if e["set"] == 0 and e["species"] < 7]
    if sets is not None:
        items = [e for e in items if e["set"] in sets]
    todo = [e for e in items if not os.path.exists(path_of(e))]
    # tür sırasıyla: önce 1. evrim, sonra ondan 2. ve 3.
    todo.sort(key=lambda e: (e["set"], e["species"], e["stage"]))
    print(f"{len(todo)} görsel üretilecek ({a.mode}, {a.steps} adım, {a.size}px)")
    t0 = time.time()
    done = 0
    for e in todo:
        seed = e["seed"] + seed_bump.get((e["set"], e["num"]), 0)
        dest = path_of(e)
        t1 = time.time()
        try:
            if e["stage"] == 0:
                g = graph(a, e["prompt"], seed)
            else:
                prev = by_key[(e["set"], e["num"] - 1)]
                if not os.path.exists(path_of(prev)):
                    print("  önceki evrim yok, atlandı:", e["set"], e["num"])
                    continue
                name = upload(a, path_of(prev))
                g = graph(a, e["prompt"], seed + e["stage"], name, a.evo2 if e["stage"] == 1 else a.evo3)
            run(a, g, dest)
        except KeyboardInterrupt:
            print("\nDurduruldu. Tekrar çalıştırınca kaldığı yerden devam eder.")
            sys.exit(0)
        except Exception as ex:
            print(f"  HATA set {e['set']} no {e['num']}: {ex}")
            if "Connection refused" in str(ex) or "10061" in str(ex):
                print("ComfyUI açık değil gibi görünüyor. Önce ComfyUI'yi başlat.")
                sys.exit(1)
            continue
        done += 1
        per = (time.time() - t0) / done
        left = (len(todo) - done) * per
        print(f"[{done}/{len(todo)}] set {e['set']:02d} no {e['num']:03d} {e['archetype']:<18} "
              f"{time.time() - t1:5.1f} sn  | kalan ~{left / 3600:.1f} saat")
    print("Bitti.")


if __name__ == "__main__":
    main()
