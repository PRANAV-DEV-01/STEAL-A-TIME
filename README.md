# STEAL A TIME — Time Sanctuary

A time-stealing multiplayer Roblox simulator. Safely spawn in TIME SANCTUARY,
then steal active seconds from NPCs and rivals in danger zones, return to the
hub, bank, upgrade, and repeat.

> **Status:** EARLY DEVELOPMENT — core loop only. See
> `docs/implementation-progress.md` for exactly what exists vs. what is planned.

## Repository layout

```
ROBLOX-THE-LAST-SHORTCUT/
├── default.project.json      Rojo project (game layout)
├── syncback.project.json     Used only to re-import the legacy place
├── AGENTS.md                 Project instructions (read first)
├── README.md
├── tools/
│   ├── Rojo.rbxm             Studio plugin (drag into Studio plugins folder)
│   └── cli/rojo.exe, rbxmk.exe
├── src/                      Rojo source tree (the actual game)
│   ├── ReplicatedStorage/    Shared modules
│   ├── ServerScriptService/  Server services
│   ├── StarterPlayer/…/      Client scripts
│   ├── StarterGui/
│   └── Workspace/            World models (from the original place file)
├── docs/                     Design + engineering docs
└── place.rbxlx, place.rbxl   Archive of the original base place
```

## Quick start

Prereqs: Roblox Studio installed.

1. **Build:** `tools\cli\rojo.exe build default.project.json --output game.rbxl`
2. **Play in Studio:** File → Open from File… → `game.rbxl` → Play (F5).
3. **Live-sync (iteration):**
   - `tools\cli\rojo.exe serve default.project.json`
   - In Studio, install the plugin from `tools\Rojo.rbxm`
     (File → Plugins → install from file, or Settings → Plugins folder), then
     Rojo → Connect.

If this is your first time, follow the walkthrough in `docs/testing-checklist.md`.

## Current features (real)

- Rojo build pipeline verified (`game.rbxl` builds from `src/`).
- Legacy places preserved as Rojo world models under `src/Workspace/`.
- Server-authoritative foundation modules (Config, Remotes, Validation, Profile).
- [Progress doc updates as systems land.]

## Design docs

- `docs/product-requirements.md` — the complete product spec and roadmap.
- `docs/game-design.md` — core loop, systems, and player experience.
- `docs/technical-architecture.md` — server architecture, services, security model.
- `docs/folder-structure.md` — every folder and what belongs in it.
- `docs/world-layout.md` — hub + zone geometry and rules.
- `docs/economy-balance.md` — all balance values and the balance rules.
- `docs/network-security.md` — authoritative validation, rate limiting, anti-cheat.
- `docs/testing-checklist.md` — manual + automated test steps.
- `docs/implementation-progress.md` — what is done, in progress, planned.
- `docs/known-issues.md` — known bugs and limitations (read before filing anything).

## Working here

Everything that matters is enforced in **AGENTS.md** — read it before editing.
Key rules: server-authoritative logic, never trust clients, all balance values in
Config, and never claim something was tested unless it actually ran.