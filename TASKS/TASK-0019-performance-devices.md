# TASK-0019 — Performance and device optimisation

- **Priority:** P1
- **Status:** in progress (baseline/profile audit)
- **Owner:** OpenCode (separate performance/QA workstream)
- **Dependencies:** Current 20v20 bot load
- **Related:** `ROADMAP.md` → Графика и производительность

## Scope

- Benchmark 20v20 on low/mid Android and PC; record frame-time and memory.
- LOD for soldiers, weapons, vehicles; occlusion/culling distances per map.
- Object pools for casings, tracers, particles, ragdolls, decals.
- Cap decals/ragdolls and simultaneous gunfire audio.
- Texture compression, APK size budget, shader warm-up.

## Acceptance criteria

- 45+ FPS in a 20v20 fight on a mid Android device; 30 FPS on low.
- No frame hitch over 100 ms during mass explosions.
- Memory < 700 MB; APK < 60 MB.
- Results recorded with device model, build and scene.
