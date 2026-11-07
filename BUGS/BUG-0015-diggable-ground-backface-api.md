# BUG-0015 — Diggable terrain collision uses an invalid backface property

- **Status:** verified
- **Severity:** major
- **Build / commit:** CI build `v0.1.59`, commit `877dbd9`
- **Platform / device:** GitHub Actions, Godot 4.3 headless
- **Found by:** Codex CI review
- **Frequency:** Every battlefield smoke-test run
- **Owner:** Codex
- **Fix commit:** `877dbd9`

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

GitHub Actions run `42394325003` completed successfully at `877dbd9`. All four gameplay smoke scenes passed, including the diggable-ground berm collision ray check; the Android APK also exported successfully.
