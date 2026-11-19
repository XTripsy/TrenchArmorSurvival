<!-- cover -->
<div align="center">

**LAPORAN FINAL PROJECT**

**GENERATIVE AI-ASSISTED GAME DEVELOPMENT**

Workshop Kecerdasan Buatan Generatif untuk Game

<br>

# Trench Armor Survival

<br>

[Nama Mahasiswa]

[NRP] / [Kelas]

[Tahun Akademik]

</div>
<!-- /cover -->

<!-- pagebreak -->

# IDENTITAS PROJECT

| Informasi | Isi |
| :--- | :--- |
| Judul Game | Trench Armor Survival |
| Nama / Tim | [Nama Mahasiswa] |
| NRP / Kelas | [NRP] / [Kelas] |
| Genre | Top-Down Arcade Shooter, Endless Arena Survival, Tactical Action |
| Format | 2D |
| Game Engine | Godot Engine 4.7 (GDScript) |
| Target Platform | PC (Windows/Linux), keyboard dan mouse |
| AI Tools | OpenCode (agentic coding) dengan plugin Superpowers; LLM melalui penyedia 9Router |

# BAB I - GAME CONCEPT

## 1.1 Deskripsi Game

Trench Armor Survival adalah game arcade survival 2D top-down berlatar medan perang Perang Dunia I dan II. Pemain mengendalikan satu tank lapis baja dengan dua bagian yang berputar terpisah: hull bergerak delapan arah memakai WASD atau tombol panah, sedangkan turret mengikuti posisi kursor. Musuh berupa kendaraan perang masuk dari empat gerbang arena secara bergelombang. Mekanik utamanya adalah tembakan ricochet: peluru yang memantul satu kali dari dinding baja atau bunker berubah menjadi oranye dan memberi skor dua kali lipat jika membunuh musuh. Pemain bertahan sampai tiga poin Armor Integrity habis, lalu dapat redeploy.

Seluruh visual dibangun dari geometri prosedural memakai Polygon2D, Line2D, dan CPUParticles2D. Seluruh audio disintesis lewat AudioStreamGenerator. Tidak ada sprite atau file audio eksternal di dalam proyek. Pendekatan ini menjaga proyek tetap ringan, konsisten dengan palet militer di GDD, dan memungkinkan gameplay diuji sebelum aset produksi dibuat. Proyek memakai Godot 4.7, GDScript dengan static typing, dan komunikasi antar sistem melalui empat autoload.

## 1.2 Target Player

1. Remaja hingga dewasa muda berusia 13 sampai 30 tahun yang mencari sesi arcade singkat.
2. Penggemar top-down shooter yang menikmati gerak cepat dan bidikan presisi.
3. Pemain yang suka trik sudut, bank shot, dan risiko terukur.
4. Penggemar tema militer Perang Dunia yang menyukai gaya stylized, bukan simulasi.
5. Pemain PC dengan keyboard dan mouse yang mengutamakan kontrol langsung.

## 1.3 Core Gameplay

Inti permainan adalah bertahan hidup sambil menciptakan peluang tembakan. Pemain membaca posisi musuh, memilih sudut, lalu memanfaatkan pantulan untuk menyerang dari arah yang tidak terlindungi. Gerak hull dan bidikan turret dipisah, sehingga pemain bisa mundur sambil tetap membidik. Recoil mendorong tank ke belakang, cooldown 0,45 detik membatasi laju tembakan, dan i-frame 1,2 detik memberi ruang untuk keluar dari kepungan. Tiga jenis musuh menuntut respons berbeda: Scout memaksa pemain terus bergerak, Artillery memaksa berlindung di balik cover, dan Dreadnought menghargai tembakan ricochet.

## 1.4 Core Loop

[[GAMBAR: Core Loop Game]]

*Gambar 1. Core Loop Game*

Alur core loop berjalan dalam satu sesi tanpa level terpisah:

1. Deploy: arena dimuat, run direset, pemain muncul di tengah arena.
2. Engage: musuh masuk lewat gerbang; pemain memilih target dan posisi.
3. Maneuver: pemain menghindari kepungan dan memakai bunker, sandbag, serta lumpur.
4. Ricochet: pemain menembak dinding untuk mendapatkan sudut kedua; peluru berubah oranye dan bernilai dua kali.
5. Escalate: skor naik, interval spawn memendek, dan tipe musuh menjadi lebih berat.
6. Resolve: armor habis, tank hancur, statistik akhir tampil, lalu pemain memilih redeploy atau main menu.

## 1.5 Character & Environment

| Komponen | Deskripsi |
| :--- | :--- |
| Character | Tank pemain berwarna Olive Drab (#556B2F) dengan bintang putih. Hull dan turret adalah visual statis dari Polygon2D dan Line2D, tanpa animasi frame-by-frame. Hitbox 36 x 36 piksel. |
| Environment | Arena tetap 1280 x 720 piksel dengan latar #4A3B32. Empat dinding perimeter memiliki gerbang selebar 80 piksel. Di dalam arena ada 4 steel bunker bersudut 45 derajat, 3 sandbag barricade, dan 3 mud crater. |
| Gameplay Object | Peluru pemain #FFD700 yang berubah #FF5500 setelah memantul, peluru musuh #FF2222, jejak roda, scorch mark, pecahan armor, ikon perisai HUD, dan reticle prosedural. |

[[GAMBAR: Character / Environment]]

*Gambar 2. Character / Environment*


# BAB II - PEMANFAATAN GENERATIVE AI

## 2.1 AI yang Digunakan

| Tahap | Tool / Model | Kegunaan |
| :--- | :--- | :--- |
| Game Design | OpenCode + LLM melalui 9Router | Menyusun GDD, TAD, dan TODO terstruktur dari brief desain, lalu memecah pekerjaan menjadi fase dan task dengan Definition of Done. |
| Visual / 2D / 3D | Tidak memakai model image generator; kode prosedural ditulis oleh agen | Membangun seluruh visual 2D dari Polygon2D, Line2D, dan CPUParticles2D dengan warna sesuai GDD. Tidak ada aset 3D. |
| Programming | OpenCode + plugin Superpowers | Menulis seluruh GDScript, file .tscn, autoload, dan harness pengujian. Plugin menyediakan alur brainstorming, perencanaan, eksekusi bertahap, dan review subagent. |
| Audio | Tidak memakai model audio generatif; AudioStreamGenerator | Menyintesis cannon, ricochet, explosion, hit, engine loop, dan BGM 125 BPM langsung dari kode, tanpa file wav atau ogg. |
| Debugging / Testing | OpenCode + Godot CLI headless | Menjalankan validasi `--headless --editor --quit` dan `--headless --quit`, membaca parse error, membuat harness per fase, lalu memperbaiki temuan sampai PASS. |

Nama model LLM mengikuti penyedia yang dikonfigurasi di lingkungan kerja, yaitu 9Router. Jika sesi yang dipakai berbeda, ganti nama model pada tabel dengan model yang tercatat di riwayat sesi. Pipeline yang dapat diverifikasi dari isi repo adalah OpenCode dengan plugin Superpowers, bukan model tertentu.

## 2.2 Contoh Prompt dan Output

| No | Kebutuhan | Prompt | Keputusan |
| :--- | :--- | :--- | :--- |
| 1 | Fondasi desain | Susun GDD dan TAD untuk game top-down tank survival 2D di Godot 4.2+ dengan mekanik ricochet, tanpa aset eksternal, lalu pecah menjadi TODO per fase. | Dipakai. Menghasilkan GDD, TAD, dan TODO yang menjadi kontrak kerja. |
| 2 | Struktur proyek | Buat project.godot 1280x720 dengan 6 input action, 6 physics layer, dan 4 autoload EventBus, GameManager, VFXManager, AudioManager sesuai TAD. | Dipakai setelah revisi minor pada stub autoload. |
| 3 | Player controller | Implementasikan player.gd dengan gerak 8 arah, hull mengikuti arah gerak, turret mengikuti mouse, cooldown 0,45 detik, recoil, i-frame 1,2 detik, dan tread mark. | Direvisi. Kontrak `direction` peluru harus diisi sebelum `add_child` agar peluru tidak diam. |
| 4 | Ricochet | Buat player_bullet.gd yang memantul satu kali dari grup bouncy_surface, berubah warna #FF5500, dan memberi skor 2x. | Dipakai setelah harness Phase 3 lulus. |
| 5 | Audio tanpa aset | Buat AudioManager dengan AudioStreamGenerator untuk cannon, ricochet, explosion, dan engine loop, tanpa error jika file audio tidak tersedia. | Direvisi. One-shot terpotong buffer dan voice pool perlu perbaikan. |
| 6 | Perbaikan kursor | Perbaiki kursor sistem yang tetap tersembunyi saat pause dan game over sehingga tombol tidak bisa diklik dengan pointer yang terlihat. | Dipakai. Diverifikasi ulang di mode windowed. |

[[GAMBAR: Contoh hasil Generative AI]]

*Gambar 3. Contoh hasil Generative AI*

## 2.3 Human-in-the-Loop

Mahasiswa memegang keputusan yang tidak bisa diserahkan ke model:

- Menentukan konsep inti, tiga design pillar, tema Perang Dunia, skema kontrol hull dan turret, serta batasan tanpa animasi frame-by-frame.
- Memilih Godot 4.7 dan pendekatan zero-asset, lalu menetapkan TAD sebagai sumber kebenaran ketika GDD dan TAD bertentangan, misalnya nilai recoil dan aturan ricochet Dreadnought.
- Menyetujui rencana tiap fase sebelum eksekusi, meninjau hasil, dan meminta perbaikan ketika hasil belum sesuai.
- Menjalankan build windowed untuk menilai game feel, keterbacaan siluet, dan audio, karena agen tidak bisa melihat layar atau mendengar suara.
- Menetapkan batas lingkup, termasuk keputusan untuk tidak memakai MCP dan tidak memakai model gambar atau audio generatif.

Agen bekerja dengan protokol yang ditulis di TODO: satu task satu hasil, setiap task punya Definition of Done, fase dikerjakan berurutan, dan validasi headless wajib bersih sebelum lanjut. Manusia tetap menjadi pihak yang menerima atau menolak hasil tersebut.

# BAB III - AI AGENT & TECHNICAL ARCHITECTURE

## 3.1 Arsitektur

[[GAMBAR: Diagram AI Model - AI Agent - MCP/Tools - Project - Game Engine]]

*Gambar 4. AI Model → AI Agent → MCP/Tools → Project → Game Engine*

Hubungan antar komponen berjalan sebagai rantai umpan balik:

1. AI Model menerima prompt, dokumen proyek, dan potongan kode yang relevan.
2. AI Agent, yaitu OpenCode dengan plugin Superpowers, mengubah instruksi menjadi rencana dan tindakan pada file proyek.
3. Tools yang dipakai adalah tool bawaan agent untuk membaca, menulis, mengedit, mencari file, dan menjalankan shell, ditambah Godot CLI untuk validasi.
4. Project menyimpan dokumen kontrak (GDD, TAD, TODO, plan, progress), scene, script, dan autoload.
5. Game Engine menjalankan atau mengimpor proyek, mengembalikan parse error dan hasil tes, lalu hasil itu menjadi input untuk iterasi berikutnya.

Dokumen di folder proyek berfungsi sebagai memori jangka panjang. Setiap fase punya file rencana, desain, dan ledger eksekusi di `docs/superpowers/`, sehingga keputusan tidak bergantung pada satu percakapan yang panjang.

## 3.2 AI Agent

| Komponen | Penjelasan |
| :--- | :--- |
| Agent / Tool | OpenCode, agent coding berbasis CLI, dengan plugin Superpowers untuk alur kerja terstruktur. |
| Model | LLM yang diakses melalui penyedia 9Router. Nama model dapat disesuaikan dengan sesi yang dipakai. |
| Fungsi Agent | Membaca konteks repo, menulis GDScript dan .tscn, menyusun dokumen, membuat harness uji, menjalankan validasi Godot, dan merangkum temuan. |
| Input | Brief manusia, GDD, TAD, TODO, isi repo, output error Godot, dan hasil harness. |
| Output | File proyek, dokumen rencana dan ledger, laporan PASS/FAIL, serta patch perbaikan. |

## 3.3 MCP

Project tidak menggunakan MCP. Tidak ada MCP server, baik untuk Godot editor maupun untuk layanan eksternal. Agent berinteraksi langsung dengan project melalui tool bawaannya: membaca file, menulis dan mengedit file, mencari teks, serta menjalankan perintah shell. Konteks diberikan lewat prompt dan dokumen di repo, sedangkan verifikasi dilakukan lewat Godot CLI dan harness scene sementara.

Karena tidak ada MCP, agent tidak bisa mengklik editor Godot atau menginspeksi viewport secara langsung. Pekerjaan yang butuh pengamatan visual, rasa kontrol, atau pendengaran tetap dilakukan manusia melalui build windowed. Batas ini disengaja agar pipeline sederhana dan mudah direproduksi.

## 3.4 Hubungan dengan Game Engine

Agent membuat dan mengubah script serta scene dalam bentuk teks. Setelah perubahan, Godot dijalankan dengan `--headless --editor --quit` untuk memastikan proyek dapat diimpor tanpa parse error, lalu `--headless --quit` untuk smoke test main scene. Untuk fitur tertentu, agent membuat scene uji sementara di `res://tests/` yang memeriksa kontrak secara otomatis, misalnya jumlah pantulan, warna peluru, nilai skor, layer collision, dan transisi state.

Hasil pengujian dibaca dari output konsol. Jika ada error, agent memperbaiki file dan mengulang. Setelah harness PASS, manusia menjalankan game secara windowed untuk memeriksa hal yang tidak terukur oleh tes, seperti recoil yang terasa berat, keterbacaan peluru di antara asap, dan audio yang tidak terpotong. Harness kemudian dihapus agar folder `tests/` bersih. Pola ini memisahkan verifikasi otomatis dari penilaian game feel.


# BAB IV - IMPLEMENTASI GAME

## 4.1 Implementasi Gameplay

**Kontrol dan gerak.** Pemain memakai `Input.get_vector()` untuk membaca WASD atau tombol panah, lalu mengalikannya dengan `BASE_SPEED` 220 piksel per detik dan `speed_multiplier`. Hull diputar halus dengan `lerp_angle` pada `TURN_SPEED` 10 radian per detik hanya saat ada input. Turret memakai `look_at(get_global_mouse_position())`, sehingga bidikan selalu mengikuti kursor. Recoil diterapkan sebagai `_recoil_velocity` yang meluruh 900 piksel per detik kuadrat, bukan sebagai perubahan posisi langsung, agar dorongan terasa halus. Lumpur menurunkan `speed_multiplier` menjadi 0,65 selama tank berada di crater.

**Pertempuran dan ricochet.** Tembakan terjadi saat tombol kiri mouse ditekan dan cooldown 0,45 detik sudah habis. Peluru bergerak 650 piksel per detik, memantul maksimal satu kali dari objek bergrup `bouncy_surface`, lalu berubah warna dari #FFD700 menjadi #FF5500. Peluru yang membunuh musuh setelah memantul memberi skor dua kali dan menaikkan `ricochet_kills`. Peluru pemain tidak bisa melukai pemain karena layer player tidak ada di mask peluru. Peluru musuh berwarna #FF2222, tidak memantul, dan hancur saat mengenai dinding.

**Musuh.** Scout Rammer berkecepatan 250 piksel per detik mengejar langsung dan meledak setelah menabrak pemain. Light Artillery berhenti pada jarak 350 piksel, membidik, lalu menembak tiap 2,5 detik dengan peluru 400 piksel per detik. Heavy Dreadnought berjalan lambat, menembak tiap 3,5 detik, tahan dua tembakan langsung, tetapi mati seketika oleh satu peluru ricochet.

**Arena dan gelombang.** Arena berukuran tetap 1280 x 720 dengan kamera di (640, 360). Empat dinding perimeter memiliki gerbang 80 piksel dan marker spawn di luar layar. Wave Director menghitung interval dengan `max(0.8, 3.0 - 0.15 * floor(t / 15))` dan memilih tipe musuh berdasarkan waktu: 100 persen Scout sebelum 45 detik, 70 persen Scout dan 30 persen Artillery pada 45 sampai 90 detik, lalu 50 persen Scout, 35 persen Artillery, dan 15 persen Dreadnought setelah 90 detik.

**UI dan alur state.** Main menu memuat grid blueprint prosedural, tombol DEPLOY dan QUIT, serta panduan kontrol. HUD menampilkan tiga ikon perisai, skor enam digit, waktu MM:SS, dan reticle yang hanya muncul saat state PLAYING. Pause menu dibuka dengan Esc dan menyediakan RESUME, RESTART, serta MAIN MENU. Game over menampilkan skor akhir, waktu bertahan, jumlah ricochet kill, lalu tombol REDEPLOY dan MAIN MENU.

**Umpan balik visual dan audio.** Muzzle flash, asap, percikan ricochet, ledakan, pecahan armor, scorch mark, tread mark, hit flash, screen shake, dan hit-stop dijalankan oleh VFXManager dan GameManager. Screen shake memakai nilai berbeda untuk tembakan, ledakan musuh, dan damage pemain. Semua suara disintesis dari kode, termasuk engine loop yang pitch-nya naik saat tank bergerak.

[[GAMBAR: Gameplay]]

*Gambar 5. Gameplay*

## 4.2 Implementasi Asset

| Asset | Format | Sumber / AI | Keterangan |
| :--- | :--- | :--- | :--- |
| Character | 2D | Prosedural, kode dibuat dengan bantuan AI | Hull, turret, barrel, dan bintang putih disusun dari Polygon2D dan Line2D. Tidak ada file gambar. |
| Environment | 2D | Prosedural, kode dibuat dengan bantuan AI | Dinding, bunker, sandbag, crater, dan grid menu memakai Polygon2D dan Line2D dengan warna dari GDD. |
| Prop | 2D | Prosedural, kode dibuat dengan bantuan AI | Scorch mark, pecahan armor, asap, api, dan percikan memakai Polygon2D dan CPUParticles2D dengan tekstur gradien prosedural. |
| Audio | Prosedural | Sintesis AudioStreamGenerator, kode dibuat dengan bantuan AI | Cannon, ricochet, explosion, hit, engine, dan BGM 125 BPM dirender saat runtime pada 22.050 Hz. Tidak ada file wav atau ogg. |

## 4.3 Implementasi Game Engine

Proyek memiliki 17 scene dan 21 skrip GDScript. Scene utama adalah `main_menu.tscn` dan `arena.tscn`. Arena memuat Player, Enemies, WaveDirector, Camera2D, HUD, PauseMenu, dan GameOverMenu. Empat autoload menjadi tulang punggung: EventBus menyimpan 7 signal bertipe, GameManager mengatur state dan skor, VFXManager membuat efek, dan AudioManager mengelola 8 voice audio.

Struktur node player terdiri dari `CharacterBody2D` dengan `CollisionShape2D` 36 x 36, `HullVisual`, `TurretPivot` yang berisi `TurretVisual` dan `MuzzleMarker`, serta `TreadTimer` 0,05 detik. Scene musuh memakai `BaseEnemy` sebagai parent class, sehingga logika damage dan kematian tidak diduplikasi. Sandbag memakai `StaticBody2D` dengan 3 HP, sedangkan mud crater memakai `Area2D` yang mengubah `speed_multiplier` saat body masuk dan keluar.

Collision dibagi menjadi enam layer:

| Layer | Nama | Objek | Mask |
| :--- | :--- | :--- | :--- |
| 1 | Player | Player | 2, 3, 5, 6 |
| 2 | Enemy | Scout, Artillery, Dreadnought | 1, 2, 3, 4, 6 |
| 3 | Environment | Dinding, bunker, sandbag | Tidak perlu |
| 4 | PlayerBullet | Peluru pemain | 2, 3 |
| 5 | EnemyBullet | Peluru musuh | 1, 3 |
| 6 | TerrainHazard | Mud crater | 1, 2 |

Grup node dipakai untuk lookup dan aturan permainan: `player`, `bouncy_surface`, `destructible_cover`, dan `spawn_gate`. Urutan z-index menjaga keterbacaan: ground -100, tread mark -2, scorch -1, debris 5, smoke 9, fire 10, sparks 15, dan peluru 20. Semua variabel, parameter, dan return type memakai tipe eksplisit. Komunikasi lintas sistem hanya lewat EventBus, sehingga tidak ada path `get_node("../..")` yang rapuh.

# BAB V - TESTING & EVALUATION

## 5.1 Functional Testing

| Fitur | Pengujian | Hasil | Status |
| :--- | :--- | :--- | :--- |
| Movement | WASD dan tombol panah, rotasi hull halus, tabrakan dinding, perlambatan lumpur 0,65x dan pemulihannya. | Harness Phase 2, 5, dan 6 lulus; audit windowed mengonfirmasi gerak dan lumpur. | Pass |
| Interaction | Cooldown 0,45 detik, recoil, pantulan satu kali, perubahan warna, skor 2x, tanpa self-damage, peluru musuh tidak memantul. | Harness Phase 3 lulus; audit windowed mengonfirmasi ricochet nyata di arena. | Pass |
| Gameplay | Tiga tipe musuh, ambang jarak Artillery, interval dan probabilitas wave, sandbag 3 hit, Dreadnought 2 hit langsung atau 1 ricochet, HUD dan skor. | Harness Phase 4 sampai 7 lulus; Phase 6 mencatat 167/167 pemeriksaan. | Pass |
| Audio | SFX terpicu pada event yang benar, pitch engine idle dan moving, BGM hanya saat PLAYING, pemulihan voice setelah pool penuh. | Harness Phase 8 lulus 74/74; verifikasi windowed untuk mendengar hasil nyata. | Pass |
| Completion | Pause, resume, restart, main menu, game over, redeploy, dan restart berulang tanpa sisa state. | Phase 7 restart 5/5; audit 53/53 headless dan 59/59 windowed. | Pass |

Angka pada kolom Hasil berasal dari harness headless yang tercatat di TODO proyek, ditambah audit windowed. Checklist playtest manual Phase 9 (T-039 sampai T-041) belum dicentang. Status Pass di sini berarti fitur lolos uji otomatis dan audit windowed, bukan jaminan bahwa QA rilis sudah selesai.

## 5.2 Evaluasi Generative AI

| Output AI | Masalah / Kelebihan | Tindakan |
| :--- | :--- | :--- |
| AudioManager one-shot | Suara terpotong karena voice dihentikan saat buffer masih berisi audio yang belum terdengar. Struktur pool dan API sudah rapi. | Direvisi dengan tail senyap 0,25 detik dan reset `volume_db`. |
| Partikel prosedural | CPUParticles2D tanpa tekstur sehingga efek tidak terlihat. | Direvisi memakai GradientTexture2D dan color ramp alpha. |
| Floating text | `setup()` dipanggil sebelum node masuk tree sehingga posisi dan tween salah. | Direvisi: `setup()` setelah `add_child`, lalu set `global_position`. |
| Collision mask musuh | Scene memakai mask 61, sedangkan TAD menetapkan 47. | Direvisi agar sesuai layer 1, 2, 3, 4, 6. |
| Kursor pause dan game over | Kursor tetap tersembunyi sehingga tombol tidak punya pointer yang terlihat. | Direvisi di `pause_menu.gd` dan `game_over_menu.gd`, diverifikasi windowed. |
| Harness pengujian | Beberapa tes mengukur velocity sebelum dua physics frame sehingga hasilnya keliru. | Direvisi pada harness, bukan pada gameplay. |
| Konflik GDD dan TAD | Nilai recoil dan aturan ricochet Dreadnought berbeda antar dokumen. | Diputuskan: TAD menjadi acuan, keputusan dicatat di bagian Decisions and Notes. |

## 5.3 Keterbatasan AI

- Model tidak bisa melihat layar atau mendengar audio. Uji headless memakai audio driver dummy, jadi kualitas rasa dan suara tetap harus dinilai manusia secara windowed.
- Pengetahuan model tentang API engine bisa tertinggal dari versi yang dipakai. Proyek berjalan di Godot 4.7, sehingga setiap API perlu diverifikasi lewat dokumentasi dan parser engine.
- Kualitas keluaran sangat bergantung pada spesifikasi. Dokumen yang ambigu menghasilkan rework, seperti mask collision dan `autostart` timer yang berbeda antara scene dan desain.
- Model bisa menghasilkan kode yang lolos parse tetapi salah secara perilaku. Harness otomatis dan review manusia tetap diperlukan.
- Model cenderung memilih solusi yang terlihat masuk akal, bukan solusi yang paling sederhana. Beberapa bug muncul dari urutan operasi yang halus, misalnya pengisian `direction` peluru sebelum `add_child`.
- Tanpa MCP, agent tidak bisa mengoperasikan editor Godot. Semua interaksi dengan engine terjadi lewat file dan CLI.
- Keputusan subjektif seperti game feel, tingkat kesulitan, dan prioritas polish tidak bisa diserahkan sepenuhnya ke model.


# BAB VI - HKI, LISENSI & AI DISCLOSURE

## 6.1 Asset & License

| Asset | Sumber / Tool | License / Status |
| :--- | :--- | :--- |
| Character | Dibuat prosedural dari Polygon2D dan Line2D di dalam proyek | Original, milik proyek. Tidak memakai aset pihak ketiga. |
| Environment | Dibuat prosedural dari Polygon2D dan Line2D di dalam proyek | Original, milik proyek. Tidak memakai aset pihak ketiga. |
| 3D Asset | Tidak digunakan karena game berformat 2D | Tidak berlaku |
| Audio | Disintesis dengan AudioStreamGenerator di dalam proyek | Original, milik proyek. Tidak memakai sampel atau musik pihak ketiga. |
| Game Engine | Godot Engine 4.7 | MIT License |
| Plugin AI | Superpowers untuk OpenCode | MIT License |

Karena seluruh visual dan audio dibuat dari kode, proyek tidak membawa lisensi aset eksternal. Ketergantungan pihak ketiga hanya engine dan plugin pengembangan, yang keduanya memakai lisensi MIT.

## 6.2 AI Disclosure

Bagian yang dibuat atau dibantu AI:

- GDD, TAD, dan TODO disusun oleh agent dari brief manusia. Manusia menetapkan konsep, pillar, tema, kontrol, dan batasan scope, lalu meninjau serta menyetujui dokumen.
- Seluruh GDScript, file .tscn, autoload, dan harness pengujian ditulis oleh agent. Manusia meminta perubahan, menjalankan build, dan memutuskan hasilnya diterima atau tidak.
- Visual prosedural ditulis sebagai kode oleh agent berdasarkan palet dan aturan visual di GDD. Tidak ada model gambar generatif yang dipakai.
- Audio prosedural ditulis sebagai kode oleh agent. Tidak ada model audio generatif yang dipakai. Manusia menilai hasil dengar di build windowed.
- Dokumen rencana, desain, dan ledger di `docs/superpowers/` dihasilkan dalam alur kerja agent, lalu dipakai sebagai catatan keputusan proyek.
- Laporan ini disusun oleh AI berdasarkan dokumen dan kode proyek. Mahasiswa perlu memeriksa ulang identitas, screenshot, dan kalimat akhir sebelum dikumpulkan.

Kontribusi manusia:

- Menentukan ide game, mekanik ricochet, tiga design pillar, dan arah visual militer stylized.
- Menetapkan Godot sebagai engine, GDScript static typing, zero-asset, dan penggunaan EventBus.
- Menyetujui atau menolak rencana tiap fase, serta memutuskan konflik antara GDD dan TAD.
- Menjalankan playtest windowed untuk menilai game feel, keterbacaan, dan audio.
- Memutuskan lingkup yang tidak dikerjakan, termasuk MCP dan aset eksternal.

# BAB VII - KESIMPULAN

## 7.1 Kesimpulan

Proyek berhasil membangun Trench Armor Survival sebagai game arcade survival 2D yang playable dari menu sampai game over. Delapan fase pengembangan (T-001 sampai T-038) selesai dengan 17 scene dan 21 skrip GDScript. Core loop berjalan penuh: deploy, combat, ricochet, eskalasi wave, kematian, dan redeploy. Seluruh visual dan audio dihasilkan dari kode tanpa aset eksternal, dan seluruh sistem berkomunikasi lewat EventBus.

Hasil pengujian otomatis dan audit windowed menunjukkan fitur utama berjalan sesuai desain: ricochet satu kali dengan skor 2x, tiga tipe musuh dengan perilaku berbeda, sandbag yang hancur pada hit ketiga, lumpur yang memperlambat 35 persen, serta alur pause, restart, dan game over yang bersih. Tahap QA rilis dan playtest manual formal masih terbuka.

## 7.2 Evaluasi Penggunaan GenAI

Bagian yang paling membantu adalah pembuatan kode boilerplate dan struktur proyek: autoload, scene, collision layer, signal, dan harness pengujian. Agent juga membantu menjaga konsistensi arsitektur lintas fase karena dokumen rencana dan TODO menjadi konteks yang dapat dibaca ulang. Iterasi RED ke GREEN pada harness mempercepat penemuan bug yang sulit dilihat dari kode saja.

Bagian yang masih membutuhkan banyak intervensi manusia adalah keputusan desain dan game feel. Model tidak bisa merasakan recoil, menilai apakah ledakan terlalu ramai, atau mendengar apakah suara terpotong. Verifikasi API engine juga menuntut koreksi manual. Beberapa bug muncul dari detail urutan operasi dan konfigurasi scene yang tidak terlihat dari deskripsi tugas, sehingga review manusia dan pengujian nyata tetap menjadi penentu.

## 7.3 Pengembangan Selanjutnya

- Menyelesaikan Phase 9: checklist playtest manual, pemeriksaan performa, README, dan export preset Windows serta Linux.
- Mengganti visual dan audio prosedural dengan aset final jika arah seni sudah stabil, tanpa mengubah kontrak gameplay.
- Menambahkan high score persisten di `user://` dan pengaturan volume.
- Menerapkan pemeriksaan sudut impact untuk Dreadnought agar ricochet hanya mematikan dari samping atau belakang, sesuai backlog.
- Menambah dukungan remap tombol dan gamepad untuk memperluas aksesibilitas.
- Menyesuaikan balancing berdasarkan data playtest, terutama interval spawn dan jumlah musuh aktif.

# DAFTAR PUSTAKA / REFERENSI

1. Godot Engine Documentation. https://docs.godotengine.org (diakses 19 November 2026).
2. GDScript Reference. https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/ (diakses 19 November 2026).
3. OpenCode. https://opencode.ai (diakses 19 November 2026).
4. Jesse Vincent. Superpowers. https://github.com/obra/superpowers (diakses 19 November 2026).
5. Dokumen internal proyek: `GDD_TrenchArmorSurvival.md`, `TECHNICAL_ARCHITECTURE_TrenchArmorSurvival.md`, `TODO_TrenchArmorSurvival.md`.
6. Dokumen rencana dan desain internal: `docs/superpowers/plans/` dan `docs/superpowers/specs/`.

# LAMPIRAN

## Lampiran A - AI Production Log

| No | Tahap | Tool / Model | Prompt | Output | Keputusan |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | Fase 0 Project Setup | OpenCode + LLM | Siapkan project Godot 1280x720, input map, layer, dan autoload. | project.godot dan 12 folder proyek | Dipakai |
| 2 | Fase 1 Autoload | OpenCode + LLM | Buat EventBus, GameManager, VFXManager, AudioManager sesuai TAD. | 4 autoload dan review fix | Direvisi |
| 3 | Fase 2 Player | OpenCode + LLM | Implementasikan gerak, turret, tembakan, damage, dan tread mark. | player.tscn, player.gd, tread_mark.tscn | Direvisi |
| 4 | Fase 3 Projectiles | OpenCode + LLM | Buat peluru pemain dengan satu pantulan dan peluru musuh tanpa pantulan. | Dua scene dan dua script peluru | Dipakai |
| 5 | Fase 4 Enemies | OpenCode + LLM | Buat BaseEnemy dan tiga tipe musuh dengan statistik dari GDD. | Empat script dan tiga scene musuh | Direvisi |
| 6 | Fase 5 Environment | OpenCode + LLM | Buat bunker, sandbag, dan mud crater beserta aturan collision. | Tiga scene environment dan dua script | Direvisi |
| 7 | Fase 6 Arena | OpenCode + LLM | Susun arena, kamera shake, dan wave director berbasis waktu. | arena.tscn, camera_shake.gd, wave_director.gd | Dipakai |
| 8 | Fase 7 UI | OpenCode + LLM | Buat main menu, HUD, pause, game over, dan floating text. | Lima scene UI dan lima script | Direvisi |
| 9 | Fase 8 Audio | OpenCode + LLM | Tambahkan SFX, engine loop, BGM, dan polish keterbacaan. | audio_manager.gd dan perbaikan z-order | Direvisi |
| 10 | Audit dan verifikasi | OpenCode + Godot CLI | Jalankan audit end-to-end dan perbaiki temuan. | Perbaikan kursor dan laporan PASS | Dipakai |

## Lampiran B - Screenshot Proses

[[GAMBAR: Screenshot proses AI / Agent]]

*Screenshot proses AI / Agent*

[[GAMBAR: Screenshot proses game engine]]

*Screenshot proses game engine*

[[GAMBAR: Screenshot debugging / testing]]

*Screenshot debugging / testing*

[[GAMBAR: Screenshot final gameplay]]

*Screenshot final gameplay*

## Lampiran C - Link Project

| Item | Link / Lokasi |
| :--- | :--- |
| Source Project | [ISI LINK REPOSITORY ATAU LOKASI FOLDER] |
| Playable Build | [ISI LINK BUILD ATAU TULIS BELUM TERSEDIA] |
| Video Demo | [ISI LINK VIDEO ATAU TULIS BELUM TERSEDIA] |
