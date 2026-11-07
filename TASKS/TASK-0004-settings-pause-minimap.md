# TASK-0004 — Add gameplay settings, pause, and minimap

- **Priority:** P0
- **Status:** merged in main (v0.1.24)
- **Owner:** OpenCode
- **Dependencies:** Current input-lock behavior at match end
- **Related:** `ROADMAP.md` → Stabilization and HUD
- **Branch / PR:** `opencode/pause-settings-minimap` → https://github.com/Bihan293/FRONTLINE_Godot/pull/8
- **Commit:** `54b155f`

## Scope

- Add separate look and aim sensitivity, invert Y, and camera FOV settings.
- Add an in-match pause menu with resume, settings, and return-to-menu actions.
- Add a circular minimap with faction, spawn, sector, and nearby teammate markers.
- Save settings across launches and preserve safe touch targets on Android.

## Acceptance criteria

- Pause stops movement, shooting, bots, and timers; resume restores the same match.
- Settings persist after restarting the game.
- The minimap stays aligned with world positions and remains readable on phone screens.

## Verification

- `godot --headless --import` — no parse errors.
- `godot --headless --path . res://tests/pause_smoke.tscn` → `PAUSE_SMOKE_OK`.
- Smoke test covers: settings persistence, main-menu settings screen, pause/resume,
  Battlefield + Village + TDM integration, minimap presence.
- Battlefield ran 1200 headless frames without script errors.
- **Not yet verified on Android hardware.** Needs touch pause button, slider hit
  targets, safe areas and minimap readability checked on the phone before sign-off.

