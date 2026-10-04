# CLAUDE.md — Larante dokümantasyon deposu

Bu dosya bir göstergedir: kural koymaz ve ikinci bir standart değildir. Çelişkide `docs/process/DEVELOPMENT-WORKFLOW-STANDARD-v1.md` (DWS-1) ve onaylı ADR'ler (`docs/adr/`) geçerlidir.

## İş akışı standardı

- **DWS-1, sürüm 1.1** (r3, 2026-09-23): `docs/process/DEVELOPMENT-WORKFLOW-STANDARD-v1.md` — kanonik kopya; uygulama alanı DWS başlık tablosundaki "Applies to" satırındadır.
- **Larante bağlaması — DWS Annex L:** §L1 standardın kopyaları · §L2 kurulu yetenekler · §L3 yollar · §L3a reviewer-isolation preflight · §L4 uygulama deposu doğrulama tabanı · §L5 owner kalıcı kuralları · §L6 görev dosyası alanları · §L7 devir kaydı.
- **Reviewer-isolation preflight betiği:** `docs/process/reviewer-preflight.sh` (kanonik kopya; Annex L §L3a).
- **Dal / PR akışı ve belge deposu değişiklikleri:** DWS §7.1 ve §7.2.

## Bu depodaki yetkili belgeler

- `LARANTE_WEB_REQUIREMENTS.md` — ürün gereksinimleri
- `LARANTE_WEB_ALTYAPI_MIMARISI_V2.md` — mimari
- `docs/adr/` — mimari karar kayıtları (ADR)
- `docs/decisions/PHASE0_KARAR_LISTESI.md` — Phase 0 karar listesi
- `docs/plan/LARANTE_MASTER_PLAN_2026-09-15.md` — master plan
- `docs/tasks/PHASE1/` — Phase 1 görev sözleşmeleri
- `LARANTE_CODEX_HANDOFF.md` — Codex devir ve durum kaydı (iş akışı kuralları: DWS-1)
- `docs/process/` — geliştirme iş akışı standardı ve reviewer preflight betiği

Uygulama kodu ayrı `larante-platform` deposundadır; o deponun `docs/README.md` dosyası bu depoya commit SHA'sıyla gösterge verir. B2B ayrı bir depodadır.

## Bu deponun konvansiyonları

- **Belge dili:** proje belgeleri (gereksinim, mimari, ADR, karar, plan ve görev dosyaları) Türkçedir; süreç standardı (`docs/process/`) İngilizcedir. Tanımlayıcılar, komutlar, yollar ve alıntılar özgün haliyle kalır.
- **Düzenleme yetkisi:** görev dosyaları ve ADR'ler yalnız ilgili görev sözleşmesi ya da owner talimatıyla (DWS §7.2); `LARANTE_CODEX_HANDOFF.md` ve master plan yalnız owner yönlendirmeli belge işiyle (Annex L §L5) düzenlenir.
- **Karar kaydı biçimi:** her karar tarih ve durumla yazılır — ör. `KARAR <tarih>` / `ONAY <tarih>` / `KABUL <tarih>` / `tarihli beklemede <tarih>`, açık maddeler `AÇIK`; durum sütunu ☐ / ☑ (örnek: `docs/decisions/PHASE0_KARAR_LISTESI.md`). Yeni ADR'ler `docs/adr/` altındaki mevcut biçimi izler (DWS §7.2).
