# BUG-0015 — Diggable terrain collision uses an invalid backface property

- **Status:** ready for retest
- **Severity:** major
- **Build / commit:** CI build at `7d43157`; fix commit pending
- **Platform / device:** GitHub Actions, Godot 4.3 headless
- **Found by:** Codex CI review
- **Frequency:** Every battlefield smoke-test run
- **Owner:** Codex
- **Fix commit:** pending

## Reproduction

1. Run `res://tests/pause_smoke.tscn` or `res://tests/gameplay_smoke.tscn` with Godot 4.3 headless.
2. Instantiate a battlefield that creates `FRONTLINEDiggableGround`.
3. Observe repeated script errors from `_rebuild_chunk()`.

## Expected

Terrain mesh and collision chunks are both created without script errors.

## Actual

`ConcavePolygonShape3D.backface_collision_enabled` is not an assignable property in Godot 4.3. The invalid assignment interrupts chunk rebuilding and causes follow-on null-mesh renderer errors.

## Evidence

GitHub Actions run `42393954279`, job `128467238679`, step “Run gameplay smoke tests”.

## Retest

Fix uses the documented `set_backface_collision_enabled(true)` method. Awaiting a passing CI build and terrain collision smoke test.
