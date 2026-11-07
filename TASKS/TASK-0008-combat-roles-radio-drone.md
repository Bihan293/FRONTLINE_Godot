# TASK-0008 — Combat roles and tethered radio drone

- **Priority:** P1
- **Status:** in progress
- **Owner:** OpenCode (single implementation owner; use real, isolated agents for gameplay, art and regression QA)
- **Dependencies:** TASK-0005 eight-weapon arsenal; TASK-0006 bodycam and weapon handling; TASK-0007 ballistic projectiles
- **Related:** `TASKS/TASK-0001-android-qa.md`

## Goal

Let the player deploy as a distinct battlefield role, with useful team support and readable equipment. The radio operator controls a small kamikaze drone from a handheld box with a screen and joysticks. A physical tether connects the box to the drone and limits its range.

## Roles

- **Medic:** carries a limited supply of bandages or medical charges and can treat wounded teammates at close range. Show remaining supplies and clear treatment feedback. Keep treatment interruptible by movement, firing, or taking damage.
- **Sniper:** receives a bolt-action precision rifle, a scoped aiming mode, and an appropriate ammunition load. Preserve weapon sway and slower follow-up shots.
- **Anti-tank:** receives a Panzerfaust or a later equivalent launcher with limited ammunition. Make the launcher useful against vehicles or fortified targets without turning it into an unlimited anti-personnel weapon.
- **Radio operator:** carries a visible drone control box with a screen and two joysticks. Launches and steers one tethered kamikaze drone, then detonates it by impact or a deliberate control input.

## Radio drone behavior

- Show the handheld controller in the player's hands with the screen and controls visible. The screen must show a live or convincingly updated view from the drone camera while it is controlled.
- Render a visible cable from the controller to the moving drone. Keep the tether attached and prevent it from passing through terrain or solid structures where practical; do not simulate a costly chain of rigid bodies.
- Set a **150 m default tether** on the large Battlefield map. Scale the maximum length to each map's playable dimensions so the drone cannot fly beyond the map; show current distance or an out-of-range warning on the controller.
- The cable constrains the drone's movement. It cannot be steered past its maximum length, and it is lost or forced to return if the cable is severed or the drone reaches its limit.
- Keep the operator in the world and vulnerable while controlling the drone. Clearly switch between operator and drone view and provide an immediate return-to-operator control.
- Limit the drone to one charge per deployment (tunable for balance), with a visible launch state, battery/failsafe behavior, impact explosion, and team-safe blast damage.
- Provide equivalent keyboard/mouse and touch controls. Keep the touch sticks away from firing, aiming, and movement controls.
- Profile the drone camera, cable rendering, and particles on Android. Use a bounded render target/update rate and remove all drone resources on return, detonation, death, or match end.

## Acceptance criteria

- A class-selection step appears before deployment, after faction/map selection; each role has distinct equipment and a concise ability description.
- All four roles can enter a match on both factions and use their role equipment on Battlefield and Village. Polygon remains a safe place to inspect controls and equipment.
- Medic treatment changes a teammate's health state and consumes a limited supply. Sniper and anti-tank equipment match their role and retain the existing ballistic/rocket rules.
- The radio operator can launch, steer, and detonate the drone; the operator stays exposed, can regain the operator view, and cannot control the drone beyond the map-scaled tether.
- The controller screen follows the drone camera, and a visible cable remains attached while the drone moves. Tether range, obstacles, collisions, friendly-fire behavior, and cleanup work without runtime errors.
- Desktop and Android controls both work. A 20-bot match remains within TASK-0006's performance targets; record device, map, frame rate, and render settings.
- Add smoke coverage for role loadouts, medic supplies, drone launch/control/return, maximum tether, wall contact, friendly blast filtering, and match cleanup.

Keep the task in progress until the four roles have been exercised in matches on both Battlefield and Village and the radio drone has been checked on a real Android device.
