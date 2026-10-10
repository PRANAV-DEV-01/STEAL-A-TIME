# Technical Architecture — STEAL A TIME

## Principles

1. **Server-authoritative.** Every value that affects the game lives and mutates
   only server-side. Clients may *request* and *display*; they never decide.
2. **No client trust.** All RemoteEvent/Function args are hostile input.
3. **Single source of balance.** All tunables live in `Config/` modules.
4. **Services own one job.** `src/ServerScriptService/.../services/` — one module
   per concern, started once, no cross-service circular mess.
5. **Controlled persistence.** Only `ProfileService` reads/writes player data.
6. **Honest testing.** Nothing is "done" until it ran in Studio and logged it.

## Runtime layout

```
ReplicatedStorage.TimeSanctuary
├── Config/SharedConfig, GameConfig, BalanceConfig, ZoneConfig, ...
├── Remotes            (RemoteEvents/RemoteFunctions definition + init)
├── Validation         (server validation helpers)
└── ProfileSchema      (profile default + migration + size limits)

ServerScriptService.TimeSanctuary
├── init.server.luau            Bootstrap: require services in dependency order
└── services/
    ├── ProfileService      → owns DataStore saves, save queue, session lock
    ├── RateLimiter         → shared token-bucket per (player, action)
    ├── ZoneService         → authoritative hub/zone membership from position
    ├── TeleportService     → warp-pad requests (server-validated)
    ├── TimeService         → authoritative active time, decay loop, delegations
    ├── StealService        → steal validation, reward math, cooldowns
    ├── TimeDeathService    → TIME'S UP pipeline, respawn, comeback, setback
    ├── NpcTimeSourceService→ NPC time pillars & small caches
    └── LeaderboardService  → server values, throttled/cached output

StarterPlayer.StarterPlayerScripts.TimeSanctuary
├── init.client.luau   Bootstrap: build HUD, subscribe to remotes
└── ui/
    ├── TimerHud    top-center timer (color states, throttle)
    ├── ActionBar   Steal / Dash / Interact buttons (mobile + keyboard)
    ├── Feedback    floating texts, announcements, warnings
    └── DeathOverlay TIME'S UP screen
```

## Decay loop (TimeService)

- One server loop tick (e.g., 0.25s) or timestamp math. Per player:
  - `activeTime -= dt * zoneDecayRate` when zone ≠ HUB and alive and not recently protected.
  - All state in a memory table keyed by player.UserId. No client echo of time.
- Sync: broadcast `SyncTime` (event) on change or throttle 0.5s to that player.

## Steal flow (authoritative)

1. Client fires `TS_StealRequest(targetKey)` (NPC id or player UserId).
2. Server checks (each fails with a reason code): player alive & not hub; target
   exists & not hub; zone valid; distance ≤ range (server-calculated); cooldown
   passed for that target; target has stealable pool; rate limit OK.
3. Server computes reward:
   `base = ZoneConfig.baseReward(z) · NPC/pet/upgrade multipliers · eventBonus`,
   all capped by `BalanceConfig.maxStealReward` and remaining target pool.
4. Apply transfer atomically (target pool -= r, player += r), set cooldowns,
   log, save through ProfileService queue, fire `StealResult` + VFX feedback.
5. PvP victim receives `VictimWarning` remote event.

## Death pipeline (TimeDeathService)

Triggered only by TimeService when `activeTime <= 0`. Guards:
- per-player `isProcessingDeath` lock; duplicate request discarded.
- Suspend decay, cancel steal cooldown-only operations, respawn to hub.
  Restore `startingTime`, grant comeback bonus (tied duration, e.g., +15s start,
  5min no-loss period), apply setback to banked time (documented), protect 30s.
- Save via ProfileService queue; broadcast `TimeUp` + `RespawnNotice`.

## Teleport flow

Remote `TS_TeleportRequest(zoneId)` → server checks zone unlocked & pad exists &
player ready (alive, not mid-death) → moves root part / respawns to pad point, sets zone.

## Networking conventions

- One `Remotes` module creates all remotes at boot with names `TS_*`.
- Requests → RemoteFunction or UnreliableEvent; results → RemoteEvent.
- All requests routed through `RateLimiter` with per-action tokens.

## Persistence (ProfileService)

- DataStore wrapped behind an interface; schema-versioned, default profile,
  migration LUT, retry+backoff, session lock (equivalent in-session memory lock),
  save queue with debounce + BindToClose flush.
- Profile shape validated on load (types, string lengths, number ranges, table sizes).
- Never save Instance refs. Never accept client tables into the profile.

## Studio / served testing

- `rojo build` → `game.rbxl` (static test) or `rojo serve` (live).
- Drone QA per `docs/testing-checklist.md`.

## Failure policy

Any service throw at boot is logged and visible in Studio Output; bootstrap marks
the service failed rather than silently continuing with broken state.