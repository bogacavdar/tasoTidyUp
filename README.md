# Taso Kaosu (çalışma adı)

Godot ile yapılan bir "kaostan düzene" toplu dizme oyunu. Oyuncu yere saçılmış binlerce tasoyu setlerine ve numaralarına göre albümlere diziyor, kazandığı jetonlarla yetenek açıyor ve hızlanıyor.

## Şu anki durum: Aşama 1, 3D birinci şahıs prototip

Bu sürümün tek amacı şu soruya cevap bulmak: **Binlerce tasoyu dizmek eğlenceli mi?** Bu yüzden yaratık çizimi yok, tasolar düz renkli diskler.

- Odanın ortasında 500 tasoluk bir yığın var. 4 set × 40 numara (160 benzersiz, geri kalanı kopya), yaklaşık %5'i holo.
- Duvarlarda her set için bir vitrin (8 × 5 numaralı yuva).
- Yürü, yığındaki tasoya bak ve al, vitrindeki doğru yuvaya yerleştir.
- Kopya Kutusu, tamamlanan vitrin bonusu.
- 4 yetenek: Renk Gözü, Otomatik Numara, Avuç (3 seviye), Holo Dedektörü.

### Tarayıcıda oyna

Her `main` push'unda GitHub Actions web build alıp GitHub Pages'e yayınlar: https://bogacavdar.github.io/tasoTidyUp/

### Godot ile çalıştırma

1. Godot 4.3 veya üstünü aç.
2. **Import** ile bu klasördeki `project.godot` dosyasını seç.
3. F5 ile çalıştır.

### Kontroller

- **WASD:** yürü, **Shift:** koş, **fare:** bak
- **Sol tık:** yığından taso al / vitrindeki yuvaya yerleştir / Kopya Kutusu'na at
- **Sağ tık veya Q:** elindekileri baktığın yere bırak (kendi ara yığınlarını yap)
- **1-4:** yetenek satın al
- **R:** yeniden başla, **Esc:** fareyi serbest bırak

## Yol haritası

0. Konsept: 3D birinci şahıs, tasolar raflara ve vitrinlere dizilir
1. **Çirkin prototip ← buradayız**
2. Veri şeması + 5000 taso performans testi (MultiMesh)
3. Yetenek ağacı ve ekonomi (15-20 yetenek)
4. Modüler yaratık sistemi ve görsel stil (gövde aileleri, parçalar, elementler, evrim)
5. İçerik: yaklaşık 150 özgün yaratık, 5-6 set, 3000-5000 taso
6. His ve cila: sesler, paket açma, holo shader
7. Steam sayfası, devlog, demo, çıkış

Sonra: aynı motorla kartlı versiyon.

> Not: Tüm yaratıklar, isimler ve setler özgün olacak. Bilinen hiçbir markanın karakteri kullanılmayacak.
