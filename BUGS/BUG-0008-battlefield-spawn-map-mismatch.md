# BUG-0008 — Выбор спавна Battlefield показывает карту Polygon

- **Status:** fixed
- **Severity:** major
- **Build / commit:** базовая версия `cbc1b42`
- **Platform / device:** desktop и Android
- **Found by:** Codex QA
- **Frequency:** каждый вход на экран Battlefield deployment
- **Owner:** Codex
- **Fix commit:** 

## Reproduction

1. Выбрать Battlefield.
2. Выбрать любую фракцию.
3. Сравнить карту и маркеры на экране выбора с геометрией Battlefield.
4. Нажать на любой маркер и начать бой.

## Expected

Показывается Battlefield сверху, а маркеры находятся точно на игровых спавнах выбранной фракции.

## Actual

Экран использует карту и позиции Polygon, затем применяет только индекс к спавнам Battlefield. У Polygon шесть точек, у Battlefield пять, поэтому шестая точка заворачивается в первую.

## Evidence

Статический аудит `scripts/main_menu.gd` и `scripts/map_preview.gd`.

## Retest

В ветке Codex добавлен отдельный Battlefield preview сверху с маркерами из `battlefield_layout.gd`. Проверить обе фракции и все точки после сборки.

