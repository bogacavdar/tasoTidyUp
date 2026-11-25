# Taso Kaosu (çalışma adı)

Godot ile yapılan bir "kaostan düzene" toplu dizme oyunu. Oyuncu birinci şahıs bakışla, yere yığılmış binlerce tasoyu setlerine ve numaralarına göre vitrinlere diziyor, kazandığı jetonlarla yetenek açıyor ve hızlanıyor.

## Şu anki durum: Aşama 2, dev depo ve 5100 benzersiz taso

- 60×50 m'lik depo. Bütün tasolar zemine tamamen rastgele saçılmış.
- **5100 benzersiz taso:** 34 set × 150 numara, kopya yok. Yaklaşık %4'ü holo.
- Her setin duvarda bir vitrini var (15 × 10 yuva), toplam 34 vitrin.
- Yuvalarda numara yazmıyor. Her taso her yuvaya konabilir, sırayı oyuncu kurar (soldan sağa, yukarıdan aşağı 1-150).
- Yanlış yerdeki taso kırmızı halkayla gösterilir. Tamamen doğru dizilen vitrin yeşile döner.
- Dolu yuvaya tıklayınca taso geri alınır ya da elindeki seçili tasoyla yer değiştirir.
- Jeton sadece bir taso doğru yere ilk kez oturduğunda verilir.
- Taso yüzlerinde set kodu ve numara var. Shader bunları küçük bir rakam/kod atlasından anında oluşturur. Holo tasolar gökkuşağı gibi parlar.
- Elde birden fazla taso tutulabilir (başta 10, Avuç ile 40). Fare tekerleğiyle seçim yapılır.
- Zıplama, Shift ile hızlı koşu.
- 4 yetenek: Renk Gözü, Otomatik Dizme, Avuç (3 seviye), Holo Dedektörü.

### Tarayıcıda oyna

Her `main` push'unda GitHub Actions web build alıp GitHub Pages'e yayınlar: https://bogacavdar.github.io/tasoTidyUp/

### Godot ile çalıştırma

1. Godot 4.3 veya üstünü aç.
2. **Import** ile bu klasördeki `project.godot` dosyasını seç.
3. F5 ile çalıştır.

### Kontroller

- **WASD:** yürü, **Shift:** koş, **Boşluk:** zıpla, **fare:** bak
- **Sol tık:** yığından taso al / seçili tasoyu boş yuvaya koy / dolu yuvadan geri al ya da seçiliyle değiştir
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
5. İçerik: 34 set, 5100 benzersiz taso için özgün yaratıklar
6. His ve cila: sesler, paket açma, holo shader
7. Steam sayfası, devlog, demo, çıkış

Sonra: aynı motorla kartlı versiyon.

> Not: Tüm yaratıklar, isimler ve setler özgün olacak. Bilinen hiçbir markanın karakteri kullanılmayacak.
