# Known Issues — STEAL A TIME

Tracked issues (append-only; newest last). Each entry: status, summary, impact,
workaround if any, opened date.

## Open

- `KI-001` — 🟨 World is procedural, not baked. The hub/zone geometry is generated
  by server scripts (WorldBuilder) so it is only visible inside Studio Play / a
  running server, not in the .rbxl editor view. Workaround: press Play to see it.
  Planned fix: bake world to `.rbxm` via a build-time step.

- `KI-002` — 🟨 DataStore round-trips cannot be fully verified in plain Studio
  (API enabled only with the right place/team settings). Persistence logic is
  written but its end-to-end proof needs a DataStore-enabled test or published
  test server. See `testing-checklist.md` F/C.

- `KI-003` — 🟨 Multi-player PvP/steal behavior cannot be verified from a single
  Studio client without a second test client / private server. Planned: document
  a two-client test procedure (Studio F5 + second Studio instance, or Roblox app).

- `KI-004` — notice: original place contained **two models named `Rig`**; the
  duplicate was renamed `Rig_Legacy1` during import so Rojo could write it.
  Neither model was modified in content.

## Recently fixed

(none yet)

## Never claim these

- "Everything works." Only the checklist rows that actually ran.
- DataStore persistence "verified" without a DataStore-enabled run.
- PvP behaviors verified with a single client.

## New issue format

```
- `KI-NNN` — 🟨/✅ ⛔/⬜ <one-line summary>. Impact: <who/what>. 
  Workaround: <if any>. Opened: <date>.
```