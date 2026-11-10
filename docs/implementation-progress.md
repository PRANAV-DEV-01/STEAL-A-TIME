# Implementation Progress — STEAL A TIME

> Updated after every milestone. Anything marked done must have actually run.
> Status map: ✅ shipped & verified · 🟨 implemented, verification pending ·
> ⬜ planned.

## Foundation

- ✅ Rojo project scaffold: `default.project.json`.
- ✅ Build pipeline verified: `rojo build` → `game.rbxl` (opens clean).
- ✅ Static analysis verified: `luau-compile --null src` exits 0 and
  `luau-analyze` reports no errors beyond unknown Roblox globals.
- ✅ Legacy place preserved: Baseplate, SpawnLocation, Rig, Rig_Legacy1 as `.rbxm`
  under `src/Workspace/`; original `place.rbxl/.rbxlx` archived.
- ✅ Tooling: `tools/cli/{rojo,rbxmk,luau}`.
- ✅ Documentation suite (AGENTS.md, README.md, 10 design/eng docs). This file.
- ✅ Git repo initialised, pushed to GitHub (`PRANAV-DEV-01/STEAL-A-TIME`).

## Core loop

- ✅ `Config/` modules: `GameConfig`, `BalanceConfig`, `ZoneConfig`,
  `EconomyConfig`, `SocialConfig`. Every tunable is here.
- ✅ `Remotes.luau` (17 events, 6 unreliable events, 10 remote functions),
  `Validation.luau`, `ProfileSchema.luau` (schema v2).
- ✅ `RateLimiter` (per-player/action sliding window + suspect counter).
- ✅ `ProfileService` (DataStore load/save, sanitize, dirty flags, 10s autosave,
  `BindToClose` flush, per-player `OnProfileReady` fan-out, `SyncAll`).
- ✅ `ZoneService` (position-based zone resolution, pad placement, tutorial hooks).
- ✅ `TimeService` (authoritative active-time decay, protection, sync broadcast).
- ✅ `StealService` (NPC + PvP validation, multipliers, cooldowns, hourly cap).
- ✅ `TimeDeathService` (TIME'S UP, bank setback, insurance, Second Chance,
  comeback window, respawn protection).
- ✅ `NpcTimeSourceService` (per-pillar pools, regen, refund).
- ✅ `TeleportService` (rate-limited warp pads, death lock).
- ✅ `WorldBuilder` (hub floor, clock towers, travel pads, 10 facility pads,
  17 NPC pillars, 6 zone floors/signs, legacy freeze/spawn handling).
- ✅ Client HUD: `TimerHud`, `ActionBar`, `Feedback`, `DeathOverlay`,
  `UIKit`, `Panels`, `PadInteraction`, `DashButton`, `TutorialHud`.

## Economy systems

- ✅ `BankService` — deposit/withdraw between active and banked time, cap aware.
- ✅ `ShopService` — upgrades, pets (buy/equip/unequip), bank-capacity tiers.
- ✅ `OfflineService` — offline earnings accrual + claim.
- ✅ `DailyService` — 7-day rotating rewards, streak logic, ability/pet/title grants.
- ✅ `PrestigeService` — 5 tiers, resets, titles, +5% steal power per prestige.
- ✅ Leaderboard data in `LeaderboardService` (two ordered stores + memory fallback).

## Social systems

- ✅ `GangService` — create/deposit/invite/accept/decline/leave/kick/disband,
  persisted registry, online/offline member view, 20-member cap.
- ✅ `TradeService` — request/accept/decline/offer/confirm/cancel banked-time
  trades with 60s sessions and stale-session sweeper.
- ✅ `LeaderboardService` — `totalTimeStolen` + `bankedTime` boards, 60s refresh,
  `TS_LeaderboardRequest` on-demand refresh.
- ✅ `EventService` — weekday event rotation (Weekend Rush, Vault Heist, Gang War)
  with NPC/PvP multipliers.

## Progression / character / safety

- ✅ `TutorialService` — 6-step flow, hints, skip/restart, completion reward + title.
- ✅ `CharacterService` — speed upgrades, dash, stealth, auto-steal, ability state sync.
- ✅ `AntiCheatService` — out-of-bounds teleport-to-hub, speed correction, suspect kick.
- ✅ `SettingsService` — persisted boolean toggles (music, sfx, tutorial, shake, particles).
- ✅ Mobile-friendly UI: 44px+ touch targets, on-screen pad prompt button.
- ✅ Timer colours: >30 green, ≤30 yellow, ≤15 orange, ≤5 red.

## Verification status (honest)

- 🟨 Every system above is **implemented and builds**, but **none of it has been
  played in Studio by the agent**. Studio is not available in this environment.
- 🟨 DataStore persistence, PvP/trading/multi-client behaviours, mobile layout,
  and anti-cheat need a Studio / published test server run. See
  `testing-checklist.md`, `known-issues.md` (KI-002, KI-003, KI-005).
- ⬜ Battle pass, cosmetics shop, moderation tooling, analytics (not coded).

## Verification ledger (append-only)

- `2026-10-01` — `rojo build` produces `game.rbxl`; Workspace.TimeSanctuary_World
  contains Baseplate/SpawnLocation/Rig/Rig_Legacy1.
- `2026-11-10` — full expansion pass: 22 services + 8 client UI modules; `rojo
  build` exits 0; `luau-compile --null src` exits 0; `luau-analyze` clean apart
  from unknown Roblox globals. Studio Play verification pending (user-run).
