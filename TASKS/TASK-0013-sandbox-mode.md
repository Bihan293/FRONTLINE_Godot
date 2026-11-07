# TASK-0013 — Sandbox mode

- **Priority:** P1
- **Status:** queued after TASK-0012
- **Owner:** OpenCode
- **Dependencies:** Vehicles (TASK-0012) for full value
- **Related:** `ROADMAP.md` → Песочница; DummyWar benchmark

## Scope

- Sandbox entry in the main menu with its own match settings.
- Spawn menu: infantry (faction/count), weapons, ammo crates, barrels, props, vehicles.
- Slow motion (0.25× / 0.5× / 1×), pause, free camera/spectator.
- Switch player faction on the fly; clear all bots; reset scene.
- Save/load sandbox preset.

## Acceptance criteria

- A 10×10 + vehicle scene can be assembled in under 2 minutes without console commands.
- Slow motion and pause stop bots, bullets and timers correctly.
- Sandbox never affects progression or normal match statistics.
