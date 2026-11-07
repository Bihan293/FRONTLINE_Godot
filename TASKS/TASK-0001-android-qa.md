# TASK-0001 — Verify current Android build and retest the QA log

- **Priority:** P0
- **Status:** ready for device test
- **Owner:** Antigravity / QA agents
- **Dependencies:** Latest main build contains the current local main commits
- **Related:** `BUGS/OPEN.md`

## Acceptance criteria

- Install and launch the APK on the target phone.
- Deploy as both factions and verify all five spawn markers match the top-down Battlefield preview.
- Try all eight weapons, mobile weapon cycling, and both held peek buttons near cover.
- Confirm the centered dot reticle and that visible bullets leave the muzzle, travel to targets, and hit walls, barrels, enemies, and allies consistently; verify friendly fire stays disabled.
- Verify bullets ignite barrels and combat freezes after match end.
- Record projectile weapon, target distance, device/build, and whether impact delay, muzzle origin, wall blocking, and friendly-fire behavior match the desktop smoke test.
- Retest every issue in `BUGS/OPEN.md`; record build, device, steps, and result before marking an issue verified.

