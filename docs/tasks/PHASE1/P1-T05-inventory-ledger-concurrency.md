# P1-T05 — Envanter ledger şeması (ADR-016 K2) ve concurrency testi — Phase 1'in ilk kodu

- **TASK ID:** P1-T05
- **Requirement refs:** REQ §31.1–§31.2 (fiziksel / rezerve / kullanılabilir; tamsayı birim), §31.8 (mutabakat — yalnız şema hazırlığı), §118 ("stok tek kaynak", "miktar tamsayı kısıtları DB'de aktif", "rezervasyon işlemleri idempotent" kriterleri), R2, R13, R14
- **ADR refs:** **ADR-016 (ONAYLI 2026-09-18) K2** — `inventory_items`, `inventory_balances`, `inventory_movements`, `inventory_reservations` (NULL içermeyen `namespace`; `UNIQUE (namespace, external_order_id, external_line_id) WHERE status = 'ACTIVE'`), `inventory_reservation_events` (`operation_ref → operations.id`), `operations` (`id PK, namespace, operation_id; UNIQUE (namespace, operation_id)`); K1 (tamsayı), K2/6 RESERVE guard'ı (`UPDATE … WHERE on_hand − reserved >= q`), K2/8 (`reserved <= on_hand` sert kısıt **değil**), K4-R (mezar taşı: yalnız şema), K10 (kimlik sınıfları); ADR-004 §3.2; ADR-015 §Karar 3, §6; master plan §8, §14, §18 P1 (Amaç: "ilk kod"), §22 (Phase 1 çıkışı: concurrency testi CI'da)
- **Bağımlılıklar:** P1-T03 (Postgres + Drizzle + test yardımcıları), P1-T04 (CI integration adımı). **Kapı (F01) sağlandı 2026-09-18** — ADR-016 onaylı, B6b / B6c karar, B6e birim sınıfları karar; varyant başına SKU verisi (B6a / B6e) bu görevi bloklamaz (şema veri içermez).

## Goal
Yalnız ADR-016 K2 şemasını Drizzle + elle gözden geçirilmiş SQL migration olarak yazmak ve gerçek Postgres'te **"N eşzamanlı rezervasyon toplamı `on_hand`'i aşamaz"** testini kırmızı → yeşil geçirmek; oversell koruması Phase 1'den itibaren CI kapısıdır.

## Scope
- Şema (Postgres, Drizzle şema dosyaları + üretilmiş / gözden geçirilmiş migration): K2/1–K2/4 tabloları ve kısıtları — `INTEGER CHECK (>= 0)` bakiyeler, `INTEGER CHECK (> 0)` hareket / olay miktarları, hareket tipleri ve yön, `reason NOT NULL`, rezervasyon `channel web|b2b`, `namespace NOT NULL` + kanal CHECK'i, ACTIVE tekillik kısmi indeksi, olay `UNIQUE (operation_ref, reservation_id, action)`, `operations` ad-alanlı tekillik; **`reserved <= on_hand` CHECK'i yazılmaz** (K2/8).
- `packages/db` repository iskeleti: yalnız atomik RESERVE guard ifadesi (K2/6, açık SQL — ADR-015 §Karar 3) ve K2/4 idempotency araması (`(namespace, operation_id)`), test için gerekli minimum yazıcı. Use-case / HTTP ucu yok.
- Concurrency integration testi (gerçek Postgres, `packages/testing` harness): N paralel RESERVE → toplam ≤ `on_hand`, `reserved` tutarlı; aynı `(namespace, operation_id)` tekrarı tek etki; aynı satır için ikinci ACTIVE nesil UNIQUE ile reddedilir; iki farklı ad alanında aynı dış `operation_id` → iki ayrı kayıt (ADR-016 §6 P1 / §6 test listesi).
- **Kesirli girdi reddi yazma sınırında:** repository / use-case girişinde tamsayı doğrulaması (zod `int()` / `Number.isInteger` eşdeğeri) ve parametreli sorgularda int4 parametre bağlama (metin parametre `'1.25'` → PostgreSQL giriş hatası). DB tarafı yalnız **tamsayı depolama** garantisi verir: numeric bir ifade INTEGER kolona atanırsa PostgreSQL yuvarlar (`1.25` → `1`, CHECK geçer); bu yüzden DB CHECK tek başına kesirli girdiyi reddetmez ve ham numeric ifadeyle yazma yolu uygulamada bulunmaz. REQ §118 "miktar tamsayı kısıtları DB'de aktif" = INTEGER tip + CHECK kısıtları; yuvarlama iş kuralı yoktur (ADR-016 K1).
- CI kapısı: test P1-T04 integration adımında zorunlu.

## Out of scope
Rezervasyon use-case'leri, patch / release / commit / abandon uçları, eskalasyon / mutabakat işleri, web checkout, B2B entegrasyonu (Phase 5 / 7 / 7B); varyant kataloğu ve SKU verisi (Phase 4 — B6a / B6e); `inventory_items` için gerçek varyant satırları (test fixture'ları sentetik); shortage yönetici akışı (Phase 5).

## Files allowed
Yalnız `larante-platform`: `packages/db/src/schema/inventory*`, `packages/db/migrations/*` (bu görevin migration'ı), `packages/db/src/repositories/inventory*` (yalnız RESERVE guard + idempotency arama iskeleti), `packages/testing/**` (concurrency harness), CI integration adımı bağlantısı. İlgili paket `package.json` bağımlılık satırları ve kök `pnpm-lock.yaml` (yalnız bu görevin eklediği bağımlılıklar; `--frozen-lockfile` CI ile tutarlı).

## Data migration impact
İlk gerçek şema migration'ı (yeni tablolar; expand-only). İş verisi yok. Açılış stoğu **bu görevde girilmez** (B6d — Phase 5 sayım runbook'u).

## Security impact
Düşük: DB kısıtları fail-closed; test veritabanı yerel / CI; secret yok.

## Acceptance
- Migration gerçek Postgres'te up + idempotent yeniden çalıştırma geçer; şema ADR-016 K2 ile birebir (kolon / kısıt / indeks listesi review'da işaretlenir).
- Concurrency testi kırmızı → yeşil kanıtı (guard'sız ilk koşu oversell üretir, guard'lı koşu üretmez) CI'da yeşil.
- Idempotency ve ACTIVE tekillik testleri yeşil; `reserved <= on_hand` sert kısıt olmadığı testle gösterilir (ADJUST_DOWN sonrası `available < 0` kaydedilebilir).
- Tamsayı depolama DB'de zorunlu (INTEGER + CHECK); kesirli girdi yazma sınırında reddedilir ve testle gösterilir: gerçek sürücü / repository yolu üzerinden `1.25` → hata (kayıt yok); doğrudan numeric-ifade INSERT / UPDATE vakası (`1.25` → `1` yuvarlama) belgelenir ve bu yolun kullanılmadığı lint / review ile korunur.
- Codex plan + kod denetimi APPROVED (ADR-016 K2 uyum kontrolü dahil).

## Tests
Integration (gerçek Postgres): N paralel RESERVE ≤ on_hand; aynı operation_id tekrarı tek etki; farklı gövde ile aynı operation_id → 422 eşdeğeri (repository düzeyinde hata); ACTIVE tekillik; ad alanı ayrımı; `available < 0` kaydı; kesirli miktar reddi (sürücü / repository yolu: `1.25` → hata; numeric-ifade yuvarlama vakası belgelenir); negatif / sıfır miktar reddi (CHECK); migration idempotency.

## Rollback
Expand-only migration; tablolar boş olduğu için görev PR'ı revert edilebilir (forward-only politikada takip migration'ı ile). CI kapısı devre dışı bırakılmaz — geri alma yalnız şema PR'ının geri alınmasıdır.
