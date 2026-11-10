# Folder Structure — STEAL A TIME

Rojo source layout (`default.project.json` maps `src/` → game services).
Every file below is real; if the tree and this doc disagree, the tree wins and
this doc is a bug.

```
ROBLOX-THE-LAST-SHORTCUT/
├── default.project.json          # Rojo project: the authoritative layout
├── syncback.project.json         # legacy import helper (not used to build the game)
├── AGENTS.md / README.md
├── tools/
│   ├── Rojo.rbxm                 # Studio plugin
│   └── cli/                      # rojo.exe, rbxmk.exe, luau/{luau,luau-compile,luau-analyze,luau-ast}.exe
├── place.rbxl / place.rbxlx      # original place archive (read-only reference)
├── game.rbxl                     # ROJO BUILD OUTPUT — never edit by hand
└── src/
    ├── ReplicatedStorage/        → ReplicatedStorage.TimeSanctuary
    │   ├── Config/               # every tunable number lives here
    │   │   ├── GameConfig.luau   # world folder names, remotes folder, decay tick, caps
    │   │   ├── BalanceConfig.luau# upgrades, pets, prestige, daily, steal caps, starting time
    │   │   ├── ZoneConfig.luau   # zones, pads, interactables, NPC pillars, spawn points
    │   │   ├── EconomyConfig.luau# bank/shop/offline/prestige/leaderboard/tutorial/character
    │   │   └── SocialConfig.luau # gangs, trade, events, anti-cheat, name rules
    │   ├── Remotes.luau          # creates RemotesFolder + all TS_* remotes (server side)
    │   ├── Validation.luau       # untrusted-input validation helpers
    │   ├── ProfileSchema.luau    # default profile, schema v2, sanitise, BankCap, Snapshot
    │   └── SharedLoader.luau     # bundles the above for convenient client/server requires
    │
    ├── ServerScriptService/      → ServerScriptService.TimeSanctuary
    │   ├── init.server.luau      # bootstrap: require + Start services in dependency order
    │   ├── services/             # 21 one-job modules
    │   │   ├── RateLimiter.luau          # per-player/action sliding windows + suspect counts
    │   │   ├── ProfileService.luau       # DataStore load/save, dirty queue, fan-out, SyncAll
    │   │   ├── ZoneService.luau          # position → zone, pad placement, tutorial hooks
    │   │   ├── NpcTimeSourceService.luau # per-pillar pools, regen, take/refund
    │   │   ├── TimeService.luau          # authoritative active time, decay, protection
    │   │   ├── TimeDeathService.luau     # TIME'S UP pipeline, setback, comeback, respawn
    │   │   ├── StealService.luau         # NPC + PvP steal validation and rewards
    │   │   ├── TeleportService.luau      # server-validated warp pads
    │   │   ├── BankService.luau          # deposit/withdraw active ↔ banked
    │   │   ├── ShopService.luau          # upgrades, pets, bank-capacity tiers
    │   │   ├── DailyService.luau         # 7-day rotating rewards + streak
    │   │   ├── OfflineService.luau       # offline earnings accrual + claim
    │   │   ├── PrestigeService.luau      # 5 tiers, resets, titles, steal bonus
    │   │   ├── LeaderboardService.luau   # two ordered stores + memory fallback
    │   │   ├── GangService.luau          # create/deposit/invite/accept/kick/leave/disband
    │   │   ├── TradeService.luau         # banked-time trade sessions
    │   │   ├── EventService.luau         # weekday event rotation + multipliers
    │   │   ├── TutorialService.luau      # 6-step onboarding flow
    │   │   ├── CharacterService.luau     # speed, dash, stealth, auto-steal, ability sync
    │   │   ├── AntiCheatService.luau     # out-of-bounds, speed correction, suspect kick
    │   │   └── SettingsService.luau      # persisted boolean toggles
    │   └── world/
    │       └── WorldBuilder.luau # hub, clock towers, travel + facility pads, zone floors, pillars
    │
    ├── StarterPlayer/
    │   └── StarterPlayerScripts/ → StarterPlayer.StarterPlayerScripts.TimeSanctuary
    │       ├── init.client.luau  # client bootstrap: builds UI, wires every remote
    │       └── ui/               # view-only; never authoritative
    │           ├── UIKit.luau        # palette + row/label/button/textbox builders
    │           ├── TimerHud.luau     # top-centre timer, colour thresholds
    │           ├── ActionBar.luau    # steal / nearest-target list, keyboard + touch
    │           ├── Feedback.luau     # floating text + announcement feed
    │           ├── DeathOverlay.luau # TIME'S UP overlay
    │           ├── Panels.luau       # bank/shop/daily/leaderboard/gang/trade/prestige/event/settings/tutorial
    │           ├── PadInteraction.luau# 44px+ on-screen pad interaction button
    │           ├── DashButton.luau   # mobile-friendly dash trigger
    │           └── TutorialHud.luau  # tutorial step banner
    │
    ├── StarterGui/               → StarterGui.TimeSanctuary (reserved)
    │
    └── Workspace/                → Workspace.TimeSanctuary_World (preserved legacy models)
        ├── Baseplate.rbxm
        ├── SpawnLocation.rbxm
        ├── Rig.rbxm              # preserved legacy work
        └── Rig_Legacy1.rbxm

docs/                             # design + engineering documentation
├── product-requirements.md
├── game-design.md
├── technical-architecture.md
├── folder-structure.md
├── world-layout.md
├── economy-balance.md
├── network-security.md
├── testing-checklist.md
├── implementation-progress.md
└── known-issues.md
```

## Naming rules that matter

- The remotes container is **`RemotesFolder`**, not `Remotes`. The ModuleScript is
  itself named `Remotes`, so a same-named child folder would be ambiguous to
  `FindFirstChild`.
- Service module files are plain `.luau` (ModuleScripts). Only
  `init.server.luau` / `init.client.luau` become executable Script/LocalScript.
- `ctx.Services` keys equal the file names (`ProfileService`, `TimeService`, …).
  The bootstrap also exposes `ctx.services` / `ctx.state` aliases.

## Conventions

- Services: `XxxService` in `services/`. Each exposes `Start(ctx)` returning
  `true/false`, and logs `[TimeSanctuary] XxxService started`.
- Config: constant = `UPPER_CASE`; lookup function = camelCase; all numbers in Config.
- Remote names: `TS_<Action>` (e.g. `TS_StealRequest`, `TS_SyncTime`).
- Files: `.server.luau` = Script, `.client.luau` = LocalScript, `.luau` = ModuleScript.
- World: static geometry → `.rbxm` under `src/Workspace/`; procedural builds →
  `world/WorldBuilder.luau` (runs on the server at boot).
- No hand edits to `game.rbxl`; it is generated.
