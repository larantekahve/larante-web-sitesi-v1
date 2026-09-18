# LARANTE WEB PLATFORMU — ALTYAPI VE MİMARİ KARAR DOKÜMANI V2

**Dosya:** `LARANTE_WEB_ALTYAPI_MIMARISI_V2.md`  
**Sürüm:** 2.3  
**Tarih:** 2026-09-15 (V2.0) · 2026-09-16 (V2.1 revizyonu) · 2026-09-17 (V2.2 — Phase 0 karar paketi 2) · 2026-09-18 (V2.3 — Phase 0 onay paketi 3)  
**Durum:** Gereksinim sonrası revize ana mimari  
**Kaynak gereksinim:** `LARANTE_WEB_REQUIREMENTS.md`  
**Önceki sürüm:** `LARANTE_WEB_ALTYAPI_MIMARISI_V1.md`

---

# 0. V2.1 Revizyon Notu — 2026-09-16

Bu revizyon yalnız **stok miktar modeli ve B2B sipariş-rezervasyon sözleşmesi** bulgularını (Codex doküman denetimi 2026-09-16: F01–F06, F11, H2, H6) ve proje sahibinin aynı gün onayladığı iş kurallarını işler. Karar kaydı: `docs/adr/ADR-016`; gereksinim tarafı: REQ v1.1 §31.1–31.8.

| Bölüm | Değişiklik |
|---|---|
| §13 | Fiziksel stok modeli kesinleşti: satılabilir varyant = stok kalemi, tamsayı, `stock_unit`; donuk pasta kutu |
| §16–17 | `on_hand` / `reserved` / `available` tanımları; fiziksel hareket ↔ rezervasyon olayı ayrımı; RESERVATION/RELEASE hareket listesinden çıktı; invariant'lar |
| §21–22 | `variant_id` zorunlu, varyant snapshot'ı; SHIPPED = COMMIT + SHIP; CANCELLED terminal; B2B rezervasyon durumları |
| §25–26 | Ödeme başarısı rezervasyonu kalıcılaştırır; fiziksel düşüş sevkiyatta; süre dolumu yalnız ödenmemiş rezervasyon |
| §30 | Worker'a eskalasyon ve mutabakat işleri |
| §62, §64 | Alan düzeyi kısıtlar; kimlik sınıfları ve çitleme |
| §87 | Port yönü düzeltildi (portlar platformda, B2B istemci); uç listesi; imzalı salt-okunur mutabakat çekmesi |
| §100 | ADR-006 → ADR-016'da birleşti; ADR-016 = stok/rezervasyon sözleşmesi; deployment → ADR-017 |
| §101 | Master plan §18 yetkili faz haritası; eşleme tablosu; Faz 0 çıkış koşulu |
| §106 | DoD'ye ADR-016 |

**Bu revizyonda dokunulmayan bilinen düzeltmeler (B10):** §5.4 "Node/Express" ve §5.6 "Prisma" varsayımları gerçek B2B (Bun + TanStack Start + Workers + D1, ORM yok) ile çelişir — ADR-001 / ADR-015 geçerlidir; metin V2.3 notuyla (2026-09-18) §5.4 / §5.6 içinde hizalanmıştır. Ertelenen denetim bulguları: master plan §23, `docs/decisions/PHASE0_KARAR_LISTESI.md` §E.

---

# 0a. V2.2 Revizyon Notu — 2026-09-17 (Phase 0 karar paketi 2)

Bu revizyon yalnız proje sahibinin 2026-09-17'de onayladığı ikinci Phase 0 iş kararı paketini işler: B6a/B6e (net içerik ≠ stok birimi; birim sınıfları; donuk pasta kutu içi parça sayısı SKU bazlı), B6d (açılış sayımı), B6f (eskalasyon yetkisi / saati), B6g (stok eksikliği politikası), B6h (ADR-004 §3.5 / §3.7 onayı), B6i (satın alma maliyeti kaynağı), B4d (KDV kaynağı), B5 (public satış kapsamı / kanal uygunluğu), B3 (mimari yön kabulü; sağlayıcılar açık). Karar kaydı: `docs/decisions/PHASE0_KARAR_LISTESI.md`, `docs/adr/ADR-016` §7, `docs/adr/ADR-004` §3.5 / §3.7 / §6. ADR-016 yetkili sözleşme olarak değişmeden korunur; hiçbir PR #1 kararı yeniden açılmamıştır.

| Bölüm | Değişiklik |
|---|---|
| §4 | B3 yön kabulü: ayrı repo + sürümlü API sözleşmesi; D1 B2B-yerel (ADR-001 onayı ayrı) |
| §13 | V2.2: net içerik ≠ stok birimi; birim sınıfları PAKET / ŞİŞE / ADET / KUTU; `variant_key` kullanım tipi; donuk pasta kutu içi parça sayısı ≠ koli `box_count` |
| §16 | Stok eksikliği (B6g): otomatik kısma yok; yalnız Yönetici; web TTL / sahipsiz onarım önceliği |
| §18, §20 | Kanal uygunluğu: Add to Cart = public satılabilir AND available > 0; donuk grup "İşletmelere Özel"; checkout sunucu tarafı ret |
| §21 | KDV oranı kaynağı ve satır KDV snapshot'ı (B4d); maliyet snapshot'ı (B6i); F13 kalanı açık |
| §26 | B2B eskalasyon: 72 saat kararı yalnız Yönetici; saat ilk rezervasyon anından |
| §90 | Logo: sonraki aşamada yalnız platform-api tarafında salt-okunur (SELECT) okuma; yazma yok |
| §97–98 | www / admin / b2b alan adı yönü kabul (B3); DNS / hosting ayrıntısı açık |

**Bu revizyonda dokunulmayanlar:** §5.4 / §5.6 düzeltmesi (B10) yine ertelenmiştir; sağlayıcı seçimleri (B3 kalanı, B7, ADR-017) açıktır.

---

# 0b. V2.3 Revizyon Notu — 2026-09-18 (Phase 0 onay paketi 3)

Bu revizyon yalnız Phase 0 kapanış onaylarını işler: ADR-001, ADR-004 (Seçenek B bütünü), ADR-015 ve ADR-016 proje sahibince **onaylandı**; `platform-api` scaffold'u **Hono + zod-openapi** ve uygulama deposu adı **`larante-platform`** karara bağlandı; B6e Phase 1 ledger kapısı sağlandı; B10 kalanı ve deployment / sağlayıcı ADR'si (ADR-017 — henüz yazılmadı) tarihli beklemede. Karar kaydı: `docs/decisions/PHASE0_KARAR_LISTESI.md` §D / §F. Hiçbir mimari kural yeniden tasarlanmamıştır.

| Bölüm | Değişiklik |
|---|---|
| §5.4 | Framework kararı: Hono + zod-openapi (2026-09-18); B2B "Node/Express uyum" cümlesi geçersiz (B2B Bun + TanStack Start + Workers) |
| §5.6 | "Henüz kilitlenmez" → kilitlendi: ADR-015 onaylı (Drizzle); Prisma öncelik kuralı geçersiz |
| §100 | ADR-017 henüz yazılmadı — tarihli beklemede |
| §101 | Faz 0 çıkış koşulu sağlandı (ADR-004 + ADR-016 onaylı; B6b / B6c / B6e birim sınıfları karar) |
| §106 | DoD: ownership audit, ownership ADR, ORM ADR, ADR-016 kutuları işaretlendi |
| Kapanış | "Bir sonraki zorunlu teknik adım" tamamlandı → Phase 1 görev dosyaları |

**Tarihli beklemede (2026-09-18, B10 kalanı):** V2.1–V2.3 notlarıyla düzeltilen bölümlerin gövde metnine editoryal konsolidasyonu (Phase 1 sonu belge bakımı); B2B tarafı belgelerinin senkronu (P7B). Sağlayıcı seçimleri (B3 kalanı, B7, ADR-017) açıktır.

---

# 1. V2 Neden Gerekli?

V1 hazırlanırken web sitesi ağırlıklı olarak:

- marka vitrini,
- ürün kataloğu,
- gelecekte B2B entegrasyonu

olarak ele alınmıştı.

Gereksinim çalışması sonunda kapsam büyüdü.

Artık V1 ürününe ek olarak zorunlu:

- B2C e-ticaret
- müşteri hesabı
- checkout
- ödeme
- havale
- ortak stok
- sipariş
- kargo
- iade
- kupon/kampanya
- yorum/favori
- Akademi takvimi
- başvuru
- lead yönetimi
- CMS-benzeri içerik
- admin panel
- audit
- internal analytics

bulunuyor.

Bu nedenle `Typed Static Content + yalnız apps/web` yaklaşımı artık yeterli değildir.

---

# 2. V2 Ana Mimari Karar

Seçim:

> **Modular Monolith + Ports/Adapters + Server-First Web + Ayrı Admin Surface + Transactional Outbox**

Mikroservis kullanılmayacaktır.

Uygulamalar ayrı deploy edilebilir; ancak domain, veri ve transaction sınırları tek platform mantığında korunur.

```text
                    INTERNET
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
   www.larantecoffee.com      admin.larantecoffee.com
          │                         │
          ▼                         ▼
       apps/web                 apps/admin
          │                         │
          └────────────┬────────────┘
                       │
                       ▼
                 apps/platform-api
                       │
        ┌──────────────┼───────────────┐
        │              │               │
        ▼              ▼               ▼
   PostgreSQL      Object Storage    Worker
        │                              │
        │                        notifications/jobs
        │
        └──── Product/Inventory Ownership Gate ────► Existing B2B
```

---

# 3. En Kritik V2 Kuralı — Dual Master Yok

Web ve B2B aynı gerçek stoğu kullanacaktır.

Ancak mevcut B2B repository'nin gerçek durumu henüz doğrulanmadan yeni sistemin:

- Product Master
- Inventory Master

olduğu varsayılmayacaktır.

## Production Gate

Ürün/stok write işlemleri production'a bağlanmadan önce B2B repository audit yapılır.

Üç olası sonuç:

### Seçenek A — B2B mevcut owner

```text
B2B Product / Inventory
        │
        ▼
Public Platform Adapter
        │
   ┌────┴────┐
   ▼         ▼
 Web       Admin
```

### Seçenek B — B2B'de kararlı owner yok

`platform-api` Product + Inventory owner olur; B2B bu kaynağa entegre edilir.

### Seçenek C — Kademeli Migration

Anti-corruption adapter ile geçiş yapılır.

**Yasak:**

```text
Web Stock DB
+
B2B Stock DB
+
senkronizasyon scripti
```

Bu sistem kalıcı mimari olarak kabul edilmez.

---

# 4. Repository Yapısı

Önerilen V2 monorepo:

```text
larante-platform/
│
├── apps/
│   ├── web/
│   ├── admin/
│   ├── platform-api/
│   └── worker/
│
├── packages/
│   ├── ui/
│   ├── design-tokens/
│   ├── domain/
│   ├── application/
│   ├── contracts/
│   ├── analytics/
│   ├── config/
│   ├── observability/
│   └── testing/
│
├── docs/
│   ├── requirements/
│   ├── architecture/
│   └── adr/
│
├── pnpm-workspace.yaml
├── turbo.json
└── pnpm-lock.yaml
```

`apps/b2b` şimdilik zorunlu olarak bu repo içine taşınmaz.

B2B repo audit sonrası:

- aynı monorepo
- ayrı repo + API
- kademeli birleştirme

kararı ADR ile alınır.

**Yön kabul (B3 — 2026-09-17):** mevcut B2B ayrı bir sistem / repo olarak kalır ve yeni platformla **onaylı sürümlü API sözleşmesi** üzerinden konuşur; zorla birleştirilmez. B2B D1 yalnız B2B-yerel durumdur, paylaşımlı envanter gerçeği değildir (Platform / PostgreSQL yetkili). Bu yön ADR-001 taslağıyla uyumludur; ADR-001'in resmi onayı ayrı bir kalemdir.

---

# 5. Teknoloji Yığını

## 5.1 Package / Workspace

- pnpm
- Turborepo

## 5.2 Public Web

- Next.js App Router
- React
- TypeScript strict
- Tailwind CSS
- Server Components default
- Client Components yalnız gerektiğinde

## 5.3 Admin

Tercih:

- Next.js App Router
- React
- TypeScript
- aynı `packages/ui`
- ayrı auth/authorization surface

Admin public web içine `/admin` route olarak karıştırılmayacaktır.

## 5.4 Backend

- Node.js + TypeScript
- modüler monolit
- REST/HTTP contracts
- repository/adapter sınırları
- OpenAPI sözleşmesi önerilir

Framework kararı scaffold aşamasında ADR ile sabitlenebilir.

Mevcut B2B Node/Express yapısı gerçekten doğrulanırsa uyum önceliklidir.

**V2.3 (2026-09-18) — karar verildi:** `platform-api` framework'ü **Hono**, API şeması / OpenAPI yönü **zod-openapi** (Phase 1 scaffold seçimi; karar kaydı `docs/decisions/PHASE0_KARAR_LISTESI.md` scaffold satırı + master plan §10; ayrı ADR dosyası yazılmaz). Yukarıdaki "B2B Node/Express … uyum önceliklidir" koşulu **boştur ve geçersizdir**: audit B2B'nin Bun + TanStack Start + Cloudflare Workers olduğunu doğruladı (ADR-001 kanıtı); uyum önceliği yoktur.

## 5.5 Database

- PostgreSQL

## 5.6 ORM

**Kilitlendi — ADR-015 ONAYLI (2026-09-18):** platform ORM'i **Drizzle ORM** (PostgreSQL); yarış-kritik envanter işlemleri onaylı repository / migration sınırında açık, gözden geçirilmiş SQL ile; platforma rakip ORM eklenmez; mevcut B2B D1 / SQLite / ham SQL kalır. *(V2.3 notu — aşağıdaki V2.0 kuralının Prisma öncelik maddesi geçersizdir: audit B2B'de ORM olmadığını doğruladı, ADR-015 kanıtı.)*

Kural (V2.0 metni; ilk madde geçersiz):

- ~~B2B gerçekten Prisma kullanıyorsa ortaklık için Prisma öncelikli değerlendirilir.~~ (koşul boş — geçersiz)
- Aksi durumda güncel alternatifler ADR ile değerlendirilir → ADR-015: Drizzle (onaylı).
- Aynı domain için `Prisma + Drizzle + başka ORM` birlikte kullanılmaz.

## 5.7 Object Storage

S3-compatible object storage + CDN.

Kullanım:

- ürün görselleri
- lifestyle görseller
- videolar
- WebP/frame setleri
- katalog PDF
- içerik medyası

---

# 6. Sürüm Politikası — 2026-09-15

Mimari güncel resmi kaynaklara göre:

- Next.js 16.3 serisi
- React 19.3
- Tailwind CSS 4.3

ile uyumludur.

**Güvenlik notu:** Next.js 16.3.3, 2026-08-25 güvenlik sürümünde Active LTS patch olarak yayımlanmıştır.

Kurulum anında:

- security-patched exact version
- lockfile
- canary/beta yok
- major upgrade otomatik yok

kuralı uygulanır.

---

# 7. Katmanlar

```text
Presentation
    ↓
Application
    ↓
Domain
    ↓
Ports
    ↓
Infrastructure Adapters
```

Domain:

- Next.js bilmez
- React bilmez
- PostgreSQL bilmez
- ödeme sağlayıcısını bilmez
- SMS firmasını bilmez

---

# 8. Domain Modülleri

Platform API içinde sınırlar:

```text
Identity
Customer
Catalog
RetailPricing
Inventory
Cart
Checkout
Order
Payment
Shipping
Promotion
Review
Wishlist
Return
Academy
Lead
Content
Media
Newsletter
SiteSettings
Notification
Analytics
Audit
```

B2B domainleri web'e taşınmaz:

```text
B2B Customer Pricing
Profitability
B2B Order Policies
B2B Tenant Membership
B2B Accounting
B2B Visit Management
```

---

# 9. B2C ve B2B Customer Ayrımı

B2C:

```text
RetailCustomer
```

B2B:

```text
BusinessCustomer
```

Aynı e-posta bulunabilir.

Kimliklerin aynı kişiye ait olması:

- otomatik fiyat yetkisi vermez
- B2B discount taşımaz
- tenant erişimi vermez

Gelecek SSO için identity link kurulabilir.

---

# 10. Identity Mimarisi

## Public Customer

V1:

- email/password
- password reset
- guest checkout
- güvenli session

## Admin

- ayrı admin surface
- 2FA zorunlu
- RBAC
- session hardening
- brute-force koruması
- audit

## B2B

Mevcut B2B auth sistemi ile karıştırılmaz.

B2B auth audit sonrası SSO ayrıca değerlendirilir.

---

# 11. RBAC

Rol örnekleri:

```text
ADMIN
SALES
WAREHOUSE
CONTENT
FINANCE
```

İzin kontrolü:

- server-side
- API seviyesinde
- domain action seviyesinde uygun olduğu yerde

UI buton gizlemek yetki kontrolü değildir.

---

# 12. Catalog Modeli

Temel:

```text
Product
ProductCategory
ProductMedia
ProductAttribute
SellableVariant
PreparationOption
ProductSeo
```

Kahve örneği:

```text
Product: Cappadocia Espresso
├── roast options
├── weight options
└── grind/preparation options
```

---

# 13. Varyant Patlamasını Önleme

Öğütüm:

```text
PreparationOption
```

olarak tutulması tercih edilir.

Yani:

```text
roast × weight × grind
```

her kombinasyon için ayrı fiziksel stok zorunlu değildir.

**V2.1 — kesinleşti (ADR-016 K1, K6, K7):**

- Fiziksel stok kalemi = **satılabilir varyant** (`SellableVariant` ↔ `InventoryItem` 1:1). Varyant kimliği stoku belirleyen tüm boyutları taşır: kavrum / kullanım tipi, gramaj, ambalaj, kutu konfigürasyonu (`variant_key`; `UNIQUE (product_id, variant_key)`).
- Her varyantın zorunlu bir **ticari stok birimi** (`stock_unit`: paket / şişe / kutu / koli / adet …) vardır; tüm miktarlar bu birimin **tam sayı** katıdır. Kesirli miktar hiçbir yerde yoktur.
- Koli (packaging conversion) yalnız **tamsayı katı** olarak ve sipariş satırına snapshot'lanmış `box_count` ile vardır; ticari birimi koli olan varyantta dönüşüm yoktur. Belirsiz / kesirli kutu-birim dönüşümü yasaktır.
- Donuk pasta: `stock_unit = kutu`; yarım / kısmi / dilim hareketi yok; karışık kutu yok; farklı içerik veya dilim sayısı ayrı varyant; kutu içeriği tanımlayıcıdır (REQ §31.3).
- Bulk (dökme kg) envanteri ve kg → paket dönüşümü **V1 dışıdır**.

**V2.2 — B6a/B6e KARAR 2026-09-17 (ADR-016 K1/2, K6/2, K7/5):**

- **Net içerik ≠ stok birimi:** 1 kg / 2,5 kg / 750 ml / 2 L ürünün net içeriğidir; envanter kg, litre ya da ml ile izlenmez. Ticari stok birimi bitmiş ürünün nasıl satılıp sayıldığıyla belirlenir: **PAKET** (1 kg kahve — espresso / filtre ayrı SKU; 1 kg toz ürünler; 100 / 250 / 300 g çay, her gramaj ayrı SKU), **ŞİŞE** (750 ml şurup; 1 kg meyve püresi; 2,5 kg bar sosu; 2,5 kg baz), **ADET** (6 kg demlik poşet çay; 2 L Frozen Lemonade / Frozen Orange Juice), **KUTU** (donuk pasta). Net içerik modellendiğinde tamsayı taban birimle (ör. 2500 g, 750 ml, 2000 ml) tanımlayıcı alandır, operasyonel miktar değildir. Onaylı gruplarda ticari birimi koli olan varyant yoktur; B2B koli (kasa) modu ve snapshot'lı `box_count` (koli içi adet) değişmez.
- **`variant_key`** kullanım tipini içerir: `usage_type | roast_level | weight_g | packaging_code | box_config` (`usage_type ∈ {espresso, filtre, -}`) — aynı aile adı altında espresso ve filtre ayrı SKU'dur (ADR-016 K6/2).
- **Donuk pasta kutu içi parça sayısı** SKU'ya özgüdür (cheesecake 12 dilim; dilimli pastalar 12 dilim; mono / cup ürüne özgü, kategori geneli değer yok) ve **koli çarpanı `box_count` değildir** (ADR-016 K7/5); kutu konfigürasyonu değişirse yeni SKU; sipariş satırı kutu konfigürasyonu + fiyat snapshot'lar.
- Somut B2B satır → varyant eşleme tablosu, kavrum ekseni ve varyant başına koli içi adet / kutu içi parça sayısı **veri görevidir** (PHASE0 B6a / B6e veri kalemleri — açık; modelleme kuralı karar).

---

# 14. Retail Pricing

Retail fiyat ayrı domain kuralıdır.

Destekler:

- KDV dahil public fiyat
- variant bazlı fiyat
- kampanya fiyatı
- başlangıç/bitiş
- fiyat geçmişi

Client fiyat gönderse bile backend:

> server-side authoritative price

hesaplar.

---

# 15. B2B Pricing

B2B pricing public API domainine kopyalanmaz.

B2B:

```text
B2B list price
- customer discount
```

B2B backend sorumluluğunda kalır.

---

# 16. Inventory Core

Hedef model:

```text
InventoryItem            (satılabilir varyant ↔ stok kalemi, 1:1)
InventoryBalance         (on_hand, reserved)
InventoryMovement        (fiziksel hareket — yalnız on_hand)
InventoryReservation     (sipariş satırı + nesil başına; ACTIVE / RELEASED / COMMITTED)
InventoryReservationEvent(RESERVE / RELEASE / COMMIT — yalnız reserved)
```

**V2.1 tanımlar (REQ §31.1, ADR-016 K1–K2):**

| Değer | Alan | Tanım |
|---|---|---|
| Fiziksel stok | `on_hand` | depoda fiilen bulunan miktar |
| Rezerve stok | `reserved` | gönderilmiş, henüz sevk edilmemiş siparişlere ayrılmış miktar |
| Kullanılabilir | `available` | `on_hand − reserved`; **türetilir, gerçek olarak saklanmaz** |

Örnek: `on_hand = 100`, `reserved = 10` → `available = 90`.

- Bakiyeler **negatif olmayan tamsayıdır** (`INTEGER CHECK (>= 0)`); kesirli miktar hiçbir tabloda yoktur.
- Her varyantın ticari stok birimi (`stock_unit`) vardır; tüm miktarlar bu birimin tam katıdır (§13).
- Rezervasyon tek atomik ifadeyle açılır: `UPDATE inventory_balances SET reserved = reserved + q WHERE item_id = i AND on_hand − reserved >= q` (0 satır → yetersiz stok).
- `reserved <= on_hand` **sert kısıt değildir**: fiziksel kayıp (hasar / sayım düşüşü) her zaman kaydedilir; `available < 0` olan kalem **açık (shortage)** durumundadır — yeni rezervasyon açılamaz, mutabakat yönetim uyarısı üretir (ADR-016 K2/8). **B6g (2026-09-17):** shortage mevcut rezervasyonları **otomatik olarak azaltmaz, yeniden atamaz, serbest bırakmaz ya da iptal etmez**; kritik stok-eksikliği uyarısı ve etkilenen sipariş listesi yönetime sunulur; hangi siparişin etkileneceğine **yalnız Yönetici** karar verir (sayım düzeltme / bekleme / onaylı PATCH / onaylı CANCEL op) — yazılım hiçbir ticari öncelik seçmez; her müdahale audit'lidir. Öncelik: bu yasak yalnız shortage'ın tetiklediği otomatik ticari tahsis değişikliklerini kapsar; ödenmemiş web rezervasyonunun TTL ile sona ermesi (§26, ADR-016 K2/9) ve gerçek teknik sahipsiz rezervasyonun deterministik onarımı (ADR-016 K11/4) shortage sırasında da kendi kurallarıyla uygulanır.

---

# 17. Inventory Ledger

Sadece `quantity = 42` saklayan kör model yeterli değildir.

**V2.1:** ledger iki ayrı kayıt türünden oluşur; ikisi **birbirine karıştırılmaz** (ADR-016 K2).

## 17.1 Fiziksel hareketler — yalnız `on_hand`

```text
RECEIVE       (+)  üretim / satın alma girişi         reason PRODUCTION | PURCHASE
SHIP          (−)  sevkiyat                            reason SALE, ref sipariş; COMMIT ile aynı transaction
RETURN_IN     (+)  iade girişi                         reason RETURN
DAMAGE_OUT    (−)  hasar / fire                        reason DAMAGE | WASTE
ADJUST_UP     (+)  sayım / manuel düzeltme (artış)     reason COUNT_ADJUSTMENT | MANUAL_ADJUSTMENT
ADJUST_DOWN   (−)  sayım / manuel düzeltme (azalış)    reason COUNT_ADJUSTMENT | MANUAL_ADJUSTMENT
```

Her hareket: `qty INTEGER CHECK (qty > 0)`, açık `direction IN|OUT`, `reason NOT NULL`, `ref_type/ref_id`, actor, audit. V2.0'daki `PRODUCTION / SALE / RETURN / DAMAGE / WASTE / COUNT_ADJUSTMENT / MANUAL_ADJUSTMENT` sebepleri bu tiplere eşlenir; **`RESERVATION` ve `RELEASE` fiziksel hareket değildir** ve bu listeden çıkarılmıştır.

## 17.2 Rezervasyon olayları — yalnız `reserved`

```text
RESERVE   (+)  sipariş gönderimi, miktar artışı, varyant değişimi (yeni nesil)
RELEASE   (−)  iptal, ret (sipariş düzeyi tek idempotent CANCEL op — B6k; sebep zorunlu), miktar azaltma (PATCH op'unun parçası), mutabakat onarımı (yalnız gerçek sahipsiz rezervasyon); açık siparişte bağımsız serbest bırakma yok
COMMIT    (−)  sevkiyat — yalnız SHIP hareketiyle birlikte, aynı transaction'da
```

Her olay: `qty INTEGER CHECK (qty > 0)`, `action`, `operation_ref` (→ `operations.id`, iç anahtar; bir işlem birden çok olay üretebilir — çok satırlı rezervasyon, varyant takası), actor, reason; `UNIQUE (operation_ref, reservation_id, action)`. İşlem kaydı `operations(id PK, namespace, operation_id, request_hash, status succeeded|failed|abandoned; UNIQUE (namespace, operation_id))` tablosundadır — dış `operation_id` (= `Idempotency-Key`) yalnız ad alanı içinde tekildir; ad alanı `'b2b:' + external_tenant_id` (B2B principal'ları) / `'web'` (platform-içi web kanalı) (ADR-016 K2/4, RV01).

## 17.3 Invariant'lar (mutabakat işi doğrular)

```text
on_hand   = Σ IN − Σ OUT                      (yalnız fiziksel hareketler)
reserved  = Σ RESERVE − Σ RELEASE − Σ COMMIT  (= aktif rezervasyonların toplamı)
available = on_hand − reserved
```

Sevkiyat (SHIP + COMMIT) her kanalda **sevkiyat anında** gerçekleşir; ödeme başarısı (web) ya da personel onayı (B2B) fiziksel stoğu değiştirmez (§25–26, ADR-016 K2/9, K3).

Audit ile ilişkilendirilir.

---

# 18. Public Inventory Projection

Public web:

```text
public satılabilir (kanal uygunluğu) AND available > 0
→ Add to Cart

public satılabilir AND available <= 0
→ Out of Stock

kanal uygunluğu = yalnız B2B (donuk grup)
→ "İşletmelere Özel" — iletişim / teklif CTA (stok durumu gösterilmez)
```

**V2.2 (B5 — 2026-09-17):** kategori taksonomisi ile kanal uygunluğu ayrı niteliklerdir; donuk grup (donuk pastalar, Frozen Lemonade, Frozen Orange Juice) public'te görünebilir ama B2C satın alımına kapalıdır (REQ §12, §30).

Miktar public API'ye gönderilmek zorunda değildir.

---

# 19. Cart

Cart server-side doğrulanan domain nesnesidir.

Guest cart:

- signed anonymous session/cart token

Member cart:

- customer ile ilişkili

Login sonrası guest cart merge politikası tanımlanır.

---

# 20. Checkout Security

Checkout:

- client fiyatına güvenmez
- client discount'a güvenmez
- kanal uygunluğunu sunucuda yeniden doğrular (donuk grup public checkout'ta reddedilir — B5)
- inventory yeniden kontrol eder
- coupon server doğrular
- shipping server hesaplar
- totals server hesaplar

Checkout snapshot siparişte saklanır.

---

# 21. Order Snapshot

Sipariş sonrası ürün adı/fiyatı sonradan değişse dahi geçmiş sipariş bozulmamalıdır.

Order line:

```text
product_id
variant_id
product_name_snapshot
variant_snapshot
unit_price_snapshot
tax_snapshot
discount_snapshot
quantity               (INTEGER > 0, varyantın stok birimi cinsinden)
source_order_id        (iptal sonrası tekrar siparişte kaynak referansı; opsiyonel)
```

gibi immutable geçmiş bilgileri korur.

**V2.1:** `variant_id` **zorunludur** — yalnız ürüne bağlı satır olamaz (ADR-016 K6); `variant_snapshot` stok-belirleyici nitelikleri (kavrum, gramaj, ambalaj, kutu konfigürasyonu) ve `stock_unit`'i dondurur. Teslimat adresi snapshot'ı ve kargo / toplam kalemleri F13 kapsamında açıktır. **V2.2:** KDV oranı kaynağı (V1 kontrollü Excel → tam varyant; sonra Logo malzeme kartı salt-okunur) ve her sipariş satırında uygulanan **KDV oranı snapshot'ı** B4d ile karara bağlandı (2026-09-17); satır ayrıca uygulanan **satın alma maliyeti ve satış fiyatı snapshot'ını** taşır (B6i) — sonraki oran / maliyet değişikliği geçmiş siparişi değiştirmez (REQ §7.1, §82).

---

# 22. Order State Machine

Public ana durumlar:

```text
PAYMENT_PENDING
PAYMENT_RECEIVED
PREPARING
SHIPPED
DELIVERED
CANCELLED
RETURNED
```

İç teknik durumlar ayrıca olabilir.

Invalid geçişler domain seviyesinde engellenir.

Örnek:

```text
DELIVERED → PREPARING
```

normal UI aksiyonu değildir.

**V2.1:** `SHIPPED` geçişi her kanalda rezervasyonu kapatır ve fiziksel stoğu düşürür (COMMIT + SHIP, §17.3). `CANCELLED` terminaldir; iptal edilen sipariş yeniden açılmaz, tekrar = yeni sipariş (REQ §31.6). B2B kendi durum sözlüğünü korur ve rezervasyon etrafında iki durum ekler: `rezervasyon_bekliyor → onay | rezervasyon_basarisiz`; `iptal` terminal (ADR-016 K4, K9).

---

# 23. Payment Architecture

```text
PaymentService
      │
      ▼
PaymentProvider
      │
 ┌────┴─────┐
 ▼          ▼
Provider A Provider B
```

Provider adapter:

- create payment
- verify 3DS
- verify webhook
- refund
- partial refund uygun olduğunda
- payment status

---

# 24. Webhook Güvenliği

Zorunlu:

- signature verification
- idempotency
- duplicate delivery toleransı
- replay koruması uygun olduğu ölçüde
- raw provider event audit/reference

Aynı `payment_succeeded` webhook iki kez gelirse iki sipariş veya iki stok düşümü oluşamaz.

---

# 25. Payment Reservation

Kartlı ödeme akışı:

```text
Checkout validated
↓
short reservation (TTL)
↓
payment flow
├── success → rezervasyon kalıcılaşır (expires_at temizlenir; miktar ve fiziksel stok değişmez)
└── failure/timeout → release
↓
SHIPPED → COMMIT + SHIP (fiziksel düşüş sevkiyatta)
```

Reservation TTL yönetilebilir (TTL'in PSP 3DS oturum süresiyle ilişkisi H10 — açık, ADR-007).

**V2.1:** ödeme başarısı fiziksel stoğu düşürmez; kullanılabilir stok zaten rezervasyonla ayrılmıştır (REQ §41, ADR-016 K2/9).

---

# 26. Bank Transfer

Havale siparişi:

```text
PAYMENT_PENDING
+
24h reservation
```

Worker:

- expiry kontrol eder
- ödenmemiş siparişi iptal eder
- stok rezervasyonunu bırakır
- kullanıcıya bildirim gönderebilir

**V2.1:** süre dolumu yalnız `expires_at` dolu (ödenmemiş) rezervasyonlar içindir; ödeme alındığında rezervasyon kalıcılaşır ve sevkiyata kadar korunur. B2B rezervasyonlarında süre dolumu yoktur (ADR-016 K5). **V2.2 (B6f — 2026-09-17):** B2B eskalasyon saati siparişin ilk rezervasyon anından işler, personel onayı sıfırlamaz; 72 saat kararını **yalnız Yönetici** verir (sürdür / uzat audit'li; ret / iptal = sipariş düzeyi idempotent CANCEL op — B6k).

---

# 27. Shipping Architecture

```text
ShippingService
      │
      ▼
ShippingProvider
      │
 ┌────┴────────────┐
 ▼                 ▼
ManualAdapter   CarrierApiAdapter
```

V1: ManualAdapter.

---

# 28. Notification Architecture

```text
Domain Event
    ↓
Transactional Outbox
    ↓
Worker
    ↓
EmailProvider / SmsProvider
```

Amaç:

Sipariş DB'ye yazıldı fakat SMS servisi çöktü diye sipariş kaybolmamalıdır.

---

# 29. Transactional Outbox

Aynı DB transaction içinde:

```text
Order Saved
+
Outbox Event Saved
```

Worker sonra event'i işler.

Retry:

- exponential backoff
- dead-letter / failed queue görünürlüğü
- idempotent handler

---

# 30. Worker

`apps/worker` aynı modular monolith codebase'inin background execution rolüdür.

Mikroservis değildir.

Görevler:

- notification
- bank transfer expiry
- retry jobs
- analytics export
- search indexing uygun olduğunda
- scheduled housekeeping
- rezervasyon eskalasyonu (24 / 48 / 72 saat bayrakları + bildirim; otomatik serbest bırakma yok — ADR-016 K5)
- stok mutabakatı (B2B'den imzalı salt-okunur anlık görüntü çekme, invariant doğrulama, deterministik onarım; `INCOMPLETE` koşuda onarım yok — ADR-016 K11)

**V2.1:** B2B tarafında zamanlayıcı yoktur; platformun mutabakat çekmesi B2B'nin bekleyen işlemlerini sonuçlandırma "tik"idir (ADR-016 K4-R).

---

# 31. Queue Teknolojisi

İlk sürümde gereksiz Redis zorunlu değildir.

Queue abstraction kullanılır.

PostgreSQL-backed güvenilir job/outbox yaklaşımı başlangıç için değerlendirilebilir.

Hacim büyürse ayrı broker ADR ile seçilir.

---

# 32. Promotions

Promotion module:

- Coupon
- Campaign
- Eligibility
- UsageLimit
- ValidityWindow

Tek source of discount calculation backend'dir.

---

# 33. Wishlist

Customer + Product ilişkisi.

Fiyat değişikliğini saklamaz; güncel ürün gösterilir.

---

# 34. Reviews

Review:

- customer
- product
- order verification reference
- rating
- content
- moderation status
- created_at

Public edilmeden moderation politikası uygulanabilir.

---

# 35. Returns

ReturnRequest:

```text
REQUESTED
UNDER_REVIEW
APPROVED
REJECTED
RECEIVED
REFUNDED
CLOSED
```

gibi internal state içerebilir.

Public basitleştirilmiş durum gösterebilir.

---

# 36. Academy

Domain:

```text
AcademyProgram
AcademySession
AcademyApplication
```

Session:

- date/time
- location
- capacity
- status

Application işletme adını optional tutar.

---

# 37. Lead

```text
Lead
├── SAMPLE
└── QUOTE
```

Lifecycle:

```text
NEW
CALLED
IN_DISCUSSION
SAMPLE_SENT
QUOTE_SENT
WON
LOST
```

Audit ile durum değişimi tutulur.

---

# 38. Content

V2'de tam harici CMS zorunlu değildir.

Platformun kendi Content module'ü:

```text
ContentEntry
ContentType
Draft
PublishedVersion
SeoMetadata
Media
```

ile:

- Kahve Rehberi
- Reçete
- Akademi İçeriği
- İşletme İpuçları

yönetilebilir.

---

# 39. Content Publish

Durum:

```text
DRAFT
PUBLISHED
ARCHIVED
```

İhtiyaç halinde revision history genişletilir.

---

# 40. Media

Object storage key metadata DB'de tutulur.

Media:

- id
- type
- object_key
- width/height uygun olduğunda
- alt text
- title
- mime
- size
- variants
- created_at

Uygulama doğrudan provider URL mantığına bağımlı olmamalıdır.

---

# 41. WebP / Frame Sequence

Hero:

```text
poster
↓
critical frames
↓
progressive frame load
↓
canvas/requestAnimationFrame
```

Kurallar:

- responsive asset set
- mobile-specific size
- lazy remainder
- reduced-motion fallback
- failure fallback
- SEO metnini animasyon içine gömmeme

---

# 42. Search

V1 ürün hacminde ayrı Elasticsearch/OpenSearch zorunlu değildir.

Başlangıç:

- PostgreSQL text search
- trigram / indexed fields uygun olduğunda
- structured filters

`SearchPort` arkasında tutulur.

Büyürse dedicated search adapter eklenir.

---

# 43. Recommendations

V1:

- manual relations
- category rules
- co-purchase basit aggregation

AI recommendation zorunlu değildir.

Provider abstraction ancak gerçek ihtiyaçta eklenir.

---

# 44. Internal Analytics

Finansal source of truth:

- Order
- Payment
- Refund
- Customer
- Product
- Promotion

tablolarından türetilir.

GA4 sonucu finansal kayıt yerine geçmez.

---

# 45. Analytics Event Layer

Package:

```text
packages/analytics
```

Örnek event contract:

```text
ProductViewed
ProductAddedToCart
CheckoutStarted
PurchaseCompleted
LeadSubmitted
SampleRequested
AcademyApplicationSubmitted
```

Sink:

- Internal
- GA4
- Meta koşullu

---

# 46. Consent

Consent state:

```text
necessary
analytics
marketing
```

GA/Meta load davranışı consent ile kontrol edilir.

Consent record policy yasal gereksinime göre uygulanır.

---

# 47. Search Console

Runtime uygulama bağımlılığı değildir.

Deployment / SEO operasyon entegrasyonudur.

Sitemap/robots/canonical doğru üretilir.

---

# 48. SEO

Next.js metadata sistemi.

Destek:

- title
- description
- canonical
- OG
- social image
- sitemap
- robots
- JSON-LD uygun sayfalarda

Şehir-spam sayfaları yok.

---

# 49. Public Rendering Strategy

Server-first.

Tercih:

- Server Components
- cached public catalog reads
- route/data revalidation
- client JS yalnız etkileşim için

Product update sonrası cache invalidation event tetiklenebilir.

---

# 50. Cache

Cache hiçbir zaman:

- müşteri özel veri
- admin yetkisi
- payment state

için yanlış shared cache üretmemelidir.

Public katalog cache'lenebilir.

Inventory availability kısa TTL / revalidate ile yönetilebilir; checkout yine DB/source doğrular.

---

# 51. Admin Architecture

Admin ayrı app/surface.

Avantaj:

- CSP daha sıkı
- ayrı session policy
- ayrı deployment protection
- public bundle'a admin kodu karışmaz
- observability ayrımı

---

# 52. Admin Security

- 2FA
- rate limiting
- session rotation
- secure cookies
- CSRF değerlendirmesi
- authorization server-side
- suspicious auth logging
- no secrets client-side

---

# 53. Audit Architecture

Append-oriented AuditLog:

```text
actor_id
action
resource_type
resource_id
before_ref / diff uygun olduğunda
after_ref / diff uygun olduğunda
reason
ip/user_agent uygun politika ile
created_at
```

Hassas secret içermez.

---

# 54. Price History

PriceHistory:

- product/variant
- old price
- new price
- effective time
- actor

Sipariş historical price bundan bağımsız order snapshot'ta da saklanır.

---

# 55. Site Settings

Settings data model:

- free_shipping_threshold
- WhatsApp
- contact
- IBAN
- social
- email identities
- feature flags uygun olduğunda

Critical settings Audit Log'a dahil edilir.

---

# 56. Newsletter

Subscription:

- email
- consent source
- subscribed_at
- unsubscribed_at
- status

Marketing communication consent ayrımı korunur.

---

# 57. Email

Provider abstraction.

DNS:

- SPF
- DKIM
- DMARC

Transactional ve marketing gönderim domain/reputation ayrımı gerektiğinde değerlendirilebilir.

---

# 58. SMS

Provider abstraction.

Gönderim:

- async worker
- delivery response log
- retry
- cost/volume gözlemi

---

# 59. Fatura Verisi

V1 otomatik muhasebe entegrasyonu yok.

Order BillingSnapshot:

- individual/corporate type
- name/title
- tax fields
- address

saklar.

Sonradan ERP/Logo adapter eklenebilir.

---

# 60. API Sözleşmesi

Public/internal contractlar ayrılır.

Örnek:

```text
/public/v1/catalog/*
/public/v1/content/*
/commerce/v1/cart/*
/commerce/v1/checkout/*
/customer/v1/*
/admin/v1/*
```

Gerçek route naming implementasyon ADR'sinde sadeleştirilebilir.

Internal model doğrudan API response olarak expose edilmez.

DTO/contract kullanılır.

---

# 61. Validation

Tüm dış veri:

- request schema
- domain invariant
- DB constraint

katmanlarında uygun biçimde doğrulanır.

Zod benzeri TypeScript schema aracı API sınırında tercih edilebilir.

---

# 62. DB Constraint

Uygulama validasyonu tek başına yeterli değildir.

Örnek:

- unique email uygun bağlamda
- coupon code uniqueness
- negatif olmayan **tamsayı** bakiyeler (`on_hand`, `reserved` ≥ 0) ve pozitif tamsayı hareket / olay miktarları (`qty` > 0); kesirli miktar yok — B2B tarafında mevcut `REAL` miktar kolonları (`order_items.qty`, `products.moq`, `products.box_count`) ve yeni miktar kolonları DB düzeyi guard tetikleyicileriyle zorlanır (ADR-016 K12/1a; uygulama doğrulaması tek başına yeterli değildir)
- foreign keys (`order_lines.variant_id NOT NULL`)
- unique idempotency / operation key (`operations(id PK, namespace, operation_id; UNIQUE (namespace, operation_id))`; olaylarda `UNIQUE (operation_ref, reservation_id, action)`; `variant_external_codes UNIQUE(system, code)`; `sellable_variants UNIQUE(product_id, variant_key)`)
- reservation validity (sipariş satırı başına tek ACTIVE nesil)

**V2.1:** `reserved <= on_hand` sert kısıt değildir (§16 shortage); ayrıntı ADR-016 K2.

DB seviyesinde korunur.

---

# 63. Concurrency

Kritik alanlar:

- stock reservation
- payment commit
- coupon usage
- order creation

concurrent isteklerde test edilir.

Transaction / row locking / atomic update gibi yöntemler adapter implementasyonunda kullanılır.

---

# 64. Idempotency

Zorunlu alanlar:

- payment webhook
- order submit uygun olduğunda
- refund request/provider callback
- background notification handler
- inventory reserve / release / adjust / cancel / commit (her biri kendi işlem kimliğiyle)

**V2.1 — kimlik sınıfları (ADR-016 K10):** gönderim kimliği (`submission_id`, istemci üretir, kanonik istek parmak iziyle saklanır), sipariş kimliği, rezervasyon kimliği + nesli, işlem kimliği (`operation_id` = `Idempotency-Key`, çağrıdan **önce** kalıcı yazılır). `order_id + geçiş` evrensel anahtar olarak **kullanılmaz**. Aynı anahtar + aynı gövde → kayıtlı sonuç; aynı anahtar + farklı gövde → 422; belirsiz sonuç → `operations/{id}` sorgusu → `abandon` (mezar taşı) ile çitleme; geçen süre tek başına sonuç sayılmaz.

---

# 65. Rate Limiting

Özellikle:

- login
- password reset
- guest order lookup
- contact
- sample
- quote
- academy application
- coupon brute force
- payment session creation

endpointlerinde uygulanır.

---

# 66. Bot / Spam

Public forms:

- honeypot / challenge uygun olduğunda
- rate limit
- duplicate detection
- server validation

Tek bir CAPTCHA sağlayıcısına domain bağımlılığı yaratılmaz.

---

# 67. Security Headers

- CSP
- HSTS
- frame-ancestors
- X-Content-Type-Options
- Referrer-Policy
- Permissions-Policy

Deployment ortamına göre test edilir.

---

# 68. Trusted Types / XSS

React/Next güvenli varsayımları korunur.

Rich content render:

- sanitize
- allowlist

olmadan raw HTML render edilmez.

---

# 69. Secrets

Secrets:

- source control'a girmez
- client env'e yanlışlıkla expose edilmez
- per-environment
- rotate edilebilir

---

# 70. PII

Customer data minimum gerekli kadar tutulur.

Log ve analytics'e gereksiz PII gönderilmez.

Provider'lara gönderilen veri minimum tutulur.

---

# 71. Backup

PostgreSQL:

- daily automated backup
- retention
- encrypted storage
- restore drill

Object storage:

- versioning/lifecycle uygun olduğunda

Yedek başarı metriği + restore metriği izlenir.

---

# 72. Observability

Üç sinyal:

```text
Logs
Metrics
Traces uygun olduğunda
```

En az:

- request error rate
- API latency
- checkout failure
- payment webhook failure
- outbox backlog
- notification failure
- worker failure
- DB health
- 404 trends
- Web Vitals

---

# 73. Error Monitoring

Production exception monitoring provider abstraction gerektirmez ama vendor seçimi config seviyesinde tutulur.

Release/version tag zorunlu.

---

# 74. Critical Alerting

Yüksek öncelik:

- ödeme alındı ama sipariş commit olmadı şüphesi
- order creation outage
- inventory write outage
- worker backlog kritik
- DB unavailable

Düşük/orta:

- tekil SMS failure
- tekil e-posta bounce
- tekil 404

---

# 75. Environment

```text
local
preview
staging
production
```

Production üzerinde manuel deneysel değişiklik yapılmaz.

---

# 76. Deployment

Portable Node/container deployment.

Vercel kullanılabilir; vendor lock-in core domain'e girmez.

Platform API/worker için Docker/Linux uyumluluğu korunur.

---

# 77. CI Pipeline

Minimum:

```text
install --frozen-lockfile
lint
typecheck
unit
integration
build
e2e smoke
```

Sonra:

```text
dependency scan
accessibility
Lighthouse CI
contract tests
migration check
```

---

# 78. DB Migration

Migration:

- review edilir
- production backup ön koşulu
- backwards-compatible rollout tercih edilir
- destructive migration iki aşamalı yapılır

AI-generated migration doğrudan production'a uygulanmaz.

---

# 79. Test Piramidi

## Unit

- domain
- pricing
- promotion
- order state
- inventory math

## Integration

- DB
- payment adapter sandbox
- outbox
- auth
- API contracts

## E2E

- browse
- add to cart
- guest checkout
- member checkout
- bank transfer
- card sandbox
- order tracking
- admin stock
- admin shipping
- academy
- lead

---

# 80. Zorunlu E2E Risk Senaryoları

- son stok için iki eşzamanlı checkout
- duplicate payment webhook
- payment success + notification provider down
- transfer expires
- coupon last-use race
- admin unauthorized role
- guest order lookup brute force
- product price changes while cart open
- stock goes zero while cart open
- refund retry
- worker restarts with pending outbox

---

# 81. Accessibility

CI/QA:

- keyboard
- focus
- headings
- labels
- contrast
- reduced motion
- form errors

Automated axe benzeri kontrol + manuel kritik flow.

---

# 82. Performance

Target:

```text
LCP <= 2.5s p75
INP <= 200ms
CLS <= 0.10
```

Main page animation bu hedefleri bozarsa:

- resolution düşürülür
- frame count azaltılır
- device-based fallback
- static poster

uygulanır.

Animasyon performans hedefinden üstün değildir.

---

# 83. Image Pipeline

- responsive sizes
- modern formats
- CDN
- dimensions known
- lazy non-critical
- priority hero
- object storage variants

AI-generated source dahi web asset optimization pipeline'dan geçer.

---

# 84. Design System

Shared:

```text
packages/design-tokens
packages/ui
```

Brand values hard-code edilmez.

```text
--brand-primary
--surface
--text-primary
--radius-md
...
```

---

# 85. Multi-brand Geleceği

Bugün Larante.

Ancak engine:

```text
Platform Engine
+
Brand Config
+
Content
```

ayrımıyla yazılır.

Bu multi-tenant SaaS anlamına gelmez; gereksiz tenant karmaşıklığı public web'e taşınmaz.

---

# 86. Microservice Kararı

V2'de de:

> **HAYIR**

API, worker ve web ayrı process olsa bile:

- aynı ürün
- aynı repo
- aynı domain
- aynı DB transaction sınırları uygun yerde

ile modüler monolit kalabilir.

Gerçek ölçek ihtiyacı olmadan distributed system kurulmaz.

---

# 87. B2B Integration Contract

**V2.1 (2026-09-16):** Audit (ADR-004) B2B'nin Inventory owner olmadığını kanıtladı; bu nedenle portların yönü V2.0'daki varsayımın **tersidir**: portlar **platformda sunulur**, B2B **istemcidir**. Ayrıntılı sözleşme: `docs/adr/ADR-016`.

```text
platform-api (owner)                          B2B (tüketici)
  /internal/v1/inventory/availability   ◄───  katalog in_stock projeksiyonu
  /internal/v1/inventory/reservations   ◄───  sipariş gönderimi (çok satırlı, atomik)
  …/reservations/patch                  ◄───  miktar / varyant değişikliği (sipariş kapsamlı, atomik)
  …/reservations/release                ◄───  iptal / ret (sipariş kapsamlı CANCEL op; sebep zorunlu; bağımsız serbest bırakma yok — B6k)
  …/reservations/commit                 ◄───  sevkiyat (sipariş kapsamlı; COMMIT + SHIP)
  …/operations/{op_id}                  ◄───  belirsiz sonuç sorgusu
  …/operations/{op_id}/abandon          ◄───  çitleme (mezar taşı)
  /api/b2b/internal/reservation-snapshot ───► platform worker mutabakat çekmesi (salt-okunur, imzalı)
```

Kurallar:

- Her çağrı `Idempotency-Key = operation_id` taşır; işlem kimliği çağrıdan **önce** çağıran tarafta kalıcı yazılır (ADR-016 K10). `order_id + geçiş` anahtar olarak kullanılmaz.
- Rezervasyon oluşturma **ve** patch / release / commit sipariş kapsamlıdır: tüm `reservation_id` + beklenen nesil listesi tek `operation_id` altında, **hepsi-ya-da-hiçbiri**; kısmi rezervasyon / kısmi commit / kısmi release yoktur. B2B tarafında niyet kabulü atomiktir (durum + sürüm + bekleyen op yok + kredi taahhüdü tek ifadede); yerel geçişler (`onay → uretimde → kalite`, `sevkiyat → teslim`) platform çağrısı olmadan koşullu tek UPDATE ile yapılır (ADR-016 K4-P). Her satır **kanonik stok-birimi miktarı** `qty_stock_units` ile (ayrıca `order_qty`, `order_unit`, `conversion_factor` — koli modunda `box_count` snapshot'ı, aksi halde 1) gönderilir; platform yalnız `qty_stock_units`'i rezerve eder.
- Zaman aşımı → `operations/{op_id}` sorgusu → aynı anahtarla sınırlı yeniden deneme → hâlâ belirsizse `abandon` ile mezar taşı; başarısızlık yalnız `abandoned` ya da yetkili `failed` sonucundan sonra sonuçlandırılır. Geçen süre tek başına sonuç sayılmaz.
- Platform → B2B yönünde yalnız **bir** çağrı vardır: imzalı, salt-okunur mutabakat anlık görüntüsü (Ed25519, zaman damgası + nonce; B2B kaynağa gömülü açık anahtarla doğrular; Worker'da sır yok). Komut / yazma çağrısı yoktur. B2B bu isteği kendi bekleyen işlemlerini sonuçlandırmak için "tik" olarak kullanır (ADR-016 K4-R). **Kiracı kapsamı (ADR-016 K11/2k):** istek kiracısı hostname'den (`resolveRequestTenant`, fail-closed) çözülür; imza anahtarı yetkili kiracıya **ve** ortama bağlıdır; imzalı yükteki `tenant_id` / `environment` host kiracısıyla eşleşmezse 403 ve hiçbir okuma / kurtarma / sonuçlandırma / audit yan etkisi olmaz; görüntü sorgusu, bekleyen-op kurtarması, koşullu yerel sonuçlandırma, audit kayıtları ve dönen satırlar tek `tenant_id`'ye bağlıdır; başka kiracı niteleyicili kimlik → `out_of_scope` (`not_found` değildir; DB'ye bakılmadan, varlıktan bağımsız aynı yanıt; onarım yok). Platform tarafında her mutasyon ucu ve idempotency araması principal → `external_tenant_id` + sipariş / rezervasyon sahipliği kapısından geçer (yabancı sipariş niteleyicisi 422, yabancı / var olmayan rezervasyon 404 — ayırt edilemez); işlem ve rezervasyon kayıtları NULL içermeyen `namespace` (`'b2b:' + external_tenant_id` / `'web'`) taşır (ADR-016 K4/7, K10/3–4). **Ortam:** preview / prod aynı D1'i paylaştığı sürece entegrasyon yalnız `environment = production` dağıtımında etkindir; non-prod dağıtım `off` değil **`environment_disabled`** modundadır — sipariş / cari / rezervasyon mutasyonları (sipariş gönderimi, admin durum / iptal / sevkiyat, değişiklik, ek / fatura, tahsilat) yan etkiden önce 403 ile reddedilir, anlık görüntü ucu 403, kurtarma çalışmaz; okuma uçları çalışır; kapı dağıtım ortamına bağlıdır (hostname ortamı ayırt etmez) ve ortam bilinmiyorsa non-prod sayılır (ADR-016 K11/2k-vii).
- B2B tarafı: `INVENTORY_PORT=off|enforce`; "uyar-geçir" modu yok; fail-closed; paylaşımlı D1'deki non-prod dağıtım ayrı `environment_disabled` modundadır (mutasyon yok — ADR-016 K11/2k-vii).
- B2B sipariş durumları rezervasyon etrafında: `rezervasyon_bekliyor → onay | rezervasyon_basarisiz`; `iptal` terminaldir (yeniden açılmaz). **Tekrar sipariş** = yeni sipariş: satırlar kalıcı `variant_code` (+ `order_unit`, `order_qty`) ile güncel katalogda çözülür, `conversion_factor` K1/3 kuralıyla yeniden hesaplanır, çözülemeyen satır "onay gerekli"; yeni `submission_id` / sipariş no / rezervasyon / `operation_id`; `source_order_id` yalnız izlenebilirlik; stok / cari durum devralınmaz (ADR-016 K9/4). **Açık siparişin rezervasyonu siparişten bağımsız serbest bırakılmaz;** iptal / ret + varsa cari ters kaydı + RELEASE tek idempotent CANCEL op'udur (ADR-016 K5/4, B6k 2026-09-16).

B2B internals web'e expose edilmez.

---

# 88. Anti-Corruption Layer

B2B veri modeli yeni domain modelinden farklıysa:

```text
B2B Model
↓
Adapter / Mapper
↓
Platform Contract
```

kullanılır.

Web componentleri B2B field isimlerini bilmez.

---

# 89. Product Identity

Ayrı:

```text
product_id
variant_id
slug
external_accounting_code
```

Logo/ERP code internal identity olmaz.

---

# 90. External Accounting

V1 manual invoice.

Gelecek:

```text
AccountingProvider
```

ile Logo/ERP adapter eklenebilir.

Bu bugün sipariş domainini ERP'ye bağımlı yapmaz.

**V2.2 (B6i / B4d — 2026-09-17):** satın alma maliyeti ve ürün KDV oranı V1'de kontrollü Excel içe aktarımından gelir (tam varyanta eşleme; belirsiz / eksik eşleme fail-closed). Sonraki aşamada bu iki veri Logo SQL'den **yalnız platform-api tarafında**, özel **salt-okunur** (yalnız SELECT) bir veritabanı kullanıcısıyla okunur; platform Logo verisine INSERT / UPDATE / DELETE yapmaz. Tablo / kolon adları belirlenmedi; sağlayıcı / ağ / güvenlik ayrıntıları ve Logo veritabanına erişim yolu altyapı işidir (B3 açık).

---

# 91. Feature Flags

Riskli integration rollout:

- new payment provider
- Meta Pixel
- carrier API
- new recommendation

feature flag ile kademeli açılabilir.

Basit config yeterliyse ayrı flag platformu şart değildir.

---

# 92. Legal Content Versioning

Checkout sırasında kullanıcı hangi sözleşme sürümünü kabul ettiyse referans saklanmalıdır.

Order:

```text
terms_version
pre_information_version
privacy_version uygun olduğunda
```

---

# 93. Consent Audit

Marketing/newsletter consent:

- timestamp
- source
- version
- withdrawn_at

uygun hukuki gereksinime göre saklanır.

---

# 94. Admin Delete Policy

Kritik finansal/operasyonel kayıtlar:

- hard delete yerine status/archive
- referential integrity korunur

Ürün pasife alma tercih edilir.

---

# 95. Content Delete Policy

Yayın içerikleri SEO açısından:

- redirect
- archive
- noindex

kararıyla yönetilir.

Rastgele 404 üretilmez.

---

# 96. URL Strategy

Public:

```text
/
 /urunler
 /urunler/[category]
 /urun/[slug]
 /hakkimizda
 /akademi
 /akademi/[slug]
 /ilham
 /ilham/[slug]
 /katalog
 /iletisim
 /hesabim
 /siparis-takip
```

Nihai Türkçe URL standardı SEO/Design phase'de sabitlenir.

---

# 97. Admin URL

Öneri:

```text
admin.larantecoffee.com
```

Public DNS'ten tamamen gizli olmak güvenlik değildir.

**V2.2 (B3 — 2026-09-17):** alan adı yönü kabul edildi — `www.larantecoffee.com` (kurumsal site + public B2C), `admin.larantecoffee.com` (yönetim), `b2b.larantecoffee.com` (B2B); DNS / hosting uygulama ayrıntıları ve sağlayıcı seçimleri açıktır (PHASE0 B3, B7).

Auth + 2FA + authorization zorunlu kalır.

---

# 98. B2B URL

```text
b2b.larantecoffee.com
```

---

# 99. API URL

Ayrı host zorunlu değildir.

Deployment kararına göre:

```text
api.larantecoffee.com
```

veya internal origin kullanılabilir.

Sırf mimari görünsün diye public API host açılmaz.

---

# 100. V2 ADR Listesi

```text
ADR-001-platform-structure
ADR-002-nextjs-app-router
ADR-003-admin-separate-surface
ADR-004-product-inventory-ownership-gate
ADR-005-retail-vs-b2b-pricing
ADR-006-inventory-ledger-reservation     (→ ADR-016'da birleşti; ayrı yazılmaz)
ADR-007-payment-provider
ADR-008-transactional-outbox
ADR-009-worker-job-strategy
ADR-010-auth-customer-admin-boundary
ADR-011-media-storage
ADR-012-analytics-event-layer
ADR-013-content-module
ADR-014-shipping-provider
ADR-015-orm-after-b2b-audit
ADR-016-inventory-reservation-contract   (2026-09-16: stok miktar modeli + B2B rezervasyon sözleşmesi)
ADR-017-deployment-portability           (2026-09-16 öncesi "ADR-016"; **henüz yazılmadı** — deployment / sağlayıcı seçimleri B3 / B7 ile tarihli beklemede 2026-09-18, Phase 1'i bloklamaz)
```

---

# 101. Uygulama Fazları

**V2.1 (H6):** Bu bölümdeki Faz 0–11 sırası ile `docs/plan/LARANTE_MASTER_PLAN_2026-09-15.md` §18'deki P0–P12 (+7B) sırası iki farklı resmi harita oluşturuyordu. **Master plan §18 yetkilidir**; bu bölüm kapsam listesi olarak kalır. Eşleme:

| ARCH Faz | Master plan Phase |
|---|---|
| Faz 0 audit + foundation | P0 (karar kilidi) + P1 (foundation; ledger yalnız ADR-016 onaylıysa) |
| Faz 1 design system | P2 |
| Faz 2 identity + content + media | P3 (identity / audit / settings); içerik ve medya P4 / P9 |
| Faz 3 catalog + retail pricing | P4 |
| Faz 4 inventory integration | P5 (inventory core + internal sözleşme) + P7B (B2B entegrasyonu; launch'ı bloklar) |
| Faz 5 cart + checkout + payment | P7 (P6 outbox / bildirim altyapısı önce gelir) |
| Faz 6 orders + notifications + shipping | P6 + P7 |
| Faz 7 customer experience | P8 |
| Faz 8 academy + leads | P9 |
| Faz 9 analytics + SEO + consent | P10 |
| Faz 10 premium home | P11 |
| Faz 11 production hardening | P12 |

## Faz 0 — B2B Ownership Audit + Foundation

- mevcut B2B repo envanteri
- Product owner
- Inventory owner
- ORM
- auth
- DB
- API
- test kanıtı
- integration strategy ADR

Paralelde:

- pnpm workspace
- Turbo
- apps/web
- apps/admin
- API skeleton
- worker skeleton
- CI
- TypeScript strict
- lint/test

**Production stok implementation audit sonucu olmadan finalize edilmez.**

**V2.1 çıkış koşulu (ADR-016 §6) — V2.3: sağlandı (2026-09-18):** ADR-004 + ADR-016 **onaylı**; stok birimi (B6b), rezervasyon anı / ömrü (B6c) karar; B6e **birim sınıfları** karar (paket / şişe / kutu / adet; proje sahibi hükmü: Phase 1 ledger kapısı sağlandı — varyant başına SKU verisi P4 / P7B veri hazırlığıdır, Phase 1'i bloklamaz); tam varyant eşleme **kuralı** kabul (B6a veri eşlemesi P4 import raporunda kanıtlanır). Kalıcı stok ledger'ı Phase 1'in ilk kodudur (`docs/tasks/PHASE1/P1-T05`); "ADR-016 onaysızsa P1 ledger'sız kapanır" yedek yolu tarihçedir.

---

## Faz 1 — Design System

- tokens
- typography
- grid
- navigation
- forms
- product components
- admin primitives

---

## Faz 2 — Identity + Content + Media

- customer auth
- admin auth + 2FA
- RBAC
- media
- content
- site settings
- catalog PDF

---

## Faz 3 — Catalog + Retail Pricing

- product
- categories
- coffee options
- search/filter
- pricing
- promotions
- SEO

---

## Faz 4 — Inventory Integration

Audit sonucu seçilen tek inventory owner'a adapter.

- read availability
- reservation
- commit
- adjustment
- audit

---

## Faz 5 — Cart + Checkout + Payment

- guest/member cart
- addresses
- invoice data
- shipping
- coupon
- payment provider sandbox
- havale
- idempotency

---

## Faz 6 — Orders + Notifications + Shipping

- lifecycle
- outbox
- worker
- SMS
- email
- manual shipping
- tracking

---

## Faz 7 — Customer Experience

- account
- favorites
- reorder
- reviews
- returns
- guest tracking

---

## Faz 8 — Academy + Leads

- calendar
- applications
- sample
- quote
- lead pipeline

---

## Faz 9 — Analytics + SEO + Consent

- internal dashboard
- event layer
- GA4
- GSC
- consent
- Meta conditional

---

## Faz 10 — Premium Home

- frame sequence
- brand story
- featured products
- academy story
- performance hardening

---

## Faz 11 — Production Hardening

- security audit
- restore drill
- payment failure drills
- load/concurrency
- accessibility
- Web Vitals
- legal content
- end-to-end regression

---

# 102. AI Geliştirme Protokolü

```text
GPT-5.6 Sol Extra High
Requirements + Architecture
        ↓
Claude Code + Fable 5.1
Implementation
        ↓
CI
        ↓
GPT Astra High
Independent Technical Audit
        ↓
GPT-5.6 Sol
Architecture/Requirement Review
        ↓
Claude
Fix
        ↓
Astra
Regression Audit
```

---

# 103. Claude Task Standardı

Her task:

```text
TASK ID
Requirement refs
ADR refs
Goal
Scope
Out of scope
Files allowed
Data migration impact
Security impact
Acceptance criteria
Tests required
Rollback notes
```

Claude büyük açık uçlu prompt ile tüm sistemi bir seferde yazmamalıdır.

---

# 104. Astra Audit Standardı

Astra'dan:

- dosya/satır
- severity
- reproduction/kanıt
- business impact
- exploit/risk uygun olduğunda
- missing test
- recommended fix direction

istenir.

Astra ilk pass'te mümkünse doğrudan refactor yapmaz; önce denetim raporu üretir.

---

# 105. Sol Architecture Review

Sol:

- requirement drift
- domain boundary
- duplicate ownership
- coupling
- data integrity
- long-term B2B fit
- unnecessary complexity
- future sellable platform fit

kontrol eder.

---

# 106. Definition of Done — Foundation V2

- [ ] requirements repo içinde
- [ ] architecture V2 repo içinde
- [ ] ADR structure var
- [ ] pnpm/Turbo kurulu
- [ ] apps/web build
- [ ] apps/admin build
- [ ] API skeleton build
- [ ] worker skeleton build
- [ ] TS strict
- [ ] lint
- [ ] unit test runner
- [ ] Playwright
- [ ] CI
- [ ] env validation
- [ ] security baseline
- [x] B2B ownership audit tamam (ADR-004 kanıt bölümü; 2026-09-18 kapanış)
- [x] Product/Inventory owner ADR onaylı (ADR-004 — 2026-09-18)
- [x] ORM ADR onaylı (ADR-015 — 2026-09-18)
- [x] Stok miktar modeli / B2B rezervasyon sözleşmesi ADR'si (ADR-016) onaylı (2026-09-18)

---

# 107. V2 Guardrails

## G1
Dual inventory master yok.

## G2
Dual product master yok; geçiş varsa geçici adapter açıkça belgelenir.

## G3
B2B pricing web'e taşınmaz.

## G4
Public retail checkout server authoritative.

## G5
Payment idempotency zorunlu.

## G6
Notification failure order'ı kaybettirmez.

## G7
Admin 2FA + server RBAC.

## G8
Stock adjustment reason + audit.

## G9
Client-side analytics finansal source of truth değildir.

## G10
No premature microservices.

## G11
No premature dedicated search/broker unless measured need.

## G12
Hero animation core commerce performance'ını bozamaz.

## G13
AI-generated code testsiz merge edilmez.

## G14
B2B repository görülmeden rewrite kararı verilmez.

---

# 108. V1'den Değişen Ana Kararlar

| V1 | V2 |
|---|---|
| yalnız `apps/web` ile başlanabilir | `web + admin + API + worker` ilk mimari |
| typed static content yeterli olabilir | DB-backed product/content/admin gerekli |
| ayrı DB gerekmeyebilir | commerce/customer/order için PostgreSQL gerekli |
| admin gelecekte | admin V1 zorunlu |
| e-commerce belirsiz | e-commerce ana domain |
| stock integration gelecekte | tek stok kaynağı launch gereksinimi |
| notifications basit | outbox + worker |
| analytics genel | internal source + event layer + GA4/GSC |
| auth public için yok | customer auth + admin auth/2FA |
| B2B integration sonra | ownership audit Faz 0 gate |

---

# 109. Kaynak Notları — 2026-09-15

Güncel teknoloji kontrolü resmi kaynaklara göre:

- Next.js blog: 16.3 serisi ve 16.3.3 Active LTS güvenlik patch'i
- React: 19.3 yayımlandı
- Tailwind CSS: 4.3 yayımlandı

Scaffold sırasında exact dependency versiyonları tekrar security check edilip lockfile'a sabitlenecektir.

---

# 110. Son Mimari

```text
                       LARANTE PLATFORM
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
       PUBLIC WEB          ADMIN               B2B
          │                   │             mevcut / audit
          └──────────┬────────┘                   │
                     ▼                            │
               PLATFORM API ◄──── Adapter ───────┘
                     │
       ┌─────────────┼─────────────┐
       │             │             │
       ▼             ▼             ▼
   PostgreSQL    Object Storage   Worker
       │                         │
       │                    Outbox/Jobs
       │                         │
       └─────────────────────────┘
```

Ana teknik yaklaşım:

```text
Next.js + React + TypeScript
PostgreSQL
Modular Monolith
Ports & Adapters
Transactional Outbox
Server-First Rendering
RBAC + Admin 2FA
Single Product/Inventory Ownership
Provider-independent Payment/SMS/Shipping/Analytics
```

**Bir sonraki zorunlu teknik adım:**  
~~Mevcut B2B repository'nin Product / Inventory / ORM / Auth / API gerçekliğini incelemek ve `ADR-004-product-inventory-ownership-gate` kararını kapatmak.~~ **Tamamlandı (2026-09-18):** audit yapıldı, ADR-004 onaylandı. Sonraki adım: Phase 1 görev dosyaları (`docs/tasks/PHASE1/`) — scaffold / altyapı temelleri + onaylı envanter ledger / concurrency sözleşmesi.

**Bir sonraki tasarım dokümanı:**  
`LARANTE_DESIGN_SYSTEM.md`
