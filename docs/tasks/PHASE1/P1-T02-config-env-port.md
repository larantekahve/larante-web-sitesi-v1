# P1-T02 — Config / env doğrulama / feature-flag portu

- **TASK ID:** P1-T02
- **Requirement refs:** REQ §90–§91 (yönetilebilir ayarlar — yalnız flag deseni; runtime `site_settings` Phase 3), §118 (env validation launch kriteri)
- **ADR refs:** ADR-001 (paket sınırları: `packages/config`), master plan §6 (LW `env.ts` / `site.config.ts` / `instrumentation.ts` REFACTOR-port kararı), §10 `packages/config`
- **Bağımlılıklar:** P1-T01 (çalışma alanı). P1-T04 ile paralel; CI env-validation adımı P1-T04'te bağlanır.

## Goal
Önceki Next.js denemesinin (`larante-web`, LW) framework'ten bağımsız, testli üç parçasını `packages/config`'e taşımak: Zod tabanlı env doğrulama (`env.ts`, değer sızdırmayan hata), `site.config.ts` feature-flag deseni (strictObject; varsayılan **kapalı**), `instrumentation.ts` fail-fast başlangıç kontrolü; 4 app bunları tüketir.

## Scope
- `packages/config`: `env` şeması (platform-api / worker / web / admin için ayrı şema alt kümeleri), `site.config` flag anahtar seti platform modüllerine göre yeniden tanımlanır (LW anahtarları birebir alınmaz), `instrumentation` fail-fast.
- Mevcut LW testleri (env 13, site.config 10) yeni anahtar setine uyarlanır ve `packages/config` içinde çalışır.
- `.env.example` (yalnız anahtar adları; değer yok); secret'lar source control dışı (secret policy P1-T04).
- Next / Zod / Vitest sürümleri scaffold'da yeniden doğrulanır (LW'nin TS 7.0.2 / Vitest 5.0.0 uç sürüm kilidi tekrarlanmaz — master plan §6).

## Out of scope
Runtime `site_settings` tablosu ve admin ayar ekranı (Phase 3), gerçek sağlayıcı anahtarları (B3 / B7 açık), CI (P1-T04), UI.

## Files allowed
Yalnız `larante-platform` çalışma alanı: `packages/config/**`, `apps/*/` içinde config tüketen giriş noktaları (`instrumentation`, env yükleme), kök `.env.example`. İlgili paket `package.json` bağımlılık satırları ve kök `pnpm-lock.yaml` (yalnız bu görevin eklediği bağımlılıklar; `--frozen-lockfile` CI ile tutarlı).

## Data migration impact
Yok.

## Security impact
Orta-düşük: env doğrulaması eksik / hatalı değerde **başlatmayı reddeder** ve hata mesajı değer sızdırmaz; secret'lar repoya girmez.

## Acceptance
- Eksik zorunlu env → uygulama başlamaz, hata yalnız anahtar adını söyler (değer yok).
- Feature flag'ler varsayılan kapalı; strictObject bilinmeyen anahtarı reddeder.
- `packages/config` unit testleri geçer; 4 app config'i tüketir ve typecheck geçer.
- Codex plan + kod denetimi APPROVED.

## Tests
Unit: env şeması (eksik / yanlış tip / değer sızıntısı yok), flag deseni (varsayılan kapalı, bilinmeyen anahtar), instrumentation fail-fast.

## Rollback
Paket düzeyinde revert; app'ler LW-öncesi boş iskelete döner (P1-T01).
