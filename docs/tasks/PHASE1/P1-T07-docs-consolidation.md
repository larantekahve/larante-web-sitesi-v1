# P1-T07 — Belge görevi: ARCH V2 gövdesine V2.1–V2.3 notlarının konsolidasyonu (B10 kalanı — b)

- **TASK ID:** P1-T07
- **Requirement refs:** — (gereksinim değişikliği yok; yalnız belge tutarlılığı). Bağlam: `docs/decisions/PHASE0_KARAR_LISTESI.md` B10 satırı (tarihli beklemede 2026-09-18, kalan (b)); ARCH §0 / §0a / §0b revizyon notları.
- **ADR refs:** ADR-001, ADR-004, ADR-015, ADR-016 (hepsi ONAYLI 2026-09-18) — bu görev hiçbir ADR'yi ve hiçbir mimari kuralı **değiştirmez**; yalnız ARCH gövde metnini onaylı ADR'ler ve V2.1–V2.3 notlarıyla tutarlı hale getirir.
- **Bağımlılıklar:** yok (Phase 1 kod görevleriyle paralel). **Phase 1 çıkış listesi kalemi** (`README.md` madde 3): tamamlanma kaydı olmadan Phase 1 kapanmaz.
- **Sahip:** dokümantasyon (Claude host editör + Codex GPT-6 Astra belge inspect'i).

## Goal
`LARANTE_WEB_ALTYAPI_MIMARISI_V2.md` gövdesinde V2.1 (2026-09-16), V2.2 (2026-09-17) ve V2.3 (2026-09-18) notlarıyla "geçersiz / düzeltildi / kilitlendi" olarak işaretlenen bölümlerin (en az §5.4, §5.6, §13, §16–§17, §18, §20–§22, §25–§26, §30, §62, §64, §87, §90, §97, §100–§101, §106) gövde metnine editoryal olarak işlenmesi, böylece not ile gövde arasında çelişki kalmaması; B10 satırının (b) kalemi kapatılır.

## Scope
- Her notlu bölümde: geçersiz V2.0 cümlelerinin kaldırılması ya da açıkça "tarihçe" olarak işaretlenmesi; geçerli kuralın gövdeye taşınması; §0 / §0a / §0b notlarının **korunması** (revizyon tarihçesi olarak) ve sonuna "gövdeye işlendi (P1-T07, tarih)" satırının eklenmesi.
- Sürüm satırı: V2.4 (konsolidasyon) — yeni kural yok.
- PHASE0 B10 satırına tamamlanma kaydı (tarih + Codex inspect artifact adı). HANDOFF bakımı bu görevin dışındadır (ayrı belge işi).
- Konsolidasyon, ADR metinlerine ve `docs/plan` / REQ'e dokunmaz (çelişki bulunursa **görev durur ve raporlar** — yeni karar icat edilmez).

## Out of scope
B10-(a) B2B tarafı belgelerinin (`CLAUDE.md` / `IS-AKISI.md`) senkronu — P7B B2B PR'ı; §5.4 / §5.6 dışında kural değişikliği; ADR düzenlemesi; kod deposu.

## Files allowed
Yalnız **bu dokümantasyon deposunda**: `LARANTE_WEB_ALTYAPI_MIMARISI_V2.md`, `docs/decisions/PHASE0_KARAR_LISTESI.md` (yalnız B10 satırı tamamlanma kaydı). Başka dosya yok (HANDOFF dahil); `larante-platform` kod çalışma alanına dokunulmaz.

## Data migration impact
Yok.

## Security impact
Yok (belge).

## Acceptance
- ARCH gövdesi ile V2.1–V2.3 notları arasında çelişki kalmaz (Codex belge inspect'i APPROVED; kontrol listesi: her notlu bölüm için "gövde = not" işareti).
- Hiçbir ADR kuralı, karar durumu ya da açık madde değişmemiştir (diff yalnız ARCH gövde metni + B10 kaydı).
- B10 satırı: (b) kapandı; (a) P7B'de kalır (yanlışlıkla tamam işaretlenmez).

## Tests
Belge tutarlılık kontrolleri: notlu bölüm listesi ↔ gövde diff'i; `grep` ile "geçersiz / Henüz kilitlenmez / onay bekliyor" kalıntısı yok; Markdown tablo bütünlüğü; Codex inspect.

## Rollback
Belge PR'ı revert; V2.x notları zaten kuralı taşıdığı için içerik kaybı yok.
