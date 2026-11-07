# FRONTLINE — Godot 4 Mobile FPS Prototype (v0.3.0)

[![Build Godot 4 Android APK and Create Release](https://github.com/Bihan293/FRONTLINE_Godot/actions/workflows/build-apk.yml/badge.svg)](https://github.com/Bihan293/FRONTLINE_Godot/actions/workflows/build-apk.yml)
[![Latest Release](https://img.shields.io/github/v/release/Bihan293/FRONTLINE_Godot?label=APK%20Release&color=green)](https://github.com/Bihan293/FRONTLINE_Godot/releases/latest)

A starter Android-friendly low-poly 3D FPS project made with Godot 4.3 / GDScript.

---

## 📲 Скачать готовую игру (APK)
Готовый установочный файл APK собирается автоматически на каждом пуше:
👉 **[Скачать свежий FRONTLINE.apk (GitHub Releases)](https://github.com/Bihan293/FRONTLINE_Godot/releases/latest)**

---

## 🚀 Автоматический CI/CD (GitHub Actions)
В репозитории настроен автоматический пайплайн `.github/workflows/build-apk.yml`:
- **Авто-сборка:** При каждом коммите в ветку `main` или отправке тега `v*` запускается сборка APK в среде Godot 4.3 headless.
- **Авто-релиз:** Готовый APK (`FRONTLINE.apk`) автоматически публикуется в [Releases](https://github.com/Bihan293/FRONTLINE_Godot/releases) с присвоением тега версии.

---

## Included
- Main menu: Play, Settings, Exit
- Map selection: one POLYGON card with a live top-down preview generated from the same layout as the playable scene
- Team selection, then top-down deployment map with four selectable spawn points; the preview and spawn markers match the in-game polygon
- Landscape orientation enforced for Android
- Physical collision on the floor, walls, covers, sandbags, crates and target boards
- Team selection: IRON LEGION (black/grey) and RED FRONT (red/brown)
- Low-poly polygon training range with firing lanes, spawn pads, barriers and steel target boards
- Player controller: keyboard + mouse on desktop, virtual joystick + swipe-look on Android
- Player and soldiers are scaled together to ~2.4 m, so the first-person camera and targets match
- AK-47 low-poly model (764 tris) with separate magazine, charging handle, `Muzzle` and `ShellEject` markers
- Rigged soldiers (20-bone humanoid skeleton) with procedural walk/aim/idle, both IRON LEGION and RED FRONT
- 16 training dummies: static targets, forward/back and strafing patrols, crouched walker, sitting and prone targets, plus standing/sitting/crouching/prone shooters firing at fixed target boards
- Shooting, 30-round magazine, reload timer, upward recoil with recovery and movement spread
- Per-part hitboxes: head 100, chest 45, stomach 35, arms 15, legs 20
- Crosshair with hitmarker; HUD split into non-overlapping zones
- TAB / on-screen scoreboard overlay (local prototype)
- CC0 sound effects: gunshot, empty-mag click, reload, flesh/metal hits, kill, footsteps and UI clicks
- Separate `maps/` directory for future maps

## Open
1. Install Godot 4.3 or newer.
2. Extract this ZIP.
3. In Godot Project Manager choose **Import**.
4. Select `project.godot`.
5. Run the project (F6/F5).

## Controls (desktop testing)
- WASD / arrow keys: move
- Mouse: look
- Left mouse: shoot
- R: reload
- C: lower stance (stand -> crouch -> prone)
- Space: rise (prone -> crouch -> stand); when standing, jump
- Shift: sprint
- TAB: scoreboard
- ESC: release mouse / return to menu using on-screen menu button

## Controls (Android)
- Left virtual joystick: move (push to the edge for ~0.7 s to sprint)
- Swipe anywhere outside the controls: look around
- ОГОНЬ: hold to fire
- ПЕРЕЗАР.: reload
- ПРИСЕСТЬ: stand -> crouch -> prone
- ПРЫЖОК: rise / jump
- МЕНЮ and ТАБЛО: top-right corner

## Android notes
This is a prototype, not a finished commercial game. Movement uses an analog virtual joystick on the left; look is a swipe on the rest of the screen. Fire, reload, stance and jump buttons are on the right. Sensitivity and layout may still need tuning on a specific device. Exporting an APK requires Godot Android export templates and Android SDK/JDK setup.

## Audio
All SFX are CC0 1.0 (public domain), see [`assets/audio/LICENSE.md`](assets/audio/LICENSE.md):
- Gunshot: "Gunshot sound effect" by **Tabasco** (OpenGameArt, CC0)
- Impacts, footsteps and UI: **Kenney** "Impact Sounds" and "Interface Sounds" (CC0)

## Current limitations
- No multiplayer, bots, capture points, or online player counts yet.
- Target dummies respawn ~2.6 s after death.
- Weapon and soldier models are in place; death animation is a simple fall, hand IK is still basic.
- Settings screen is a placeholder.
- TAB scoreboard is local-only.


## v0.3.0 changes
- Restored the full soldier height (~2.39 m) and scaled the player up to match (2.4 m capsule, 2.05 m eye height, adjusted stances).
- Polygon rebuilt from a single shared layout: every wall, cover, sandbag, crate and target board now has collision.
- Menu map preview and deployment screen are drawn from that same layout, so they match the playable polygon exactly.
- Added 16 training dummies: forward/back and strafing patrols, crouched walker, sitting and prone targets.
- Added shooting dummies that aim and fire at fixed target boards from standing, sitting, crouching and prone positions, with muzzle flash, tracer, impact flash and 3D gunshot audio.
- Added proper sitting pose (hips lowered through the skeleton) and prone pose (body rotated to the ground) with stance-specific hitboxes.
## v0.2.1 changes
- Mobile controls rewritten: analog virtual joystick on the left, swipe-to-look on the rest of the screen.
- Fixed inverted look axes; recoil now kicks upward and recovers instead of pulling down.
- HUD moved into separate zones: stats top-left, MENU/ТАБЛО top-right, ammo bottom-right, notices top-center.
- AK-47 and both rigged soldiers imported; soldiers scaled to 1.79 m, face the player and use procedural animation.
- Added per-part hitboxes, death fall, respawn, crosshair hitmarker and weapon bob.
- Added CC0 sound effects: gunshot, empty click, reload, hits, kill, footsteps and UI clicks.

## v0.2.0 changes
- Android orientation switched to landscape (`window/handheld/orientation=0`).
- Added physical collision to the floor; the old scene only had a visible floor mesh.
- Player capsule is offset correctly inside the CharacterBody3D and spawns at floor-safe height.
- Reworked menu flow: map card -> map preview/details -> faction selection -> tactical deployment map -> selected spawn -> DEPLOY.
- Added `maps/polygon/polygon_preview.png` for map preview and deployment screen.
