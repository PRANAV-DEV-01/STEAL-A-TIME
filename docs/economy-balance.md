# Economy Balance — STEAL A TIME

All values below are the **intent**. The running source of truth is
`src/ReplicatedStorage/TimeSanctuary/Config/` — if code and this doc disagree,
the code wins and this doc must be updated.

## Currencies

| Currency | What it is | Sources | Sinks | Cap |
|---|---|---|---|---|
| Active time | spendable + lifebar (drains outside hub) | steals, practice, daily, offline, events, caches | upgrades, pets, cosmetics, bank deposits | 0 ≤ t ≤ 600s |
| Banked time | safe reserve | deposits (from active) | withdrawals, setbacks, bank cap | default 300s, upgradable |
| Entitlements | cosmetics/titles/battle pass | daily, events, prestige | — | per-item bool |
| XP (pets) | pet leveling | steals | non-monetary | per-pet |

## Starting state and death

- `startingTime = 60s` (restored on TIME'S UP).
- Decay (active/s): hub `0`, NPC Village `0.05`, Player City `0.15`, Vaults `0.10`,
  Secret `0.15`.
- TIME'S UP setback: **banked time −10%** (floor 0), unbanked active time forfeit
  (it was drained to 0 anyway). Permanent progression untouched.
- Comeback bonus: after death, `+15s` starting grant for the next 5 minutes
  (`comebackFlatBonus = 15`, `comebackWindow = 300s`).
- Respawn protection: `30s` (`protectionDuration`).
- Second Chance (defense upgrade): once per 120s, revive in place, keep 3s of time.

## Stealing

Base reward per zone (per steal, subject to caps):

| Zone | baseReward | cooldown | target pool (NPC pillar) | min player time to participate |
|---|---|---|---|---|
| NPC Village | 8s | 12s per pillar | 40s, respawn 30s | 10s |
| Player City (NPC-fountain) | 12s | 20s | 50s | 10s |
| Player City (PvP) | up to 20% of victim's active (capped 15s) | 25s per victim pair | victim active | 10s |
| Time Vaults (elite) | 25s | 30s | 120s + traps | 15s |
| Secret caches | 30s | respawn 5m | 60s | — |

Multipliers (server-side, CAPPED):
- Power (NPC reward): +5%/level, max lvl 10 → +50%.
- Pet bonus: +2–20% by rarity (common→mythic), cap +20% total pets.
- Event bonus: stack limited to `extra` ≤ 25%.
- Combined upper bound: `maxStealReward = base × min(2.5, product of multipliers)`.
- Anti-average: max session steal/hour = 600s (soft), hard 900s.

## Purchases (active-time costs)

Upgrades:

| Upgrade | Cost (cumulative) | Effect / level |
|---|---|---|
| Speed I/II/III | 120 / 300 / 700 | +8% walk speed per level (cap total +20% char walkspeed 16→19.2 via server clamp) |
| Time Dash | 400 (single) | 1.5× speed 4s, cooldown 15s — server time-scaled, clamping max walkspeed 24 |
| Stealth I/II | 250 / 600 | invis 3s/6s, cooldown 25s |
| Shadow Step | 900 | blink 20 studs, cooldown 20s |
| Power I–X | 150 + 150·(lvl−1) | +5% NPC reward per level (see caps) |
| Auto-Steal | 1200 | server-driven grab every 45s (rate-limited, capped) |
| Time Insurance | 450 | reduces death setback 10%→5% |
| Second Chance | 1000 | revive once/120s |
| Bounty Protection | 750 | 30% less PvP steal vs you |

Pets:

| Pet (rarity) | Cost | Passive (cap applied) |
|---|---|---|
| Time Puppy (common) | 200 | +2% steal |
| Clockwork Owl (rare) | 550 | +5% bank earnings (offline) |
| Golden Clock (epic) | 1200 | +10% daily claim |
| Time Dragon (mythic) | 2400 | +8% steal, +5% offline (cap total listed) |
| Void Phoenix (event) | event-only | +15% comeback bonus |

Bank:

- Bank cap upgrade: 300 → 600 → 1000 → 1500 (costs 500 / 900 / 1500).
- Offline earnings: 5% of banked/hour, max 12h accrued, claim button, cap payout 500s.

Cosmetics: 150–900 active-time, cosmetic only.

## Daily rewards (streak resets on missed UTC day, no disguise)

| Day | Reward |
|---|---|
| 1 | +30s bank payout |
| 2 | temporary ability (Second Chance 1 use) |
| 3 | +60s |
| 4 | temporary pet (Time Puppy) |
| 5 | +120s |
| 6 | permanent title "Streak Master" |
| 7 | exclusive title + cosmetic "Chrono" set |

## Events

- Weekend Time Rush: +25% steal reward, Sat 00:00 UTC → Mon 00:00 UTC.
- Wednesday Vault Heist: vault chests +50%, 23:00→24:00 UTC window.
- Friday Gang War: gang points × 2 day.
- Monthly Time War: seasonal leaderboard + badges.

## Prestige (rebirth)

Requirements by total time lived: 100h / 250h / 500h / 1000h / 2500h.
Reset: upgrades, pets (kept? NO — documented as reset), bank, active/banked time
(starting grant scales). Keep: titles, cosmetics, prestige count, achievements.
Bonus per tier (capped): +5% steal, stacked cap +25% total across all tiers.
Prestige celebrations + purple VFX + Hall of Legends entry.

## Fairness guardrails

- No paid power. Cosmetics only for Robux.
- Everything recoverable by play. No time-gated content behind purchases.
- All purchases double-checked server-side; client price never trusted.