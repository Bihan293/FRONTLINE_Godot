# BUG-0009 — Стартовый спавн не выделен при открытии экрана

- **Status:** fixed
- **Severity:** minor
- **Build / commit:** базовая версия `cbc1b42`
- **Platform / device:** desktop и Android
- **Found by:** Codex QA
- **Frequency:** каждый вход на экран deployment
- **Owner:** Codex
- **Fix commit:** 

## Reproduction

1. Выбрать фракцию и открыть deployment.
2. Не нажимать на точки спавна.
3. Сравнить выбранную подпись и фактическую точку с маркерами на карте.

## Expected

Точка спавна по умолчанию сразу визуально выделена.

## Actual

Подпись и индекс указывают на точку 1, но на карте ни один маркер не выделен.

## Evidence

Статический аудит `scripts/main_menu.gd`.

## Retest

В ветке Codex превью получает индекс 0 при создании. Проверить на сборке.

