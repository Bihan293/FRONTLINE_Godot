# TASK-0023 — Environment variety: weather, time of day, destructibles

- **Priority:** P2
- **Status:** planned
- **Owner:** OpenCode
- **Dependencies:** Stable maps and lighting
- **Related:** `ROADMAP.md` → Карты, разрушение

## Scope

- Presets: day, dusk, night; clear, fog, rain, snow (map-specific).
- Destructible crates, fences, small cover and explosive barrels with debris.
- Wet/snow ground material variants and reduced visibility at night.
- Performance-safe particle budgets.

## Acceptance criteria

- At least three atmosphere presets selectable per map.
- Destructibles break consistently from bullets/explosions and do not break navigation permanently.
- Night map remains readable with tracers/flares.
- No FPS drop below the low-device target.
