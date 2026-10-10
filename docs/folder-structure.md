# Folder Structure — STEAL A TIME

Rojo source layout (`default.project.json` maps src/ → game services).

```
ROBLOX-THE-LAST-SHORTCUT/
├── default.project.json          # Rojo project: the authoritative layout
├── syncback.project.json         # legacy import helper (not used for building the game)
├── AGENTS.md / README.md
├── tools/
│   ├── Rojo.rbxm                 # Studio plugin
│   └── cli/                      # rojo.exe, rbxmk.exe (build/convert utilities)
├── place.rbxl / place.rbxlx      # original place archive (read-only reference)
├── game.rbxl                     # ROJO BUILD OUTPUT — never edit by hand
└── src/
    ├── ReplicatedStorage/        → ReplicatedStorage.TimeSanctuary
    │   ├── Config/               # Balance & game config modules (single source of truth)
    │   │   ├── SharedConfig.luau
    │   │   ├── GameConfig.luau
    │   │   ├── BalanceConfig.luau
    │   │   └── ZoneConfig.luau
    │   ├── Remotes.luau          # All TS_* remotes created here
    │   ├── Validation.luau       # input validation helpers (server-usable, client-safe)
    │   └── ProfileSchema.luau    # profile default, schema version, migrations, limits
    │
    ├── ServerScriptService/      → ServerScriptService.TimeSanctuary
    │   ├── init.server.luau      # bootstrap (order matters)
    │   └── services/             # one module per concern
    │       ├── ProfileService.server.luau
    │       ├── RateLimiter.server.luau
    │       ├── ZoneService.server.luau
    │       ├── TeleportService.server.luau
    │       ├── TimeService.server.luau
    │       ├── StealService.server.luau
    │       ├── TimeDeathService.server.luau
    │       ├── NpcTimeSourceService.server.luau
    │       └── LeaderboardService.server.luau
    │
    ├── StarterPlayer/
    │   └── StarterPlayerScripts/ → StarterPlayer.StarterPlayerScripts.TimeSanctuary
    │       ├── init.client.luau  # client bootstrap
    │       └── ui/
    │           ├── TimerHud.client.luau
    │           ├── ActionBar.client.luau
    │           ├── Feedback.client.luau
    │           └── DeathOverlay.client.luau
    │
    ├── StarterGui/               → StarterGui.TimeSanctuary (GUI instances if needed)
    │
    └── Workspace/                → Workspace.TimeSanctuary_World (pre-built world)
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

## Conventions

- Services: `XxxService` in `services/`. Each has `Start()` returning `true/false`,
  logs `[TimeSanctuary] XxxService started`.
- Config: constant = `UPPER_CASE`; lookup function = camelCase; all numbers in Config.
- Remote names: `TS_<Action>` (e.g., `TS_StealRequest`, `TS_SyncTime`).
- Files: `.server.luau` = Script, `.client.luau` = LocalScript, `.luau` = ModuleScript.
- World: static geometry → `.rbxm` under `src/Workspace/`; procedural builds →
  dedicated builder scripts under `src/ServerScriptService/.../builders/`.
- No hand edits to `game.rbxl`; it is generated.