# LARANTE WEB PLATFORMU — ALTYAPI VE MİMARİ KARAR DOKÜMANI V2

**Dosya:** `LARANTE_WEB_ALTYAPI_MIMARISI_V2.md`  
**Sürüm:** 2.0  
**Tarih:** 2026-09-15  
**Durum:** Gereksinim sonrası revize ana mimari  
**Kaynak gereksinim:** `LARANTE_WEB_REQUIREMENTS.md`  
**Önceki sürüm:** `LARANTE_WEB_ALTYAPI_MIMARISI_V1.md`

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

## 5.5 Database

- PostgreSQL

## 5.6 ORM

**Henüz kilitlenmez.**

Kural:

- B2B gerçekten Prisma kullanıyorsa ortaklık için Prisma öncelikli değerlendirilir.
- Aksi durumda güncel alternatifler ADR ile değerlendirilir.
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

Fiziksel stok modeli üretim gerçekliğine göre:

- sellable SKU
- bulk inventory
- packaging conversion

arasından B2B/stok audit sonrası kesinleştirilir.

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
InventoryItem
InventoryBalance
InventoryMovement
InventoryReservation
```

Türetilebilir değerler:

```text
on_hand
reserved
available
```

`available` mümkün olduğunca türetilir:

```text
available = on_hand - reserved
```

---

# 17. Inventory Ledger

Sadece `quantity = 42` saklayan kör model yeterli değildir.

Stok hareketleri:

```text
PRODUCTION
SALE
RETURN
DAMAGE
WASTE
COUNT_ADJUSTMENT
MANUAL_ADJUSTMENT
RESERVATION
RELEASE
```

gibi nedenlerle kaydedilebilir.

Audit ile ilişkilendirilir.

---

# 18. Public Inventory Projection

Public web:

```text
available > 0
→ Add to Cart

available <= 0
→ Out of Stock
```

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
quantity
```

gibi immutable geçmiş bilgileri korur.

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
short reservation
↓
payment flow
├── success → reservation commit / sale
└── failure/timeout → release
```

Reservation TTL yönetilebilir.

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
- non-negative quantities
- foreign keys
- unique idempotency key
- reservation validity

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

Audit sonrası public ihtiyaçlar için sözleşme:

```text
CatalogReadPort
InventoryReadPort
InventoryReservationPort
InventoryCommitPort
```

uygulanabilir.

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
ADR-006-inventory-ledger-reservation
ADR-007-payment-provider
ADR-008-transactional-outbox
ADR-009-worker-job-strategy
ADR-010-auth-customer-admin-boundary
ADR-011-media-storage
ADR-012-analytics-event-layer
ADR-013-content-module
ADR-014-shipping-provider
ADR-015-orm-after-b2b-audit
ADR-016-deployment-portability
```

---

# 101. Uygulama Fazları

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
- [ ] B2B ownership audit tamam
- [ ] Product/Inventory owner ADR onaylı
- [ ] ORM ADR onaylı

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
Mevcut B2B repository'nin Product / Inventory / ORM / Auth / API gerçekliğini incelemek ve `ADR-004-product-inventory-ownership-gate` kararını kapatmak.

**Bir sonraki tasarım dokümanı:**  
`LARANTE_DESIGN_SYSTEM.md`
