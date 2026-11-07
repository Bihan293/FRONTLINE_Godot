# TASK-0022 — Defect sweep: maps, bots, animations, functions

- **Priority:** P0
- **Status:** in progress
- **Owner:** OpenCode
- **Dependencies:** Latest `main`
- **Related:** `BUGS/OPEN.md`, `RELEASE_GATE.md`

## Scope

- Visual/geometry audit of Battlefield, Village and Polygon: holes, floating props, missing collision, blocked paths, overlapping covers, spawn mismatch.
- Bot audit: stuck bots, door crowding, friendly fire, medic/drone/sniper edge cases, objective selection.
- Animation audit: first-person weapon/arms, soldier rig, ragdoll, aim/reload/stance transitions.
- Function audit: menu flow, settings persistence, pause/timers, mode scoring, role/loadout selection.
- Record every reproducible issue in `BUGS/` with steps and evidence; fix high-impact ones.

## Acceptance criteria

- No blocker/critical defects in the main match loop.
- Every fixed bug has a retest on the build containing the fix.
- Navigation/pause/gameplay/projectile smoke tests stay green.
- Screenshots confirm the fixed map/animation state.
