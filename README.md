# Taso Kaosu (çalışma adı)

Godot ile yapılan bir "kaostan düzene" toplu dizme oyunu. Oyuncu yere saçılmış binlerce tasoyu setlerine ve numaralarına göre albümlere diziyor, kazandığı jetonlarla yetenek açıyor ve hızlanıyor.

## Şu anki durum: Aşama 1, çirkin prototip

Bu sürümün tek amacı şu soruya cevap bulmak: **Binlerce tasoyu dizmek eğlenceli mi?** Bu yüzden görsel yok, tasolar numaralı dairelerden ibaret.

- 500 taso, 4 set × 40 numara (160 benzersiz, geri kalanı kopya), yaklaşık %5'i holo
- Sürükle-bırak ile albümdeki doğru yuvaya yerleştirme
- Kopya Kutusu, tamamlanan albüm bonusu
- 4 yetenek: Renk Gözü, Otomatik Numara, Avuç (3 seviye), Holo Dedektörü

### Çalıştırma

1. Godot 4.3 veya üstünü aç.
2. **Import** ile bu klasördeki `project.godot` dosyasını seç.
3. F5 ile çalıştır.

### Kontroller

- **Sol tık basılı tut:** taso al. Albümdeki doğru yuvaya bırak.
- **Yere bırak:** kendi ara yığınlarını yap.
- **Kopya Kutusu:** albümde yeri dolu olan tasolar.
- **R:** yeniden başla.

## Yol haritası

0. Konsept sayfası: 2D tepeden masa görünümü seçildi
1. **Çirkin prototip ← buradayız**
2. Veri şeması + 5000 taso performans testi (MultiMesh)
3. Yetenek ağacı ve ekonomi (15-20 yetenek)
4. Modüler yaratık sistemi ve görsel stil (gövde aileleri, parçalar, elementler, evrim)
5. İçerik: yaklaşık 150 özgün yaratık, 5-6 set, 3000-5000 taso
6. His ve cila: sesler, paket açma, holo shader
7. Steam sayfası, devlog, demo, çıkış

Sonra: aynı motorla kartlı versiyon.

> Not: Tüm yaratıklar, isimler ve setler özgün olacak. Bilinen hiçbir markanın karakteri kullanılmayacak.
