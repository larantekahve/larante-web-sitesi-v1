# LARANTE WEB PLATFORMU — ÜRÜN GEREKSİNİMLERİ

**Dosya:** `LARANTE_WEB_REQUIREMENTS.md`  
**Sürüm:** 1.0  
**Tarih:** 2026-09-15  
**Durum:** Onaylanmış ana gereksinimler  
**Kapsam:** Larante Coffee Roastery kurumsal web sitesi, B2C e-ticaret, Larante Akademi, içerik, lead yönetimi ve web yönetim paneli.  
**İlişkili doküman:** `LARANTE_WEB_ALTYAPI_MIMARISI_V2.md`

---

# 1. Dokümanın Amacı

Bu doküman, Larante web platformunun ne yapacağını tanımlar.

Teknik uygulama ayrıntıları mimari dokümanda yer alır. Bu dosya ise:

- iş hedeflerini,
- kullanıcıları,
- sayfa ve fonksiyonları,
- ürün kataloğunu,
- e-ticaret davranışlarını,
- yönetim panelini,
- Akademi ve içerik özelliklerini,
- B2B ile sınırları,
- bildirimleri,
- analitiği,
- güvenliği,
- performans ve kabul kriterlerini

tek kaynakta toplar.

Bu dokümandaki onaylanmış gereksinimler, Claude Code görevleri ve sonraki teknik denetimler için ana referanstır.

---

# 2. Ürün Vizyonu

Larante web platformu yalnızca bir kurumsal tanıtım sitesi olmayacaktır.

Platform aynı anda dört görevi yerine getirecektir:

1. **Marka prestiji oluşturmak**
2. **Larante ürünlerini güçlü biçimde sergilemek**
3. **Son tüketiciye doğrudan online satış yapmak**
4. **Mevcut işletme müşterilerini B2B sistemine yönlendirmek**

Web mağazası ile B2B sistemi ticari olarak farklı kanallardır.

```text
LARANTE
│
├── Public Web / B2C
│   ├── Marka
│   ├── İçerik
│   ├── Akademi
│   └── Perakende E-Ticaret
│
└── B2B
    ├── İşletme müşterileri
    ├── B2B liste fiyatı
    ├── Müşteri iskontosu
    └── B2B operasyonları
```

---

# 3. İş Hedefleri — Öncelik Sırası

## 3.1 Ana hedefler

1. **Marka prestiji**
2. **Ürünleri göstermek**
3. **Mevcut müşterilere bilgi vermek**

## 3.2 Ana marka algısı

Ziyaretçi Larante hakkında şu üç kavramı anlamalıdır:

- **Kalite**
- **Tutarlılık**
- **Doğru fiyat / doğru maliyet dengesi**

Bu mesaj doğrudan “ucuzluk” algısına dönüştürülmeyecektir.

---

# 4. Marka Sloganı

Çalışma standardı:

> **True Maths. Perfect Coffee.**

Anlam:

> **Doğru matematik, mükemmel kahve.**

Slogan yalnız dekoratif bir ifade olarak değil; Larante’ın:

- reçete,
- oran,
- kavurma,
- öğütüm,
- demleme,
- maliyet,
- tutarlılık

yaklaşımının marka prensibi olarak kullanılacaktır.

Nihai yazım, noktalama ve tipografik uygulama `LARANTE_DESIGN_SYSTEM.md` içinde sabitlenecektir.

---

# 5. Hedef Kullanıcılar — Öncelik Sırası

1. **Mevcut kafe müşterileri**
2. **Son tüketiciler**
3. **Yeni kafe açacak işletmeciler**
4. **Oteller / kurumsal işletmeler**

---

# 6. Ana Kullanıcı Aksiyonları — Öncelik Sırası

1. **B2B sisteme giriş**
2. **Kataloğu inceleme**
3. **WhatsApp ile iletişim**
4. **Numune talebi**
5. **Teklif talebi**

B2B girişi header içinde belirgin olacaktır; ana sayfada ayrı büyük B2B reklam bölümü oluşturulmayacaktır.

---

# 7. Satış Kanalları ve Fiyatlandırma Sınırı

## 7.1 Public web mağazası

- Son tüketiciye satış yapılır.
- Fiyatlar **KDV dahil** gösterilir.
- Public fiyat B2B fiyatından bağımsızdır.
- Kurumsal bir müşteri public mağazadan alışveriş yaparsa public perakende fiyatını görür.

## 7.2 B2B sistemi

- B2B müşterilerine sabit B2B liste fiyatı uygulanır.
- Müşterilerin ayrı ayrı iskonto oranları olabilir.
- B2B indirimi public web mağazasına otomatik taşınmaz.

```text
Ürün
├── Retail / Web fiyatı (KDV dahil)
└── B2B liste fiyatı
        └── müşteri bazlı iskonto
```

---

# 8. Ana Navigasyon

Desktop ana navigasyon:

```text
Ana Sayfa
Ürünler
Hakkımızda
Akademi
Katalog
İletişim
```

Sağ aksiyon alanı:

```text
Ara
Hesabım
Sepet
B2B Giriş
```

`B2B Giriş` görsel olarak diğer header öğelerinden daha belirgin olacaktır.

---

# 9. Mobil Navigasyon

Mobilde desktop navigasyon küçültülmeyecektir; ayrı optimize edilmiş akış kullanılacaktır.

Ana görünür aksiyonlar:

```text
Menü
Ara
Sepet
B2B
```

Mobil ürün, sepet, checkout ve B2B geçiş deneyimleri ayrı kontrol edilecektir.

---

# 10. Ana Sayfa Bilgi Mimarisi

Ana sayfa önerilen ve onaylanan sıralama:

## 10.1 Hero

- Premium hareketli kahve üretim sekansı
- Marka mesajı
- `Ürünleri Keşfet`
- `B2B Giriş`

Sekans örnek akışı:

```text
Kavurma kapağı
→ Soğutma
→ Tartım
→ Öğütme
→ Portafilter
→ Tamp
→ Espresso
```

## 10.2 Marka Felsefesi

`True Maths. Perfect Coffee.`

Doğru matematik → tutarlı sonuç → mükemmel kahve ilişkisi anlatılır.

## 10.3 Ürün Kategorileri

Dört büyük premium kategori:

- Kahve
- Aroma Grubu
- Toz Grubu
- Çay Grubu

## 10.4 Hakkımızda Özeti

- kısa marka hikâyesi
- kavurmahane
- Akademi
- `Hikâyemizi Keşfet`

## 10.5 Larante Akademi

Ana sayfada güçlü ve görsel ağırlıklı bölüm.

## 10.6 Öne Çıkan Ürünler

Admin panelinden manuel seçilir.

## 10.7 Kalite ve Tutarlılık

- kavurma yaklaşımı
- reçete standardı
- kalite anlayışı
- tutarlılık

## 10.8 Katalog

Web katalog sayfasına yönlendirir.

## 10.9 İletişim

- WhatsApp
- numune
- teklif
- satış temsilcisi talebi

## 10.10 Footer

Ayrıntılar ilgili bölümde tanımlanmıştır.

---

# 11. Referans Müşteri Politikası

Ana sayfada veya public web sitesinde referans kafe/otel logoları yayınlanmayacaktır.

Müşteri verisi ve işletme ilişkileri public prestij unsuru olarak paylaşılmayacaktır.

---

# 12. Ana Ürün Kategorileri

Public e-ticaret ana kategorileri:

```text
Kahve
Aroma Grubu
Toz Grubu
Çay Grubu
```

**Donuk ürün grubu public web satış kapsamında değildir.**

Kategori yapısı admin panelinden genişletilebilir olmalıdır.

---

# 13. Kahve Alt Kategorileri

```text
Kahve
├── Espresso
├── Filtre
├── Single Origin
└── Özel Seri
```

Espresso ve Filtre aynı blend ismini taşısalar dahi ayrı ürün olarak listelenebilir.

Örnek:

```text
Cappadocia Espresso
Cappadocia Filter
```

---

# 14. Kahve Gramaj Seçenekleri

Standart seçenekler:

- 250 g
- 500 g
- 1000 g

Ürün bazında seçenekler açılıp kapatılabilir.

---

# 15. Kahve Öğütüm Seçenekleri

```text
Çekirdek
Espresso Makinesi
Moka Pot
Aeropress
V60
Chemex
Filtre Kahve Makinesi
French Press
Türk Kahvesi
```

Öğütüm, kendi başına stok kalemi olmak zorunda değildir; sipariş hazırlama tercihi olarak modellenebilir.

Ürün bazında uygun olmayan öğütüm seçenekleri kapatılabilir.

---

# 16. Kavrum Seçenekleri

Standart çalışma seçenekleri:

- **Açık Kavrum — Agtron 75**
- **Orta Kavrum — Agtron 65**
- **Koyu Kavrum — Agtron 55**

## Gösterim kuralı

Ürün kartı / temel seçim:

```text
Açık
Orta
Koyu
```

Teknik ürün detayında:

```text
Açık — Agtron 75
Orta — Agtron 65
Koyu — Agtron 55
```

Espresso ve Filtre ürünlerinde üç seçenek desteklenir.

Single Origin ve Özel Seri ürünlerinde ürün bazında seçenek sayısı azaltılabilir.

---

# 17. Single Origin Modeli

Single Origin ürünleri bölge/ülke/çiftlik mantığıyla sunulabilir.

Örnek:

```text
Ethiopia Guji
Colombia Huila
Guatemala Antigua
```

Ürün bazında:

- gramaj,
- kavrum,
- öğütüm

seçenekleri yapılandırılabilir.

---

# 18. Kahve Ürün Detay Sayfası

Zorunlu alanlar:

- ürün adı
- ana ürün fotoğrafı
- fiyat
- kavrum seçimi
- gramaj
- öğütüm
- adet
- sepete ekle

İçerik alanları:

- tadım notaları
- gövde
- asidite
- tatlılık
- kavrum seviyesi
- menşei ülkeler
- işleme yöntemi
- blend içeriği
- demleme önerisi
- kavurma / tazelik politikası

Kavurma tarihi önceden sabit web tarihi olarak gösterilmez.

Mesaj yaklaşımı:

> Taze kavrulur. Kavurma tarihi paket üzerinde yer alır.

---

# 19. Aroma Grubu

Alt kategoriler:

```text
Aroma Grubu
├── Şuruplar
├── Meyve Püreleri
└── Bar Sosları
```

Yeni alt kategori ihtiyacı çıkarsa admin tarafından genişletilebilir.

---

# 20. Toz Grubu

Başlangıç ürün aileleri arasında:

- Milkshake
- Frappe
- Sıcak Çikolata
- Beyaz Çikolata
- Sahlep

bulunabilir.

Liste sabit değildir. Yeni toz ürünler kod değişikliği gerektirmeden eklenebilmelidir.

---

# 21. Çay Grubu

Sistem aşağıdaki gibi genişleyebilir:

```text
Çay Grubu
├── Siyah Çay
├── Yeşil Çay
├── Bitki Çayları
├── Meyve Çayları
├── Chai
└── Yeni alt kategoriler
```

Kategori ve ürün yapısı veri odaklı olacaktır.

---

# 22. Ürün Kartları

Ürün kartında:

- ana görsel
- ürün adı
- kısa kategori
- başlangıç fiyatı / uygun fiyat gösterimi
- kısa tat veya ürün notu
- favori
- `Ürünü İncele`

yer alabilir.

Çok varyantlı kahvelerde karttan doğrudan yanlış varyantı sepete eklemek yerine ürün detayına gidilir.

---

# 23. Ürün Görsel Yaklaşımı

Ürün sunumunda iki tip görsel birlikte kullanılacaktır:

1. **Ambalaj / ürün odaklı görsel**
2. **Lifestyle / kullanım görseli**

Genel estetik:

- fotogerçekçi
- premium
- stüdyo kalitesi
- sıcak
- yapay zekâ hissi düşük

---

# 24. Ürün Arama

Arama yalnız ürün adına bağlı olmayacaktır.

Aranabilir örnek alanlar:

- ürün adı
- kategori
- alt kategori
- tadım notası
- menşei
- işleme
- kavrum
- ürün açıklaması

Örnek sorgular:

```text
çikolata
meyvemsi
orta kavrum
Guatemala
```

---

# 25. Ürün Filtreleme

Filtreler kategoriye göre dinamik olmalıdır.

Kahve örneği:

- Espresso / Filtre / Single Origin / Özel Seri
- gramaj
- kavrum
- fiyat aralığı
- tadım profili
- menşei / uygun olduğu durumda diğer teknik alanlar

---

# 26. Sıralama

En az:

- Öne Çıkanlar
- En Yeniler
- Fiyat: Artan
- Fiyat: Azalan
- Çok Satanlar

---

# 27. Ürün Karşılaştırma

Kahveler arasında karşılaştırma desteklenir.

Karşılaştırılabilir örnek alanlar:

- gövde
- asidite
- tatlılık
- kavrum
- menşei
- işleme
- tadım notaları

---

# 28. Ürün Yorumları

- Ürün yorumları desteklenir.
- Satın alma doğrulaması yapılabilir.
- Doğrulanmış siparişten gelen yorumlarda `Doğrulanmış Alışveriş` etiketi gösterilir.
- Admin moderasyonu desteklenir.
- İçerik/blog yorumları V1'de kapalıdır.

---

# 29. Öneri Sistemleri

Ürün detaylarında:

- Benzer Ürünler
- Bununla İyi Gider
- Birlikte Alınanlar

gibi öneri alanları desteklenir.

İlk sürümde öneriler kural/manüel tabanlı olabilir; yapay zekâ zorunlu değildir.

---

# 30. Public Stok Davranışı

Stok varsa:

```text
Sepete Ekle
```

gösterilir.

Ek stok mesajı gösterilmez.

Stok yoksa:

```text
Stokta Yok
```

gösterilir.

Public sitede kesin stok adedi gösterilmez.

---

# 31. Tek Stok Kaynağı Kuralı

Web ve B2B aynı gerçek stok kaynağına bağlı olmalıdır.

```text
Tek Yetkili Stok
├── Web / B2C
└── B2B
```

**İki ayrı stok master kaynağı oluşturulması yasaktır.**

Teknik sahiplik kararı mevcut B2B repository incelemesinden sonra mimari dokümana göre uygulanacaktır.

---

# 32. Sepet

Sepet:

- üye kullanıcı
- misafir kullanıcı

için çalışmalıdır.

Sepete ürün eklemek uzun süreli stok rezervasyonu oluşturmaz.

Fiyat ve kullanılabilirlik checkout sırasında server tarafında yeniden doğrulanır.

---

# 33. Checkout Akışı

```text
Sepet
↓
Misafir / Üye Girişi
↓
Teslimat Bilgileri
↓
Fatura Tipi ve Bilgileri
↓
Kargo
↓
Kupon
↓
Ödeme
↓
Yasal Onaylar
↓
Sipariş Onayı
```

---

# 34. Misafir Alışveriş

Üyelik zorunlu değildir.

Misafir kullanıcı:

- ürün satın alabilir
- sipariş numarası alır
- e-posta ve SMS bildirimi alır
- siparişini takip edebilir

Satın alma sonrası hesap oluşturması teşvik edilebilir fakat zorunlu değildir.

---

# 35. Üye Müşteri Hesabı

Üye kullanıcı:

- profilini yönetebilir
- birden fazla adres kaydedebilir
- sipariş geçmişini görebilir
- kargo durumunu görebilir
- favorilerini yönetebilir
- tekrar satın alabilir
- iade talebi oluşturabilir

Giriş V1:

```text
E-posta + Şifre
Şifremi Unuttum
```

Telefon OTP / sosyal giriş zorunlu V1 kapsamı değildir.

---

# 36. Adresler

Birden fazla kayıtlı adres desteklenir.

Örnek etiketler:

- Ev
- İş
- Ofis

Checkout'ta:

> Fatura adresim teslimat adresimle aynı

seçeneği varsayılan olarak sunulabilir.

Fatura ve teslimat adresi ayrılabilir.

---

# 37. Fatura Tipleri

İki tip desteklenir:

- Bireysel
- Kurumsal

Kurumsalda gerekli şirket/vergi bilgileri alınır.

V1'de e-fatura/e-arşiv otomatik kesim entegrasyonu yoktur.

Sistem gerekli fatura verisini saklar; fatura Larante tarafından manuel kesilir.

---

# 38. Sipariş Takibi — Misafir Kullanıcı

Misafir kullanıcı:

```text
Sipariş No
+
E-posta veya Telefon
↓
Sipariş Takip
```

ile sipariş durumunu görebilir.

Bilgi ifşasına karşı doğrulama ve rate-limit uygulanmalıdır.

---

# 39. Ödeme Yöntemleri

V1:

- Kredi kartı
- Banka kartı
- 3D Secure
- Havale / EFT

Kapıda ödeme onaylanmış V1 kapsamı değildir.

---

# 40. Ödeme Sağlayıcısı

Uygulama tek ödeme firmasına bağımlı tasarlanmayacaktır.

`PaymentProvider` sözleşmesi kullanılacaktır.

Sağlayıcı seçimi:

- komisyon
- 3D Secure
- API kalitesi
- webhook güvenliği
- iade desteği
- operasyonel uygunluk

değerlendirilerek ayrıca yapılacaktır.

iyzico / PayTR vb. aday olabilir; bu doküman sağlayıcıyı kilitlemez.

---

# 41. Kartlı Ödemede Stok

Kullanıcı sepete eklediğinde stok düşmez.

Ödeme başlatıldığında oversell'i önlemek için kısa süreli teknik rezervasyon yapılabilir.

Ödeme başarılı olduğunda:

- sipariş kesinleşir
- stok kesin düşer
- rezervasyon kalıcı satış hareketine dönüşür

Ödeme başarısız olduğunda rezervasyon serbest bırakılır.

---

# 42. Havale / EFT Akışı

```text
Sipariş Oluşturuldu
↓
Ödeme Bekleniyor
↓
IBAN Göster
↓
24 Saat Rezervasyon
↓
Ödeme Kontrolü
↓
Ödeme Alındı
↓
Hazırlanıyor
```

24 saat içinde ödeme alınmazsa:

- sipariş otomatik iptal edilebilir
- ayrılmış stok serbest bırakılır

Havale süresi yönetilebilir ayar olmalıdır; ilk kural 24 saattir.

---

# 43. Sipariş Durumları

```text
Ödeme Bekleniyor
Ödeme Alındı
Hazırlanıyor
Kargoya Verildi
Teslim Edildi
İptal Edildi
İade Edildi
```

Teknik alt durumlar kullanıcıya birebir gösterilmek zorunda değildir.

---

# 44. Sipariş Bildirimleri

Aşağıdaki olaylarda kullanıcıya e-posta + SMS:

- Sipariş alındı
- Ödeme alındı
- Kargoya verildi
- Teslim edildi
- İptal edildi
- İade sonucu

Bildirim teslimatı ana sipariş transaction'ını kırmamalıdır; retry mekanizması olmalıdır.

---

# 45. Kargo

V1:

- Türkiye geneli kargo
- manuel takip numarası
- admin takip numarasını girer
- müşteri e-posta + SMS alır
- takip bağlantısı gösterilir

V1'de doğrudan kargo API zorunlu değildir.

Mimari daha sonra kargo API entegrasyonu eklenebilecek şekilde tasarlanır.

---

# 46. Ücretsiz Kargo

Belirli sepet tutarı üzerinde ücretsiz kargo desteklenir.

Limit:

- admin panelinden değiştirilebilir
- kod içine gömülmez

Site üzerinde uygun yerlerde:

> Belirli tutar üzeri ücretsiz kargo

mesajı gösterilebilir.

---

# 47. Kupon / Kampanya

Sistem:

- yüzde indirim
- sabit tutar indirim
- minimum sepet
- başlangıç tarihi
- bitiş tarihi
- kullanım limiti

destekleyebilir.

Varsayılan:

- aynı siparişte bir kupon

Admin özel kampanyalarda birleştirilebilirlik kuralı tanımlayabilir.

---

# 48. Kampanyalı Fiyat

Ürün:

- normal fiyat
- kampanya fiyatı
- başlangıç
- bitiş

alanlarını destekler.

Gerekirse normal fiyat üstü çizili, kampanya fiyatı gösterilir.

Fiyat geçmişi korunur.

---

# 49. Favoriler

Üye kullanıcı ürünleri favoriye ekleyebilir.

Favoriler hesap alanından görüntülenebilir.

---

# 50. Tekrar Satın Al

Önceki siparişlerden tekrar satın alma akışı desteklenir.

Mevcut fiyat/stok/varyant geçerliliği yeniden doğrulanır.

---

# 51. İade ve İptal

Müşteri iki yoldan talep oluşturabilir:

1. Hesap / sipariş takip ekranı
2. İletişim kanalı

Kargoya verilmeden:

- `İptal Talebi`

Kargoya verildikten sonra:

- `İade Talebi`

akışı kullanılır.

Tam/kısmi iade teknik olarak ödeme sağlayıcısı desteklediği ölçüde mimaride mümkün olmalıdır.

---

# 52. Hakkımızda

Ton:

- kısa
- premium
- marka merkezli

Hikâye yapısı:

```text
2017 marka başlangıcı
→ 2020/2021 işin operasyonel başlangıcı
→ kavurmahane
→ Akademi
→ bugün
```

Kurucular/ortaklar marka önüne çıkarılmayacaktır.

Kişisel profil/fotoğraf zorunlu değildir.

---

# 53. Kavurmahane

İlk sürümde ayrı route zorunlu değildir.

`Hakkımızda` sayfasında güçlü bir bölüm olarak yer alır.

---

# 54. Larante Akademi

Akademi ana sayfada ve kendi alanında güçlü konumlandırılır.

Hizmetler:

- Barista Eğitimi
- Kahve ve Demleme Eğitimi
- İşletme Kurulum Desteği
- Menü / Reçete Geliştirme
- Ekipman Kullanım Eğitimi
- Personel Eğitimi

Yeni eğitim türleri admin tarafından eklenebilir.

---

# 55. Akademi Hedef Kitlesi

Eğitimler:

- işletmelere
- çalışanlara
- son tüketicilere
- bireysel kahve meraklılarına

açık olabilir.

---

# 56. Akademi Takvimi

Public takvimde uygun alanlar:

- eğitim
- tarih
- saat
- lokasyon
- kontenjan/doluluk gösterimi uygun olduğu ölçüde
- başvuru durumu

Admin tarafından yönetilir.

---

# 57. Akademi Başvuru Formu

Alanlar:

- eğitim türü
- tarih
- ad soyad
- telefon
- e-posta
- şehir
- işletme adı — opsiyonel
- katılımcı sayısı
- not

Başvuru sonrası uygun bildirim gönderilir.

---

# 58. Akademi Online Ödeme

V1'de Akademi başvurusunun e-ticaret checkout'una bağlanması zorunlu değildir.

Mimari daha sonra:

```text
AcademyBooking
→ PaymentProvider
```

eklenebilecek şekilde genişlemeye açık olmalıdır.

---

# 59. Katalog

Ana navigasyonda `Katalog` route'u bulunur.

Doğrudan PDF'ye atlamak yerine:

```text
Katalog Sayfası
→ İncele
→ PDF Aç / İndir
```

akışı kullanılır.

Katalog PDF admin panelinden değiştirilebilir.

---

# 60. Numune Talebi

Ayrı form bulunur.

Önerilen alanlar:

- ad soyad
- telefon
- e-posta
- şehir
- işletme adı
- işletme türü
- ilgilenilen ürün grubu
- yaklaşık aylık tüketim
- açıklama
- beni satış temsilcisi arasın

---

# 61. Teklif Talebi

Numune formundan ayrı tutulur.

Ürün, miktar ve işletme bilgileri daha detaylı alınabilir.

---

# 62. Lead Yönetimi

Numune ve teklif talepleri admin panelinde lead olarak görünür.

Durumlar:

```text
Yeni
Arandı
Görüşülüyor
Numune Gönderildi
Teklif Verildi
Kazanıldı
Kaybedildi
```

Durumlar gelecekte yapılandırılabilir.

---

# 63. Lead Bildirimleri

Yeni lead:

- admin panelinde görünür
- ortaklara e-posta / panel bildirimi gider
- kritik yapılandırmada SMS kullanılabilir

---

# 64. WhatsApp

Tüm sitede sağ altta sabit WhatsApp aksiyonu bulunur.

Hazır başlangıç mesajı kullanılabilir:

> Merhaba, Larante ürünleri hakkında bilgi almak istiyorum.

Checkout'ta dikkat dağıtmaması için görsel önceliği düşürülebilir.

---

# 65. İletişim Sayfası

İçerir:

- iletişim formu
- kavurmahane bilgisi
- Akademi bilgisi
- telefon
- e-posta
- çalışma saatleri
- harita
- WhatsApp
- satış temsilcisi talebi

---

# 66. İçerik Türleri

Düzenli içerik:

- Kahve Rehberi
- Reçeteler
- Akademi İçerikleri
- İşletmeler İçin İpuçları

---

# 67. Reçeteler

Reçeteler:

- fotoğraf
- video
- gramaj
- hazırlama adımları
- kullanılan Larante ürünleri

içerebilir.

CTA:

> Bu reçetedeki ürünleri sepete ekle

desteklenir.

---

# 68. İçerik Yönetimi

Admin akışı:

```text
Taslak
→ Önizleme
→ Yayınla
```

İçerik kişiler yerine marka imzasıyla yayınlanabilir:

- Larante Coffee Roastery
- Larante Akademi

---

# 69. Newsletter

E-posta bülteni bulunur.

Abonelik:

- üyelikten bağımsız olabilir
- açık izin mantığı kullanır
- kullanıcı kolayca abonelikten çıkabilir

Konular:

- yeni reçeteler
- ürünler
- Akademi eğitimleri
- uygun kampanyalar

---

# 70. SEO Yönetimi

Ürün/içerik sayfalarında yönetilebilir:

- SEO title
- meta description
- slug
- sosyal medya görseli

Global:

- sitemap
- robots
- canonical
- Open Graph
- uygun structured data

---

# 71. Şehir Bazlı SEO

Kayseri/Nevşehir adına spam veya yapay şehir landing page'leri oluşturulmayacaktır.

Bölgesel bilgiler doğal kurumsal içerikte yer alabilir.

---

# 72. Marka Dili

Ton:

> **Premium ama ulaşılabilir; teknik bilgiyi sade anlatan.**

Ne aşırı kurumsal ve soğuk, ne de aşırı günlük olacaktır.

---

# 73. Görsel Tasarım Dili

Ana yaklaşım:

- açık beyaz / kırık beyaz
- siyah / füme
- sıcak kahve tonları
- kontrollü metalik vurgular

Premium ancak soğuk olmayan görünüm.

---

# 74. Animasyon Dili

Ana Hero sekansı dışında:

- yumuşak fade
- hafif slide
- hover geçişleri
- kontrollü parallax

Ağır 3D ve gereksiz gösterişli animasyon kullanılmaz.

`prefers-reduced-motion` desteklenir.

---

# 75. Footer

Footer alanları:

- Hızlı Linkler
- Ürünler
- Akademi
- Kurumsal
- Yasal
- Sosyal Medya
- Bülten
- Ödeme bilgileri
- Kargo bilgileri

---

# 76. Admin Panel — Genel

Admin panel ilk sürümün resmi parçasıdır.

İlk aktif kullanıcılar ortaklardır.

Buna rağmen rol sistemi baştan desteklenir.

---

# 77. Admin Roller

```text
Yönetici
Satış
Depo
İçerik
Finans
```

## Yönetici

Tüm alanlar.

## Satış

- sipariş
- müşteri
- teklif
- numune
- lead

## Depo

- stok
- hazırlama
- kargo

## İçerik

- ürün içerikleri
- görseller
- katalog
- Akademi
- yayın içerikleri

## Finans

- ödeme
- havale
- finansal raporlar

Rol ve izinler server tarafında enforce edilir.

---

# 78. Admin 2FA

Admin hesaplarında 2FA zorunludur.

Sadece arayüzde rol kontrolü güvenlik kabul edilmez.

---

# 79. Ürün Yönetimi

Admin:

- ürün ekler
- düzenler
- pasife alır
- kategori belirler
- fotoğraf/video yönetir
- açıklama yönetir
- tadım ve teknik bilgileri yönetir
- varyantları yönetir
- fiyatları yönetir
- kampanya fiyatını yönetir
- SEO alanlarını yönetir

---

# 80. Stok Yönetimi

Admin görebilir:

- mevcut stok
- rezerve stok
- kullanılabilir stok

Public kullanıcı kesin adet görmez.

---

# 81. Manuel Stok Hareketi

Manuel stok değişikliğinde sebep zorunludur.

Örnek nedenler:

- Üretim
- Sayım Düzeltmesi
- Fire
- Hasar
- İade
- Manuel Düzeltme

İşlem Audit Log'a yazılır.

---

# 82. Fiyat Geçmişi

Fiyat değişiklikleri geçmişte tutulur.

En az:

- eski fiyat
- yeni fiyat
- değişim zamanı
- değiştiren kullanıcı

takip edilebilir.

---

# 83. Sipariş Yönetimi

Admin:

- siparişleri listeler
- detay açar
- ödeme durumunu yönetir
- hazırlama durumunu değiştirir
- takip numarası girer
- iptal/iade akışını yönetir

---

# 84. Kargo Takip Numarası

Takip numarası girildiğinde:

- sipariş `Kargoya Verildi` olur
- e-posta gönderilir
- SMS gönderilir
- müşteri hesabında takip görünür

---

# 85. Admin Müşteri Ekranı

B2C müşteri için:

- ad soyad
- telefon
- e-posta
- kayıt tarihi
- toplam sipariş
- toplam harcama
- ortalama sepet
- son sipariş
- sipariş geçmişi
- favoriler
- kupon kullanımları
- iade talepleri

görülebilir.

B2C müşteri kaydı B2B müşteri domainiyle otomatik aynı kayıt sayılmaz.

---

# 86. Admin Satış Dashboard'u

En az:

- Bugünkü Ciro
- Aylık Ciro
- Sipariş Sayısı
- Ortalama Sepet
- Yeni Müşteri
- Tekrar Satın Alan Müşteri
- En Çok Satan Ürünler
- En Çok Satan Kategoriler
- Kupon Kullanımı
- İade Oranı
- Ödeme Yöntemi Dağılımı

---

# 87. Öne Çıkan Ürün Yönetimi

Ana sayfa öne çıkan ürünler admin tarafından manuel seçilebilir.

---

# 88. Akademi Admin

Admin:

- eğitim oluşturur
- tarih/saat düzenler
- lokasyon tanımlar
- kontenjan yönetir
- başvuruları görüntüler
- eğitimi kapatır/pasife alır

---

# 89. Katalog Admin

Yeni katalog PDF admin panelinden yüklenebilir.

Public katalog sayfası güncel dosyaya yönelir.

---

# 90. Site Ayarları

Admin tarafından yönetilebilir:

- WhatsApp
- IBAN
- ücretsiz kargo limiti
- iletişim bilgileri
- sosyal medya hesapları
- uygun genel site ayarları

---

# 91. Audit Log

Kritik işlemler kaydedilir.

Örnek:

- fiyat değişimi
- stok değişimi
- sipariş iptal/iade
- ödeme durumu
- kullanıcı/rol değişimi
- site kritik ayarları
- Akademi kritik değişiklikleri

Audit kayıtları fiziksel olarak sıradan UI ile silinemez.

---

# 92. Güvenlik Logları

Kaydedilebilir:

- başarısız admin girişleri
- yeni/şüpheli oturum
- kritik ayar değişimi
- yetkisiz erişim denemeleri

Parola/token gibi sırlar loglanmaz.

---

# 93. Admin Bildirimleri

Ortaklara uygun kanallardan:

- yeni sipariş
- yeni numune talebi
- yeni teklif talebi
- Akademi başvurusu
- kritik ödeme/sipariş hatası
- ciddi sistem arızası

bildirilebilir.

---

# 94. Analytics — Ana İlke

Gerçek ticari veri kaynağı:

> **Larante veritabanı ve Internal Commerce Analytics**

GA4 muhasebe/sipariş master kaynağı değildir.

---

# 95. Internal Commerce Analytics

Admin ekranında en az:

- ciro
- sipariş
- ortalama sepet
- dönüşüm oranı
- sepete ekleme oranı
- checkout terk oranı
- en çok görüntülenen ürün
- en çok satılan ürün
- yeni/tekrar müşteri
- numune talepleri
- teklif talepleri
- Akademi başvuruları
- trafik kaynakları

uygun olduğu ölçüde gösterilebilir.

---

# 96. GA4

Kullanıcı davranışı ve e-ticaret funnel ölçümü için kullanılır.

Event örnekleri:

```text
productViewed
productAddedToCart
checkoutStarted
purchaseCompleted
leadSubmitted
sampleRequested
academyApplicationSubmitted
```

---

# 97. Search Console

Google organik görünürlüğünü ölçmek için zorunludur.

---

# 98. Meta Pixel

- altyapı hazır olabilir
- Meta reklamı aktif olduğunda etkinleştirilir
- pazarlama iznine tabidir
- V1'de kullanılmıyorsa gereksiz script yüklenmez

---

# 99. Analytics Event Layer

Uygulama GA4 veya Meta'ya doğrudan her componentten bağlanmaz.

Sağlayıcı bağımsız bir event layer bulunur.

```text
Domain / UI Event
↓
Analytics Event Layer
├── Internal
├── GA4
└── Meta — koşullu
```

---

# 100. Server-side Tagging

İlk sürümde server-side GTM/tagging zorunlu değildir.

İhtiyaç ve hacim oluşursa ayrıca değerlendirilir.

---

# 101. Çerez ve İzin Yönetimi

Kategoriler:

- Zorunlu
- Analitik
- Pazarlama

Analitik ve pazarlama tracker'ları kullanıcı iznine göre çalışır.

İzin tercihleri kayıt altına alınabilir ve değiştirilebilir.

---

# 102. Yasal E-Ticaret Akışları

Checkout ve gerekli formlarda uygulanacak içerikler arasında:

- Mesafeli Satış Sözleşmesi
- Ön Bilgilendirme Formu
- KVKK / Aydınlatma
- gerekli açık rıza / ticari ileti izinleri

bulunur.

Nihai metinler hukuk/mali müşavir kontrolünden geçirilmelidir.

---

# 103. E-posta

Transactional e-posta Larante alan adından gönderilir.

Örnek adresler:

```text
siparis@larantecoffee.com
akademi@larantecoffee.com
```

SPF, DKIM ve DMARC düzgün yapılandırılmalıdır.

---

# 104. SMS

SMS tek sağlayıcıya bağımlı değildir.

`SmsProvider` adapter yapısı kullanılır.

Sağlayıcı değiştirilebilir olmalıdır.

---

# 105. Yedekleme

- veritabanı günlük otomatik yedeklenir
- yedek saklama politikası tanımlanır
- geri yükleme prosedürü düzenli test edilir

Yalnız “backup var” olması yeterli kabul edilmez.

---

# 106. Hata Bildirimleri

Kritik örnekler:

- ödeme hatası
- sipariş oluşturulamaması
- stok tutarsızlığı
- SMS/e-posta sürekli hata
- ciddi uygulama hatası

Normal teknik hatalar panel/e-posta ile; iş kaybı riski taşıyan kritik olaylar daha yüksek öncelikli uyarı üretir.

---

# 107. Performans

Mobile-first.

Hedef:

```text
Core Web Vitals: Good
LCP <= 2.5 s p75 hedefi
INP <= 200 ms
CLS <= 0.10
SEO Lighthouse: 95+ geliştirme hedefi
Accessibility: 90+ geliştirme hedefi
```

Lighthouse skorları garanti değil, release kalite hedefidir.

---

# 108. Hero Animasyon Fallback

Hareketli sekans:

- yüklenmese bile site kullanılabilir
- poster/fallback görseli olur
- checkout ve navigasyonu engellemez
- düşük bağlantı / düşük cihaz gücünde sadeleşebilir
- reduced-motion destekler

---

# 109. Arayüz Erişilebilirliği

Minimum:

- semantik HTML
- keyboard navigation
- focus visible
- uygun contrast
- doğru heading düzeni
- form label
- hata mesajlarının erişilebilir duyurusu
- görsel alt metni
- reduced-motion

---

# 110. B2B Giriş Sınırı

Public header üzerinden B2B uygulamasına geçiş yapılır.

Hedef URL yapısı:

```text
www.larantecoffee.com
b2b.larantecoffee.com
```

Public web B2B panelini iframe ile gömmez.

---

# 111. Web ve B2B Hesap Ayrımı

Aynı kişi her iki sistemde bulunabilir; ancak:

- web hesabı = B2C kimliği
- B2B hesabı = işletme/B2B kimliği

ticari olarak ayrı bağlamlardır.

Web oturumunda B2B fiyatı otomatik gösterilmez.

Gelecekte SSO ayrı kararla eklenebilir.

---

# 112. Product / Inventory Ortaklığı

Uzun vadeli hedef:

- ürün ve stok için tek yetkili kaynak
- kanallara göre fiyatlandırma
- web ve B2B arasında stok çakışmasının önlenmesi

Mevcut B2B repository doğrulanmadan duplicate product/inventory master kurulmaz.

---

# 113. Kargo Entegrasyonu — Gelecek

V1 manuel.

Gelecekte:

```text
ShippingProvider
├── ManualShippingAdapter
└── CarrierApiAdapter
```

---

# 114. Ödeme / SMS / Analytics Sağlayıcı Bağımsızlığı

Aşağıdaki sistemler adapter/port arkasında olmalıdır:

- PaymentProvider
- SmsProvider
- EmailProvider
- ShippingProvider
- AnalyticsProvider

---

# 115. V1'de Açıkça Yapılmayacaklar

- şehir bazlı spam SEO sayfaları
- referans müşteri logo vitrini
- donuk ürün satışı
- otomatik e-fatura/e-arşiv kesimi
- zorunlu üyelik
- web mağazasında B2B fiyatı
- public kesin stok adedi
- B2B panelini iframe ile gömme
- ilk günden kargo API entegrasyonu
- ilk günden server-side GTM
- ilk günden Akademi online checkout zorunluluğu
- mikroservis mimarisi
- duplicate ürün/stok master kaynağı

---

# 116. V1 Sonrası Adaylar

- kargo API entegrasyonu
- Akademi online ödeme
- Google/social login
- telefon OTP
- B2B/Web SSO
- daha gelişmiş recommendation motoru
- özel arama servisi
- server-side tagging
- gelişmiş CRM entegrasyonu
- otomatik e-fatura/e-arşiv

---

# 117. Launch Kabul Kriterleri — Fonksiyonel

Launch öncesi en az:

- [ ] ürünler admin'den yönetilebiliyor
- [ ] ürün kategorileri çalışıyor
- [ ] kahve varyant seçimleri çalışıyor
- [ ] stokta yok davranışı doğru
- [ ] guest checkout çalışıyor
- [ ] üye checkout çalışıyor
- [ ] kart/3D sağlayıcı entegrasyonu test edilmiş
- [ ] havale akışı ve 24 saat rezervasyon çalışıyor
- [ ] sipariş durumları çalışıyor
- [ ] e-posta + SMS bildirimleri çalışıyor
- [ ] manuel kargo takip akışı çalışıyor
- [ ] misafir sipariş takip çalışıyor
- [ ] favori çalışıyor
- [ ] tekrar satın al çalışıyor
- [ ] kupon çalışıyor
- [ ] kampanya fiyatı çalışıyor
- [ ] yorum moderasyonu çalışıyor
- [ ] numune formu çalışıyor
- [ ] teklif formu çalışıyor
- [ ] lead ekranı çalışıyor
- [ ] Akademi takvimi çalışıyor
- [ ] Akademi başvurusu çalışıyor
- [ ] içerik yayınlama çalışıyor
- [ ] katalog yönetimi çalışıyor
- [ ] admin 2FA çalışıyor
- [ ] rol/izin kontrolleri server-side çalışıyor
- [ ] Audit Log kritik işlemleri kaydediyor

---

# 118. Launch Kabul Kriterleri — Teknik

- [ ] production build geçiyor
- [ ] TypeScript strict geçiyor
- [ ] lint geçiyor
- [ ] unit/integration testler geçiyor
- [ ] E2E kritik akışlar geçiyor
- [ ] ödeme webhook idempotency test edilmiş
- [ ] oversell senaryosu test edilmiş
- [ ] havale timeout test edilmiş
- [ ] stok tek kaynak kuralı doğrulanmış
- [ ] admin yetkisiz erişim test edilmiş
- [ ] rate-limit kritik endpointlerde aktif
- [ ] backup oluşturma test edilmiş
- [ ] restore testi yapılmış
- [ ] security headers aktif
- [ ] cookie consent doğru çalışıyor
- [ ] analitik izin olmadan pazarlama scripti çalışmıyor
- [ ] sitemap/robots/canonical doğru
- [ ] mobil checkout test edilmiş
- [ ] accessibility kritik kontrolü tamamlanmış
- [ ] Core Web Vitals hedefleri değerlendirilmiş
- [ ] ana Hero fallback ile çalışıyor

---

# 119. Ana İş Kuralı Guardrails

## R1
Public web fiyatı ile B2B fiyatı birbirine karıştırılmaz.

## R2
Web ve B2B için iki ayrı gerçek stok master'ı oluşturulmaz.

## R3
Public kullanıcı stok adetini görmez.

## R4
Öğütüm tercihi gereksiz SKU/stok patlamasına yol açmamalıdır.

## R5
Sepet server doğrulaması olmadan siparişe dönüşmez.

## R6
Client tarafından gönderilen fiyat güvenilir veri kabul edilmez.

## R7
Ödeme callback/webhook'ları idempotent işlenmelidir.

## R8
Admin kritik yetkileri yalnız UI gizleme ile korunamaz.

## R9
Audit Log kritik işlemlerde zorunludur.

## R10
Analytics gerçek finansal source of truth değildir.

## R11
Bildirim servisindeki hata sipariş verisini kaybettirmemelidir.

## R12
Mevcut B2B kodu doğrulanmadan stok/product ownership varsayımı yapılmaz.

---

# 120. Sonuç

Larante Web Platform V1 aşağıdaki ana ürünlerden oluşacaktır:

```text
1. Premium Kurumsal Web
2. B2C E-Ticaret
3. Müşteri Hesabı
4. Ürün & Katalog Deneyimi
5. Larante Akademi
6. Reçete / İçerik Platformu
7. Numune / Teklif / Lead Yönetimi
8. Admin Panel
9. Stok / Sipariş / Kargo Operasyonu
10. Internal Analytics + GA4 + Search Console
11. B2B Geçiş ve Entegrasyon Sınırı
```

Bu dokümandan sonraki teknik uygulama kaynağı:

`LARANTE_WEB_ALTYAPI_MIMARISI_V2.md`

Tasarım uygulamasından önce hazırlanması gereken sonraki ürün dokümanı:

`LARANTE_DESIGN_SYSTEM.md`
