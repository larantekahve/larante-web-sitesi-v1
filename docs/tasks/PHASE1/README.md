# Phase 1 — Foundation görev dosyaları (yalnız belge; uygulama içermez)

**Tarih:** 2026-09-18 · **Kaynak / yetkili plan:** `docs/plan/LARANTE_MASTER_PLAN_2026-09-15.md` §18 "Phase 1 — Foundation" (Amaç, Kapsam, Kapsam dışı, Bağımlılıklar, Test, Acceptance, Rollback) · **Görev standardı:** master plan §21.C-8 (TASK ID / Requirement refs / ADR refs / Goal / Scope / Out of scope / Files allowed / Data migration impact / Security impact / Acceptance / Tests / Rollback) · **İş akışı:** `LARANTE_CODEX_HANDOFF.md` (Claude plan → Codex plan denetimi → onaylı plan → Claude uygulama + testler → Codex kod / test denetimi → düzeltme → Codex final).

## Giriş koşulu (sağlandı — 2026-09-18)
Phase 0 kapandı (`docs/decisions/PHASE0_KARAR_LISTESI.md` §D / §F): ADR-001, ADR-004, ADR-015, ADR-016 onaylı; `platform-api` scaffold'u **Hono + zod-openapi** ve uygulama deposu kökü **`larante-platform`** karar; Phase 1 ledger kapısı sağlandı (ADR-016 onaylı, B6b / B6c karar, B6e birim sınıfları karar — varyant başına SKU verisi P4 / P7B veri hazırlığıdır ve Phase 1'i bloklamaz). Sağlayıcı / deployment seçimleri (B3, B7, ADR-017 — henüz yazılmadı), Higgsfield cevapları (B2), fiyat listesi (B4a–c) ve diğer sonraki faz kalemleri **Phase 1 koşulu değildir**.

## Görevler ve sıra
| ID | Görev | Bağımlılık | Not |
|---|---|---|---|
| [P1-T01](P1-T01-workspace-monorepo.md) | `larante-platform` çalışma alanı + pnpm / Turborepo monorepo iskeleti (4 app + packages) | — | ilk görev |
| [P1-T02](P1-T02-config-env-port.md) | Config / env doğrulama / feature-flag portu (LW `env.ts`, `site.config.ts`, `instrumentation.ts`) | T01 | T03 / T04 ile paralel |
| [P1-T03](P1-T03-local-infra-db-tooling.md) | docker-compose Postgres + MinIO; Drizzle + drizzle-kit migrate runner; `packages/db` / `packages/testing` iskeleti | T01 | T02 / T04 ile paralel |
| [P1-T04](P1-T04-ci-security-baseline.md) | CI zinciri + import-boundary lint + güvenlik taban çizgisi | T01 (T02 / T03 çıktıları CI'a bağlanır) | push tetiği ilk PR'da doğrulanır |
| [P1-T05](P1-T05-inventory-ledger-concurrency.md) | **İlk kod:** ADR-016 K2 envanter ledger şeması + gerçek Postgres'te concurrency testi (kırmızı → yeşil) | T03, T04 | Phase 1'in ölçülen çıktısı |
| [P1-T06](P1-T06-platform-api-worker-skeleton.md) | Hono + zod-openapi `platform-api` iskeleti + worker iskeleti (domain kodu yok) | T01, T02 | T05 ile paralel olabilir |
| [P1-T07](P1-T07-docs-consolidation.md) | **Belge görevi (bu depo):** B10 kalanı — ARCH V2 gövdesine V2.1–V2.3 notlarının editoryal konsolidasyonu | — (paralel) | kod deposuna dokunmaz |

Kapsam dışı (master plan §18 P1): UI, domain use-case'leri, B2B repo değişikliği, sağlayıcı seçimleri, deployment. B10-(a) B2B tarafı belge senkronu Phase 1 dışıdır (P7B B2B PR'ı).

## Çıkış listesi (Phase 1 kapanışı)
1. ARCH §106 altyapı maddeleri: pnpm/Turbo kurulu; `apps/web`, `apps/admin`, API skeleton, worker skeleton build; TS strict; lint; unit test runner; Playwright smoke; CI yeşil; env validation; security baseline (T01–T04, T06).
2. **Ledger concurrency testi CI'da yeşil** — "N eşzamanlı rezervasyon toplamı `on_hand`'i aşamaz" (T05; master plan §22 Phase 1 çıkışı).
3. **P1-T07 tamamlanma kaydı** (PHASE0 B10 satırı güncellenmiş; Codex belge inspect'i APPROVED).
4. Her görev HANDOFF akışından geçmiş: Codex plan denetimi APPROVED + kod / test denetimi APPROVED; "AI-üretimi kod testsiz merge edilmez" (G13).
5. Phase 1 kapanış kaydı **görev dosyalarının dışında, ayrı belge işi olarak** master plan §18 P1 Acceptance altına ve `LARANTE_CODEX_HANDOFF.md` durum bölümüne işlenir (T01–T07 belge deposunda HANDOFF / master plan düzenlemez).

## Genel kurallar (tüm görevler)
- Sürüm pinleri: master plan §18 P1 Kapsam metnine göre (Next 16.3.x, typescript-eslint uyumlu TS, stabil Vitest, Node 22 LTS; security-patched exact sürümler) — bu dosyalar sürüm numarası icat etmez; kesin pinler T01 planında kaydedilir ve Codex denetiminden geçer.
- Platformda `cloudflare:*` importu yasak; B2B'de `pg` / `drizzle` yasak; `packages/domain` framework / DB / sağlayıcı importu yasak; `packages/adapters` yalnız `platform-api` + `worker` tarafından import edilir (ADR-001 §Karar 5).
- Para `INTEGER` kuruş; miktarlar tamsayı; `REAL` / float yasak (ADR-015 §6, ADR-016 K1–K2).
- Sağlayıcı SDK'sı, hosting, DNS, e-posta / SMS / PSP entegrasyonu Phase 1'de yoktur (B3 / B7 açık).
