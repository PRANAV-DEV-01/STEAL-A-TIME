# Product Requirements — STEAL A TIME

## 1. Product vision

A multiplayer Roblox simulator where **time is the currency and the danger**.
Players start poor in seconds, leave the sanctuary to steal time from NPCs and
rivals, and race back to spend it. Time is simultaneously the reward, the stat,
and the lifebar — one system drives earning, spending, risk, and failure.

## 2. Target players

- Primary: Roblox simulation/grinder audience, ages 9–16, mobile-heavy.
- Desktop secondary, gamepad optional.
- Session habits: 5–20 minutes per login, multiple logins per day, week-streak retention.

## 3. Core gameplay loop

```
SPAWN → ENTER A ZONE → STEAL TIME → AVOID/ESCAPE DANGER → RETURN TO HUB
     → BUY UPGRADES → SOCIALIZE → REPEAT
```

- Time decays **only outside** TIME SANCTUARY.
- Rotating through zones, stealing, and banking keeps each session short and loopable.
- Offline earnings, daily rewards, gangs, and prestige drive long-term retention.

## 4. First five minutes (tutorial)

1. Spawn in Central Spawn Plaza. Timer shows 60s. It **does not** tick in the hub.
2. Tutorial hologram + Time Keeper NPC: "Time is money AND fuel. Leave the hub and it drains."
3. Step into the Training Zone (safe area) → practice a steal on a practice NPC → +time reward.
4. Follow the glowing path to the NPC Village pad → confirm teleport → timer starts draining.
5. Steal from an NPC (server-validated) → golden particles + floating "+Xs".
6. Return to hub via warp pad → timer pauses again.
7. Open Upgrade Shop → buy first upgrade (Speed I).
8. Explain TIME'S UP: die once → respawn in hub with restored time + comeback bonus, upgrades kept.

Full walkthrough in `docs/testing-checklist.md`.

## 5. Safe-hub experience

TIME SANCTUARY (~500×500 studs).

- No combat, no stealing, no decay, no hostile NPCs, invulnerable players.
- Server decides hub status; clients only display.
- Sections: Spawn Plaza, Shop District, Leaderboard Arena, Gang HQ, Event Plaza,
  Training Zone, Teleportation Hub, Social District, Prestige Hall, Settings & Support.

## 6. Combat-zone experience

Four zone families (see `world-layout.md`):

| Zone | Scale | Danger | Time decay | Risk | Reward |
|---|---|---|---|---|---|
| NPC Village | 400×400 | Low | Low | NPCs only | Small, constant |
| Player City | 600×600 | Medium | High | PvP stealing | Large, contested |
| Time Vaults | dungeon | High | Medium | Traps/puzzles/elites | Vault + boss |
| Secret Areas | hidden | varies | configurable | discovery | Rare caches |

Zones can be entered by teleport pad (with confirmation + danger warning) or
physical boundaries. Return routes are always available and signposted.

## 7. Progression system

- **Active time** — spendable currency AND lifebar.
- **Banked time** — stored safe reserve with a cap.
- **Upgrades** — Speed/Stealth/Power/Defense trees, max levels, server-validated purchases.
- **Pets** — passive % bonuses (capped), leveled with XP.
- **Prestige** — reset documented values after milestone hours for permanent capped bonuses.
- **Titles & cosmetics** — daily/weekly/event rewards, no pay-to-win power.

See `economy-balance.md` for all numbers.

## 8. Social system

Gangs (create/join/leave/kick, roles, shared vault, leaderboard, events), trading
(consensual, two-sided, server-atomic), social district (emotes, photo booth,
seating), friend cross-referencing where supported.

## 9. Economy

Three "buckets": active time, banked time, and cosmetics/entitlements.
Sources: steals, practice, daily rewards, offline earnings, events, caches.
Sinks: upgrades, pets, cosmetics, bank cap upgrades, prestige fees.
No real-money advantage in *power*; cosmetic-only premium.

## 10. Retention systems

- Daily streak rewards (7-day table, no pressure tactics).
- Offline earnings on returning.
- Weekly leaderboard.
- Events across the week (Weekend Time Rush, Wednesday Vault Heist, Friday Gang War, Monthly Time War).
- Gangs give social stickiness.

## 11. Monetization

Fair free-to-play:
- Cosmetics, titles, and QoL (bank cap) only — never required for progression.
- No forced ads. Death setbacks are always recoverable by playing.
- Nothing time-gated behind purchases for core content.

## 12. Mobile controls

- Left virtual joystick + right context buttons (Steal, Dash, Interact).
- Large touch targets (≥60px), safe-area padding, no UI in cutouts.
- Desktop: keyboard/mouse. Gamepad if practical. Scalable UI, low-graphics option.

## 13. Accessibility

- Four timer color states + numeric text (not color-only).
- High-contrast UI theme; adjustable UI scale; audio volume sliders.
- Attack/target feedback via text + sound + particles together.

## 14. Performance targets

- 60 FPS mid-range mobile where practical; smooth inputs.
- StreamingEnabled world; reusable effects; capped particles; event-driven updates;
  no per-frame work where events suffice; low-cost UI updates (0.5s throttle).

## 15. Security model

- **Server-authoritative everything.** No client-trusted values, positions, or raws.
- Validation helpers + per-remote rate limiting + abuse logging.
- No permanent bans on single signals; temporary restrictions + reviewable logs.
- Text filtering for all user content (game-provided filter function).

## 16. Testing strategy

- Build verification (`rojo build`) automatic.
- Manual Studio checklist (`testing-checklist.md`) run per milestone.
- Where available, server-side self-tests in `tests/` (runs in Studio).
- Published multi-client test before claiming anything about replication.

## 17. Launch plan

1. Core loop + hub + NPC Village playable and balanced. (M1)
2. Player City PvP + gangs + leaderboards + persistence hardened. (M2)
3. Vaults, trading, daily rewards, events, prestige. (M3)
4. Live-ops dashboard-light + moderation + analytics hooks. (M4)
5. Soft launch private servers → limited public → feature launch.

## 18. Post-launch update plan

- Weekly balance pass + event calendar.
- Rare secret-area rotation.
- Seasonal leaderboards + battle pass cosmetics.
- Community suggestions triage in-game + Discord (needs moderation pipeline).

## Explicit product constraints (enforced)

- Never forced advertising. Never pay-only recovery. No predatory design targeting children.
- No unbounded multiplier stacking. No unbounded loop anti-cheat bans.
- Client-provided currency/price/reward/target/damage values are NEVER trusted.