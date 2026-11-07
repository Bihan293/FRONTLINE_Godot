# TASK-0011 — Backup sidearm, entrenching shovel, and mobile controls

- **Priority:** P1
- **Status:** done; CI smoke tests and Android export passed
- **Owner:** Codex
- **Related:** `TASKS/TASK-0006-bodycam-realism-optimization.md`, `TASKS/TASK-0007-ballistic-bullets-dot-reticle.md`, `TASKS/TASK-0001-android-qa.md`

## Acceptance criteria

- Every role can switch quickly between its primary weapon and a loaded M1911.
- The player can dig shallow trenches and use collected soil to build berms; rendered terrain and collision stay aligned.
- Terrain edits rebuild only nearby chunks so digging does not regenerate the whole map.
- Mobile gameplay buttons use black backgrounds and white action icons without text labels. Include separate sidearm and shovel controls.
- Gameplay smoke coverage checks the sidearm, shovel model, trench/berm limits, collision updates, and weapon toggles.

## Verification

- GitHub Actions run `42394325003` passed all four gameplay smoke scenes and exported the Android APK for commit `877dbd9` (`v0.1.59`).
- Physical-device input feel and performance remain part of the Android release QA task (`TASK-0001`).

## Controls

- `9`: switch between M1911 and the last primary weapon.
- `0` or `B`: equip or put away the shovel.
- Left mouse / mobile fire: dig while holding the shovel.
- Right mouse / shovel icon while carrying soil: place a soil layer.
