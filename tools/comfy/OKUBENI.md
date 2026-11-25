# Taso çizimlerini ComfyUI + Flux ile üretmek

Hedef: 34 set × 50 tür × 3 evrim = 5100 benzersiz çizim. Bilgisayarın: RTX 4060 (8 GB), 16 GB RAM.
Ayar: Flux dev (GGUF Q5), 20 adım, 1024 px. Görsel başına ~1 dakika, toplam 3–4 gece. İstediğin an durdurabilirsin; kaldığı yerden devam eder.

## 1. Kurulum (bir kez, ~1 saat; çoğu indirme)

1. **ComfyUI:** https://github.com/comfyanonymous/ComfyUI/releases adresinden `ComfyUI_windows_portable_nvidia.7z` dosyasını indir, örneğin `C:\ComfyUI_windows_portable` içine aç.
2. **GGUF eklentisi:** `C:\ComfyUI_windows_portable\ComfyUI\custom_nodes` klasöründe bir komut penceresi aç:
   ```
   git clone https://github.com/city96/ComfyUI-GGUF
   ..\..\python_embeded\python.exe -m pip install -r ComfyUI-GGUF\requirements.txt
   ```
   (git yoksa eklentiyi GitHub'dan zip olarak indirip `custom_nodes\ComfyUI-GGUF` klasörüne aç.)
3. **Modeller** (Hugging Face'ten indirip şu klasörlere koy):

   | Dosya | Klasör | Nereden |
   |---|---|---|
   | `flux1-dev-Q5_K_S.gguf` (~8 GB) | `ComfyUI\models\unet` | https://huggingface.co/city96/FLUX.1-dev-gguf |
   | `t5xxl_fp8_e4m3fn.safetensors` (~5 GB) | `ComfyUI\models\clip` | https://huggingface.co/comfyanonymous/flux_text_encoders |
   | `clip_l.safetensors` | `ComfyUI\models\clip` | https://huggingface.co/comfyanonymous/flux_text_encoders |
   | `ae.safetensors` | `ComfyUI\models\vae` | https://huggingface.co/black-forest-labs/FLUX.1-schnell (Files sekmesi) |

4. `run_nvidia_gpu.bat` ile ComfyUI'yi başlat. Tarayıcıda http://127.0.0.1:8188 açılıyorsa hazır.

## 2. Deneme (21 görsel, ~20 dakika)

Bu depo bilgisayarında olsun (GitHub Desktop ya da "Code → Download ZIP"). Depo klasöründe komut penceresi aç:

```
C:\ComfyUI_windows_portable\python_embeded\python.exe tools\comfy\run_comfy.py --test
C:\ComfyUI_windows_portable\python_embeded\python.exe tools\comfy\contact_sheet.py 0
```

`tools\comfy\out\sheets\set_00.jpg` dosyasına bak. Görsel başına süre ekranda yazar. Beğenirsen devam.

## 3. Hepsini üret

```
C:\ComfyUI_windows_portable\python_embeded\python.exe tools\comfy\run_comfy.py
```

- Pencereyi açık bırak, gece çalışsın. Ctrl+C ile durdur, aynı komutla devam et.
- Sadece belirli setler: `--sets 0,1,2`
- Bellek hatası alırsan daha küçük model: `flux1-dev-Q4_K_S.gguf` indirip `--unet flux1-dev-Q4_K_S.gguf` ekle.
- Daha hızlı istersen: `--steps 14` ya da `--size 832`.

## 4. Kontrol ve düzeltme

```
...\python.exe tools\comfy\contact_sheet.py
```

Her set için `out\sheets\set_XX.jpg` oluşur, numaralar görselin altında yazar. Beğenmediklerini yeniden üret:

```
...\python.exe tools\comfy\run_comfy.py --redo 3:5,17,22
```

(3. setin 5, 17 ve 22 numaraları. Birden fazla set: `--redo "3:5,17;8:40"`.) Bir 1. evrimi yeniden üretirsen o türün 2. ve 3. evrimi de onunla uyumlu olsun diye yeniden üretilir.

## 5. Oyuna aktar

```
...\python.exe tools\comfy\build_atlas.py
```

`assets\art\set_XX.jpg` dosyaları güncellenir (yarım kalmış setlerde eksik numaralar eski çizimle kalır). Sonra değişiklikleri GitHub'a gönder (GitHub Desktop: Commit → Push). Oyunun web, Windows ve Android sürümleri kendiliğinden yeni çizimlerle derlenir.

## İstemler

`tools/comfy/prompts.py` her setin temasını (ortam, malzeme, renkler, canlı türleri) tanımlar ve `prompts.json` dosyasını üretir. Tema ya da tarz değiştirmek istersen bu dosyayı düzenleyip `python tools/comfy/prompts.py` çalıştır; daha önce üretilmiş görseller silinmedikçe yeniden üretilmez.
