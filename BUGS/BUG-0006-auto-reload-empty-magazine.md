# BUG-0006 — Missing auto-reload when pulling trigger on empty magazine

- **Status:** fixed
- **Severity:** minor / QoL
- **Build / commit:** v0.1.20 / cbc1b42
- **Platform / device:** Android / Linux / PC
- **Found by:** Antigravity
- **Frequency:** 100% on empty clip
- **Owner:** Antigravity
- **Fix commit:** pending

## Reproduction

1. Empty weapon magazine to 0 bullets while reserve ammo remains.
2. Press fire button again.

## Expected

In Dummy War and modern combat shooters, attempting to fire an empty weapon initiates reload automatically if reserve ammo is available.

## Actual

Player only hears an empty click sound and weapon refuses to fire until the player manually locates and taps the reload button.

## Evidence

`scripts/player.gd:586-590`:
```gdscript
	if ammo <= 0:
		_play_sfx(sfx_empty, SFX_EMPTY, -5.0, randf_range(0.95, 1.05))
		fire_cooldown = 0.25
		return
```

## Retest

Added auto-reload trigger: `if reserve_ammo > 0 and not is_reloading: _reload()`.
