# TASK-0006 — Bodycam realism and Android optimization

- **Priority:** P1
- **Status:** planned
- **Owner:** Antigravity (visual direction) / Codex (camera and combat feel) / OpenCode (profiling and settings)
- **Dependencies:** TASK-0001 device QA baseline; TASK-0004 settings and pause; TASK-0005 eight-weapon arsenal
- **Related:** `ROADMAP.md` → Combat, presentation, and performance

## Goal

Give FRONTLINE the close, physical feel of a body-worn combat camera instead of a weightless arcade 3D shooter. Keep the camera readable and comfortable, and make the look affordable on Android hardware.

## Scope

- Prototype a chest/shoulder-mounted first-person camera with controlled wide-angle framing, subtle camera inertia, footstep motion, and bounded roll. Camera motion must not clip through nearby walls or become disorienting.
- Add an optional bodycam presentation preset with restrained lens distortion, vignette, grain, and a compact recording/time overlay. Let players disable visual effects and tune motion intensity.
- Give movement and weapons believable weight: acceleration and stopping, different handling by weapon, recoil recovery, reload timing, and visible consequences from injuries. Preserve clear controls and responsive aiming.
- Profile CPU, GPU, memory, draw calls, and frame pacing on representative Android devices. Optimize map detail, shadows, particles, materials, and AI update rates based on measured bottlenecks.

## Acceptance criteria

- The bodycam preset is visibly distinct in recorded gameplay, can be disabled in settings, and keeps the target and nearby threats readable.
- Camera motion is clamped and collision-aware; settings allow the player to reduce or disable motion and image effects.
- Movement, weapon handling, and injury effects feel weighty in a short desktop and Android combat scenario without making aiming unresponsive.
- On a documented mid-range Android device, a 20-bot match holds at least 45 FPS; on a documented low-end device, it holds at least 30 FPS. Record average and 1% low frame rates, memory use, device model, map, and settings.
- No visual effect or optimization change introduces clipping, unreadable HUD, missing hit feedback, or broken touch targets. Retest both Battlefield and Village.

## Work split

- **Antigravity:** bodycam art direction, environment/model review, and visual proof from both maps.
- **Codex:** camera, movement, weapon feel, injury feedback, and collision-aware motion.
- **OpenCode:** Android profiling, effect controls, performance measurements, and regression smoke tests.

Keep this task in progress until the bodycam gameplay is captured and the Android performance measurements are attached. A static code review alone does not satisfy the visual or device criteria.
