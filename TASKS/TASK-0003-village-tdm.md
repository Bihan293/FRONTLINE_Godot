# TASK-0003 — Add Village and Team Deathmatch

- **Priority:** P1
- **Status:** in progress
- **Owner:** Antigravity
- **Dependencies:** Current Battlefield build and shared `battlefield_layout.gd` map contract
- **Related:** `ROADMAP.md` → Maps and Game modes

## Scope

- Add a separate Village map with houses, fences, barns, wells, and narrow streets.
- Add a selectable Team Deathmatch mode with no sector ticket bleed.
- Provide faction spawn positions and a map preview generated from Village layout data.

## Acceptance criteria

- Village can be selected, deployed on, and played by both factions.
- Bots can leave both spawn areas, navigate around buildings, and engage the opposing team.
- TDM ends at its configured frag limit and displays the winner.
