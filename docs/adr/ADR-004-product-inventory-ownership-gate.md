# ADR-004 — Product / Inventory Ownership Gate

**Durum:** TASLAK — proje sahibi onayı ve Codex adversarial denetimi bekliyor
**Tarih:** 2026-09-15
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
2. **Inventory master = `apps/platform-api` (PostgreSQL).** `inventory_items / inventory_balances(on_hand, reserved; CHECK) / inventory_movements(reason NOT NULL) / inventory_reservations(channel web|b2b, idempotency_key UNIQUE)`; `available = on_hand − reserved` türetilir. Rezervasyon tek atomik `UPDATE … WHERE on_hand − reserved >= $q`.
3. **B2B tüketicidir.** B2B `products` tablosu silinmez; **B2B kanal projeksiyonu** olarak kalır: `list_price / box_count / box_unit_price / moq / dealer-grup-kategori-kampanya iskontoları` B2B fiyat domainidir ve B2B'de kalır (G3).
4. **Eşleme yalnız platformda:** `product_external_codes(system ∈ {logo, b2b}, code; UNIQUE(system, code))`, 1:N (aynı ürün Logo'da iki kodla olabilir; B2B `products.id` de buraya yazılır). B2B istemci çağrılarında kendi `product.id`'sini gönderir; platform çözer.
5. **B2B'de yeni D1 migration açılmaz** (P7B dahil). B2B katalog migration'ları dondurulur.
6. **`products.stock` dondurulur:** admin ProductRow'dan stok alanı kaldırılır; `admin-product-save` bu kolona yazmaz; katalog `in_stock` platform port'undan okunur; kolon silinmez (rebuild migration açmamak için).
7. **Port yönü ARCH §87'nin tersidir:** `InventoryReadPort / InventoryReservationPort / InventoryCommitPort` **platformda sunulur** (`/internal/v1/inventory/{availability, reserve, commit, release}`, servis token + IP allowlist + `Idempotency-Key`); B2B `platform-client.server.ts` ile istemcidir. Platform → B2B yönünde çağrı yok.
8. **B2B çağrıları senkron, idempotent ve fail-closed.** Tek bayrak `INVENTORY_PORT=off|enforce`; `off` = bugünkü davranış = rollback. "Soft / uyar-geçir" modu YOK (üçüncü bir stok gerçeği üretir).
9. **Rezervasyon anı (varsayılan, A-13 teyidine bağlı):** B2B'de `POST order` anında `reserve(channel='b2b', qty = adet | qty × box_count, expires_at NULL)`; `sevkiyat` geçişinde `commit` (SALE), `iptal`de `release`, iptal-geri-alışta yeniden `reserve`. Web: ödeme başlangıcında kısa TTL rezervasyon; başarıda commit; başarısızlık/TTL'de release; havale 24 saat (ayar).
10. **Açılış stoğu fiziksel sayımla** `COUNT_ADJUSTMENT` hareketleri olarak girilir; taşınacak stok verisi hiçbir sistemde yoktur.
11. **Logo/ERP V1'de owner değildir**; ileride yalnız platform-api tarafında `AccountingProvider` adapter'ı (Cloudflare Workers yerel ağa erişemediği için B2B'ye konmaz).
12. **Geçici prosedür (G2 "geçici adapter belgelenir"):** P7B canlıya alınana kadar B2B sevkiyatları platform admin'inden **elle** `SALE (ref='b2b:#order_no')` hareketi olarak işlenir. Bu bir senkron scripti değil, tek ledger'a operatör girişidir. Sahibi: Depo rolü. **Sunset:** P7B `INVENTORY_PORT=enforce` canlıya alındığı gün.

## 4. Reddedilen alternatifler
- **Seçenek A — B2B owner:** B2B'de envanter yok; ürün modeli varyant/KDV/slug taşımıyor; onu paylaşımlı prod D1'de rebuild migration'larla büyütmek en riskli yol; D1 dış API açmıyor.
- **Seçenek C — kademeli migration:** yalnız kimlik köprüsü (`product_external_codes`) düzeyinde zaten uygulanıyor; daha fazlası gereksiz.
- **B2B'de `0022 platform_variant_id` kolonu:** işlevsel kazanç yok (eşleme platformda), paylaşımlı D1'de migration riski → HAYIR.
- **`INVENTORY_ENFORCE=soft`:** sessiz oversell'e izin verir → HAYIR.
- **Rezervasyonu B2B "onay→uretimde" geçişine ertelemek:** onay bekleyen sipariş süresince web aynı birimi satar → HAYIR.
- **B2B'de yerel outbox/kuyruk:** D1 transaction'sız (yalnız batch), cron/KV/DO yok → HAYIR.

## 5. Sonuçlar
- Web checkout ve B2B siparişi aynı `inventory_balances` satırına dokunur; oversell testi ("N eşzamanlı rezervasyon toplamı on_hand'i aşamaz") CI kapısıdır (Phase 1'den itibaren).
- B2B siparişi platform-api erişilebilirliğine bağımlı hale gelir (fail-closed). Bilinçli tercih: iki master'dan kötü değildir.
- P7B'ye kadar B2B bugünkü gibi stoksuz çalışır (risk artmaz); geçiş prosedürü §3.12.
- ARCH V2 §87 ve §5.4/§5.6 düzeltme notu (V2.1) gerekir.

## 6. Ön koşullar / açık maddeler (bu ADR'yi kilitlemeden önce)
| # | Madde | Sahip | Durum |
|---|---|---|---|
| 1 | Proje sahibi onayı (Seçenek B) | Proje sahibi | BEKLİYOR |
| 2 | Codex adversarial denetimi | Codex | BEKLİYOR |
| 3 | A-13: rezervasyon anı, TTL, yetersiz stok davranışı, hangi B2B geçişi hangi hareketi üretir | Proje sahibi | AÇIK (varsayılan §3.9) |
| 4 | Stok birimi: sellable variant (V1) + B2B koli dönüşümü; bulk kg → paket "packaging conversion" erteleme onayı | Proje sahibi (üretim gerçekliği) | AÇIK |
| 5 | Fiziksel sayım tarihi ve sayım runbook'u | Depo | AÇIK |
| 6 | **B2B egress/servis token/deploy hattı** (Higgsfield'a yazılı sorular) ve **HEAD'in canlıya alınması** (0003-0021 prova + uygulama) — P7B fizibilitesi | Proje sahibi + Higgsfield | AÇIK — **P7B'yi ve launch'ı bloklar; P1-P6'yı bloklamaz** |
| 7 | Canlı D1 envanteri: hangi commit koşuyor, migration seviyesi, `products.stock` gerçek değerleri, `tenant_domains` | Salt-okunur inceleme | AÇIK |

## 7. Geri alma
- Platform tarafı: inventory tabloları expand-only; projeksiyon feature flag ile kapatılabilir.
- B2B tarafı: `INVENTORY_PORT=off` → bugünkü davranış (stok kontrolsüz). Kolon silinmediği için şema geri alma gerekmez.

## 8. İlgili ADR'ler
ADR-001 (platform structure — ayrı repo + vendored contract), ADR-015 (ORM — Drizzle), ADR-016 (deployment/Postgres), ADR-006 (inventory ledger/reservation ayrıntısı — Phase 5'te), ADR-010 (identity boundary).
