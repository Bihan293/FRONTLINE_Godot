# BUG-0014 — Игрок повреждает ботов своей фракции

- **Status:** investigating
- **Severity:** minor
- **Build / commit:** базовая версия `cbc1b42`
- **Platform / device:** desktop и Android
- **Found by:** Codex QA
- **Frequency:** при попадании в союзного бота
- **Owner:** gameplay design
- **Fix commit:** none

## Reproduction

1. Высадиться за Iron Legion или Red Front.
2. Выстрелить в ближайшего бота той же фракции.
3. Проверить, теряет ли он здоровье.

## Expected

Требуется зафиксировать правило: friendly fire является намеренным режимом реализма или должен быть отключён.

## Actual

Обработчик попадания игрока наносит урон любому damageable-боту и не сверяет название фракции.

## Evidence

Статический аудит `scripts/player.gd`.

## Retest

Не закрывать до фиксации ожидаемого поведения и проверки.

