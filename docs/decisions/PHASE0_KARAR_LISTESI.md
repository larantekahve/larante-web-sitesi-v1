# Phase 0 — Karar Listesi ve Dış Sorular

**Tarih:** 2026-09-15 · **Kaynak:** `docs/plan/LARANTE_MASTER_PLAN_2026-09-15.md` §19-21, `docs/adr/ADR-004`
**Kural:** Bu liste kapanmadan (veya maddeler "tarihli beklemede" olarak işaretlenmeden) ilgili faz başlamaz. Product/Inventory sahipliği (B1) netleşmeden commerce (Phase 4+) koduna geçilmez.

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
| B6a | **Varyant sınırı:** Cappadocia Light/Medium/Night ayrı ürün mü, kavrum varyantı mı? (Dashboard tek ad, skill 3 Logo kodu, B2B tek "Cappadocia Blend") | Öneri: tek Product + roast varyantı | Phase 4 | ☐ |
| B6b | **Stok birimi:** V1 = sellable variant (paket); B2B koli = qty × box_count adapter'da; bulk kg → paket dönüşümü ertelenir | Onay | Phase 5 | ☐ |
| B6c | **Rezervasyon anı (A-13):** B2B'de sipariş oluşturma anında (fail-closed); web kartta kısa TTL; havale 24 saat; yetersiz stokta B2B ret | Onay / değişiklik | Phase 5, 7B | ☐ |
| B6d | **Fiziksel sayım tarihi** (açılış stoğu `COUNT_ADJUSTMENT`) — hiçbir sistemde stok verisi yok | Tarih + sorumlu | Phase 5 | ☐ |
| B7 | **Sağlayıcılar:** PSP (iyzico / PayTR / diğer — 3DS, kısmi iade, webhook imzası), e-posta (transactional), SMS, S3-compatible storage + CDN | ADR-007 | Phase 6-7 | ☐ |
| B3 | **Platform hosting:** Postgres sağlayıcısı, veri yerleşimi (TR/EU), alan adı/DNS (`www` / `admin` / `b2b`), e-posta gönderim domain'i (SPF/DKIM/DMARC); mevcut Supabase "Larante Kahve" projesinin uygunluğu | ADR-016 | Phase 6, 12 | ☐ |
| B2a | **B2B barındırma:** Higgsfield'da mı kalınacak, kendi Cloudflare hesabına mı geçilecek? (CLAUDE.md §14/11) | Cevap Phase 7B'nin tek gerçek engelidir | Phase 7B, launch | ☐ |
| B8a | `LARANTE_DESIGN_SYSTEM.md` sahibi ve tarihi | — | Phase 2 (marka-yoğun kısım), 11 | ☐ |
| B8b | Kahve / Toz / Çay / Pasta **ürün fotoğrafları** (yalnız 94 Aroma görseli var, hepsi AI üretimi — REQ §23 gerilimi) — gerçek çekim mi, AI mockup mı? | — | Phase 4 içerik, launch | ☐ |
| B8c | REQ §18 kahve nitelik içerikleri (tadım/gövde/asidite/menşei/işleme/demleme) — hiçbir kaynakta yok | İçerik teslim planı | Phase 4 | ☐ |
| B8d | Hero kare dizisi 65-73 eksik; slogan yazımı ("True Maths. Perfect Coffee." vs varlıklarda noktasız) | — | Phase 11 | ☐ |
| B8e | Yayındaki e-katalog PDF arka kapağında kişisel e-posta → yeniden üretim | — | Phase 9 | ☐ |
| B9 | Skill Excel'leri (`urun_maliyet.xlsx` 216 Logo kodu, `satis_listesi.xlsx`) claude.ai oturum klasöründe → `data/` altına kopya + kaynak/tarih notu; `musteriler.xlsx` (teklif/iskonto kaydı) diskte yok — nerede? | — | Phase 4 | ☐ |
| B10 | Doküman hizalaması: ARCH V2.1 notu (§5.4 Node/Express, §5.6 Prisma, §87 port yönü); sipariş durum sözlüğü (web = REQ §43; B2B kendi sözlüğü); admin rol seti (web = REQ §77 5 rol); Logo V1 kapsam dışı + "Logo'ya yazma yok" yazılı teyidi | — | Phase 0 | ☐ |
| — | Proje klasörü adı ASCII (`larante-platform`) yapılsın mı? | Öneri: evet | Phase 1 | ☐ |
| — | `platform-api` framework: Hono (+zod-openapi) — ADR-scaffold | Öneri: Hono | Phase 1 | ☐ |

## B. Higgsfield'a yazılı sorular (B2)

1. **Egress:** B2B Worker'ı `wrangler.jsonc:38-41`'e göre "Outbound Worker" üzerinden çıkıyor ve `AGENTS.md:166-170` kimliği yalnız `https://fnf.internal`'a ekliyor. Worker **keyfi bir dış HTTPS host'a** (`api.larantecoffee.com` gibi) `fetch` yapabilir mi? Allowlist gerekiyor mu?
2. **Sır/servis token:** Worker'da secret tutulamıyorsa, dış bir API'ye servis token'ı ile kimlik doğrulamak için desteklenen mekanizma nedir?
3. **Migration uygulama:** `migrations/000N_*.sql` dosyaları deploy'da otomatik mi uygulanıyor (`0001_init.sql:1-2` "Applied by the platform on deploy") yoksa elle mi? Bekleyen 19 migration (0003-0021; DROP+CREATE rebuild içerir) tek deploy'da paylaşımlı prod D1'e koşar mı? Prova/rollback imkânı var mı?
4. **Deploy hattı:** `origin` (`apps-repos.higgsfield.ai`) şu an erişilebilir mi? Canlı `larante-b2b.higgsfield.app` hangi commit'i koşuyor (`bb2c415` MVP mi)? Preview/prod ayrımı ve ayrı D1 mümkün mü?

## C. Salt-okunur teknik doğrulamalar (Phase 0 içinde yapılacak)

- Canlı B2B: hangi commit, D1 migration seviyesi, `tenant_domains` dolu mu, `products.stock` gerçek değerleri, R2 içeriği (görsel/belge/fatura).
- B2B testlerinin çalıştırılarak geçtiği (B2B repo'da, izinle).
- `moq` sıfırlanma bug'ının çalıştırılarak teyidi.
- Supabase "Larante Kahve" projesinin içeriği (prod adayı mı?).

## D. Phase 0 çıkış kriteri
ADR-004 / ADR-001 / ADR-015 onaylı; Codex denetim bulguları plana işlendi; yukarıdaki tabloda her satır "karar" veya "tarihli beklemede"; B2/B3 beklemede olabilir (Phase 1-6'yı bloklamaz, Phase 7B ve launch'ı bloklar); Phase 1 görev dosyaları hazır.
