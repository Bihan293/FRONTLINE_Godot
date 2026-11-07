# TASK-0018 — Localization and accessibility

- **Priority:** P2
- **Status:** planned
- **Owner:** OpenCode
- **Dependencies:** UI strings audit
- **Related:** `ROADMAP.md` → UI/UX

## Scope

- String table RU/EN, no hard-coded UI text in scripts.
- Language switch in settings, persisted.
- Colour-blind markers, subtitles for combat barks, HUD scale option.
- Safe-area handling for notches/gesture bars.

## Acceptance criteria

- Entire menu, HUD and pause screen switch RU/EN without restart.
- No missing-string placeholders in either language.
- Colour-blind mode keeps ally/enemy/sector markers distinguishable.
- UI fits 16:9 and 20:9 phones.
