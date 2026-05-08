# Money Muncher

## Core Fantasy

Money Muncher is a fast, colorful arcade game about a cursed wallet that eats cash, coins, cards, jewels, and anything else with value. The game should feel greedy, funny, and instantly readable: collect good money, dodge bad finance, chain combos, and escape each round with the biggest net worth.

## First Playable Prototype

Build the first version as a 2.5D top-down Unity arena.

The player controls a chomping wallet. Money pickups spawn around the arena. Good pickups add score and extend the combo. Bad pickups add debt, reduce the combo, or stun the player. A round lasts 90 seconds.

Core prototype features:

- Top-down player movement.
- Collectible money pickups with different values.
- Bad pickups such as debt bombs and fake bills.
- Score, debt, combo multiplier, and net worth.
- Round timer.
- Money magnet power-up.
- Simple hazard zones such as tax lasers.
- End-of-round summary.

## Game Loop

1. Start a timed round.
2. Move around the arena and munch valuable pickups.
3. Keep a combo alive by collecting quickly.
4. Avoid bad money and hazards.
5. Trigger power-ups for short bursts of greed.
6. End the round with a net worth score.
7. Spend winnings on upgrades between rounds.

## Player Feel

The wallet should feel snappy and a little mischievous. Collection feedback is important:

- Pickups spiral into the mouth.
- Coins make light chomp sounds.
- Cash bundles make deeper, richer chomps.
- Combo increases pitch, particle density, or screen sparkle.
- The wallet grows slightly as score increases.
- Getting hit should feel comedic, not punishingly harsh.

## Scoring

Track four main values:

- `grossScore`: all positive value collected.
- `debt`: penalties collected or caused by hazards.
- `comboMultiplier`: grows when the player collects quickly.
- `netWorth`: final score, calculated as gross score minus debt plus combo bonus.

Suggested formula:

```text
pickupValueEarned = pickup.baseValue * currentComboMultiplier
netWorth = grossScore - debt
```

## Pickups

Good pickups:

- Copper Coin: low value, common.
- Silver Coin: medium value.
- Gold Coin: higher value.
- Cash Bundle: valuable, slightly rarer.
- Gift Card: bonus points if collected in a streak.
- Gold Bar: heavy item, only edible after upgrade.

Bad pickups:

- Fake Bill: looks good, breaks combo.
- Debt Bomb: adds debt and pushes nearby money away.
- Credit Card: immediate score boost, delayed interest penalty.
- Tax Form: takes a percentage of current gross score.

## Hazards

- Tax Laser: passing through removes a percent of score.
- Shredder Zone: destroys nearby pickups.
- Inflation Cloud: lowers pickup values inside it.
- Security Drone: chases the player after big combos.
- Market Crash Wave: temporarily turns some pickups negative.

## Power-Ups

- Money Magnet: pulls nearby good pickups toward the player.
- Golden Bite: doubles pickup value for a short time.
- Receipt Shield: blocks one penalty.
- Tax Loophole: ignores tax hazards briefly.
- Jackpot Rain: spawns a short burst of coins.

## Online Roadmap

Phase 1 online features:

- Online leaderboards for net worth, biggest combo, and fastest vault clear.
- Daily challenge seed so every player gets the same layout.
- Cloud save for cosmetics and upgrades.

Phase 2 online features:

- Ghost runs against friends or top players.
- Friend challenges and weekly events.

Phase 3 online features:

- Real-time multiplayer mode called Cash Clash.
- Four players race in the same arena to earn the highest net worth.
- Debt traps and market events create chaos.

Recommended Unity services:

- Unity Gaming Services Leaderboards.
- Unity Cloud Save.
- Unity Remote Config for daily challenge rules.
- Netcode for GameObjects or Photon Fusion later for real-time multiplayer.

## Milestones

### Milestone 1: Arcade Slice

- Player movement.
- Collectibles.
- Score and combo.
- Timer.
- One arena.
- End summary.

### Campaign Levels

Level 1 is Treasure Island. It teaches basic money collection, tax/debt avoidance, saving coins, and buying gear after the round.

Level 2 is Soccer Stadium. It keeps the money-munching loop but adds soccer play: push the ball into goals for a big score bonus, collect trophies, and avoid red-card penalties.

### Milestone 2: Game Feel

- Pickup magnet animation.
- Chomp animation trigger.
- Particles.
- Sound hooks.
- Camera shake and value popups.

### Milestone 3: Strategy

- Debt pickups.
- Tax hazards.
- Upgrade choices.
- Risk/reward pickup values.

### Milestone 4: Online Competitive

- Daily seed.
- Leaderboard-ready score structure.
- Local score submission stub.
- Later replacement with Unity Gaming Services.

### Milestone 5: Multiplayer

- Prototype Cash Clash.
- Networked player movement.
- Shared pickup spawning.
- Server-authoritative scoring.
