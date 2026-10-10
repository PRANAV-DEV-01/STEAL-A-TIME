# World Layout — STEAL A TIME

Coordinates: +X east, +Z south (Roblox convention). World centered around origin.
All geometry streaming-friendly, low part counts, mobile-safe.

## TIME SANCTUARY — safe hub (500 × 500 studs)

Hub origin at `(0, 0, 0)`. Safe bounds: `-250 ≤ X,Z ≤ 250`; server checks radius-bounds.

Landmarks (built toward in M1):

1. **Central Spawn Plaza** — hub center; ≥10 spawn points; 80-stud Clock Tower
   (time-of-day visual, Hour/Hand beams); Time Keeper NPC (tutorial); player-count
   display; announcement pillar; compass signs.
2. **Shop District** — north ring: Upgrade Shop, Pet Shop, Cosmetic Shop,
   Time Bank, Battle Pass kiosk.
3. **Leaderboard Arena** — east: 7 data pillars (all-time/weekly/safe time/
   streak/gangs/fastest heists/bounties).
4. **Gang Headquarters** — south-east: creation terminal, recruitment board,
   vault door, member list, leaderboard.
5. **Event Plaza** — west: stage, event calendar, countdown hologram, reward booth.
6. **Training Zone** — south-west: 3 practice pillars, obstacle course ramp,
   first-upgrade vendor dummy, zero risk.
7. **Teleportation Hub** — south: pads for NPC Village, Player City, Time Vaults,
   Secret Areas, Event Zone, each with danger + recommended-progression + confirm UI.
8. **Social District** — north-west: seating, emote circles, photo booth, trade post.
9. **Prestige Hall** — north-east: rebirth terminal, Hall of Legends, statue plinths.
10. **Settings & Support** — menu, not a physical district.

Hub rules (server-enforced via ZoneService):
- Decay rate = 0. Combat/steal disabled. Invulnerable. Weapons disabled.
- Pad → confirmed teleport. Return pads spawn at Plaza.

## ZONE 1: NPC VILLAGE (400 × 400)

Center ~`(-800, 0, -800)`. Danger 1, low decay.
- 8 NPC time pillars (NPC_TimeKeeper01..08) with small pools + personal cooldowns.
- 5 hidden caches (small, respawn 5m). Beginner missions tied to upgrades.
- Safe return: two warp pads at village edges + sign trails.
- No ambushes: NPCs never damage; they only announce "you got caught" (cooldown applied).

## ZONE 2: PLAYER CITY (600 × 600)

Center ~`(900, 0, -900)`. Danger 2, high decay.
- Rooftops, streets, tunnels, shortcuts (MeshParts kept coarse).
- PvP stealing active: steal target = players in-zone, gated by distance + cooldown.
- Bounty board plan (post-M2). Anti-abuse: hard steal cap/hour, victim protection
  12s after a successful steal vs them.

## ZONE 3: TIME VAULTS (dungeon, ~300 × 300 x 3 levels)

Entrance at `(-950, 0, 1050)`, interior offset deep.
- Elite NPCs (big pools, higher cooldowns), traps (server-triggered knockback,
  small time loss), puzzles (co-op levers), locked vault doors, boss vault (M4).

## ZONE 4: SECRET AREAS

Hidden, floating/sky/cave themed, rotating. Discoverable via hints on Event Plaza.
Never required for core progression. Rare caches only.

## Teleport pads

Each pad: name, danger level, recommended progression (e.g., "recommended: Speed I"),
current occupancy (beacon count), confirmation prompt. Server validates unlock.

## Geometry budget (M1)

- Hub: ~90 parts + 1 large baseplate + tower (~18 parts). Village: ~70 parts.
- Zero particles by default; steal VFX pooled and capped at 64 concurrent.

## Spawn points

`SpawnPoints` list in ZoneConfig; server picks deterministic rotation + small jitter;
initial spawn uses Studio SpawnLocation fallback when character exists first time.