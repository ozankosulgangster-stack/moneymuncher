# Money Muncher WebGL Publishing Plan

## Publishing Target

The first public version of Money Muncher should be a Unity WebGL build hosted on itch.io.

This gives the game a low-friction launch path:

- Players can open it in a browser.
- No install is required.
- It is easy to share for feedback.
- Updates are simple while the game is still evolving.

## First Public Demo Scope

The first WebGL demo should be small, polished, and replayable.

Required features:

- One playable arena.
- Cursed wallet player.
- 90-second arcade round.
- Good money pickups.
- Debt pickups.
- Tax hazard.
- Money magnet power-up.
- Score, debt, combo, net worth, and timer HUD.
- End-of-round results screen.
- Restart button.

Nice-to-have features:

- Animated pickup pull into the wallet.
- Chomp animation.
- Coin and cash sound effects.
- Combo popup effects.
- Best local score saved in browser storage.

Do not add real-time multiplayer for the first public demo. The first demo should prove that the core arcade loop is fun.

## WebGL Build Settings

Recommended Unity settings for the demo:

- Platform: WebGL.
- Compression Format: Brotli or Gzip.
- Decompression Fallback: enabled if hosting does not serve compressed files correctly.
- Canvas size: responsive, 16:9 preferred.
- Input: keyboard first, then touch controls later.
- Quality: medium or custom lightweight profile.
- Audio: compressed and short.

Performance priorities:

- Keep the scene small.
- Use simple materials.
- Limit particle counts.
- Avoid huge textures.
- Avoid expensive real-time lights.
- Pool pickups later if spawning/despawning becomes heavy.

## itch.io Setup

Suggested itch.io page format:

- Title: Money Muncher
- Kind of project: HTML
- Embed: browser playable
- Viewport: 960 x 540 or 1280 x 720
- Fullscreen button: enabled

Short description:

> A greedy arcade game about a cursed wallet that eats cash, dodges debt, and tries to leave the round with the biggest net worth.

Tags:

- Arcade
- Unity
- WebGL
- Score Attack
- Funny
- Casual

## Online Feature Roadmap

### Phase 1: Local Web Demo

Store only local browser data:

- Best net worth.
- Best combo.
- Total runs played.

Unity APIs:

- `PlayerPrefs` for local high scores.

### Phase 2: Online Competitive

Add online services:

- Global leaderboard.
- Daily challenge seed.
- Weekly challenge score.

Recommended services:

- Unity Gaming Services Leaderboards.
- Unity Cloud Save for player progress.
- Unity Remote Config for daily rules.

### Phase 3: Multiplayer

Add real-time multiplayer only after the single-player game feels strong.

Possible mode:

- Cash Clash: four players race in one arena to earn the highest net worth before the timer ends.

Networking options:

- Unity Netcode for GameObjects.
- Photon Fusion.

## Development Milestones

### Milestone 1: Playable Browser Slice

- Build the arena.
- Add player controller.
- Add pickups.
- Add score HUD.
- Add timer.
- Add restart flow.
- Export a WebGL build.

### Milestone 2: Juice Pass

- Add chomp animation.
- Add pickup trails.
- Add particles.
- Add sound effects.
- Add screen feedback for combo and tax hits.

### Milestone 3: Replayability

- Add local best score.
- Add random seed.
- Add more pickup types.
- Add one extra hazard.
- Add simple upgrade choice after each run.

### Milestone 4: Public itch.io Demo

- Create title screen.
- Create pause menu.
- Create results screen.
- Add itch.io cover image.
- Upload WebGL build.
- Collect playtest feedback.

## Immediate Next Build Tasks

1. Create the Unity project.
2. Import the scripts from `Assets/Scripts`.
3. Make the player prefab.
4. Make pickup prefabs.
5. Make the arena scene.
6. Wire the HUD.
7. Add restart/end screen behavior.
8. Make the first WebGL build.
