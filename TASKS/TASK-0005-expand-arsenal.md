# TASK-0005 — Expand the arsenal to eight distinct weapons

- **Priority:** P1
- **Status:** done
- **Owner:** Codex / Antigravity
- **Dependencies:** `TASK-0002` weapon pickup and ammo support
- **Related:** `ROADMAP.md` → Weaponry

## Scope

- Add at least three additional weapons with distinct roles, models, fire behavior, and reload handling.
- Candidates: PPSh-41 drum SMG, Kar98k sniper with optic scope, Panzerfaust anti-armor rocket launcher.
- Keep weapon stats in a shared data table and balance damage by hit region.

## Acceptance criteria

- The loadout contains at least eight selectable weapons.
- Every weapon has a visible model and noticeably different cadence, spread, range, and magazine size.
- All weapon types pass the same desktop and Android firing/reload checks.

## Verification & Implementation

- Arsenal expanded to 8 fully functional weapons in `WEAPON_DEFS` (`scripts/player.gd`):
  1. `ak47` (AK-47 assault rifle)
  2. `mp40` (MP-40 submachine gun)
  3. `mosin` (Mosin-Nagant infantry rifle, 1.7x ADS zoom)
  4. `m1911` (M1911 semi-auto pistol)
  5. `shotgun` (Pump-Action shotgun, 7 pellets)
  6. `ppsh41` (PPSh-41 high-cadence drum SMG, 71 rounds, 920 RPM)
  7. `kar98k` (Kar98k sniper rifle with optical scope, 2.6x ADS zoom, 260m range)
  8. `panzerfaust` (Panzerfaust anti-armor rocket launcher firing ballistic `FRONTLINERocketProjectile` with 10.5m blast radius)
- Added procedural 3D weapon meshes and materials for all weapons in `scripts/weapon_meshes.gd`.
- Bot squads spawn with diverse weapons (AK-47, MP-40, PPSh-41, Shotgun, Mosin, Kar98k) and drop their respective weapons upon death.
- Controls support direct key switching (1–8), mouse wheel cycling, and touch cycle/interact buttons.


