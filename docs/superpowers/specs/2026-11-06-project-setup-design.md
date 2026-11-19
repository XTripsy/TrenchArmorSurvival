# Project Setup (Phase 0) — Design

Tanggal: 2026-11-06
Status: approved
Scope: TODO Phase 0 (T-001..T-004)

## Intent

Menyiapkan fondasi proyek Godot untuk *Trench Armor Survival* memakai engine yang
sudah terpasang di mesin ini: `4.7.2.stable.steam.ed1daf0bf`
(`D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`).
Tujuannya agar Phase 1 dan seterusnya bisa dikerjakan tanpa revisi konfigurasi dasar.

## Goals

- `project.godot` valid untuk Godot 4.7 dan terbuka tanpa error.
- Struktur direktori persis seperti TODO §2.
- Input map 6 action (TAD §1.2), 6 nama physics layer (TAD §3.1), 4 autoload terdaftar.

## Non-Goals

- Tidak mengerjakan isi autoload (Phase 1) — hanya stub.
- Tidak membuat `main_menu.tscn` / `main_scene` (T-028).
- Tidak membuat scene, script gameplay, asset, atau export preset.
- Tidak menginisialisasi git repo.

## Constraints

- Godot 4.2+ (TAD §1.1) → 4.7.2 yang terpasang.
- `config_version=5`, `config/features` berisi `"4.7"` + renderer.
- Zero-asset: tidak ada file biner/asset yang dibuat.
- Tidak membuat file di luar §2 TODO, kecuali dokumen ini dan `project.godot`.

## Approaches

1. **Tulis `project.godot` manual, validasi dengan engine headless** (dipilih).
   Transparan, mudah di-review, dan `ProjectSettings` yang tidak dikenal akan
   dilaporkan engine saat validasi.
2. Generate konfigurasi lewat script `ProjectSettings.save()` sementara.
   Ditolak: menambah file sementara dan menghilangkan komentar/urutan yang kita
   kontrol, tanpa manfaat untuk konfigurasi sekecil ini.
3. Konfigurasi lewat GUI editor.
   Ditolak: tidak bisa dijalankan agent dan tidak reproducible.

## Decisions

| Topik | Keputusan | Alasan |
|---|---|---|
| Renderer | `forward_plus` | Mendukung glow/HDR 2D untuk ledakan & spark (GDD §7). Alternatif `gl_compatibility` jika target GPU low-end. |
| `run/main_scene` | kosong | Scene menu baru ada di T-028. |
| Autoload | didaftarkan + stub `extends Node` | Autoload tanpa file = error saat proyek dibuka. Stub diizinkan TODo T-004. |
| Input keycode | `physical_keycode` | Independen layout keyboard. |
| Layer names | 6 layer sesuai TAD §3.1 | Single source of truth. |
| Clear color | `#4A3B32` | Ground color GDD §7.1, mencegah layar abu-abu sebelum arena dibuat. |
| Folder kosong | hanya direktori | Tidak perlu `.gitkeep` (belum repo), menghindari file di luar spesifikasi. |
| Stretch | `canvas_items` + `keep` | TAD §1.2. |

## Definition of Done

- `godot --headless --path . --editor --quit` selesai tanpa parse error.
- `InputMap` memuat 6 action dengan event yang benar.
- `ProjectSettings` memuat 6 layer name, 4 autoload, viewport 1280x720, physics 60.
- Semua folder §2 ada.
