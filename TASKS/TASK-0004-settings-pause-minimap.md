# TASK-0004 — Add gameplay settings, pause, and minimap

- **Priority:** P0
- **Status:** open
- **Owner:** OpenCode
- **Dependencies:** Current input-lock behavior at match end
- **Related:** `ROADMAP.md` → Stabilization and HUD

## Scope

- Add separate look and aim sensitivity, invert Y, and camera FOV settings.
- Add an in-match pause menu with resume, settings, and return-to-menu actions.
- Add a circular minimap with faction, spawn, sector, and nearby teammate markers.
- Save settings across launches and preserve safe touch targets on Android.

## Acceptance criteria

- Pause stops movement, shooting, bots, and timers; resume restores the same match.
- Settings persist after restarting the game.
- The minimap stays aligned with world positions and remains readable on phone screens.

