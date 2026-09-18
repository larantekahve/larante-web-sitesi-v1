# Larante Web — Codex Handoff

## Amaç ve ana dokümanlar

Larante Web Platformu; kurumsal web sitesi, B2C e-ticaret, admin panel, Akademi, lead/içerik yönetimi ve mevcut B2B ile ortak ürün/stok mantığını kapsıyor.

Proje klasöründeki iki ana doküman:

1. `LARANTE_WEB_REQUIREMENTS.md` — Onaylanmış iş gereksinimleri; ne yapılacağını belirler.
2. `LARANTE_WEB_ALTYAPI_MIMARISI_V2.md` — Hedef mimari; mevcut B2B hakkındaki teknik varsayımları gerçek repository üzerinden doğrulanmalıdır.

Dokümanlar proje klasörüne alındı; önceki yerleşim önerisi `docs/` idi. Bu handoff, iki dokümanın ve Claude planının yerine geçmez.

## Onaylanan geliştirme iş akışı

Her faz için:

**Claude Code Plan Mode → Codex plan denetimi → onaylı plan → Claude Code Implement + testler → Codex kod/test/rapor denetimi → Claude düzeltmeleri → Codex regresyon ve final denetimi → sonraki faz.**

- Claude'un planı ana plandır. Codex bulguları değerlendirilip onaylanan düzeltmeler bu plana işlenir; her turda gereksinimleri değiştiren yeni bir prompt oluşturulmaz.
- Kodlamadan sonra otomatik olarak Plan Mode'a dönülmez. Mimari bir sorun bulunursa plan revizyonu ve yeniden Codex denetimi yapılır.
- Codex yalnız uygulama raporunu değil, gerçek kodu ve testleri de inceler.
- Claude'un planlama ve kodlama oturumları aynı ana proje klasörünü kullanır; planlama oturumu kaynak dosyalarını değiştirmez.

## Şu anki durum ve audit kapsamı

Claude Code şu anda **Plan Mode'da salt-okunur repository audit'i ve master implementation planı** hazırlıyor. **Bu çalışma kapsamında henüz kod yazılmadı; implementasyon başlamadı.** Audit sırasında kaynak dosyası değişikliği, migration çalıştırma veya dependency kurulumu yapılmayacak. Plan tamamlandığında onay bekleniyor.

Mevcut B2B olarak seçilen repository, önceki konuşmada şu yolla belirtildi:

```text
Desktop\Larante Web Sitesi\b2b-portal\larante-b2b\app
```

Şunlar da **salt-okunur bağlam** olarak kapsama alındı:

- Önceki `larante-web` denemesi.
- Eski `Larante Web Sitesi/larante-site` projesi.
- İki eski B2B analiz Markdown dosyası; tam dosya adları konuşmada belirtilmedi.

Mevcut sistemin teknik doğruluk kaynağı gerçek B2B repository'sidir. Eski projeler ve analizler yalnız referans ve yeniden kullanım adayıdır; kararları otomatik taşınmaz. Modüller **KEEP / REFACTOR / REBUILD** gerekçeleriyle değerlendirilir.

Claude'un aktarılan ilk bulguları, mimarideki Node/Express/Prisma/PostgreSQL varsayımı yerine Bun, TanStack Start, Cloudflare Workers, D1/SQLite, R2, 21 SQL migration, tenant altyapısı ve CI bulunduğu yönünde. **Bunlar bu handoff hazırlanırken bağımsız doğrulanmadı; audit kanıtlarıyla kontrol edilmeli.**

## Codex'in ilk görevi

**Claude'un tamamlanan planını adversarial olarak, yani yanlış varsayımları ve kırılma senaryolarını arayarak denetle. İlk görev implementasyon değildir.**

İki ana dokümanı, Claude planını ve ilgili repository kanıtlarını okuyarak özellikle şunları kontrol et:

- Product/Inventory sahipliği, tek ürün ve stok kaynağı, B2B–B2C sınırları.
- Hedef mimari ile gerçek sistem arasındaki uyumsuzluklar; gereksiz rewrite, framework/ORM çoğalması.
- Stok yarış koşulları ve fazla satış, ödeme/webhook idempotency, transaction ve veri bütünlüğü.
- Auth/RBAC, tenant izolasyonu, fiyat sızıntısı ve sunucu tarafı yetkilendirme.
- Faz sırası, bağımlılıklar, migration/rollback, testler ve kabul kriterleri.

Çıktı: önem derecesi, kanıt, etki ve çözüm yönü içeren bulgular; kodlamayı engelleyen kararlar; ana plana işlenecek düzeltmeler ve net Phase 0 kapsamı. Doğrulanamayan noktaları açıkça belirt. Product/Inventory sahipliği netleşmeden commerce geliştirmesine geçilmemeli.

Claude planı henüz sunulmadıysa denetim tamamlanmış sayılmaz; planın paylaşılması gerekir.

## Durum — 2026-09-16 (dal `docs/stok-b2b-v2-1`, yalnız dokümantasyon)

2026-09-16 Codex (GPT-6 Astra, high) doküman denetimi **REVISE** verdi (10 yüksek + 8 orta bulgu). Aynı gün proje sahibi stok ve B2B sipariş-rezervasyon iş kurallarını onayladı; bu kurallar dokümantasyona işlendi. **Kod yazılmadı; implementasyon başlamadı.**

Bu revizyonda yapılanlar:

- `docs/adr/ADR-016-inventory-reservation-contract.md` (YENİ, TASLAK): stok miktar modeli (fiziksel / rezerve / kullanılabilir), tamsayı birim, B2B rezervasyon yaşam döngüsü (gönderimde rezervasyon; süresiz; 24/48/72 saat eskalasyon), güvenli sipariş → rezervasyon akışı (kalıcı niyet, işlem kimliği, çitleme, kurtarma), tam varyant bağlama, donuk pasta kutu kuralı, miktar / varyant değişikliği, iptal değişmezliği, kimlik / idempotency, mutabakat. ARCH §100'deki "ADR-006" konusunu kapsar; deployment ADR'si **ADR-017** oldu.
- `LARANTE_WEB_REQUIREMENTS.md` v1.1: §31.1–31.8, §41–42, §51, §80–83, §117–118 maddeleri, R13–R17.
- `LARANTE_WEB_ALTYAPI_MIMARISI_V2.md` V2.1: §13, §16–17 (ledger ayrımı), §21–22, §25–26 (ödeme ≠ sevkiyat), §30, §62, §64, §87 (port yönü düzeltildi), §100–101 (faz haritası eşlemesi), §106. §5.4/§5.6 düzeltmesi hâlâ B10'da beklemede.
- `docs/plan/LARANTE_MASTER_PLAN_2026-09-15.md` rev. 1.1: §8, §9, §11, §14, §15, §18 (P0/P1/P5/P7/P7B kapıları), §19, §21 ve yeni **§23 denetim bulgu dispozisyonu**.
- `docs/adr/ADR-004` (§3.2/§3.4/§3.5/§3.7/§3.8/§3.9 ADR-016 ile hizalandı; §3.5 ve §3.7 istisnaları o tarihte onay bekliyordu — 2026-09-17'de B6h ile onaylandı, aşağıda), `ADR-015` §5–6, `ADR-001` ilgili listesi, `docs/decisions/PHASE0_KARAR_LISTESI.md` (B6b/B6c karar; B6e–B6i yeni; §E ertelenen bulgular).

Planın kendisi Codex plan denetiminden geçti (5 tur; son tur APPROVED). Değişen dokümanlar ayrıca bağımsız Codex çapraz denetimine sunulur; sonuç master plan §23'e işlenir.

**İkinci tur (aynı gün, 2026-09-16 — yalnız dokümantasyon, aynı dal, commit yok):** Codex inspect (`claudex-hvm78reh`, REVISE) kalan üç bulguyu bıraktı; bu tur yalnız onları ve proje sahibinin B6k kararını işledi. Revizyon planı Codex GPT-6 Astra (high) plan denetiminden geçti (4 tur; tur 1 operasyonel BLOCKED, tur 2–3 REVISE — PLAN-R01–R05 kabul edildi ve işlendi, tur 4 APPROVED).
- **B6k KARAR:** açık B2B siparişinin rezervasyonu siparişten bağımsız serbest bırakılmaz; iptal / ret + varsa cari ters kaydı + RELEASE tek, sipariş düzeyi, idempotent CANCEL op; bağımsız admin aksiyonu yok; mutabakat yalnız gerçek sahipsiz rezervasyonu → ADR-016 K5/4 + §7 U9 (kapandı), REQ §31.1 / §31.4 / R18, ARCH §17 / §87, master plan §9 / §14 / P5 / P7B / §19, PHASE0 B6k ☑, ADR-004 §3.9.
- **RV01 (kiracı kapsamı):** anlık görüntü ucu + tik uçtan uca tek `tenant_id` (`resolveRequestTenant` + kiracı / ortam bağlı `PLATFORM_INTEGRATION_KEYS`; kiracı-nitelikli `external_order_id`; `out_of_scope` ≠ `not_found`, DB'siz ve varlıktan bağımsız); platform mutasyon uçları ve idempotency aramaları principal → `external_tenant_id` + sahiplik kapısı; işlem kaydı iç `id` + ad-alanlı `operation_id` (`UNIQUE (namespace, operation_id)`), olaylar iç anahtara bağlı; `abandon` çağıran ad alanında mezar taşı → ADR-016 K2/4, K4/7, K4-R, K10/3–4, K11/2k, K11/2a, K11/3–4, K12/7, §6; ARCH §17 / §62 / §87; REQ §31.8 / §118; master plan §8 / §9 / §14 / §15 / P5 / P7B; ADR-004 §3.2; PHASE0 §B-2.
- **RV02 (tekrar sipariş):** kalıcı `variant_code` (= varyant düzeyi `products.id`) / `order_unit` / `order_qty` ile çözüm; `orders` GET projeksiyonu + `OrderItem` tipi; `conversion_factor` K1/3 kuralıyla; çözülemeyen satır "onay gerekli"; yeni `submission_id` / sipariş no / rezervasyon / `operation_id`; `source_order_id` yalnız izlenebilirlik; yeniden açma yok → ADR-016 K9/4, K12/6, §6; REQ §31.6; ARCH §87; master plan §9 / §15 / P7B.
- **RV03 (DB tamsayı guard'ları):** `0022` içinde mevcut REAL kolonlar (`order_items.qty`, `products.moq`, `products.box_count`) + yeni miktar kolonları için BEFORE INSERT / UPDATE tetikleyicileri (değer tabanlı predikat; 5 / 5.0 korunur), yeni tablolarda CHECK, alan bazlı pozitif / negatif-olmayan kural, kesirli legacy değerde ön-doğrulama abort (yuvarlama yok), 0.5 / 1.25 / 2.5 reddi testleri (gerçek `node:sqlite`) → ADR-016 K1/4, K12/1a, K12/3, §5, §6; ADR-004 §3.5; ARCH §62; REQ §118; master plan §15 / §17 / P7B; PHASE0 §B-3.
- Taze Codex inspect (tur 1, `claudex-ktqnp3y_`, REVISE) dört ek bulgu verdi ve hepsi işlendi: **IR01** ortam izolasyonu (preview / prod paylaşımlı D1 — entegrasyon, anlık görüntü ucu ve K4-R kurtarması yalnız `environment = production` dağıtımında; `order_reservation_ops.environment` damgası; ADR-016 K11/2k-vii, K12/6–7; ARCH §87; REQ §31.8; master plan §15 / §17 / P7B; PHASE0 §B-4), **IR02** web rezervasyon tekilliği (NULL içermeyen `inventory_reservations.namespace`, `UNIQUE (namespace, external_order_id, external_line_id) WHERE status = 'ACTIVE'`; ADR-016 K10/4; master plan §8; ADR-004 §3.2), **IR03** `out_of_scope` yanıt birliğine eklendi ve yükü tanımlandı (ADR-016 K11/2a), **IR04** yabancı sipariş niteleyicisi 422 / yabancı rezervasyon 404 ayrımı (ADR-016 K4/7, §6; master plan §15).
- Taze Codex inspect tur 2 (`claudex-phur529h`, REVISE, tek bulgu **IR05 high**): paylaşımlı D1'de non-prod dağıtımı eski `off` moduna zorlamak, bugünkü admin / bayi yazıcılarıyla (`admin-order-status`, `POST order`) prod siparişine yazmayı engellemez → düzeltme turu 2'de işlendi: non-prod dağıtım `off` değil **`environment_disabled`** modudur — sipariş / cari / rezervasyon mutasyonları dispatcher düzeyinde yan etkiden önce 403 (ADR-016 K4/8, K11/2k-vii, K12/6, §6; ADR-004 §3.8 / §5; ARCH §87; REQ §31.8; master plan §9 / §15 / P7B; PHASE0 §B-4). **Bu son düzeltme inspect bütçesi (2 tur) dolduğu için bağımsız denetimden geçmedi** — üçüncü bir taze inspect proje sahibi kararıdır.
- Değişen dosyalar: ADR-016, REQ, ARCH, master plan (§23'e RV01–RV03 / B6k dispozisyon tablosu), PHASE0 (B6k ☑; §B-2 / §B-3 ek sorular; §E değişmedi), ADR-004 (§3.2 / §3.5 / §3.9), bu dosya. ADR-001 / ADR-015 bu turda değişmedi. **Kod yok.** *(Güncelleme 2026-09-17: bu ikinci tur belgeleri `9eee7eb` ile commit edildi ve PR #1 ile `main`'e birleşti — `a303130`.)*

**Codex'in bir sonraki görevi (ikinci tur):** taze bir inspect oturumunda (base `c133684`) RV01–RV03 kapanışını ve B6k tutarlılığını doğrula — kiracı kapsamı uçtan uca (uç, sorgu, kurtarma, sonuçlandırma, audit, dönen satırlar; platform mutasyon / idempotency sahipliği; ad-alanlı işlem kimliği ve `abandon` mezar taşı), tekrar sipariş yolunun projeksiyon / tip / dönüşüm kurallarıyla tamamlığı, `0022` guard'larının rebuild'siz uygulanabilirliği ve test listesi, B6k'nın tüm dokümanlarda aynı kuralı taşıması; PHASE0 §E'deki ertelenen bulgular yeniden açılmaz.

**Codex'in önceki görevi (ilk revizyon için, tamamlandı):** ADR-016'yı ve değişen bölümleri adversarial olarak denetle — özellikle: fiziksel ↔ rezerve ayrımının tüm dokümanlarda aynı anlamı taşıması; `rezervasyon_bekliyor → onay | rezervasyon_basarisiz` geçişleri; işlem kimliği / çitleme / kurtarma yürütücüsü; kredi taahhüdü ve cari kayıt sırası; varyant düzeyi dış kodlar; tamsayı kısıtları; faz kapılarının REQ / ARCH / plan / ADR / karar listesi arasında tutarlılığı; çelişkili ya da çift kural.

**Açık iş kararları (bu revizyon karar vermedi; B6k 2026-09-16'da karara bağlandı — yukarıda):** B6a eşleme tablosu, B6d sayım tarihi, B6e "yalnız koli" listesi, B6f eskalasyon aktörü / saat, B6g shortage politikası, B6h ADR-004 istisnaları, B6i maliyet kaynağı, B6j iptal edilmiş siparişe belge ekleme istisnası; ertelenen denetim bulguları F07, F08, F09, F10, F12, F13, F14, F15, F16 (kalan), F17, F18, H8, H10 (PHASE0 §E). *(2026-09-17: B6d / B6f / B6g / B6h / B6i ve B6a / B6e'nin kural kısmı aşağıdaki paketle karara bağlandı.)*

## Durum — 2026-09-17 (dal `docs/phase0-business-decisions-v2`, yalnız dokümantasyon)

Proje sahibi ikinci Phase 0 iş kararı paketini onayladı; bu tur yalnız o paketi kaydeder (base `a303130` = PR #1 merge). ADR-016 yetkili sözleşme olarak değişmeden korundu; PR #1 kararları yeniden açılmadı. Revizyon planı Codex GPT-6 Astra (high) denetiminden geçti (tur 1 REVISE — R01 `variant_key` kullanım tipi, R02 shortage yasağının web TTL / sahipsiz onarım önceliği, R03 B2B yüzeyi yetkilendirme blokajı; tur 2 APPROVED). **Kod, migration, SQL, paket ya da yapılandırma dosyası yok; commit yok.**

- **B6a / B6e — modelleme kuralı KARAR, veri AÇIK:** net içerik ≠ stok birimi; birim sınıfları PAKET (1 kg kahve — espresso / filtre ayrı SKU; 1 kg toz; 100 / 250 / 300 g çay) · ŞİŞE (750 ml şurup, 1 kg püre, 2,5 kg sos / baz) · ADET (6 kg demlik poşet çay, 2 L Frozen Lemonade / Orange Juice) · KUTU (donuk pasta: cheesecake / dilimli 12 dilim; mono / cup ürüne özgü, kategori geneli değer yok; kutu içi parça sayısı ≠ koli `box_count`; konfigürasyon değişince yeni SKU; satır snapshot) → ADR-016 K1/2–3, K6/2 (`variant_key` + `usage_type`), K7/5, U1 / U3; REQ §12–14, §19–21, §31.2–31.3; ARCH §13; master plan §11; PHASE0. **Kalan veri görevi:** somut satır → varyant eşleme tablosu (iki repoda da yok), kavrum ekseni (Light / Medium / Night), "Kanesh" / "Mercantily" kaynağı (B2B tohumunda yok), paket dışı satırlar, mono / cup kutu içi sayıları.
- **B6d — kural KARAR:** legacy `products.stock` / tahmin yok; SKU düzeyi fiziksel sayım; Depo sayar, Yönetici onaylar; audit; COUNT_ADJUSTMENT; tarih planlama → ADR-016 U2; ADR-004 §3.10, §6/5; REQ §81; master plan §17, P5.
- **B6f — KARAR:** saat ilk rezervasyon anından, onay sıfırlamaz; 72 saat yalnız Yönetici; sürdür / uzat audit; ret / iptal = B6k CANCEL op → ADR-016 K5/2–3, U4, K12/6; REQ §31.4, §77, §83; ARCH §26. **P7B yetkilendirme blokajı:** B2B yüzeyi rol eşlemesi AÇIK; ayrı sunucu yetkisi; aktör audit; onaysız reddet.
- **B6g — KARAR:** otomatik kısma / yeniden atama / serbest bırakma / iptal yok; tahsis blokajı; kritik uyarı; yalnız Yönetici; web TTL ve sahipsiz onarım önceliği korunur → ADR-016 K2/8, U5; REQ §31.1, §80; ARCH §16; master plan §23 F11 ÇÖZÜLDÜ.
- **B6h — ONAY:** ADR-004 §3.5 (additive fail-closed 0022) ve §3.7 (imzalı, kiracı + ortam kapsamlı salt-okunur snapshot) → ADR-004 §3.5 / §3.7 / §6/8; ADR-016 U7; master plan §9 / §17 / P7B. ADR-004 bütünü (B1) ve ADR-016 resmi onayı (B12) bu paketle verilmiş sayılmaz.
- **B6i — kaynak stratejisi KARAR:** V1 kontrollü Excel → tam varyant (fail-closed); sonra Logo yalnız SELECT; güncel maliyet + kaynak + son güncelleme; satır maliyet + fiyat snapshot'ı; donuk pasta SKU / kutu bazlı → ADR-016 U6, K7/5; ADR-004 §3.11; REQ §82; ARCH §90; master plan §11 / §13. **AÇIK:** B2B `order_items` maliyet / KDV snapshot'ı (0022 kapsamı).
- **B4d — KARAR:** KDV oranı V1 Excel → tam varyant (tahmin yok); sonra Logo malzeme kartı; satır snapshot → REQ §7.1; ARCH §21; master plan §4.2 / §11 / §19; B4a / B4b / B4c AÇIK.
- **B5 — KARAR:** public B2C donuk grup hariç; donuk grup B2B + paylaşımlı envanter; public'te "İşletmelere Özel" (Sepete Ekle yok; iletişim / teklif CTA); alt gruplar; taksonomi ≠ kanal uygunluğu → REQ §12, §19–21, §30, §31.3, §115, §117; ARCH §18, §20; master plan §19; PHASE0 B5a / B5b. **AÇIK:** Ekipman / Eğitim public'te; vitrin IA yeri; liste dışı satırlar.
- **B3 — yön KABUL:** www / admin / b2b; Platform / PostgreSQL yetkili; nesne depolama + CDN; transactional e-posta; B2B ayrı repo + sürümlü API; D1 yerel → PHASE0 B3; master plan §19; ARCH §4, §97; REQ §110. **AÇIK:** tüm sağlayıcı seçimleri (Postgres, hosting, storage / CDN, e-posta, SMS), TR/EU, DNS; ADR-001 / ADR-015 / ADR-017 resmi onayı.
- **Değişmeyen açık maddeler:** B1 (ADR-004 bütünü), B12 / ADR-016 resmi onayı, B2a, B4a–c, B6j, B7, B8a–e, B9, B10 (Logo alt kalemi yazılı teyit edildi; §5.4 / §5.6 beklemede), PHASE0 §E ertelenen bulgular (F07–F18, H8, H10).
- Değişen dosyalar: ADR-016, REQ (rev. 1.2), ARCH (V2.2 notu), master plan (§23 paket 2 tablosu), PHASE0, ADR-004, bu dosya. ADR-001 / ADR-015 değişmedi.

**Codex'in bir sonraki görevi (paket 2):** taze bir inspect oturumunda (base `a303130`) paketin belgeler arasında tutarlı kaydedildiğini, icat edilmiş karar olmadığını, ADR-016 kurallarının zayıflatılmadığını ve açık maddelerin doğru işaretlendiğini doğrula.
