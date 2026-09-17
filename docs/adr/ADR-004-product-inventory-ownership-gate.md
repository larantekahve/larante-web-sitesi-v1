# ADR-004 — Product / Inventory Ownership Gate

**Durum:** TASLAK — proje sahibi onayı ve Codex adversarial denetimi bekliyor
**Tarih:** 2026-09-15 · **Değişiklik notu (2026-09-16, dal `docs/stok-b2b-v2-1`):** §3.2, §3.4, §3.5, §3.7, §3.8, §3.9, §4, §5, §6 ve §8 `docs/adr/ADR-016` (stok miktar modeli ve B2B rezervasyon sözleşmesi) ile hizalandı. §3.5 ve §3.7'deki istisnalar proje sahibi onayı bekler (ADR-016 §7 U7).
**Kaynaklar:** `LARANTE_WEB_REQUIREMENTS.md` §31, §112, R2, R12 · `LARANTE_WEB_ALTYAPI_MIMARISI_V2.md` §3 (Production Gate), §12-18, §87-89, §101 Faz 0, §107 G1/G2/G14 · `docs/plan/LARANTE_MASTER_PLAN_2026-09-15.md` §7-9
**Audit referansı:** B2B repo `C:\Users\Monster\Desktop\Larante Web Sitesi\b2b-portal\larante-b2b\app` — git HEAD `d75dc7d`, dal `refactor/tenant-foundation` (tüm satır referansları bu HEAD'e göredir)

---

## 1. Bağlam

REQ §31 "Web ve B2B aynı gerçek stok kaynağına bağlı olmalıdır; iki ayrı stok master'ı yasaktır" ve ARCH §3 "Dual Master Yok" kuralı, mevcut B2B repository audit'i yapılmadan Product/Inventory sahibinin varsayılmasını yasaklar (R12, G14). Bu ADR, salt-okunur audit'in kanıtlarıyla ARCH §3'teki üç seçenekten birini seçer.

## 2. Kanıt (bizzat dosya açılarak doğrulandı)

### 2.1 B2B'de envanter yoktur
| Kanıt | Yer |
|---|---|
| Stok yalnız `products.stock REAL NOT NULL DEFAULT 0` kolonu; ayrı inventory/movement/reservation tablosu yok (21 migration'daki CREATE TABLE listesi: settings, admins, dealers, sessions, products, orders, order_items, price_groups, product_docs, transactions, campaigns, audit_log, dealer_category_discounts, tenants, tenant_domains) | `migrations/0002_b2b.sql:7`; `migrations/0019_tenant_not_null_hardening.sql:262-278` |
| Sipariş oluşturma stoğu **okumaz**: SELECT listesi `id, name, category, unit, list_price, box_count, box_unit_price, moq` — `stock` yok | `src/routes/api/b2b/$action.ts:610-614` |
| Sipariş oluşturma stoğu **düşmez/rezerve etmez**: batch yalnız `INSERT INTO orders` + `INSERT INTO order_items`; `UPDATE products` yok | `$action.ts:712-726` |
| `stock` kolonuna yazan tek yer admin formundan mutlak değer ataması (delta/sebep yok) | `$action.ts:1086-1093` (UPDATE), `:1119-1127` (INSERT); `src/routes/admin.tsx:1523-1534` |
| Katalogda yalnız `in_stock: p.stock > 0` boolean; panelde "stok sorunuz" rozeti siparişi **engellemez** | `$action.ts:580`; `src/routes/panel.tsx:150-154, 679-686` |
| Seed'de tüm ürünler `stock=0`; yerel miniflare D1'de `stock>0` olan ürün: 0 | `migrations/0002/0004/0006` INSERT'leri; `app/.wrangler/state/v3/d1/...sqlite` |
| Stok/oversell/rezervasyon için test: 0 (17 test dosyası, 495 statik it) | `src/lib/b2b/__tests__/` |
| Cron/queue/KV/Durable Object yok → expiry/worker kurulamaz | `wrangler.jsonc` (triggers yok); `app.manifest.json {kv:false, durableObject:null}` |
| Dashboard (Python) ve skill Excel'lerinde stok kavramı yok; kodda Logo/ERP bağı yok | `Desktop\Dashboard\src\db\sema.sql`; grep `logo|erp` B2B src → 0 |

### 2.2 B2B Product modeli web gereksinimini taşıyamaz
| Kanıt | Yer |
|---|---|
| Tek düz tablo; `sku` boş; `category` düz string (FK yok, hiyerarşi yok); `unit` serbest metin; slug/SEO/medya/nitelik/KDV/fiyat geçmişi yok | `0019:262-278`; grep `kdv|vat|tax` → 0 |
| Varyant (gramaj/kavrum/öğütüm) kavramı yok; her gramaj ayrı satır | `0006` unit dağılımı (11 serbest değer) |
| Doğal anahtar ürün ADI: migration'lar `WHERE name=` ile eşler (isim değişince yeni satır + eski pasif → p/n/u id serileri) | `0004:5-6`, `0006:4-5` |
| Yeni ürün id `SELECT MAX(sort)+1 FROM products` tenant filtresiz | `$action.ts:1112-1116` |
| Admin UI ad/kategori/birim düzenleyemez, yeni ürün ekleyemez; `admin-products` GET `moq` döndürmediği için her satır kaydı `COALESCE(0, moq)` ile MOQ'yu sıfırlar (bug) | `$action.ts:1069 vs 1086`; `admin.tsx:1524-1535` |
| Ürün master'ı fiilen 4 kopya ve ayrışmış: B2B D1 (ad-anahtarlı) / skill `urun_maliyet.xlsx` (216, Logo kodlu) + `satis_listesi.xlsx` (181) / Dashboard `larante.db` (311, normalize ad) / Dashboard Eylül fiyat listesi (197). Çikolata Şurup 750ml liste fiyatı 450 / 400 / 500 | Dashboard-skills audit |

### 2.3 B2B fiyat domaini sağlamdır (web'e taşınmaz)
Server-side authoritative: `OrderSchema` fiyat kabul etmez; `dealerPrice / effectiveDiscount / categoryDiscountsFor / activeCampaignsFor / productDiscount` (`src/lib/b2b/core.server.ts:668-705, 844-873`); entegrasyon testli (`tenant-dealer-read-scope.test.ts:108-185, 310-355`). ARCH §15/G3: B2B pricing public domaine kopyalanmaz.

### 2.4 Platform kısıtları
- Deploy config'i Higgsfield CI üretir; repo'daki `wrangler.jsonc` deploy'da yok sayılır (`wrangler.jsonc:4-9`). Tek D1 ve tek R2 preview+prod paylaşımlı (`:57-59, :65`).
- Worker sır taşımaz; sırlar "platform Outbound Worker" ile egress'te eklenir (`wrangler.jsonc:38-41`); kimlik yalnız `https://fnf.internal` egress'ine (`packages/fnf/ai/AGENTS.md:166-170`). **Keyfi dış hosta HTTPS izni belgesiz (NOT_FOUND).** B2B kodunda hiç dış `fetch` yok.
- **Deploy hattındaki kod `origin/main` = `bb2c415` (2026-08-17 MVP)**, HEAD'in 54 commit gerisinde, yalnız `0001-0002` migration içeriyor (`git rev-list --count origin/main..HEAD` = 54; `git ls-tree origin/main app/migrations/`). Audit edilen HEAD hiç deploy edilmemiş.

## 3. Karar — ARCH §3 **Seçenek B**

1. **Product identity master = `apps/platform-api` (PostgreSQL).** UUID id, slug, kategori ağacı, `sellable_variants`, `preparation_options` (stok kalemi değil — R4), typed nitelikler, `media`, KDV oranı, perakende fiyat platformda yaşar.
2. **Inventory master = `apps/platform-api` (PostgreSQL).** Miktar modeli ADR-016 K1–K2: `inventory_items` (varyant ↔ stok kalemi 1:1) / `inventory_balances(on_hand INTEGER CHECK (>= 0), reserved INTEGER CHECK (>= 0))` / `inventory_movements` (yalnız fiziksel: RECEIVE, SHIP, RETURN_IN, DAMAGE_OUT, ADJUST_UP/DOWN; `qty INTEGER CHECK (> 0)` + yön; `reason NOT NULL`) / `inventory_reservations` (sipariş satırı + nesil; `channel web|b2b`; NULL içermeyen `namespace` = `'b2b:' + external_tenant_id` / `'web'`, `UNIQUE (namespace, external_order_id, external_line_id) WHERE status = 'ACTIVE'` — ADR-016 K10/4) / `inventory_reservation_events` (RESERVE, RELEASE, COMMIT; `operation_ref` → `operations.id`, `UNIQUE (operation_ref, reservation_id, action)`) / `operations(id PK, namespace, operation_id, request_hash, status; UNIQUE (namespace, operation_id))` — dış `operation_id` yalnız ad alanı içinde tekil (`'b2b:' + external_tenant_id` / `'web'`; ADR-016 K2/4); `available = on_hand − reserved` türetilir. Rezervasyon tek atomik `UPDATE … WHERE on_hand − reserved >= $q`. RESERVE/RELEASE fiziksel hareket değildir; kesirli miktar yoktur; `reserved <= on_hand` sert kısıt değildir (shortage uyarısı, ADR-016 K2/8).
3. **B2B tüketicidir.** B2B `products` tablosu silinmez; **B2B kanal projeksiyonu** olarak kalır: `list_price / box_count / box_unit_price / moq / dealer-grup-kategori-kampanya iskontoları` B2B fiyat domainidir ve B2B'de kalır (G3).
4. **Eşleme yalnız platformda ve varyant düzeyinde (ADR-016 K6):** `variant_external_codes(system ∈ {logo, b2b}, code, variant_id; UNIQUE(system, code))`, 1:N (aynı varyant Logo'da iki kodla olabilir; B2B `products.id` de buraya yazılır). Her kod **tam olarak bir** satılabilir varyanta çözülür; çözülemeyen kod import'ta reddedilir, sipariş anında 422 (fail-closed). B2B istemci çağrılarında kendi `product.id`'sini gönderir; platform çözer. Varyant düzeyine çözülemeyen mevcut B2B satırları (ör. kavrumsuz "Cappadocia Blend") P7B öncesi varyant başına ayrı B2B satırına bölünür (veri değişikliği; eşleme B6a — AÇIK). *(2026-09-16 öncesi: ürün düzeyi `product_external_codes` — değiştirildi.)*
5. **B2B'de katalog / rebuild D1 migration'ı açılmaz.** B2B katalog migration'ları dondurulur. **İstisna (2026-09-16, ADR-016 K12 — onay bekliyor):** P7B'de yalnız **bir** additive, fail-closed rezervasyon-kayıt migration'ı (`order_reservation_ops` + `orders.request_hash / admission_token / revision / source_order_id` + `order_items.variant_code / box_count_snapshot`) **+ DB düzeyi tamsayı guard tetikleyicileri ve ön-doğrulama** (mevcut `order_items.qty` / `products.moq` / `products.box_count` ve yeni miktar kolonlarında BEFORE INSERT / UPDATE; kesirli legacy değerde abort, yuvarlama yok — ADR-016 K12/1a); DROP / rebuild yok. *(2026-09-16 öncesi hüküm "B2B'de yeni D1 migration açılmaz (P7B dahil)" — değiştirildi.)*
6. **`products.stock` dondurulur:** admin ProductRow'dan stok alanı kaldırılır; `admin-product-save` bu kolona yazmaz; katalog `in_stock` platform port'undan okunur; kolon silinmez (rebuild migration açmamak için).
7. **Port yönü ARCH V2.0 §87'nin tersidir (ARCH V2.1 §87 düzeltildi):** `InventoryReadPort / InventoryReservationPort / InventoryCommitPort` **platformda sunulur** (`/internal/v1/inventory/{availability, reservations (oluştur), reservations/patch, reservations/release, reservations/commit, operations/{id}, operations/{id}/abandon}` — patch / release / commit **sipariş kapsamlıdır** (tüm `reservation_id` + beklenen nesil listesi, tek `operation_id`, hepsi-ya-da-hiçbiri), servis token + `Idempotency-Key`; IP allowlist varsayımı F14 kapsamında AÇIK); B2B `platform-client.server.ts` ile istemcidir. Platform → B2B yönünde **komut / yazma çağrısı yok**; **tek istisna (2026-09-16, ADR-016 K11 — onay bekliyor):** platform worker'ının imzalı (Ed25519, zaman damgası + nonce; B2B kaynağa gömülü açık anahtarla doğrular, Worker'da sır yok), salt-okunur mutabakat anlık görüntüsü çekmesi (`/api/b2b/internal/reservation-snapshot`).
8. **B2B çağrıları senkron, idempotent ve fail-closed.** Kimlikler ADR-016 K10: gönderim kimliği (`submission_id`), sipariş kimliği, rezervasyon kimliği + nesli, işlem kimliği (`operation_id` = `Idempotency-Key`, çağrıdan önce kalıcı yazılır); `order_id + geçiş` anahtar olarak kullanılmaz. Tek bayrak `INVENTORY_PORT=off|enforce`; `off` = bugünkü davranış = rollback (launch sonrası kullanımı F08 — AÇIK). "Soft / uyar-geçir" modu YOK (üçüncü bir stok gerçeği üretir). Prod D1'ini paylaşan non-prod dağıtım `off` değil **`environment_disabled`**'dır: sipariş / cari / rezervasyon mutasyonları (bugünkü admin ve bayi yazıcıları dahil) yan etkiden önce reddedilir; entegrasyon, anlık görüntü ucu ve kurtarma yalnız `environment = production`'da (ADR-016 K11/2k-vii).
9. **Rezervasyon anı ve ömrü (2026-09-16 onaylı iş kuralı, ADR-016 K3–K5, K9):** B2B'de sepet rezerve etmez; rezervasyon **sipariş gönderiminde, kalıcı sipariş kaydıyla** başlar (`rezervasyon_bekliyor` → platform `reservations` (çok satırlı, atomik; `qty` tamsayı; koli = tamsayı katı + `box_count_snapshot`) → `onay`; kesin hata → `rezervasyon_basarisiz`); personel onayı beklenmez ve yeniden rezerve etmez. `expires_at NULL` — **otomatik süre dolumu yok**; 24 saat uyarı / 48 saat yükseltilmiş uyarı / 72 saat yönetim kararı zorunlu; sistem sessizce serbest bırakmaz. `sevkiyat` → `commit` (COMMIT + SHIP); `iptal` / ret → **sipariş düzeyi tek idempotent CANCEL op** (iptal + varsa cari ters kaydı + `release`; sebep zorunlu); **açık siparişin rezervasyonu siparişten bağımsız serbest bırakılmaz** (B6k KARAR 2026-09-16, ADR-016 K5/4); **iptal terminaldir, iptal-geri-alış yoktur** (tekrar = yeni sipariş: kalıcı `variant_code` ile çözülür, yeni kimlikler, `source_order_id` yalnız izlenebilirlik — ADR-016 K9/4). Web: ödeme başlangıcında TTL'li rezervasyon; **ödeme başarısında rezervasyon kalıcılaşır (fiziksel düşüş yok)**; commit sevkiyatta; başarısızlık / TTL'de release; havale 24 saat (ayar).
10. **Açılış stoğu fiziksel sayımla** `COUNT_ADJUSTMENT` hareketleri olarak girilir; taşınacak stok verisi hiçbir sistemde yoktur.
11. **Logo/ERP V1'de owner değildir**; ileride yalnız platform-api tarafında `AccountingProvider` adapter'ı (Cloudflare Workers yerel ağa erişemediği için B2B'ye konmaz).
12. **Geçici prosedür (G2 "geçici adapter belgelenir"):** P7B canlıya alınana kadar B2B sevkiyatları platform admin'inden **elle** `SALE (ref='b2b:#order_no')` hareketi olarak işlenir. Bu bir senkron scripti değil, tek ledger'a operatör girişidir. Sahibi: Depo rolü. **Sunset:** P7B `INVENTORY_PORT=enforce` canlıya alındığı gün.

## 4. Reddedilen alternatifler
- **Seçenek A — B2B owner:** B2B'de envanter yok; ürün modeli varyant/KDV/slug taşımıyor; onu paylaşımlı prod D1'de rebuild migration'larla büyütmek en riskli yol; D1 dış API açmıyor.
- **Seçenek C — kademeli migration:** yalnız kimlik köprüsü (`variant_external_codes`, varyant düzeyi — §3.4) düzeyinde zaten uygulanıyor; daha fazlası gereksiz.
- **B2B'de `0022 platform_variant_id` kolonu:** işlevsel kazanç yok (eşleme platformda), paylaşımlı D1'de migration riski → HAYIR.
- **`INVENTORY_ENFORCE=soft`:** sessiz oversell'e izin verir → HAYIR.
- **Rezervasyonu B2B "onay→uretimde" geçişine ertelemek:** onay bekleyen sipariş süresince web aynı birimi satar → HAYIR.
- **B2B'de yerel outbox/kuyruk:** D1 transaction'sız (yalnız batch), cron/KV/DO yok → HAYIR.
- **İptal edilen B2B siparişini geri alma (yeniden reserve):** iptal değişmez ve terminaldir; tekrar = yeni sipariş (ADR-016 K9) → HAYIR (2026-09-16).
- **B2B rezervasyonu için otomatik TTL:** gerçek sipariş için stok sessizce bırakılır (ADR-016 K5) → HAYIR (2026-09-16).

## 5. Sonuçlar
- Web checkout ve B2B siparişi aynı `inventory_balances` satırına dokunur; oversell testi ("N eşzamanlı rezervasyon toplamı on_hand'i aşamaz") CI kapısıdır (Phase 1'den itibaren).
- B2B siparişi platform-api erişilebilirliğine bağımlı hale gelir (fail-closed). Bilinçli tercih: iki master'dan kötü değildir.
- P7B'ye kadar B2B bugünkü gibi stoksuz çalışır (risk artmaz); geçiş prosedürü §3.12.
- ARCH V2.1 (2026-09-16): §87 düzeltildi; §5.4/§5.6 düzeltmesi B10 kapsamında beklemede.
- P7B B2B PR'ı ADR-016 K12 ile büyür: bir additive D1 migration, `submission_id` + parmak izi, op kaydı, cari borcun `onay`'a taşınması, iptal-geri-alışın kaldırılması, tamsayı doğrulama, imzalı anlık görüntü ucu.

## 6. Ön koşullar / açık maddeler (bu ADR'yi kilitlemeden önce)
| # | Madde | Sahip | Durum |
|---|---|---|---|
| 1 | Proje sahibi onayı (Seçenek B) | Proje sahibi | BEKLİYOR |
| 2 | Codex adversarial denetimi | Codex | BEKLİYOR |
| 3 | A-13: rezervasyon anı, ömrü, yetersiz stok davranışı, hangi B2B geçişi hangi hareketi üretir | Proje sahibi | **KARAR 2026-09-16** — ADR-016 K3–K5, K9 (ADR-016 onayıyla kilitlenir) |
| 4 | Stok birimi: varyantın ticari birimi, tamsayı; B2B koli yalnız tamsayı katı + snapshot; donuk pasta kutu; bulk kg → paket ertelendi | Proje sahibi | **KARAR 2026-09-16** — ADR-016 K1, K7; "yalnız koli" varyant listesi B6e AÇIK |
| 5 | Fiziksel sayım tarihi ve sayım runbook'u | Depo | AÇIK |
| 6 | **B2B egress/servis token/deploy hattı** (Higgsfield'a yazılı sorular) ve **HEAD'in canlıya alınması** (0003-0021 prova + uygulama) — P7B fizibilitesi | Proje sahibi + Higgsfield | AÇIK — **P7B'yi ve launch'ı bloklar; P1-P6'yı bloklamaz** |
| 7 | Canlı D1 envanteri: hangi commit koşuyor, migration seviyesi, `products.stock` gerçek değerleri, `tenant_domains` | Salt-okunur inceleme | AÇIK |
| 8 | §3.5 istisnası (P7B'de bir additive D1 migration) ve §3.7 istisnası (imzalı salt-okunur mutabakat çekmesi) onayı — ADR-016 U7 | Proje sahibi | AÇIK — P7B'yi bloklar |
| 9 | Mevcut B2B ürün satırlarının tam varyanta eşlemesi (B6a) — §3.4 | Proje sahibi | AÇIK — P4 import / P7B'yi bloklar |

## 7. Geri alma
- Platform tarafı: inventory tabloları expand-only; projeksiyon feature flag ile kapatılabilir.
- B2B tarafı: `INVENTORY_PORT=off` → bugünkü davranış (stok kontrolsüz) — yalnız üretim dağıtımında; paylaşımlı D1'deki non-prod dağıtım `environment_disabled` kalır (ADR-016 K11/2k-vii). Kolon silinmediği için şema geri alma gerekmez.

## 8. İlgili ADR'ler
ADR-001 (platform structure — ayrı repo + vendored contract), ADR-015 (ORM — Drizzle), **ADR-016 (stok miktar modeli, fiziksel/rezerve ayrımı, B2B rezervasyon yaşam döngüsü, tam varyant bağlama, tamsayı birim, idempotency, mutabakat — bu ADR'nin §3.2/§3.4/§3.5/§3.7/§3.8/§3.9 ayrıntısı; ARCH §100'deki "ADR-006" konusunu kapsar)**, ADR-017 (deployment/Postgres; 2026-09-16 öncesi "ADR-016"), ADR-010 (identity boundary).
