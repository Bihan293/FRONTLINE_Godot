# TASK-0012 — Vehicles, transport and emplacements

- **Priority:** P1
- **Status:** planned
- **Owner:** Antigravity / Codex
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
