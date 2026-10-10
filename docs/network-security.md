# Network Security — STEAL A TIME

## Trust model

The **server is the only authority**. LocalScripts may:
- request actions via `TS_*` remotes,
- display whatever the server sends.

They never decide amounts, validity, ownership, or timing.

## Remote catalog (created once in `Remotes.luau`)

| Remote | Direction | Purpose |
|---|---|---|
| `TS_StealRequest` | client→server (UnreliableEvent) | request steal by targetKey |
| `TS_TeleportRequest` | client→server | request zone warp |
| `TS_PurchaseRequest` | client→server (synchronous) | request purchase by itemId |
| `TS_ClaimDaily` | client→server | claim daily reward |
| `TS_ClaimOffline` | client→server | claim offline earnings |
| `TS_BankDeposit` / `TS_BankWithdraw` | client→server | move active↔banked |
| `TS_StealResult` / `TS_BankResult` | server→client | results |
| `TS_SyncTime` | server→client | authoritative timer sync + active effects |
| `TS_SyncProfile` | server→client | curated profile view (no secrets) |
| `TS_Announcement` / `TS_Feedback` | server→client | world messages / floating text |
| `TS_VictimWarn` | server→client | PvP victim warning |
| `TS_TimeUp` / `TS_RespawnNotice` | server→client | death + respawn flow |

## Server-side validation checklist (each remote)

Every handler runs through: `RateLimiter(player, action)` → argument type/range
table (`Validation`) → domain check (owner/zone/cooldown/state) → state mutation →
log.

**Steal** (`StealService`):
- player alive; not decaying-dead; zone ≠ HUB; target exists; target not hub;
  distance ≤ zone.maxStealDistance (server-calculated), ≤ `serverRange`; cooldown
  per target passed; rate limit per minute passed; target pool > 0; player has ≥
  minimum active time to participate; reward computed server-side with caps.

**Teleport**: pad exists; zone unlocked; player alive & not mid-death; rate limit;
position set server-side.

**Purchase**: itemId in catalog; cost taken from server state (never client);
requirements met; duplicate ownership guard; atomic deduct+grant; save queued.

**Claims/Daily**: server UTC day boundary; streak bookkeeping server-side; no dup
claim (flag + server day key); offline earnings from last math, capped.

**Bank**: transforms active↔banked within caps, both computed server-side;
negative-proof via clamped checks.

## Rate limiting (`RateLimiter`)

Token buckets per (player, action): steal `6/min`, teleport `6/min`, purchase
`10/min`, claims `3/min`, bank `10/min`.
Hard-abuse detection: > 3× limit or repeated invalid args → `suspect` level 1
(30s cooldown on that action + log); level 3 (temporary 5m action ban + evidence log);
never permanent bans from a single signal.

## Input validation (`Validation` module)

- Strings: length caps, character allowlists, filtered via `TextService:FilterStringAsync`.
- Numbers: `typeIs("number")`, finite, range-clamped.
- Tables: max size, key allowlists, value checks; no `rawget` arbitrary keys.
- IDs: only from server catalogs, never free-form.
- Booleans: must be actual booleans.

## Profile safety (`ProfileService`)

- Schema version field; load-time sanitize: unknown keys dropped, wrong types
  defaulted, strings trimmed+capped, tables size-capped.
- Client NEVER receives raw profile; receives `SyncProfile` presence-only view.
- No client-defined keys accepted anywhere.

## Anti-cheat posture

- Logs every refused request with player.UserId, action, reason, timestamp.
- Flag suspicious: impossible movement (speed > clamp + margin), steal frequency,
  invalid prices, remote spam, data mismatch.
- Response: warn → temp action restriction → reviewable evidence list.
- No public ban list; moderation path documented.

## Moderation

`AdminService` (future) uses server-only ranks (no client "admin" flags).
Text: all gang names, messages, names through `TextService:FilterStringAsync`
(for-place instances; on client pre-filter for display only — server re-filters).