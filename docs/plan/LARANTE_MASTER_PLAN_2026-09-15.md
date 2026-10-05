# LARANTE WEB PLATFORMU — MASTER IMPLEMENTATION PLAN (Faz 0 Audit + Plan)

**Tarih:** 2026-09-15 · **Revizyon 1.1:** 2026-09-16 — stok / B2B sipariş-rezervasyon sözleşmesi (§8, §9, §11, §14, §15, §18, §19, §21, yeni §23; karar kaydı `docs/adr/ADR-016`; onaylı iş kuralları proje sahibi 2026-09-16) · **Mod:** PLAN MODE — hiçbir kaynak dosya değiştirilmedi; install/build/migration/test çalıştırılmadı (yalnız salt-okunur inceleme + git okuma komutları).
**Ana kaynaklar (tamamı okundu):** `LARANTE_WEB_REQUIREMENTS.md` v1.0, `LARANTE_WEB_ALTYAPI_MIMARISI_V2.md` v2.0, `LARANTE_CODEX_HANDOFF.md` (oturum sırasında eklendi).
**Yöntem:** 26 salt-okunur ajan (8 okuyucu → 8 bağımsız şüpheci doğrulayıcı → 5 domain gap analisti → 3 mimar merceği [risk / reuse / platform-fit] → hakem → eksiklik eleştirmeni) + kritik olguların benim tarafımdan bizzat dosya açılarak teyidi. Ham çıktılar: `%TEMP%\claude\...\scratchpad\audit\*.json` (bu oturumun scratchpad'i).

**Yol kısaltmaları**
- `B2B` = `C:\Users\Monster\Desktop\Larante Web Sitesi\b2b-portal\larante-b2b\app` (git HEAD `d75dc7d`, dal `refactor/tenant-foundation`)
- `LW` = `C:\Users\Monster\Desktop\larante-web` · `LS` = `C:\Users\Monster\Desktop\Larante Web Sitesi\larante-site` · `DASH` = `C:\Users\Monster\Desktop\Dashboard`
- `REQ §n` = REQUIREMENTS bölümü · `ARCH §n` = MİMARİ V2 bölümü · `R1-R12`, `G1-G14` = guardrail'ler

---

## 0. Context

Larante için premium kurumsal web + B2C e-ticaret + admin + Akademi + lead + içerik platformu kurulacak; **mevcut B2B ile tek Product/Inventory kaynağı** paylaşılacak (REQ §31, §112; ARCH §3 "Production Gate"). Dokümanlar Faz 0'da B2B repository audit'i yapılmadan ownership kararı verilmesini yasaklıyor (R12, G14, ADR-004). Bu plan o audit'i yapar, kararı kanıta bağlar ve Codex adversarial denetimine (HANDOFF §"Codex'in ilk görevi") sunulacak master planı verir.

**İlk tespit:** çalışma dizini `LARANTE WEB SİTESİ - v1` içinde **hiç kod yok** (3 markdown; git reposu değil; `docs/` klasörü yok — dokümanlar kökte). "Mevcut sistem" Desktop'taki kardeş klasörlerdedir (kullanıcı onayıyla kapsama alındı):

| Aday | Yol | Ne |
|---|---|---|
| **Mevcut B2B** | `B2B` | 56 commit (2026-08-17 → 09-12), TanStack Start + Cloudflare Workers + D1 + R2, Higgsfield platformunda |
| Önceki web denemesi | `LW` | pnpm workspace + Next.js `apps/web` iskeleti (197 satır kod), D-001..D-009 karar dokümanları, 19 commit |
| Önceki statik site | `LS` | tek dosya `index.html` (1769 satır) + 50 MB asset; hiç deploy edilmedi |
| Veri kaynağı bağlamı | `DASH` + claude.ai skill Excel'leri | Python/Streamlit kârlılık dashboard'u (Logo e-Fatura PDF → SQLite), Logo kodlu ürün/fiyat Excel'leri |
| Bağlam dokümanları | `Desktop\B2B_Durum_Analizi_ve_Plan_2026-09-14.md`, `Desktop\Isletme_Sistemi_B2B_Guncel_2026-09-14.md` | doğrulanmamış bağlam (B2B gereksinim revizyonu v2.0) |

---

## 1. Executive Summary

1. **Mimari dokümanın B2B varsayımları yanlış.** ARCH §5.4 "Node/Express" ve §5.6 "Prisma ise Prisma" — gerçek B2B: **Bun + TanStack Start + Cloudflare Workers + D1 (SQLite, ham SQL, ORM yok) + R2**, deploy config'i Higgsfield platformu üretiyor, tek D1 preview+prod paylaşımlı. Postgres/Prisma "uyum" koşulu boş; ORM kararı serbest.
2. **B2B bir Inventory owner DEĞİL.** `products.stock REAL` yalnızca admin formundan elle yazılan bir sayı; sipariş oluşturma stoğu ne okur, ne düşer, ne rezerve eder (`$action.ts:610-614`, `:712-726`); ledger/rezervasyon/hareket tablosu yok; seed'de tüm ürünler `stock=0`; stok testi sıfır. → **ARCH §3 Seçenek B**: `apps/platform-api` (Postgres) Product identity + Inventory master olur, B2B tüketici olur. Seçenek A uygulanamaz; Seçenek C yalnız kimlik köprüsü (`variant_external_codes`, varyant düzeyi — rev. 1.1) düzeyinde gerekli.
3. **B2B'nin Product master'ı zayıf ama fiyat domaini sağlam.** Varyant/kategori tablosu/slug/KDV/fiyat geçmişi yok; doğal anahtar ürün ADI; ama `dealerPrice/effectiveDiscount/categoryDiscountsFor/activeCampaignsFor/productDiscount` server-side authoritative ve entegrasyon testli → **B2B fiyatlaması B2B'de KEEP (G3), web'e kopyalanmaz**. B2B `products` tablosu "B2B kanal projeksiyonu" olarak kalır; eşleme platformda `variant_external_codes(system='b2b')` (varyant düzeyi — rev. 1.1, ADR-016 K6).
4. **Ürün master'ı bugün fiilen 4 kopya** (B2B D1 ad-anahtarlı / skill Excel'leri Logo kodlu / Dashboard SQLite normalize-ad / Dashboard Eylül fiyat listesi) ve ayrışmış (Çikolata Şurup 450/400/500; 142 üründe maliyet farkı). G2 ihlali kodda değil ama veri düzeyinde gerçekleşmiş → tek import aracı + Logo kodu köprüsü zorunlu.
5. **Yeniden kullanım kod düzeyinde ~%5-10, desen/veri/varlık düzeyinde yüksek.** Port edilecek saf parçalar: PBKDF2/oturum-cookie/CSRF/TOTP/RBAC matrisi/kilit (`core.server.ts`), zod şemaları + `OrderSchema` "fiyat istemciden alınmaz" sözleşmesi, `files.server.ts` dosya güvenliği, LW `env.ts`/`site.config.ts`; 179 ürün seed'i, 94 ürün görseli (+2048 PNG), vektör logo, hero kare dizisi. Geri kalan commerce domaini (varyant, retail pricing, inventory ledger, cart/checkout, payment, order state machine, outbox/worker, promotion, review, wishlist, return, academy, lead, content, media, newsletter, settings, analytics, yapısal audit, RetailCustomer, admin app) **NEW**.
6. **Repo kararı: AYRI REPO + versiyonlu HTTP sözleşmesi** (`larante-platform` pnpm+Turbo+Next.js+Postgres; B2B Bun/Workers/D1'de kalır). Monorepo'ya alma iki package manager, vendored `@higgsfield/*` workspace paketleri ve Higgsfield deploy CI'ının repo'daki wrangler.jsonc'yi yok sayması nedeniyle bugün doğrulanamaz.
7. **İki kritik yeni bulgu (eleştirmen + bizzat teyit):** (a) **Deploy hattındaki kod `origin/main` = `bb2c415` (17 Ağu MVP), HEAD'in 54 commit gerisinde, yalnız migration 0001-0002 içeriyor** → audit'in "MEVCUT/KEEP" dediği tenant/CSRF/2FA/RBAC/kampanya/koli/0021 kodunun **hiçbiri canlıda değil**; canlı portal büyük olasılıkla CSRF/2FA/tenant'sız MVP. (b) **B2B Worker'ın keyfi dış hosta HTTPS çıkışı doğrulanamadı** (`wrangler.jsonc:38-41` "platform Outbound Worker injects secrets on egress"; `packages/fnf/ai/AGENTS.md:166-170` kimlik yalnız `fnf.internal`'a) → B2B→platform stok çağrısı (P7) fizibilitesi Higgsfield'a yazılı sorulmalı; cevap "hayır" ise tek yol B2B'nin kendi Cloudflare hesabına taşınması.
8. **Kodlamadan önce çözülmesi gereken blocker'lar (2026-09-15 tespiti — güncel durum 2026-09-18: ADR-004 / ADR-016 onaylı, Phase 1 için kalan blokaj yok; kalan kalemler ilgili faz öncesi, bkz. §19 / §23):** ADR-004 onayı (Seçenek B — **verildi 2026-09-18**); B2B barındırma/egress/deploy hattı + canlı D1 migration seviyesi; fiyat gerçeği (hangi liste güncel, KDV dahil/hariç, perakende fiyat listesi yok); kategori taksonomisi; varyant eşlemesi (B6a — açık; stok birimi ve rezervasyon anı 2026-09-16'da ADR-016 ile karara bağlandı — **ADR-016 onaylı 2026-09-18**); sağlayıcılar (PSP/e-posta/SMS/Postgres hosting); skill Excel'lerinin repo'ya alınması.

---

## 2. Repository'de DOĞRULANAN mevcut durum

### 2.1 28 maddelik öncelikli inceleme — kanıt tablosu

| # | Konu | Bulgu | Kanıt (dosya / sembol) |
|---|---|---|---|
| 1 | Klasör/repo yapısı | Çalışma dizininde kod yok. B2B: `larante-b2b/{app,refs,CLAUDE.md,IS-AKISI.md,.github}`; `app/{src,migrations,packages,public}`; `src/routes/api/b2b/$action.ts` tek API dosyası | `ls`, `find` (bizzat) |
| 2 | Framework | TanStack Start 1.168 + TanStack Router + React 19.2 + Vite 7 + Nitro (SSR Worker) | `B2B\package.json` deps; `src/router.tsx`, `src/server.ts` |
| 3 | Frontend | React + Tailwind 4.2 + Radix/shadcn (yalnız şablon ölü kodda); B2B ekranları `admin.tsx` (1641 satır), `panel.tsx` (889), `kayit.tsx`, `index.tsx` inline stil, yalnız `lib/b2b/ui.tsx` import eder | `src/routes/*.tsx` (bizzat wc) |
| 4 | Backend | Cloudflare Workers (`nodejs_compat`), Express yok; 38 `action === "…"` if-zinciri (17 GET + 21 POST) | `$action.ts:249-1979` (bizzat: 38 dal); `wrangler.jsonc:21-24` |
| 5 | Package manager | **Bun** (`bun.lock`, `bunfig.toml minimumReleaseAge`), workspaces `packages/*` (vendored `@higgsfield/fnf|fnf-react|quanta`); CI `oven-sh/setup-bun@v2` | `package.json:6-8,26-28`; `.github/workflows/ci.yml` (bizzat) |
| 6 | Monorepo | Hayır (tek app + vendored paketler). LW: pnpm workspace kabuğu ama `packages/` dizini yok, turbo yok | `pnpm-workspace.yaml` (LW) |
| 7 | Veritabanı | **Cloudflare D1 (SQLite)**; tek DB preview+prod paylaşımlı; KV kapalı, DO yok, cron yok | `wrangler.jsonc:56-59,65`; `app.manifest.json {db:true,r2:true,kv:false,durableObject:null}`; `src/lib/bindings.server.ts:7` `import { env } from "cloudflare:workers"` |
| 8 | ORM | **YOK** — `db().prepare().bind().all/first/run` ham SQL; `pg/prisma/drizzle/kysely` yok | `core.server.ts:11-21`; `package.json` grep (bizzat) |
| 9 | Migration | Ham SQL `migrations/0001..0021_*.sql`; runner repoda yok; `0001_init.sql:1-2` "Applied by the platform on deploy"; CLAUDE.md "elle wrangler d1 execute" (çelişki); 0018/0019 DROP+CREATE rebuild (additive değil); SQLite'a özgü (355 `RAISE(ABORT)`, `COLLATE NOCASE`) | `migrations/0018:222,332,454`, `0019:260-742`; yerel miniflare D1'de `d1_migrations` 0001-0010 kayıtlı |
| 10 | Product modeli | Tek düz tablo `products(id TEXT, sku TEXT[boş], name, category TEXT[düz string], unit TEXT[serbest], list_price REAL, stock REAL, active, sort, image_key, box_count, box_unit_price REAL, weight_kg, moq REAL, tenant_id NOT NULL)`; slug/SEO/medya tablosu/nitelik yok; id serileri `p001/n001/u001`; yeni id `MAX(sort)+1` tenant filtresiz; doğal anahtar ürün ADI (`WHERE name=`) | `0002_b2b.sql:7`; `0019:262-278` (bizzat); `$action.ts:1112-1116`; `0004:5-6`, `0006:4-5` |
| 11 | Product Variant | **YOK** — her gramaj ayrı satır; `unit` serbest metin ('750 ML','1000 GR','KUTU'); kavrum/öğütüm kavramı hiçbir kaynakta yok | grep variant/varyant/sku → 0 (kod); `0006` unit dağılımı 11 değer |
| 12 | Category | Ayrı tablo YOK, hiyerarşi yok; `0008` Excel'den 5 değer (Aroma 94 / Pasta 37 / Kahve 27 / Çay 19 / Donuk 2) ile `WHERE name=` UPDATE; UI kategori setini `new Set(products.category)` ile türetir | `0008_excel_kategoriler.sql`; `panel.tsx:115-117` |
| 13 | Inventory/Stock | Yalnız `products.stock REAL` **kör kolon**; ledger/balance/rezervasyon tablosu YOK; seed'de hepsi 0; yerel D1'de `stock>0` = 0 satır | grep stok/stock/inventory/rezerv/movement → yalnız bu kolon (bizzat); `0002:14+` |
| 14 | Inventory movement | **YOK**; stok yalnız admin `admin-product-save` mutlak atama (`UPDATE products SET ... stock = ?`); sebep yok, delta yok | `$action.ts:1086-1093, 1119-1127`; `admin.tsx:1523-1534` |
| 15 | Reservation | **YOK**; sipariş SELECT'inde `stock` bile yok; batch yalnız INSERT orders/order_items; `in_stock: p.stock > 0` rozeti siparişi engellemez | `$action.ts:610-614, 712-726, 580` (bizzat); `panel.tsx:150-154, 679-686` |
| 16 | Pricing | `list_price` (REAL, KDV kavramı YOK), `box_unit_price` (bağımsız ikinci fiyat, liste fiyatından türetilmez), `weight_kg` → kg fiyatı; fiyat geçmişi YOK (0006 yerinde UPDATE); **server-side authoritative** (`OrderSchema` fiyat kabul etmez) | `$action.ts:109-121, 524-578, 639-695` (bizzat); `core.server.ts:668-670` |
| 17 | B2B müşteri iskontosu | 4 katman: `dealers.discount_pct` → `price_groups.discount_pct` (dealer.price_group_id) → `dealer_category_discounts` (kategori override) → `campaigns` (yüzde, tarih penceresi, en avantajlısı kazanır, zincirleme yok); MOQ + kredi limiti kontrolü server'da | `core.server.ts:674-705, 844-873`; `0003:2-8`, `0005:2-11`, `0007:3-8`; `$action.ts:629-705` |
| 18 | Auth | `admins`/`dealers` ayrı tablolar; PBKDF2-HMAC-SHA256 100k tur (WebCrypto, `crypto.subtle.timingSafeEqual`); D1 `sessions` (opak token 68 kar., düz metin), cookie `lb_session HttpOnly; Secure; SameSite=Lax; 7 gün`, rotation/sliding YOK; **admin TOTP 2FA VAR** (opsiyonel, replay/recovery yok, secret düz metin); hesap kilidi 5/15dk (eskalasyonsuz); IP rate limit YOK; şifremi unuttum/e-posta YOK | `core.server.ts:9,45-82,86-180,418-455,572-575,717-758,760-830` (760-830 bizzat teyit); `$action.ts:339-460,1300-1420` |
| 19 | Authorization/RBAC | `ADMIN_ROLES owner/admin/viewer` (owner==admin), `ROLE_CAPABILITIES read/write/self-security/export`; `requireAdmin(request, capability)` 24 uç, `requireDealer` 5, `capabilityDenied` 3 — **server-side, UI-only değil**; ama global middleware yok (her blokta elle); admin kullanıcı CRUD/rol atama ucu YOK; 0020 trigger rolü 3 değere kilitler | `core.server.ts:488-529,634-664`; `0020:95-107` |
| 20 | Multi-tenant | `tenants` (tek seed tenant `ce66d3d2…/larante`), `tenant_domains` (hostname tam eşleşme, fail-closed, **tohumsuz**), 10 tabloda `tenant_id NOT NULL`, FK yerine 34+ BEFORE trigger (0016), oturum tenant'ı host tenant'ına eşit olmalı; `order_items/product_docs/dealer_category_discounts` tenant_id taşımaz | `0013`, `0016`, `0017:75-97`, `0019`; `core.server.ts:357-416, 598-599` |
| 21 | API yapısı | Tek HTTP route `/api/b2b/$action` (cookie + CSRF); **servis-token/Bearer makine API'si YOK**; `createServerFn` yalnız şablon örneğinde; DTO yok (D1 satırları doğrudan JSON, 24 `.results`; `admin-export` `SELECT *`) | `$action.ts:1972-1979`; grep bearer/authorization → 0 |
| 22 | Validation | zod 4, 16 istek şeması + `parseBody` (safeParse → 400 `invalid_input`); çıkış şeması yok | `$action.ts:58-208` |
| 23 | Test | vitest 4; 17 `*.test.ts` + `tenant-fixture.ts` (~22.8k satır; 495 statik it/it.each, 92 describe); 12 dosya sahte D1 ile `handle()` uçtan uca, 9 dosya gerçek `node:sqlite` migration testi, **12 dosya kaynak-metin pini** (`readFileSync` + string sayımı — refactor'da kırılır); stok/oversell/idempotency/yarış testi **sıfır**; coverage yok; testlerin geçtiği DOĞRULANAMADI (çalıştırma yasak) | `vitest.config.ts`; `__tests__/` (bizzat wc); `admin-rbac.test.ts:1575-1633` |
| 24 | CI/CD | GitHub Actions `ci.yml`: bun install --frozen-lockfile → typecheck → build (HF_DESIGN_INSPECTOR=1) → test:b2b → lint:b2b → `bun audit --audit-level=critical`; deploy adımı YOK; push tetiği koşu üretmiyor (CLAUDE.md §9; son 2 commit "push tetiği deneyi"); Node sürümü sabitlenmemiş | `.github/workflows/ci.yml` (bizzat) |
| 25 | Deployment | Higgsfield platformu: `origin = apps-repos.higgsfield.ai`, `backup = github.com/larantekahve/larante_b2b`; deploy CI `wrangler.jsonc`'yi `app.manifest.json`'dan üretir; sırlar Worker'a girmez ("Outbound Worker"); **`origin/main` = `bb2c415` (17 Ağu MVP), HEAD 54 commit ileride, yalnız 0001-0002 migration** (bizzat: `git rev-list --count origin/main..HEAD`=54, `git ls-tree origin/main app/migrations/`); origin erişilebilirliği DOĞRULANAMADI (CLAUDE.md 7 Eyl "repository not found") | `wrangler.jsonc:3-9,38-41`; `git remote -v`; `git log origin/main` |
| 26 | Logging/audit | `audit_log(actor_type, actor_name, action, detail≤500, tenant_id)` serbest metin, 12 çağrı; entity_id/before/after/ip YOK; login/2FA/şifre olayları loglanmıyor; BEFORE DELETE guard yok; `security-headers.server.ts` tanımlı ama **hiç çağrılmıyor** (bizzat grep); observability yalnız `console.error` + wrangler `observability.enabled` | `core.server.ts:879-900`; `src/server.ts` (import yok) |
| 27 | Dashboard/admin kodu | B2B `admin.tsx` tek dosya (bayi onay, ürün satır düzenleme [yalnız price/stock/moq/active], sipariş durumu, kampanya, fiyat grubu, tahsilat, audit, export); client-side `useEffect+navigate` gating; **doğrulanmış bug:** `admin-products` GET `moq` döndürmüyor → her satır kaydında `COALESCE(0,moq)=0` MOQ sıfırlanır; yeni ürün ekleme butonu yok. `DASH` Python/Streamlit ayrı ürün, B2B ile bağsız | `$action.ts:1069 vs 1086`; `admin.tsx:1524-1535` |
| 28 | Yeniden kullanılabilir modüller | Bkz. §6 KEEP/REFACTOR/REBUILD. Kod: identity primitifleri, zod şemaları, `files.server.ts`, fiyat kuralı (yalnız B2B'de), LW `env.ts`/`site.config.ts`. Veri/varlık: 179 ürün seed'i, Logo kodlu `urun_maliyet.xlsx` (216), 94 görsel + 2048 PNG, `logo.svg`, hero kareleri, `design-package.md` kopya bankası | — |

### 2.2 B2B iş akışı (kod, bizzat okundu)
- Sipariş: `POST order` → tenant'ın aktif ürünleri → MOQ (adet + koli×box_count) → iskonto zinciri server'da → kredi limiti (`balance + total > credit_limit` → 403) → `order_no = MAX(order_no)+1` (**tenant filtresiz, INSERT'ten ayrı** → 0021 UNIQUE(tenant_id, order_no) yarışta ikinciyi RAISE(ABORT)=500 ile düşürür, retry yok) → `db().batch([INSERT orders, INSERT order_items…])` → `addTransaction('siparis')` (**dönüşü kontrol edilmiyor**, ayrı batch) → `audit()` (ayrı run). Idempotency YOK (`crypto.randomUUID()`). Durumlar `onay/uretimde/kalite/sevkiyat/teslim/iptal`, geçiş grafı YOK (`teslim→onay` serbest); iptal/geri-alış üçlü koşullu batch + `changes===1` (iyi desen). Para ve miktar REAL; `qty` tamsayı zorunlu değil. Ödeme = admin elle tahsilat; kargo = etiket; bildirim/e-posta/SMS/PSP/webhook YOK.

### 2.3 larante-web (LW) — önceki Next.js denemesi
Next 16.3.4 · React 19.2.8 · **TS 7.0.2 (Go derleyici; typescript-eslint uyumsuz; D-009 6.0.3 kararı uygulanmamış)** · Tailwind 4.3.3 · Zod 4.5.4 · Vitest 5.0.0 · Node 24 kilidi. Kod: 6 dosya / **197 satır** (`env.ts` Zod env doğrulama + 13 test; `site.config.ts` strictObject feature-flag + 10 test; `instrumentation.ts` fail-fast; placeholder layout/page; tek satır CSS). DB/ORM/auth/UI/SEO/i18n YOK; turbo/ESLint/Prettier/Playwright/CI YOK. ~2.900 satır doküman (ARCHITECTURE.md 1300 satır 18 faz; D-001..D-009; T-001 362 satır). D-003 tek kiracı (tenant_id yok), D-005 URL/slug kuralları, D-007 TR VPS "kısmen açık", D-008 Drizzle kararı (kurulmamış), D-005/D-008 admin'i aynı app'te `/admin` tanımlar (ARCH §51 ile çelişir). Uzak repo yok.

### 2.4 larante-site (LS) + varlıklar
Saf HTML tek dosya (1769 satır; 666 satır inline CSS + 837 satır inline JS: hash router, hero MP4 scrub, filtre, form `mailto:`); 14 içerik bölümü 29.08'de boşaltılmış; `og:url = LIVE-URL-PLACEHOLDER` → **hiç deploy edilmedi**. Koyu espresso palet (REQ §73 açık zemin ile çelişir), Verdana. Varlıklar: 94 ürün JPEG 1024² (Aroma grubu: 45 şurup, 24 püre, 17 baz, 8 sos) + 2048² saydam PNG kaynakları (`Sos\*`), `hero-scrub.mp4` 28,6 MB/36 sn (7 sahne, REQ §10.1 akışıyla aynı), 4K kare dizisi 66/75 (65-73 eksik, 552 MB PNG), **tek vektör logo** `Sos\katalog\assets\logo\logo.svg` (kaynak PDF raster), `design-package.md` kopya bankası, e-katalog PDF (arka kapakta kişisel e-posta — pdftotext ile doğrulandı). **Kahve/Toz/Çay/Pasta ürün fotoğrafı YOK.** Katalog PDF üretim zinciri kırık (scratchpad'deki kayıp `cdp.mjs`'e mutlak yol; `chrome.exe` sabit yol; Windows fontları). Tüm görseller AI üretimi (REQ §23 "AI hissi düşük" gerilimi).

### 2.5 Gerçek veri kaynakları (DASH + skill Excel'leri)
- `DASH`: Logo e-Arşiv/e-Fatura PDF'lerinden (689 PDF, Oca-Ağu 2026, 2.264 satır, 107 müşteri VKN/TCKN, 311 tekil ürün) pdfplumber → SQLite; ürün anahtarı **normalize AD** (Logo kodu 2.264 satırın 1'inde); KDV oranları faturada **%1 (2.195 satır) / %20 (69 satır)**; stok kavramı yok; B2B ile API/export bağı yok.
- Skill Excel'leri (`%APPDATA%\Claude\local-agent-mode-sessions\...\skills\larante-{karlilik,teklif,karne}\data\`): `urun_maliyet.xlsx` **216 ürün, Logo Malzeme Kodu `ddd.ddd.ddddd` + ad + ana birim + koli içi adet + gramaj** (tek yapılandırılmış `external_accounting_code` kaynağı); `satis_listesi.xlsx` 181 ürün Logo kodlu liste fiyatı + alt grup + marj/min-fiyat kuralları (zincirleme iskonto — B2B kodundaki "tek oran" kuralıyla ÇELİŞİR; A-12 açık). Dosyalar claude.ai oturum klasöründe, 22-24 Ağustos tarihli, kalıcı değil. `musteriler.xlsx` diskte YOK.

---

## 3. DOĞRULANAMAYAN / belirsiz alanlar

| Konu | Durum |
|---|---|
| Canlı B2B portalında hangi commit koşuyor | DOĞRULANAMADI — `origin/main` MVP (bb2c415), ağ erişimi yapılmadı; `larante-b2b.higgsfield.app` (LS `index.html:738`) |
| Canlı D1 migration seviyesi | DOĞRULANAMADI — CLAUDE.md "0002'de" der; origin/main yalnız 0001-0002 içerir (dolaylı destek); yerel miniflare D1 0010 seviyesinde (28 Ağu) |
| Higgsfield deploy hattı erişilebilirliği | DOĞRULANAMADI — CLAUDE.md 7 Eyl "repository not found" beyanı; push denenmedi |
| Platformun migration'ları deploy'da otomatik uygulayıp uygulamadığı | ÇELİŞKİLİ — `0001_init.sql:1-2` "evet", CLAUDE.md "elle"; otomatikse ilk HEAD deploy'u paylaşımlı prod D1'de 19 migration'ı (DROP+CREATE rebuild + 355 preflight abort dahil) tek seferde koşturur |
| B2B Worker'dan keyfi dış hosta HTTPS egress | NOT_FOUND — Outbound Worker + `fnf.internal` kimliği belgeli; keyfi host izni belgesiz; B2B kodunda hiç dış `fetch` yok |
| Higgsfield'ın yanıtlara güvenlik başlığı ekleyip eklemediği | DOĞRULANAMADI (`security-headers.server.ts:7-14` yorumu iddia ediyor) |
| B2B testlerinin fiilen geçtiği (CLAUDE.md "1471 runtime test") | DOĞRULANAMADI — çalıştırma yasak; statik 495 |
| Canlı D1'de `products.stock` gerçek değerleri, `tenant_domains` doluluğu | DOĞRULANAMADI |
| `list_price` KDV dahil mi hariç mi | Kodda/migration'da belirtilmiyor |
| Hangi fiyat listesi güncel (B2B 0006 18 Ağu / skill 24 Ağu / Dashboard Eyl) | ÇELİŞKİLİ (450/400/500; 1500/1800) |
| Logo ERP'nin gerçek malzeme/stok/fiyat kartları | Erişim yok |
| `musteriler.xlsx` (teklif/iskonto kaydı) | Diskte NOT_FOUND |
| Supabase "Larante Kahve" projesinin içeriği | Açılmadı (MCP kullanılmadı) |
| moq sıfırlanma bug'ı | Yalnız kod okumasıyla (3 bağımsız teyit), çalıştırılmadı |
| Perakende (B2C, KDV dahil) fiyat listesi | Hiçbir kaynakta YOK |

---

## 4. Requirements Gap Analysis

Statü: **MEVCUT** yalnız kodda kanıtlıysa; **KISMEN** = desen/veri var, iş kuralı/model yok; **YOK**. Karar: KEEP (B2B'de yerinde) / REFACTOR (port+uyarlama) / REBUILD / NEW. Not: "MEVCUT" olan B2B kodu **HEAD'dedir, canlıda değildir** (bkz. §1/7). Tam satır seti (≈160 satır) audit JSON'larında (`gap_G1..G5.json`).

### 4.1 Catalog (G1)
| Requirement | Statü | Reusable | Risk | Aksiyon / Karar |
|---|---|---|---|---|
| Kategori ağacı, admin'den genişletilebilir (§12, ARCH §12) | KISMEN (veri) | `0008` 5 değer; `araclar/katalog-veri.mjs` alt seri; kod YOK | 3 farklı taksonomi (REQ / B2B 5'li / eski menü); kampanya eşleşmesi düz string | NEW `product_categories(parent_id, slug, visible_public)`; seed |
| Kahve alt kategorileri, Espresso/Filtre ayrı ürün (§13, §17) | YOK | skill `satis_listesi` "Alt Grup" | Cappadocia Light/Medium/Night granülaritesi 3 kaynakta farklı | NEW; A-kararı (B6) |
| Gramaj/kavrum varyantı, ürün bazında aç/kapa (§14, §16) | YOK | — | B2B satırları gramaj varyantı karışık | NEW `sellable_variants(weight_g, roast_level, agtron, sku)` |
| Öğütüm = PreparationOption, SKU patlaması yasak (§15, R4) | YOK | — | 3×3×9=81 kombinasyon riski | NEW `preparation_options` (stok kalemi değil) |
| Tadım/teknik nitelikler (§18) | YOK | içerik yok | Arama/filtre/karşılaştırma buna bağlı | NEW typed `product_attributes`; içerik B8 |
| Ürün medya (ambalaj + lifestyle, çoklu, WebP) (§23, ARCH §40, §83) | KISMEN | 94 JPEG + 2048 PNG; `files.server.ts` (57 test) | Kahve/Toz/Çay görseli YOK; AI üretimi; tek `image_key`; B2B file ucu oturumlu+no-store | REFACTOR (files.server.ts port) + NEW `media`/`product_media` |
| Çok alanlı arama (§24), dinamik filtre/sıralama/kart (§22, §25, §26) | YOK | — | tsvector Türkçe konfig; "çok satanlar" sipariş agregasyonu ister | NEW (Postgres tsvector + pg_trgm, `SearchPort`) |
| Karşılaştırma + öneriler (§27, §29) | YOK | — | attribute'a bağımlı | NEW `product_relations` |
| Ürün kimliği: id/variant/slug/external code (ARCH §89) | YOK | `urun_maliyet.xlsx` Logo kodları; D-005 slug kuralı | B2B ad-anahtarlı; Logo'da aynı ürün 2 kod (Nar Şurubu) | NEW UUID + slug + `variant_external_codes` 1:N (logo, b2b; **varyant düzeyi** — ADR-016 K6) |
| Admin ürün yönetimi (§79) | KISMEN | zod `ProductSaveSchema` deseni | B2B admin eksik/hatalı (moq bug, yeni ürün yok, ad düzenlenemez) | REBUILD (apps/admin) |
| Seed/import + dual master yasağı (§112, G2) | KISMEN (veri) | 0006/0008/0009-0012, katalog-veri.mjs, urun_maliyet.xlsx | Master 4 kopya ve ayrışmış; Excel→migration deseni | NEW `tools/import-catalog` (idempotent upsert, dry-run) |

### 4.2 Retail Pricing (G1)
| Requirement | Statü | Reusable | Risk | Aksiyon |
|---|---|---|---|---|
| KDV dahil public fiyat, B2B'den bağımsız (§7.1, R1, G3) | YOK | `fmtTL`; fatura KDV oranları (%1/%20) — yalnız referans, oran kaynağı değil (B4d 2026-09-17: kontrollü Excel → tam varyant, sonra Logo salt-okunur; tahmin yok) | B2B KDV kavramı yok, para REAL | NEW `retail_prices(price_kurus, tax_rate_bp, tax_inclusive)` |
| Varyant bazlı fiyat, "başlangıç fiyatı" (ARCH §14) | YOK | — | perakende fiyat listesi hiçbir kaynakta yok (B4) | NEW + `min_price` materialized |
| Kampanya fiyatı + tarih penceresi (§48) | YOK | `activeCampaignsFor` tarih penceresi kuralı | B2B kampanya yüzde+dealer kapsamlı | NEW `retail_campaign_prices` |
| Fiyat geçmişi (§82, ARCH §54) | YOK | — | yerinde UPDATE, geçmiş yok | NEW append-only `price_history` |
| Server-side authoritative price (R6, G4) | **MEVCUT (B2B)** | `OrderSchema` + order handler | kompozisyon 2 kopya; panel.tsx 3. kopya (gösterim) | KEEP (kural) — retail için `PricingService.quote` tek fonksiyon |
| B2B pricing web'e taşınmaz (§7.2, ARCH §15, G3) | **MEVCUT** | `core.server.ts:668-873` | kod "tek oran" vs teklif skill'i "zincirleme+min fiyat" (A-12) | KEEP (B2B'de); B2B tarafında ayrı ADR |

### 4.3 Inventory (G1)
| Requirement | Statü | Reusable | Risk | Aksiyon |
|---|---|---|---|---|
| Tek yetkili stok, dual master yasak (§31, §112, R2, G1) | YOK | — | **B2B owner değil**; Isletme_Sistemi stok sahibini Logo sayar ama kod bağı yok, Workers yerel ağa erişemez | ADR-004 Seçenek B; B2B `stock` dondurulur |
| InventoryItem/Balance/Movement/Reservation, available türetilir (ARCH §16) | YOK | — | stok birimi kararı açık (A-13) | NEW ledger (INTEGER, CHECK; fiziksel hareket ↔ rezervasyon olayı ayrımı — ADR-016 K2) |
| Sebepli hareket + audit (§81, G8) | YOK | `addTransaction` fail-closed batch deseni (finans) | B2B stok mutlak atama, sebepsiz | NEW `reason NOT NULL enum` + audit |
| Admin stok ekranı (§80, R3) | YOK | — | — | NEW (WAREHOUSE rolü) |
| Public projeksiyon `available>0` (§30, R3) | KISMEN | `in_stock: p.stock>0` tek satır | B2B rozeti siparişi engellemez | NEW; checkout server kontrolü esas |
| Kart ödemede kısa TTL rezervasyon/commit/release (§41, ARCH §25) | YOK | koşullu batch deseni (`$action.ts:1192-1227`) | oversell | NEW atomik `UPDATE … WHERE on_hand-reserved>=q` |
| Havale 24s rezervasyon + worker expiry (§42) | YOK | — | B2B'de cron/worker yok | NEW (worker) |
| Concurrency + DB kısıtları + oversell testi (ARCH §62-63, §118) | YOK | fail-closed migration ilkesi | B2B'de FK yok, yarış testi yok | NEW; CI kapısı |
| B2B Integration Contract + ACL (ARCH §87-88) | YOK | — | Yön tersine (B2B tüketici); B2B'de makine API'si yok; egress belirsiz | NEW `/internal/v1/inventory` + B2B `platform-client` |
| Fiziksel stok birimi (ARCH §13) | YOK | `box_count`, `Ana Birim`, `Koli İçi Adet` | A-13 | V1: sellable variant + `stock_unit`, tamsayı; koli yalnız tamsayı katı + snapshot; donuk pasta kutu (ADR-016 K1, K7) |
| B2B siparişinin tek stoğa bağlanması | KISMEN | order handler + admin-order-status | atomik değil; pin testleri; deploy belirsiz; kesirli qty | REFACTOR (B2B repo PR, P7B — ADR-016 K4, K12) |

### 4.4 Cart / Checkout / Payment / Order / Shipping (G2) — 32 satır: MEVCUT 2, KISMEN 12, YOK 19
| Domain | Öne çıkan gereksinim | Statü | Reusable | Aksiyon |
|---|---|---|---|---|
| Cart | misafir+üye sepet, merge, uzun rezervasyon yok (§32, ARCH §19) | YOK | — | NEW `carts/cart_lines` (imzalı guest token) |
| Cart | client fiyatı güvenilmez, totals server (R6) | MEVCUT (B2B) | `OrderSchema` | KEEP kural, NEW impl |
| Checkout | 9 adımlı akış, misafir, adres, fatura tipi, kupon, yasal onay sürümleri (§33-37, §102, ARCH §92) | YOK | — | NEW |
| Checkout | misafir sipariş takibi + rate-limit (§38) | YOK | — | NEW (IP+hesap limit) |
| Payment | kart/3DS/havale; `PaymentProvider` port (§39-40, ARCH §23) | YOK | — | NEW + ADR-007 |
| Payment | webhook imza + idempotency (R7, ARCH §24, §64) | YOK | B2B'de idempotency hiç yok (çift POST = 2 sipariş) | NEW `payment_events(provider,event_id) UNIQUE` |
| Payment | iade/kısmi iade idempotent (§51) | KISMEN | iptal→'iade' cari batch | NEW |
| Order | durum makinesi (§43, ARCH §22) | KISMEN | `ORDER_STATUSES` (geçiş grafı yok — anti-örnek) | REBUILD (transition map) |
| Order | immutable snapshot (ARCH §21) | KISMEN | `order_items` ad/birim/fiyat snapshot | REFACTOR: + sku/variant/iskonto/KDV |
| Order | atomik oluşturma + outbox + idempotent submit (ARCH §29, §63-64, R11) | KISMEN | `db().batch` kısmi | REBUILD (Postgres transaction + SEQUENCE + idempotency_key) |
| Order | bildirimler e-posta+SMS retry (§44) | YOK | — | NEW (outbox/worker) |
| Order | admin sipariş yönetimi (§83) | KISMEN | `admin-orders`, guard deseni | REBUILD |
| Order | müşteri iptal/iade talebi (§51) | YOK | — | NEW |
| Order | B2B fiyat/sipariş B2B'de kalır (§111, R1) | MEVCUT | order handler | KEEP |
| Shipping | manuel takip no → SHIPPED → bildirim (§45, §84), `ShippingProvider` (§113) | YOK | — | NEW ManualAdapter |
| Shipping | ücretsiz kargo eşiği ayarı (§46) | YOK | B2B `settings` tablosu (ölü) | NEW `site_settings` |

### 4.5 Customer / Wishlist / Review / Promotion / Return (G3) — 41 satır: 33 YOK
| Domain | Öne çıkan gereksinim | Statü | Reusable | Aksiyon |
|---|---|---|---|---|
| Customer | misafir alışveriş (§34) | YOK | — (B2B register→pending→admin onayı modeli tam tersi) | NEW |
| Customer | e-posta+şifre üye, güvenli oturum, brute-force (§35) | KISMEN | `hashPassword/verifyPassword`, token/cookie parse, CSRF, `lockCheck` | REFACTOR → `packages/identity` (node:crypto, sürümlü hash ≥600k/argon2id, eskalasyonlu kilit) |
| Customer | şifremi unuttum, profil, çoklu adres, fatura profili (§35-37) | YOK | — | NEW |
| Customer | sipariş geçmişi + kargo (§35) | KISMEN | `orders` GET | REBUILD |
| Customer | B2C ≠ B2B kimliği (§111, ARCH §9) | KISMEN | `dealers` UNIQUE(tenant_id,email) | NEW `retail_customers` (tenant yok, discount yok); FK yok |
| Customer | güvenlik olay logu (§92) | YOK | `audit()` deseni | NEW `security_events` |
| Wishlist | favoriler (§49, ARCH §33) | YOK | — | NEW |
| Review | yorum + doğrulanmış alışveriş + moderasyon (§28, ARCH §34) | YOK | — | NEW |
| Promotion | kupon (kod UNIQUE, min sepet, limit, atomik kullanım) (§47, ARCH §32, §63) | YOK | `productDiscount` "max kazanır" kuralı (analog) | NEW `coupons` + `coupon_redemptions(order_id UNIQUE)` |
| Promotion | kampanya + fiyat geçmişi + tek indirim kaynağı (§48, ARCH §54) | KISMEN | tarih penceresi deseni | REFACTOR (kural) + NEW |
| Return | iptal/iade talebi, durum makinesi, refund idempotent, RETURN stok hareketi (§51, ARCH §35) | YOK | çift iptalde tek iade testi (şablon) | NEW |

### 4.6 Academy / Lead / Content / Media / Newsletter / Site Settings (G4) — 25 satır: 6 KISMEN, 19 YOK
| Domain | Öne çıkan gereksinim | Statü | Reusable | Aksiyon |
|---|---|---|---|---|
| Academy | program/oturum/başvuru, kontenjan atomik, admin (§54-58, §88, ARCH §36) | YOK | zod `parseBody` deseni | NEW |
| Lead | numune/teklif formları, pipeline durumları, bildirim (§60-63, ARCH §37) | KISMEN (kopya) | LS eski `lead-form` HTML (mailto! sunucu yok) | REBUILD |
| Lead | WhatsApp sabit aksiyon (§64) | KISMEN | LS `wa-float` + hazır mesaj | REFACTOR (numara SiteSettings'ten) |
| Lead | İletişim sayfası (§65) | KISMEN | LS yedek SSS/form | REBUILD |
| Content | içerik türleri, reçete→sepete ekle, DRAFT/PUBLISHED/ARCHIVED, silme politikası (§66-68, ARCH §38-39, §95) | YOK | `design-package.md` kopya bankası | NEW |
| Media | Media modeli + pipeline + hero frame sequence (ARCH §40-41, §83, §108) | KISMEN | `files.server.ts`; varlıklar; LS scrub davranış sözleşmesi + selftest | REFACTOR (files.server.ts) + REBUILD (HeroSequence) + NEW pipeline |
| Media | Katalog PDF sayfası + admin yükleme (§59, §89) | KISMEN | e-katalog PDF (PII içeriyor) | NEW; PDF yeniden üretim |
| Newsletter | abonelik + consent audit (§69, ARCH §56, §93) | YOK | — | NEW |
| Site Settings | yönetilebilir ayarlar + audit (§90-91, ARCH §55) | KISMEN | B2B `settings` şeması (ölü); LW `site.config.ts` flag deseni | NEW runtime `site_settings` + REFACTOR flag deseni |
| Site Settings | öne çıkan ürünler (§87) | YOK | — | NEW |

### 4.7 Notification / Analytics / Audit / Admin-RBAC / Identity(Admin) (G5) — 32 satır
| Domain | Öne çıkan gereksinim | Statü | Reusable | Aksiyon |
|---|---|---|---|---|
| Notification | sipariş/lead/admin bildirimleri, Email/Sms adapter, outbox+worker (§44, §63, §93, §103-104, ARCH §28-31, R11) | YOK | — (B2B'de sıfır; şifre sıfırlama bile düz metin JSON) | NEW (Postgres-backed outbox, SKIP LOCKED worker) |
| Analytics | admin dashboard + internal analytics (§86, §95, ARCH §44) | KISMEN | `admin-overview` 5 sayaç; DASH formülleri (referans) | NEW KPI view'ları |
| Analytics | GA4 / event layer / consent / Meta koşullu (§96-101, ARCH §45-46) | YOK | LW `isFeatureEnabled` deseni | NEW `packages/analytics` |
| Analytics | sitemap/robots/canonical (§97, §118) | KISMEN | B2B robots/sitemap route şablonu | NEW (DB'den) |
| Audit | yapısal audit, append-only (§91, R9, ARCH §53) | KISMEN | `audit()` + `audit_log` (serbest metin; DELETE guard yok) | REBUILD (entity/before/after/ip; DB rolünde REVOKE) |
| Audit | güvenlik logları (§92) | YOK | `recordLoginFailure` (sayaç var, log yok) | NEW |
| Audit | fiyat geçmişi (§82) | YOK | — | NEW |
| Admin/RBAC | ayrı admin surface (§76, ARCH §51) | KISMEN | B2B ekran akışları (spec) | NEW apps/admin |
| Admin/RBAC | 5 rol + izin matrisi (§77, ARCH §11) | KISMEN | `ROLE_CAPABILITIES` deseni (3 rol) | REBUILD (5 rol, kaynak-bazlı) |
| Admin/RBAC | server-side enforcement, UI gizleme yetki değil (R8) | **MEVCUT** | `requireAdmin(request, capability)` | REFACTOR (global guard) |
| Admin/RBAC | admin kullanıcı CRUD + rol atama | YOK | `admin-setup` (yalnız ilk hesap, yarışa açık) | NEW |
| Identity | admin 2FA zorunlu + recovery + replay (§78) | KISMEN | TOTP `hotp/verifyTotp` | REFACTOR |
| Identity | session hardening (rotation, iptal, CSRF) (ARCH §52) | KISMEN | token/cookie/CSRF çekirdeği | REFACTOR + REBUILD session store |
| Identity | rate limiting (ARCH §65) | KISMEN | hesap kilidi | NEW IP+hesap token-bucket |
| Identity | security headers (ARCH §67) | KISMEN | `security-headers.server.ts` (çağrılmıyor) | NEW (nonce CSP) |
| Identity | B2B auth ile karıştırılmaz (§110-111) | MEVCUT | host bazlı ayrım | KEEP |

---

## 5. Mimari uyumsuzluklar (doküman ↔ kod, doküman ↔ doküman)

1. **ARCH §5.4 "Node/Express" / §5.6 "Prisma"** ↔ B2B = Bun + TanStack Start + Workers + ham D1 SQL, ORM yok → "uyum önceliği" ve "Prisma öncelikli" koşulları boş; ADR-015 serbest.
2. **ARCH §87 port yönü** ("B2B'nin CatalogRead/InventoryRead/Reservation/Commit portları") B2B'nin owner olacağı varsayımıyla yazılmış → tersine döner: portlar **platformda sunulur, B2B istemcidir**.
3. **ARCH §4 monorepo + `pnpm`** ↔ B2B Bun workspace + Higgsfield deploy CI (repo'daki `wrangler.jsonc` yok sayılır) → B2B monorepo'ya alınamaz; ayrı repo + sözleşme.
4. **ARCH §5.5 PostgreSQL** ↔ B2B D1 (SQLite) → iki DB; ortak şema/migration YOK; yalnız HTTP sözleşmesi + external code.
5. **REQ §43 sipariş durumları** (7, ödeme odaklı) ↔ B2B `onay/uretimde/kalite/sevkiyat/teslim/iptal` ↔ Isletme_Sistemi `Onay Bekliyor/Onaylandı/Hazırlanıyor/Hazır/Sevk Edildi/Teslim` → üç sözlük; B2B siparişleri web'e taşınmayacağı için web REQ §43'ü alır, B2B kendi sözlüğünde kalır.
6. **Admin rol seti**: REQ §77 5 rol ↔ B2B CLAUDE.md Faz 1 4 rol ↔ Isletme_Sistemi 6 rol ↔ B2B kodu 3 rol → web admin REQ/ARCH 5 rol; B2B ayrı.
7. **Logo/ERP**: B2B CLAUDE.md §10 `ErpAdaptoru.faturaGonder` (Logo'ya yazma) ↔ Isletme_Sistemi K-03 "yazma yok" ↔ Isletme_Sistemi §18.2/§21 "stok sahibi Logo" ↔ kodda Logo bağı yok + Workers yerel ağa erişemez ↔ ARCH §90 `AccountingProvider` gelecek → V1'de Logo owner değil; yalnız platform-api tarafında gelecek adapter.
8. **LW D-005/D-008** `/admin` aynı app'te, "yalnız apps/web" ↔ ARCH §5.3/§51 ayrı admin app → LW kararları REFACTOR.
9. **B2B CLAUDE.md "anayasa"** 1 haftada eskidi (0020→0021, 16→17 test, 35→39 commit); `0001_init.sql` "platform migration uygular" ↔ CLAUDE.md "elle" ↔ yerel D1'de `d1_migrations` tablosu (0001-0010) + 0011/0012 out-of-band → migration uygulama yolu belirsiz.
10. **Isletme_Sistemi §4-5** Logo replika SQL + VPN + ayrı sunucu ↔ Cloudflare Workers yerel ağa erişemez → mimari uyumsuz (B2B_Durum_Analizi de yerel ajan öneriyor).
11. **REQ §12 kategoriler** (Kahve/Aroma/Toz/Çay; Donuk dışı) ↔ B2B 5'li (Pasta/Donuk dahil) ↔ eski site (SOS/Pastalar/Ekipmanlar/Eğitim) ↔ `satis_listesi` alt grupları → B5.
12. **REQ §4 slogan** "True Maths. Perfect Coffee." ↔ varlıklarda "TRUE MATHS PERFECT COFFEE" (tagline.png, noktasız).
13. **REQ §73 açık zemin** ↔ LS koyu espresso palet → LS görsel dili taşınmaz.
14. **B2B CLAUDE.md İlke 7 "para tamsayı kuruş"** ↔ kod REAL → platformda ihlal tekrarlanmaz.

---

## 6. KEEP / REFACTOR / REBUILD matrisi

| Modül | Karar | Gerekçe |
|---|---|---|
| B2B fiyat/iskonto motoru + iskonto tabloları (`core.server.ts:668-705, 844-873`; 0002/0003/0005/0007) | **KEEP (B2B'de)** | Server-side authoritative, tenant-izolasyonlu, entegrasyon testli (`tenant-dealer-read-scope.test.ts:108-185, 310-355`); G3 gereği web'e kopyalanmaz. Tek borç: kompozisyon 2 kopya → B2B'nin kendi Faz 0/8 işi. |
| B2B auth/session/CSRF/TOTP/tenant çözümleme (`core.server.ts:45-416, 418-664, 717-830`) | **KEEP (B2B'de)** | Bütünlüklü, 17 test dosyası; REQ §110-111 zaten web ile karıştırmayı yasaklıyor. |
| Identity saf primitifleri → `packages/identity` | **REFACTOR (port)** | Bağımlılıksız Web API kodu; uyarlama: `subtle.timingSafeEqual`→`node:crypto`, sürümlü hash (argon2id veya PBKDF2≥600k; eski `pbkdf2-sha256$100000` okunur + login'de rehash), TOTP replay/recovery, eskalasyonlu kilit, 5 rol matrisi. |
| B2B `products` tablosu + admin ürün akışı | **KEEP + ADAPTER** | B2B kanal projeksiyonu; eşleme platformda `variant_external_codes(system='b2b')` (varyant düzeyi — ADR-016 K6); **B2B'de katalog / rebuild migration açılmaz; P7B'de yalnız bir additive rezervasyon-kayıt migration'ı (ADR-016 K12, ADR-004 §3.5 istisnası — B6h ONAY 2026-09-17)**. Tek B2B PR'ı (P7B): `admin-products` GET'e moq/box (bug), `stock` alanının form+save'den çıkarılması, ADR-016 K12 kalemleri. |
| B2B envanter (`products.stock`) | **REBUILD (platformda NEW)** | Ölü kolon, ledger/rezervasyon yok, test yok; kolon dondurulur, silinmez (rebuild migration açmamak için). |
| B2B sipariş handler + `admin-order-status` (`$action.ts:598-736, 1174-1246`) | **REFACTOR (P7, B2B PR)** | Çalışır ve testli; kancalar: reserve/commit/release, `rezervasyon_bekliyor` / `rezervasyon_basarisiz` durumları, `submission_id` + istek parmak izi, op başlığı + op satırları (kalıcı niyet; K12/1), cari borcun `onay`'a taşınması ve değişikliklerde idempotent delta kaydı (K4-F), iptal-geri-alışın kaldırılması, tamsayı `qty`, tenant içi atomik `order_no` (0021 sözleşmesinin uygulama yarısı), `addTransaction` dönüş kontrolü, geçiş matrisi (ADR-016 K4, K12). Rewrite G14 ile yasak. |
| B2B `$action.ts` monolit + `admin.tsx/panel.tsx` UI | **KEEP (B2B'de) + P7B'de sınırlı değişiklik** | B2B kanalı için çalışıyor; parçalama platform kapsamı dışı; UI platforma taşınmaz, ekran akışları spec. P7B PR'ı (ADR-016 K12/6): `panel.tsx` `submission_id` + üç ayrı yanıt gösterimi, `ui.tsx` yeni durum etiketleri, `admin.tsx` eskalasyon / 72 saat aksiyonları, toplayıcı okuyucularda açık durum kümesi. |
| B2B migration fail-closed kalıbı (0015-0021) | **KEEP (ilke olarak)** | Ön-doğrulama → abort, rename'siz rebuild, migration testi ilkesi Postgres hattına kural olarak taşınır; SQL taşınmaz (SQLite'a özgü). |
| B2B kaynak-metin pin testleri (12 dosya) | **REFACTOR (B2B'de, yalnız dokunulan dosyalar)** | Davranış yerine yazım pinliyor; platforma taşınmaz. |
| B2B `files.server.ts` (magic-byte, safeFilename, readBodyExactly, fileResponse; 57 test) | **REFACTOR (port)** | R2/D1 bağımsız saf bayt işleme → `packages/adapters/storage` önü. Public CDN servisi + Media tablosu NEW. |
| B2B Higgsfield şablon ölü kodu (`src/layouts` 2721 satır, `src/components`, `packages/@higgsfield/*` 363 dosya, `design-inspector`, `security-headers.server.ts`, `settings` tablosu, `config.server.ts`, `example.functions.ts`) | **KEEP (dokunma; B2B'nin ayrı temizlik ADR'si)** | Platforma hiçbir parçası taşınmaz; `__root.tsx` quanta bağımlılığı nedeniyle B2B'de silinemiyor. |
| B2B audit/settings/robots-sitemap şablonları | **KEEP (B2B'de)** | Platformda yapısal audit, runtime site_settings, DB'den sitemap NEW. |
| LW `env.ts` (+13 test), `site.config.ts` flag deseni (+10 test), `instrumentation.ts`, `vitest.config.mts` alias/stub | **REFACTOR (port → packages/config, apps/web)** | Framework'ten bağımsız, testli; flag anahtar seti platform modüllerine göre yeniden; Next/Zod sürümü scaffold'da yeniden doğrulanır. |
| LW pnpm kabuğu, placeholder page/layout/globals.css, TS 7.0.2 / Vitest 5.0.0 / Node 24 kilidi | **REBUILD** | 197 satır placeholder; TS 7 typescript-eslint uyumsuz; yeni iskelet security-patched exact sürümlerle. |
| LW karar dokümanları D-002 (uyumluluk), D-003 (tek kiracı), D-004 (modül flag), D-005 (URL/slug), D-006 (içerik teslimi) | **KEEP (docs/adr referansı)** | Teknolojiden bağımsız. D-007/D-008/D-009 ve ARCHITECTURE.md 18-faz/çok-proje bölümleri → REFACTOR/atılır. |
| LS `index.html` (hero scrub, hash router, form) | **REBUILD** | 1769 satır inline global-scope JS; `mailto:` lead formu; koyu palet. Hero davranış sözleşmesi + selftest senaryoları React `HeroSequence`'e yeniden yazılır. |
| Katalog PDF üretim zinciri (`araclar/katalog2-*`, `Sos/katalog/tools`) | **REBUILD** | Kayıp `cdp.mjs`, sabit `chrome.exe` yolu, Windows fontları; V1: Media(PDF) + admin yükleme; PDF PII temiz yeniden üretim. |
| Ürün görselleri, 2048 PNG'ler, `logo.svg`, hero MP4 + 4K kareler, `design-package.md` kopya bankası | **KEEP (girdi)** | Tek kaynak ilan edilip `tools/assets-pipeline` ile WebP/AVIF; eksikler B8. |
| Ürün seed verisi (0006/0008/0009-0012, `katalog-veri.mjs`, `urun_maliyet.xlsx`) | **KEEP (veri) + NEW (import aracı)** | Idempotent upsert (Logo kodu + slug), dry-run; Excel→migration deseni terk. |
| DASH `anahtar.py`/`okuyucu.py` normalizasyon kuralları | **KEEP (spec)** | Türkçe harf katlama, birim eşanlam, VKN doldurma → import aracında TS'e uyarlanır. |
| Platform commerce/customer/promo/return/academy/lead/content/media/newsletter/settings/analytics/audit/identity/admin | **NEW** | Gap G1-G5: 160+ satırın ~100'ü YOK; karşılığı olan B2B kodu ilkeyi ihlal ediyor (REAL, kesirli qty, ad-anahtarlı kimlik, serbest metin audit). |

---

## 7. Product ownership kararı — **ADR-004 (ONAYLI 2026-09-18): ARCH §3 Seçenek B** — bu bölüm 2026-09-15 tarihli taslak gerekçesidir; yetkili metin `docs/adr/ADR-004-product-inventory-ownership-gate.md`

**Karar:** `apps/platform-api` (PostgreSQL) **Product identity ve katalog master'ıdır** (UUID id, slug, kategori ağacı, `sellable_variants`, `preparation_options`, nitelikler, medya, KDV oranı, perakende fiyat). B2B `products` tablosu silinmez, **B2B kanal projeksiyonu** olarak kalır: `list_price / box_count / box_unit_price / moq / dealer-grup-kategori-kampanya iskontoları` B2B fiyat domainidir (G3) ve orada kalır. Eşleme yalnız platformda ve **varyant düzeyinde** `variant_external_codes(system ∈ {logo,b2b}, code, variant_id)` 1:N (aynı varyant Logo'da iki kod; B2B `products.id` de buraya; çözülemeyen kod fail-closed — ADR-016 K6). **B2B'de katalog / rebuild D1 migration'ı açılmaz** (P7B'de yalnız bir additive rezervasyon-kayıt migration'ı — ADR-016 K12); B2B katalog migration'ları dondurulur (kural). B2B'nin ad/kategori alanlarını platformdan çekmesi (pull) V1 dışı, ayrı ADR.

**Kanıt:** B2B ürün modeli REQ §12-18'i taşıyamaz — tek düz tablo, varyant/kategori/slug/KDV/fiyat geçmişi yok, `sku` boş (`0019:262-278`); doğal anahtar ürün ADI (`0004:5-6`, `0006:4-5`); yeni id tenant filtresiz `MAX(sort)+1` (`$action.ts:1112-1116`); admin UI ad/kategori düzenleyemez, yeni ürün ekleyemez, her satır kaydı moq'u sıfırlar (`$action.ts:1069 vs 1086`); master 4 kopya ve ayrışmış (DASH audit). Onu D1 içinde büyütmek = paylaşımlı prod D1'de rebuild migration + belirsiz deploy hattı.

**Reddedilenler:** A (B2B owner) — model yetersiz, D1 dış API açmıyor. C (kademeli) — yalnız kimlik köprüsü olarak zaten uygulanıyor. Öneri 2'nin `0022 platform_variant_id` kolonu — işlevsel kazanç yok (eşleme platformda), migration riski var → HAYIR.

**Geçici adapter (G2 gereği belgeli, sunset tarihli):** B2B ürün id ↔ platform variant eşlemesi `variant_external_codes` (varyant düzeyi, ADR-016 K6); ilk eşleme 179 ürün için import aracı dry-run raporunda elle doğrulanır.

---

## 8. Inventory ownership kararı — **ADR-004 (devam)**

**Karar (rev. 1.1 — ADR-016 K1–K2):** `apps/platform-api` (PostgreSQL) **tek Inventory Core sahibi**: `inventory_items(variant_id UNIQUE)` · `inventory_balances(on_hand INTEGER CHECK (>= 0), reserved INTEGER CHECK (>= 0), version)` · `inventory_movements(type RECEIVE|SHIP|RETURN_IN|DAMAGE_OUT|ADJUST_UP|ADJUST_DOWN, qty INTEGER CHECK (> 0), direction IN|OUT, reason enum PRODUCTION|PURCHASE|SALE|RETURN|DAMAGE|WASTE|COUNT_ADJUSTMENT|MANUAL_ADJUSTMENT, ref_type/ref_id, actor, note)` — **yalnız fiziksel; RESERVE/RELEASE hareket değildir** · `inventory_reservations(item_id, channel web|b2b, namespace NOT NULL ('b2b:' + external_tenant_id | 'web'), external_tenant_id, external_order_id, external_line_id, generation, qty INTEGER CHECK (> 0), status ACTIVE|RELEASED|COMMITTED, expires_at NULL for b2b; UNIQUE (namespace, external_order_id, external_line_id) WHERE status = 'ACTIVE')` · `inventory_reservation_events(reservation_id, operation_ref → operations.id, action RESERVE|RELEASE|COMMIT, qty INTEGER CHECK (> 0), actor, reason; UNIQUE (operation_ref, reservation_id, action))` — bir işlem birden çok olay üretebilir · `operations(id PK, namespace, operation_id, request_hash, status succeeded|failed|abandoned; UNIQUE (namespace, operation_id))` (idempotency + mezar taşı; dış `operation_id` yalnız ad alanı içinde tekil — `'b2b:' + external_tenant_id` / `'web'`; ADR-016 K2/4, RV01); `available = on_hand − reserved` türetilir; invariant'lar `on_hand = Σ IN − Σ OUT`, `reserved = Σ RESERVE − Σ RELEASE − Σ COMMIT`. `reserved <= on_hand` sert kısıt değildir (fiziksel kayıp sonrası shortage uyarısı — ADR-016 K2/8). Ödeme başarısı fiziksel stoğu düşürmez; COMMIT + SHIP her kanalda sevkiyatta (ADR-016 K2/9). **B2B tüketicidir.** `products.stock` dondurulur (admin formundan kaldırılır, `admin-product-save` yazmaz, katalog `in_stock` port'tan; kolon silinmez). Açılış stoğu **fiziksel sayımla** `COUNT_ADJUSTMENT` — taşınacak stok verisi hiçbir sistemde yok. Logo V1'de owner değil; ileride yalnız platform-api tarafında `AccountingProvider`.

**Kanıt:** `$action.ts:610-614` (order SELECT'inde `stock` yok), `:712-726` (batch yalnız INSERT), `:1086/:1119` (tek yazım admin), 21 migration'da inventory/movement/reservation tablosu yok, seed hepsi `stock=0`, yerel D1 `stock>0` = 0, stok testi sıfır, `wrangler.jsonc` triggers yok, manifest kv:false/DO null, DASH/skill'lerde stok yok, kodda Logo bağı yok.

**Stok birimi (rev. 1.1 — ADR-016 K1, K7; B6b KARAR 2026-09-16):** sellable variant = stok kalemi; her varyantın ticari `stock_unit`'i (paket / şişe / kutu / koli / adet) var; **tüm miktarlar tamsayı**; B2B koli yalnız tamsayı katı (`qty_koli × box_count`, `box_count_snapshot` sipariş satırında); donuk pasta `stock_unit = kutu` (yarım / karışık kutu yok; farklı içerik = ayrı varyant); öğütüm stok etkisi yok (R4); bulk kg → paket dönüşümü V1 dışı. "Yalnız koli" varyant listesi B6e (AÇIK).

---

## 9. B2B entegrasyon stratejisi

- **Repo:** AYRI (bkz. §10). Sözleşme `packages/contracts/internal.b2b-integration.v1` (zod → OpenAPI); B2B'ye **vendored** kopya (`app/src/lib/b2b/platform-contract.v1.json` + üretilmiş tipli istemci `platform-client.server.ts`, sürüm pini); iki CI'da contract test. npm/git-tag dağıtımı yok (Bun/Higgsfield CI'da doğrulanmamış).
- **Yön (rev. 1.1):** B2B → platform komut çağrıları (`/internal/v1/inventory/{availability, reservations, reservations/patch, reservations/release, reservations/commit, operations/{id}, operations/{id}/abandon}` — patch / release / commit sipariş kapsamlı, hepsi-ya-da-hiçbiri); platform → B2B yönünde **komut / yazma çağrısı yok**, tek istisna imzalı salt-okunur mutabakat çekmesi `POST /api/b2b/internal/reservation-snapshot` (ADR-016 K4-R/K11; ADR-004 §3.7 istisnası — **B6h ONAY 2026-09-17**). Kimlik: servis token (+ rotasyon; IP allowlist F14 AÇIK) — **barındırma/egress kararına bağlı (B2)**.
- **Kancalar (B2B PR, P7B — rev. 1.1, ADR-016 K4–K12):** `POST order` → (0) `submission_id` çözümü + parmak izi → (1) doğrulama (tamsayı qty, tam varyant, MOQ; kredi = bekleyen taahhütler dahil tek atomik koşullu INSERT, `credit_limit <= 0` sınırsız) → (2) `orders` (`id = submission_id`, `rezervasyon_bekliyor`, `admission_token`, `revision`) + satırlar + `order_reservation_ops` (kalıcı niyet; kabul belirtecine koşullu) → (3) platform `reservations` (çok satırlı, atomik; `Idempotency-Key = operation_id`) → (4) tek kazanan koşullu batch: bakiye + `siparis:`+op_id cari kaydı (`WHERE NOT EXISTS`) + op `succeeded` + `onay`; zaman aşımı → `operations/{id}` → aynı anahtarla yeniden deneme → `abandon` (mezar taşı) → ancak o zaman `rezervasyon_basarisiz`; kesin hata → `rezervasyon_basarisiz` (borç yok). `admin-order-status`: `sevkiyat` → `commit` (COMMIT + SHIP), `iptal` / ret → **sipariş düzeyi idempotent CANCEL op** (iptal + varsa cari ters kaydı + `POST reservations/release` tek işlem; sebep zorunlu; **iptal terminal, geri-alış yok; açık siparişte bağımsız RELEASE yok — B6k KARAR 2026-09-16**), miktar / varyant değişikliği → `POST reservations/patch` (sipariş kapsamlı; artış = yalnız fark, hepsi-ya-da-hiçbiri; azalış = anında release; varyant = atomik takas; cari delta kaydı K4-F). Sipariş başına tek `pending` op; niyet kabulü atomik (durum + sürüm + bekleyen op yok + bayi düzeyi kredi taahhüdü); yerel geçişler (`onay → uretimde → kalite`, `sevkiyat → teslim`) koşullu tek UPDATE, platform çağrısı yok; belge / fatura yazıcıları da `iptal` / `rezervasyon_basarisiz` dışı durum koşuluyla yazar. Tek bayrak `INVENTORY_PORT=off|enforce` (off = bugünkü davranış = P7B öncesi rollback; launch sonrası kullanımı F08 AÇIK; **"soft/uyar-geçir" modu YOK** — üçüncü bir stok gerçeği üretir); paylaşımlı D1'deki non-prod dağıtım ayrı `environment_disabled` modundadır (mutasyon yok — ADR-016 K11/2k-vii).
- **Rezervasyon anı ve ömrü (B6c KARAR 2026-09-16 — ADR-016 K3, K5):** sipariş gönderiminde, kalıcı kayıtla; personel onayı beklenmez; **otomatik süre dolumu yok** (`expires_at NULL`); 24 saat uyarı / 48 saat yükseltilmiş uyarı / 72 saat yönetim kararı zorunlu (onayla-sürdür / iptal + release / uzat); sistem sessizce serbest bırakmaz; serbest bırakma yalnız sipariş düzeyi CANCEL op'udur (B6k KARAR 2026-09-16 — ADR-016 K5/4), sebep / aktör / zaman audit'li. **B6f KARAR 2026-09-17:** eskalasyon saati siparişin ilk rezervasyon anından işler, personel onayı sıfırlamaz; 72 saat kararını yalnız Yönetici verir (sürdür / uzat audit'li; ret / iptal = CANCEL op). **B6g KARAR 2026-09-17:** `on_hand < reserved` shortage'ında otomatik kısma / yeniden atama / serbest bırakma / iptal yok; yeni tahsis bloklanır, kritik uyarı; yalnız Yönetici karar verir (ADR-016 K2/8). Yalnız gerçek teknik sahipsiz (orphan) rezervasyonları mutabakat onarır (ADR-016 K11/4).
- **Mutabakat ve kurtarma (ADR-016 K4-R, K11):** platform worker'ı zamanlanmış olarak B2B'den **imzalı, salt-okunur** anlık görüntü çeker (`POST /api/b2b/internal/reservation-snapshot`; Ed25519 + zaman damgası + nonce; B2B kaynağa gömülü açık anahtarla doğrular — Worker'da sır yok; ADR-004 §3.7 istisnası — **B6h ONAY 2026-09-17**); B2B bu çekmeyi bekleyen op'larını sonuçlandırma "tik"i olarak kullanır (erişimde onarım + çekme ile tik); yanıt istenen her sipariş için açık durum (`not_found` dahil) + watermark + `complete`; `INCOMPLETE` koşuda otomatik onarım yok; deterministik onarım yalnız ADR-016 K11/4 durum tablosuna göre (B2B `not_found` / `iptal` / `rezervasyon_basarisiz` + platform ACTIVE → release; `pending` op → B2B tik ile tamamlama) audit'li; `sevkiyat` / `teslim` siparişte kalan rezervasyon, eksik rezervasyon, miktar uyuşmazlığı, çift nesil → yönetim uyarısı, onarım yok. **Kiracı kapsamı (RV01 — ADR-016 K11/2k, K4/7, K10/3):** anlık görüntü ucu ve tik uçtan uca tek `tenant_id`'ye bağlı (hostname kiracısı; anahtar kiracıya + ortama bağlı; görüntü sorgusu, bekleyen-op kurtarması, koşullu sonuçlandırma, audit, dönen satırlar); başka kiracı niteleyicili kimlik → `out_of_scope` (DB'siz, varlıktan bağımsız; `not_found` değildir; onarım yok); platform mutasyon uçları ve idempotency aramaları principal → `external_tenant_id` + sahiplik kapısından geçer; işlem kimlikleri kiracı ad alanlı. **Tekrar sipariş (RV02 — ADR-016 K9/4):** kalıcı `variant_code` / `order_unit` / `order_qty` ile güncel katalogda çözüm, `conversion_factor` K1/3 kuralıyla yeniden; çözülemeyen satır "onay gerekli"; yeni `submission_id` / sipariş no / rezervasyon / `operation_id`; `source_order_id` yalnız izlenebilirlik; iptal edilmiş sipariş yeniden açılmaz.
- **Geçiş dönemi (P7 canlıya kadar):** B2B sevkiyatları platform admin'inden elle `SALE (ref='b2b:#order_no')` işlenir — senkron scripti değil, tek ledger'a operatör girişi; ADR-004'te sunset tarihli; sahibi Depo rolü.
- **B2B'de outbox/worker kurulmaz** (D1 batch-only; cron/queue/KV/DO yok); çağrılar senkron + `Idempotency-Key = operation_id` (çağrıdan önce kalıcı) + timeout + sınırlı retry + `abandon` çitlemesi. **B2B'de bir additive D1 migration (`0022`, ADR-016 K12)** gerekir: `order_reservation_ops`, `orders.request_hash / admission_token / revision / source_order_id`, `order_items.variant_code / box_count_snapshot` — ADR-004 §3.5 istisnası (B6h ONAY 2026-09-17).
- **Aynı PR'daki zorunlu B2B düzeltmeleri:** tenant içi atomik `order_no` (0021 sözleşmesi: INSERT…SELECT MAX+1 aynı ifadede/counter), ürün id CSPRNG (CLAUDE.md §6.4), `addTransaction` dönüş kontrolü, `admin-products` moq/box alanları, `applySecurityHeaders` bağlanması; dokunulan dosyaların pin testleri davranış testine çevrilir.
- **ÖN KOŞUL (yeni bulgu):** HEAD (`d75dc7d`) hiç deploy edilmemiş; canlıya alınması için `0003-0021` (19 migration; 0015 26 preflight abort, 0016 142, 0018/0019 DROP+CREATE rebuild) **paylaşımlı prod D1'e** uygulanmalı → ayrı B2B deploy projesi: canlı D1 seviyesi teyidi → yedek → staging benzeri kopyada prova (yerel miniflare ile mümkün) → uygulama. Bu iş P7'nin ön koşulu ve **Higgsfield'da mı kalınacağı (§14/11) kararına bağlı**.
- **Kademeli birleşme (apps/b2b):** yalnız B2B kendi Cloudflare hesabına geçer VE entegrasyon 1 çeyrek canlıda kanıtlanırsa ayrı ADR ile; o zaman bile D1→Postgres taşıma yok.

---

## 10. Önerilen hedef repository yapısı

**Uygulama deposu kökü — KARAR 2026-09-18:** yeni kod / uygulama deposunun kökü **`larante-platform`** (ASCII-güvenli adlandırma); Phase 1 uygulama çalışma alanı / deposu oluşturulurken uygulanır (`docs/tasks/PHASE1/P1-T01`); mevcut dokümantasyon deposu / klasörü (`LARANTE WEB SİTESİ - v1`) bu kararla yeniden adlandırılmaz — dokümantasyonun taşınması ya da referanslanması P1-T01'de tanımlanır. *(Önceki metin: "Repo kökü = bu proje klasörü … P1'de ASCII ad önerilir" — gerekçe: boşluk + Türkçe karakterli klasör adı turbo cache, native modüller ve Windows yol uzunluğunda sorun çıkarabilir.)*

```
larante-platform/                     pnpm + Turborepo · Node 22 LTS · TS strict · exact security-patched sürümler
├── apps/
│   ├── web/                          Next.js App Router (www). Server Components. LW env/site.config/instrumentation tohumu (sürüm kilidi düzeltilmiş).
│   │                                 Routes (ARCH §96 + D-005): / /urunler /urunler/[category] /urun/[slug] /hakkimizda /akademi /akademi/[slug] /ilham /ilham/[slug]
│   │                                 /katalog /iletisim /hesabim /siparis-takip /sepet /odeme. Sağlayıcı SDK importu YASAK; yalnız packages/contracts istemcisi.
│   ├── admin/                        Next.js App Router (admin.larantecoffee.com). Ayrı cookie (__Host-, Strict), nonce CSP, zorunlu 2FA, 5 rol.
│   ├── platform-api/                 Node + Hono (+@hono/zod-openapi) — KARAR 2026-09-18 (Phase 0 onay paketi 3). Modüler monolit:
│   │                                 src/modules/<identity|customer|catalog|retail-pricing|inventory|cart|checkout|order|payment|shipping|promotion|
│   │                                 review|wishlist|return|academy|lead|content|media|newsletter|site-settings|notification|analytics|audit>
│   │                                 src/http/{public-v1,commerce-v1,customer-v1,admin-v1,internal-v1(b2b)} · src/bootstrap (DI). Docker image.
│   └── worker/                       Aynı codebase, ayrı süreç (aynı image, farklı entrypoint): outbox consumer (SKIP LOCKED), expiry, retry/dead-letter,
│                                     tutarlılık job'u, analytics export. Mikroservis değil (ARCH §30).
├── packages/
│   ├── domain/                       Saf TS: entity/VO/invariant (Money=kuruş INT, Order/Return state machine, inventory math, promotion rules) + PORT arayüzleri.
│   │                                 Framework/DB/sağlayıcı importu lint ile YASAK.
│   ├── application/                  Use-case'ler (createOrder, reserveStock, commitReservation, releaseReservation, priceCart, transitionOrder, submitLead…)
│   │                                 + transaction sınırı soyutlaması + outbox yazımı.
│   ├── db/                           Drizzle şema + drizzle-kit ile üretilip ELLE review edilen SQL migration'lar (forward-only) + repository impl. TEK ORM.
│   ├── adapters/                     payment/<psp>, email/<p>, sms/<p>, shipping/manual, storage/s3 (+ files.server.ts portu), analytics/{internal,ga4,meta}; fake/.
│   │                                 Yalnız platform-api + worker import eder (import-boundary lint).
│   ├── identity/                     B2B'den PORT: sürümlü password hash, token/cookie parse, CSRF çekirdeği, TOTP(+replay/recovery), RBAC matrisi (5 rol), kilit + rate-limit.
│   ├── contracts/                    zod DTO + OpenAPI + üretilen TS istemci (web/admin) + internal.b2b-integration.v1 (B2B'ye vendored kopya).
│   ├── analytics/                    Tipli olay sözleşmesi + sink registry + consent kapısı.
│   ├── ui/ · design-tokens/          Tasarım sistemi (REQ §73 açık zemin + marka mavisi #007EB9/#2196D6); brand config token düzeyinde (engine yok).
│   ├── config/                       env doğrulama (LW env.ts), site.config feature flag'ler (varsayılan kapalı).
│   ├── observability/                logger, request-id, metrik, error monitoring init, release tag.
│   └── testing/                      Postgres test container yardımcıları, fake adapter'lar, concurrency harness, fixture'lar.
├── tools/import-catalog/             Idempotent seed CLI (B2B 0006/0008/0009-0012 + katalog-veri.mjs + data/urun_maliyet.xlsx → product/variant/media/external_code); --dry-run zorunlu.
├── tools/assets-pipeline/            2048 PNG → WebP/AVIF; hero kare seti kodlama.
├── data/                             Proje içine alınan tekil kaynak kopyaları (skill Excel'leri, seed JSON) + kaynak/tarih notu.
├── docs/{requirements,architecture,adr}/   REQ + ARCH V2 (+ V2.1 düzeltme notu) + bu audit + ADR-001…016.
├── infra/                            docker-compose (Postgres + MinIO + api + worker), Dockerfile'lar. Cloudflare Workers'a bağlanmaz.
├── .github/workflows/ci.yml          install --frozen-lockfile · lint (import-boundary; cloudflare:* yasak) · typecheck · unit · integration (gerçek Postgres, concurrency) · build · e2e smoke · contract test · migration check · dependency scan
└── pnpm-workspace.yaml · turbo.json · pnpm-lock.yaml
```
**B2B (mevcut, ayrı repo, yerleşim değişmez)** — P7'de tek PR: `app/src/lib/b2b/platform-client.server.ts` (NEW), `platform-contract.v1.json` (NEW), `$action.ts` (kancalar + düzeltmeler), `admin.tsx` (stok input kaldırılır), `__tests__/` (pin → davranış). Kural: B2B'de katalog / rebuild D1 migration'ı açılmaz (P7B'de yalnız bir additive rezervasyon-kayıt migration'ı — ADR-016 K12); B2B'de `pg/drizzle` yok; platformda `cloudflare:*` yok.

---

## 11. Veri modeli stratejisi

- **DB:** PostgreSQL (16/17); yalnız düz Postgres (sağlayıcıya özgü auth/RLS/edge yok → taşınabilir); local/CI/staging docker-compose; prod sağlayıcı ADR-017 (B3 / B7 — dosya henüz yazılmadı, tarihli beklemede 2026-09-18; Phase 1'i bloklamaz). B2B D1 dokunulmaz; iki DB tablo/migration/bağlantı paylaşmaz.
- **Tek ORM:** Drizzle + drizzle-kit (ADR-015). Gerekçe: SQL-first → `UPDATE … WHERE on_hand-reserved>=$q`, `SELECT … FOR UPDATE SKIP LOCKED`, SEQUENCE, CHECK/UNIQUE/FK gizlenmeden yazılır/review edilir; motor/Data Proxy yok; LW D-008 aynı karar. Prisma/TypeORM platformda yasak.
- **Tipler:** para `*_kurus INTEGER`, oranlar basis point INT, miktar tamsayı — bakiyeler `INTEGER CHECK (>= 0)`, hareket / olay miktarları `INTEGER CHECK (> 0)` + açık yön (ADR-016 K2, ADR-015 §6); REAL/float yasak (B2B İlke 7 ihlali tekrarlanmaz). Tüm id UUID; slug tr-ASCII UNIQUE (D-005).
- **Catalog:** `product_categories(id, parent_id, slug, name, sort, visible_public)` · `products(id, slug UNIQUE, name, category_id, status draft|active|archived, seo jsonb, featured_sort)` · `sellable_variants(id, product_id, sku UNIQUE, weight_g, roast_level, agtron, packaging_code, box_config, stock_unit NOT NULL, variant_key, active; UNIQUE(product_id, variant_key))` — `variant_key` = stok-belirleyici boyutların kanonik birleşimi `usage_type | roast_level | weight_g | packaging_code | box_config` (ADR-016 K6/2; kullanım tipi 2026-09-17 R01 ile kanonik anahtara eklendi); **tasarım notu (P4, B6a/B6e/B6i/B5 2026-09-17):** net içerik tanımlayıcı alan (tamsayı taban birim — ör. `net_content_qty` + `net_content_unit` g|ml — `stock_unit`'ten ayrı), kanal uygunluğu niteliği (public satılabilir / yalnız B2B), güncel satın alma maliyeti + kaynak + son güncelleme; donuk pasta `slices_per_box` = kutu içi parça sayısı (SKU bazlı; koli `box_count` değil); donuk pasta: `box_content_desc`, `slices_per_box`, `per_slice_price_kurus` (bilgi) · `preparation_options` + `product_preparation_allow` (stok kalemi değil) · `product_attributes(typed) + category_attribute_templates` · `media` + `product_media(kind packaging|lifestyle)` · `variant_external_codes(system logo|b2b, code, variant_id; UNIQUE(system,code))` 1:N (varyant düzeyi — ADR-016 K6) · `product_relations`.
- **Retail pricing (G3):** `retail_prices(variant_id, price_kurus, tax_rate_bp, tax_inclusive=true, effective_from)` · `retail_campaign_prices(variant_id, price_kurus, starts_at, ends_at, active)` · `price_history` (append-only; DB rolünde UPDATE/DELETE yetkisiz) · `products.min_price_kurus` materialized. B2B `list_price/iskonto` platformda ASLA tutulmaz.
- **Inventory:** bkz. §8 / ADR-016 K2. Rezervasyon tek atomik UPDATE; COMMIT sevkiyatta, aynı transaction'da SHIP hareketi; tutarlılık job'u `on_hand = Σ IN − Σ OUT` (yalnız fiziksel) ve `reserved = Σ aktif rezervasyon`; eskalasyon (24/48/72) ve mutabakat işleri worker'da.
- **Commerce:** `carts/cart_lines` (imzalı guest token, merge) · `orders(order_no SEQUENCE, status + transition map, customer_id NULL|guest_email/phone, idempotency_key UNIQUE (= submission id) + request_hash, source_order_id, terms_version, pre_information_version, privacy_version)` · `order_lines(product_id, variant_id NOT NULL, name, sku, variant_snapshot (kullanım tipi/kavrum/gramaj/ambalaj/kutu + stock_unit), unit_price_kurus, tax_rate_bp (kaynağı B4d; sipariş anı snapshot'ı), purchase_cost_kurus_snapshot (B6i; geçmiş kârlılık — sonraki maliyet değişikliği geçmişi yazmaz), discount jsonb, preparation_snapshot, qty INTEGER CHECK (> 0))` · `order_billing_snapshot` · `payments` · `payment_events(provider, event_id UNIQUE, raw jsonb)` · `shipments` · `return_requests` (state machine) · `coupons` + `coupon_redemptions(order_id UNIQUE)` · `outbox_events` · `processed_events(event_id, handler PK)` · `delivery_log`.
- **Identity/Audit:** `admin_users(role ADMIN|SALES|WAREHOUSE|CONTENT|FINANCE, totp_secret_enc, totp_last_counter, recovery_codes_hash)` · `retail_customers(email citext UNIQUE)` · `customer_addresses` · `invoice_profiles` · `sessions(token_hash, rotated_at)` · `password_reset_tokens` · `security_events(ip, ua)` · `audit_log(actor, action, resource_type, resource_id, before jsonb, after jsonb, reason, ip, ua; append-only)` · `consent_records` · `site_settings` · `identity_links` (yalnız gelecek SSO ADR'siyle).
- **Content/Academy/Lead:** `content_entries(type, status DRAFT|PUBLISHED|ARCHIVED, draft/published body, seo)` · `redirects` · `recipe_ingredients(product_id)` · `academy_programs/sessions(capacity, confirmed_count atomik)/applications` · `leads(kind SAMPLE|QUOTE|CONTACT, status + transition map)` · `lead_items` · `newsletter_subscriptions`.
- **Seed:** `tools/import-catalog` — kimlik/ambalaj `urun_maliyet.xlsx` (Logo kodu), ad/kategori/görsel B2B 0006/0008/0009-0012 + `katalog-veri.mjs`; `active=1` filtresi (yerel D1'de 32 inaktif "Pastalar" çöp satırı); Türkçe normalizasyon DASH `anahtar.py` kurallarından; dry-run raporu (179 ürün, 94 görsel, 216 Logo kodu, çakışmalar) onaysız yazmaz.

---

## 12. Auth / RBAC stratejisi

- **Üç ayrı kimlik alanı, FK yok:** `retail_customers` (web), `admin_users` (admin), B2B `dealers/admins` (D1, dokunulmaz). Aynı e-posta iki tarafta olabilir; hiçbir kural fiyat/iskonto/tenant yetkisi taşımaz (`PricingService` dealer bağlamını bilmez). Header'dan `b2b.larantecoffee.com`'a düz link, iframe yok. SSO ayrı ADR (REQ §116).
- **Port edilen (`packages/identity`):** `hashPassword/verifyPassword` (sürümlü `$alg$params$salt$hash`; argon2id native modül kabulse, aksi PBKDF2≥600k; eski `pbkdf2-sha256$100000` okunur + rehash-on-login), `generateSessionToken/isSessionToken/parseCookies` (fail-closed), CSRF çekirdeği (`__Host-` double-submit + Origin; Next server action Origin kontrolüyle çakışmaması için TEK mekanizma), TOTP `hotp/verifyTotp` (+ `last_used_counter` replay engeli, hash'li recovery kodları, secret at-rest şifreli), `lockCheck` (eskalasyonlu, aynı yanıt kodu → enumeration kapanır), `ROLE_CAPABILITIES` deseni (5 rol, kaynak-bazlı capability: `catalog:write`, `inventory:write`, `orders:write`, `finance:write`, `content:publish`, `settings:write`, `users:manage`).
- **Yeniden kurulan:** Postgres session store (token hash; login/parola/2FA değişiminde rotation + diğer oturumların iptali; admin `__Host-` Strict, kısa TTL; müşteri Lax), **zorunlu 2FA enrollment kapısı** (admin ilk girişte), IP+hesap DB tabanlı token-bucket rate limit (login/reset/2FA/re-auth/guest lookup/form'lar/kupon), `security_events`, admin kullanıcı CRUD + rol yönetimi (son owner koruması), RetailCustomer e-posta/parola/reset e-postası/misafir token, **global route guard** (Hono middleware + Next server action wrapper — "her handler'da elle guard" anti-pattern'i kapanır), güvenlik başlıkları (nonce CSP, HSTS, frame-ancestors, nosniff, Referrer-Policy, Permissions-Policy).
- **B2B → platform servis kimliği:** imzalı servis token (rotasyon) + IP allowlist; `/internal/v1/*` yalnız bu kimlikle.
- **Tenant çözümleme web'e taşınmaz** (ARCH §85: tek marka, tenant karmaşıklığı yok).

---

## 13. API ve adapter sınırları

- **Port arayüzleri** `packages/domain/ports`: `PaymentProvider{createPayment, verify3DS, verifyWebhook(rawBody, headers)→PaymentEvent, refund(amount, idempotencyKey), partialRefund, getStatus}`, `EmailProvider`, `SmsProvider{send→deliveryRef}`, `ShippingProvider{quote, createShipment, track}`, `StoragePort`, `AnalyticsSink`, `InventoryPorts`, `Clock`, `IdGen`.
- **Uygulama servisleri** `packages/application`: `PaymentService` (webhook → `payment_events` UNIQUE INSERT ON CONFLICT DO NOTHING → tek commit), `NotificationService` (yalnız outbox'a yazar; gönderim worker'da), `ShippingService` (V1 ManualAdapter: admin takip no → `shipments` → SHIPPED + outbox), `PricingService.quote` (katalog ve checkout aynı fonksiyon), `AnalyticsEmitter`.
- **Somut adapter'lar** `packages/adapters/<kind>/<provider>` (+`fake/`); yalnız `platform-api` + `worker` DI ile bağlar; `web`/`admin` sağlayıcı SDK'sı import etmez (lint). Kart verisi sunucuya değmez (hosted/3DS).
- **HTTP yüzeyi** (ARCH §60): `/public/v1/catalog|content|academy` (cache'lenebilir, B2B alanı yok — contract test), `/commerce/v1/cart|checkout` (guest token/oturum), `/customer/v1/*`, `/admin/v1/*` (admin oturumu + RBAC), `/internal/v1/inventory/*` (servis token), `/webhooks/payment/<provider>` (imza doğrulama adapter'da). DTO/contract zod; internal model expose edilmez.
- **Analytics:** `packages/analytics` tipli olaylar (`ProductViewed … AcademyApplicationSubmitted`) → sink registry: `InternalDbSink` zorunlu, GA4 consent `analytics`, Meta flag + consent `marketing` (V1 kapalı). Finansal gerçek yalnız Order/Payment tabloları (R10/G9).
- **Logo/ERP:** yalnız platform-api'de gelecek `AccountingProvider` (Workers yerel ağa erişemez; B2B'ye konmaz). **B6i / B4d (2026-09-17):** sonraki aşamada satın alma maliyeti ve malzeme kartı KDV oranı Logo SQL'den özel **salt-okunur** (yalnız SELECT) DB kullanıcısıyla okunur; platform Logo'ya INSERT / UPDATE / DELETE yapmaz; tablo / kolon adları belirlenmedi; V1 kaynağı kontrollü Excel içe aktarımıdır (tam varyant eşlemesi, fail-closed).

---

## 14. Transaction / concurrency / idempotency

- **Sipariş oluşturma (web):** tek Postgres transaction = `orders` + `order_lines` + `order_billing_snapshot` + rezervasyon oluşturma (TTL'li) + `outbox_events`; `idempotency_key` UNIQUE (= gönderim kimliği, client-generated, checkout token'a bağlı) + istek parmak izi → aynı gövde tekrar = aynı sipariş döner, farklı gövde = 422 (ADR-016 K10).
- **Rezervasyon:** `UPDATE inventory_balances SET reserved=reserved+$q, version=version+1 WHERE item_id=$i AND on_hand-reserved>=$q` (0 satır → yetersiz stok); her işlem bir `operations` kaydıdır (iç `id` + ad-alanlı dış `operation_id`: `UNIQUE (namespace, operation_id)`, `request_hash`; olaylar iç anahtara referans verir — ADR-016 K2/4); **ödeme başarısı**: `expires_at := NULL` (kalıcılaşır; miktar / fiziksel stok değişmez); **commit sevkiyatta**: aynı transaction'da `reserved-=q, on_hand-=q` + SHIP hareketi (reason SALE) + COMMIT olayı; release: expiry worker (yalnız ödenmemiş), iptal / ret / iade use-case'i (sipariş düzeyi, tek idempotent işlem; sebep zorunlu); açık B2B siparişinde bağımsız release yok (B6k); mutabakat yalnız gerçek orphan; miktar / varyant değişikliği `PATCH` (artış = yalnız fark, hepsi-ya-da-hiçbiri; azalış = anında release; varyant = atomik takas); COMMITTED sonrası PATCH 409. Kart: kısa TTL (site_settings; 3DS ilişkisi H10 AÇIK), havale: 24s (site_settings). Belirsiz sonuç: `operations/{id}` → `abandon` mezar taşı (ADR-016 K4-R).
- **Ödeme webhook:** `payment_events(provider, event_id) UNIQUE` INSERT … ON CONFLICT DO NOTHING; eklenmediyse no-op; eklendiyse aynı transaction'da order → PAYMENT_RECEIVED + rezervasyonun kalıcılaştırılması (`expires_at := NULL`; commit sevkiyatta) + outbox. Tutar / para birimi / sipariş / deneme eşlemesi F09 kapsamında AÇIK. Geç gelen webhook (rezervasyon süresi dolmuş): yeniden rezervasyon dene, olmazsa `PAYMENT_RECEIVED_NO_STOCK` iç durumu + kritik alarm + manuel iade akışı.
- **Kupon:** `UPDATE coupons SET used=used+1 WHERE code=$c AND used<usage_limit RETURNING` + `coupon_redemptions(order_id UNIQUE)`.
- **Sipariş numarası:** Postgres SEQUENCE (+ prefix format kararı); B2B tarafında tenant içi MAX+1 tek ifadede (0021 sözleşmesi).
- **Outbox:** aynı transaction'da INSERT; worker `SELECT … FOR UPDATE SKIP LOCKED`, exponential backoff (`available_at = now + 2^attempts×30s`, max N → dead), `processed_events(event_id, handler)` PK ile handler idempotency; dead-letter admin ekranı + yeniden kuyruğa alma.
- **Akademi kontenjan:** `UPDATE academy_sessions SET confirmed=confirmed+1 WHERE id=$s AND confirmed<capacity RETURNING`.
- **Order/Return state machine:** izinli geçiş tablosu domain'de; invalid geçiş domain hatası; terminal durumlar tanımlı (B2B'deki "her durumdan her duruma" tekrarlanmaz).
- **B2B çağrıları (ADR-016 K4, K10):** senkron, `Idempotency-Key = operation_id` (çağrıdan önce B2B'de kalıcı; sipariş başına tek `pending` op; `orders.revision` ile sürümlü sonuçlandırma), istek parmak izi, timeout + sınırlı retry + `operations/{id}` sorgusu + `abandon` çitlemesi, fail-closed; `order_id + geçiş` anahtar olarak **kullanılmaz**; platform yan etkilerini kendi outbox'ına yazar. B2B cari borç yalnız `onay`'da, tek kazanan koşullu batch'te, `transactions.id = 'siparis:' + op_id` (`WHERE NOT EXISTS` — tetikleyici uyumlu); kredi kontrolü bayi düzeyinde tek `taahhüt(d)` tanımıyla bekleyen sipariş toplamlarını **ve** bekleyen pozitif PATCH deltalarını sayar (ADR-016 K4/1, K4-F).

---

## 15. Test stratejisi

- **Piramit (ARCH §79):** Unit (domain: pricing, promotion, order/return state machine, inventory math — saf, DB'siz) · Integration (gerçek Postgres test container: rezervasyon concurrency, outbox, webhook idempotency, kupon yarışı, auth, migration up + runner ikinci çalıştırmada uygulananı atlar (SQL dosyası doğrudan tekrar çalıştırılmaz), contract) · E2E (Playwright: browse, add to cart, guest/member checkout, havale, kart sandbox, order tracking, admin stok/kargo, academy, lead).
- **CI kapıları (her PR):** lint (import-boundary, cloudflare:* yasak, domain→framework yasak) · typecheck strict · unit · integration (Postgres servis) · build (4 app) · e2e smoke · contract test (public DTO'da B2B alanı yok; internal.b2b v1 uyumu) · migration check (up + yeniden çalıştırma idempotent) · dependency scan. Sonra: accessibility (axe), Lighthouse CI bütçesi, migration review.
- **Zorunlu risk senaryoları (ARCH §80, §118) — kırmızı→yeşil test-first:** son stok için N eşzamanlı checkout (toplam ≤ on_hand) · duplicate payment webhook · payment success + notification provider down (sipariş kaybolmaz) · transfer expires (release) · coupon last-use race · admin unauthorized role (403 yan etkisiz) · guest order lookup brute force (rate limit) · product price changes while cart open (server yeniden fiyatlar) · stock goes zero while cart open · refund retry idempotent · worker restarts with pending outbox · B2B reserve/commit/release idempotent (fake platform ile B2B testi; fake B2B istemcisi ile platform testi) · **ADR-016 senaryoları:** kesirli miktar reddi (DB + API) · çok satırlı rezervasyon hepsi-ya-da-hiçbiri · aynı `operation_id` tekrarı tek etki, farklı gövde 422 · zaman aşımı → sorgu → aynı anahtar → `abandon` → gecikmiş orijinal 409 · `rezervasyon_basarisiz` onaylı sipariş gibi görünmez ve borç taşımaz · çift POST (aynı `submission_id`) tek sipariş; eşzamanlı kaybeden kazananın siparişine satır ekleyemez · kredi taahhüdü bekleyen siparişleri sayar; `credit_limit <= 0` sınırsız · cari kaydı tekrarda bakiye iki kez hareket etmez · miktar artışı stok yoksa sipariş değişmez; azalışta anında release; varyant takası atomik; COMMITTED sonrası PATCH 409 · 24/48/72 bayrakları, sessiz release yok · sebepsiz release reddi · açık B2B siparişinde bağımsız RELEASE ucu yok (403/404); CANCEL op idempotent (iptal + ters kayıt + RELEASE tek işlem, tekrar → aynı sonuç, bakiye bir kez) · **kiracı izolasyonu (RV01):** tenant A anahtarıyla tenant B niteleyicili mevcut / var olmayan kimlik → bayt-bayt aynı `out_of_scope`, DB araması yok; tik B'nin `pending` op'unu sonuçlandırmaz; yetkisiz anahtar / uyuşmayan `tenant_id` / `environment` → 403 yan etkisiz; çapraz-kiracı `patch` / `release` / `commit`: yabancı sipariş niteleyicisi → 422 `tenant_mismatch` (sözdizimsel), yetkili niteleyici + yabancı / var olmayan `reservation_id` → ayırt edilemez 404, sıfır değişiklik; aynı web satırı iki `operation_id` ile → ikinci UNIQUE ile reddedilir; prod D1'ini paylaşan preview dağıtımında anlık görüntü → 403 `environment_disabled`, kurtarma yok, prod `pending` op'u değişmez; preview'da yetkili admin `admin-order-status` / bayi `POST order` / ek yükleme → 403, `orders` / `transactions` / `dealers.balance` / `order_reservation_ops` değişmez; karışık toplu istek tümüyle reddedilir; iki kiracı aynı `operation_id` → iki ayrı kayıt; A `abandon` A'da yok → A-kapsamlı mezar taşı, B değişmez · **tekrar sipariş (RV02):** aynı adlı iki varyant → `variant_code` ile doğru varyant; arşivlenmiş / legacy satır → "onay gerekli"; adet satırı `box_count = 12` → faktör 1; koli `box_count = 0` → onay gerekli; gerçek uçtan yükle → reorder; yeniden açma 409 · **DB tamsayı (RV03, gerçek `node:sqlite`):** legacy 5 / 5.0 geçer; fixture'da 1.5 → migration abort; `qty` ∈ {0.5, 1.25, 2.5} INSERT / UPDATE → `SQLITE_CONSTRAINT`; `moq` −1 abort, 0 kabul; `box_count` 0.5 abort; `qty_stock_units ≠ order_qty × conversion_factor` abort · orphan → otomatik release + audit; belirsiz uyuşmazlık → uyarı, onarım yok; `INCOMPLETE` görüntüde onarım yok · DAMAGE_OUT ile `available < 0` → kayıt + shortage uyarısı · ödeme başarısı fiziksel stoğu değiştirmez; SHIPPED = COMMIT + SHIP.
- **B2B davranış senaryoları spec olarak taşınır** (tenant sızıntı, viewer 403, çift iptal tek iade, CSRF, cookie parsing); kaynak-metin pinleri taşınmaz.
- **Fake adapter'lar** (`packages/adapters/fake`): PSP (webhook üretici), Email/Sms (delivery log), Shipping, Storage (memory), Clock — deterministik integration/E2E.
- **Test verisi:** `tools/import-catalog --dry-run` çıktısı fixture; PII içeren fatura verisi test'e girmez.

---

## 16. Security stratejisi

- Admin: zorunlu TOTP + recovery + replay engeli; `__Host-` Strict cookie, kısa TTL, rotation, iptal; nonce CSP + HSTS + frame-ancestors 'none'; IP+hesap rate limit; `security_events` (ip/ua, başarısız giriş, kilit, rol değişimi, kritik ayar); admin kullanıcı yönetimi audit'li.
- Müşteri: e-posta/parola (sürümlü hash), reset token tek kullanımlık + süreli, misafir imzalı token, guest lookup rate limit, hesap-varlığı sızdırmayan yanıtlar.
- Checkout/ödeme: client fiyat/indirim/kargo güvenilmez; totals server; kart verisi sunucuya değmez; webhook imza + idempotency + raw event audit; refund idempotent; yasal onay sürümleri siparişte.
- Servis kimliği: B2B → platform imzalı token + IP allowlist + rotasyon; secret'lar env/secret store, source control'a girmez (LW `env.ts` değer sızdırmayan doğrulama).
- Formlar (lead/akademi/newsletter/yorum): rate limit + honeypot/challenge (sağlayıcı bağımsız) + duplicate detection + server validation.
- İçerik: rich text sanitize + allowlist; raw HTML yok.
- PII/KVKK: minimum veri; loglara PII yok; consent kayıtları sürümlü; fatura verisi (TCKN) şifreli/erişim kısıtlı; e-katalog PDF PII temiz yeniden üretim.
- Audit: append-only (`audit_log` DB rolünde REVOKE UPDATE/DELETE); kritik işlemler (fiyat/stok/iptal-iade/ödeme durumu/rol/ayar/Akademi) zorunlu.
- Backup: günlük otomatik + retention + şifreli + **restore drill kanıtı** (P12 kapısı).
- B2B tarafı (P7 PR'ı): `applySecurityHeaders` bağlanır; ek B2B borçları (rotation, IP limit, TOTP replay) B2B'nin kendi backlog'u.

---

## 17. Migration stratejisi

- Platform: Drizzle şema → drizzle-kit ile üretilen düz SQL migration → **elle review** (AI-üretimi migration doğrudan prod'a uygulanmaz, ARCH §78) → forward-only; destructive değişiklik iki aşamalı (expand → migrate → contract); her migration gerçek Postgres'te up + idempotent yeniden çalıştırma testi; prod öncesi backup zorunlu. "Fail-closed" ilkesi (ön-doğrulama → abort) B2B'den taşınır.
- **Veri göçü (platforma):** ürün/kategori/görsel/Logo kodu → `tools/import-catalog` (idempotent, dry-run, onay); stok → fiziksel sayım (COUNT_ADJUSTMENT; **B6d KARAR 2026-09-17:** legacy `products.stock` / tahmin ile tohumlama yok; SKU düzeyi sayım; Depo sayar, Yönetici onaylar; zaman damgası + sayan + onaylayan + audit; tarih planlama kalemi — F07 runbook); B2B siparişleri/müşterileri **taşınmaz** (ayrı domain); LW/LS'den kod göçü yok.
- **B2B migration'ları:** platform işi değil; **HEAD'in canlıya alınması** (0003→0021) ayrı B2B deploy projesi: canlı seviye teyidi → yedek → miniflare/staging kopyasında prova (0015/0016 preflight abort koşulları tablo halinde) → uygulama; platformun deploy'da otomatik uygulayıp uygulamadığı Higgsfield'a sorulur. B2B'de katalog / rebuild migration'ı açılmaz; P7B'de yalnız bir additive rezervasyon-kayıt migration'ı (`0022`, ADR-016 K12 — ADR-004 §3.5 istisnası, **B6h ONAY 2026-09-17**); `0022` ayrıca `order_reservation_ops.environment` damgasını (ortam izolasyonu, ADR-016 K11/2k-vii) ve DB düzeyi tamsayı guard tetikleyicilerini (mevcut `order_items.qty` / `products.moq` / `products.box_count` + yeni miktar kolonları; değer tabanlı predikat) ve kesirli legacy değerde **ön-doğrulama abort'unu** (yuvarlama yok) içerir (ADR-016 K12/1a, RV03).
- Rollback: platform migration'ları expand/contract ile geri alınabilir; `INVENTORY_PORT=off` B2B rollback'i; feature flag'ler (ARCH §91) riskli entegrasyonlar için.

---

## 18. Implementation fazları

Ortak kurallar: her faz küçük PR'lar + CI yeşil + Codex denetimi (HANDOFF akışı); "AI-generated code testsiz merge edilmez" (G13); faz kapanışı = acceptance criteria kanıt bağlantılı. **Ownership (ADR-004) onayı olmadan Phase 4+ commerce kodu yazılmaz.**

### Phase 0 — Repository Audit / Ownership Decisions (bu plan + kararlar)
- **Amaç:** ADR-004 (Seçenek B), ADR-001 (ayrı repo + vendored contract), ADR-015 (Drizzle), **ADR-016 (stok miktar modeli + B2B rezervasyon sözleşmesi — rev. 1.1)**, ADR-017 (Node container + Postgres; eski adı ADR-016 — **henüz yazılmadı, B3 / B7 ile tarihli beklemede 2026-09-18**), ADR-scaffold (Hono — **KARAR 2026-09-18:** Hono + zod-openapi) kapatmak; blocker listesini sahipli/tarihli kapatmak; doküman-kod çelişkilerini ARCH V2.1–V2.3 notlarıyla kapatmak.
- **Kapsam:** bu audit; ADR taslakları; Codex adversarial denetimi; proje sahibi karar listesi (B1-B10); Higgsfield'a yazılı sorular (egress, migration uygulama, deploy hattı, sır); canlı B2B envanteri (hangi commit, D1 seviyesi, `tenant_domains`); skill Excel'lerinin `data/` altına kopyalanması; `LARANTE_DESIGN_SYSTEM.md` sahiplendirme.
- **Kapsam dışı:** kod, migration, install.
- **Bağımlılıklar:** yok. **Değişen/yeni modüller:** yalnız docs/adr. **Veri/migration etkisi:** yok. **Security riski:** yok.
- **Test planı:** Codex denetimi bulguları plana işlenir. **Acceptance (2026-09-18 — sağlandı):** ADR-004 / 001 / 015 / 016 **onaylı (2026-09-18)**; ADR-017 (deployment / sağlayıcı) dosyası henüz yazılmadı — B3 / B7 ile tarihli beklemede, Phase 1'i bloklamaz; B1–B10 her biri karar / onay ya da tarihli beklemede; **Phase 1 ledger kapısı sağlandı:** ADR-016 onaylı, B6b / B6c karar, B6e birim sınıfları karar (proje sahibi hükmü 2026-09-18 — SKU verisi P4 / P7B, Phase 1'i bloklamaz); B6a eşleme kuralı kabul; U7 onaylı (B6h); scaffold (Hono + zod-openapi) ve `larante-platform` adı karar; ARCH düzeltme notları (§87 / §101 V2.1; §5.4 / §5.6 V2.3); B10 kalanı tarihli beklemede; Higgsfield cevapları / canlı D1 / fiyat listesi / sağlayıcı seçimleri Phase 1 koşulu değildir; HANDOFF akışı teyit; Phase 1 görev dosyaları hazır (`docs/tasks/PHASE1/`). **Phase 0 kapanış: 2026-09-18 (PHASE0 §F).**
- **Rollback:** n/a. **Risk:** Low.

### Phase 1 — Foundation (monorepo iskeleti + CI + ilk concurrency kapısı)
- **Amaç:** DoD ARCH §106 altyapı maddeleri; domain kodu yazmadan build/lint/test/e2e zinciri; **ilk kod = inventory ledger şeması (yalnız ADR-016 K2 şeması: balances / movements / reservations / reservation_events / operations) + gerçek Postgres'te "N eşzamanlı rezervasyon toplamı on_hand'i aşamaz" testi (kırmızı→yeşil)** — oversell koruması birinci günden ölçülür. **Kapı (F01) — sağlandı 2026-09-18:** ADR-016 onaylı, B6b / B6c karar, B6e birim sınıfları karar (proje sahibi hükmü) → ledger + concurrency testi Phase 1'in ilk kodudur (`docs/tasks/PHASE1/P1-T05`); "ledger'sız P1" yedek yolu artık gerekmez (tarihçe). Kalan SKU verisi (B6a / B6e) P4 / P7B veri hazırlığıdır ve ledger şemasını (K2) bloklamaz.
- **Kapsam:** `larante-platform` uygulama çalışma alanı / deposu (KARAR 2026-09-18; P1-T01), pnpm+Turbo, 4 app skeleton (web/admin/platform-api/worker "hello"), packages/{domain,application,db,adapters,identity,contracts,config,observability,testing,ui,design-tokens,analytics} boş iskelet; LW `env.ts`/`site.config.ts`/`instrumentation.ts` portu (sürümler security-patched exact: Next 16.3.x, TS typescript-eslint uyumlu, Vitest stabil, Node 22 LTS); docker-compose Postgres+MinIO; Drizzle migrate runner; CI zinciri (push tetiği ilk PR'da doğrulanır); import-boundary lint; env validation; security baseline (headers helper, secret policy); `packages/db` inventory_items/balances/movements/reservations + concurrency integration testi.
- **Kapsam dışı:** UI, domain use-case'leri, B2B.
- **Bağımlılıklar:** **Phase 0 kapandı (2026-09-18):** ADR-001 / ADR-015 onaylı, scaffold Hono + zod-openapi karar, `larante-platform` adı karar; **ledger için ADR-004 + ADR-016 onaylı, B6b / B6c / B6e birim sınıfları karar** (SKU verisi P4 — Phase 1'i bloklamaz). Görev dosyaları: `docs/tasks/PHASE1/README.md`. **Veri modeli:** yalnız inventory çekirdeği (ADR-016 K2). **Migration:** ilk migration. **Security:** düşük (secret policy, CI izinleri).
- **Test:** CI tüm kapılar yeşil; concurrency testi (yalnız ledger dalında). **Acceptance:** 4 app build; TS strict; lint; unit+integration runner; Playwright smoke; CI yeşil; env validation; **ledger dalı:** concurrency testi CI'da (ADR-016 2026-09-18'de onaylandığı için tek dal budur; "ledger'sız dal" tarihçedir).
- **Kapanış kaydı (2026-10-05 — Acceptance sağlandı; Phase 1 KAPANDI):** `docs/tasks/PHASE1/README.md` çıkış listesi kanıtla doğrulandı; uygulama deposu `larantekahve/larante-platform` `main` = `6fd2f2b97540118bcbf41db6d5d4c1a5891d3d83`. **(1) ARCH §106 altyapısı:** pnpm 12.4.2 + Turbo; `apps/web`, `apps/admin`, `apps/platform-api`, `apps/worker` build; TS strict; lint (import-boundary kuralları dahil); Vitest unit test runner; Playwright smoke; env validation; security baseline — merge sonrası CI koşusu 37213835963'te yeşil; P1-T04'ten bu yana `main` üzerindeki her push koşusu yeşil (36135566423, 36149391157, 37124125477, 37213835963). **(2) Ledger concurrency kapısı (ölçülen çıktı):** `packages/testing/test/inventory-ledger.integration.test.ts` (P1-T05, ADR-016 K2) CI'daki gerçek PostgreSQL 17.11 servisinde, süper kullanıcı olmayan CI rolüyle 20/20 yeşil — 16 eşzamanlı rezervasyon `on_hand` 10'u aşmaz; karışık miktarlarda `reserved` `on_hand`'i aşmaz; 10'un 4'ü rezerveyken 1'er birimlik 8 yarışçıdan tam 6'sı başarılı olur; "20 required test(s) present" kapısı geçer, atlanan test yok; P1-T05 merge'ünden (`cd09f9a`) bu yana her `main` push koşusunda yeşil. **(3) P1-T07:** PHASE0 B10 satırı "(b) TAMAMLANDI 2026-10-04"; Codex belge inspect'i APPROVED (`claudex-26u7w1id`, final `claudex-u7iwknoz`). **(4) HANDOFF akışı + G13:** P1-T01…P1-T07'nin her birinde Codex plan denetimi ve son kod / test denetimi APPROVED (son denetimler: `claudex-5qu34bvn`, `claudex-1nmnyc6y`, `claudex-45ebg_jf`, `claudex-t9twt9c1`, `claudex-fmm5h5b2`, `claudex-do0lp00k`, `claudex-1v6qtutk`; P1-T01'in son denetimi 11. turdur, P1-T04 ve P1-T06'da owner'ın yetkilendirdiği ek turlar vardır); merge'ler larantekahve/larante-platform#1–#7 ve larantekahve/larante-web-sitesi-v1#8; her platform PR'ı test içerir. **(5)** Bu kayıt ve `LARANTE_CODEX_HANDOFF.md` "Durum — 2026-10-05" bölümü. **Açık takip işleri (kapatılmadı; çıkışı bloklamaz):** P1-T06b / R61, B10-(a) (P7B) ve HANDOFF 2026-10-05 bölümündeki diğer açık maddeler. CI1 (test veritabanı temizliğinde 42501 yetki yarışı; takip sahibi proje owner) bu kayıt yazıldığında takip işiydi; sonradan kapandı — aşağıdaki "CI1 kapanış kaydı".
- **CI1 kapanış kaydı (2026-10-05, Phase 1 kapanışından sonra — CI1 KAPANDI):** düzeltme (CI1-FIX) larantekahve/larante-platform#8 ile `main`'e girdi — merge commit `cfa2e849f3d2ce29fa2d256876eee02cc5e88d13` (ebeveynler `6fd2f2b` ve incelenen HEAD `7ac1170`). `packages/testing` içindeki `createTestDatabase().drop()` yalnız geçici hatayı (`42501`, sunucu rutini `TerminateOtherDBBackends`) yeniden dener: **en çok 6 deneme; aralardaki beklemelerin toplamı 3.1 saniye** (100 / 200 / 400 / 800 / 1600 ms); diğer hatalar hemen yayılır; engel kalıcıysa son hata değişmeden döner ve veritabanı silinmiş sayılmaz. Bu, **toplam `drop()` süresinin garantisi değildir** (tek denemenin kendi zaman aşımı yoktur) ve **autovacuum'un kök neden olduğunun kanıtı değildir** — engelleyen backend'in kaynağı kanıtlanmadı; autovacuum açıklaması hipotezdir. Final Codex incelemesi (GPT-5.6 Sol high, inceleme 2/3) APPROVED (`claudex-iwrgpam1`); merge sonrası CI koşusu 37312562027 (push, `cfa2e84`) yeşil. **Açık kalan residual'lar:** CR3 (başarılı yeniden denemeler loglanmaz; owner seçeneği), SA1 (yerel bir çökmede şablon test veritabanı kalıntısı), SA3 (tek denemenin kendi zaman aşımı yok), R1 (toplam 3.1 saniyelik bekleme bütçesinin yeterli olduğu gösterilemez; engelin kaynağı bilinmiyor) ve başka rolün bağlı kaldığı senaryonun CI testi yerine yerel gerçek PostgreSQL probuyla kanıtlanması. Yukarıdaki Phase 1 kapanış kanıtları değişmedi; ayrıntı `LARANTE_CODEX_HANDOFF.md` "Durum — 2026-10-05 — CI1 kapanışı" bölümünde.
- **Rollback:** repo yeniden kurulabilir. **Risk:** Low.

### Phase 2 — Design System (Phase 3 ile paralel)
- **Amaç:** `packages/design-tokens` + `packages/ui` temel bileşenleri; web/admin layout-nav; erişilebilirlik baseline (REQ §72-74, §109; ARCH §84).
- **Kapsam:** token'lar (REQ §73 açık zemin, tek mavi vurgu, tipografi, radius), grid, nav (REQ §8-9: B2B Giriş belirgin), form primitifleri, ürün kartı iskeleti, admin primitifleri (tablo/form/dialog), `prefers-reduced-motion`, `design-package.md` kopya bankası + `logo.svg` girdisi; LS koyu palet alınmaz.
- **Kapsam dışı:** marka-yoğun hero/ana sayfa (P11), `LARANTE_DESIGN_SYSTEM.md` (B8) beklenen kısımlar; admin primitifleri beklemez.
- **Bağımlılıklar:** P1. **Veri/migration:** yok. **Security:** yok.
- **Test:** Storybook/visual snapshot + axe; klavye/focus. **Acceptance:** token'lar hard-code yok; web+admin kabuğu render; axe kritik 0; reduced-motion çalışır.
- **Rollback:** paket düzeyinde. **Risk:** Low.

### Phase 3 — Identity / Admin çekirdeği / yapısal Audit
- **Amaç:** G7 (admin 2FA + server RBAC) ve müşteri kimliği çekirdeği; yapısal audit + security events; site_settings.
- **Kapsam:** `packages/identity` portu (uyarlanmış); `admin_users` CRUD + davet + rol atama (son owner koruması); zorunlu TOTP enrollment + recovery + replay engeli + secret şifreleme; Postgres session store (hash, rotation, iptal); DB tabanlı IP+hesap rate limit; global guard; `audit_log` append-only (REVOKE) + `security_events`; `site_settings` (WhatsApp/IBAN/kargo eşiği/iletişim/sosyal/e-posta kimlikleri; audit'li); RetailCustomer auth çekirdeği (kayıt/giriş/reset — e-posta gönderimi P6'ya kadar fake adapter); apps/admin login + kullanıcı/ayar ekranları; nonce CSP.
- **Kapsam dışı:** B2B auth; SSO; müşteri adres/profil ekranları (P8).
- **Bağımlılıklar:** P1, (P2 admin primitifleri). **Veri modeli:** identity/audit/settings tabloları. **Migration:** yeni tablolar. **Security:** Yüksek (kimlik çekirdeği) → bağımsız gözden geçirme (Codex).
- **Test:** unit (hash/TOTP/CSRF/RBAC matrisi), integration (session rotation, rate limit, viewer 403 yan etkisiz, audit append-only), E2E admin login+2FA. **Acceptance:** admin 2FA zorunlu; 5 rol server-side; unauthorized testleri; audit kritik işlemleri kaydediyor; security_events; ayarlar admin'den değişiyor + audit.
- **Rollback:** feature flag'siz (temel); migration expand-only. **Risk:** Medium.

### Phase 4 — Catalog master + Import + Retail Pricing + Media
- **Amaç:** Platformu Product master yapmak; 179 ürün + Logo kodları + 94 görsel yüklü; public katalog SSR; KDV dahil tamsayı-kuruş fiyat tek fiyat servisiyle.
- **Kapsam:** catalog şeması (§11; birim sınıfları PAKET / ŞİŞE / ADET / KUTU, net içerik tanımlayıcı, kullanım tipi kanonik anahtarda, donuk pasta kutu içi parça sayısı SKU bazlı — B6a/B6e 2026-09-17; kanal uygunluğu niteliği: donuk grup public'te "İşletmelere Özel", B2C satın alımı kapalı — B5); `tools/import-catalog` (dry-run raporu: 179 ürün, 94 görsel, 216 Logo kodu, çakışmalar, active filtresi; **kontrollü Excel içe aktarımı** satın alma maliyetini ve KDV oranını tam varyanta eşler, belirsiz / eksik / çoklu eşleşme fail-closed → inceleme — B6i / B4d); B2B satır → varyant eşleme tablosu, kavrum ekseni ve mono / cup kutu içi sayıları veri görevi (B6a / B6e açık); `retail_prices/campaign_prices/price_history` + `PricingService.quote`; Media tablosu + S3 adapter + `files.server.ts` portu + WebP/AVIF pipeline + CDN URL; admin ürün/varyant/kategori/nitelik/hazırlama seçeneği/medya/fiyat/kampanya/SEO/öne çıkan CRUD (audit'li); public `/urunler`, `/urunler/[category]`, `/urun/[slug]`, arama (tsvector+pg_trgm, `SearchPort`), filtre/sıralama, karşılaştırma, `product_relations`; public DTO'da B2B alanı yok (contract test); cache/revalidate stratejisi (ARCH §49-50).
- **Kapsam dışı:** stok (P5) — bu fazda tüm ürünler "Sepete Ekle" yerine "Yakında"/in_stock=false projeksiyonu; sepet.
- **Bağımlılıklar:** P3 (admin auth), ADR-004 onayı, B4/B5/B6/B9 kararları, B8 içerik (nitelikler) kısmen. **Veri modeli:** catalog + pricing + media. **Migration:** yeni tablolar + seed (import aracı, migration değil). **Security:** Medium (admin yazma yolları, medya upload magic-byte, public cache'te özel veri yok).
- **Test:** unit (slugify, resolveRetailPrice, KDV hesabı kuruş), integration (import idempotent, price_history trigger, tsvector Türkçe), contract (public DTO), E2E (admin ürün oluştur → public'te görünür). **Acceptance:** REQ §117 "ürünler admin'den yönetilebiliyor / kategoriler / varyant seçimleri / kampanya fiyatı"; import dry-run onaylı; fiyat geçmişi kaydediyor; görseller WebP + srcset; Lighthouse SEO ≥95 (katalog sayfaları).
- **Rollback:** import aracı idempotent (yeniden çalıştırma güvenli); tablolar expand-only. **Risk:** Medium.

### Phase 5 — Inventory Core + admin stok + `/internal/v1/inventory` sözleşmesi
- **Amaç:** Tek yetkili stok ledger'ı canlı; rezervasyon atomik; oversell testi CI'da; public `in_stock` projeksiyonu; B2B'ye açılacak internal sözleşme tanımlı (B2B tarafı P7).
- **Kapsam (rev. 1.1):** reserve (çok satırlı, atomik) / patch (miktar-varyant) / release (sebep zorunlu) / commit (sevkiyat = COMMIT + SHIP) / adjust use-case'leri; açılış sayımı runbook'u (B6d: Depo sayar, Yönetici onaylar; zaman damgası + sayan + onaylayan + audit; COUNT_ADJUSTMENT ile ilk `on_hand`); shortage yönetici karar akışı (B6g: otomatik kısma yok; etkilenen siparişler listesi; sayım düzelt / bekle / PATCH / CANCEL; audit); 72 saat kararı yalnız Yönetici (B6f; ayrı yetki, aktör audit); `operations/{id}` + `abandon` (mezar taşı); alan düzeyi CHECK kısıtları (ADR-016 K2); worker skeleton + expiry job (yalnız ödenmemiş web rezervasyonları) + **eskalasyon job'u (24/48/72; sessiz release yok)** + **mutabakat job'u** (imzalı anlık görüntü çekme, invariant doğrulama `on_hand = Σ IN − Σ OUT` / `reserved = Σ aktif`, deterministik onarım, `INCOMPLETE` kuralı, rapor) + shortage uyarısı; sebepli manuel hareket + sipariş düzeyi iptal / ret (CANCEL) audit'i (WAREHOUSE / ADMIN rolü; `channel=b2b` ve karşılığında açık sipariş olan ACTIVE rezervasyon için bağımsız RELEASE ucu / düğmesi **yok** — B6k KARAR 2026-09-16; serbest bırakma yalnız sipariş iptali / reddi yoluyla); `/internal/v1/inventory/*` mutasyon ve idempotency kapısı principal → `external_tenant_id` + sahiplik, ad-alanlı `operation_id` (ADR-016 K4/7, K10/3); admin stok ekranı (on_hand / reserved / available, hareket + rezervasyon geçmişi, eskalasyon bayrakları, mutabakat raporu, 72 saat karar aksiyonları); açılış sayımı runbook (ADJUST_UP / COUNT_ADJUSTMENT); public projeksiyon (kısa revalidate; checkout yine DB doğrular); `/internal/v1/inventory/{availability, reservations, reservations/patch, reservations/release, reservations/commit, operations/{id}, operations/{id}/abandon}` (patch / release / commit sipariş kapsamlı, atomik) + servis token + Idempotency-Key + OpenAPI + fake B2B istemcisiyle contract test (imzalı snapshot doğrulaması dahil); geçici "B2B sevkiyatı elle SALE" prosedürü (ADR-004 sunset; cutover F07 AÇIK).
- **Kapsam dışı:** B2B repo değişikliği (P7); bulk/packaging conversion.
- **Bağımlılıklar:** P4 (variant + `stock_unit` + `variant_external_codes`), **ADR-016 onaylı**, B6a eşleme kuralı, B6b/B6c/B6e karar, B6f (**KARAR 2026-09-17:** yalnız Yönetici; saat ilk rezervasyon anından), B6g (**KARAR 2026-09-17:** otomatik kısma yok; `available < 0` iken yeni tahsis engeli ve kritik uyarı; yalnız Yönetici karar verir), B6d (**kural KARAR 2026-09-17**; tarih planlama). **Veri modeli:** inventory (P1'de başladı) + reservations channel + operations. **Migration:** kısıt ekleri. **Security:** Medium (internal endpoint kimliği, IP allowlist).
- **Test:** concurrency (N paralel reserve), expiry (yalnız ödenmemiş), idempotent reserve/patch/release/commit (aynı `operation_id` tek etki; farklı gövde 422), `abandon` çitlemesi, çok satırlı hepsi-ya-da-hiçbiri, eskalasyon bayrakları + sessiz release yokluğu, sebepsiz release reddi; açık B2B siparişinde bağımsız release ucu yok (B6k), mutabakat tespit / deterministik onarım / `INCOMPLETE`, shortage, tutarlılık job'u, admin unauthorized. **Acceptance:** oversell senaryosu CI'da yeşil; REQ §80-81 admin stok + sebep zorunlu + audit; §30 public davranış; internal sözleşme contract testi.
- **Rollback:** feature flag ile projeksiyon kapatılabilir; ledger append-only. **Risk:** High.

### Phase 6 — Transactional Outbox / Worker / Notification & Shipping portları
- **Amaç:** Bildirim ve zamanlı işler sipariş verisini kaybettirmeden çalışsın (G6/R11); Email/Sms/Shipping adapter'ları hazır.
- **Kapsam:** `outbox_events/processed_events/dead-letter`; worker consumer (SKIP LOCKED, backoff, dead-letter admin ekranı + yeniden kuyruğa alma, metrikler backlog/failure); `EmailProvider` + `SmsProvider` gerçek adapter (ADR-007 sağlayıcı) + fake; DNS SPF/DKIM/DMARC; şablonlar (Content); `delivery_log`; `ShippingProvider` ManualAdapter; müşteri reset e-postası gerçek; admin bildirimleri (yeni sipariş/lead/başvuru) altyapısı; observability (ARCH §72-74 alarm iskeleti).
- **Kapsam dışı:** checkout (P7), lead/akademi formları (P9).
- **Bağımlılıklar:** P3, B7 (sağlayıcı), B3 (DNS/domain). **Veri modeli:** outbox/delivery. **Migration:** yeni tablolar. **Security:** Medium (secret'lar, sağlayıcı webhook'ları).
- **Test:** "sipariş yazıldı + provider down" (event dead-letter'a düşer, sipariş kalır), worker restart pending outbox, handler idempotency, backoff. **Acceptance:** REQ §44 retry; dead-letter görünür; e-posta Larante domain'inden DKIM geçer; SMS delivery log.
- **Rollback:** worker durdurulur, outbox birikir (veri kaybı yok). **Risk:** Medium.

### Phase 7 — Cart / Checkout / Payment / Order lifecycle / Manuel kargo
- **Amaç:** Server-authoritative B2C satış akışı uçtan uca: sepet, checkout, kart/3DS + havale, webhook idempotency, rezervasyon TTL, sipariş durum makinesi + snapshot + SEQUENCE numara, admin sipariş yönetimi, manuel kargo + bildirimler, misafir takip.
- **Kapsam:** `carts/cart_lines` (imzalı guest token, login merge politikası); checkout use-case (fiyat/available/kupon iskeleti/kargo ücreti+ücretsiz eşik settings'ten/yasal onay sürümleri/adres+fatura profili+billing snapshot); `orders` + `order_lines` snapshot + `idempotency_key`; state machine + transition map; `PaymentProvider` adapter (sandbox) + 3DS + `payment_events` UNIQUE; kartta kısa TTL rezervasyon; ödeme başarısında rezervasyon kalıcılaşır (fiziksel düşüş yok), başarısızlık / TTL'de release; havale PAYMENT_PENDING + 24s + admin "ödeme alındı" (FINANCE) → rezervasyon kalıcılaşır; **COMMIT + SHIP sevkiyatta** (SHIPPED geçişi); iptal / iade release (ADR-016 K2/9); refund iskeleti (idempotent); misafir takip (rate-limit); admin sipariş ekranları (SALES/WAREHOUSE); takip no → SHIPPED + outbox bildirimi; müşteri hesabı sipariş geçmişi (temel).
- **Kapsam dışı:** kupon tam kuralları, iade akışı, favori/yorum (P8); kargo API.
- **Bağımlılıklar:** P4, P5, P6, B7 (PSP). **Veri modeli:** commerce tabloları. **Migration:** yeni tablolar + SEQUENCE. **Security:** High (ödeme, PII, yasal).
- **Test:** ARCH §80 senaryoları (duplicate webhook, oversell, transfer expiry, price change while cart open, stock zero while cart open, refund retry); E2E guest+member checkout kart sandbox + havale; mobil checkout. **Acceptance:** REQ §117 checkout/kart/havale/sipariş durumları/bildirimler/manuel kargo/misafir takip maddeleri; §118 webhook idempotency + oversell + havale timeout testleri yeşil.
- **Rollback:** ödeme sağlayıcısı feature flag; checkout "bakım modu" flag'i; siparişler kalıcı. **Risk:** High.

### Phase 7B — B2B Stok Entegrasyonu (paralel kulvar; P5 sonrası başlar; checkout'u bloklamaz, LAUNCH'I BLOKLAR)
- **Amaç:** REQ §31/§118 "stok tek kaynak" kriterini kapatmak: B2B sipariş geçişleri platform ledger'ına ADR-016 sözleşmesiyle (gönderimde rezervasyon; `rezervasyon_bekliyor → onay | rezervasyon_basarisiz`; commit sevkiyatta; iptal terminal) yazar; `products.stock` yazımı biter; geçici manuel SALE prosedürü kapanır (cutover runbook F07 AÇIK).
- **Kapsam (platform):** servis token yönetimi + rotasyon (IP allowlist F14 AÇIK); `channel='b2b'` rezervasyon (`expires_at NULL`, eskalasyon); mutabakat çekmesi için imza anahtarı yönetimi; contract test; `variant_external_codes(system='b2b')` tam eşleme (B6a tablosu). **Kapsam (B2B repo, tek PR — ADR-016 K12):** **bir additive D1 migration `0022`** (`order_reservation_ops` başlığı + `order_reservation_op_lines` satırları, `orders.request_hash / admission_token / revision / source_order_id`, `order_items.variant_code / order_unit / conversion_factor / qty_stock_units`, sipariş başına tek `pending` op indeksi, **DB düzeyi tamsayı guard tetikleyicileri + ön-doğrulama abort'u (RV03 — ADR-016 K12/1a)** — ADR-004 §3.5 istisnası, **B6h ONAY 2026-09-17**); `platform-client.server.ts` + vendored spec; `order` → `submission_id` çözümü + parmak izi → kredi taahhüdü dahil atomik kabul → kalıcı niyet → `reservations` (fail-closed) → tek kazanan koşullu sonuçlandırma (cari borç yalnız `onay`'da, `WHERE NOT EXISTS`); zod `qty`/`moq` tamsayı, koli tamsayı katı + snapshot; `admin-order-status` sevkiyat→commit, iptal→release (sipariş kapsamlı, sebep), **iptal-geri-alış ucu kaldırılır**; miktar / varyant değişikliği → `reservations/patch`; tüm durum yazıcıları op protokolünden (yerel geçişler koşullu tek UPDATE; geçiş matrisi ADR-016 K4-P); ek / fatura yazıcıları `iptal` / `rezervasyon_basarisiz` dışı durum + sürüm + bekleyen op yok koşuluyla, yükleme yarışında R2 temizliği; **istemci / okuyucu tarafı (ADR-016 K12/6):** `panel.tsx` `submission_id` üretimi + aynı kimlikle yeniden deneme + üç ayrı yanıt / gösterim, `ui.tsx` yeni durum etiketleri, `admin.tsx` eskalasyon bayrakları ve 72 saat aksiyonları, `admin-overview` / satış toplamlarında açık durum kümesi (`rezervasyon_bekliyor` ayrı sayaç; `rezervasyon_basarisiz` / `iptal` toplam dışı); bağımsız manuel RELEASE (`channel=b2b`) **sunulmaz — B6k KARAR 2026-09-16** (iptal / ret = tek idempotent CANCEL op, ADR-016 K5/4); **tekrar sipariş yolu (RV02 — K9/4, K12/6):** `panel.tsx` ad-eşlemesi kaldırılır, satırlar kalıcı `variant_code` / `order_unit` / `order_qty` ile çözülür, `orders` GET projeksiyonu + `OrderItem` tipi bu alanları taşır, `conversion_factor` K1/3 kuralıyla yeniden, çözülemeyen satır "onay gerekli", yeni kimlikler, `source_order_id`, yeniden açma yok; erişimde onarım + çekme ile tik (K4-R); `POST /api/b2b/internal/reservation-snapshot` (imzalı, salt-okunur; ADR-004 §3.7 istisnası, **B6h ONAY 2026-09-17**; **kiracı kapsamı RV01 — K11/2k, K12/7:** `resolveRequestTenant` + `PLATFORM_INTEGRATION_KEYS` kiracı / ortam bağı, `out_of_scope`, tenant damgalı audit, çapraz-kiracı kurtarma / sonuçlandırma yok); `INVENTORY_PORT=off|enforce` (yalnız `environment = production` dağıtımında `enforce`; prod D1'ini paylaşan non-prod dağıtım `off` değil **`environment_disabled`**: sipariş / cari / rezervasyon mutasyonları — bugünkü admin ve bayi yazıcıları dahil — dispatcher düzeyinde yan etkiden önce 403, anlık görüntü ucu 403, K4-R kurtarması kapalı, okuma uçları açık; ortam bilinmiyorsa non-prod — ADR-016 K11/2k-vii; `order_reservation_ops.environment` damgası); tenant içi atomik `order_no`; ürün id CSPRNG; `addTransaction` dönüş kontrolü; `admin-products` moq/box alanları; `admin-product-save` stock yazımı kaldırılır; `admin.tsx` stok input kaldırılır; `applySecurityHeaders` bağlanır; dokunulan dosyaların pin testleri davranış testine; off/enforce + contract testleri. **Ön koşul:** HEAD'in canlıya alınması (0003-0021 prova + uygulama) — ayrı B2B deploy projesi; B6a eşleme tablosu; ambiguous B2B satırlarının varyant başına bölünmesi (veri).
- **Kapsam dışı:** B2B ad/kategori pull (ayrı ADR); B2B outbox; B2B ölü kod temizliği; apps/b2b birleşmesi.
- **Bağımlılıklar:** P5; **ADR-016 onaylı; ADR-004 §3.5/§3.7 istisnaları B6h ile ONAYLI (2026-09-17)**; **B2 (barındırma/egress/servis token/deploy hattı)**; B6a eşleme tablosu (veri — açık); B6e varyant verisi (açık); **B6k karar (2026-09-16)**; **yetkilendirme blokajı (B6f 2026-09-17):** 'Yönetici' → B2B rol / yetki eşlemesi proje sahibince onaylanmalı; eskalasyon kararı ve CANCEL op genel `write` yerine ayrı sunucu yetkisiyle korunur, aktör audit'e yazılır, eşleme onaylanana kadar aksiyon reddedilir (ADR-016 K12/6). **Veri modeli:** platform yok; B2B: bir additive migration (`0022`). **Security:** High (servis kimliği, fail-closed davranış).
- **Test:** B2B vitest (fake platform: kesin hata → `rezervasyon_basarisiz`, borç yok; zaman aşımı → sorgu → aynı anahtar → `abandon`; çift POST tek sipariş; eşzamanlı kaybeden kazananın siparişine yazamaz; kredi taahhüdü; `credit_limit <= 0` sınırsız; commit/release; iptal terminal; kesirli qty 400 (zod) **ve** DB düzeyinde `SQLITE_CONSTRAINT` (RV03: 0.5 / 1.25 / 2.5 INSERT + UPDATE reddi, 5 / 5.0 korunur, legacy kesirli değerde migration abort; gerçek `node:sqlite`); imzalı snapshot doğrulama + tik ile sonuçlandırma; **kiracı izolasyonu (RV01):** yabancı niteleyicili mevcut / var olmayan kimlik → aynı `out_of_scope`, tik yabancı `pending` op'a dokunmaz, yetkisiz anahtar / ortam → 403 yan etkisiz, audit yalnız `:t`; **ortam izolasyonu:** paylaşımlı D1'de preview dağıtımından yetkili admin / bayi sipariş, cari, ek ya da rezervasyon mutasyonu → 403 `environment_disabled`, prod satırları değişmez; **tekrar sipariş (RV02):** gerçek `orders` GET'ten yükle → reorder, `variant_code` ile doğru varyant, dönüşüm dalları, arşivlenmiş / legacy satır onay gerekli, yeniden açma 409; **CANCEL op (B6k):** iptal + ters kayıt + RELEASE tek işlem, tekrar → aynı sonuç, bağımsız RELEASE ucu yok; off modu = eski davranış); platform contract test (çapraz-kiracı mutasyon / op-kimliği ad alanı dahil); staging'de gerçek B2B→platform çağrısı. **Acceptance:** `INVENTORY_PORT=enforce` canlıda; B2B siparişi platform `available`'ı düşürüyor; `products.stock` hiçbir yerden yazılmıyor; REQ §118 "stok tek kaynak kuralı doğrulanmış" işaretli; manuel SALE prosedürü kapatıldı.
- **Rollback:** `INVENTORY_PORT=off` (bugünkü davranış). **Risk:** High (dış blocker).

### Phase 8 — Customer Experience / Promotions / Returns
- **Amaç:** Hesap (profil/adresler/sipariş/kargo), favoriler, tekrar satın al, yorum + moderasyon + doğrulanmış alışveriş, kupon (UNIQUE kod, atomik kullanım, birleştirilebilirlik), iptal/iade durum makinesi + idempotent refund + RETURN stok hareketi, misafir→üye claim, admin müşteri ekranı agregatları.
- **Kapsam dışı:** Akademi/lead/içerik (P9). **Bağımlılıklar:** P7. **Veri modeli:** wishlist/reviews/coupons/return_requests. **Security:** Medium (yorum spam, kupon brute force, iade parası). **Test:** kupon yarışı, refund idempotent, REQUESTED→…→REFUNDED geçişleri, reorder yeniden doğrulama, moderasyon audit. **Acceptance:** REQ §117 favori/tekrar satın al/kupon/yorum moderasyonu; §85 admin müşteri ekranı. **Rollback:** modül flag'leri. **Risk:** Medium.

### Phase 9 — Academy / Leads / Content / Newsletter / Site Settings ekranları
- **Amaç:** REQ §54-69, §87-93: veri odaklı Akademi (program/oturum/başvuru, kontenjan atomik), lead pipeline (SAMPLE/QUOTE/CONTACT, durum makinesi + audit + bildirim), içerik (DRAFT/PUBLISHED/ARCHIVED, önizleme, redirect/noindex, marka imzası), reçete→sepete ekle, katalog PDF sayfası + admin yükleme (PII temiz yeniden üretim), newsletter double opt-in + consent_records, WhatsApp/iletişim sayfası (ayarlardan), öne çıkan ürünler.
- **Bağımlılıklar:** P6 (bildirim), P4 (ürün referansları), P3 (settings). **Security:** Medium (public formlar: rate limit + honeypot + duplicate). **Test:** kontenjan yarışı, lead geçişleri, content publish/preview yetkisi, unsubscribe token. **Acceptance:** REQ §117 numune/teklif/lead/Akademi takvim+başvuru/içerik yayınlama/katalog yönetimi. **Rollback:** modül flag'leri. **Risk:** Low.

### Phase 10 — Analytics / SEO / Consent
- **Amaç:** Consent banner + sürümlü kayıt; `packages/analytics` event layer (internal sink zorunlu, GA4 consent'e bağlı, Meta kapalı flag); sitemap/robots/canonical/OG/JSON-LD DB'den; internal KPI view'ları + admin satış dashboard'u (REQ §86, §95; Order/Payment mutabakatı, R10); Search Console.
- **Bağımlılıklar:** P7 (sipariş verisi), P9. **Security:** Low-Medium (consent olmadan script yüklenmez). **Test:** "analitik izin olmadan pazarlama scripti çalışmıyor" E2E; sitemap doğrulama; KPI = DB toplamları. **Acceptance:** REQ §118 consent/sitemap maddeleri; §86 KPI'lar. **Risk:** Medium.

### Phase 11 — Premium Home / Hero
- **Amaç:** `HeroSequence` (WebP kare seti, poster, kritik kareler, canvas/rAF, reduced-motion, cihaz/bağlantı fallback), marka hikayesi, kategori/Akademi/kalite bölümleri, öne çıkan ürünler; performans bütçesi (LCP ≤2.5s p75, INP ≤200ms, CLS ≤0.10; G12).
- **Bağımlılıklar:** P2, P4, B8 (`LARANTE_DESIGN_SYSTEM.md`, kareler 65-73, slogan yazımı). **Test:** LS selftest senaryoları Playwright'a (scrub timing, poster fallback, reduced-motion, video engellendiğinde); Lighthouse CI. **Acceptance:** REQ §107-108; hero fallback ile site kullanılabilir. **Rollback:** statik poster. **Risk:** Low.

### Phase 12 — Production Hardening / Launch kapısı
- **Amaç:** REQ §117 (27 madde) + §118 (21 madde) kanıt bağlantılı; bağımsız güvenlik denetimi; backup/restore drill; ödeme arıza tatbikatları; yük/eşzamanlılık; erişilebilirlik; yasal metin sürümleri (hukuk kontrolü); ARCH §74 kritik alarmlar; ARCH §80 11 senaryo CI'da; release tag; DNS/HSTS; B2B contract testi yeşil; **P7B tamamlanmadan launch YOK**.
- **Risk:** High (launch).

---

## 19. BLOCKER'lar (kodlamadan önce)

| # | Blocker | Etkilediği faz | Kanıt |
|---|---|---|---|
| **B1** | **ADR-004 onayı — ONAY 2026-09-18 (Seçenek B bütünü; B1 kapandı):** platform Product identity + Inventory owner; B2B tüketici; `products` projeksiyon; `stock` dondurulur; katalog / rebuild migration açılmaz — P7B'de bir additive istisna (ADR-016 K12, B6h onaylı); `variant_external_codes`; ARCH §87 yön tersine; geçici manuel SALE sunset tarihli; somut eşleme verisi B6a (veri) açık | P4+ (commerce), P1 ledger | `$action.ts:610-614, 712-727, 1086, 1119`; `0019:262-279`; seed `stock=0`; cron/KV/DO yok |
| **B2** | **B2B barındırma / deploy hattı / egress / servis token / canlı seviye**: origin erişilebilirliği (CLAUDE.md 7 Eyl); deploy config Higgsfield üretiyor; Worker sır taşımıyor; kimlik yalnız `fnf.internal` egress'ine → keyfi hosta HTTPS **NOT_FOUND**; **HEAD hiç deploy edilmemiş** (origin/main = MVP, 0001-0002); migration'ların otomatik uygulanıp uygulanmadığı çelişkili; Higgsfield'da mı kalınacak yoksa kendi Cloudflare hesabı mı (§14/11) | P7B, launch | `wrangler.jsonc:4-9,38-41,57-59`; `AGENTS.md:166-170`; `git rev-list origin/main..HEAD`=54 |
| **B3** | **Mimari yön KABUL 2026-09-17:** `www` (kurumsal + B2C) / `admin` / `b2b` alan adları; Platform / PostgreSQL yeni platform domainleri ve paylaşımlı envanter için yetkili; nesne depolama + CDN (medya / belge); transactional e-posta servisi (sistem / sipariş e-postaları); mevcut B2B ayrı sistem / repo, onaylı sürümlü API sözleşmesiyle; D1 B2B-yerel. **AÇIK (sağlayıcı seçimleri):** Postgres sağlayıcısı, hosting, nesne depolama / CDN sağlayıcısı, transactional e-posta sağlayıcısı, SMS sağlayıcısı, TR/EU veri yerleşimi, DNS / hosting uygulama ayrıntıları, e-posta domain'i (SPF/DKIM/DMARC), Supabase "Larante Kahve" uygunluğu — sağlayıcı ADR'si (ADR-017 / ADR-007) tamam sayılmaz | P6, P12 | LW D-007 "kısmen açık" |
| **B4** | **Fiyat gerçeği:** hangi liste güncel (B2B 0006 / skill 24 Ağu / Dashboard Eyl: 450/400/500, 1500/1800); `list_price` KDV dahil mi hariç mi; **perakende KDV dahil fiyat listesi hiçbir kaynakta yok** (B4a/B4b/B4c AÇIK); ürün bazlı KDV oranı kaynağı — **B4d KARAR 2026-09-17:** V1 kontrollü Excel ürün verisi → tam varyant (kategoriye göre tahmin yok; fail-closed), sonra Logo malzeme kartı salt-okunur; sipariş satırı KDV snapshot'ı; oranlar doğrulanmadan yazılmaz | P4 | DASH audit |
| **B5** | **KARAR 2026-09-17 (public satış kapsamı / kanal):** public B2C checkout donuk grup (donuk pastalar, Frozen Lemonade, Frozen Orange Juice) hariç onaylı grupları satar; donuk grup B2B + paylaşımlı envanterde kalır, public'te "İşletmelere Özel" lead-gen gösterimi (Sepete Ekle yok; iletişim / teklif CTA); public alt gruplar: Kahve (Espresso, Filtre), Aroma (Şuruplar, Meyve Püreleri, Bar Sosları, Bazlar), Toz (Milkshake, Frappe, Sıcak Çikolata, Beyaz Çikolata, Sahlep), Çay (100 / 250 / 300 g, demlik poşet); taksonomi ≠ kanal uygunluğu. **AÇIK:** Ekipman / Eğitim public'te var mı; "İşletmelere Özel" vitrininin IA yeri; paket listesi dışındaki satırların kanal uygunluğu | P4 seed | `0008`; `katalog-veri.mjs` |
| **B6** | **Karar 2026-09-16 (ADR-016 — onaylı 2026-09-18):** stok birimi = varyantın ticari birimi, tamsayı, koli tamsayı katı + snapshot, donuk pasta kutu (B6b); rezervasyon gönderimde, süresiz, 24/48/72 eskalasyon (B6c); **B6k KARAR 2026-09-16:** açık B2B siparişinin rezervasyonu siparişten bağımsız serbest bırakılmaz — yalnız sipariş düzeyi idempotent CANCEL op (ADR-016 K5/4). **Phase 0 karar paketi 2 (2026-09-17):** B6a/B6e modelleme kuralı (net içerik ≠ stok birimi; PAKET / ŞİŞE / ADET / KUTU; espresso / filtre ayrı SKU; donuk pasta kutu içi parça sayısı SKU bazlı ≠ koli `box_count`), B6d açılış sayımı kuralı (Depo sayar, Yönetici onaylar, audit), B6f (yalnız Yönetici; saat ilk rezervasyon anından), B6g (otomatik kısma yok; yalnız Yönetici), B6h (§3.5 / §3.7 ONAY), B6i (V1 kontrollü Excel → sonra Logo salt-okunur; satır maliyet snapshot'ı) KARAR. **Açık:** B6a somut eşleme tablosu + kavrum ekseni + "Kanesh / Mercantily" kaynağı + paket dışı satırlar (veri); B6e varyant başına koli içi adet / mono-cup kutu içi parça sayısı (veri); B6d takvim tarihi (planlama); B6f B2B yüzeyi rol eşlemesi (P7B yetkilendirme blokajı); B6i B2B `order_items` maliyet / KDV snapshot'ı (0022 kapsamı); B6j | P1 (ledger), P4, P5, P7B | hiçbir sistemde stok verisi yok; `$action.ts:115` kesirli qty |
| **B12** | **ADR-016 onayı — ONAY 2026-09-18** (proje sahibi; Codex denetimi tamamlandı: PR #1 taze inspect APPROVED `claudex-vnnauzuj` 2026-09-17, PR #2 taze inspect APPROVED `claudex-docuqko6` 2026-09-17) | P1 (ledger), P4, P5, P7B | `docs/adr/ADR-016` |
| **B7** | Sağlayıcı seçimleri: PSP (iyzico/PayTR; 3DS, kısmi iade), e-posta, SMS, S3-compatible storage + CDN | P6, P7 | ADR-007 |
| **B8** | Tasarım/içerik girdileri: `LARANTE_DESIGN_SYSTEM.md` yok; REQ §18 kahve nitelik içerikleri yok; Kahve/Toz/Çay/Pasta ürün fotoğrafı yok (94 Aroma görseli AI üretimi, §23 gerilimi); hero kare 65-73 eksik; e-katalog PDF'de kişisel e-posta; slogan yazımı | P2 (kısmen), P4 içerik, P11, launch | LS audit |
| **B9** | Kaynak dosyaların kalıcılığı: skill Excel'leri claude.ai oturum klasöründe (22-24 Ağu) → `data/` altına kopya + kaynak/tarih notu; `musteriler.xlsx` yok | P4 import | DASH audit |
| **B10** | Doküman-kod hizalaması (IS-AKISI Kural 7): ARCH §5.4/§5.6/§87 düzeltmesi (§87 V2.1 notu; **§5.4 / §5.6 V2.3 ile hizalandı 2026-09-18**); sipariş durum sözlüğü; admin rol seti; Logo V1 kapsam dışı + "Logo'ya yazma yok" yazılı teyidi — **Logo alt kalemi 2026-09-17'de yazılı teyit edildi** (B6i / B4d paketi: Logo erişimi yalnız SELECT, platform INSERT / UPDATE / DELETE yapmaz); **kalan kalemler tarihli beklemede 2026-09-18** (PHASE0 B10): (a) B2B tarafı belge senkronu → P7B B2B PR'ı; (b) ARCH gövde konsolidasyonu → `docs/tasks/PHASE1/P1-T07-docs-consolidation.md` (Phase 1 çıkış listesi); Phase 1 blokajı değil | P0 (kapandı 2026-09-18) → P1-T07 / P7B | §5; PHASE0 B10 |
| B11 | Doğrulanmamış varsayımlar (kayıt): B2B testlerinin geçtiği; Higgsfield güvenlik başlıkları; moq bug'ı çalıştırılarak; canlı `products.stock`; Supabase içeriği | — | — |

---

## 20. Anti-pattern kontrolü (bulundu / bulunmadı)

| Anti-pattern | Sonuç | Kanıt / not |
|---|---|---|
| Duplicate Product master | **BULUNDU (veri düzeyinde, 4 kopya)** | B2B D1 (ad-anahtarlı) / skill Excel (Logo kodlu) / Dashboard SQLite / Dashboard fiyat listesi; 450/400/500; 142 maliyet farkı → tek platform master + import aracı + external code |
| Duplicate Inventory master | **RİSK** (bugün gerçek envanter hiçbir sistemde yok) | B2B `stock` ölü kolon; web kendi stoğunu açar ve B2B kolonu yazılabilir kalırsa G1 ihlali → kolon dondurulur, B2B tüketici |
| Web↔B2B stok senkron scripti | Bugün yok; mimari yasak | B2B'de dış API yok; çözüm port + fail-closed çağrı, script değil |
| Client-side authoritative price | **BULUNMADI** (B2B'de server authoritative) | `OrderSchema` fiyat kabul etmez; `panel.tsx:146-148` yalnız gösterim (3. kopya, güvenlik ihlali değil) |
| Component içine business logic | KISMEN | `panel.tsx` sepet toplamı; `admin.tsx ProductRow.save` (moq bug); LS `index.html` 1769 satır inline — taşınmaz |
| UI-only authorization | **BULUNMADI** | `requireAdmin(capability)` server-side; yalnız UX eksiği (viewer düğmeleri gizlenmez); client-side route gating var ama veri API'de korunur |
| Payment webhook idempotency eksikliği | PSP yok; **genel idempotency yok** | `POST order` çift = 2 sipariş + 2 cari borç (`$action.ts:645`) → platformda `payment_events` UNIQUE + `idempotency_key` |
| Oversell riski | **BULUNDU (B2B canlı davranış)** | stok kontrol/düşüm yok; `stock=0` ürün sipariş edilebilir; kredi limiti read-then-write; `order_no` yarışı 500 |
| Audit eksikliği | **BULUNDU** | serbest metin, entity/before/after/ip yok; login/2FA/şifre olayları loglanmıyor; fiyat geçmişi yok; audit DELETE guard yok |
| ORM çoğalması | Bugün ORM yok; risk potansiyel | B2B ham D1; LW Drizzle kararı kurulmamış → tek ORM Drizzle (platform), B2B'de ORM eklenmez; aynı domain iki DB'de yaşamaz |
| Gereksiz microservice | **BULUNMADI**; plan modüler monolit + worker aynı image | B2B ayrı process mevcut durum, karar değil |
| Gereksiz yeni framework | ARCH varsayımı yanlış → Next.js+Postgres yeni yığın kaçınılmaz; LW TS 7.0.2/Vitest 5.0.0 uç sürüm kilidi tekrarlanmaz; Hono ADR-scaffold ile | 3 farklı yığın birikmiş (B2B TanStack/Workers, LW Next, DASH Python) |
| Mevcut sağlam kodu yeniden yazma | Korunuyor | fiyat motoru/auth/CSRF/TOTP/RBAC/files.server.ts B2B'de KEEP, saf parçalar port; B2B handler rewrite YOK (G14); pin testleri refactor maliyeti |
| AI-üretimi ölü kod | **BULUNDU (çok)** | B2B `src/layouts` 2721 satır + `src/components` + `packages/@higgsfield/*` 363 dosya + `design-inspector` (prod build'e giriyor) + `security-headers.server.ts` (çağrılmıyor) + `settings` tablosu + `products.sku` boş; LW 197 satır kod vs ~2.900 satır doküman; `araclar/katalog2-pdf.mjs` kayıp `cdp.mjs`; git yazarları 53/56 "Higgsfield Agent" |
| Test olmadan kritik finansal işlem | **BULUNDU** | `addTransaction` dönüşü kontrol edilmiyor; stok/oversell/idempotency/yarış testi 0; para REAL; qty kesirli → platformda test-first CI kapısı |
| Ek: tenant filtresiz `MAX+1` sayaç + INSERT'ten ayrı SELECT | BULUNDU | `$action.ts:707-710, 1112-1116`; 0021 "sonraki adım" |
| Ek: DTO yok, D1 satırları doğrudan JSON, `SELECT *` export | BULUNDU | `$action.ts` 24 `.results`, `:1901-1929` |
| Ek: "additive" denen DROP+CREATE rebuild migration, runner'sız, tek paylaşımlı D1 | BULUNDU | `0018/0019`; `wrangler.jsonc:57-59` |
| Ek: kaynak-metin pin testleri | BULUNDU | 12 dosya `readFileSync` + string sayımı |

---

## 21. SONUÇ

### A. "Bugün implementasyona başlasaydım ilk yapacağım iş"
Kod yazmadan: `docs/adr/ADR-004-product-inventory-ownership-gate.md` taslağını bu audit'in kanıt satırlarıyla yazmak (karar Seçenek B; B2B tüketici; `products` projeksiyon; `stock` dondurulur; katalog / rebuild migration açılmaz (P7B'de bir additive istisna); `variant_external_codes`; B2B çağrıları senkron + işlem kimliği (`Idempotency-Key`) + fail-closed; `INVENTORY_PORT=off|enforce`; rezervasyon B2B'de sipariş oluşturma anında; commit sevkiyat / release iptal; geçici manuel SALE sunset tarihli; ARCH §87 yön tersine; **ek not: HEAD hiç deploy edilmedi, 0003-0021 prod'a uygulanmadan P7B mümkün değil; egress izni NOT_FOUND**) + ADR-015 (Drizzle) + ADR-001 (ayrı repo + vendored contract) özetleri → HANDOFF akışıyla Codex adversarial denetimine sunmak. Aynı gün proje sahibine tek sayfalık karar listesi (B2-B6) ve Higgsfield'a 4 yazılı soru (egress, sır, migration uygulama, deploy hattı). Onay gelir gelmez ilk kod işi: `packages/db` inventory ledger şeması + gerçek Postgres'te "N eşzamanlı rezervasyon toplamı on_hand'i aşamaz" testi (kırmızı→yeşil) CI kapısına; iskeletin kalanı bunun etrafına örülür.

### B. "Kodlamadan önce mutlaka çözülmesi gereken kararlar"
1. **ADR-004 onayı** (Seçenek B) — B1 — **ONAY 2026-09-18** (bütünü).
2. **B2B barındırma/deploy/egress** — Higgsfield'da mı kalınacak, kendi Cloudflare hesabına mı geçilecek; HEAD canlıya nasıl alınacak; B2B Worker keyfi hosta HTTPS yapabilir mi; servis token nasıl saklanır — B2.
3. **Fiyat gerçeği** — güncel liste, `list_price` KDV durumu, **perakende KDV dahil fiyat listesi** (yok) — B4a / B4b / B4c AÇIK; ürün bazlı KDV oranı kaynağı **B4d 2026-09-17'de karara bağlandı** (Excel → tam varyant; sonra Logo salt-okunur).
4. **Kategori taksonomisi + public kapsam** — **B5 2026-09-17'de karara bağlandı** (public B2C donuk hariç; İşletmelere Özel gösterim; alt gruplar); kalan: Ekipman / Eğitim public'te, vitrin IA yeri, liste dışı satırlar.
5. **Varyant eşleme tablosu (veri) + kavrum ekseni + varyant başına koli içi adet / kutu içi parça sayısı verisi + fiziksel sayım tarihi (planlama) + B2B yüzeyi rol eşlemesi (P7B yetkilendirme)** — B6 veri / planlama kalanları (P4 / P5 / P7B; Phase 1'i bloklamaz); **ADR-016 resmi onayı (B12) — ONAY 2026-09-18** (stok birimi ve rezervasyon anı 2026-09-16'da; birim sınıfları, açılış sayımı kuralı, eskalasyon aktörü / saati, shortage politikası, ADR-004 §3.5 / §3.7 istisnaları ve maliyet kaynağı stratejisi 2026-09-17'de karara bağlandı; B6e Phase 1 kapısı 2026-09-18 hükmüyle sağlandı).
6. **Platform hosting/Postgres/domain/DNS** — B3 (mimari yön 2026-09-17'de kabul; sağlayıcı, TR/EU ve DNS ayrıntıları AÇIK); **PSP/e-posta/SMS/storage sağlayıcıları** — B7 (AÇIK).
7. **Tek ORM (Drizzle) + ayrı repo + Hono** — **ADR-015 ve ADR-001 ONAY 2026-09-18; Hono + zod-openapi scaffold KARAR 2026-09-18**; **doküman düzeltmeleri** (ARCH §87 V2.1; §5.4 / §5.6 V2.3 ile hizalandı; durum sözlüğü, rol seti, Logo kapsamı kayıtlı) — B10 kalanı tarihli beklemede 2026-09-18.
8. **Skill Excel'lerinin repo'ya alınması**, `musteriler.xlsx` akıbeti — B9.
9. **Uygulama deposu adı** — **KARAR 2026-09-18:** `larante-platform` (belge deposu yeniden adlandırılmaz); `LARANTE_DESIGN_SYSTEM.md` sahibi/tarihi — B8a AÇIK (Phase 2 / 11).

### C. "Önerilen Phase 0"
**Phase 0 = Karar kilidi (kod yok), 1-2 hafta:**
1. Bu planın Codex adversarial denetimi → bulgular plana işlenir (HANDOFF §"Codex'in ilk görevi").
2. ADR-001 / 004 / 015 / **016 — dördü de ONAYLI (2026-09-18)**; 017 (deployment — henüz yazılmadı, tarihli beklemede), scaffold (Hono + zod-openapi — KARAR 2026-09-18, ayrı ADR dosyası yok), 007 (PSP), 008 (outbox), 010 (identity boundary) taslakları `docs/adr/` altında ilgili fazda; ARCH düzeltme notları (§87 / §101 V2.1; §5.4 / §5.6 V2.3 — yapıldı); REQ/ARCH `docs/requirements|architecture/` altına (Phase 1 çalışma alanında).
3. Proje sahibi karar oturumu: B4 (fiyat listesi + KDV + perakende fiyat), B5 (taksonomi), B6 (varyant/stok birimi/rezervasyon anı/sayım tarihi), B7 (sağlayıcılar), B3 (hosting/domain). *(Durum 2026-09-17: 2026-09-16 ve 2026-09-17 paketleriyle B4d, B5, B6b/B6c/B6k, B6a/B6e kuralı, B6d kuralı, B6f, B6g, B6h, B6i ve B3 yönü karara bağlandı; kalan: B4a–c, B5 kalanları, B6 veri / tarih / rol eşlemesi, B7 ve B3 sağlayıcıları.)*
4. Higgsfield'a yazılı sorular (B2): egress, sır/servis token, migration uygulama mekanizması, deploy hattı; paralelde "kendi Cloudflare hesabı" seçeneğinin maliyeti.
5. Canlı B2B envanteri (salt-okunur): hangi commit koşuyor, D1 hangi migration'da, `tenant_domains` dolu mu, `products.stock` gerçek değerleri, R2 içeriği → ADR-004 kanıt listesine.
6. Kaynak konsolidasyonu: skill Excel'leri + `katalog-veri.mjs` + B2B seed → `data/` (kaynak/tarih notu); 2048 PNG'ler tek kaynak; e-katalog PDF PII notu.
7. `LARANTE_DESIGN_SYSTEM.md` sahiplendirme; içerik/görsel iş kalemleri (B8) sahip + tarih.
8. Çıkış kriteri (DoD) — **sağlandı 2026-09-18 (PHASE0 §D / §F):** ADR-004 / 001 / 015 / **016** onaylı; B1–B10 her biri karar / onay ya da tarihli beklemede; **Phase 1 ledger kapısı sağlandı** (ADR-016 onaylı; B6b / B6c karar; B6e birim sınıfları karar — SKU verisi P4 / P7B, Phase 1'i bloklamaz); B6a eşleme kuralı kabul; B2 / B3 / ADR-017 / sağlayıcılar tarihli beklemede (P1–P5'i bloklamaz; P6 e-posta domain'i için B3 DNS kısmı, P7B / launch için B2); Phase 1 görev dosyaları (task standardı: TASK ID / Requirement refs / ADR refs / Goal / Scope / Out of scope / Files allowed / Data migration impact / Security impact / Acceptance / Tests / Rollback) **hazır: `docs/tasks/PHASE1/README.md` + `P1-T01`…`P1-T06`**.

---

## 22. Doğrulama (bu planın kendisi nasıl test edilir)
- **Codex adversarial denetimi** (HANDOFF): yanlış varsayım/kırılma senaryosu arar; özellikle ADR-004 kanıtları, B2 egress/deploy varsayımı, faz bağımlılıkları, migration/rollback, test/acceptance.
- **Kanıt tekrarı:** her `dosya:satır` referansı repoda salt-okunur açılarak yeniden doğrulanabilir (ajan JSON'ları: `read_*.json`, `verify_*.json`, `gap_G*.json`, `arch_*.json`, `judge.json`, `critic.json` — scratchpad `audit/`).
- **Phase 0 sonrası / ilgili faz öncesi somut doğrulamalar (Phase 1'i bloklamaz — 2026-09-18):** canlı B2B commit/D1 seviyesi ve Higgsfield yazılı cevapları (B2 — P7B öncesi); fiyat listesi onayı (B4a — P4 öncesi); `tools/import-catalog --dry-run` prototipi (Phase 4'te) 179 ürün/94 görsel/216 Logo kodu eşleşme raporu.
- **Phase 1 çıkışında:** CI zinciri yeşil + **ledger concurrency testi CI'da yeşil (zorunlu — `docs/tasks/PHASE1/P1-T05`)** = oversell koruması ölçülmüş; P1-T07 (B10 ARCH konsolidasyonu) tamamlanma kaydı. *("ledger'sız dalda bu ölçüm P5 başına kayar" ifadesi tarihçedir — ADR-016 2026-09-18'de onaylandı.)*

**Bu oturumda (2026-09-15) hiçbir kaynak dosya değiştirilmedi; hiçbir install/build/migration/test çalıştırılmadı.** Plan bitti — onay bekleniyor. **Rev. 1.1 (2026-09-16):** yalnız dokümantasyon revize edildi (dal `docs/stok-b2b-v2-1`); kod yazılmadı.
---

## 23. Denetim bulguları dispozisyonu (Codex GPT-6 Astra doküman denetimi, 2026-09-16)

**Revizyon 1.1 (2026-09-16, dal `docs/stok-b2b-v2-1`)** yalnız stok / B2B sipariş-rezervasyon sözleşmesi bulgularını çözer. Diğer bulgular **bilinçli olarak açık bırakılmıştır**; sonraki karar paketlerinde ele alınır. Hiçbir bulgu sessizce kapatılmamıştır.

| Bulgu | Konu | Durum | Nerede |
|---|---|---|---|
| F01 | P1 kalıcı ledger'ı B6b/B6c/ADR-006 onaysız kuruyordu | **ÇÖZÜLDÜ** | ADR-016 §6; §18 P0/P1; PHASE0 §D |
| F02 | `INTEGER CHECK(>0)` ↔ işaretli `qty_delta`; RESERVATION/RELEASE fiziksel toplamda | **ÇÖZÜLDÜ** | ADR-016 K2; §8; ADR-015 §6; ARCH V2.1 §17, §62 |
| F03 | Senkron reserve → D1 yazımı arasında sahipsiz rezervasyon; kurtarma yok | **ÇÖZÜLDÜ** | ADR-016 K4, K4-P, K4-R, K11; §9; ARCH V2.1 §87 |
| F04 | `order_id+geçiş` idempotency anahtarı; kalıcı gönderim dedup'ı yok | **ÇÖZÜLDÜ** | ADR-016 K10; §14; ARCH V2.1 §64 |
| F05 | Ürün düzeyi dış kod ↔ varyant düzeyi stok | **ÇÖZÜLDÜ (kural)** — veri eşlemesi B6a AÇIK | ADR-016 K6; §11; ADR-004 §3.4 |
| F06 | Kesirli B2B miktarı; koli dönüşümü dondurulmuyor | **ÇÖZÜLDÜ** | ADR-016 K1; REQ §31.2; PHASE0 B6b |
| F07 | P7B cutover: geçiş öncesi siparişlerde commit edilecek rezervasyon yok; elle SALE çift sayım | **AÇIK** — cutover runbook karar paketi | PHASE0 §E |
| F08 | `INVENTORY_PORT=off` launch sonrası tek stok kuralını ihlal eder; degradasyon prosedürü yok | **AÇIK** | PHASE0 §E |
| F09 | Webhook dedup yalnız event id; tutar / sipariş / deneme eşlemesi yok | **AÇIK** (ADR-007 ile) | PHASE0 §E |
| F10 | Misafir sipariş sahiplenme (claim) kanıtı | **AÇIK** | PHASE0 §E |
| F11 | `CHECK reserved<=on_hand` hasar / sayım düşüşünü engeller | **ÇÖZÜLDÜ** — sert kısıt kaldırıldı, shortage uyarısı tanımlandı; kısma politikası U5 **B6g KARAR 2026-09-17** (otomatik kısma yok; yalnız Yönetici) | ADR-016 K2/8, §7 |
| F12 | B2B projeksiyonunun import sonrası yaşam döngüsü | **AÇIK** | PHASE0 §E |
| F13 | Sipariş snapshot'ında varyant nitelikleri / teslimat adresi | **KISMEN** — varyant snapshot'ı ADR-016 K6/6 + ARCH §21; teslimat adresi snapshot'ı AÇIK | PHASE0 §E |
| F14 | IP allowlist sabit egress varsayar | **AÇIK** (Higgsfield soruları) | PHASE0 §B, §E |
| F15 | B2B CI tetiği ölü; contract release kapısı | **AÇIK** | PHASE0 §E |
| F16 | Phase 0 çıkış listesi tutarsız; ADR-016 yok | **KISMEN ÇÖZÜLDÜ** — ADR-016 yazıldı, çıkış kriterleri hizalandı; B3/B7 kapasite bazlı ayrımı AÇIK | PHASE0 §D, §E; §21.C |
| F17 | Akademi kontenjanı katılımcı sayısını yok sayar | **AÇIK** | PHASE0 §E |
| F18 | Internal analytics sink consent'siz davranışsal olay yazıyor | **AÇIK** | PHASE0 §E |
| H2 | Onaylanmayan / iptal edilmeyen B2B siparişi stoğu süresiz tutar | **ÇÖZÜLDÜ** — otomatik serbest bırakma yok; 24/48/72 eskalasyon + yönetim kararı | ADR-016 K5; REQ §31.4 |
| H6 | ARCH §101 ↔ §18 iki farklı faz haritası | **ÇÖZÜLDÜ** — §18 yetkili; ARCH V2.1 §101 eşleme tablosu | ARCH V2.1 §101 |
| H8 | `b2b.larantecoffee.com` özel alan adı + `tenant_domains` tohumsuz | **AÇIK** | PHASE0 §B, §E |
| H10 | Kart rezervasyon TTL'i 3DS oturum süresinden kısa olabilir | **AÇIK** (ADR-007 ile) | PHASE0 §E |

**Plan denetimi bulguları (bu revizyonun kendi Codex plan denetimi, R01–R13):** R01 ödeme ↔ sevkiyat COMMIT ayrımı (ADR-016 K2/9); R02/R09 kurtarma yürütücüsü + çitleme (K4-R); R03 anlık görüntü tamlığı (K11/2a); R04/R10/R11/R12/R13 cari ve kredi yaşam döngüsü (K4/1–2, K4-F); R05 gönderim parmak izi (K4/0); R06 varyant tekilliği (K6/2); R07 normatif kalıntılar (bu dokümanın §6, §7, §10, §17, §19, §21); R08 sürüm + tek uçuş (K4-P).

**İkinci tur inspect bulguları (2026-09-16, Codex GPT-6 Astra `claudex-hvm78reh`; plan denetimi PLAN-R01–R05 dahil):**

| Bulgu | Konu | Durum | Nerede |
|---|---|---|---|
| RV01 | Anlık görüntü ucu + tik kiracı kapsamı; platform mutasyon / idempotency sahipliği; işlem kimliği ad alanı; inspect tur 1 ekleri IR01 ortam izolasyonu (paylaşımlı D1), IR02 web rezervasyon tekilliği (`namespace`), IR03 `out_of_scope` yanıt birliği, IR04 422 / 404 ayrımı; inspect tur 2 eki IR05 non-prod `environment_disabled` (mutasyon yok; eski `off` değil) — **son düzeltme bağımsız denetimden geçmedi (inspect bütçesi doldu)** | **ÇÖZÜLDÜ** (IR05 denetim bekliyor) | ADR-016 K2/4, K4/7, K4-R, K10/3–4, K11/2k, K11/2a, K11/3–4, K12/7, §6; ARCH V2.1 §17, §62, §87; REQ §31.8, §118; PHASE0 §B-2; bu doküman §8, §9, §14, §15, P5, P7B |
| RV02 | Tekrar sipariş yolu (kalıcı `variant_code`; projeksiyon / tipler; K1/3 dönüşüm; yeni kimlikler; yeniden açma yok) | **ÇÖZÜLDÜ** | ADR-016 K9/4, K12/6, §6; REQ §31.6; ARCH V2.1 §87; bu doküman §9, §15, P7B |
| RV03 | Mevcut REAL miktar kolonlarında DB düzeyi tamsayı guard'ları (`0022` tetikleyicileri + ön-doğrulama; 0.5 / 1.25 / 2.5 testi) | **ÇÖZÜLDÜ** | ADR-016 K1/4, K12/1a, K12/3, §5, §6; ADR-004 §3.5; ARCH V2.1 §62; REQ §118; bu doküman §15, §17, P7B |
| B6k | Açık B2B siparişinde bağımsız serbest bırakma | **KARAR 2026-09-16** — yok; yalnız sipariş düzeyi idempotent CANCEL op; mutabakat yalnız gerçek sahipsiz | ADR-016 K5/4, §7 U9; REQ §31.1, §31.4, R18; ARCH V2.1 §17, §87; PHASE0 B6k; ADR-004 §3.9; bu doküman §9, §14, P5, P7B, §19 |

**Bu revizyonla değişen ADR-004 hükümleri:** §3.5 (P7B'de bir additive D1 migration) ve §3.7 (imzalı salt-okunur mutabakat çekme ucu) — **B6h ONAY 2026-09-17 (U7 kapandı)**; §3.9 (iptal terminal; iptal-geri-alış kaldırıldı), §3.2 / §3.4 / §3.8 (ADR-016'ya göre) — **kilitlendi (2026-09-18: ADR-016 ve ADR-004 bütünü / B1 onaylı)**.

**Phase 0 onay paketi 3 (proje sahibi, 2026-09-18; dal `docs/phase0-final-approvals`) — Phase 0 kapanışı:**

| Kalem | Durum | Nerede | Kalan |
|---|---|---|---|
| ADR-001 | **ONAYLI 2026-09-18** (ayrı repo + sürümlü HTTP sözleşmesi; B2B monorepoya alınmaz; sahiplik sınırları ve sözleşme sürümleme korunur) | ADR-001 Durum; PHASE0 §D / §F | — |
| ADR-015 | **ONAYLI 2026-09-18** (PostgreSQL + tek ORM Drizzle; yarış-kritik SQL repository / migration sınırında; rakip ORM yok; B2B D1 ham SQL) — sağlayıcı markası onayı değil | ADR-015 Durum + onay notu; ARCH §5.6, §106 | Sağlayıcı (B3 / ADR-017) tarihli beklemede |
| Scaffold | **KARAR 2026-09-18:** Hono + zod-openapi (Phase 1) | PHASE0 satırı; §10; ARCH §5.4 V2.3 | Kod / paket dosyası Phase 1'de (P1-T06) |
| Uygulama deposu adı | **KARAR 2026-09-18:** `larante-platform` (ASCII); belge deposu yeniden adlandırılmaz | PHASE0 satırı; ADR-001 §Karar 1 / 6; §10 | Dokümantasyon taşıma / referans P1-T01 |
| B6e Phase 1 kapısı | **Sağlandı 2026-09-18** (proje sahibi hükmü) | PHASE0 §Kural / §D; §18 P0 / P1; §21.C-8; ARCH §101; ADR-016 §6 | SKU verisi P4 / P7B (B6a / B6e ☐ veri; icat yok) |
| ADR-016 / B12 | **ONAYLI 2026-09-18** | ADR-016 Durum; PHASE0 B12; §19 B12; ARCH §106 | — |
| ADR-004 / B1 | **ONAYLI 2026-09-18** (Seçenek B bütünü; B6h istisnaları onaylı; tek envanter master) | ADR-004 Durum + §6; PHASE0 B1; §19 B1; ARCH §106; REQ §31 / R12 | Eşleme verisi B6a (veri) |
| B10 | §5.4 / §5.6 V2.3 ile hizalandı; kalan **tarihli beklemede 2026-09-18** (B2B belge senkronu — P7B; ARCH gövde konsolidasyonu — P1 sonu) | PHASE0 B10; ARCH §0b | — |
| ADR-017 / sağlayıcılar | **Dosya yok; tarihli beklemede 2026-09-18** | PHASE0 B3 / §F; §11, §18 P0; ARCH §100; ADR §İlgili | Postgres / hosting / storage-CDN / e-posta / SMS / TR-EU / DNS / Supabase (B3, B7) |
| Çıkış kriterleri | Çelişkiler giderildi (PHASE0 §Kural / §D, §18 P0 / P1, §21.B / §21.C-8, §22, ARCH §101 / §106, ADR-016 §6) | — | — |
| Phase 1 görev dosyaları | **Hazır:** `docs/tasks/PHASE1/README.md`, `P1-T01`…`P1-T06` | docs/tasks | Uygulama Phase 1'de |

**Phase 0 karar paketi 2 (proje sahibi, 2026-09-17; dal `docs/phase0-business-decisions-v2`):**

| Karar | Durum | Nerede | Kalan |
|---|---|---|---|
| B6a/B6e | **Modelleme kuralı KARAR** — net içerik ≠ stok birimi; PAKET / ŞİŞE / ADET / KUTU; espresso / filtre ayrı SKU; donuk pasta kutu içi parça sayısı SKU bazlı (cheesecake / dilimli 12; mono / cup ürüne özgü) ≠ koli `box_count`; konfigürasyon değişince yeni SKU; satır snapshot | ADR-016 K1/2–3, K6/2, K7/5, §7 U1 / U3; REQ §12–14, §19–21, §31.2–31.3; ARCH §13; §11 | **Veri (açık):** somut satır → varyant eşleme tablosu (repolarda yok), kavrum ekseni, "Kanesh / Mercantily" kaynağı, paket dışı satırlar, mono / cup kutu içi sayıları, koli içi adet doğrulaması |
| B6d | **Kural KARAR** — legacy stock / tahmin ile tohumlama yok; SKU düzeyi fiziksel sayım; Depo sayar, Yönetici onaylar; audit; COUNT_ADJUSTMENT | ADR-016 U2; ADR-004 §3.10, §6/5; REQ §81; §17, P5 | Takvim tarihi (planlama, F07 runbook); varyant kataloğu sonrası |
| B6f | **KARAR** — saat ilk rezervasyon anından; onay sıfırlamaz; 72 saat yalnız Yönetici; sürdür / uzat audit; ret / iptal = CANCEL op | ADR-016 K5/2–3, U4, K12/6; REQ §31.4, §77, §83; ARCH §26; P5, P7B | B2B yüzeyi rol eşlemesi (P7B yetkilendirme blokajı) |
| B6g | **KARAR** — otomatik kısma / yeniden atama / serbest bırakma / iptal yok; tahsis blokajı; kritik uyarı; yalnız Yönetici; web TTL / sahipsiz onarım önceliği | ADR-016 K2/8, U5; REQ §31.1, §80; ARCH §16; P5; F11 | — |
| B6h | **ONAY** — ADR-004 §3.5 (additive fail-closed 0022) ve §3.7 (imzalı, kiracı + ortam kapsamlı salt-okunur snapshot) | ADR-004 §3.5, §3.7, §6/8; ADR-016 U7; §9, §17, P7B; PHASE0 | ADR-004 bütünü (B1), ADR-016 resmi onayı (B12) ayrı |
| B6i | **Kaynak stratejisi KARAR** — V1 kontrollü Excel → tam varyant (fail-closed); sonra Logo salt-okunur SQL; güncel maliyet + kaynak + son güncelleme; satır snapshot; donuk pasta SKU bazlı | ADR-016 U6, K7/5; ADR-004 §3.11; REQ §82; ARCH §90; §11, §13, P4 | B2B `order_items` snapshot'ı (0022 kapsamı); Excel / Logo adları; B9 |
| B4d | **KARAR** — KDV oranı V1 Excel → tam varyant; sonra Logo malzeme kartı; satır snapshot; tahmin yok | REQ §7.1; ARCH §21; §4.2, §11, §19 | B4a / B4b / B4c açık; kontrollü Excel hazırlanacak (B9) |
| B5 | **KARAR** — public B2C donuk hariç; İşletmelere Özel gösterim; alt gruplar; taksonomi ≠ kanal | REQ §12, §19–21, §30, §31.3, §115, §117; ARCH §18, §20; §19 | Ekipman / Eğitim public'te; vitrin IA yeri; liste dışı satırlar |
| B3 | **Yön KABUL** — www / admin / b2b; Platform / PostgreSQL; nesne depolama + CDN; transactional e-posta; B2B ayrı repo + sözleşme; D1 yerel | §19; ARCH §4, §97; REQ §110; PHASE0 | Sağlayıcılar (Postgres, hosting, storage / CDN, e-posta, SMS), TR/EU, DNS; ADR-001 / ADR-015 / ADR-017 onayı |
