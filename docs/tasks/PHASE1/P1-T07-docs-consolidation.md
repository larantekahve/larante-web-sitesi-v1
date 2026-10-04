# P1-T07 — Belge görevi: ARCH V2 gövdesine V2.1–V2.3 notlarının konsolidasyonu (B10 kalanı — b) ve DWS §L7 H4 (`CLAUDE.md` + belge göstergesi)

- **TASK ID:** P1-T07
- **Requirement refs:** — (gereksinim değişikliği yok; yalnız belge tutarlılığı). Bağlam: `docs/decisions/PHASE0_KARAR_LISTESI.md` B10 satırı (tarihli beklemede 2026-09-18, kalan (b)); ARCH §0 / §0a / §0b revizyon notları; `docs/process/DEVELOPMENT-WORKFLOW-STANDARD-v1.md` (DWS-1 1.1) Annex L §L7 H4.
- **ADR refs:** ADR-001, ADR-004, ADR-015, ADR-016 (hepsi ONAYLI 2026-09-18) — bu görev hiçbir ADR'yi ve hiçbir mimari kuralı **değiştirmez**; yalnız ARCH gövde metnini onaylı ADR'ler ve V2.1–V2.3 notlarıyla tutarlı hale getirir.
- **Bağımlılıklar:** yok (Phase 1 kod görevleriyle paralel). **Phase 1 çıkış listesi kalemi** (`README.md` madde 3): tamamlanma kaydı olmadan Phase 1 kapanmaz.
- **Sahip:** dokümantasyon (Claude host editör + Codex GPT-6 Astra belge inspect'i); H4'ün `larante-platform` kısmı için DWS'nin gerektirdiği Codex plan ve kod / test denetimi.
- **H4 carry-in (owner onayı, 2026-10-04):** DWS-1 1.1 Annex L §L7 H4 bu sözleşmeye eklendi (carry-in kuralı: H4'ü atlayan bir P1-T07 planı S5'te REVISE'dır). Bu ekleme ARCH konsolidasyonunun (B10-b) kapsamını değiştirmez.

## Goal
`LARANTE_WEB_ALTYAPI_MIMARISI_V2.md` gövdesinde V2.1 (2026-09-16), V2.2 (2026-09-17) ve V2.3 (2026-09-18) notlarıyla "geçersiz / düzeltildi / kilitlendi" olarak işaretlenen bölümlerin (en az §5.4, §5.6, §13, §16–§17, §18, §20–§22, §25–§26, §30, §62, §64, §87, §90, §97, §100–§101, §106) gövde metnine editoryal olarak işlenmesi, böylece not ile gövde arasında çelişki kalmaması; B10 satırının (b) kalemi kapatılır. Ayrıca DWS §L7 H4 teslim edilir: bu dokümantasyon deposunda ve `larante-platform`'da tek bir proje düzeyi `CLAUDE.md` ile `larante-platform/docs/README.md` belge göstergesinin güncellenmesi.

## Scope
- Her notlu bölümde: geçersiz V2.0 cümlelerinin kaldırılması ya da açıkça "tarihçe" olarak işaretlenmesi; geçerli kuralın gövdeye taşınması; §0 / §0a / §0b notlarının **korunması** (revizyon tarihçesi olarak) ve sonuna "gövdeye işlendi (P1-T07, tarih)" satırının eklenmesi.
- Sürüm satırı: V2.4 (konsolidasyon) — yeni kural yok.
- PHASE0 B10 satırına tamamlanma kaydı (tarih + Codex inspect artifact adı). HANDOFF bakımı bu görevin dışındadır (ayrı belge işi).
- Konsolidasyon, ADR metinlerine ve `docs/plan` / REQ'e dokunmaz (çelişki bulunursa **görev durur ve raporlar** — yeni karar icat edilmez).
- **H4 — proje düzeyi `CLAUDE.md` (her depoda tek):**
  - Bu dokümantasyon deposunun kökünde `CLAUDE.md` (yeni): DWS göstergesi (kanonik yol `docs/process/DEVELOPMENT-WORKFLOW-STANDARD-v1.md` ve sürümü), bu depoyu bağlayan Annex L bölümlerine göstergeler ve bu deponun konvansiyonları (belge dili; görev dosyası / ADR / HANDOFF / master plan yalnız sözleşme ya da owner talimatıyla düzenlenir; karar kaydı biçimi).
  - `larante-platform` kökünde `CLAUDE.md` (yeni): belge göstergesi (`docs/README.md`), DWS ve Annex L göstergeleri ve bu deponun konvansiyonları — onaylı kaynaklara (ADR-001 §Karar 5 import sınırları; ADR-015 / ADR-016 tamsayı para ve miktar; DWS Annex L §L4 / §L5) gösterge olarak.
  - İki dosya da normatif DWS metnini çoğaltmaz ve ikinci bir standart oluşturmaz; çelişkide DWS ve onaylı ADR'ler geçerlidir (dosyada yazılı). Ortak komutlar, yollar ve bölüm adları tek başına çoğaltma sayılmaz.
- **H4 — belge göstergesi:** `larante-platform/docs/README.md` referans commit'i, bu görevin onaylı ve merge edilmiş doküman PR'ının doküman deposu `main`'indeki exact merge SHA'sına güncellenir; yetkili dosyalar listesine DWS (`docs/process/DEVELOPMENT-WORKFLOW-STANDARD-v1.md`), `docs/process/reviewer-preflight.sh` ve bu deponun `CLAUDE.md`'si eklenir; kopya tutulmaz.
- **H4 — izlenen-dosya guard'ı:** `larante-platform/test/import-boundaries.test.ts` içinde yalnız kök `CLAUDE.md` için tam yol kabulü (`rel === 'CLAUDE.md'`) ve bu kabulün kesinlik testleri; diğer yollar, yazım (büyük / küçük harf) varyantları ve uzantılar reddedilir; mevcut sınırlar korunur. Tests-first: kabul eklenmeden önce izlenen kök `CLAUDE.md` ile guard'ın kırmızı, kabulden sonra yeşil olduğu kanıtlanır.
- **Depo ayrımı (DWS §7.2, flag X):** her depo için ayrı dal / PR ve ayrı inspection base; bağımlılık iki PR gövdesine yazılır; önce onaylı doküman PR'ı merge edilir; platform PR'ının final inspection'ı gösterge güncellemesini kapsar.

## Out of scope
B10-(a) B2B tarafı belgelerinin (`CLAUDE.md` / `IS-AKISI.md`) senkronu — P7B B2B PR'ı; B2B deposunda herhangi bir dosya; §5.4 / §5.6 dışında kural değişikliği; ADR, DWS veya mimari kural metninde değişiklik; HANDOFF, master plan ve Phase 1 `README.md`; kullanıcı düzeyi `~/.claude` dosyaları, memory ve skill kopyaları; `larante-platform`'da Files allowed dışındaki her dosya (uygulama kodu, CI, diğer testler ve yapılandırmalar).

## Files allowed
- **Bu dokümantasyon deposunda:** `LARANTE_WEB_ALTYAPI_MIMARISI_V2.md`; `docs/decisions/PHASE0_KARAR_LISTESI.md` (yalnız B10 satırı tamamlanma kaydı); `CLAUDE.md` (yeni, kök).
- **`larante-platform`'da:** `CLAUDE.md` (yeni, kök); `docs/README.md`; `test/import-boundaries.test.ts` (yalnız `rel === 'CLAUDE.md'` kabulü ve kesinlik testleri).
- Başka dosya yok (HANDOFF dahil).

## Data migration impact
Yok.

## Security impact
- `larante-platform/test/import-boundaries.test.ts`'deki izlenen-dosya guard'ı, ADR-001 §Karar 5 import sınırlarının statik denetiminin parçasıdır. Değişiklik yalnız tek bir kod-dışı dosyanın (depo kökündeki `CLAUDE.md`) tam yol kabulüdür; başka hiçbir yol, yazım varyantı ya da uzantı kabul edilmez; mevcut kabuller ve sınırlar değişmez; kırmızı → yeşil kanıtı zorunludur.
- `CLAUDE.md` dosyaları secret, kimlik bilgisi veya erişim bilgisi içermez; DWS ve ADR kurallarını gevşeten ya da onlarla çelişen talimat içermez.
- ARCH konsolidasyonu ve B10 kaydı belge değişikliğidir.

## Acceptance
- ARCH gövdesi ile V2.1–V2.3 notları arasında çelişki kalmaz (Codex belge inspect'i APPROVED; kontrol listesi: her notlu bölüm için "gövde = not" işareti).
- Hiçbir ADR kuralı, karar durumu ya da açık madde değişmemiştir (doküman deposu diff'i yalnız ARCH metni + B10 kaydı + kök `CLAUDE.md`; `larante-platform` diff'i yalnız Files allowed'daki üç dosya).
- B10 satırı: (b) kapandı; (a) P7B'de kalır (yanlışlıkla tamam işaretlenmez).
- **H4:**
  - Her depoda tam olarak bir `CLAUDE.md` vardır (bu dokümantasyon deposunun kökü, `larante-platform` kökü); başka konumda yoktur; B2B deposu değişmez.
  - Her `CLAUDE.md` DWS göstergesini (kanonik yol + sürüm), ilgili Annex L bölümlerine göstergeleri ve deponun konvansiyonlarını içerir; "çelişkide DWS / ADR geçerlidir" der; normatif DWS metnini çoğaltmaz ve ikinci bir standart oluşturmaz.
  - `CLAUDE.md` dosyaları belge gibi incelenir: bu görevin Codex inspect'leri iki dosyayı da kapsar ve APPROVED olur.
  - `docs/README.md` göstergesi onaylı doküman PR'ının exact merge SHA'sını anar; bu commit doküman deposu `main`'inde vardır ve listelenen her yol o commit'te mevcuttur.
  - Guard: yalnız `rel === 'CLAUDE.md'` kabul edilir; kesinlik testleri diğer yolları, yazım varyantlarını ve uzantıları reddeder; mevcut sınırlar korunur; tests-first kırmızı → yeşil kanıtı; DWS Annex L §L4 tabanı yeşil; `larante-platform` PR'ında GitHub CI tamamen yeşil.
  - Her depo için ayrı PR ve inspection base; bağımlılık iki PR gövdesinde; önce onaylı doküman PR'ı merge edilir; platform final inspection'ı gösterge güncellemesini kapsar.

## Tests
- Belge tutarlılık kontrolleri: notlu bölüm listesi ↔ gövde diff'i; `grep` ile "geçersiz / Henüz kilitlenmez / onay bekliyor" kalıntısı yok; Markdown tablo bütünlüğü; Codex inspect.
- H4: `CLAUDE.md` dosyalarının DWS'ye karşı içerik incelemesi (normatif metin çoğaltılmamış, ikinci standart yok — satır eşleşmesi kuralı değildir); gösterge varlık kontrolü (listelenen her yol için `git cat-file -e <commit>:<yol>`); boundary suite'te kırmızı → yeşil (`CLAUDE.md` kabulü ve kesinlik testleri); `larante-platform` için DWS Annex L §L4 tabanı ve GitHub CI; Codex inspect'leri.

## Rollback
Platform PR'ı, ardından belge PR'ı revert edilir; V2.x notları zaten kuralı taşıdığı için içerik kaybı yok; guard kabulü `CLAUDE.md` ile aynı PR'da geri alınır. Veri etkisi yok.
