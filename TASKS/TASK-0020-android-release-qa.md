# TASK-0020 — Android release QA and distribution

- **Priority:** P0
- **Status:** ready for device test
- **Owner:** OpenCode (QA coordinator; Android result requires an actual device run)
- **Dependencies:** Latest `main` APK
- **Related:** `TASK-0001`, `RELEASE_GATE.md`

## Scope

- Install APK from scratch on a clean phone; record device/build.
- Full match: menu → faction → deployment → battle → victory → exit → relaunch.
- Verify pause, settings persistence, minimap alignment, touch HUD, safe areas.
- Log crashes, ANRs, thermal throttling and battery use.
- Publish the tested APK to GitHub Releases and attach evidence to the gate.

## Acceptance criteria

- No blocker/critical bugs in the full match flow.
- Settings and progression survive relaunch.
- Evidence (video/screenshots/logs/device) linked in `RELEASE_GATE.md`.
- The tested build is the one published for players.
