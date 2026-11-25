# Taso Kaosu (çalışma adı)

Godot ile yapılan bir "kaostan düzene" toplu dizme oyunu. Oyuncu birinci şahıs bakışla, yere yığılmış binlerce tasoyu setlerine ve numaralarına göre vitrinlere diziyor, kazandığı jetonlarla yetenek açıyor ve hızlanıyor.

## Şu anki durum: Taso dükkânı

- **Bina:** 70×50 m'lik bir taso dükkânı.
  - Ön duvarda açık cam kapı, "TASO DÜKKÂNI" tabelası, dışarıda kaldırım.
  - Vitrin camları ve pencereler, kapının yanında bir kasa.
  - Spiral merdivenle çıkılan, cam korkuluklu bir asma kat.
- **34 adet 3D vitrin:**
  - Sol ve sağ duvarlarda 6'şar, ortada 4 çift taraflı stand (8), ön duvarda 4, asma katta 10.
  - Her vitrinde yan panolar, üst kapak, alt dolap, her sırada raf çıtası, cam ön yüz, LED şerit ve set renginde başlık var.
  - 10 sütun × 15 satır yuva.
- **Taso çizimleri:** 34 setin her birinde temaya uygun çizimler var, her biri taso numarasından türetiliyor. Hepsi kodla, ekran kartında çiziliyor (`taso.gdshader`). Motifler: yaratık, balık, çiçek/mercan, kristal, gök cismi, mantar, kuş/yarasa, manzara, böcek. Setler gece, pastel ve taş/metalik gibi renk havalarına ayrılıyor.
- **5100 benzersiz taso:** 34 set × 150 numara, her setin kendine ait belirgin bir rengi var. İki katın zeminine rastgele saçılmış.
- **Yuvalar:** Koyu ahşap panoda krem halkalar. Baktığın yuvanın etrafında sarı bir halka çıkar.
- **Dizme:** Her taso her yuvaya konabilir, sırayı oyuncu kurar. Doğru sıra soldan sağa, yukarıdan aşağı 1-150.
  - Yanlış yerdeki taso kırmızı halkayla gösterilir.
  - Tamamen doğru dizilen vitrin yeşile döner.
  - Doğru yere oturan taso çan sesi çıkarır.
- **Jeton:** Sadece bir taso doğru yere ilk kez oturduğunda verilir.
- **Taşıma:** Elde birden fazla taso tutulabilir, fare tekerleğiyle seçilir. Zıplama ve Shift ile koşu var.
- **3 yetenek:** Otomatik Dizme, Avuç, Holo Dedektörü.

### İndir

- **Windows ve Android:** [Releases → Son sürüm](https://github.com/bogacavdar/tasoTidyUp/releases/tag/son-surum). Her `main` push'unda otomatik güncellenir. Windows için zip'i aç ve `TasoDukkani.exe`'yi çalıştır. Android için `.apk`'yı kur.
- **Telefonda kontroller:** Sol taraf sanal joystick. Sağ tarafı sürükleyince bakış döner, kısa dokununca taso alınır veya yerleştirilir. Zıpla, Koş, Bırak, < > ve 1-3 butonları da var.

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
- **1-3:** yetenek satın al
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
