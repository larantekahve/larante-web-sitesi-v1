# LARANTE WEB PLATFORMU — MASTER IMPLEMENTATION PLAN (Faz 0 Audit + Plan)

**Tarih:** 2026-09-15 · **Mod:** PLAN MODE — hiçbir kaynak dosya değiştirilmedi; install/build/migration/test çalıştırılmadı (yalnız salt-okunur inceleme + git okuma komutları).
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
2. **B2B bir Inventory owner DEĞİL.** `products.stock REAL` yalnızca admin formundan elle yazılan bir sayı; sipariş oluşturma stoğu ne okur, ne düşer, ne rezerve eder (`$action.ts:610-614`, `:712-726`); ledger/rezervasyon/hareket tablosu yok; seed'de tüm ürünler `stock=0`; stok testi sıfır. → **ARCH §3 Seçenek B**: `apps/platform-api` (Postgres) Product identity + Inventory master olur, B2B tüketici olur. Seçenek A uygulanamaz; Seçenek C yalnız kimlik köprüsü (`product_external_code`) düzeyinde gerekli.
3. **B2B'nin Product master'ı zayıf ama fiyat domaini sağlam.** Varyant/kategori tablosu/slug/KDV/fiyat geçmişi yok; doğal anahtar ürün ADI; ama `dealerPrice/effectiveDiscount/categoryDiscountsFor/activeCampaignsFor/productDiscount` server-side authoritative ve entegrasyon testli → **B2B fiyatlaması B2B'de KEEP (G3), web'e kopyalanmaz**. B2B `products` tablosu "B2B kanal projeksiyonu" olarak kalır; eşleme platformda `product_external_code(system='b2b')`.
4. **Ürün master'ı bugün fiilen 4 kopya** (B2B D1 ad-anahtarlı / skill Excel'leri Logo kodlu / Dashboard SQLite normalize-ad / Dashboard Eylül fiyat listesi) ve ayrışmış (Çikolata Şurup 450/400/500; 142 üründe maliyet farkı). G2 ihlali kodda değil ama veri düzeyinde gerçekleşmiş → tek import aracı + Logo kodu köprüsü zorunlu.
5. **Yeniden kullanım kod düzeyinde ~%5-10, desen/veri/varlık düzeyinde yüksek.** Port edilecek saf parçalar: PBKDF2/oturum-cookie/CSRF/TOTP/RBAC matrisi/kilit (`core.server.ts`), zod şemaları + `OrderSchema` "fiyat istemciden alınmaz" sözleşmesi, `files.server.ts` dosya güvenliği, LW `env.ts`/`site.config.ts`; 179 ürün seed'i, 94 ürün görseli (+2048 PNG), vektör logo, hero kare dizisi. Geri kalan commerce domaini (varyant, retail pricing, inventory ledger, cart/checkout, payment, order state machine, outbox/worker, promotion, review, wishlist, return, academy, lead, content, media, newsletter, settings, analytics, yapısal audit, RetailCustomer, admin app) **NEW**.
6. **Repo kararı: AYRI REPO + versiyonlu HTTP sözleşmesi** (`larante-platform` pnpm+Turbo+Next.js+Postgres; B2B Bun/Workers/D1'de kalır). Monorepo'ya alma iki package manager, vendored `@higgsfield/*` workspace paketleri ve Higgsfield deploy CI'ının repo'daki wrangler.jsonc'yi yok sayması nedeniyle bugün doğrulanamaz.
7. **İki kritik yeni bulgu (eleştirmen + bizzat teyit):** (a) **Deploy hattındaki kod `origin/main` = `bb2c415` (17 Ağu MVP), HEAD'in 54 commit gerisinde, yalnız migration 0001-0002 içeriyor** → audit'in "MEVCUT/KEEP" dediği tenant/CSRF/2FA/RBAC/kampanya/koli/0021 kodunun **hiçbiri canlıda değil**; canlı portal büyük olasılıkla CSRF/2FA/tenant'sız MVP. (b) **B2B Worker'ın keyfi dış hosta HTTPS çıkışı doğrulanamadı** (`wrangler.jsonc:38-41` "platform Outbound Worker injects secrets on egress"; `packages/fnf/ai/AGENTS.md:166-170` kimlik yalnız `fnf.internal`'a) → B2B→platform stok çağrısı (P7) fizibilitesi Higgsfield'a yazılı sorulmalı; cevap "hayır" ise tek yol B2B'nin kendi Cloudflare hesabına taşınması.
8. **Kodlamadan önce çözülmesi gereken blocker'lar:** ADR-004 onayı (Seçenek B); B2B barındırma/egress/deploy hattı + canlı D1 migration seviyesi; fiyat gerçeği (hangi liste güncel, KDV dahil/hariç, perakende fiyat listesi yok); kategori taksonomisi; varyant/stok birimi/rezervasyon anı (A-13); sağlayıcılar (PSP/e-posta/SMS/Postgres hosting); skill Excel'lerinin repo'ya alınması.

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
| Ürün kimliği: id/variant/slug/external code (ARCH §89) | YOK | `urun_maliyet.xlsx` Logo kodları; D-005 slug kuralı | B2B ad-anahtarlı; Logo'da aynı ürün 2 kod (Nar Şurubu) | NEW UUID + slug + `product_external_codes` 1:N (logo, b2b) |
| Admin ürün yönetimi (§79) | KISMEN | zod `ProductSaveSchema` deseni | B2B admin eksik/hatalı (moq bug, yeni ürün yok, ad düzenlenemez) | REBUILD (apps/admin) |
| Seed/import + dual master yasağı (§112, G2) | KISMEN (veri) | 0006/0008/0009-0012, katalog-veri.mjs, urun_maliyet.xlsx | Master 4 kopya ve ayrışmış; Excel→migration deseni | NEW `tools/import-catalog` (idempotent upsert, dry-run) |

### 4.2 Retail Pricing (G1)
| Requirement | Statü | Reusable | Risk | Aksiyon |
|---|---|---|---|---|
| KDV dahil public fiyat, B2B'den bağımsız (§7.1, R1, G3) | YOK | `fmtTL`; fatura KDV oranları (%1/%20) | B2B KDV kavramı yok, para REAL | NEW `retail_prices(price_kurus, tax_rate_bp, tax_inclusive)` |
| Varyant bazlı fiyat, "başlangıç fiyatı" (ARCH §14) | YOK | — | perakende fiyat listesi hiçbir kaynakta yok (B4) | NEW + `min_price` materialized |
| Kampanya fiyatı + tarih penceresi (§48) | YOK | `activeCampaignsFor` tarih penceresi kuralı | B2B kampanya yüzde+dealer kapsamlı | NEW `retail_campaign_prices` |
| Fiyat geçmişi (§82, ARCH §54) | YOK | — | yerinde UPDATE, geçmiş yok | NEW append-only `price_history` |
| Server-side authoritative price (R6, G4) | **MEVCUT (B2B)** | `OrderSchema` + order handler | kompozisyon 2 kopya; panel.tsx 3. kopya (gösterim) | KEEP (kural) — retail için `PricingService.quote` tek fonksiyon |
| B2B pricing web'e taşınmaz (§7.2, ARCH §15, G3) | **MEVCUT** | `core.server.ts:668-873` | kod "tek oran" vs teklif skill'i "zincirleme+min fiyat" (A-12) | KEEP (B2B'de); B2B tarafında ayrı ADR |

### 4.3 Inventory (G1)
| Requirement | Statü | Reusable | Risk | Aksiyon |
|---|---|---|---|---|
| Tek yetkili stok, dual master yasak (§31, §112, R2, G1) | YOK | — | **B2B owner değil**; Isletme_Sistemi stok sahibini Logo sayar ama kod bağı yok, Workers yerel ağa erişemez | ADR-004 Seçenek B; B2B `stock` dondurulur |
| InventoryItem/Balance/Movement/Reservation, available türetilir (ARCH §16) | YOK | — | stok birimi kararı açık (A-13) | NEW ledger (INTEGER, CHECK) |
| Sebepli hareket + audit (§81, G8) | YOK | `addTransaction` fail-closed batch deseni (finans) | B2B stok mutlak atama, sebepsiz | NEW `reason NOT NULL enum` + audit |
| Admin stok ekranı (§80, R3) | YOK | — | — | NEW (WAREHOUSE rolü) |
| Public projeksiyon `available>0` (§30, R3) | KISMEN | `in_stock: p.stock>0` tek satır | B2B rozeti siparişi engellemez | NEW; checkout server kontrolü esas |
| Kart ödemede kısa TTL rezervasyon/commit/release (§41, ARCH §25) | YOK | koşullu batch deseni (`$action.ts:1192-1227`) | oversell | NEW atomik `UPDATE … WHERE on_hand-reserved>=q` |
| Havale 24s rezervasyon + worker expiry (§42) | YOK | — | B2B'de cron/worker yok | NEW (worker) |
| Concurrency + DB kısıtları + oversell testi (ARCH §62-63, §118) | YOK | fail-closed migration ilkesi | B2B'de FK yok, yarış testi yok | NEW; CI kapısı |
| B2B Integration Contract + ACL (ARCH §87-88) | YOK | — | Yön tersine (B2B tüketici); B2B'de makine API'si yok; egress belirsiz | NEW `/internal/v1/inventory` + B2B `platform-client` |
| Fiziksel stok birimi (ARCH §13) | YOK | `box_count`, `Ana Birim`, `Koli İçi Adet` | A-13 | V1: sellable variant; koli dönüşümü B2B adapter'ında |
| B2B siparişinin tek stoğa bağlanması | KISMEN | order handler + admin-order-status | atomik değil; pin testleri; deploy belirsiz | REFACTOR (B2B repo PR, P7) |

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
| B2B `products` tablosu + admin ürün akışı | **KEEP + ADAPTER** | B2B kanal projeksiyonu; eşleme platformda `product_external_code(system='b2b')`; **B2B'de yeni D1 migration açılmaz**. Tek B2B PR'ı (P7): `admin-products` GET'e moq/box (bug), `stock` alanının form+save'den çıkarılması. |
| B2B envanter (`products.stock`) | **REBUILD (platformda NEW)** | Ölü kolon, ledger/rezervasyon yok, test yok; kolon dondurulur, silinmez (rebuild migration açmamak için). |
| B2B sipariş handler + `admin-order-status` (`$action.ts:598-736, 1174-1246`) | **REFACTOR (P7, B2B PR)** | Çalışır ve testli; kancalar: reserve/commit/release, tenant içi atomik `order_no` (0021 sözleşmesinin uygulama yarısı), `addTransaction` dönüş kontrolü, geçiş matrisi. Rewrite G14 ile yasak. |
| B2B `$action.ts` monolit + `admin.tsx/panel.tsx` UI | **KEEP (B2B'de)** | B2B kanalı için çalışıyor; parçalama platform kapsamı dışı; UI platforma taşınmaz, ekran akışları spec. |
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

## 7. Product ownership kararı — **ADR-004 (taslak): ARCH §3 Seçenek B**

**Karar:** `apps/platform-api` (PostgreSQL) **Product identity ve katalog master'ıdır** (UUID id, slug, kategori ağacı, `sellable_variants`, `preparation_options`, nitelikler, medya, KDV oranı, perakende fiyat). B2B `products` tablosu silinmez, **B2B kanal projeksiyonu** olarak kalır: `list_price / box_count / box_unit_price / moq / dealer-grup-kategori-kampanya iskontoları` B2B fiyat domainidir (G3) ve orada kalır. Eşleme yalnız platformda `product_external_codes(system ∈ {logo,b2b}, code)` 1:N (aynı ürün Logo'da iki kod; B2B `products.id` de buraya). **B2B'de yeni D1 migration açılmaz**; B2B katalog migration'ları dondurulur (kural). B2B'nin ad/kategori alanlarını platformdan çekmesi (pull) V1 dışı, ayrı ADR.

**Kanıt:** B2B ürün modeli REQ §12-18'i taşıyamaz — tek düz tablo, varyant/kategori/slug/KDV/fiyat geçmişi yok, `sku` boş (`0019:262-278`); doğal anahtar ürün ADI (`0004:5-6`, `0006:4-5`); yeni id tenant filtresiz `MAX(sort)+1` (`$action.ts:1112-1116`); admin UI ad/kategori düzenleyemez, yeni ürün ekleyemez, her satır kaydı moq'u sıfırlar (`$action.ts:1069 vs 1086`); master 4 kopya ve ayrışmış (DASH audit). Onu D1 içinde büyütmek = paylaşımlı prod D1'de rebuild migration + belirsiz deploy hattı.

**Reddedilenler:** A (B2B owner) — model yetersiz, D1 dış API açmıyor. C (kademeli) — yalnız kimlik köprüsü olarak zaten uygulanıyor. Öneri 2'nin `0022 platform_variant_id` kolonu — işlevsel kazanç yok (eşleme platformda), migration riski var → HAYIR.

**Geçici adapter (G2 gereği belgeli, sunset tarihli):** B2B ürün id ↔ platform variant eşlemesi `product_external_codes`; ilk eşleme 179 ürün için import aracı dry-run raporunda elle doğrulanır.

---

## 8. Inventory ownership kararı — **ADR-004 (devam)**

**Karar:** `apps/platform-api` (PostgreSQL) **tek Inventory Core sahibi**: `inventory_items(variant_id UNIQUE)` · `inventory_balances(on_hand INT, reserved INT, version; CHECK on_hand>=0, reserved>=0, reserved<=on_hand)` · `inventory_movements(qty_delta INT, reason enum PRODUCTION|SALE|RETURN|DAMAGE|WASTE|COUNT_ADJUSTMENT|MANUAL_ADJUSTMENT|RESERVATION|RELEASE, ref_type/ref_id, actor, note)` · `inventory_reservations(item_id, qty, status, expires_at, order_ref, channel web|b2b, idempotency_key UNIQUE)`; `available = on_hand − reserved` türetilir. **B2B tüketicidir.** `products.stock` dondurulur (admin formundan kaldırılır, `admin-product-save` yazmaz, katalog `in_stock` port'tan; kolon silinmez). Açılış stoğu **fiziksel sayımla** `COUNT_ADJUSTMENT` — taşınacak stok verisi hiçbir sistemde yok. Logo V1'de owner değil; ileride yalnız platform-api tarafında `AccountingProvider`.

**Kanıt:** `$action.ts:610-614` (order SELECT'inde `stock` yok), `:712-726` (batch yalnız INSERT), `:1086/:1119` (tek yazım admin), 21 migration'da inventory/movement/reservation tablosu yok, seed hepsi `stock=0`, yerel D1 `stock>0` = 0, stok testi sıfır, `wrangler.jsonc` triggers yok, manifest kv:false/DO null, DASH/skill'lerde stok yok, kodda Logo bağı yok.

**Stok birimi (V1):** sellable variant = stok kalemi; B2B koli = `qty × box_count` dönüşümü B2B adapter'ında; öğütüm stok etkisi yok (R4); bulk kg → paket "packaging conversion" ertelenir (ADR ile; üretim gerçekliğine göre proje sahibi onayı — B6).

---

## 9. B2B entegrasyon stratejisi

- **Repo:** AYRI (bkz. §10). Sözleşme `packages/contracts/internal.b2b-integration.v1` (zod → OpenAPI); B2B'ye **vendored** kopya (`app/src/lib/b2b/platform-contract.v1.json` + üretilmiş tipli istemci `platform-client.server.ts`, sürüm pini); iki CI'da contract test. npm/git-tag dağıtımı yok (Bun/Higgsfield CI'da doğrulanmamış).
- **Yön:** yalnız B2B → platform (`/internal/v1/inventory/{availability,reserve,commit,release}`); platform → B2B çağrı yok. Kimlik: servis token (+ IP allowlist, rotasyon) — **barındırma/egress kararına bağlı (B2)**.
- **Kancalar (B2B PR, P7):** `POST order` → `availability` + `reserve(channel='b2b', qty=adet|qty×box_count, idempotency_key=order_id+'reserve', expires_at NULL)`; başarısızsa sipariş yazılmaz (**fail-closed**). `admin-order-status`: `sevkiyat` → `commit` (SALE), `iptal` → `release`, iptal-geri-alış → yeniden `reserve`. Tek bayrak `INVENTORY_PORT=off|enforce` (off = bugünkü davranış = rollback; **"soft/uyar-geçir" modu YOK** — üçüncü bir stok gerçeği üretir).
- **Rezervasyon anı:** sipariş oluşturma (POST order) — B2B siparişi `onay` (Onay Bekliyor) ile açılır (`$action.ts:715`); onay süresince web aynı birimi satabilir; oversell aşırı rezervasyondan kötüdür. A-13 iş kararı olarak teyit edilir (B6).
- **Geçiş dönemi (P7 canlıya kadar):** B2B sevkiyatları platform admin'inden elle `SALE (ref='b2b:#order_no')` işlenir — senkron scripti değil, tek ledger'a operatör girişi; ADR-004'te sunset tarihli; sahibi Depo rolü.
- **B2B'de outbox/worker kurulmaz** (D1 batch-only, transaction yok; cron/queue/KV/DO yok); çağrılar senkron + Idempotency-Key + timeout + sınırlı retry.
- **Aynı PR'daki zorunlu B2B düzeltmeleri:** tenant içi atomik `order_no` (0021 sözleşmesi: INSERT…SELECT MAX+1 aynı ifadede/counter), ürün id CSPRNG (CLAUDE.md §6.4), `addTransaction` dönüş kontrolü, `admin-products` moq/box alanları, `applySecurityHeaders` bağlanması; dokunulan dosyaların pin testleri davranış testine çevrilir.
- **ÖN KOŞUL (yeni bulgu):** HEAD (`d75dc7d`) hiç deploy edilmemiş; canlıya alınması için `0003-0021` (19 migration; 0015 26 preflight abort, 0016 142, 0018/0019 DROP+CREATE rebuild) **paylaşımlı prod D1'e** uygulanmalı → ayrı B2B deploy projesi: canlı D1 seviyesi teyidi → yedek → staging benzeri kopyada prova (yerel miniflare ile mümkün) → uygulama. Bu iş P7'nin ön koşulu ve **Higgsfield'da mı kalınacağı (§14/11) kararına bağlı**.
- **Kademeli birleşme (apps/b2b):** yalnız B2B kendi Cloudflare hesabına geçer VE entegrasyon 1 çeyrek canlıda kanıtlanırsa ayrı ADR ile; o zaman bile D1→Postgres taşıma yok.

---

## 10. Önerilen hedef repository yapısı

**Repo kökü = bu proje klasörü** (`LARANTE WEB SİTESİ - v1` → `git init`; HANDOFF: planlama ve kodlama aynı klasör). ⚠️ Klasör adı boşluk + Türkçe karakter içeriyor; bazı araçlar (turbo cache, native modüller, Windows yol uzunluğu) sorun çıkarabilir → **P1'de ASCII ad (`larante-platform`) önerilir** (kullanıcı kararı).

```
larante-platform/                     pnpm + Turborepo · Node 22 LTS · TS strict · exact security-patched sürümler
├── apps/
│   ├── web/                          Next.js App Router (www). Server Components. LW env/site.config/instrumentation tohumu (sürüm kilidi düzeltilmiş).
│   │                                 Routes (ARCH §96 + D-005): / /urunler /urunler/[category] /urun/[slug] /hakkimizda /akademi /akademi/[slug] /ilham /ilham/[slug]
│   │                                 /katalog /iletisim /hesabim /siparis-takip /sepet /odeme. Sağlayıcı SDK importu YASAK; yalnız packages/contracts istemcisi.
│   ├── admin/                        Next.js App Router (admin.larantecoffee.com). Ayrı cookie (__Host-, Strict), nonce CSP, zorunlu 2FA, 5 rol.
│   ├── platform-api/                 Node + Hono (+@hono/zod-openapi) — ADR-scaffold ile sabitlenir. Modüler monolit:
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
**B2B (mevcut, ayrı repo, yerleşim değişmez)** — P7'de tek PR: `app/src/lib/b2b/platform-client.server.ts` (NEW), `platform-contract.v1.json` (NEW), `$action.ts` (kancalar + düzeltmeler), `admin.tsx` (stok input kaldırılır), `__tests__/` (pin → davranış). Kural: B2B'de D1 migration açılmaz; B2B'de `pg/drizzle` yok; platformda `cloudflare:*` yok.

---

## 11. Veri modeli stratejisi

- **DB:** PostgreSQL (16/17); yalnız düz Postgres (sağlayıcıya özgü auth/RLS/edge yok → taşınabilir); local/CI/staging docker-compose; prod sağlayıcı ADR-016 (B3). B2B D1 dokunulmaz; iki DB tablo/migration/bağlantı paylaşmaz.
- **Tek ORM:** Drizzle + drizzle-kit (ADR-015). Gerekçe: SQL-first → `UPDATE … WHERE on_hand-reserved>=$q`, `SELECT … FOR UPDATE SKIP LOCKED`, SEQUENCE, CHECK/UNIQUE/FK gizlenmeden yazılır/review edilir; motor/Data Proxy yok; LW D-008 aynı karar. Prisma/TypeORM platformda yasak.
- **Tipler:** para `*_kurus INTEGER`, oranlar basis point INT, miktar INTEGER CHECK(>0); REAL/float yasak (B2B İlke 7 ihlali tekrarlanmaz). Tüm id UUID; slug tr-ASCII UNIQUE (D-005).
- **Catalog:** `product_categories(id, parent_id, slug, name, sort, visible_public)` · `products(id, slug UNIQUE, name, category_id, status draft|active|archived, seo jsonb, featured_sort)` · `sellable_variants(id, product_id, sku UNIQUE, weight_g, roast_level, agtron, active; UNIQUE(product_id, weight_g, roast_level))` · `preparation_options` + `product_preparation_allow` (stok kalemi değil) · `product_attributes(typed) + category_attribute_templates` · `media` + `product_media(kind packaging|lifestyle)` · `product_external_codes(system logo|b2b, code; UNIQUE(system,code))` 1:N · `product_relations`.
- **Retail pricing (G3):** `retail_prices(variant_id, price_kurus, tax_rate_bp, tax_inclusive=true, effective_from)` · `retail_campaign_prices(variant_id, price_kurus, starts_at, ends_at, active)` · `price_history` (append-only; DB rolünde UPDATE/DELETE yetkisiz) · `products.min_price_kurus` materialized. B2B `list_price/iskonto` platformda ASLA tutulmaz.
- **Inventory:** bkz. §8. Rezervasyon tek atomik UPDATE; commit aynı transaction'da SALE movement; `SUM(movement)=on_hand` tutarlılık job'u.
- **Commerce:** `carts/cart_lines` (imzalı guest token, merge) · `orders(order_no SEQUENCE, status + transition map, customer_id NULL|guest_email/phone, idempotency_key UNIQUE, terms_version, pre_information_version, privacy_version)` · `order_lines(product/variant id, name, sku, unit_price_kurus, tax_rate_bp, discount jsonb, preparation_snapshot, qty)` · `order_billing_snapshot` · `payments` · `payment_events(provider, event_id UNIQUE, raw jsonb)` · `shipments` · `return_requests` (state machine) · `coupons` + `coupon_redemptions(order_id UNIQUE)` · `outbox_events` · `processed_events(event_id, handler PK)` · `delivery_log`.
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
- **Logo/ERP:** yalnız platform-api'de gelecek `AccountingProvider` (Workers yerel ağa erişemez; B2B'ye konmaz).

---

## 14. Transaction / concurrency / idempotency

- **Sipariş oluşturma:** tek Postgres transaction = `orders` + `order_lines` + `order_billing_snapshot` + rezervasyon commit/oluşturma + `outbox_events`; `idempotency_key` UNIQUE (client-generated, checkout token'a bağlı) → tekrar = aynı sipariş döner.
- **Rezervasyon:** `UPDATE inventory_balances SET reserved=reserved+$q, version=version+1 WHERE item_id=$i AND on_hand-reserved>=$q` (0 satır → yetersiz stok); `inventory_reservations.idempotency_key UNIQUE`; commit: aynı transaction'da `reserved-=q, on_hand-=q` + SALE movement; release: worker (expiry) veya use-case. Kart: kısa TTL (site_settings), havale: 24s (site_settings).
- **Ödeme webhook:** `payment_events(provider, event_id) UNIQUE` INSERT … ON CONFLICT DO NOTHING; eklenmediyse no-op; eklendiyse aynı transaction'da order → PAYMENT_RECEIVED + rezervasyon commit + outbox. Geç gelen webhook (rezervasyon süresi dolmuş): yeniden rezervasyon dene, olmazsa `PAYMENT_RECEIVED_NO_STOCK` iç durumu + kritik alarm + manuel iade akışı.
- **Kupon:** `UPDATE coupons SET used=used+1 WHERE code=$c AND used<usage_limit RETURNING` + `coupon_redemptions(order_id UNIQUE)`.
- **Sipariş numarası:** Postgres SEQUENCE (+ prefix format kararı); B2B tarafında tenant içi MAX+1 tek ifadede (0021 sözleşmesi).
- **Outbox:** aynı transaction'da INSERT; worker `SELECT … FOR UPDATE SKIP LOCKED`, exponential backoff (`available_at = now + 2^attempts×30s`, max N → dead), `processed_events(event_id, handler)` PK ile handler idempotency; dead-letter admin ekranı + yeniden kuyruğa alma.
- **Akademi kontenjan:** `UPDATE academy_sessions SET confirmed=confirmed+1 WHERE id=$s AND confirmed<capacity RETURNING`.
- **Order/Return state machine:** izinli geçiş tablosu domain'de; invalid geçiş domain hatası; terminal durumlar tanımlı (B2B'deki "her durumdan her duruma" tekrarlanmaz).
- **B2B çağrıları:** senkron, `Idempotency-Key = order_id+geçiş`, timeout + sınırlı retry, fail-closed; platform yan etkilerini kendi outbox'ına yazar.

---

## 15. Test stratejisi

- **Piramit (ARCH §79):** Unit (domain: pricing, promotion, order/return state machine, inventory math — saf, DB'siz) · Integration (gerçek Postgres test container: rezervasyon concurrency, outbox, webhook idempotency, kupon yarışı, auth, migration up/down, contract) · E2E (Playwright: browse, add to cart, guest/member checkout, havale, kart sandbox, order tracking, admin stok/kargo, academy, lead).
- **CI kapıları (her PR):** lint (import-boundary, cloudflare:* yasak, domain→framework yasak) · typecheck strict · unit · integration (Postgres servis) · build (4 app) · e2e smoke · contract test (public DTO'da B2B alanı yok; internal.b2b v1 uyumu) · migration check (up + yeniden çalıştırma idempotent) · dependency scan. Sonra: accessibility (axe), Lighthouse CI bütçesi, migration review.
- **Zorunlu risk senaryoları (ARCH §80, §118) — kırmızı→yeşil test-first:** son stok için N eşzamanlı checkout (toplam ≤ on_hand) · duplicate payment webhook · payment success + notification provider down (sipariş kaybolmaz) · transfer expires (release) · coupon last-use race · admin unauthorized role (403 yan etkisiz) · guest order lookup brute force (rate limit) · product price changes while cart open (server yeniden fiyatlar) · stock goes zero while cart open · refund retry idempotent · worker restarts with pending outbox · B2B reserve/commit/release idempotent (fake platform ile B2B testi; fake B2B istemcisi ile platform testi).
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
- **Veri göçü (platforma):** ürün/kategori/görsel/Logo kodu → `tools/import-catalog` (idempotent, dry-run, onay); stok → fiziksel sayım (COUNT_ADJUSTMENT); B2B siparişleri/müşterileri **taşınmaz** (ayrı domain); LW/LS'den kod göçü yok.
- **B2B migration'ları:** platform işi değil; **HEAD'in canlıya alınması** (0003→0021) ayrı B2B deploy projesi: canlı seviye teyidi → yedek → miniflare/staging kopyasında prova (0015/0016 preflight abort koşulları tablo halinde) → uygulama; platformun deploy'da otomatik uygulayıp uygulamadığı Higgsfield'a sorulur. B2B'de yeni migration açılmaz (P7 dahil).
- Rollback: platform migration'ları expand/contract ile geri alınabilir; `INVENTORY_PORT=off` B2B rollback'i; feature flag'ler (ARCH §91) riskli entegrasyonlar için.

---

## 18. Implementation fazları

Ortak kurallar: her faz küçük PR'lar + CI yeşil + Codex denetimi (HANDOFF akışı); "AI-generated code testsiz merge edilmez" (G13); faz kapanışı = acceptance criteria kanıt bağlantılı. **Ownership (ADR-004) onayı olmadan Phase 4+ commerce kodu yazılmaz.**

### Phase 0 — Repository Audit / Ownership Decisions (bu plan + kararlar)
- **Amaç:** ADR-004 (Seçenek B), ADR-001 (ayrı repo + vendored contract), ADR-015 (Drizzle), ADR-016 (Node container + Postgres), ADR-scaffold (Hono) kapatmak; blocker listesini sahipli/tarihli kapatmak; doküman-kod çelişkilerini ARCH V2.1 notuyla kapatmak.
- **Kapsam:** bu audit; ADR taslakları; Codex adversarial denetimi; proje sahibi karar listesi (B1-B10); Higgsfield'a yazılı sorular (egress, migration uygulama, deploy hattı, sır); canlı B2B envanteri (hangi commit, D1 seviyesi, `tenant_domains`); skill Excel'lerinin `data/` altına kopyalanması; `LARANTE_DESIGN_SYSTEM.md` sahiplendirme.
- **Kapsam dışı:** kod, migration, install.
- **Bağımlılıklar:** yok. **Değişen/yeni modüller:** yalnız docs/adr. **Veri/migration etkisi:** yok. **Security riski:** yok.
- **Test planı:** Codex denetimi bulguları plana işlenir. **Acceptance:** ADR-004/001/015/016 onaylı; B1-B10 her biri "karar verildi / tarihli beklemede"; ARCH V2.1 düzeltme notu; HANDOFF akışı teyit.
- **Rollback:** n/a. **Risk:** Low.

### Phase 1 — Foundation (monorepo iskeleti + CI + ilk concurrency kapısı)
- **Amaç:** DoD ARCH §106 altyapı maddeleri; domain kodu yazmadan build/lint/test/e2e zinciri; **ilk kod = inventory ledger şeması + gerçek Postgres'te "N eşzamanlı rezervasyon toplamı on_hand'i aşamaz" testi (kırmızı→yeşil)** — oversell koruması birinci günden ölçülür.
- **Kapsam:** `git init` (klasör adı ASCII önerisi), pnpm+Turbo, 4 app skeleton (web/admin/platform-api/worker "hello"), packages/{domain,application,db,adapters,identity,contracts,config,observability,testing,ui,design-tokens,analytics} boş iskelet; LW `env.ts`/`site.config.ts`/`instrumentation.ts` portu (sürümler security-patched exact: Next 16.3.x, TS typescript-eslint uyumlu, Vitest stabil, Node 22 LTS); docker-compose Postgres+MinIO; Drizzle migrate runner; CI zinciri (push tetiği ilk PR'da doğrulanır); import-boundary lint; env validation; security baseline (headers helper, secret policy); `packages/db` inventory_items/balances/movements/reservations + concurrency integration testi.
- **Kapsam dışı:** UI, domain use-case'leri, B2B.
- **Bağımlılıklar:** Phase 0 ADR-001/015/scaffold. **Veri modeli:** yalnız inventory çekirdeği. **Migration:** ilk migration. **Security:** düşük (secret policy, CI izinleri).
- **Test:** CI tüm kapılar yeşil; concurrency testi. **Acceptance:** 4 app build; TS strict; lint; unit+integration runner; Playwright smoke; CI yeşil; env validation; concurrency testi CI'da.
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
- **Kapsam:** catalog şeması (§11); `tools/import-catalog` (dry-run raporu: 179 ürün, 94 görsel, 216 Logo kodu, çakışmalar, active filtresi); `retail_prices/campaign_prices/price_history` + `PricingService.quote`; Media tablosu + S3 adapter + `files.server.ts` portu + WebP/AVIF pipeline + CDN URL; admin ürün/varyant/kategori/nitelik/hazırlama seçeneği/medya/fiyat/kampanya/SEO/öne çıkan CRUD (audit'li); public `/urunler`, `/urunler/[category]`, `/urun/[slug]`, arama (tsvector+pg_trgm, `SearchPort`), filtre/sıralama, karşılaştırma, `product_relations`; public DTO'da B2B alanı yok (contract test); cache/revalidate stratejisi (ARCH §49-50).
- **Kapsam dışı:** stok (P5) — bu fazda tüm ürünler "Sepete Ekle" yerine "Yakında"/in_stock=false projeksiyonu; sepet.
- **Bağımlılıklar:** P3 (admin auth), ADR-004 onayı, B4/B5/B6/B9 kararları, B8 içerik (nitelikler) kısmen. **Veri modeli:** catalog + pricing + media. **Migration:** yeni tablolar + seed (import aracı, migration değil). **Security:** Medium (admin yazma yolları, medya upload magic-byte, public cache'te özel veri yok).
- **Test:** unit (slugify, resolveRetailPrice, KDV hesabı kuruş), integration (import idempotent, price_history trigger, tsvector Türkçe), contract (public DTO), E2E (admin ürün oluştur → public'te görünür). **Acceptance:** REQ §117 "ürünler admin'den yönetilebiliyor / kategoriler / varyant seçimleri / kampanya fiyatı"; import dry-run onaylı; fiyat geçmişi kaydediyor; görseller WebP + srcset; Lighthouse SEO ≥95 (katalog sayfaları).
- **Rollback:** import aracı idempotent (yeniden çalıştırma güvenli); tablolar expand-only. **Risk:** Medium.

### Phase 5 — Inventory Core + admin stok + `/internal/v1/inventory` sözleşmesi
- **Amaç:** Tek yetkili stok ledger'ı canlı; rezervasyon atomik; oversell testi CI'da; public `in_stock` projeksiyonu; B2B'ye açılacak internal sözleşme tanımlı (B2B tarafı P7).
- **Kapsam:** reserve/commit/release/adjust use-case'leri; CHECK kısıtları; worker skeleton + expiry job + `SUM(movement)=on_hand` job; sebepli manuel hareket + audit (WAREHOUSE rolü); admin stok ekranı (on_hand/reserved/available, hareket geçmişi); açılış sayımı runbook (COUNT_ADJUSTMENT); public projeksiyon (kısa revalidate; checkout yine DB doğrular); `/internal/v1/inventory/{availability,reserve,commit,release}` + servis token + Idempotency-Key + OpenAPI + fake B2B istemcisiyle contract test; geçici "B2B sevkiyatı elle SALE" prosedürü (ADR-004 sunset).
- **Kapsam dışı:** B2B repo değişikliği (P7); bulk/packaging conversion.
- **Bağımlılıklar:** P4 (variant), B6 (stok birimi, rezervasyon anı). **Veri modeli:** inventory (P1'de başladı) + reservations channel. **Migration:** kısıt ekleri. **Security:** Medium (internal endpoint kimliği, IP allowlist).
- **Test:** concurrency (N paralel reserve), expiry, idempotent reserve/commit/release, tutarlılık job'u, admin unauthorized. **Acceptance:** oversell senaryosu CI'da yeşil; REQ §80-81 admin stok + sebep zorunlu + audit; §30 public davranış; internal sözleşme contract testi.
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
- **Kapsam:** `carts/cart_lines` (imzalı guest token, login merge politikası); checkout use-case (fiyat/available/kupon iskeleti/kargo ücreti+ücretsiz eşik settings'ten/yasal onay sürümleri/adres+fatura profili+billing snapshot); `orders` + `order_lines` snapshot + `idempotency_key`; state machine + transition map; `PaymentProvider` adapter (sandbox) + 3DS + `payment_events` UNIQUE; kartta kısa TTL rezervasyon commit/release; havale PAYMENT_PENDING + 24s + admin "ödeme alındı" (FINANCE) → commit; refund iskeleti (idempotent); misafir takip (rate-limit); admin sipariş ekranları (SALES/WAREHOUSE); takip no → SHIPPED + outbox bildirimi; müşteri hesabı sipariş geçmişi (temel).
- **Kapsam dışı:** kupon tam kuralları, iade akışı, favori/yorum (P8); kargo API.
- **Bağımlılıklar:** P4, P5, P6, B7 (PSP). **Veri modeli:** commerce tabloları. **Migration:** yeni tablolar + SEQUENCE. **Security:** High (ödeme, PII, yasal).
- **Test:** ARCH §80 senaryoları (duplicate webhook, oversell, transfer expiry, price change while cart open, stock zero while cart open, refund retry); E2E guest+member checkout kart sandbox + havale; mobil checkout. **Acceptance:** REQ §117 checkout/kart/havale/sipariş durumları/bildirimler/manuel kargo/misafir takip maddeleri; §118 webhook idempotency + oversell + havale timeout testleri yeşil.
- **Rollback:** ödeme sağlayıcısı feature flag; checkout "bakım modu" flag'i; siparişler kalıcı. **Risk:** High.

### Phase 7B — B2B Stok Entegrasyonu (paralel kulvar; P5 sonrası başlar; checkout'u bloklamaz, LAUNCH'I BLOKLAR)
- **Amaç:** REQ §31/§118 "stok tek kaynak" kriterini kapatmak: B2B sipariş geçişleri platform ledger'ına reserve/commit/release yazar; `products.stock` yazımı biter; geçici manuel SALE prosedürü kapanır.
- **Kapsam (platform):** servis token yönetimi + rotasyon + IP allowlist; `channel='b2b'` rezervasyon (expires NULL); contract test; `product_external_codes(system='b2b')` tam eşleme. **Kapsam (B2B repo, tek PR):** `platform-client.server.ts` + vendored spec; `order` → availability+reserve (fail-closed); `admin-order-status` sevkiyat→commit, iptal→release, geri-alış→re-reserve; `INVENTORY_PORT=off|enforce`; tenant içi atomik `order_no`; ürün id CSPRNG; `addTransaction` dönüş kontrolü; `admin-products` moq/box alanları; `admin-product-save` stock yazımı kaldırılır; `admin.tsx` stok input kaldırılır; `applySecurityHeaders` bağlanır; dokunulan dosyaların pin testleri davranış testine; off/enforce + contract testleri. **Ön koşul:** HEAD'in canlıya alınması (0003-0021 prova + uygulama) — ayrı B2B deploy projesi.
- **Kapsam dışı:** B2B ad/kategori pull (ayrı ADR); B2B outbox; B2B ölü kod temizliği; apps/b2b birleşmesi.
- **Bağımlılıklar:** P5; **B2 (barındırma/egress/servis token/deploy hattı)**; B6 (rezervasyon anı A-13). **Veri modeli:** platform yok; B2B migration YOK. **Security:** High (servis kimliği, fail-closed davranış).
- **Test:** B2B vitest (fake platform: reserve fail → sipariş yok; commit/release; idempotent tekrar; off modu = eski davranış); platform contract test; staging'de gerçek B2B→platform çağrısı. **Acceptance:** `INVENTORY_PORT=enforce` canlıda; B2B siparişi platform `available`'ı düşürüyor; `products.stock` hiçbir yerden yazılmıyor; REQ §118 "stok tek kaynak kuralı doğrulanmış" işaretli; manuel SALE prosedürü kapatıldı.
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
| **B1** | **ADR-004 onayı** (Seçenek B: platform Product identity + Inventory owner; B2B tüketici; `products` projeksiyon; `stock` dondurulur; D1 migration açılmaz; `product_external_code`; ARCH §87 yön tersine; geçici manuel SALE sunset tarihli) | P4+ (commerce) | `$action.ts:610-614, 712-727, 1086, 1119`; `0019:262-279`; seed `stock=0`; cron/KV/DO yok |
| **B2** | **B2B barındırma / deploy hattı / egress / servis token / canlı seviye**: origin erişilebilirliği (CLAUDE.md 7 Eyl); deploy config Higgsfield üretiyor; Worker sır taşımıyor; kimlik yalnız `fnf.internal` egress'ine → keyfi hosta HTTPS **NOT_FOUND**; **HEAD hiç deploy edilmemiş** (origin/main = MVP, 0001-0002); migration'ların otomatik uygulanıp uygulanmadığı çelişkili; Higgsfield'da mı kalınacak yoksa kendi Cloudflare hesabı mı (§14/11) | P7B, launch | `wrangler.jsonc:4-9,38-41,57-59`; `AGENTS.md:166-170`; `git rev-list origin/main..HEAD`=54 |
| **B3** | Platform production barındırma + Postgres sağlayıcısı + veri yerleşimi (TR/EU) + alan adı/DNS (www/admin/b2b) + e-posta gönderim domain'i (SPF/DKIM/DMARC); Supabase "Larante Kahve" projesinin uygunluğu | P6, P12 | LW D-007 "kısmen açık" |
| **B4** | **Fiyat gerçeği:** hangi liste güncel (B2B 0006 / skill 24 Ağu / Dashboard Eyl: 450/400/500, 1500/1800); `list_price` KDV dahil mi hariç mi; **perakende KDV dahil fiyat listesi hiçbir kaynakta yok**; ürün bazlı KDV oranı kaynağı (%1/%20) | P4 | DASH audit |
| **B5** | Kategori taksonomisi ve public kapsam: REQ §12 vs B2B 5'li vs eski menü; Pasta (Gastro Cake, 3. taraf) public'te var mı; "Aroma" mı "SOS" mu | P4 seed | `0008`; `katalog-veri.mjs` |
| **B6** | Varyant/stok birimi/rezervasyon (A-13): Cappadocia Light/Medium/Night ayrı ürün mü kavrum varyantı mı; stok birimi = sellable variant onayı; B2B koli dönüşümü; B2B rezervasyon anı (öneri: sipariş oluşturma, fail-closed); web TTL + havale süresi; **açılış stoğu için fiziksel sayım tarihi** | P5, P7B | hiçbir sistemde stok verisi yok |
| **B7** | Sağlayıcı seçimleri: PSP (iyzico/PayTR; 3DS, kısmi iade), e-posta, SMS, S3-compatible storage + CDN | P6, P7 | ADR-007 |
| **B8** | Tasarım/içerik girdileri: `LARANTE_DESIGN_SYSTEM.md` yok; REQ §18 kahve nitelik içerikleri yok; Kahve/Toz/Çay/Pasta ürün fotoğrafı yok (94 Aroma görseli AI üretimi, §23 gerilimi); hero kare 65-73 eksik; e-katalog PDF'de kişisel e-posta; slogan yazımı | P2 (kısmen), P4 içerik, P11, launch | LS audit |
| **B9** | Kaynak dosyaların kalıcılığı: skill Excel'leri claude.ai oturum klasöründe (22-24 Ağu) → `data/` altına kopya + kaynak/tarih notu; `musteriler.xlsx` yok | P4 import | DASH audit |
| **B10** | Doküman-kod hizalaması (IS-AKISI Kural 7): ARCH §5.4/§5.6/§87 düzeltmesi (V2.1 notu); sipariş durum sözlüğü; admin rol seti; Logo V1 kapsam dışı + "Logo'ya yazma yok" yazılı teyidi | P0 | §5 |
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
Kod yazmadan: `docs/adr/ADR-004-product-inventory-ownership-gate.md` taslağını bu audit'in kanıt satırlarıyla yazmak (karar Seçenek B; B2B tüketici; `products` projeksiyon; `stock` dondurulur; D1 migration açılmaz; `product_external_code`; B2B çağrıları senkron + Idempotency-Key + fail-closed; `INVENTORY_PORT=off|enforce`; rezervasyon B2B'de sipariş oluşturma anında; commit sevkiyat / release iptal; geçici manuel SALE sunset tarihli; ARCH §87 yön tersine; **ek not: HEAD hiç deploy edilmedi, 0003-0021 prod'a uygulanmadan P7B mümkün değil; egress izni NOT_FOUND**) + ADR-015 (Drizzle) + ADR-001 (ayrı repo + vendored contract) özetleri → HANDOFF akışıyla Codex adversarial denetimine sunmak. Aynı gün proje sahibine tek sayfalık karar listesi (B2-B6) ve Higgsfield'a 4 yazılı soru (egress, sır, migration uygulama, deploy hattı). Onay gelir gelmez ilk kod işi: `packages/db` inventory ledger şeması + gerçek Postgres'te "N eşzamanlı rezervasyon toplamı on_hand'i aşamaz" testi (kırmızı→yeşil) CI kapısına; iskeletin kalanı bunun etrafına örülür.

### B. "Kodlamadan önce mutlaka çözülmesi gereken kararlar"
1. **ADR-004 onayı** (Seçenek B) — B1.
2. **B2B barındırma/deploy/egress** — Higgsfield'da mı kalınacak, kendi Cloudflare hesabına mı geçilecek; HEAD canlıya nasıl alınacak; B2B Worker keyfi hosta HTTPS yapabilir mi; servis token nasıl saklanır — B2.
3. **Fiyat gerçeği** — güncel liste, `list_price` KDV durumu, **perakende KDV dahil fiyat listesi** (yok), ürün bazlı KDV oranı — B4.
4. **Kategori taksonomisi + public kapsam** (Pasta/Donuk/Aroma-SOS) — B5.
5. **Varyant sınırı + stok birimi + rezervasyon anı + fiziksel sayım tarihi** (A-13) — B6.
6. **Platform hosting/Postgres/domain/DNS** — B3; **PSP/e-posta/SMS/storage sağlayıcıları** — B7.
7. **Tek ORM (Drizzle) + ayrı repo + Hono** ADR'leri; **doküman düzeltmeleri** (ARCH V2.1: §5.4/§5.6/§87, durum sözlüğü, rol seti, Logo kapsamı) — B10.
8. **Skill Excel'lerinin repo'ya alınması**, `musteriler.xlsx` akıbeti — B9.
9. **Proje klasörü adı** (ASCII `larante-platform`?) ve `LARANTE_DESIGN_SYSTEM.md` sahibi/tarihi — B8.

### C. "Önerilen Phase 0"
**Phase 0 = Karar kilidi (kod yok), 1-2 hafta:**
1. Bu planın Codex adversarial denetimi → bulgular plana işlenir (HANDOFF §"Codex'in ilk görevi").
2. ADR-001/004/015/016/scaffold(Hono)/007(PSP)/008(outbox)/010(identity boundary) taslakları `docs/adr/` altında; ARCH V2.1 düzeltme notu; REQ/ARCH `docs/requirements|architecture/` altına.
3. Proje sahibi karar oturumu: B4 (fiyat listesi + KDV + perakende fiyat), B5 (taksonomi), B6 (varyant/stok birimi/rezervasyon anı/sayım tarihi), B7 (sağlayıcılar), B3 (hosting/domain).
4. Higgsfield'a yazılı sorular (B2): egress, sır/servis token, migration uygulama mekanizması, deploy hattı; paralelde "kendi Cloudflare hesabı" seçeneğinin maliyeti.
5. Canlı B2B envanteri (salt-okunur): hangi commit koşuyor, D1 hangi migration'da, `tenant_domains` dolu mu, `products.stock` gerçek değerleri, R2 içeriği → ADR-004 kanıt listesine.
6. Kaynak konsolidasyonu: skill Excel'leri + `katalog-veri.mjs` + B2B seed → `data/` (kaynak/tarih notu); 2048 PNG'ler tek kaynak; e-katalog PDF PII notu.
7. `LARANTE_DESIGN_SYSTEM.md` sahiplendirme; içerik/görsel iş kalemleri (B8) sahip + tarih.
8. Çıkış kriteri (DoD): ADR-004/001/015 onaylı; B1-B10 her biri "karar" veya "tarihli beklemede" (B2/B3 beklemede olabilir — P1-P6'yı bloklamaz, P7B/launch'ı bloklar); Phase 1 görev dosyaları (HANDOFF task standardı: TASK ID / Requirement refs / ADR refs / Goal / Scope / Out of scope / Files allowed / Data migration impact / Security impact / Acceptance / Tests / Rollback) hazır.

---

## 22. Doğrulama (bu planın kendisi nasıl test edilir)
- **Codex adversarial denetimi** (HANDOFF): yanlış varsayım/kırılma senaryosu arar; özellikle ADR-004 kanıtları, B2 egress/deploy varsayımı, faz bağımlılıkları, migration/rollback, test/acceptance.
- **Kanıt tekrarı:** her `dosya:satır` referansı repoda salt-okunur açılarak yeniden doğrulanabilir (ajan JSON'ları: `read_*.json`, `verify_*.json`, `gap_G*.json`, `arch_*.json`, `judge.json`, `critic.json` — scratchpad `audit/`).
- **Phase 0 çıkışında somut doğrulamalar:** canlı B2B commit/D1 seviyesi; Higgsfield yazılı cevapları; fiyat listesi onayı; `tools/import-catalog --dry-run` prototipi (Phase 4'te) 179 ürün/94 görsel/216 Logo kodu eşleşme raporu.
- **Phase 1 çıkışında:** CI zinciri yeşil + concurrency testi yeşil = oversell koruması ölçülmüş.

**Bu oturumda hiçbir kaynak dosya değiştirilmedi; hiçbir install/build/migration/test çalıştırılmadı.** Plan bitti — onay bekleniyor.
