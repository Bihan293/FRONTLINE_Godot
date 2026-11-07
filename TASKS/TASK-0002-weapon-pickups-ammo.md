# TASK-0002 — Add weapon pickups and ammunition crates

- **Priority:** P1
- **Status:** done
- **Owner:** Codex / Antigravity
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

## Verification & Implementation

- Added reusable ammo caches on both maps (Battlefield and Village). Each gives up to 48 rounds to the held weapon, respects that weapon's reserve cap, and respawns after 65 seconds (`scripts/field_pickup.gd`, `scripts/battlefield.gd`).
- Bots drop their equipped weapon with ammunition when killed. Weapon pickups expire after 50 seconds; replacing the held weapon drops it for a possible swap back.
- Pickup prompts use **F** on desktop and an on-screen **ВЗЯТЬ** button on touch (`scripts/mobile_controls.gd`).
- Limit of 16 active world pickups with automated FIFO cleanup prevents physics and draw-call overhead on mobile hardware.


