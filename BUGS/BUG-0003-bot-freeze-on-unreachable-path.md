# BUG-0003 — Soldier bot permanently freezes when path is empty

- **Status:** fixed
- **Severity:** critical
- **Build / commit:** v0.1.20 / cbc1b42
- **Platform / device:** Android / Linux / PC
- **Found by:** Antigravity
- **Frequency:** 100% when goal or bot is unreachable
- **Owner:** Antigravity
- **Fix commit:** pending

## Reproduction

1. Place bot at a coordinate with no navigable path to target (or during isolated spawn as in BUG-0002).
2. Bot enters `_advance_behavior` or `_combat_behavior`.
3. Check bot velocity and position over time.

## Expected

Bot falls back to direct vector movement (`direct.normalized()`) so `move_and_slide()` allows it to slide along walls or advance toward the target.

## Actual

`scripts/soldier_bot.gd:424` checks `if _route_path.is_empty(): return Vector3.ZERO`.
When no path exists, `_route_direction()` returns `Vector3.ZERO`, zeroing `velocity.x` and `velocity.z`. The bot freezes permanently in place as a statue.

## Evidence

`scripts/soldier_bot.gd:424` and `scripts/soldier_bot.gd:426`:
```gdscript
		if _route_path.is_empty():
			return Vector3.ZERO
	if _route_path.is_empty():
		return Vector3.ZERO
```

## Retest

Changed `return Vector3.ZERO` when empty to `return direct.normalized()`. Verified bots continuously advance even if A* returns no solution.
