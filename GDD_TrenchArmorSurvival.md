# Game Design Document (GDD): Trench Armor Survival (Playtest Edition)

## 1. Game Overview & Design Pillars

### 1.1. Game Identity
* **Title:** Trench Armor Survival (Playtest Build)
* **Genre:** Top-Down Arcade Shooter, Boss Encounter, Territory Invasion, Arena Survival
* **Target Platform:** PC (Windows/Linux via Keyboard & Mouse)
* **Perspective:** 2D Top-Down Orthographic
* **Art Style:** Stylized 2D WW1/WW2 Gritty Military (100% Zero Frame-by-Frame Animation)

### 1.2. Elevator Pitch
A fast-paced arcade action-survival game set on a stylized WW1/WW2 battlefield where the player commands an armored tank with independent hull movement and turret aiming. Fight through skirmish waves to draw out a heavy **Boss**, shatter the outer perimeter upon defeating it to **expand the battlefield**, and launch a **Territory Invasion** to capture fortified zones across the enlarged map.

### 1.3. Design Pillars
1. **Tactical Ricochet:** Direct fire handles light threats, while bouncing shots off steel walls (1 bounce, fiery orange `#FF5500`, 2x score and bonus damage against heavy/boss armor) unlocks angles behind cover.
2. **Escalating Battlefield (Skirmish → Boss → Expansion → Invasion):** Combat scales from a tight initial arena (`1280x720`) into a boss duel, then opens into a wider warzone (`2560x1440`) with active capture objectives so the playtest feels expansive and goal-driven.
3. **Heavy Mechanical Feel & Readable Chaos:** Recoil, muddy track marks, hit-stop, screen shake, and synthesized/procedural audio deliver weight without sprite-sheet animations, while silhouettes and objective pointers keep the expanded map readable.

---

## 2. Core Gameplay Loop & Progression Phases

A playtest run progresses through structured escalating phases per sector (with looping escalation if a sector is cleared):

1. **Deployment (Start):** The player spawns at the center of the **Inner Sector** (`1280x720`) surrounded by barricades and destructible expansion barriers.
2. **Phase 1 — Skirmish & Threat Escalation:** Enemy waves enter through gates and build up the **Threat / Boss Gauge** as enemies are destroyed.
3. **Phase 2 — Boss Encounter ("Iron Goliath"):** Once the Threat Gauge reaches `100%`, regular wave pressure eases/shifts and the **Boss** enters to anchor the sector boundary.
4. **Phase 3 — Map Expansion:** Destroying the Boss blasts open/removes the inner sector expansion walls, expands the playable arena & camera bounds into the **Outer Expansion Sector** (`2560x1440`), and activates **3 Capture Zones (Invasion Objectives)** with defenders.
5. **Phase 4 — Territory Invasion:** The player pushes into the expanded map to capture all **3 Capture Zones** (holding inside each zone while clearing/contesting enemies), earning score, zone capture rewards, and `+1 HP` recovery per captured zone (up to `MAX_HP`).
6. **Sector Clear / Loop or Game Over:**
   * Capturing all zones in the sector completes the invasion objective, grants a sector clear bonus, and escalates into the next cycle/sector (`Sector +1`) with tougher scaling.
   * Reaching `0 HP` in any phase triggers **Game Over** with final stats and instant **Redeploy**.

---

## 3. Player Mechanics & Balancing Metrics

### 3.1. Dual-Entity Control System
The player tank consists of two static visual components that rotate independently:
* **Hull (Tank Body):** Controlled using `W, A, S, D` or `Arrow Keys` (8-directional movement). The hull smoothly interpolates to face its current movement vector (`TURN_SPEED = 10.0 rad/s`).
* **Turret (Cannon Assembly):** Rotates continuously to track the `Mouse` cursor position.
* **Reticle (Cursor Aim):** The system mouse cursor is replaced with a military crosshair in `PLAYING`, and restored in menus and overlays.

### 3.2. Combat & Ricochet Mechanics
* **Primary Fire:** Left-click (`shoot`) to fire a high-velocity cannon projectile (`650 px/s`, `0.45s` cooldown).
* **Ricochet Rule:** When a player bullet hits a steel wall or bunker (`"bouncy_surface"`), it bounces once ($\theta_i = \theta_r$), turns bright orange (`#FF5500`), and grants **2x Score** on kills (plus bonus damage against the Boss). It is destroyed on its second wall impact.
* **No Self-Damage:** Bouncing player bullets cannot damage the player.

### 3.3. Player Parameter Table

| Parameter | Value | Unit | Description |
| :--- | :--- | :--- | :--- |
| Max HP | 3 | Hit Points | Base armor integrity; capturing an Invasion Zone restores +1 HP (up to Max HP) |
| Move Speed | 220 | Pixels/second | Base movement speed (`0.65x` inside Mud Craters) |
| Hull Turn Speed | 10 | Radians/second | Hull rotation speed while moving |
| Fire Cooldown | 0.45 | Seconds | Delay between primary cannon shots |
| Recoil Force | 40 | Pixels | Backward impulse scalar when firing |
| Bullet Speed | 650 | Pixels/second | Player projectile speed |
| Max Bounces | 1 | Bounces | Maximum wall bounces before destruction on next impact |
| I-Frames Duration | 1.2 | Seconds | Invulnerability window after taking damage |

---

## 4. Enemy Design, Boss & Invasion Defenders

### 4.1. Standard Archetypes
1. **Scout Car "Rammer" (`HP: 1`, `Speed: 250`, `Score: 100`):** Light armored car with spiked bumper; rushes straight toward the player and explodes on contact for `1` damage.
2. **Light Artillery Tank (`HP: 1`, `Speed: 110`, `Fire: 2.5s`, `Bullet: 400`, `Score: 200`):** Stops at `<= 350 px` from the player and fires straight non-ricocheting shells.
3. **Heavy Dreadnought (`HP: 2`, `Speed: 70`, `Fire: 3.5s`, `Bullet: 350`, `Score: 500`):** Slow armored bruiser; requires `2` direct hits or `1` ricochet shot to destroy.

### 4.2. Boss Archetype: "Iron Goliath"
* **Role:** Sector Guardian that gates Map Expansion.
* **Visual & Scale:** Oversized heavy tank (`~2.4x` player scale, `#36393F` / `#8B3A3A` armor plating, high-contrast outline).
* **Stats & Combat Behavior:**
  * **HP:** `16` HP (`+4` HP per additional sector). Direct shot = `1` damage; ricochet shot = `2` damage.
  * **Attack Pattern 1 — Fan / Spread Volley:** Fires a 3-way spread of enemy projectiles toward the player.
  * **Attack Pattern 2 — Mortar Telegraph Zone:** Marks a circular danger zone on the ground with a brief warning telegraph before detonation, forcing movement.
  * **Attack Pattern 3 — Heavy Advance:** Advances steadily toward the player/center lane between volleys.
  * **Defeat:** Triggers explosion VFX, camera shake, hit-stop, score award (`1500` base score), and **Map Expansion**.

### 4.3. Invasion Defenders (Expansion Sector)
* **Pillbox / Outpost Turret (`HP: 3`, `Score: 300`):** Stationary emplacement guarding Capture Zones in the expanded arena, aiming at the player and firing periodic straight shells (`enemy_bullet`) until destroyed.
* **Patrol / Reinforcement Units:** Scout, Artillery, and Dreadnought units patrol or reinforce contested zones during Territory Invasion.

---

## 5. Arena, Map Expansion & Territory Invasion Mechanics

### 5.1. Inner Arena & Expanded Invasion Arena
* **Inner Sector (Skirmish & Boss):** `1280 x 720` pixels, enclosed by `SteelBunker` ricochet mirrors, `SandbagBarricade` cover, `MudCrater` hazards, and expandable border barriers.
* **Expanded Invasion Sector:** Expands to `2560 x 1440` pixels (`2x` width and `2x` height). Outer perimeter walls enclose the expanded map while inner expansion barriers open so the player can drive out into new quadrants.
* **Camera Behavior:** Centered within the `1280x720` inner sector during initial combat, then smoothly tracks the player clamped within the expanded `2560x1440` arena boundaries (plus screen shake offsets).

### 5.2. Territory Invasion (Capture Zones)
* **Layout:** `3` **Capture Zones** activate in distinct quadrants of the expanded sector outside the starting core.
* **Capture Rules:**
  * Each Capture Zone has a circular capture radius (`180 px`) rendered procedurally on the ground.
  * **Capturing:** When the player is inside the zone and no enemies are inside the zone, capture progress increases (`+15%/s`, ~`6.7s` to capture).
  * **Contested:** If an enemy enters the zone while progress `< 100%`, progress pauses and displays a `CONTESTED` state until enemies inside are cleared.
  * **Captured (`100%`):** Locks the zone as captured, triggers a visual pulse + floating text (`+500 ZONE CAPTURED!`), restores `+1 HP` to the player (up to `MAX_HP`), and counts toward **Sector Clear**.

### 5.3. Environmental Obstacles
* **Steel Bunker (`"bouncy_surface"`):** Indestructible angled steel blocks (`#36393F`) that reflect player bullets once.
* **Sandbag Barricade (`"destructible_cover"`):** `3 HP` cover; absorbs player and enemy bullets without bouncing and breaks on the 3rd hit.
* **Mud Crater (`"TerrainHazard"`):** Dark mud craters (`#2E241E`, `z_index = -1`); slows tanks by `35%` (`speed_multiplier = 0.65`), bullets unaffected.

---

## 6. Pacing, Escalation & Threat Progression

* **Skirmish Threat Progress:** Destroying enemies adds threat points (Scout `+10`, Artillery `+15`, Dreadnought `+25`) up to `100` to trigger the **Boss** encounter.
* **Wave Spawn Interval:** Preserves the time-based escalation formula with sector scaling:
  $$T_{\text{spawn}} = \max\left(0.65, 3.0 - 0.15 \times \lfloor \frac{t}{15} \rfloor - 0.1 \times (\text{sector} - 1)\right)$$
* **Enemy Spawn Phases (Within Skirmish):**
  * **0:00 – 0:45:** `100%` Scout Rammer.
  * **0:45 – 1:30:** `70%` Scout Rammer, `30%` Light Artillery.
  * **1:30+:** `50%` Scout Rammer, `35%` Light Artillery, `15%` Heavy Dreadnought.
* **Phase Transitions:**
  * **Skirmish → Boss:** Triggered at `100%` Threat Progress.
  * **Boss → Invasion:** Triggered upon Boss defeat; map expands to `2560x1440` and `3` Capture Zones activate until all `3` are captured.

---

## 7. Art Style, Visual Feedback & Navigation UI

### 7.1. Color Palette (Stylized War Tones)
* **Ground / Mud Environment:** Earthy Brown (`#4A3B32`) & Dark Mud (`#2E241E`).
* **Player Tank:** Olive Drab Green (`#556B2F`) with bright white star accents.
* **Enemy Units & Boss:** Rust Red (`#8B3A3A`) and Charcoal Grey (`#36393F`) with high-contrast silhouettes.
* **Projectiles:** Brass Yellow (`#FFD700`) normal bullets, Fiery Orange (`#FF5500`) ricochet bullets, Crimson Red (`#FF2222`) enemy bullets.
* **Capture Zones:** Tactical Amber (`#D9A738`) when neutral/capturing, Alert Red (`#FF4444`) when contested, Military Olive (`#6B8E23`) when captured.

### 7.2. Procedural Juice & VFX (No Character Animation)
* **Track Marks:** Double dark-brown lines (`#2E241E`) fading out over `3s`.
* **Muzzle Blast & Recoil:** `0.08s` muzzle flash, gray smoke burst, backward barrel tween, and hull recoil impulse.
* **Ricochet Sparks & Destruction:** `#FFD700` directional sparks on bounce; `#FF5500` fireballs, thick black smoke, $3\text{–}5$ debris fragments, and ground scorch marks on tank destruction.
* **Hit Flash & Screen Shake:** `0.1s` bright white hit flash; Firing (`2 px`, `0.1s`), Enemy Explosion (`5 px`, `0.2s`), Player Damaged (`12 px`, `0.35s` + `0.05s` hit-stop).

### 7.3. UI, Navigation & Screen Flow
* **Title Screen:** Blueprint grid background, `DEPLOY (START)` & `QUIT` buttons, control guide (`WASD` = Move, `Mouse` = Aim/Shoot).
* **In-Game HUD:**
  * **Top-Left:** Armor Integrity shield icons (`current_hp` / `MAX_HP`).
  * **Top-Center:** `SCORE: %06d`, survival timer `MM:SS`, and **Dynamic Objective Tracker** (`THREAT %` during Skirmish → `BOSS HP` bar during Boss → `ZONES CAPTURED: X/3` during Invasion).
  * **Off-Screen Zone Pointers & Minimap:** Edge-of-screen directional arrows pointing toward active uncaptured Capture Zones (or Boss when off-screen), paired with a compact corner minimap showing arena bounds, player, active zones, and boss/hostiles.
* **Pause Menu (`ESC`):** Pauses simulation with `RESUME`, `RESTART`, and `MAIN MENU`.
* **Game Over Screen:** Sepia-tinted overlay showing `TANK DESTROYED`, `Final Score`, `Time Survived`, `Ricochet Kills`, and `REDEPLOY` / `MAIN MENU` buttons.