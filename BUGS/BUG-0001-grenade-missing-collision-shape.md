# BUG-0001 — Grenades lack CollisionShape3D causing them to pass through world floor

- **Status:** fixed
- **Severity:** critical
- **Build / commit:** v0.1.20 / cbc1b42
- **Platform / device:** Android / Linux / PC
- **Found by:** Antigravity & QA Subagent (Player Controls)
- **Frequency:** 100%
- **Owner:** Antigravity
- **Fix commit:** pending

## Reproduction

1. Start Battlefield map or Polygon.
2. Throw a frag grenade (`G` or mobile button «ГРАНАТА») or smoke grenade (`X` / «ДЫМ»).
3. Observe the grenade trajectory as it contacts the ground.

## Expected

Grenade physically collides with the ground, bounces based on velocity and normal vector, and comes to rest on the terrain.

## Actual

`FRONTLINEGrenade` and `FRONTLINESmokeGrenade` extend `CharacterBody3D` and call `move_and_collide()`, but neither script instantiated a `CollisionShape3D` with a `Shape3D` (e.g. `SphereShape3D`). In Godot 4, a `CharacterBody3D` without collision shapes has no query shape and fails all world collision tests, falling infinitely through the floor until its timer expires.

## Evidence

- `scripts/grenade.gd:27-33`: `_ready()` sets collision mask 1, but creates no `CollisionShape3D`.
- `scripts/smoke_grenade.gd:26-30`: `_ready()` creates no `CollisionShape3D`.

## Retest

Added `_build_collision()` with `SphereShape3D(radius = 0.08)` to both grenade scripts. Bouncing and ground settling verified.
