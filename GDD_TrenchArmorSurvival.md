# Game Design Document (GDD): Trench Armor Survival

## 1. Game Overview & Design Pillars

### 1.1. Game Identity
* **Title:** Trench Armor Survival (Working Title)
* **Genre:** Top-Down Arcade Shooter, Endless Arena Survival, Tactical Action
* **Target Platform:** PC (Windows/Linux via Keyboard & Mouse)
* **Perspective:** 2D Top-Down Orthographic
* **Art Style:** Stylized 2D WW1/WW2 Gritty Military (100% Zero Frame-by-Frame Animation)

### 1.2. Elevator Pitch
A fast-paced arcade survival game set on a WW1/WW2-era battlefield, where the player controls an armored tank with independently controlled hull movement and cannon aiming. Survive waves of enemy war machines by using bullet ricochets off steel barricades to destroy enemies from unexpected angles. The entire combat experience is delivered through momentum-based physics, thick smoke, mud, and particle effects, without using any frame-by-frame sprite animation.

### 1.3. Design Pillars
1. **Tactical Ricochet:** Shooting directly is ordinary; using steel-wall angles to destroy enemies from unexpected directions is the core of the gameplay experience.
2. **Heavy Mechanical Feel:** Although the game is 2D and uses no character animation, the tank must feel heavy, powerful, and deadly through recoil, muddy track marks, camera shake, and booming audio.
3. **Readable Chaos:** Amid large amounts of smoke, projectiles, and explosions, the silhouettes of key objects (player, enemies, and active bullets) must remain high-contrast and immediately readable.

---

## 2. Core Gameplay Loop & Game States

1. **Deployment (Start):** The player spawns at the center of a battlefield arena surrounded by barricades.
2. **Engagement (Combat):** Waves of enemy armored vehicles enter from outside the arena boundaries and begin hunting the player.
3. **Execution (Maneuver & Ricochet):** The player maneuvers to avoid being surrounded, finds direct or ricochet firing angles, and destroys targets.
4. **Escalation (Progression):** Each destroyed enemy increases the player's score (with a multiplier for ricochet shots). As time passes, enemy spawn intervals become shorter and enemy types become more dangerous.
5. **Resolution (Game Over):** When the player's Armor Integrity (HP) reaches $0$, the player's tank explodes, the game stops, the final combat statistics are displayed, and the player is given the option to Deploy Again (Restart).

---

## 3. Player Mechanics & Balancing Metrics

### 3.1. Dual-Entity Control System
The player tank consists of two static visual components that rotate independently:
* **Hull (Tank Body):** Controlled using `W, A, S, D` or `Arrow Keys` (8-directional movement). The hull smoothly interpolates to face its current movement vector.
* **Turret (Cannon Assembly):** Rotates instantly and continuously to track the `Mouse` cursor position.
* **Reticle (Cursor Aim):** The system mouse cursor is replaced with a military-style crosshair icon.

### 3.2. Combat & Ricochet Mechanics
* **Primary Fire:** Left-click to fire a high-velocity cannon projectile.
* **Ricochet Rule:** When a player bullet hits an arena boundary wall or steel barricade, it bounces according to the law of perfect reflection, where the angle of incidence equals the angle of reflection ($\theta_i = \theta_r$).
* **Ricochet Limit & Bonus:** A bullet can bounce a maximum of $1\text{ time}$ (it is destroyed on its second wall impact). After bouncing once, the bullet changes color to bright orange (heated metal effect) and grants **2x Score** if it successfully kills an enemy.
* **No Self-Damage:** Bouncing player bullets cannot damage the player, allowing aggressive trick shots in tight spaces.

### 3.3. Player Parameter Table

| Parameter | Value | Unit | Description |
| :--- | :--- | :--- | :--- |
| Max HP | 3 | Hit Points | Number of hits the player can take before being destroyed |
| Move Speed | 220 | Pixels/second | Maximum movement speed |
| Hull Turn Speed | 10 | Radians/second | Hull rotation speed while turning |
| Fire Cooldown | 0.45 | Seconds | Delay between cannon shots |
| Recoil Force | 40 | Pixels | Instant backward impulse when firing |
| Bullet Speed | 650 | Pixels/second | Player projectile speed |
| Max Bounces | 1 | Bounces | Maximum number of wall bounces per bullet |
| I-Frames Duration | 1.2 | Seconds | Temporary invulnerability duration after taking damage |

---

## 4. Enemy Design & AI Behavior

All enemies use static images without animation and are destroyed by $1\text{ player shot}$, except for the Heavy Armor type.

### 4.1. Archetypes
1. **Scout Car "Rammer" (Fast Melee):**
   * **Visual:** A light armored car without a cannon, painted dull brown, with a spiked front bumper.
   * **Behavior:** Continuously moves straight toward the player's position.
   * **Attack:** Rams the player's hull head-on (deals $1\text{ HP}$ damage to the player, then the enemy vehicle also explodes and is destroyed).
2. **Light Artillery Tank (Ranged Sniper):**
   * **Visual:** A box-shaped tank with a long cannon barrel, painted dark gray in a German/World War style.
   * **Behavior:** Slowly moves into the arena. It stops completely when it is within $\le 350\text{ pixels}$ of the player and begins rotating its cannon to aim at the player.
   * **Attack:** Fires a straight cannon projectile every $2.5\text{ seconds}$. Enemy bullets **cannot ricochet** off walls.
3. **Heavy Dreadnought (Slow Bruiser):**
   * **Visual:** A massive WW1 Mark V-style tank with thick armor plates.
   * **Behavior:** Moves very slowly toward the player while firing occasionally.
   * **Special Trait:** Has $2\text{ HP}$ against ordinary direct shots, but is destroyed instantly by $1\text{ Ricochet Shot}$ from the side/rear.

### 4.2. Enemy Parameter Table

| Enemy Type | HP | Speed (px/s) | Fire Rate (s) | Bullet Speed | Base Score |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Scout Rammer | 1 | 250 | Does not fire | 0 | 100 Points |
| Light Artillery | 1 | 110 | 2.5 | 400 px/s | 200 Points |
| Heavy Dreadnought | 2 | 70 | 3.5 | 350 px/s | 500 Points |

---

## 5. Arena, Obstacles & Camera Design

### 5.1. Arena & Camera Layout
* **Arena Size:** $1280 \times 720\text{ pixels}$ (one fixed full-screen view / fixed camera). The camera does not follow the player's movement; it only moves slightly when the Screen Shake effect occurs.
* **Perimeter Walls:** All four screen edges are enclosed by concrete and steel barricades, with open gate gaps on the outer boundary to allow enemies to enter.

### 5.2. Environmental Obstacles (Inside the Arena)
To maximize the bullet ricochet mechanic, the center of the arena contains $4\text{ to }6$ static obstacles:
1. **Steel Tank Traps / Bunkers (Indestructible):** Angled steel blocks that cannot be destroyed. They act as bullet-reflecting surfaces and permanent cover.
2. **Sandbag Barricades (Destructible):** Sandbag piles that block tanks and bullets, but are destroyed into pieces after receiving a total of $3\text{ bullet hits}$ (from either the player or enemies). Bullets **do not ricochet** off sandbags.
3. **Mud Craters (Terrain Hazard):** Dark, mud-filled blast craters on the ground. Bullets can pass over them, but tanks (player and enemies) moving through the mud have their movement speed reduced by $35\%$.

---

## 6. Pacing, Escalation & Spawner Logic

The game is not divided into levels. Instead, it is a single Endless session controlled by a time-based director:

* **Initial Spawn Interval:** $3.0\text{ seconds}$ per enemy.
* **Difficulty Scaling Formula:** Every $15\text{ seconds}$ of gameplay, the spawn interval is reduced by $0.15\text{ seconds}$ until it reaches the minimum cap of $0.8\text{ seconds}$ per enemy:
  $$T_{\text{spawn}} = \max(0.8, 3.0 - 0.15 \times \lfloor \frac{t}{15} \rfloor)$$
* **Enemy Spawn Phases:**
  * **0:00 – 0:45 (Early Skirmish):** $100\%$ Scout Rammer. The player gets used to movement controls and wall ricochets.
  * **0:45 – 1:30 (Artillery Barrage):** $70\%$ Scout Rammer, $30\%$ Light Artillery. The player is forced to take cover behind barricades and use ricochet shots.
  * **1:30+ (Total War):** $50\%$ Scout Rammer, $35\%$ Light Artillery, $15\%$ Heavy Dreadnought.

---

## 7. Art Style & Visual Feedback (Zero-Animation Strategy)

### 7.1. Color Palette (Stylized War Tones)
To maintain visual readability, object colors must be clearly differentiated:
* **Ground / Mud Environment:** Earthy Brown (`#4A3B32`) & Dark Mud (`#2E241E`).
* **Player Tank:** Olive Drab Green (`#556B2F`) with bright white star accents.
* **Enemy Units:** Rust Red (`#8B3A3A`) and Charcoal Grey (`#36393F`).
* **Projectiles:** Bright Brass Yellow (`#FFD700`) for normal bullets, Fiery Orange (`#FF5500`) for bullets after ricocheting, and Crimson Red (`#FF2222`) for enemy bullets.

### 7.2. Procedural Juice & VFX (No Character Animation)
* **Track Marks:** Double dark-brown lines appear on the ground following the tank tracks and fade out after $3\text{ seconds}$.
* **Muzzle Blast & Recoil:** When firing, a fire flash appears at the cannon muzzle for $0.08\text{ seconds}$, followed by a burst of thin gray smoke particles. Meanwhile, the cannon visual moves backward slightly and smoothly returns to its original position.
* **Ricochet Sparks:** When a bullet bounces off a steel wall, bright yellow line-shaped sparks appear and travel toward the reflection direction.
* **Destruction & Debris:** When a tank is destroyed, its visual disappears immediately and is replaced by:
  1. An explosion of orange fireball particles and thick black smoke.
  2. $3\text{ to }5$ small armor-plate fragments that are launched, spin, and settle on the ground as wreckage for several seconds.
  3. A black scorch mark on the ground where the tank exploded.
* **Hit Flash:** When an enemy or the player takes damage but is not destroyed, its entire sprite turns bright white (`#FFFFFF`) for $0.1\text{ seconds}$.
* **Screen Shake Matrix:**
  * Firing: Light shake ($2\text{ pixels}$, duration $0.1\text{ seconds}$).
  * Enemy Explosion: Medium shake ($5\text{ pixels}$, duration $0.2\text{ seconds}$).
  * Player Damaged: Heavy shake ($12\text{ pixels}$, duration $0.35\text{ seconds}$), plus Hit-Stop (the game freezes for $0.05\text{ seconds}$ to emphasize the impact).

---

## 8. Audio Direction (SFX & Music)

Since the visuals are static, sound design plays a major role in conveying mechanical weight:

### 8.1. Sound Effects (SFX) List
* **Cannon Fire:** A sharp, heavy cannon blast followed by the mechanical sound of a falling shell casing (*clink*).
* **Bullet Ricochet:** A distinctive bullet-on-metal sound (*"Piiiing!"* or *"Whizz!"*) with a high pitch. Randomize the pitch between $0.9\text{ and }1.1$ to avoid repetition.
* **Armor Hit / Tank Explosion:** A heavy metallic impact followed by a deep, bass-heavy explosion.
* **Tank Engine Loop:** A low diesel engine rumble while idle; its pitch increases when the player moves.

### 8.2. Background Music (BGM)
* Military Percussion / Industrial War Drums-style background music (primarily military snare drums and low brass instruments), at approximately $120\text{–}130\text{ BPM}$ to build adrenaline without interfering with the sound of bullet ricochets.

---

## 9. User Interface (UI) & Game Flow

### 9.1. Screen Flow
* **Title Screen:** Displays the game title over a WW2 tank blueprint background. Includes `DEPLOY (START)` and `QUIT` buttons, plus a brief visual control guide (`WASD` = Move, `Mouse` = Aim/Shoot).
* **In-Game HUD:**
  * **Top Left (Armor Integrity):** $3\text{ steel shield plate icons}$. When the player is hit, a shield icon breaks or turns black.
  * **Top Center (Score & Time):** Military stencil-style score text (`SCORE: 004500`) and survival time (`01:45`).
  * **Floating Text:** When an enemy is killed by a ricochet bullet, small text such as `+200 RICOCHET!` floats upward and fades at the enemy's destruction location.
* **Pause Menu:** Opened with `ESC`. Pauses the entire simulation and displays `RESUME`, `RESTART`, and `MAIN MENU` options.
* **Game Over Screen (MIA / Destroyed):** The screen dims with a sepia-brown tint and displays:
  * Header: `TANK DESTROYED`
  * Statistics: `Final Score`, `Time Survived`, and `Ricochet Kills`.
  * Buttons: `REDEPLOY (SPACE / CLICK)` and `MAIN MENU`.
