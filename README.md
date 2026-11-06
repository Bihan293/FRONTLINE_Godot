# FRONTLINE — Godot 4 Mobile FPS Prototype (v0.2.0)

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
- Map selection: one POLYGON card; selecting it opens a right-side map preview and description
- Team selection, then top-down deployment map with four selectable spawn points
- Landscape orientation enforced for Android
- Physical static floor collider and corrected player capsule/spawn height
- Team selection: IRON LEGION (black/grey) and RED FRONT (red/brown)
- Low-poly polygon training range
- Player controller with mouse + keyboard and on-screen action buttons
- PPSh-inspired placeholder first-person weapon
- Shooting, ammo, reload timer, basic recoil
- T-pose target dummies with separate head/chest/stomach/arm/leg hit regions
- Damage values: head 100, chest 45, stomach 35, arms 15, legs 20
- TAB scoreboard overlay (local prototype)
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

## Android notes
This is a prototype, not a finished commercial game. On-screen directional movement and look buttons plus fire/reload/stance buttons are included. They are functional prototype controls, but their layout and sensitivity still need testing and tuning on a real device. Exporting an APK requires Godot Android export templates and Android SDK/JDK setup.

## Current limitations
- No multiplayer, bots, capture points, or online player counts yet.
- Target dummies respawn their health when reduced to zero.
- Weapon model, animations, sound effects, and soldier visuals are placeholder low-poly assets.
- Settings screen is a placeholder.
- TAB scoreboard is local-only.


## v0.2.0 changes
- Android orientation switched to landscape (`window/handheld/orientation=0`).
- Added physical collision to the floor; the old scene only had a visible floor mesh.
- Player capsule is offset correctly inside the CharacterBody3D and spawns at floor-safe height.
- Reworked menu flow: map card -> map preview/details -> faction selection -> tactical deployment map -> selected spawn -> DEPLOY.
- Added `maps/polygon/polygon_preview.png` for map preview and deployment screen.
