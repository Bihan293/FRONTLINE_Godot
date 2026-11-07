# TASK-0003 — Add Village and Team Deathmatch

- **Priority:** P1
- **Status:** done
- **Owner:** Antigravity
- **Dependencies:** Current Battlefield build and shared `battlefield_layout.gd` map contract
- **Related:** `ROADMAP.md` → Maps and Game modes
- **Resolution:** Реализована карта `scripts/village_layout.gd` (180×150м: церковь с колокольней, центральная площадь с колодцем, мельница с амбаром, 6 жилых домов, заборы, сеновалы, взрывные бочки), тактический интерактивный вид сверху `scripts/village_map_preview.gd`, переключатель режима TDM (до 50 фрагов) и адаптация навигации ботов в `scripts/bot_navigation.gd` и `scripts/soldier_bot.gd`.

## Scope

- Add a separate Village map with houses, fences, barns, wells, and narrow streets.
- Add a selectable Team Deathmatch mode with no sector ticket bleed.
- Provide faction spawn positions and a map preview generated from Village layout data.

## Acceptance criteria

- Village can be selected, deployed on, and played by both factions.
- Bots can leave both spawn areas, navigate around buildings, and engage the opposing team.
- TDM ends at its configured frag limit and displays the winner.

