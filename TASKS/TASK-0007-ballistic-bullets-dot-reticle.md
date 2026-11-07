# TASK-0007 — Dot reticle and visible ballistic bullets

- **Priority:** P1
- **Status:** in progress
- **Owner:** Codex (projectile and reticle implementation) / Antigravity (visual review and Android retest)
- **Dependencies:** Current eight-weapon arsenal and TASK-0002 weapon drops
- **Related:** `TASKS/TASK-0006-bodycam-realism-optimization.md`

## Goal

Make ordinary firearm shots feel like bullets leaving the weapon, traveling through the world, and hitting things, instead of instant camera raycasts presented as gunfire.

## Scope

- Replace the four-bar arcade crosshair with a small centered dot and preserve a brief hit confirmation.
- Spawn bullets at the weapon muzzle, aim them toward the camera's center target with realistic muzzle-to-target parallax, and give each weapon its own velocity, spread, and gravity.
- Show a small, short-lived bullet/tracer in flight. Resolve collision along each projectile's traveled segment so fast bullets cannot pass through thin targets between frames; apply damage only on impact.
- Preserve hit regions, faction friendly-fire rules, barrels, bullet holes, blood feedback, and the Panzerfaust's separate rocket behavior.
- Keep projectile count and visual effects within a measured mobile budget; shotgun pellets may use a grouped representation if individual pellets are too costly.

## Acceptance criteria

- The reticle is a single dot, clearly centered on desktop and Android; a hit still gives clear feedback.
- Every firearm round visibly originates at its muzzle and travels before applying damage. Nearby walls, barrels, enemies, and allies block or receive the shot according to current combat rules.
- Bullet speed/drop and spread differ by weapon. Shotgun spread produces a pellet pattern; the Panzerfaust continues to fire its own rocket.
- No hitscan damage remains for normal player firearm shots. Segment collision is allowed only as the projectile's per-frame collision check.
- Smoke and impact effects remain readable, and projectile simulation does not cause measurable frame-rate loss at the target bot count.
- Add headless coverage for travel time, muzzle origin, blocked shots, damage, and friendly fire; include the same scenarios in TASK-0001 Android QA.

## Verification

Record the tested commit/build, map, weapon, target distance, and headless/Android results. Do not mark complete after changing only the crosshair or projectile visuals.
