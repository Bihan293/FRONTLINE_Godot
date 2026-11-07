# TASK-0016 — Progression, loadouts and statistics

- **Priority:** P2
- **Status:** planned
- **Owner:** OpenCode
- **Dependencies:** Stable role/loadout selection
- **Related:** `ROADMAP.md` → Прогресс и мета

## Scope

- Local profile in `user://`: XP, rank, total stats, unlocked skins.
- XP for kills, captures, wins; rank-up notification.
- Three loadout slots: primary, sidearm, grenade; unlock by rank.
- Match summary with accuracy, K/D, captures, damage.
- Local achievements and a profile screen; reset progress.

## Acceptance criteria

- Progress survives restart and scene changes.
- Unlocks apply in the next match and never block core weapons unfairly.
- No pay-to-win, no network dependency.
- Corrupt/missing save falls back to safe defaults.
