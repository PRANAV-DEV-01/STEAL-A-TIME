# Known Issues — STEAL A TIME

Tracked issues (append-only; newest last). Each entry: status, summary, impact,
workaround if any, opened date.

Status map: ✅ fixed · 🟨 open/implemented-needs-verification · ⬜ planned.

## Open

- `KI-001` — 🟨 World is procedural, not baked. The hub/zone geometry is generated
  by server scripts (`world/WorldBuilder.luau`) so it is only visible inside
  Studio Play / a running server, not in the `.rbxl` editor view. Impact: level
  design can't be inspected without pressing Play. Workaround: press Play.
  Planned fix: bake the world to `.rbxm` via a build-time step. Opened: 2026-10-01.

- `KI-002` — 🟨 DataStore round-trips cannot be fully verified in plain Studio
  (API enabled only with the right place/team settings). Persistence logic is
  written but its end-to-end proof needs a DataStore-enabled test or published
  test server. Affects: `ProfileService`, `GangService`, `LeaderboardService`.
  See `testing-checklist.md` sections F/H. Opened: 2026-10-01.

- `KI-003` — 🟨 Multi-player PvP/steal/trade behavior cannot be verified from a
  single Studio client without a second test client / private server. Impact:
  PvP steal, victim warning, trade, gang invites. Workaround: Studio F5 + a
  second Studio instance, or publish to a private/test server. Opened: 2026-10-01.

- `KI-004` — notice: original place contained **two models named `Rig`**; the
  duplicate was renamed `Rig_Legacy1` during import so Rojo could write it.
  Neither model was modified in content. Opened: 2026-10-01.

- `KI-005` — 🟨 **No Studio Play run has happened yet.** The full expansion
  (22 services, 9 UI modules, 5 config modules) compiles and builds, but nothing
  in `docs/testing-checklist.md` has been exercised in a running place by the
  agent — Studio is unavailable in the build environment. Impact: runtime bugs
  (nil indexing, ordering, UI layout) may remain. Workaround: run sections B–I
  of the checklist in Studio and log results. Opened: 2026-11-10.

- `KI-006` — 🟨 DataStore budget/fallback: `LeaderboardService` writes on every
  submit and reads every 60s per board; `GangService` writes the whole registry
  with a 15s debounce. Under heavy concurrency this can approach the DataStore
  request budget. Impact: writes may silently fail (wrapped in `pcall`), so
  leaderboards fall back to in-memory and gang changes are lost on shutdown.
  Planned fix: batch leaderboard writes and add an explicit retry/backoff queue.
  Opened: 2026-11-10.

## Recently fixed

- ✅ `2026-11-10` — **Remote folder name collision.** The `Remotes` ModuleScript
  created a child folder also named `Remotes`; `FindFirstChild("Remotes")` could
  resolve the module instead of the folder. Folder is now `RemotesFolder`
  (`Config.Game.RemotesFolderName`), and lookups use `WaitForChild` with timeout.
- ✅ `2026-11-10` — **Leaderboard stores shared one key-space.** Both boards wrote
  into a single OrderedDataStore. Now each board uses
  `StoreName .. "_" .. board` (`totalTimeStolen`, `bankedTime`).
- ✅ `2026-11-10` — **NPC time lost on hourly-cap rejection.** `StealService` took
  pool time before the cap check and never returned it. Added
  `NpcTimeSourceService.Refund` and call it on rejection.
- ✅ `2026-11-10` — **Timer never initialised on Studio Play.** `TimeService` only
  wired `PlayerAdded`; a player present at server start (Studio F5) got no timer.
  Now it also iterates `Players:GetPlayers()` at startup.
- ✅ `2026-11-10` — **Trade initiator couldn't act.** Both sides saw `"requested"`;
  the initiator now sees `"outgoing"` (waiting/cancel) and only the invitee can
  accept. Trade feedback uses `%+d` so negative differences render correctly.
- ✅ `2026-11-10` — **Gangs could not recruit.** Added `invite` / `accept` /
  `decline` actions, ephemeral invite state, and invite UI in `Panels.renderGang`.
- ✅ `2026-11-10` — **Missing `trade` rate limit.** Added to `RateLimiter`
  defaults (20/60s).
- ✅ `2026-11-10` — **Clock tower overlapped spawn.** Centre tower moved to
  `(0, 20, -150)`; NPC pillars/orbs now sit on each zone's floor height.
- ✅ `2026-11-10` — **Leaderboard panel showed stale data.** Panel now applies the
  table returned by `TS_LeaderboardRequest`.

## Never claim these

- "Everything works." Only the checklist rows that actually ran.
- DataStore persistence "verified" without a DataStore-enabled run.
- PvP behaviors verified with a single client.

## New issue format

```
- `KI-NNN` — 🟨/✅ ⛔/⬜ <one-line summary>. Impact: <who/what>.
  Workaround: <if any>. Opened: <date>.
```
