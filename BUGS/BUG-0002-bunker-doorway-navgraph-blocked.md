# BUG-0002 — Bunker doorway cells marked blocked isolating spawns in nav graph

- **Status:** fixed
- **Severity:** blocker
- **Build / commit:** v0.1.20 / cbc1b42
- **Platform / device:** Android / Linux / PC
- **Found by:** Antigravity & QA Subagent (Combat & Bot AI)
- **Frequency:** 100%
- **Owner:** Antigravity
- **Fix commit:** pending

## Reproduction

1. Start Battlefield match.
2. Observe bots spawned at `(0, 76)` (Iron bunker) or `(0, -76)` (Red bunker).
3. Check bot movement towards center objectives.

## Expected

Bots navigate out of the bunker doorway (6m opening) into the trench network and advance toward Sector Bravo.

## Actual

`scripts/bot_navigation.gd` uses `CELL_SIZE := 3.0` and `AGENT_CLEARANCE := 1.1`. The left and right facade bunker walls (-6.5 and +6.5, width 7m) expand by clearance and both round to grid cell `x = 36`, completely blocking the 6-meter wide doorway.
As a result, the AStar graph partitions into isolated components:
- Component 0 (main battlefield): 3004 points
- Component 1 (Iron bunker interior): 3 points
- Component 2 (Red bunker interior): 3 points
Bots spawned inside the bunkers cannot pathfind to any point outside, causing `find_path()` to return an empty array.

## Evidence

Subagent graph component analysis confirmed Iron bunker spawn `(0, 76)` and Red bunker spawn `(0, -76)` are trapped in 3-node isolated subgraphs.

## Retest

Adjusted clearance calculation and ensured doorway clearance at bunker entries is preserved, establishing full path connectivity across all 5 spawns per faction.
