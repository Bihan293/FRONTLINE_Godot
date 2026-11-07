# BUG-0005 — Player can fire weapon while applying field bandage

- **Status:** fixed
- **Severity:** minor
- **Build / commit:** v0.1.20 / cbc1b42
- **Platform / device:** Android / Linux / PC
- **Found by:** Antigravity & QA Subagent (Player Controls)
- **Frequency:** 100%
- **Owner:** Antigravity
- **Fix commit:** pending

## Reproduction

1. Take damage on Battlefield.
2. Press `H` or tap mobile button «БИНТ» to initiate field dressing.
3. Immediately press Left Mouse Button or mobile «ОГОНЬ».

## Expected

Weapon cannot fire during the 2.2-second healing bandage animation.

## Actual

`_shoot()` in `scripts/player.gd` checks `if is_reloading or fire_cooldown > 0.0 or is_dead: return`, but omitted `is_healing`. The player could continuously shoot AK-47 while simultaneously wrapping bandages.

## Evidence

`scripts/player.gd:584`:
```gdscript
func _shoot() -> void:
	if is_reloading or fire_cooldown > 0.0 or is_dead:
		return
```

## Retest

Added `or is_healing` check in `_shoot()`. Firing during healing is now blocked until bandage application is completed.
