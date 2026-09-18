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

## Tests
CI'nın kendisi (yeşil koşu), negatif lint / audit denemeleri, headers helper unit testleri.

## Rollback
Workflow dosyaları revert edilir; kod tabanı etkilenmez.
