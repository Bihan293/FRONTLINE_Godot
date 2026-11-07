# TASK-0012 — Vehicles, transport and emplacements

- **Priority:** P1
- **Status:** deferred until 2026-11-08 (user request)
- **Owner:** OpenCode (implementation lead; use isolated specialist agents/worktrees where available)
- **Dependencies:** Stable bot navigation, vehicle collision layer
- **Related:** `ROADMAP.md` → Техника и турели

## Scope

- Jeep/truck with driver + passenger seats and a mounted MG.
- Tank with turret rotation, cannon, hull MG, armour zones and smoke on damage.
- Motorcycle for one rider; passenger can fire.
- Static MG/AA emplacements on capture points.
- Enter/exit prompts (F on desktop, ВОЙТИ on mobile), vehicle HUD and respawn timer.

## Acceptance criteria

- Vehicles drive, collide with terrain/props, take damage and explode.
- Player and bots can enter/exit; camera and controls switch cleanly.
- Bots use at least static turrets; vehicle pathing does not break infantry navigation.
- No physics explosion when a vehicle spawns or is abandoned.
- Add smoke coverage for enter/exit, seat handoff, collision, damage/destruction, abandonment cleanup, and infantry navigation around vehicles.
- Reuse meshes/materials and limit active physics and per-frame scans; include reproducible frame/object metrics and mark Android performance unverified unless measured on a named device.
