# BUG-0004 — Compass bar lacks is_instance_valid check on player camera

- **Status:** fixed
- **Severity:** major
- **Build / commit:** v0.1.20 / cbc1b42
- **Platform / device:** Android / Linux / PC
- **Found by:** Antigravity
- **Frequency:** on player death / scene transition
- **Owner:** Antigravity
- **Fix commit:** pending

## Reproduction

1. Player dies or scene transitions from Battlefield to MainMenu.
2. `player_camera` reference in `compass_bar.gd` becomes a freed Object.
3. `_draw()` executes: `if player_camera == null: return`.
4. Engine throws error attempting to access `.global_rotation` on a deleted instance.

## Expected

Compass safely aborts drawing if the camera is null or invalid (`not is_instance_valid(player_camera)`).

## Actual

`scripts/compass_bar.gd:41` only checked `if player_camera == null: return`.

## Evidence

`scripts/compass_bar.gd:41`:
```gdscript
func _draw() -> void:
	if player_camera == null:
		return
```

## Retest

Added `if player_camera == null or not is_instance_valid(player_camera): return`.
