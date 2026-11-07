# TASK-0015 — Third game mode and match configuration

- **Priority:** P1
- **Status:** planned
- **Owner:** OpenCode
- **Dependencies:** Existing Conquest/TDM
- **Related:** `ROADMAP.md` → Режимы игры

## Scope

- Add Domination (3 points, hold to score) or CTF.
- Pre-match screen: mode, map, bot count 4–40, tickets, time limit, difficulty, friendly fire.
- Mode-specific HUD, win conditions and end screen.
- Rematch with the same settings.

## Acceptance criteria

- Three modes play end-to-end from menu to victory screen.
- Settings persist and are shown on the loading/deployment screen.
- Bots prioritise objectives differently per mode.
- No score/ticket logic leaks between modes.
