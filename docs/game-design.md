# Game Design — STEAL A TIME

## Theme

Futuristic clockwork world. Glowing teal time crystals, brass/gold accents,
huge clock towers, blue energy walkways, gold steal particles, purple prestige
effects. UI is big, high-contrast, readable on phones.

## Player fantasy

"A thief of time": every second you hold is real currency and a ticking lifebar.
Hub = safety + spending town. Zones = heist. The fantasy is risk/reward: push a
little further, grab a big cache, and get back before the clock runs out.

## Core loop detail (the rulebook)

**Start:** 60s active time in TIME SANCTUARY (timer paused).

**Decay:** Active time decreases only outside the hub at a zone-decay rate
(sec real time per sec game time; configurable). Hub decay = 0.

**Steal:** Request a steal → server verifies everything → server transfers
time from the target pool to the player → cooldown starts.

**Return:** safe zones pause decay; bank can store a reserve and generate
offline earnings.

**TIME'S UP:** player is respawned in the hub with starting time restored and a
comeback bonus; permanent progression is untouched; a fair setback applies
(e.g., a portion of unbanked active time is donated).

## Player-facing systems

### Timer
- Always visible, top-center. Color states: green (safe, >30s), yellow (≤30s),
  orange (≤15s), red (≤5s) — plus numeric seconds text.
- Pauses in the hub. Pulse+ring when critical.

### Training Zone (safe intro)
- Practice NPC pillars, no risk. Three tasks: steal once, spend upgrade once,
  use the warp pad once. Completing all grants starting bonus + tutorial clear.

### Upgrades (server-validated)
- Speed I/II/III + Time Dash (hold Shift/button to burst; server-checked speed caps).
- Stealth: temporary invisibility, shadow step.
- Power: +NPC reward %, controlled auto-steal (very slow, server rate-limited).
- Defense: Time Insurance (partial loss protection), Second Chance (revive once
  in zone, cooldown), Bounty Protection.
- Every upgrade: id, name, desc, cost, category, requirements, max level,
  server purchase validation, persistence, UI, and feedback.

### Pets
- Time Puppy (common): +small steal %. Clockwork Owl (rare): +bank earnings.
  Golden Clock (epic): +daily reward. Time Dragon (mythic): +steal & banking.
  Void Phoenix (mythic/event): +comeback bonus. Leveled via XP from stealing.
  Equip rules server-side; passive caps; no unlimited generation.

### Gangs
- Create (name filtered, fee), invite/join/leave/kick, roles (Leader/Officer/Member).
- Shared vault with per-role withdrawal limits. Gang leaderboard + events.
- All mutations server-side; clients only render.

### Trading
- Request → offer side A/B → both ready → both confirm → server atomic swap.
- Cancel on disconnect. Items limited to tradeable categories (cosmetics/titles,
  some pets) with rate limits. No direct time trading P2P in the hub.

### Daily rewards & events
- 7-day streak table; UTC day boundary is server-controlled. Missed days reset
  streak (documented, non-punitive messaging). Events on weekdays/weekend with
  server clock windows + countdown UI + claim validation.

### Prestige (rebirth)
- After milestone total time lived (100h, 250h, 500h, 1000h, 2500h), reset
  documented progression, gain permanent capped % bonuses + prestige title +
  purple effects. Explicit double-confirmation, atomic save, leaderboard update.

### Leaderboards
All-time stolen, weekly stolen, current safe (bank) time, login streak, gangs,
fastest heists, bounties. Server values only; cache output, write rarely.

## UX principles

- Every action has: press → feedback (sound+particles+text) → result state.
- Buttons ≥ 60px on mobile; safe-area aware; no drag required.
- One primary action per context (Steal / Dash / Interact share a radial layout slot).
- Failure states explain "why" (in cooldown, too far, target protected, in hub).
- Never interrupt core play with ads or forced prompts.

## Audio & VFX budget

- 3 music layers (hub, zone, danger), 6 SFX families (steal, buy, death, warning,
  event, UI). Reusable pools; ≤ 120 particles on mid-range; all optional graphics.