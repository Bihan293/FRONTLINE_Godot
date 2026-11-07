# TASK-0026 — Co-op / online multiplayer

- **Priority:** P3
- **Status:** blocked until single-player v1.0
- **Owner:** Codex / Antigravity
- **Dependencies:** All P0/P1 single-player work, stable netcode design
- **Related:** `ROADMAP.md` → Сеть

## Scope

- Start with LAN/host-client co-op for 2–4 players.
- Authoritative host, bot synchronisation, damage/grenade/vehicle sync.
- Lobby, invite, reconnect and match settings sync.
- Online matchmaking only after stable co-op.

## Acceptance criteria

- Two players finish a full match with bots without desync.
- Host migration or clean disconnect handling.
- No regression to single-player performance.
- Security: no client-trusted damage or infinite ammo.

## Note

Do not start before the single-player release gate is signed. Multiplayer doubles the cost of every gameplay change.
