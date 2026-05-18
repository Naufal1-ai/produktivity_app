# Domain Layer (Non-intrusive scaffold)

Folder ini disiapkan untuk poin arsitektur (poin 3) tanpa mengubah alur program yang sudah ada.

Tujuan:
- Menjaga business rule terpisah dari UI/Provider/Data.
- Menjadi tempat entity dan usecase ke depan.
- Tidak dipakai langsung dulu agar aman (no breaking change).

Struktur awal:
- `entities/` : model domain murni (tanpa dependensi framework)
- `usecases/` : aturan bisnis per fitur

Catatan:
- Saat ini hanya scaffold, tidak ada wiring ke kode existing.
