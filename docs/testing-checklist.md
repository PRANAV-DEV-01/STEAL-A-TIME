# Testing Checklist — STEAL A TIME

Status legend: ⬜ not started · 🟨 in progress · ✅ passed · ⛔ blocked / can't verify here.

> Never flip a system to ✅ unless you actually ran it in Studio and saw the
> expected result (output log line, visible behavior, or remote round-trip).

## A. Build verification (must always pass)

- ✅ `rojo build default.project.json --output game.rbxl` exits 0.
- ✅ `game.rbxl` re-opens and `rbxmk` inventory shows all fixtures.
- ⬜ `rojo serve` connects from Studio plugin (live sync smoke test).

## B. Boot

- 🟨 Server output logs `[TimeSanctuary] bootstrap` with each service's start line.
- 🟨 No duplicate service start; no circular require error.
- ⬜ No error spam in Server Output over 5 min idle.

## C. Core loop (hub → steal → return → upgrade)

- 🟨 Player spawns in hub; timer displays 60s; **does not tick in hub**.
- 🟨 Warp pad to NPC Village; timer begins decaying at 0.05/s.
- 🟨 Steal button requests → server processes → +X s, cooldown, particles, text.
- 🟨 Timer colors: green/yellow/orange/red at thresholds.
- 🟨 Back in hub decay pauses; sync timer accurate (±0.3s).
- 🟨 First upgrade purchase deducts server time, grants Speed I, HUD updates.

## D. Time death pipeline

- 🟨 Avoid hub long enough → TIME'S UP overlay plays once (no duplicates).
- 🟨 Player respawns in hub, time restored to 60 (+comeback if within window).
- 🟨 Banked time setback −10% applied; upgrades preserved.
- 🟨 Respawn protection 30s honored; second wind bonus present.

## E. Security

- 🔲 Modify client args: steal with fake targetKey / bogus amount → refused, logged.
- 🔲 Spam steal remote > rate limit → suspect cooldown engaged.
- 🔲 Attempt purchase with client-sent price override → refused.
- 🔲 Attempt teleport during death processing → refused.
- 🔲 Attempt bank withdraw beyond cap → refused.
- 🔲 Rapid teleport spam → rate limited.
- 🔲 Double-claim daily offline → only one payout.
- ⛔ Real multi-client tests require publishing/Test servers (document when done).

## F. Persistence

- 🟨 Load default profile for new player (fresh data).
- 🟨 Purchase → save → rejoin → state persists.
- 🟨 BindToClose flush writes final data (Studio close).
- 🟨 Bad/chunked DataStore response → retry + user-friendly message.
- ⬜ DataStore only truly testable with enabled API → note restrictions.

## G. Performance (mid-range mobile at 60fps target)

- 🔲 Memory: `MemoryUsed` stable over 10 min.
- 🔲 No per-frame remote spam; UI updates throttled.
- 🔲 Steal VFX pool bounded (≤64 particles).

## Reproduction steps (new builds)

1. `rojo build`. 2. Open `game.rbxl` in Studio. 3. Press Play.

When you run a row, append `@ who/what/when` (e.g., `✅ @ dev, Studio F5, 2026-10-01`).