# Technical Architecture — STEAL A TIME

## Principles

1. **Server-authoritative.** Every value that affects the game lives and mutates
   only server-side. Clients may *request* and *display*; they never decide.
2. **No client trust.** All RemoteEvent/Function args are hostile input.
3. **Single source of balance.** All tunables live in `Config/` modules.
4. **Services own one job.** `services/` — one module per concern, started once,
   in an explicit dependency order.
5. **Controlled persistence.** Only `ProfileService` writes player data; gang and
   leaderboard stores are owned by their own services.
6. **Honest testing.** Nothing is "done" until it ran in Studio and logged it.

## Runtime layout

```
ReplicatedStorage.TimeSanctuary
├── Config/GameConfig, BalanceConfig, ZoneConfig, EconomyConfig, SocialConfig
├── Remotes             (creates RemotesFolder + all TS_* remotes on the server)
├── Validation          (untrusted-input validation helpers)
├── ProfileSchema       (default profile, schema v2, sanitise, BankCap, Snapshot)
└── SharedLoader        (one require surface for the modules above)

ServerScriptService.TimeSanctuary
├── init.server.luau     Bootstrap: require in one order, Start in another
├── services/            21 one-job service modules
│   ├── RateLimiter              sliding-window limiter + suspect escalation
│   ├── ZoneService              position → zone, pad placement, tutorial hooks
│   ├── NpcTimeSourceService     per-pillar pools, regen, take/refund
│   ├── ProfileService           DataStore load/save, dirty queue, BindToClose flush
│   ├── TimeService              active time, decay loop, protection, sync
│   ├── TimeDeathService         TIME'S UP pipeline, setback, comeback, respawn
│   ├── StealService             NPC + PvP validation, reward math, cooldowns
│   ├── TeleportService          warp-pad requests (server-validated)
│   ├── BankService              deposit/withdraw active ↔ banked
│   ├── ShopService              upgrades, pets, bank-capacity tiers
│   ├── DailyService             7-day rewards + streak
│   ├── OfflineService           offline earnings accrual + claim
│   ├── PrestigeService          5 tiers, resets, titles, steal bonus
│   ├── LeaderboardService       two ordered stores + memory fallback
│   ├── GangService              persisted gang registry + invite flow
│   ├── TradeService             banked-time trade sessions
│   ├── EventService             weekday rotation + NPC/PvP multipliers
│   ├── TutorialService          6-step onboarding
│   ├── CharacterService         speed, dash, stealth, auto-steal
│   ├── AntiCheatService         out-of-bounds, speed correction, suspect kick
│   └── SettingsService          persisted boolean toggles
└── world/WorldBuilder.luau      procedural hub + zones + pads + pillars

StarterPlayer.StarterPlayerScripts.TimeSanctuary
├── init.client.luau     Bootstrap: build UI, subscribe to every remote
└── ui/                  view-only (login/display); no authoritative logic
    ├── UIKit            palette + row/label/button/textbox builders
    ├── TimerHud         top-centre timer (colour thresholds, throttled)
    ├── ActionBar        steal targets + keyboard/touch buttons
    ├── Feedback         floating text + announcement feed
    ├── DeathOverlay     TIME'S UP screen
    ├── Panels           all facility panels (bank/shop/daily/leaderboard/
    │                    gang/trade/prestige/event/settings/tutorial)
    ├── PadInteraction   44px+ on-screen pad prompt button
    ├── DashButton       mobile-friendly dash trigger
    └── TutorialHud      tutorial step banner
```

### Bootstrap contract

`init.server.luau` builds a single `ctx` and passes it to every service:

| `ctx` field | Contents |
|---|---|
| `ctx.Config` | `Game`, `Balance`, `Zones`, `Economy`, `Social` |
| `ctx.Remotes` | the `Remotes` module (`Remotes.Get(name)`) |
| `ctx.Validation` | `Validation` helpers |
| `ctx.ProfileSchema` | schema, sanitise, `BankCap`, `Snapshot` |
| `ctx.Services` | map keyed by module file name, incl. `WorldBuilder` |
| `ctx.State` | shared state (e.g. `processingDeath` locks) |
| `ctx.services`, `ctx.state` | lowercase aliases kept for older services |

Each service is required first, then `Start(ctx)` is pcall'd in dependency order.
A failure is logged (`<Name> failed to start: …`) and does not abort boot; the
final line is `[TimeSanctuary] bootstrap complete`. `BindToClose` flushes
`ProfileService` and `GangService`.

## Remote catalogue

All remotes are created by `Remotes.luau` inside a folder named
**`RemotesFolder`** (deliberately not `Remotes`, which is the module's own name).
Requests are `UnreliableRemoteEvent` where loss is acceptable, `RemoteFunction`
where the caller needs a reply, and results are `RemoteEvent`.

| Kind | Remotes |
|---|---|
| Events | `TS_StealResult`, `TS_SyncTime`, `TS_Announcement`, `TS_Feedback`, `TS_VictimWarn`, `TS_TimeUp`, `TS_RespawnNotice`, `TS_SyncProfile`, `TS_CooldownSync`, `TS_BankUpdate`, `TS_DailyUpdate`, `TS_LeaderboardUpdate`, `TS_GangUpdate`, `TS_TradeUpdate`, `TS_EventUpdate`, `TS_TutorialUpdate`, `TS_AbilityState` |
| Unreliable | `TS_StealRequest`, `TS_TeleportRequest`, `TS_BankDeposit`, `TS_BankWithdraw`, `TS_DashRequest`, `TS_StealthRequest` |
| Functions | `TS_PurchaseRequest`, `TS_ClaimDaily`, `TS_ClaimOffline`, `TS_PrestigeRequest`, `TS_GangAction`, `TS_TradeAction`, `TS_SettingsAction`, `TS_LeaderboardRequest`, `TS_TutorialAction`, `TS_ProfileRequest` |

Each RemoteFunction has exactly one `OnServerInvoke` owner.

## Profile fan-out

`ProfileService` loads a profile, then:
1. calls `OnProfileReady(player)` on every service that defines it (bank, daily,
   leaderboard, event, tutorial, character, gang …);
2. calls `SyncAll(player)` to push the full snapshot.

The client also fires `TS_ProfileRequest` on start. The server answers with the
current snapshot, and re-sends after ~3s so a client that connected late still
receives state. Profiles are only ever mutated via `ProfileService`.

## Decay loop (TimeService)

- One server loop tick (`Config.Game.DecayTick`). For each player with a loaded
  profile: `activeTime -= dt * zoneDecayRate` when the zone is not the hub, the
  humanoid is alive, and the player is not protected.
- State lives in a `userId → number` table; the client never echoes time back.
- `TS_SyncTime` is throttled to the player. `TimeService.SetTime` /
  `AwardTime` are the only mutation entry points for other services.

## Steal flow (authoritative)

1. Client fires `TS_StealRequest(targetKey)` (NPC pillar id or player UserId).
2. Server checks, each with a reason code: player alive and not in hub; target
   exists and not in hub; distance ≤ zone range; per-target cooldown; pool has
   time; hourly cap; rate limit.
3. Server computes the reward from zone base, NPC/PvP caps, upgrade/pet/prestige
   multipliers and event multipliers — never from client values.
4. Transfer is applied atomically (pool −= r, player += r); pool time is refunded
   if the hourly cap rejects the steal.
5. Result → `TS_StealResult`; PvP victim → `TS_VictimWarn`; profile marked dirty.

## Death pipeline (TimeDeathService)

Triggered by `TimeService` when `activeTime <= 0`:
- `ctx.State.processingDeath[userId]` lock; duplicate requests discarded.
- Decay suspended, character respawned to the hub, `startingTime` restored,
  comeback bonus applied inside its window, banked setback applied
  (`DeathBankSetbackFraction`, reduced by Time Insurance, skipped by Second
  Chance), then spawn protection for `RespawnProtectionSeconds`.
- Saves via `ProfileService`, then broadcasts `TS_TimeUp` + `TS_RespawnNotice`.

## Economy and social notes

- All purchases are paid from `bankedTime`; prices come from config tables, never
  from the client.
- Bank cap is enforced on deposit and on withdrawal (active time is capped too).
- `GangService` keeps a single registry document in a DataStore with a debounced
  save; invites are in-memory (ephemeral) and cleared on leave/disband.
- `TradeService` sessions expire after `SocialConfig.Trade.SessionSeconds`; a
  sweeper closes stale sessions with a reason.
- `LeaderboardService` uses one OrderedDataStore per board
  (`<StoreName>_<board>`) and falls back to an in-memory sort when DataStore is
  unavailable (Studio).

## Persistence

- DataStore behind `ProfileService`: schema version + migration, sanitise on load,
  10s autosave of dirty profiles, `BindToClose` flush.
- Session lock is an in-process memory lock; profile tables are never exposed to
  clients except through `ProfileSchema.Snapshot`.
- Never save Instance references. Never merge a client table into a profile.

## Failure policy

Any service throw at boot is caught, logged, and visible in Output; the rest of
boot continues so one broken system does not hide the others. `rojo build` and
`luau-compile --null src` must both exit 0 before a change is considered done.
