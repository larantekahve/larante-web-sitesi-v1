# P1-T03 — Yerel altyapı (Postgres + MinIO) ve veritabanı araç zinciri (Drizzle)

- **TASK ID:** P1-T03
- **Requirement refs:** REQ §31 (tek stok kaynağı — ledger'ın barınacağı DB), §118 (migration / integration test kriterleri)
- **ADR refs:** ADR-015 (PostgreSQL + tek ORM Drizzle; migration'lar drizzle-kit ile üretilir, elle gözden geçirilir, forward-only, expand → migrate → contract; yarış-kritik SQL yalnız `packages/db` repository / migration sınırında), ADR-016 §6 Phase 1 (ledger şeması bu ADR'nin K2 şemasıyla — P1-T05), master plan §11, §17
- **Bağımlılıklar:** P1-T01. P1-T05 bu göreve bağlıdır.

## Goal
Geliştirme ve CI için tekrarlanabilir yerel altyapı ve DB araç zinciri: `infra/docker-compose` (PostgreSQL 16/17 + MinIO), `packages/db` (Drizzle şema kökü + migrate runner + repository katmanı iskeleti), `packages/testing` (gerçek Postgres ile integration testi yardımcıları: test container / şema sıfırlama / fixture).

## Scope
- `infra/docker-compose.yml`: Postgres (yalnız düz Postgres özellikleri — sağlayıcıya özgü RLS / edge / auth yok, ADR-015 §Karar 1), MinIO (S3-uyumlu yerel nesne depolama; sağlayıcı seçimi değildir — B3 / B7 açık).
- `packages/db`: `drizzle-orm` + `drizzle-kit` kurulumu; `migrations/` (drizzle-kit ile üretilen, **elle gözden geçirilmiş**, düz SQL, forward-only); migrate runner (uygulanan migration'ı ikinci çalıştırmada atlar — master plan §15); `sql` şablonuyla açık SQL yalnız repository implementasyonlarında (ADR-015 §Karar 3).
- `packages/testing`: gerçek Postgres test container / bağlantı yardımcıları, şema up + idempotent yeniden çalıştırma testi altyapısı, concurrency harness iskeleti (P1-T05 kullanır).
- Migration politikası belgesi (README): forward-only, destructive değişiklik iki aşamalı, AI-üretimi migration doğrudan prod'a uygulanmaz, prod öncesi backup (master plan §17) — **prod ortamı bu görevde yoktur**.
- ORM yasak-listesi politikası (platformda Prisma / TypeORM / Kysely yasak — ADR-015 §Karar 4) README'de yazılır; **lint kuralının konfigürasyonu ve negatif testi P1-T04'tedir** (kök lint yapılandırması bu görevin dosya listesinde değildir).

## Out of scope
Ledger şeması ve concurrency testi (P1-T05), domain tabloları, sağlayıcı / hosting seçimi ve prod Postgres (B3, ADR-017 açık), B2B D1 (dokunulmaz), seed / import araçları (Phase 4).

## Files allowed
Yalnız `larante-platform`: `infra/**`, `packages/db/**`, `packages/testing/**`, kök script'ler (`package.json` scripts), CI bağlantısı P1-T04'te. İlgili paket `package.json` bağımlılık satırları ve kök `pnpm-lock.yaml` (yalnız bu görevin eklediği bağımlılıklar; `--frozen-lockfile` CI ile tutarlı).

## Data migration impact
İlk (boş / altyapı) migration çerçevesi; iş verisi yok.

## Security impact
Düşük: yerel kimlik bilgileri yalnız docker-compose / `.env.example` içinde; gerçek secret yok; migration review kuralı.

## Acceptance
- `docker compose up` ile Postgres + MinIO ayağa kalkar; `packages/db` migrate runner boş / ilk migration'ı uygular ve ikinci çalıştırmada atlar (idempotent).
- `packages/testing` ile gerçek Postgres'e bağlanan örnek integration testi CI'da geçer (P1-T04).
- ORM yasak-listesi politikası ve `drizzle-kit` üretimi + elle review süreci README'de (lint kuralı P1-T04 kabulünde).
- Codex plan + kod denetimi APPROVED.

## Tests
Integration: migrate up + tekrar çalıştırma (idempotent); bağlantı / şema sıfırlama yardımcıları (yasak ORM importu lint negatif testi P1-T04'te).

## Rollback
Compose ve paketler kaldırılabilir; migration'lar forward-only olduğundan geri alma = expand/contract politikasıyla yeni migration (bu fazda iş verisi olmadığı için pratikte revert).
