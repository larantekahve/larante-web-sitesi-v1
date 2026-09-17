# ADR-015 — ORM Kararı (B2B Audit Sonrası): Tek ORM = Drizzle (PostgreSQL)

**Durum:** TASLAK — onay ve Codex denetimi bekliyor · **Tarih:** 2026-09-15
**Kaynaklar:** ARCH §5.5-5.6, §62-63, §78; `docs/plan/LARANTE_MASTER_PLAN_2026-09-15.md` §11

## Bağlam
ARCH §5.6: "B2B gerçekten Prisma kullanıyorsa ortaklık için Prisma öncelikli değerlendirilir; aksi durumda alternatifler ADR ile; aynı domain için Prisma + Drizzle + başka ORM birlikte kullanılmaz."

## Kanıt
- **B2B'de ORM YOK:** ham D1 SQL — `db().prepare(...).bind(...).all/first/run` (`src/lib/b2b/core.server.ts:11-21` çıplak `D1Database` binding); `app/package.json`'da `prisma`, `@prisma/client`, `drizzle-orm`, `kysely`, `pg`, `postgres` yok.
- B2B SQL'i SQLite/D1'e özgü: `db().batch()` (BEGIN/COMMIT yok), FK yerine 34 BEFORE trigger (`migrations/0016`), `DROP TABLE + CREATE TABLE` rebuild (`0018/0019`), toplam 355 `RAISE(ABORT)`, `COLLATE NOCASE`, `INSERT OR IGNORE` — Postgres'e taşınmaz; 9 migration testi `node:sqlite`'a bağlı.
- Önceki web denemesi `larante-web` D-008 Drizzle + drizzle-kit (forward-only) kararı vermiş, kurmamış.
- Platform gereksinimleri: gerçek transaction, satır kilidi (`SELECT … FOR UPDATE SKIP LOCKED`), atomik güncelleme (`UPDATE … WHERE on_hand − reserved >= $q`), SEQUENCE, CHECK/UNIQUE/FK (ARCH §62-63).

## Karar
1. Platform veritabanı **PostgreSQL** (yalnız düz Postgres özellikleri; sağlayıcıya özgü RLS/edge/auth yok → taşınabilir). B2B D1 dokunulmaz.
2. **Tek ORM = Drizzle ORM** (`drizzle-orm` + `drizzle-kit`, Postgres sürücüsü). Migration'lar drizzle-kit ile üretilir, **elle gözden geçirilir** ve düz SQL olarak repoya girer; forward-only; destructive değişiklik iki aşamalı (expand → migrate → contract); AI-üretimi migration doğrudan prod'a uygulanmaz (ARCH §78).
3. Yarış-kritik ifadeler (rezervasyon UPDATE, SKIP LOCKED, sequence) Drizzle'ın `sql` şablonuyla açık SQL olarak yazılır ve review edilir; ham SQL yalnız `packages/db` repository implementasyonlarında ve migration dosyalarında.
4. Platform repo'sunda Prisma/TypeORM/Kysely **yasak** (lint + dependency review). B2B'ye ORM eklenmez.
5. **İki-ORM riski aynı domain için yoktur:** B2B (D1/SQLite, ham SQL) ile platform (Postgres, Drizzle) hiçbir tablo, migration veya bağlantı paylaşmaz; tek bağ HTTP sözleşmesi (ADR-001) + `variant_external_codes` (ADR-004 §3.4, ADR-016 K6 — 2026-09-16 öncesi `product_external_codes`). Gerçek risk şema **çiftlenmesi**dir (B2B `products` projeksiyonu vs platform `products`) — bu, "B2B'de katalog migration'ları dondurulur, ad/kategori B2B'de düzenlenmez" kuralıyla sınırlanır.
6. Tipler: para `INTEGER` kuruş, oranlar basis point `INTEGER`; **miktarlar tamsayı** — bakiyeler (`on_hand`, `reserved`) `INTEGER CHECK (>= 0)`, fiziksel hareket ve rezervasyon olayı miktarları `INTEGER CHECK (> 0)` + açık yön / aksiyon (işaretli delta yok; ayrıntı ADR-016 K2); `REAL/float` yasak (B2B'nin REAL borcu taşınmaz). Tüm id UUID.

## Reddedilenler
- **Prisma:** zengin DSL/tooling; ancak satır kilidi/atomik UPDATE için raw SQL'e düşülür, motor ikili dosyası/Data Proxy bağımlılığı; "B2B Prisma ise" koşulu boş.
- **ORM'siz ham SQL (B2B gibi):** DTO/tip güvenliği yok; B2B'de bu yol tek dosyalık 1979 satırlık handler ve `SELECT *` export üretmiş.

## Sonuçlar
Drizzle'ın relational API'si Prisma kadar olgun değil; karşılığında migration SQL'i şeffaf ve DB kısıtları doğrudan yazılır. Concurrency integration testleri (gerçek Postgres) CI kapısıdır.

## İlgili
ADR-001, ADR-004, ADR-016 (stok miktar modeli / rezervasyon sözleşmesi — tip kuralının kaynağı), ADR-017 (deployment; eski "ADR-016" numarası).
