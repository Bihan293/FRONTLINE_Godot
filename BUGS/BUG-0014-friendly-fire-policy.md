# BUG-0014 — Игрок повреждает ботов своей фракции

- **Status:** fixed
- **Severity:** minor
- **Build / commit:** базовая версия `cbc1b42`, исправлено в `v0.1.22`
- **Platform / device:** desktop и Android
- **Found by:** Codex QA
- **Frequency:** при попадании в союзного бота
- **Owner:** gameplay design & Antigravity
- **Fix commit:** `ce0d962`

## Reproduction

1. Высадиться за Iron Legion или Red Front.
2. Выстрелить в ближайшего бота той же фракции.
3. Проверить, теряет ли он здоровье.

## Expected

Урон сослуживцам отключен (friendly fire = false): пули игрока и ботов игнорируют союзников и не тратят билеты команды.

## Actual

Защита от дружественного огня внедрена в `player.gd`, `soldier_bot.gd` и `grenade.gd`. Боты и игрок не наносят урон союзным бойцам своей фракции.

## Evidence

Статический аудит `scripts/player.gd`.

## Retest

Не закрывать до фиксации ожидаемого поведения и проверки.

