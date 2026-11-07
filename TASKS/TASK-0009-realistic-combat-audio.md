# TASK-0009 — Realistic positional combat audio

- **Priority:** P1
- **Status:** planned
- **Owner:** Codex (audio behavior and gameplay integration) / Antigravity (sound direction and asset review) / OpenCode (implementation support, profiling and regression checks)
- **Dependencies:** TASK-0006 bodycam and Android optimization; TASK-0007 ballistic bullets and combat feedback
- **Related:** `TASKS/TASK-0001-android-qa.md`, `TASKS/TASK-0008-combat-roles-radio-drone.md`

## Goal

Make combat sound place the player in a believable space. Players should be able to judge whether gunfire or an explosion is nearby or far away, whether it came from indoors or outdoors, and roughly where it happened, without losing important gameplay cues in the mix.

## Scope

- Use positional 3D audio for player and bot gunshots, bullet cracks/impacts, grenades, rockets, explosions, footsteps and other combat-critical sounds. Use weapon-specific reports and avoid playing every shot at the same volume and tone.
- Apply distance attenuation and direction consistently. Distant shots should sound quieter and less detailed, with an appropriate filtered/indirect report; nearby shots should remain forceful without clipping or causing uncomfortable peaks.
- Account for walls, buildings and terrain between source and listener. Occluded fire should be quieter and more muffled than an unobstructed shot, using affordable ray checks or equivalent spatial audio features.
- Distinguish open-air and enclosed spaces. Indoor gunfire should have a strong, space-appropriate reflection/reverberation tail and a fuller, more confined character; outdoor reports may carry terrain-dependent echoes and reflections without an artificial indoor reverb.
- Give grenades and other explosions a sharp nearby blast, a distance-appropriate low-frequency body and tail, and reflections that respond to nearby structures. Keep blast sound spatially tied to its source.
- Handle overlapping gunfire, ambience and voice/UI cues with sensible bus levels, voice limits and prioritization. Critical hit, reload and warning cues must remain audible during a large fight.
- Keep the system performant on Android: pool or limit short-lived voices, avoid expensive per-frame acoustic queries, and expose mix/effect quality settings if needed.

## Acceptance criteria

- A listener can reliably distinguish close, medium and distant gunfire in a recorded Battlefield and Village scenario by level, filtering and spatial position; the mix does not clip during sustained fire.
- The same weapon fired in an open area and inside representative buildings has a clearly different, convincing acoustic character. Indoor reflections decay naturally, and outdoor echoes respond to the environment rather than applying one generic reverb everywhere.
- Walls and substantial terrain reduce and muffle gunshots and explosions; removing the obstruction restores the direct sound. Verify several source/listener distances and directions.
- Grenades and rockets sound positioned at their actual explosion point, with distinct near/far behavior and appropriate indoor reflections.
- A 20-bot firefight does not cause runaway audio voices, audible dropouts in critical cues, runtime errors, or a measurable frame-rate regression against TASK-0006's Android targets.
- Attach short comparison recordings or video with audio for indoor/outdoor, occluded/unoccluded, near/distant gunfire, and grenade tests; include device, map, and audio settings for Android results.

Keep this task in progress until desktop and Android audio comparisons are captured and reviewed. A static code review alone does not satisfy the acoustic acceptance criteria.
