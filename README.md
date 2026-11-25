# Taso Kaosu (çalışma adı)

Godot ile yapılan bir "kaostan düzene" toplu dizme oyunu. Oyuncu birinci şahıs bakışla, yere yığılmış binlerce tasoyu setlerine ve numaralarına göre vitrinlere diziyor, kazandığı jetonlarla yetenek açıyor ve hızlanıyor.

## Şu anki durum: Aşama 2, büyük depo ve 5000 taso

- 40×30 m'lik depo. 6 kaotik yığın ve yere saçılmış tasolar, toplam 5000 taso.
- 12 set × 60 numara (720 benzersiz taso), yaklaşık %4'ü holo.
- Her setin duvarda bir vitrini var (10 × 6 yuva), toplam 12 vitrin. Yuvalarda numara yazmıyor. Her taso her yuvaya konabilir, sırayı oyuncu kendisi kuruyor (soldan sağa, yukarıdan aşağı 1-60).
- Yanlış yerdeki taso kırmızı halkayla gösteriliyor. Tamamen doğru dizilen vitrin yeşile dönüyor.
- Dolu yuvaya tıklayınca taso geri alınıyor ya da elindeki seçili tasoyla yer değiştiriyor.
- Jeton sadece bir taso doğru yere ilk kez oturduğunda veriliyor.
- Taso yüzlerinde set kodu ve numara var (shader + çalışma anında üretilen doku atlası). Holo tasolar gökkuşağı gibi parlıyor.
- Elde birden fazla taso tutulabiliyor (başta 10, Avuç ile 40). Fare tekerleğiyle seçim yapılıyor.
- Zıplama, Shift ile hızlı koşu.
- Yığınlar MultiMesh ile çiziliyor, bakılan taso uzamsal ızgarayla bulunuyor.
- 4 yetenek: Renk Gözü, Otomatik Dizme, Avuç (3 seviye), Holo Dedektörü.

### Tarayıcıda oyna

Her `main` push'unda GitHub Actions web build alıp GitHub Pages'e yayınlar: https://bogacavdar.github.io/tasoTidyUp/

### Godot ile çalıştırma

1. Godot 4.3 veya üstünü aç.
2. **Import** ile bu klasördeki `project.godot` dosyasını seç.
3. F5 ile çalıştır.

### Kontroller

- **WASD:** yürü, **Shift:** koş, **Boşluk:** zıpla, **fare:** bak
- **Sol tık:** yığından taso al / seçili tasoyu boş yuvaya koy / dolu yuvadan geri al ya da seçiliyle değiştir / kopyaları Kopya Kutusu'na at
- **Fare tekerleği:** eldeki tasolar arasında seçim yap
- **Q:** seçili tasoyu bırak, **sağ tık:** elindekilerin hepsini bırak
- **1-4:** yetenek satın al
- **R:** yeniden başla, **Esc:** fareyi serbest bırak

## Yol haritası

0. Konsept: 3D birinci şahıs, tasolar raflara ve vitrinlere dizilir
1. Çirkin prototip ✓
2. **5000 taso, büyük depo, taso yüzleri ← buradayız** (sırada: veri şeması)
3. Yetenek ağacı ve ekonomi (15-20 yetenek)
4. Modüler yaratık sistemi ve görsel stil (gövde aileleri, parçalar, elementler, evrim)
5. İçerik: yaklaşık 150 özgün yaratık, 5-6 set, 3000-5000 taso
6. His ve cila: sesler, paket açma, holo shader
7. Steam sayfası, devlog, demo, çıkış

Sonra: aynı motorla kartlı versiyon.

> Not: Tüm yaratıklar, isimler ve setler özgün olacak. Bilinen hiçbir markanın karakteri kullanılmayacak.
