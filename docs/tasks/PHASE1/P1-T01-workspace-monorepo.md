# P1-T01 — `larante-platform` çalışma alanı ve monorepo iskeleti

- **TASK ID:** P1-T01
- **Requirement refs:** REQ §4 (platform kapsamı), §110 (www / admin / b2b sınırı), §116–§118 (launch kabul — altyapı maddeleri)
- **ADR refs:** ADR-001 (ayrı repo + sürümlü sözleşme; §Karar 1, 5, 6 — `larante-platform`, lint sınırları), ADR-015 (tek ORM Drizzle — burada yalnız paket yerleşimi), PHASE0 §F (scaffold kararı: Hono + zod-openapi; ad kararı: `larante-platform`)
- **Bağımlılıklar:** Phase 0 kapanışı (2026-09-18). Diğer Phase 1 görevleri bu göreve bağlıdır.

## Goal
Master plan §10 hedef ağacına uygun, boş ama derlenen bir monorepo iskeleti: `larante-platform` kökü (ASCII), pnpm + Turborepo, Node 22 LTS, TypeScript strict; `apps/{web, admin, platform-api, worker}` "hello" iskeletleri ve `packages/{domain, application, db, adapters, identity, contracts, analytics, ui, design-tokens, config, observability, testing}` boş paketler; ADR-001 §Karar 5 import sınırları lint ile uygulanır.

## Scope
- Çalışma alanının `larante-platform` adıyla oluşturulması (ASCII-güvenli; mevcut dokümantasyon deposu / klasörü yeniden adlandırılmaz — PHASE0 ad kararı). Dokümantasyonun bu çalışma alanıyla ilişkisi: **mevcut belge deposu değişmez** (taşıma yok, silme yok, dosya düzenleme yok); çalışma alanı içinde `docs/README.md` belge deposuna (yol + commit) **referans** verir; salt-okunur kopya (`docs/` altına) yalnız kaynak depoyu değiştirmeden eklenebilir.
- `pnpm-workspace.yaml`, `turbo.json`, kök `package.json`, `tsconfig` tabanı (strict), `.editorconfig` / `.gitignore` (yeni çalışma alanı içinde), Node 22 LTS kilidi (`engines` / `.nvmrc` eşdeğeri).
- `apps/web` (Next.js App Router placeholder sayfa), `apps/admin` (Next.js App Router placeholder), `apps/platform-api` (Hono "hello" — ayrıntı P1-T06), `apps/worker` (entrypoint "hello" — ayrıntı P1-T06): hepsi `build` ve `typecheck` geçer.
- `packages/*` boş iskeletler (her biri `package.json` + `src/index.ts` + tsconfig); `packages/contracts` içinde `internal.b2b-integration.v1` için yer tutucu dizin (içerik yok).
- Import-boundary lint kuralları: platformda `cloudflare:*` importu yasak; `packages/domain` framework / DB / sağlayıcı importu yasak; `packages/adapters` yalnız `platform-api` + `worker` tarafından import edilir; `apps/web` ve `apps/admin` sağlayıcı SDK'sı import etmez (ADR-001 §Karar 5, master plan §10).
- Sürüm pinleri: master plan §18 P1 Kapsam'a göre security-patched exact sürümler (Next 16.3.x, typescript-eslint uyumlu TypeScript, stabil Vitest, Node 22 LTS); kesin sürümler bu görevin Claude planında kaydedilir ve Codex plan denetiminde doğrulanır (bu belge sürüm icat etmez).

## Out of scope
Domain kodu, UI, veritabanı şeması (P1-T03 / P1-T05), CI (P1-T04), config / env portu (P1-T02), Hono / worker iskelet ayrıntısı (P1-T06), B2B repo değişikliği, sağlayıcı / deploy yapılandırması (B3 / B7 açık), mevcut belge deposunun yeniden adlandırılması ya da herhangi bir dosyasının değiştirilmesi / taşınması.

## Files allowed
Yalnız yeni `larante-platform` çalışma alanı: kök yapılandırma dosyaları, `apps/*`, `packages/*`, `tools/` (boş), `data/` (boş), `infra/` (boş), `docs/` (yalnız referans / salt-okunur kopya). **Bu belge deposunda hiçbir dosya değişikliği yok** (HANDOFF dahil; HANDOFF / master plan bakımı görev dosyalarının dışında ayrı belge işi olarak yürütülür).

## Data migration impact
Yok.

## Security impact
Düşük: secret policy (env dosyaları commit edilmez; `.env.example` yalnız anahtar adları), bağımlılık sürüm kilidi, `bun`/`pnpm` lockfile frozen.

## Acceptance
- `pnpm install --frozen-lockfile` temiz; `pnpm -r build` ve `pnpm -r typecheck` 4 app + tüm paketler için geçer (TS strict).
- Import-boundary lint çalışır ve ihlali kırmızıya çevirir (en az bir negatif test: `cloudflare:*` importu → lint hatası).
- Ağaç master plan §10 ile birebir; ADR-001 §Karar 5 kuralları lint konfigürasyonunda mevcut.
- Belge deposuna referans mevcut; kaynak belge deposu değişmemiş (belge deposunda `git status` temiz).
- Codex plan denetimi APPROVED; kod denetimi APPROVED (HANDOFF akışı).

## Tests
- Build / typecheck (4 app + paketler).
- Lint negatif testleri (yasak import örnekleri).
- Smoke: her app "hello" çıktısı (web / admin placeholder render; api / worker process başlar).

## Rollback
Çalışma alanı yeniden oluşturulabilir; belge deposu etkilenmez. Sonraki görevler bu iskelete bağımlı olduğundan geri alma = görev PR'ının reverti.
