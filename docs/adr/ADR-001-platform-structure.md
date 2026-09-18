# ADR-001 — Platform Repository Yapısı: Ayrı Repo + Versiyonlu HTTP Sözleşmesi

**Durum:** ONAYLI — proje sahibi 2026-09-18 (Phase 0 onay paketi 3); Codex denetimi: 2026-09-16 doküman denetimi + 2026-09-16/17 plan ve inspect turları (`LARANTE_CODEX_HANDOFF.md`) · **Tarih:** 2026-09-15 · **Onay:** 2026-09-18
**Kaynaklar:** ARCH §2, §4, §86, §98-99, §107 G10; `docs/plan/LARANTE_MASTER_PLAN_2026-09-15.md` §9-10

## Bağlam
ARCH §4 monorepo önerir ("`apps/b2b` şimdilik zorunlu olarak taşınmaz; audit sonrası aynı monorepo / ayrı repo + API / kademeli birleşme kararı ADR ile"). Audit B2B'nin yapısını doğruladı.

## Kanıt
- B2B **Bun** workspace (`app/package.json:6-8 workspaces ['packages/*']`, `bun.lock`, `bunfig.toml`) + vendored `@higgsfield/fnf|fnf-react|quanta` (`workspace:*`); CI `oven-sh/setup-bun@v2` + `bun install --frozen-lockfile` (`.github/workflows/ci.yml`).
- Deploy config'i Higgsfield CI `app.manifest.json`'dan üretir; repo'daki `wrangler.jsonc` deploy'da yok sayılır (`wrangler.jsonc:4-9`). Origin `apps-repos.higgsfield.ai`. Tek D1/R2 preview+prod (`:57-59, :65`).
- B2B veri erişimi D1 API (`db().prepare().bind()`), `cloudflare:workers` env (`src/lib/bindings.server.ts:7`); Postgres kullanılamaz.
- Platform hedefi: pnpm + Turborepo + Next.js + Node + PostgreSQL (ARCH §5).
- Deploy hattındaki `origin/main` HEAD'in 54 commit gerisinde; deploy keşfi (repo yerleşimi değişirse Higgsfield CI'ın davranışı) doğrulanamaz.

## Karar
1. **Yeni uygulama deposu / çalışma alanı `larante-platform`** (ASCII-güvenli ad — **KARAR 2026-09-18**; Phase 1'de uygulama çalışma alanı / deposu oluşturulurken uygulanır; mevcut dokümantasyon deposu / klasörü bu kararla yeniden adlandırılmaz; dokümantasyonun bu çalışma alanına taşınması ya da referanslanması `docs/tasks/PHASE1/P1-T01` görev dosyasında tanımlanır; pnpm + Turborepo; Node 22 LTS; TS strict): `apps/{web, admin, platform-api, worker}` + `packages/{domain, application, db, adapters, identity, contracts, analytics, ui, design-tokens, config, observability, testing}` + `tools/` + `data/` + `docs/` + `infra/`. Ayrıntılı ağaç: master plan §10.
2. **B2B kendi repo'sunda kalır** (Bun + TanStack Start + Workers + D1 + R2; Higgsfield hattı; `b2b.larantecoffee.com`). Yerleşim değiştirilmez.
3. **Tek ortaklık = versiyonlu HTTP sözleşmesi:** `packages/contracts/internal.b2b-integration.v1` (zod → OpenAPI). B2B'ye **vendored** kopya (`app/src/lib/b2b/platform-contract.v1.json` + üretilmiş tipli istemci `platform-client.server.ts`, sürüm pini). İki CI'da contract test. npm/git-tag paket dağıtımı **yok** (Bun/Higgsfield CI'da doğrulanmamış).
4. **Kademeli birleşme (`apps/b2b`)** yalnız şu iki koşul birlikte sağlanırsa ayrı ADR ile yeniden açılır: B2B Higgsfield'dan kendi Cloudflare hesabına geçer **ve** P7B entegrasyonu bir çeyrek canlıda kanıtlanır. O zaman bile D1 → Postgres taşıma yok; B2B kendi wrangler deploy birimi olarak kalır.
5. Lint kuralları: platformda `cloudflare:*` importu yasak; B2B'de `pg/drizzle` yasak; `packages/domain` framework/DB/sağlayıcı importu yasak; `packages/adapters` yalnız `platform-api` + `worker` tarafından import edilir.
6. Proje klasörü adı (`LARANTE WEB SİTESİ - v1`) boşluk + Türkçe karakter içerir — **KARAR 2026-09-18 (proje sahibi):** yeni kod / uygulama deposunun kökü **`larante-platform`**'dur ve ASCII-güvenli adlandırma kullanılır; mevcut dokümantasyon deposu / klasörü bu görevde yeniden adlandırılmaz; karar Phase 1 çalışma alanı oluşturulurken uygulanır.

## Reddedilenler
- **Aynı monorepo (şimdi):** iki package manager (Bun/pnpm) veya B2B'nin pnpm'e taşınması → Higgsfield deploy'unun beklediği yapı bozulur; Turbo pipeline'ında Workers/Vite build ile Next build karışır; fayda (tek lockfile) belirsizliğe değmez.
- **`@larante/contracts` npm/git-tag paketi:** Bun workspace + Higgsfield CI'da bağımlılık çözümü doğrulanmamış; tek dosya vendoring deploy hattına bağımlılık eklemez.

## Sonuçlar
İki CI, iki sürüm zinciri; sözleşme drift'i contract test + semver (v1 dondurulur, breaking = v2) ile yönetilir. Ortak UI paketi paylaşılmaz (B2B UI inline stil, paylaşım hedefi değil).

## İlgili
ADR-004 (ownership), ADR-015 (ORM), ADR-016 (stok miktar modeli ve B2B rezervasyon sözleşmesi — `internal.b2b-integration.v1` uçlarının kaynağı), ADR-017 (deployment / sağlayıcı — **henüz yazılmadı**; B3 / B7 ile tarihli beklemede 2026-09-18, Phase 1'i bloklamaz; 2026-09-16 öncesi "ADR-016" olarak anılıyordu).
