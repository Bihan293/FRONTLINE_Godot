# FRONTLINE — Godot 4 Mobile FPS Prototype

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

## Included Features
- Main menu: Play, Settings, Exit
- Map selection: POLYGON
- Team selection: IRON LEGION (black/grey) and RED FRONT (red/brown)
- Low-poly polygon training range
- Player controller with mouse + keyboard and on-screen action buttons
- PPSh-inspired placeholder first-person weapon
- Shooting, ammo, reload timer, basic recoil
- T-pose target dummies with separate head/chest/stomach/arm/leg hit regions
- Damage values: head 100, chest 45, stomach 35, arms 15, legs 20
- TAB scoreboard overlay (local prototype)
- Separate `maps/` directory for future maps

---

## Open in Godot Editor
1. Install Godot 4.3 or newer.
2. In Godot Project Manager choose **Import**.
3. Select `project.godot`.
4. Run the project (F6/F5).

---

## Controls (Desktop)
- **WASD / Arrows**: Move
- **Mouse**: Look around
- **Left Mouse**: Shoot
- **R**: Reload
- **C**: Lower stance (stand -> crouch -> prone)
- **Space**: Rise (prone -> crouch -> stand); when standing, jump
- **Shift**: Sprint
- **TAB**: Scoreboard
- **ESC**: Release mouse / return to menu using on-screen menu button

---

## Android Controls
- Виртуальный экранный джойстик и кнопки прицеливания/оглядывания.
- Кнопки «ОГОНЬ», «ПЕРЕЗАРЯДКА», «СМЕНА ПОЗИЦИИ» (стойка/присед/лёжа).
