# P1-T04 — CI zinciri, import-boundary lint ve güvenlik taban çizgisi

- **TASK ID:** P1-T04
- **Requirement refs:** REQ §118 (production build / TS strict / lint / unit-integration / E2E / dependency scan launch kriterleri), §92 (güvenlik olayları — yalnız taban çizgisi), ARCH §67 (security headers), §79–§80 (test piramidi, CI kapıları), §106 (DoD)
- **ADR refs:** ADR-001 §Karar 5 (lint sınırları), ADR-015 §Karar 4 (ORM yasak-listesi), master plan §15 (CI kapıları), §16 (security baseline: headers helper, secret policy)
- **Bağımlılıklar:** P1-T01; P1-T02 (env validation adımı) ve P1-T03 (Postgres servisli integration adımı) çıktıları CI'a bağlanır.

## Goal
Her PR'da çalışan, master plan §15'teki kapıların tamamını içeren CI zinciri ve güvenlik taban çizgisi; push tetiği ilk PR'da fiilen doğrulanır (B2B'deki "ölü tetik" tekrarlanmaz — master plan §2.1/24).

## Scope
- CI iş akışı: `pnpm install --frozen-lockfile` · lint (import-boundary; `cloudflare:*` yasak; domain → framework yasak; **ORM yasak-listesi — Prisma / TypeORM / Kysely, ADR-015 §Karar 4; kural konfigürasyonu ve negatif testi bu görevde**) · typecheck strict · unit · integration (Postgres servis, P1-T03 yardımcıları) · build (4 app) · Playwright smoke (web / admin placeholder) · contract test iskeleti (`packages/contracts` — içerik yok, kapı hazır) · migration check (up + idempotent yeniden çalıştırma) · dependency scan · env validation (P1-T02).
- Node sürümü CI'da sabit (Node 22 LTS); cache stratejisi (pnpm store / turbo cache).
- Güvenlik taban çizgisi: security headers helper (`packages/observability` ya da `packages/config` — nonce CSP / HSTS / frame-ancestors / nosniff / Referrer-Policy / Permissions-Policy şablonu; app'lere bağlanması Phase 3), secret policy (env commit yasağı, CI izinleri en az yetki, lockfile frozen), `bun audit` eşdeğeri `pnpm audit` kritik eşik.
- Branch koruması / gerekli kontroller listesi belgelenir (uygulanması repo yönetimidir; bu görev PR yaratmaz).

## Out of scope
Deploy / staging / prod pipeline'ı (B3 / ADR-017 açık), Lighthouse / axe (Phase 2+), contract test içeriği (Phase 5), gerçek E2E akışları (Phase 4+), B2B CI (F15 — P7B).

## Files allowed
Yalnız `larante-platform`: `.github/workflows/**`, kök lint / test / script yapılandırmaları, `packages/observability/**` (headers helper), `packages/testing/**` (CI yardımcıları), `turbo.json` pipeline adımları. İlgili paket `package.json` bağımlılık satırları ve kök `pnpm-lock.yaml` (yalnız bu görevin eklediği bağımlılıklar; `--frozen-lockfile` CI ile tutarlı).

## Data migration impact
Yok (migration check yalnız P1-T03 çerçevesini çalıştırır).

## Security impact
Orta: CI izinleri (en az yetki, secret'suz PR koşuları), dependency scan eşiği, headers helper içerik güvenliği şablonu; gerçek sağlayıcı sırrı yok.

## Acceptance
- İlk PR'da CI tetiklenir ve tüm adımlar yeşil (push tetiği fiilen doğrulanmış).
- Her kapı ayrı adım olarak görünür ve tek bir başarısızlık PR'ı kırmızıya çevirir (negatif kanıt: kasıtlı lint ihlali içeren deneme PR'ı ya da yerel `act` eşdeğeri).
- Migration check idempotency'yi kanıtlar; integration adımı gerçek Postgres'e bağlanır.
- Security baseline belgesi + headers helper testleri mevcut; `pnpm audit` kritik seviyede kırar.
- Codex plan + kod denetimi APPROVED.

### Carry-in kabul maddeleri (owner onayı, 2026-09-23)
Kaynaklar: DWS-1 1.1 Annex L §L7 (H1–H3; carry-in kuralı: bu maddeleri atlayan bir P1-T04 planı S5'te REVISE'dır); P1-T02 checkpoint + review log (F1, SA2, SA8); P1-T03 final checkpoint + plan §13 + review log ((a)–(g), R24, R27, T12, gözlemler). Aşağıdaki maddeler de bu görevin kabul maddeleridir; Scope / Out of scope / Files allowed'ı genişletmezler.

**DWS L7 (zorunlu)**
- **H1 — cache bütünlüğü (= P1-T01 R17):** güvenlikle ilgili test çalıştırmaları, Git index dosya modları ya da güvenlikle ilgili başka bir repo metadata'sı değiştiğinde sahte cache isabeti (false cache hit) üretmez.
- **H2 — CI floor guard (DWS §6.7):** diff kapsamlı bir guard (referans: `agent-skills` `constraint-driven-development/references/floor-guard.md`; Node; yeni harici araç yok) her PR'da CI'da çalışır ve beş "çıtayı düşüren hamle"yi bloklar; exit 2 (çalışamadı) hiçbir zaman temiz sayılmaz; B18 host incelemesi yalnız bu kapı yeşil olduğunda emekliye ayrılır.
- **H3 — `CONSTRAINTS.md` ve harici güvenlik tarayıcıları:** repo kökünde bir `CONSTRAINTS.md` ve harici tarayıcılar (`gitleaks`, `osv-scanner`, `semgrep`) hakkında kayıtlı owner kararı; owner onayı olmadan hiçbir araç kurulmaz (aşağıda "Owner onayı bekleyen kararlar" 1).

**P1-T02'den**
- **F1 — turbo test girdisi bütünlüğü (`cache-input-integrity`, medium, sınıf C, H1 sınıfı):** `@larante/config#test` (ve kökteki bir dosyayı okuyan her test) `inputs: ["$TURBO_DEFAULT$", "$TURBO_ROOT$/.env.example"]` bildirir ya da `.env.example` `globalDependencies`'e girer; `.env.example` değiştiğinde `turbo run test` önbellekten PASS tekrar oynatmaz. Bu sağlanana kadar CI env-validation adımı `corepack pnpm --filter @larante/config test`'i doğrudan ya da `--force` ile çalıştırır.
- **SA2 — build / instrumentation negatif smoke (`entrypoint-presence-guard`):** `next build` sonrasında `apps/{web,admin}/.next/server/instrumentation.js`'in var olduğu ve chunk'ının `loadEnvOrExit` içerdiği CI'da doğrulanır; otomatik `next start` negatif smoke: eksik env anahtarı → exit 1, hiçbir 200 yanıtı yok. `apps/*` içinde unit test eklemek bu görevin Files allowed'ı dışındadır (owner genişletmesi gerektirir).
- **SA8 — `.env.example` yorum satırları:** mevcut test `.env.example`'daki yorum satırlarını kısıtlamaz (`# SECRET=abc` geçer); secret politikası bu durumu ele alır (P1-T02 kaydı: o zamana kadar her görevde B17 host incelemesi kapsar).

**P1-T03'ten**
- **(a) CI integration adımı:** Postgres servis container'ı + `LARANTE_TEST_DATABASE_URL` + `corepack pnpm run test:integration`.
- **(b) Migration check:** temiz bir veritabanında `db:migrate` iki kez; ikinci çalıştırma uygulanmış migration'ı atlar (idempotent).
- **(c) ORM yasak listesi:** Prisma / TypeORM / Kysely lint kuralı + negatif testi (ADR-015 §Karar 4; Scope'taki maddeyle aynı).
- **(d) Dependency-scan eşiği ve GHSA-67mh-4wv8-2f99:** eşik kararı (Scope: `pnpm audit` kritik eşik) planda açıkça kaydedilir ve GHSA-67mh-4wv8-2f99'u kapsar — moderate; yol `drizzle-kit > @esbuild-kit/esm-loader > @esbuild-kit/core-utils > esbuild 0.18.20`; P1-T03'te erişilebilirlik triajıyla residual olarak kaydedildi, suppress edilmedi (audit-ignore yapılandırması yok); gözden geçirme tetikleyicisi: sonraki drizzle-kit sürümü ve bu görevin dependency-scan kapı tanımı. Bir ignore / istisna yalnız owner + son tarih taşıyan kayıtlı bir istisna olarak eklenebilir (DWS §5.2, §6.7).
- **(e) `.github/workflows` guard kabulü:** CI `.github/workflows/*.yml` eklediğinde tracked-tree guard'a bu dosyalar için kendi tam (exact) kabul satırı eklenir; guard bugün `.github/workflows/ci.yml`'i reddeder.
- **(f) `@larante/testing` kullanım kısıtı (P1-T03 doubt review D5):** `@larante/testing` artık `@larante/db` ve `pg`'ye bağlıdır; lint politikası `packages/domain`'in db / adapters dışındaki her `@larante/*` paketini import etmesine izin verir ve manifest guard yalnız bu ikisini yasaklar → `@larante/testing` test dosyaları dışında (ve devDependencies dışında) yasaklanır (lint politikası + manifest guard); domain kodu PostgreSQL'e bu paket üzerinden ulaşamaz.
- **(g) ESM relative import uzantı kısıtı (D6):** ESM relative import'lar yalnız kaynak ve JSON uzantılarıyla sınırlanır (Vitest bilinmeyen uzantıları JavaScript olarak çalıştırır; lint bugün uzantıyı yalnız CommonJS yüklemelerinde denetler).
- **R24 — migration SQL politika tarayıcısı:** migration SQL'inde `BEGIN` / `COMMIT`, `pg_advisory_unlock*`, `COPY … PROGRAM` ve `CREATE INDEX CONCURRENTLY` yakalanır (bugün yalnız `packages/db/README.md` manuel inceleme listesinde).
- **R27 — manifest / sürüm pin guard'ı:** manifest guard'ın genel sürüm spec'i kuralı sıkılaştırılır (P1-T03 `pins.test.ts` yalnız o görevin dört pin'ini doğrular: exact; `pg` / `@types/pg` iki manifest'te özdeş).
- **T12 — `--frozen-lockfile` ve script öncesi lockfile bütünlüğü:** CI `--frozen-lockfile` ile kurar ve herhangi bir script çalışmadan önce lockfile / `node_modules` sapmasında kırılır (P1-T03 gözlemi: `pnpm-workspace.yaml`'a `overrides:` eklenince `corepack pnpm test` önce yeniden çözümleyip kurdu).
- **Gözlem — boundary-suite cold-run timeout:** temiz kurulumdan sonraki ilk koşuda bir kez görülen boundary-suite (B6) timeout'u (46 sn vs 2.5 sn; tekrarlanamadı) P1-T04 CI koşularında izlenir; sonuç görev kayıtlarında raporlanır.
- **Gözlem — vite opsiyonel peer çözümlemesi:** vite 8.3.0'ın opsiyonel peer'ları (drizzle-kit ağacı üzerinden) `esbuild@0.28.2` ve `tsx@4.23.15`'e çözülür (hiçbir yapılandırma kullanmaz; 0.28.2 yamalı sürümdür); dependency / security scan kapsamında izlenir.
- **Owner / tasarım kararı — dört exact pin'in `catalog:`'a taşınması:** aşağıda "Owner onayı bekleyen kararlar" 3.

### Owner onayı bekleyen kararlar (bu sözleşme karar vermez)
Aşağıdakiler bu görev dosyasında karara bağlanmamıştır; plan bunları önerebilir, ancak owner onayı olmadan hiçbiri seçilmez ya da uygulanmaz (DWS §1 "No new software", §9.1):
1. **Harici güvenlik tarayıcılarının kurulması / kullanılması** (`gitleaks`, `osv-scanner`, `semgrep` ve benzerleri) ve repo kökünde `CONSTRAINTS.md` (H3).
2. **Negatif CI kanıtının yöntemi:** yukarıdaki "kasıtlı lint ihlali içeren deneme PR'ı ya da yerel `act` eşdeğeri" — `act` kurulu değildir (yeni yazılım) ve görevin kendi draft PR'ı dışındaki bir deneme PR'ı dışarıya dönük bir işlemdir; ikisi de ayrı owner onayı gerektirir.
3. **Dört exact pin'in `catalog:`'a taşınması:** `drizzle-orm` 0.45.3, `drizzle-kit` 0.31.11, `pg` 8.23.0, `@types/pg` 8.23.1 (P1-T03 R7; bugün manifest'lerde exact). Taşınıp taşınmayacağı owner / tasarım kararıdır; bu görev kendiliğinden taşımaz.

### Kapsam notu
Scope, Out of scope, Files allowed, Data migration impact ve Security impact bu eklemeyle değişmez. Kök guard testlerine (boundary suite, `corepack pnpm test`) dokunan carry-in'ler ((e), (f), R27) ve H2 floor guard script'i "kök lint / test / script yapılandırmaları" okumasına dayanır; bu okuma DWS Annex L §L6 gereği plan §3'te ve Intake Record'da açıkça yazılır; plan reviewer ya da owner farklı okursa bu bir owner sorusudur (DWS §9.1).

## Tests
CI'nın kendisi (yeşil koşu), negatif lint / audit denemeleri, headers helper unit testleri.

## Rollback
Workflow dosyaları revert edilir; kod tabanı etkilenmez.
