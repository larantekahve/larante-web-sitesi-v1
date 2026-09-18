# P1-T06 — `platform-api` (Hono + zod-openapi) ve worker iskeleti

- **TASK ID:** P1-T06
- **Requirement refs:** REQ §104 (worker / zamanlı işler — yalnız iskelet), §118 (API skeleton build, worker skeleton build), ARCH §5.4 (V2.3: Hono + zod-openapi kararı), §30 (worker aynı codebase, ayrı süreç), §60 (HTTP yüzeyi — yalnız yer tutucu), §106 (DoD "API skeleton build", "worker skeleton build")
- **ADR refs:** PHASE0 scaffold kararı (2026-09-18: Hono + zod-openapi), ADR-001 §Karar 1 / 5 (uygulama yerleşimi; `packages/adapters` yalnız `platform-api` + `worker`), master plan §10 (`apps/platform-api` modüler monolit, `src/http/{public-v1,commerce-v1,customer-v1,admin-v1,internal-v1}` ve `src/bootstrap` — bu görevde yalnız dizin iskeleti), §12 (global route guard — yer tutucu)
- **Bağımlılıklar:** P1-T01 (app iskeleti), P1-T02 (env / config tüketimi). P1-T05 ile paralel olabilir; ledger'a bağlanmaz.

## Goal
`apps/platform-api` için Hono + `@hono/zod-openapi` tabanlı, domain kodu içermeyen, derlenen ve OpenAPI belgesi üreten iskelet; `apps/worker` için aynı image / codebase içinde ayrı entrypoint iskeleti (outbox / job mantığı yok — Phase 6).

## Scope
- `apps/platform-api`: Hono uygulaması; `GET /health` (yer tutucu); zod-openapi ile OpenAPI 3 belgesi üretimi (yalnız health şeması); `src/http/*` dizinleri boş yer tutucu (`public-v1`, `commerce-v1`, `customer-v1`, `admin-v1`, `internal-v1`); `src/bootstrap` DI iskeleti (adapter kayıt noktası — adapter yok); global guard **yer tutucu** (kimlik doğrulama yok; Phase 3'te doldurulur); Node 22 runtime; `cloudflare:*` importu yasak (lint P1-T04).
- `apps/worker`: aynı codebase / image, ayrı entrypoint (`worker` process "hello" + sağlıklı kapanma); job / outbox / cron mantığı yok.
- Dockerfile'lar (`infra/`): platform-api ve worker için aynı image, farklı entrypoint (master plan §10) — sağlayıcı / deploy hedefi yok.
- OpenAPI çıktısı build artefaktı olarak üretilir; `packages/contracts` ile ilişki yalnız yer tutucu (contract test içeriği Phase 5).

## Out of scope
Domain / use-case kodu, gerçek route'lar, kimlik doğrulama / RBAC (Phase 3), inventory port'ları (Phase 5), outbox / worker işleri (Phase 6), deploy / hosting (B3 açık), B2B istemcisi (P7B).

## Files allowed
Yalnız `larante-platform`: `apps/platform-api/**`, `apps/worker/**`, `infra/Dockerfile*`, `packages/contracts/**` (yer tutucu dizin), kök script'ler. İlgili paket `package.json` bağımlılık satırları ve kök `pnpm-lock.yaml` (yalnız bu görevin eklediği bağımlılıklar; `--frozen-lockfile` CI ile tutarlı).

## Data migration impact
Yok.

## Security impact
Düşük: health ucu bilgi sızdırmaz (sürüm / ortam ayrıntısı yok); global guard yer tutucu **fail-closed** varsayılanla tasarlanır (Phase 3'te gerçek guard gelmeden hiçbir korunan route açılmaz); headers helper (P1-T04) bağlanma noktası hazır ama içerik Phase 3.

## Acceptance
- `apps/platform-api` build + typecheck geçer; `GET /health` 200; OpenAPI belgesi üretilir ve şema doğrulamasından geçer.
- `apps/worker` build + typecheck geçer; process başlar ve düzgün kapanır.
- Aynı image / iki entrypoint Dockerfile'ları build olur (yerel).
- Lint: `cloudflare:*` yok; `packages/adapters` yalnız bu iki app'ten import edilebilir (henüz adapter yok — kural aktif).
- Codex plan + kod denetimi APPROVED.

## Tests
Unit / smoke: health ucu; OpenAPI üretimi snapshot; worker entrypoint başlatma / kapanma; lint negatif testleri.

## Rollback
App iskeletleri P1-T01 "hello" haline revert edilir; başka bağımlılık yok.
