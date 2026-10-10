# Implementation Progress — STEAL A TIME

> Updated after every milestone. Anything marked done must have actually run.
> Status map: ✅ shipped & verified · 🟨 implemented, verification pending ·
> ⬜ planned.

## Foundation

- ✅ Rojo project scaffold: `default.project.json`, `syncback.project.json`.
- ✅ Build pipeline verified: `rojo build` → `game.rbxl` (opens clean, rbxmk inventory OK).
- ✅ Legacy place preserved: Baseplate, SpawnLocation, Rig, Rig_Legacy1 as `.rbxm`
  under `src/Workspace/`; original `place.rbxl/.rbxlx` archived.
- ✅ Tooling: `tools/cli/{rojo,rbxmk}.exe`, `tools/Rojo.rbxm`.
- ✅ Documentation suite (AGENTS.md, README.md, 10 design/eng docs). This file.
- ⬜ Git: seed repo with .gitignore for `.rbxl`, `game.rbxl`, `.DS_Store`, etc.

## Core loop (M1: hub + steal + death + upgrade)

- 🟨 `Config/` modules (Shared, Game, Balance, Zone) — shared scaffolding in progress.
- 🟨 `Remotes.luau` + `Validation.luau` + `ProfileSchema.luau`.
- 🟨 `ProfileService` (save queue, sanitize, session lock).
- 🟨 `ZoneService` (hub/zone membership from position).
- 🟨 `TimeService` (authoritative active-time decay loop, sync remote).
- 🟨 `StealService` (validation + reward math + cooldowns).
- 🟨 `TimeDeathService` (TIME'S UP, respawn, comeback, setback).
- 🟨 `NpcTimeSourceService` (village pillars).
- 🟨 `TeleportService` + warp pads.
- 🟨 Client HUD: TimerHud, ActionBar (Steal/Dash), Feedback, DeathOverlay.
- 🟨 World builder: Spawn Plaza + Clock Tower + pads + village pods.

## M2 (planned): Player City PvP, gangs, leaderboards, bounties, persistence hardening.

## M3 (planned): Vaults, trading, daily rewards, events, prestige.

## M4 (planned): battle pass cosmetics, moderation, analytics, launch hardening.

## Not yet built (explicit)

- Pets (design doc complete; not coded).
- Gangs / social / trading (not coded).
- Daily rewards, offline earnings, events (not coded).
- Prestige / rebirth (not coded).
- Leaderboards (planned service; not coded).
- Settings menu / accessibility options (not coded).
- Mobile controller overlays beyond basic buttons (not coded).

## Verification ledger (append-only)

- `2026-10-01` — `rojo build` produces `game.rbxl`; rbxmk inventory confirms
  Workspace.TimeSanctuary_World with Baseplate/SpawnLocation/Rig/Rig_Legacy1.
- Next: Studio Play smoke test rows in `testing-checklist.md` B/C/D.