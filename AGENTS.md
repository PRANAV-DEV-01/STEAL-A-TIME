# AGENTS.md — STEAL A TIME (Time Sanctuary)

This file is the **permanent source of project instructions**. Read it before changing anything. It overrides vague defaults when reasoning about this codebase.

## What this project is

**Steal a Time** — a time-stealing multiplayer Roblox simulator. Players spawn in
`TIME SANCTUARY`, a large safe hub, then travel to danger zones to steal active
time from NPCs and other players, return to the hub to bank/spend time, upgrade,
and repeat.

All authoritative game logic runs **on the server**. LocalScripts are UI/view only.

## How to run the project

Everything under `src/` is a Rojo source tree. Consumed tools live in `tools\cli`.

```powershell
# 1. Rebuild the place file from source
tools\cli\rojo.exe build default.project.json --output game.rbxl

# 2A. Test in Studio (static build — recommended first)
#     - Open game.rbxl via File > Open from File...

# 2B. Test in Studio (live sync — recommended for iteration)
tools\cli\rojo.exe serve default.project.json
#     - Enable the Rojo Studio plugin (tools\Rojo.rbxm), pair to the session.
```

`rojo build` must exit without errors before any change is considered done.

## How to test in Roblox Studio

1. Open `game.rbxl` (built from source) or connect via `rojo serve`.
2. Press **Play** (F5). Studio Play mode runs the server scripts.
3. Watch the **Output** window for the boot log:
   - `[TimeSanctuary] bootstrap` line = services all started.
4. Test checklist: `docs/testing-checklist.md`. Never mark a system "tested" unless
   it ran in Studio and produced the expected behavior.
5. Anticheat note: Studio servers and Client-server replication behave differently
   than published; remote validation also needs a published/Test-servers check.

## Folder conventions (Rojo mapping — `default.project.json`)

| Source path | Becomes | Contents |
|---|---|---|
| `src/ReplicatedStorage/` | `ReplicatedStorage.TimeSanctuary` | Shared config, remotes, types, profile schema |
| `src/ServerScriptService/` | `ServerScriptService.TimeSanctuary` | Server services + bootstrap |
| `src/StarterPlayer/StarterPlayerScripts/` | `StarterPlayer.StarterPlayerScripts.TimeSanctuary` | Client UI/controllers (view only) |
| `src/StarterGui/` | `StarterGui.TimeSanctuary` | Reserved for GUI instances if needed |
| `src/Workspace/` | `Workspace.TimeSanctuary_World` | Pre-built world models (.rbxm from original place) |
| `tools/` | — (not built) | Rojo plugin, CLI binaries |
| `docs/`, `AGENTS.md`, `README.md` | — | Documentation, not built |

- Files ending `.server.luau` → `Script` (runs on server).
- Files ending `.client.luau` → `LocalScript` (runs on client). No game logic here.
- `init.luau`/`init.server.luau`/`init.client.luau` → ModuleScript/Script for that folder.
- Plain `.luau` → `ModuleScript`.

## Naming conventions

- Services: `XxxService` (e.g. `TimeService`), owned by their own module in
  `services/`.
- RemoteEvents/Functions: `TS_` prefix in a single `Remotes` module; never created
  ad-hoc in feature code.
- Config values live in `Config/` modules — **balance numbers never hardcode in scripts**.
- Profile fields: camelCase; schema version in `ProfileSchema`.
- Prefabs/zones: `Zone_<Name>`, `Pad_<Name>`, `NPC_<Name>`.

## Server/client security rules (non-negotiable)

1. **Never trust a client.** Every RemoteEvent/Function argument is untrusted input.
2. Validate on the server: player existence, target existence, zone, distance,
   cooldown, resource amounts, and that rewarded/charged values match **server**
   calculations — never client-sent prices/rewards.
3. No authoritative logic in LocalScripts. LocalScripts may only *request* and *display*.
4. No secrets in code reachable by clients (DataStore keys, admin keys).
5. Rate-limit every remote per player (`RateLimiter` helper) and log abuse.
6. Clamp all timers/currency to sane ranges; reject negatives.
7. Player profiles are modified only through `ProfileService`; never saved ad-hoc.
8. Duplicate-processing protection: death/claim/purchase paths lock per player until settled.

## Required validation

Every player-facing input (steal target, purchase, claim, trade, teleport, gang op)
MUST pass through `Validation` helpers in `src/ReplicatedStorage/TimeSanctuary/Shared`.
See `docs/network-security.md` and `docs/economy-balance.md` for the authoritative
rule lists.

## Definition of done

- `rojo build` succeeds.
- The feature has a matching entry in `docs/testing-checklist.md`.
- It was actually exercised AND logged in Studio (or explicitly documented as
  "not testable here, requires Studio/published test").
- Server-side validation exists for every client-accessible input.
- Balance values are in Config, not scattered.
- `docs/implementation-progress.md` and `docs/known-issues.md` are updated.
- No fake claims: never state something ran unless it ran.

## What to do when starting work

1. Read `docs/implementation-progress.md` and `docs/known-issues.md`.
2. Read this file's rules again.
3. Check `rojo build` still passes before and after changes.