# Phase 0 — Karar Listesi ve Dış Sorular

**Tarih:** 2026-09-15 · **Revizyon:** 2026-09-16 (stok / B2B rezervasyon kararları; `docs/adr/ADR-016`) · **Kaynak:** `docs/plan/LARANTE_MASTER_PLAN_2026-09-15.md` §19-21, §23, `docs/adr/ADR-004`, `docs/adr/ADR-016`
**Kural:** Bu liste kapanmadan (veya maddeler "tarihli beklemede" olarak işaretlenmeden) ilgili faz başlamaz. Product/Inventory sahipliği (B1) netleşmeden commerce (Phase 4+) koduna geçilmez. **ADR-016, B6b, B6c ve B6e için "tarihli beklemede" kabul edilmez:** kalıcı stok ledger'ı (Phase 1 / Phase 5) bunlar karara bağlanmadan yazılmaz.

## A. Proje sahibi kararları

| # | Karar | Seçenekler / öneri | Bloke ettiği faz | Durum |
|---|---|---|---|---|
| B1 | **Product/Inventory sahibi** | Öneri: ARCH §3 Seçenek B (platform-api owner; B2B tüketici) — `docs/adr/ADR-004` | Phase 4+ | ☐ |
| B4a | **Hangi fiyat listesi güncel?** B2B `0006` (18 Ağu) / skill `satis_listesi.xlsx` (24 Ağu) / Dashboard `satis_fiyat_listesi_2026-09_2026-12.xlsx` (Eyl). Örnek: Çikolata Şurup 750ml 450 / 400 / 500; Filtre Cappadocia 1500 / 1800 | Tek liste seçilir, kaynağı `data/` altına kopyalanır | Phase 4 | ☐ |
| B4b | **B2B `list_price` KDV dahil mi hariç mi?** (kodda/migration'da yazmıyor) | — | Phase 4 | ☐ |
| B4c | **Perakende (B2C, KDV dahil) fiyat listesi** — hiçbir kaynakta yok | Proje sahibi hazırlar (variant bazında: gramaj × kavrum) | Phase 4 | ☐ |
| B4d | **Ürün bazlı KDV oranı kaynağı** (faturalarda %1: 2.195 satır, %20: 69 satır) | Logo malzeme kartından mı, ürün grubu kuralından mı | Phase 4 | ☐ |
| B5a | **Kategori taksonomisi:** REQ §12 (Kahve/Aroma/Toz/Çay) vs B2B 5'li (Aroma/Pasta/Kahve/Çay/Donuk) vs eski site (SOS/Pastalar/Ekipmanlar/Eğitim) | Öneri: REQ §12 üst kategoriler + `satis_listesi` alt grupları | Phase 4 | ☐ |
| B5b | "Aroma Grubu" mu "SOS" mu? Pasta (Gastro Cake, 3. taraf) ve Ekipman public sitede var mı? | — | Phase 4 | ☐ |
| B6a | **Varyant eşlemesi (veri):** Cappadocia Light/Medium/Night ayrı ürün mü, kavrum varyantı mı? (Dashboard tek ad, skill 3 Logo kodu, B2B tek "Cappadocia Blend"). **Kural karara bağlandı (ADR-016 K6):** her sipariş satırı tam bir varyanta bağlanır; dış kodlar varyant düzeyinde; çözülemeyen B2B satırı varyant başına ayrı satıra bölünür. **Açık kalan:** mevcut B2B satırlarının somut eşleme tablosu | Öneri: tek Product + roast varyantı; eşleme tablosu P4 import dry-run raporuyla onaylanır | Phase 4 import, Phase 7B | ☐ |
| B6b | **Stok birimi:** varyantın ticari stok birimi (paket / şişe / kutu / koli / adet), **tamsayı**; B2B koli yalnız tamsayı katı + sipariş satırında `box_count` snapshot'ı; donuk pasta = kutu (yarım / karışık kutu yok); bulk kg → paket dönüşümü V1 dışı | — | Phase 1 (ledger), Phase 4, Phase 5 | ☑ **KARAR 2026-09-16** — ADR-016 K1, K7 (ADR-016 onayıyla kilitlenir) |
| B6c | **Rezervasyon anı ve ömrü (A-13):** sepet rezerve etmez; B2B'de sipariş **gönderiminde** (kalıcı kayıtla, `rezervasyon_bekliyor` → `onay`), personel onayı beklenmez; **otomatik süre dolumu yok**; 24 saat uyarı / 48 saat yükseltilmiş uyarı / 72 saat yönetim kararı zorunlu, sessiz serbest bırakma yok; iptal terminal; yetersiz stokta `rezervasyon_basarisiz`. Web: TTL'li rezervasyon, ödeme başarısında kalıcılaşır, fiziksel düşüş sevkiyatta | — | Phase 1 (ledger), Phase 5, 7B | ☑ **KARAR 2026-09-16** — ADR-016 K3–K5, K9 (ADR-016 onayıyla kilitlenir) |
| B6d | **Fiziksel sayım tarihi** (açılış stoğu `ADJUST_UP` / COUNT_ADJUSTMENT) — hiçbir sistemde stok verisi yok | Tarih + sorumlu | Phase 5 | ☐ |
| B6e | **"Yalnız koli" satılan varyant listesi** ve varyant başına `box_count` / `stock_unit` değerleri (ADR-016 K1/3) | Veri tablosu (P4 import girdisi) | Phase 4, 7B | ☐ |
| B6f | **Eskalasyon aktörü ve saati:** 72 saat kararını hangi rol verir (varsayılan: Yönetici); personel onayı eskalasyon saatini sıfırlar mı? (ADR-016 U4) | Öneri: Yönetici; onay saati sıfırlamaz, açık uzatma kaydı gerekir | Phase 5 | ☐ |
| B6g | **Shortage politikası:** fiziksel kayıp sonrası `available < 0` olduğunda hangi rezervasyonlar kısılır (ADR-016 U5). **Karar verilene kadar** sistem yalnız kaydı tutar, yeni tahsisi engeller ve yönetim uyarısı üretir; rezervasyon kısma / seçim kuralı uygulanmaz | Aday seçenekler (uygulanmaz): en yeni rezervasyondan başlayarak; kanal önceliği | Phase 5 | ☐ |
| B6h | **ADR-004 istisnalarının onayı:** §3.5 (P7B'de bir additive D1 migration) ve §3.7 (platform → B2B imzalı salt-okunur mutabakat çekmesi) (ADR-016 U7) | Onay / ret | Phase 7B | ☐ |
| B6j | **İptal edilmiş / rezervasyonu başarısız siparişe belge veya fatura ekleme istisnası** gerekli mi? (ADR-016 U8; varsayılan: hayır, sipariş değişmez) | Hayır / evet + koşul | Phase 7B | ☐ |
| B6k | **Bağımsız manuel serbest bırakma:** açık B2B siparişinin (onay / üretimde / kalite) rezervasyonunu siparişi iptal etmeden serbest bırakmak izinli mi — **☑ KARAR 2026-09-16 (ADR-016 K5/4, §7 U9 kapandı):** izinli değil; rezervasyon serbest bırakılacaksa sipariş reddedilir / iptal edilir; iptal / ret + varsa cari ters kaydı + RELEASE **tek, sipariş düzeyi, idempotent CANCEL op**; siparişi açık bırakıp rezervasyonu düşüren / azaltan admin aksiyonu sunulmaz; deterministik mutabakat yalnız karşılığında gerçek sipariş olmayan teknik sahipsiz rezervasyonu serbest bırakabilir (K11/4) | Hayır (yalnız sipariş iptali / reddi) — **seçildi** | Phase 5 admin, 7B | ☑ |
| B6i | **Varyant satın alma maliyetinin kaynağı** (Logo / `urun_maliyet.xlsx` / platform) — donuk pasta varyant maliyeti dahil (ADR-016 U6) | B4/B9 ile birlikte | Phase 4 | ☐ |
| B7 | **Sağlayıcılar:** PSP (iyzico / PayTR / diğer — 3DS, kısmi iade, webhook imzası), e-posta (transactional), SMS, S3-compatible storage + CDN | ADR-007 | Phase 6-7 (storage/CDN Phase 4 — bkz. §E F16) | ☐ |
| B3 | **Platform hosting:** Postgres sağlayıcısı, veri yerleşimi (TR/EU), alan adı/DNS (`www` / `admin` / `b2b`), e-posta gönderim domain'i (SPF/DKIM/DMARC); mevcut Supabase "Larante Kahve" projesinin uygunluğu | ADR-017 (2026-09-16 öncesi "ADR-016") | Phase 6, 12 | ☐ |
| B2a | **B2B barındırma:** Higgsfield'da mı kalınacak, kendi Cloudflare hesabına mı geçilecek? (CLAUDE.md §14/11) | Cevap Phase 7B'nin tek gerçek engelidir | Phase 7B, launch | ☐ |
| B8a | `LARANTE_DESIGN_SYSTEM.md` sahibi ve tarihi | — | Phase 2 (marka-yoğun kısım), 11 | ☐ |
| B8b | Kahve / Toz / Çay / Pasta **ürün fotoğrafları** (yalnız 94 Aroma görseli var, hepsi AI üretimi — REQ §23 gerilimi) — gerçek çekim mi, AI mockup mı? | — | Phase 4 içerik, launch | ☐ |
| B8c | REQ §18 kahve nitelik içerikleri (tadım/gövde/asidite/menşei/işleme/demleme) — hiçbir kaynakta yok | İçerik teslim planı | Phase 4 | ☐ |
| B8d | Hero kare dizisi 65-73 eksik; slogan yazımı ("True Maths. Perfect Coffee." vs varlıklarda noktasız) | — | Phase 11 | ☐ |
| B8e | Yayındaki e-katalog PDF arka kapağında kişisel e-posta → yeniden üretim | — | Phase 9 | ☐ |
| B9 | Skill Excel'leri (`urun_maliyet.xlsx` 216 Logo kodu, `satis_listesi.xlsx`) claude.ai oturum klasöründe → `data/` altına kopya + kaynak/tarih notu; `musteriler.xlsx` (teklif/iskonto kaydı) diskte yok — nerede? | — | Phase 4 | ☐ |
| B10 | Doküman hizalaması: ARCH V2.1 notu (§5.4 Node/Express, §5.6 Prisma — **beklemede**; §87 port yönü — **2026-09-16'da düzeltildi**; §101 faz haritası — **2026-09-16'da eşlendi**); sipariş durum sözlüğü (web = REQ §43; B2B kendi sözlüğü + `rezervasyon_bekliyor` / `rezervasyon_basarisiz`); admin rol seti (web = REQ §77 5 rol); Logo V1 kapsam dışı + "Logo'ya yazma yok" yazılı teyidi | — | Phase 0 | ☐ (kısmen) |
| — | Proje klasörü adı ASCII (`larante-platform`) yapılsın mı? | Öneri: evet | Phase 1 | ☐ |
| — | `platform-api` framework: Hono (+zod-openapi) — ADR-scaffold | Öneri: Hono | Phase 1 | ☐ |
| — | **ADR-016 onayı** (stok miktar modeli, fiziksel/rezerve ayrımı, B2B rezervasyon yaşam döngüsü, tam varyant bağlama, tamsayı birim, idempotency, mutabakat) | `docs/adr/ADR-016` — Codex denetimi bekliyor | **Phase 1 (ledger), 4, 5, 7B** | ☐ |

## B. Higgsfield'a yazılı sorular (B2)

1. **Egress:** B2B Worker'ı `wrangler.jsonc:38-41`'e göre "Outbound Worker" üzerinden çıkıyor ve `AGENTS.md:166-170` kimliği yalnız `https://fnf.internal`'a ekliyor. Worker **keyfi bir dış HTTPS host'a** (`api.larantecoffee.com` gibi) `fetch` yapabilir mi? Allowlist gerekiyor mu? **Ek (F14):** çıkış IP adresleri sabit mi? Sabit değilse platform tarafında IP allowlist kurulamaz; imzalı istek / kısa ömürlü token tasarımı gerekir.
2. **Sır/servis token:** Worker'da secret tutulamıyorsa, dış bir API'ye servis token'ı ile kimlik doğrulamak için desteklenen mekanizma nedir? **Ek:** Worker'ın **gelen** isteği asimetrik imzayla (kaynağa gömülü açık anahtar) doğrulaması ve bunun için `POST /api/b2b/internal/reservation-snapshot` gibi cookie'siz bir uç sunması mümkün mü (ADR-016 K11)? İmza anahtarı kaynakta kiracı **ve** ortama (preview / prod) bağlı tutulacak (`PLATFORM_INTEGRATION_KEYS`; ADR-016 K11/2k) — ortam ayrımı platform tarafında da yapılabilir mi; kapsam dışı kimlik için `out_of_scope` yanıtı (varlık sızdırmaz) bu uçta sorun yaratır mı?
3. **Migration uygulama:** `migrations/000N_*.sql` dosyaları deploy'da otomatik mi uygulanıyor (`0001_init.sql:1-2` "Applied by the platform on deploy") yoksa elle mi? Bekleyen 19 migration (0003-0021; DROP+CREATE rebuild içerir) tek deploy'da paylaşımlı prod D1'e koşar mı? Prova/rollback imkânı var mı? **Ek:** P7B'de bir adet additive migration (`0022`, ADR-016 K12) aynı yolla uygulanabilir mi? `0022` DB düzeyi tamsayı guard tetikleyicileri (BEFORE INSERT / UPDATE) ve kesirli legacy değerde **ön-doğrulama abort'u** (migration durur, yuvarlama yok — ADR-016 K12/1a) içerir: abort eden bir migration deploy hattında nasıl raporlanır ve düzeltme sonrası yeniden uygulanabilir mi?
4. **Deploy hattı:** `origin` (`apps-repos.higgsfield.ai`) şu an erişilebilir mi? Canlı `larante-b2b.higgsfield.app` hangi commit'i koşuyor (`bb2c415` MVP mi)? Preview/prod ayrımı ve ayrı D1 mümkün mü? **Ek (ADR-016 K11/2k-vii):** ayrı D1 sağlanana kadar prod D1'ini paylaşan non-prod dağıtım `environment_disabled` modundadır — stok entegrasyonu, anlık görüntü ucu ve kurtarma kapalı **ve** sipariş / cari / rezervasyon mutasyonları (bugünkü admin / bayi yazıcıları dahil) reddedilir; dağıtımın kendi ortamını (`environment`) güvenilir biçimde bilmesi için hangi mekanizma var?
5. **Özel alan adı (H8):** `b2b.larantecoffee.com` Higgsfield'da desteklenir mi; B2B `tenant_domains` (fail-closed, tohumsuz) alan adı yönlendirilmeden önce nasıl tohumlanır?

## C. Salt-okunur teknik doğrulamalar (Phase 0 içinde yapılacak)

- Canlı B2B: hangi commit, D1 migration seviyesi, `tenant_domains` dolu mu, `products.stock` gerçek değerleri, R2 içeriği (görsel/belge/fatura).
- B2B testlerinin çalıştırılarak geçtiği (B2B repo'da, izinle).
- `moq` sıfırlanma bug'ının çalıştırılarak teyidi.
- Supabase "Larante Kahve" projesinin içeriği (prod adayı mı?).
- Mevcut B2B ürün satırlarının varyant düzeyine çözülebilirliği (kavrumsuz satırlar, aynı ürünün farklı ambalajları) — B6a eşleme tablosu girdisi.

## D. Phase 0 çıkış kriteri
ADR-004 / ADR-001 / ADR-015 / **ADR-016** onaylı; Codex denetim bulguları plana işlendi (master plan §23 dispozisyon tablosu); yukarıdaki tabloda her satır "karar" veya "tarihli beklemede" — **istisna: ADR-016, B6b, B6c, B6e "tarihli beklemede" olamaz** (Phase 1 kalıcı ledger'ını ve Phase 4/5/7B'yi bloklar; ADR-016 onaysızsa Phase 1 ledger'sız kapanır, ledger + concurrency testi Phase 5 başına kayar); B6a eşleme **kuralı** kabul edilmiş, veri eşlemesi Phase 4 import dry-run raporuyla kanıtlanır; B2/B3 beklemede olabilir (Phase 1-5'i bloklamaz, Phase 6 e-posta domain'i için B3'ün DNS kısmı, Phase 7B ve launch'ı bloklar); Phase 1 görev dosyaları hazır.

## E. Ertelenen denetim bulguları (2026-09-16 Codex doküman denetimi — karar paketi bekliyor)

Bu maddeler 2026-09-16 doküman revizyonunda **bilinçli olarak çözülmemiştir**; sessizce kapatılmış sayılmaz. Ayrıntı: master plan §23.

| Bulgu | Konu | Bloke ettiği | Karar paketi |
|---|---|---|---|
| F07 | P7B cutover runbook: geçiş öncesi B2B siparişlerinde commit edilecek rezervasyon yok; elle SALE kayıtlarının çift sayımı; watermark / mutabakat | Phase 7B canlıya alma | B2B geçiş paketi |
| F08 | Launch sonrası `INVENTORY_PORT=off` tek stok kuralını ihlal eder; koordineli degradasyon / mevcut rezervasyonların korunması / yeniden açmada mutabakat | Launch | B2B geçiş paketi |
| F09 | Ödeme webhook doğrulaması: event id dedup'ına ek tutar / para birimi / sipariş / deneme eşlemesi, tek settlement garantisi | Phase 7 | ADR-007 (PSP) |
| F10 | Misafir sipariş sahiplenme (claim) ve hassas sorgu için sipariş-bağlı sahiplik kanıtı | Phase 7/8 | Müşteri kimliği paketi |
| F12 | B2B ürün projeksiyonunun import sonrası yaşam döngüsü (yeni / değişen / arşivlenen ürünler) | Phase 4, 7B | Katalog paketi |
| F13 | Sipariş snapshot'ında teslimat adresi (fatura adresinden ayrı) ve toplam / kargo / vergi kalemleri | Phase 7 | Checkout paketi |
| F14 | IP allowlist sabit Worker egress'i varsayar; kaynak IP'ye bağımlı olmayan servis kimliği | Phase 5 sözleşme, 7B | Higgsfield cevabı + ADR-016 ek |
| F15 | B2B CI push tetiği ölü; contract sürüm / digest kontrolü ve iki deploy'u bağlayan release kapısı | Phase 7B release | B2B CI paketi |
| F16 (kalan) | B3 / B7'nin yetenek bazlı ayrımı (Phase 4 storage + CDN; Phase 6 e-posta domain'i) | Phase 4, 6 | Sağlayıcı paketi |
| F17 | Akademi kontenjanı katılımcı sayısıyla atomik düşmeli | Phase 9 | Akademi paketi |
| F18 | Internal analytics sink'i consent'siz davranışsal olay yazmamalı; operasyonel / davranışsal ayrımı | Phase 10 | Analytics paketi |
| H8 | `b2b.larantecoffee.com` özel alan adı ve `tenant_domains` tohumlama | Launch | Higgsfield cevabı |
| H10 | Kart rezervasyon TTL'i PSP 3DS oturum süresini aşmalı | Phase 7 | ADR-007 (PSP) |
