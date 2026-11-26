# Taso Kaosu (çalışma adı)


> **Şimdilik:** Yerde yalnızca ComfyUI + Z-Image Turbo ile çizilmiş **Kor Vadisi** setinin 150 tasosu var. 34 vitrinin hepsi duruyor; diğer setlerin çizimleri üretildikçe `ACTIVE_SETS` (main.gd) artırılıp eklenecek.
Godot ile yapılan bir "kaostan düzene" toplu dizme oyunu. Oyuncu birinci şahıs bakışla, yere yığılmış binlerce tasoyu setlerine ve numaralarına göre vitrinlere diziyor, kazandığı puanlarla gelişim ağacında yetenek açıyor ve hızlanıyor.

## Şu anki durum: Taso dükkânı

- **Bina:** 70×50 m'lik bir taso dükkânı.
  - Ön duvarda açık cam kapı, "TASO DÜKKÂNI" tabelası, dışarıda kaldırım.
  - Vitrin camları ve pencereler, kapının yanında bir kasa.
  - Sağda ve solda iki kollu (U şeklinde) malikane merdiveniyle çıkılan, cam korkuluklu bir asma kat.
- **34 adet 3D vitrin:**
  - Sol ve sağ duvarlarda 6'şar, ortada 4 çift taraflı stand (8), ön duvarda 4, asma katta 10.
  - Her vitrinde yan panolar, üst kapak, alt dolap, her sırada raf çıtası, cam ön yüz, LED şerit ve set renginde başlık var.
  - 10 sütun × 15 satır yuva.
- **Canlılar:** Her sette 50 tür ve her türün 3 evrimi var (50 × 3 = 150). Numaralar Pokédex gibi sıralı: 1-2-3 ilk türün evrimleri. Türler setin konseptine uygun vücut planlarından üretiliyor: dört ayaklı, iki ayaklı, yılan, kuş, balık, böcek, ahtapot/denizanası/kalamar, hayalet, bitki, golem, yengeç/ıstakoz, balçık. Her planın alt formları var. Resimler `tools/gen_creatures.py` ile üretilip `assets/art/set_XX.jpg` atlaslarına yazılıyor.
- **5100 benzersiz taso:** 34 set × 150 numara (50 tür × 3 evrim), her setin kendine ait belirgin bir rengi var. İki katın zeminine rastgele saçılmış.
- **Yuvalar:** Koyu ahşap panoda krem halkalar. Baktığın yuvanın etrafında sarı bir halka çıkar.
- **Dizme:** Her taso her yuvaya konabilir, sırayı oyuncu kurar. Doğru sıra soldan sağa, yukarıdan aşağı 1-150.
  - Yanlış yerdeki taso kırmızı halkayla gösterilir.
  - Tamamen doğru dizilen vitrin yeşile döner.
  - Doğru yere oturan taso çan sesi çıkarır.
- **Puan:** Doğru yere ilk kez oturan taso +1, bir türün 3 evrimi doğru yerde +2, tamamlanan vitrin +25. Puanlar gelişim ağacında harcanır.
- **Taşıma:** Elde birden fazla taso tutulabilir, fare tekerleğiyle seçilir. Zıplama ve Shift ile koşu var.
- **Dükkânın dönüşümü:** Oyun loş, soluk renkli ve tozlu bir dükkânda başlar; yerde kir lekeleri, havada toz zerreleri vardır. Doğru dizilen taso arttıkça lambalar parlar, renkler canlanır, toz ve lekeler kaybolur. Her vitrinin LED şeridi o vitrin doldukça yanar ve camındaki toz silinir. Biten vitrinden konfeti fışkırır; %2, %10, %25, %50, %75 ve %90 düzende dükkân aydınlanıyor mesajı çıkar.
- **Albüm (B ya da menü):** 34 setin her biri için 150 canlılık bir sayfa. Doğru yerine koyduğun canlılar renkli açılır, diğerleri karanlık siluet olarak durur. Alttaki set sekmeleri ve oklarla gezilir.
- **Ses ve müzik:** Kodla sentezlenmiş sakin bir lo-fi dükkân müziği (`tools/gen_music.py` → `assets/audio/muzik.ogg`), ayak sesleri, taso alma, bırakma, yanlış yerleştirme, satın alma ve büyü sesleri. Ayarlarda genel ses, müzik ve efekt ayrı ayrı.
- **İlk açılış rehberi:** Yeni oyunda 7 adımlık kısa bir rehber: taso alma, seçme, vitrini bulma, numara sırası, kırmızı halka ve puanlar, gelişim ağacı. H ile ya da telefonda "Rehberi geç" ile atlanır; Ayarlar'dan baştan gösterilir.
- **Gelişim ağacı (Tab):** Taşıma ve hareket (El Kapasitesi, Avuç, Hız), Görüş (Sezgi, Vitrin Pusulası), Büyüler (Toplama, Otomatik Dizme, Ayıklama). Büyüler bekleme sürelidir: Z Sezgi, F Toplama, G Ayıklama.

### İndir

- **Windows ve Android:** [Releases → Son sürüm](https://github.com/bogacavdar/tasoTidyUp/releases/tag/son-surum). Her `main` push'unda otomatik güncellenir. Windows için zip'i aç ve `TasoDukkani.exe`'yi çalıştır. Android için `.apk`'yı kur (64 bit ve 32 bit ARM telefonlarda çalışır). APK'lar depodaki sabit test anahtarıyla (`android/test.keystore`) imzalanır, böylece güncellemeler eskisinin üstüne kurulur. Bu anahtar yalnızca test dağıtımı içindir; Google Play'e çıkarken gizli tutulan ayrı bir yükleme anahtarı kullanılmalı.
- **Telefonda kontroller:** Sol taraf sanal joystick. Sağ tarafı sürükleyince bakış döner, kısa dokununca taso alınır veya yerleştirilir. Zıpla, Koş, Bırak, < >, Ağaç ve açılan büyüler için butonlar da var. Telefonda görüntü çözünürlüğü varsayılan olarak %80'dir, parlama efekti kapalıdır; Ayarlar'dan değiştirilebilir.

### Tarayıcıda oyna

Her `main` push'unda GitHub Actions web build alıp GitHub Pages'e yayınlar: https://bogacavdar.github.io/tasoTidyUp/

### Godot ile çalıştırma

1. Godot 4.3 veya üstünü aç.
2. **Import** ile bu klasördeki `project.godot` dosyasını seç.
3. F5 ile çalıştır.

### Kontroller

- **WASD:** yürü, **Shift:** koş, **Boşluk:** zıpla, **fare:** bak
- **Sol tık:** yerden taso al / seçili tasoyu boş yuvaya koy / dolu yuvadaki tasoyu eline al (bir yuvada tek taso olur)
- **Fare tekerleği:** eldeki tasolar arasında seçim yap
- **Q:** seçili tasoyu fırlat, **Shift+Q:** elindekilerin hepsini fırlat (fizikle seker, ters düşebilir)
- **Sağ tık (basılı tut):** yakınlaştır (zoom); telefonda Zoom butonu
- **Tab:** gelişim ağacı, **B:** albüm, **Z / F / G:** büyüler, **H:** rehberi geç
- **Esc:** menü (telefonda sağ üstteki Menü butonu)

## Kayıt ve menü

- İlerleme otomatik kaydedilir: değişiklik varsa 20 saniyede bir, menü açılınca, pencere arka plana geçince ve çıkarken. Tarayıcıda, Windows'ta ve Android'de ayrı ayrı çalışır (`user://kayit.json`).
- Açılışta ve Esc ile menü: Devam Et, Kaydet, Yeni Oyun (iki kez onaylı), Gelişim Ağacı, Albüm, Ayarlar (fare/dokunmatik hassasiyeti, genel ses, müzik, efektler, görüntü çözünürlüğü, rehberi baştan göster), Çıkış (tarayıcıda yok).

## Görseller

- Zemin, duvar, tavan ve ahşap yüzeylerde [Poly Haven](https://polyhaven.com)'ın gerçek fotoğraf dokuları (CC0) kullanılıyor. Liste `assets/textures.txt` dosyasında. `Dokuları indir` iş akışı bunları `assets/tex/` klasörüne indirir.
- Işık: ACES ton eşleme, hafif parlama (glow), sarkıt lambalar.

## Yol haritası

0. Konsept: 3D birinci şahıs, tasolar raflara ve vitrinlere dizilir
1. Çirkin prototip ✓
2. 5000 taso, büyük dükkân, taso yüzleri ✓
3. Puan ve gelişim ağacı ✓ (dengeleme sürüyor)
4. Modüler yaratık sistemi ve görsel stil (gövde aileleri, parçalar, elementler, evrim)
5. İçerik: 34 set, 5100 benzersiz taso için özgün yaratıklar
6. His ve cila: dükkân dönüşümü, albüm, müzik ve sesler, rehber ✓
7. Steam sayfası, devlog, demo, çıkış

Sonra: aynı motorla kartlı versiyon.

> Not: Tüm yaratıklar, isimler ve setler özgün olacak. Bilinen hiçbir markanın karakteri kullanılmayacak.
