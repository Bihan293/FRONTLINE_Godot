# BUG-0010 — После Escape нельзя снова захватить курсор

- **Status:** open
- **Severity:** major
- **Build / commit:** базовая версия `cbc1b42`
- **Platform / device:** desktop
- **Found by:** Codex QA
- **Frequency:** при каждом нажатии Escape во время боя
- **Owner:** unassigned
- **Fix commit:** none

## Reproduction

1. Начать матч на ПК.
2. Нажать Escape.
3. Попробовать двигать обзор мышью или щёлкнуть по игровому окну.

## Expected

Игра показывает меню паузы либо позволяет щелчком снова захватить курсор.

## Actual

Курсор становится виден, но обратного захвата нет; обзор мышью остаётся выключенным до конца матча.

## Evidence

Статический аудит `scripts/player.gd`: Escape переключает режим курсора в `VISIBLE`.

## Retest

Ожидает исправления и проверки на ПК.

