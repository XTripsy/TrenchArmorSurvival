# UI/UX Design Specification: Trench Armor Survival (v3.0 Showcase Edition)

## 1. Design Philosophy & Showcase Visual Direction
* **Theme:** Stylized WW1/WW2 Tactical Field Command Terminal (Military Stencil, Gunmetal Steel, Olive Drab, Radar Phosphor, & High-Contrast Signal Amber/Crimson).
* **Showcase Mandate (Anti-Plain / Zero-Asset Richness):** Karena game akan ditampilkan dalam sesi *showcase*, antarmuka **tidak boleh terlihat seperti kotak panel polos**. Seluruh elemen UI wajib diperkaya menggunakan ornamentasi vektor prosedural (`Control._draw()`, `Polygon2D`, `Line2D`, `ShaderMaterial`/`GradientTexture2D` prosedural, dan `Tween`):
  * **Tactical Frame Ornamentation:** Siku bidik (*L-bracket corners*), paku keling sudut (*corner rivets*), garis arsir bahaya diagonal (*hazard stripes*), dan tekstur *scanline/grid* radar tipis (`alpha = 0.04–0.06`).
  * **Attract-Mode & Field Intel:** *Main Menu* menampilkan pertempuran AI aktif di latar belakang disertai *Field Manual* visual agar pengunjung *showcase* langsung memahami mekanik unik *Ricochet 2x* dan *Map Expansion* dalam sekali lihat.
* **Core Principle:** **Diegetic, Glanceable (`< 0.3s`) & Colorblind-Safe HUD**. Dekorasi visual harus membingkai informasi tanpa mengurangi rasio kontras teks maupun menghalangi area aksi tengah layar.
* **Viewport & Scaling Standard:** Base resolution `1280x720`, Stretch Mode `canvas_items`, Stretch Aspect `expand`. HUD berada pada `CanvasLayer (layer = 1)`, *Phase Banner* & *Screen Vignette* pada `CanvasLayer (layer = 2)`, dan *Modal/Overlay* pada `CanvasLayer (layer = 3)`.

---

## 2. Design Tokens (Single Source of Truth)

### 2.1. Color Palette & Contrast Roles
| Token Name | Hex Code | RGBA (`Color`) | Contrast / Tier | Usage & Semantic Role |
| :--- | :--- | :--- | :--- | :--- |
| `UI_BG_DARK` | `#141618` | `(0.078, 0.086, 0.094, 0.92)` | Base Surface | Latar belakang utama kartu HUD & modal |
| `UI_BG_ELEVATED` | `#1B1E22` | `(0.106, 0.118, 0.133, 0.95)` | Card Inset | Latar sub-kartu, baris tabel selang-seling, *keycap* |
| `UI_SURFACE` | `#22262A` | `(0.133, 0.149, 0.165, 0.95)` | Interactive Base | Tombol normal, *track* bar kosong, node netral |
| `UI_SURFACE_HOVER` | `#2E343B` | `(0.180, 0.204, 0.231, 1.0)` | Interactive Hover | Latar tombol saat *hover* atau *keyboard focus* |
| `UI_BORDER_STEEL` | `#4D5660` | `(0.302, 0.337, 0.376, 1.0)` | 3.1:1 (Graphical) | Garis tepi utama panel & tombol (`border_width = 2px`) |
| `UI_ORNAMENT_DIM` | `#6E7A87` | `(0.431, 0.478, 0.529, 0.75)` | Ornamental | Siku *L-bracket*, garis pembagi internal, *ticks* radar |
| `UI_BORDER_ACTIVE` | `#E0AF3E` | `(0.878, 0.686, 0.243, 1.0)` | 9.6:1 (AAA) | *Hover/Focus border*, aksen komando, stempel *Rank S* |
| `UI_TEXT_PRIMARY` | `#F4F1EA` | `(0.957, 0.945, 0.918, 1.0)` | 16.4:1 (AAA) | Teks utama, angka skor, judul layar |
| `UI_TEXT_MUTED` | `#A8B2BC` | `(0.659, 0.698, 0.737, 1.0)` | 8.2:1 (AAA) | Label sekunder, timer, *hotkey hints* |
| `UI_TEXT_DANGER` | `#FF6B6B` | `(1.000, 0.420, 0.420, 1.0)` | 6.8:1 (AA+) | Teks peringatan Boss & status Game Over |
| `SEMANTIC_ALLY` | `#5E943B` | `(0.369, 0.580, 0.231, 1.0)` | 4.8:1 (Graphical) | Segmen HP aktif, zona `CAPTURED`, status `READY` |
| `SEMANTIC_WARN` | `#E59528` | `(0.898, 0.584, 0.157, 1.0)` | 7.3:1 (Graphical) | *Threat Meter*, zona `CAPTURING`, peringatan taktis |
| `SEMANTIC_DANGER` | `#D13B3B` | `(0.820, 0.231, 0.231, 1.0)` | 4.1:1 (Graphical) | Isian Boss HP bar, HP kritis, zona `CONTESTED` |
| `SEMANTIC_CRIT` | `#FF6A1A` | `(1.000, 0.416, 0.102, 1.0)` | 6.4:1 (AA+) | *Floating combat text* & *Streak* `RICOCHET KILL` |

### 2.2. Typography Scale & Hierarchy
Gunakan `SystemFont` monospace taktis (`["JetBrains Mono", "Consolas", "Liberation Mono", "Courier New"]`), `font_weight = 700` (Bold), dengan *outline* gelap (`outline_size = 2`, `outline_color = #0B0C0E`):
* **`TYPE_HERO` (`52 px`):** Judul utama pada *Main Menu* (`TRENCH ARMOR`), *uppercase*, *letter spacing* `+3 px`.
* **`TYPE_DISPLAY` (`44 px`):** Judul *overlay* besar (`ARMOR DESTROYED`, `SECTOR CLEARED`), *uppercase*, *letter spacing* `+2 px`.
* **`TYPE_METRIC` (`24 px`):** Angka skor utama (`%06d`) & angka statistik besar dengan lebar karakter tetap (*tabular*).
* **`TYPE_HEADER` (`18 px`):** Judul kartu modal, nama Boss (`WARNING: IRON GOLIATH`), & *Phase Banner*.
* **`TYPE_LABEL` (`14 px`):** Label status fase, timer (`TIME 00:00`), tab *Intel*, dan teks tombol.
* **`TYPE_MICRO` (`11–12 px`):** Label telemetri mikro (`ARMOR INTEGRITY`, `RADAR // 2560M`, `UNIT: VANGUARD-01`) dan *keycap hints*.

### 2.3. Spacing, Grid & Procedural Ornamentation Rules
* **Base Grid Unit:** `8 px` (semua margin, padding, dan jarak wajib kelipatan `4 px` atau `8 px`).
* **Screen Safe Margin:** `24 px` dari keempat tepi *viewport*.
* **Tactical Frame Spec (`TacticalFrame` Helper):**
  * **Corner L-Brackets:** Garis siku `8 x 8 px` (`width = 2 px`) pada keempat sudut kartu utama dengan jarak `3 px` dari tepi luar panel.
  * **Micro Scanlines:** Garis horizontal berulang setiap `4 px` (`Color(1, 1, 1, 0.03)`) di dalam kartu modal dan panel *Intel*.
  * **Diagonal Hazard Stripes:** Garis miring `45°` (`width = 6 px`, jarak `12 px`, `alpha = 0.18`) khusus untuk *header* fase `BOSS`, peringatan `CRITICAL ARMOR`, dan tombol `CONFIRM ABORT?`.
  * **Physical Keycap Badges:** Tag tombol seperti `[WASD]`, `[LMB]`, `[ESC]` dirender di dalam kotak `UI_BG_ELEVATED` ber-border `1 px` `UI_ORNAMENT_DIM` dengan *bottom border* `2 px` menyerupai tuts keyboard mekanik.

---

## 3. Showcase Main Menu Specification (`main_menu.gd`)

Untuk menghilangkan kesan kosong/polos saat game dipamerkan di layar *showcase*, *Main Menu* dirancang sebagai **Tactical War-Room Command Console** dengan tata letak asimetris 2-kolom di atas medan tempur aktif:

### 3.1. Background Layer: Live Attract-Mode Battlefield
* **Live AI Skirmish / Camera Pan:** Kamera perlahan menyapu arena tempur aktif (`1280x720`) tempat unit tank AI saling bertempur dan memantulkan peluru di sekitar bunker, lengkap dengan jejak roda (*tread marks*) dan asap tipis.
* **Atmospheric Framing:**
  * *Vignette* tepi layar (`alpha = 0.55` di tepi, `alpha = 0.18` di tengah) agar teks UI tetap kontras.
  * *Coordinate Grid Overlay:* Garis grid tipis (`128 px` interval, `alpha = 0.06`) dengan penanda koordinat mikro (`SEC-01 // LAT 49.2N`) di sudut layar.

### 3.2. Left Column (`x = 56 px`, `width = 480 px`): Command Crest & Navigation
1. **Procedural Military Emblem (`72 x 72 px` `_draw()`):**
   * Perisai segi enam baja (`UI_SURFACE`), siluet tank *top-down* di tengah (`#556B2F`), bintang putih, dan dua *chevron* emas (`UI_BORDER_ACTIVE`) di bawahnya.
2. **Title Lockup:**
   * Badge mikro di atas judul: `● FIELD COMMAND TERMINAL // BUILD 1.0` (`TYPE_MICRO`, `UI_BORDER_ACTIVE`).
   * Judul utama: `TRENCH ARMOR` (`TYPE_HERO`, `UI_TEXT_PRIMARY`).
   * Sub-judul berlatar *strip* gelap: `SURVIVAL  //  RICOCHET TACTICS` (`TYPE_HEADER`, `UI_BORDER_ACTIVE`).
3. **Primary Action Stack (`separation = 12 px`, `width = 340 px`):**
   * **`DEPLOY TO SECTOR` (Primary CTA, `height = 52 px`):** Border `2 px` `UI_BORDER_ACTIVE`, aksen *chevron* animasi `>>` di sisi kanan saat *hover/focus*, otomatis terfokus saat menu terbuka.
   * **`TACTICAL INTEL` (`height = 44 px`):** Mengganti/menyorot kartu *Field Manual* di sisi kanan dengan efek *flash border*.
   * **`QUIT TO DESKTOP` (`height = 44 px`):** Tombol keluar standar dengan gaya `UI_SURFACE`.

### 3.3. Right Column (`Anchor: Right`, Margin `56 px`, `width = 440 px`): Interactive Field Manual Card
Kartu *showcase* permanen di sisi kanan layar dengan tab interaktif (`[1] COMBAT`, `[2] ESCALATION`, `[3] INVASION`) yang otomatis berganti tiap `6.0 detik` (atau saat diklik pengunjung) disertai **diagram vektor prosedural (`140 px` tinggi)** yang digambar via `_draw()`:
* **Tab 1 — `RICOCHET TACTICS`:** Diagram pantulan peluru kuning (`#FFD700`) memantul pada dinding baja miring menjadi peluru oranye (`#FF5500`), disertai keterangan `1x WALL BOUNCE = 2X SCORE & HEAVY ARMOR PIERCING`.
* **Tab 2 — `THREAT & BOSS`:** Diagram progres `100% THREAT` menuju siluet `IRON GOLIATH`, menjelaskan bahwa tembakan pantulan memberikan `2x DAMAGE` pada Boss.
* **Tab 3 — `TERRITORY INVASION`:** Diagram `1280x720 -> 2560x1440` dengan 3 lingkaran zona *capture* (`+500 PTS` & `+1 ARMOR REPAIR`).

### 3.4. Bottom Telemetry Bar (`Anchor: Bottom`, `height = 44 px`)
* **Kiri:** *Physical Keycap Badges* `[W][A][S][D]` `DRIVE` · `[MOUSE]` `AIM` · `[LMB]` `FIRE` · `[ESC]` `PAUSE`.
* **Kanan:** `BEST RECORD: %06d` (`UI_BORDER_ACTIVE`) & `STATUS: COMBAT READY` (`SEMANTIC_ALLY`).

---

## 4. In-Game HUD & Diegetic Feedback (`hud.gd` & `floating_text.gd`)

### 4.1. Top-Left: Armored Chassis & Integrity Card (`Anchor: Top-Left`, Margin `(24, 24)`)
* Dibingkai `TacticalFrame` dengan siku *L-bracket* dan header mikro `CHASSIS // VANGUARD-01` + status teks kanan (`NOMINAL` hijau, `CAUTION` kuning, `CRITICAL` merah).
* **Procedural Tank Status Icon (`36 x 36 px` `_draw()`):** Siluet mini tank *top-down* di sisi kiri kartu yang berotasi mengikuti *turret* pemain secara *real-time* dan berkedip putih/merah saat terkena *damage*.
* **Chamfered Segmented Armor Bar (`HBoxContainer`, `separation = 6 px`):**
  * Tiap segmen digambar sebagai pelat baja trapesium/miring (`38 x 16 px`, atau `30 x 16 px` jika `MAX_HP > 5`) dengan garis kilau atas `1 px` (`alpha = 0.25`) dan titik paku keling kecil.
  * *State Aktif:* `SEMANTIC_ALLY` (`#5E943B`).
  * *State Kritis (`HP == 1`):* Warna `SEMANTIC_DANGER` + *pulse alpha* (`0.55 <-> 1.0`, `2 Hz`) + **Screen-Edge Crimson Vignette** halus (`alpha = 0.16`).
  * *Damaged Feedback:* Segmen yang hilang berkedip `#FFFFFF` selama `0.15s` sebelum meredup ke `UI_SURFACE`.

### 4.2. Top-Center: Command Phase & Objective Tracker (`Anchor: Top-Center`, Margin Top `24 px`)
Dibingkai panel komando bersudut miring dengan indikator fase (`PHASE 01/03`) dan transisi *fade + vertical slide* (`8 px`, `0.25s`):
1. **Fase 1 — `SKIRMISH`:**
   * Header (`TYPE_LABEL`): `SECTOR %02d  //  THREAT ESCALATION` + persentase angka di kanan (`%3d%%`).
   * Progress Bar (`360 x 14 px`): Isian `SEMANTIC_WARN` dilengkapi garis penanda (*milestone ticks*) pada `25%`, `50%`, dan `75%`.
2. **Fase 2 — `BOSS`:**
   * Header dengan latar *diagonal hazard stripes* (`TYPE_HEADER`, `UI_TEXT_DANGER`): `⚠ WARNING: IRON GOLIATH` + sub-label `RICOCHET WEAKNESS [2X DMG]`.
   * Boss Health Bar (`460 x 18 px`): Layer depan `SEMANTIC_DANGER` dengan garis segmentasi tiap `25%` HP, serta **delayed white damage trail bar** (`#FFFFFF`, `alpha = 0.85`, *delay* `0.25s`, *shrink* `0.30s`).
3. **Fase 3 — `INVASION`:**
   * Header (`TYPE_LABEL`): `TERRITORY INVASION  //  CAPTURE ALL OUTPOSTS`.
   * **3 Tactical Node Cards (`84 x 28 px`, `separation = 12 px`):** Masing-masing memiliki ikon status *colorblind-safe* dan *mini progress bar* `3 px` di bagian bawah badge:
     * `NEUTRAL`: `01 [ - ]` (`UI_SURFACE`, `UI_TEXT_MUTED`).
     * `CAPTURING`: `01 [ ▲ ]` (`SEMANTIC_WARN`, teks `#141618` + bar progres).
     * `CONTESTED`: `01 [ ! ]` (`SEMANTIC_DANGER`, teks `#FFFFFF` + *border pulse*).
     * `CAPTURED`: `01 [ ✓ ]` (`SEMANTIC_ALLY`, teks `#FFFFFF`).

### 4.3. Top-Right: Telemetry & Sweeping Tactical Radar (`Anchor: Top-Right`, Margin `(24, 24)`)
* **Score & Combo Card:**
  * Rata kanan dengan siku *L-bracket*: Label `COMBAT SCORE`, angka `%06d` (`TYPE_METRIC`, *scale punch* `1.0 -> 1.2 -> 1.0` dalam `0.18s`), dan baris bawah `TIME %02d:%02d` + badge `SECTOR %02d`.
  * **Ricochet Streak Pill:** Muncul dinamis di bawah kartu skor saat pemain mencetak >= 2 *ricochet kill* beruntun tanpa meleset/terkena hit (`🔥 RICOCHET STREAK x%d`, warna `SEMANTIC_CRIT`).
* **Tactical Radar Scope (`168 x 94 px`, jarak `8 px` di bawah Score Card):**
  * Rasio `16:9` presisi dengan bingkai `UI_BG_DARK`, border `2 px` `UI_BORDER_STEEL`, garis kuadran (`A1–B2`), dan **garis sapuan radar berputar** (`0.5 rev/s`, `alpha = 0.08`).
  * Z-order `_draw()`: (1) Batas arena & rintangan `UI_SURFACE`, (2) Capture Zones `r = 6 px` + cincin progres, (3) Musuh `r = 2.5 px` `SEMANTIC_DANGER` & Boss `r = 5 px` ber-outline putih, (4) Pemain `r = 3.5 px` `#FFFFFF` + garis arah *turret* `9 px`.

### 4.4. Center-Top (`y = 128 px`): Dramatic Phase Transition Banner
Saat fase berpindah (`BOSS SPAWNED`, `PERIMETER BREACHED — SECTOR EXPANDED`, atau `SECTOR CLEARED`), tampilkan *banner* taktis ber-arsir diagonal selama `1.8 detik` (*slide-in* horizontal `0.2s`, tahan `1.3s`, *fade-out* `0.3s`) agar penonton *showcase* langsung menangkap perubahan fase permainan.

### 4.5. Diegetic & World-Space UI
* **Off-Screen Objective Pointers:** Di-clamp `32 px` dari tepi layar, berotasi ke target (`Boss` / `CaptureZone` belum `CAPTURED`), menampilkan panah taktis berkedip halus dan jarak `%dm` (`TYPE_MICRO`).
* **Diegetic Reload & Ricochet Reticle:** Titik pusat (`2 px`) + 4 garis bidik (`6 px`) yang melebar `+8 px` saat menembak dan menyusut kembali mengikuti `fire_cooldown` (`0.45s`), dilengkapi busur lengkung tipis di bawah *crosshair* saat meriam siap tembak.
* **Floating Combat Text:** Naik `32 px` selama `0.70s` (*ease-out*) lalu *fade out*: Normal Kill (`+100`), Ricochet Kill (`+200 RICOCHET!`, `SEMANTIC_CRIT`, *scale pop* `1.25x`), Outpost Secured (`OUTPOST SECURED (+1 HP)`, `SEMANTIC_ALLY`).

---

## 5. Menus, Overlays & Interaction Safety Guards (`CanvasLayer 3`)

### 5.1. Button States & Godot 4 Pivot Rule
Semua tombol interaktif menerapkan `pivot_offset = size / 2` (pada `ready` & `resized`) serta 4 *state* (`Normal`, `Hover/Focus` dengan `UI_BORDER_ACTIVE` + *scale* `1.03x` `0.1s` Tween + *left accent bar* `4 px`, `Pressed` *scale* `0.97x`, `Disabled` `alpha = 0.45`).

### 5.2. Pause Overlay (`Esc`)
* *Dimmer* layar penuh `Color(0.04, 0.05, 0.06, 0.80)` dengan tekstur *scanline*.
* Kartu tengah (`width: 400 px`) berbingkai `TacticalFrame` berisi:
  * Header `TACTICAL PAUSE` + *diagonal hazard bar*.
  * Ringkasan statistik sesi berjalan (*Current Score*, *Time Elapsed*, *Ricochet Kills*, *Sector*).
  * Strip pengingat kontrol ringkas (`[WASD] Drive · [LMB] Ricochet Shot`).
  * Tombol *toggle* `AUDIO: ON / OFF`, tombol `RESUME`, dan tombol `ABORT TO MENU` dengan **Two-Step Abort Protection** (klik pertama berubah menjadi `CONFIRM ABORT?` dengan border `SEMANTIC_DANGER` selama `3.0s`).

### 5.3. Game Over / After-Action Report (`game_over_menu.gd`)
* Muncul setelah jeda dramatis `0.6s` pasca ledakan tank pemain.
* Kartu *After-Action Combat Report* (`width: 460 px`) berisi:
  * Header `ARMOR DESTROYED` (`TYPE_DISPLAY`, `UI_TEXT_DANGER`) & sub-header `AFTER-ACTION COMBAT REPORT`.
  * **Procedural Performance Rank Stamp (`76 x 76 px`):** Stempel peringkat (`RANK S` >= 8000 pts, `RANK A` >= 4500 pts, `RANK B` >= 2000 pts, `RANK C` < 2000 pts) yang jatuh ke sudut kanan atas kartu dengan animasi *scale slam* (`2.2x -> 1.0x`, `0.22s`, rotasi `-6°`).
  * Tabel statistik 4 baris dengan latar selang-seling (`UI_BG_ELEVATED`): *Final Score* (disertai badge `NEW RECORD!` jika memecahkan rekor), *Sector Reached*, *Outposts Captured*, dan *Ricochet Kills*.
  * Tombol `REDEPLOY` & `MAIN MENU` dengan **`0.8s` Input Lockout Protection** sebelum `REDEPLOY` maupun pintasan `Space` / `Enter` dapat ditekan.