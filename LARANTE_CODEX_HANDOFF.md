# Larante Web — Codex Handoff

## Amaç ve ana dokümanlar

Larante Web Platformu; kurumsal web sitesi, B2C e-ticaret, admin panel, Akademi, lead/içerik yönetimi ve mevcut B2B ile ortak ürün/stok mantığını kapsıyor.

Proje klasöründeki iki ana doküman:

1. `LARANTE_WEB_REQUIREMENTS.md` — Onaylanmış iş gereksinimleri; ne yapılacağını belirler.
2. `LARANTE_WEB_ALTYAPI_MIMARISI_V2.md` — Hedef mimari; mevcut B2B hakkındaki teknik varsayımları gerçek repository üzerinden doğrulanmalıdır.

Dokümanlar proje klasörüne alındı; önceki yerleşim önerisi `docs/` idi. Bu handoff, iki dokümanın ve Claude planının yerine geçmez.

## Onaylanan geliştirme iş akışı

Her faz için:

**Claude Code Plan Mode → Codex plan denetimi → onaylı plan → Claude Code Implement + testler → Codex kod/test/rapor denetimi → Claude düzeltmeleri → Codex regresyon ve final denetimi → sonraki faz.**

- Claude'un planı ana plandır. Codex bulguları değerlendirilip onaylanan düzeltmeler bu plana işlenir; her turda gereksinimleri değiştiren yeni bir prompt oluşturulmaz.
- Kodlamadan sonra otomatik olarak Plan Mode'a dönülmez. Mimari bir sorun bulunursa plan revizyonu ve yeniden Codex denetimi yapılır.
- Codex yalnız uygulama raporunu değil, gerçek kodu ve testleri de inceler.
- Claude'un planlama ve kodlama oturumları aynı ana proje klasörünü kullanır; planlama oturumu kaynak dosyalarını değiştirmez.

## Şu anki durum ve audit kapsamı

Claude Code şu anda **Plan Mode'da salt-okunur repository audit'i ve master implementation planı** hazırlıyor. **Bu çalışma kapsamında henüz kod yazılmadı; implementasyon başlamadı.** Audit sırasında kaynak dosyası değişikliği, migration çalıştırma veya dependency kurulumu yapılmayacak. Plan tamamlandığında onay bekleniyor.

Mevcut B2B olarak seçilen repository, önceki konuşmada şu yolla belirtildi:

```text
Desktop\Larante Web Sitesi\b2b-portal\larante-b2b\app
```

Şunlar da **salt-okunur bağlam** olarak kapsama alındı:

- Önceki `larante-web` denemesi.
- Eski `Larante Web Sitesi/larante-site` projesi.
- İki eski B2B analiz Markdown dosyası; tam dosya adları konuşmada belirtilmedi.

Mevcut sistemin teknik doğruluk kaynağı gerçek B2B repository'sidir. Eski projeler ve analizler yalnız referans ve yeniden kullanım adayıdır; kararları otomatik taşınmaz. Modüller **KEEP / REFACTOR / REBUILD** gerekçeleriyle değerlendirilir.

Claude'un aktarılan ilk bulguları, mimarideki Node/Express/Prisma/PostgreSQL varsayımı yerine Bun, TanStack Start, Cloudflare Workers, D1/SQLite, R2, 21 SQL migration, tenant altyapısı ve CI bulunduğu yönünde. **Bunlar bu handoff hazırlanırken bağımsız doğrulanmadı; audit kanıtlarıyla kontrol edilmeli.**

## Codex'in ilk görevi

**Claude'un tamamlanan planını adversarial olarak, yani yanlış varsayımları ve kırılma senaryolarını arayarak denetle. İlk görev implementasyon değildir.**

İki ana dokümanı, Claude planını ve ilgili repository kanıtlarını okuyarak özellikle şunları kontrol et:

- Product/Inventory sahipliği, tek ürün ve stok kaynağı, B2B–B2C sınırları.
- Hedef mimari ile gerçek sistem arasındaki uyumsuzluklar; gereksiz rewrite, framework/ORM çoğalması.
- Stok yarış koşulları ve fazla satış, ödeme/webhook idempotency, transaction ve veri bütünlüğü.
- Auth/RBAC, tenant izolasyonu, fiyat sızıntısı ve sunucu tarafı yetkilendirme.
- Faz sırası, bağımlılıklar, migration/rollback, testler ve kabul kriterleri.

Çıktı: önem derecesi, kanıt, etki ve çözüm yönü içeren bulgular; kodlamayı engelleyen kararlar; ana plana işlenecek düzeltmeler ve net Phase 0 kapsamı. Doğrulanamayan noktaları açıkça belirt. Product/Inventory sahipliği netleşmeden commerce geliştirmesine geçilmemeli.

Claude planı henüz sunulmadıysa denetim tamamlanmış sayılmaz; planın paylaşılması gerekir.
