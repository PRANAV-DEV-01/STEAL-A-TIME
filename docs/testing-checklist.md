# Testing Checklist — STEAL A TIME

Status legend: ⬜ not started · 🟨 implemented, not yet run · ✅ passed · ⛔ blocked / can't verify here.

> Never flip a system to ✅ unless you actually ran it in Studio and saw the
> expected result (output log line, visible behavior, or remote round-trip).

## A. Build verification (must always pass)

- ✅ `rojo build default.project.json --output game.rbxl` exits 0.
- ✅ `luau-compile --null src` exits 0.
- ✅ `luau-analyze src` reports no errors except unknown Roblox globals.
- ⬜ `rojo serve` connects from Studio plugin (live sync smoke test).

## B. Boot

- 🟨 Server output prints `[TimeSanctuary] bootstrap complete` and one
  `started` line per service (rate limiter is not a service).
- 🟨 No duplicate service start; no circular require error.
- ⬜ No error spam in Server Output over 5 min idle.

## C. Core loop (hub → steal → return → upgrade)

- 🟨 Player spawns in hub at (0, 4, 0); timer displays 60s; **does not tick in hub**.
- 🟨 Player can stand next to the centre clock tower without spawning inside it.
- 🟨 Travel pad (NPC Village) prompts `TRAVEL: NPC VILLAGE`; timer decays 0.05/s.
- 🟨 Steal button targets the nearest NPC pillar in range → `+X s`, cooldown, feedback.
- 🟨 Timer colours: green >30, yellow ≤30, orange ≤15, red ≤5.
- 🟨 Back in hub decay pauses; timer sync accurate (±0.3s).
- 🟨 Purchase Speed I from the shop deducts banked time and raises WalkSpeed.
- 🟨 Bank deposit moves active → banked; withdraw moves banked → active.
- 🟨 Bank cap blocks deposits past the cap and the shop upgrade raises it.

## D. Time death pipeline

- 🟨 Stay outside the hub until time hits 0 → TIME'S UP overlay plays once.
- 🟨 Player respawns in hub with restored time (+comeback when within window).
- 🟨 Banked time setback −10% applied (−5% with Time Insurance); upgrades preserved.
- 🟨 Time Insurance reduces the setback; Second Chance consumes itself and skips it.
- 🟨 Respawn protection 30s prevents decay and PvP steals.

## E. Economy systems

- 🟨 Offline earnings appear as `offlinePending` and claim into banked time only.
- 🟨 Daily reward can only be claimed once per UTC day; streak increments/resets.
- 🟨 Daily day-2 ability / day-4 pet / day-6+ title actually grant.
- 🟨 Pet purchase, equip, unequip; steal multiplier applies.
- 🟨 Bank capacity tier purchase raises cap and charges the configured cost.
- 🟨 Prestige blocked until the tier's lived-hours requirement; on success resets
  upgrades/bank/active and grants a title.
- 🟨 Leaderboards populate (`totalTimeStolen`, `bankedTime`) and refresh ≤60s.

## F. Social systems

- 🟨 Gang create charges 250 banked time; invalid names rejected.
- 🟨 Gang invite → target sees invite, accept joins, decline clears.
- 🟨 Gang deposit moves banked time into the gang bank.
- 🟨 Owner can kick; leaving transfers leadership; disband clears all members.
- 🟨 Gang persists across a DataStore-enabled rejoin.
- 🟨 Trade request auto-opens the partner's panel; initiator sees "waiting".
- 🟨 Both sides offer + confirm → banked time swaps exactly once.
- 🟨 Cancel/timeout/partner-leave closes the session with a reason.
- 🟨 Weekday events apply the correct NPC/PvP multiplier; banner announces.

## G. Progression / character / safety

- 🟨 Tutorial shows steps 1→6, advances on travel/steal/return/bank/purchase,
  grants 20 banked time + "Initiate" title once.
- 🟨 Tutorial skip/restart works and persists.
- 🟨 Dash requires Time_Dash, cooldown enforced server-side.
- 🟨 Stealth requires Stealth_I/II, transparency restores after duration.
- 🟨 Auto-steal only fires in danger zones within range, respects steal cooldown.
- 🟨 Settings toggles persist across rejoin.
- 🔲 Modify client args: steal with fake targetKey / bogus amount → refused, logged.
- 🔲 Spam steal remote > rate limit → suspect counter rises.
- 🔲 Attempt purchase with client-sent price override → refused.
- 🔲 Attempt teleport during death processing → refused.
- 🔲 Attempt bank withdraw beyond cap → refused.
- 🔲 Rapid teleport spam → rate limited (6/min).
- 🔲 Double-claim daily/offline → only one payout.
- 🔲 Speed hack / out-of-bounds → corrected, eventually kicked.
- ⛔ Real multi-client tests require publishing/Test servers (document when done).

## H. Persistence

- 🟨 Load default profile for new player (fresh data).
- 🟨 Purchase → save → rejoin → state persists.
- 🟨 BindToClose flush writes final data (Studio close).
- 🟨 DataStore failure falls back to an in-memory profile without crashing.
- ⬜ DataStore only truly testable with enabled API → note restrictions.

## I. Performance (mid-range mobile at 60fps target)

- 🔲 Memory: `MemoryUsed` stable over 10 min.
- 🔲 No per-frame remote spam; UI updates throttled.
- 🔲 17 pillar pools + player decays stay under CPU budget.

## Reproduction steps (new builds)

1. `rojo build`. 2. Open `game.rbxl` in Studio. 3. Press Play.

When you run a row, append `@ who/what/when` (e.g., `✅ @ dev, Studio F5, 2026-10-01`).
