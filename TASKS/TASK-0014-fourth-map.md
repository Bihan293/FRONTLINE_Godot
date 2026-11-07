# TASK-0014 — Fourth battle map

- **Priority:** P1
- **Status:** planned (deferred until TASK-0012 and TASK-0013)
- **Owner:** OpenCode (later queue)
- **Dependencies:** Map contract from Village/Battlefield
- **Related:** `ROADMAP.md` → Карты

## Scope

- New 180–240 m map: industrial factory/port with interiors, catwalks, cranes and explosive tanks.
- Three attack lanes, verticality (roofs/second floor), at least 12 covers per sector.
- Spawn protection, map bounds, minimap preview and deployment screen parity.
- Map-specific hazard: steam/fire/explosive barrel chain.

## Acceptance criteria

- All spawns reachable for both factions; navigation smoke test passes.
- Preview and deployment markers match real geometry.
- 20 bots run without stuck groups or wall clipping.
- Distinct silhouette/landmarks from Battlefield and Village.
- When scheduled, keep the map mobile-friendly: reuse materials/meshes, bound particles and active physics, and avoid per-frame scene-wide scans.
- When scheduled, report draw/object counts or a comparable reproducible runtime profile; mark Android device performance unverified unless tested on a named device.
- When scheduled, add or extend automated navigation/gameplay smoke coverage and attach representative map/deployment screenshots.
