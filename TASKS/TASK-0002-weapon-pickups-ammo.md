# TASK-0002 — Add weapon pickups and ammunition crates

- **Priority:** P1
- **Status:** open
- **Owner:** Codex
- **Dependencies:** Stable weapon switching and the latest QA pass
- **Related:** `ROADMAP.md` → Weaponry

## Scope

- Place readable weapon pickups and faction-neutral ammunition crates on Battlefield.
- Allow the player to replace the current weapon and replenish the correct weapon's reserve.
- Show a short interaction prompt and support both keyboard and touch.
- Keep pickup collision and interaction performant with the existing bot count.

## Acceptance criteria

- A player can pick up and switch to a dropped weapon on desktop and Android.
- Ammunition crates refill the held weapon without exceeding its reserve limit.
- Items respawn or remain spent according to a documented match rule.
