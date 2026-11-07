# BUG-0013 — Стрельба не зажигает взрывные бочки

- **Status:** fixed
- **Severity:** major
- **Build / commit:** базовая версия `cbc1b42`, исправлено в `v0.1.22`
- **Platform / device:** desktop и Android
- **Found by:** Codex QA
- **Frequency:** при каждом прямом попадании пули
- **Owner:** Codex & Antigravity
- **Fix commit:** `ce0d962`

## Reproduction

1. Начать матч Battlefield.
2. Стрелять по красной бочке до срабатывания.

## Expected

Бочка искрит, загорается и взрывается после короткого фитиля.

## Actual

Луч попадает сначала в StaticBody бочки на слое 1. Тело помечено `damageable`, но у него нет метаданных владельца, поэтому обработчики игрока и ботов не вызывают `receive_hit`. Area хитбокс с владельцем расположен на другом слое и не попадает первым.

## Evidence

Статический аудит `scripts/explosive_barrel.gd`, `scripts/player.gd` и `scripts/soldier_bot.gd`.

## Retest

Ветка Codex обновляет разрешение попаданий по `damageable`-телам. Проверить стрельбу игрока и ботов на сборке.

