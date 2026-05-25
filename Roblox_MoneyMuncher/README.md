# Money Muncher Roblox Prototype

This folder contains a Roblox-native starter version of **Money Muncher: Learning Trail**.

It is not a Unity export. Roblox games are built inside Roblox Studio with Luau scripts, Roblox parts, UI, and Roblox publishing tools. These files give us the first playable Roblox prototype:

- Super Mario-style learning trail
- Coin pickups
- Money question gates
- Themed areas: Saving Forest, Budget Bridge, Investment Mountain, Tax Tunnel
- Debt puddle hazards
- Correct answers open gates and award coins
- Wrong answers add a small debt penalty and teach the concept
- Simple player progress saving
- Personal online Money Park plots
- Preset build items bought with earned coins

## Quick Studio Setup

1. Open Roblox Studio.
2. Create a new **Baseplate** experience.
3. In **Explorer**, create the scripts listed below.
4. Copy each `.lua` file into the matching Roblox script.
5. Press **Play**.

## Script Placement

| File | Roblox location | Script type |
| --- | --- | --- |
| `src/ReplicatedStorage/MoneyQuestions.lua` | `ReplicatedStorage/MoneyQuestions` | ModuleScript |
| `src/ReplicatedStorage/BuildCatalog.lua` | `ReplicatedStorage/BuildCatalog` | ModuleScript |
| `src/ServerScriptService/MapBuilder.server.lua` | `ServerScriptService/MapBuilder` | Script |
| `src/ServerScriptService/PlayerProgress.server.lua` | `ServerScriptService/PlayerProgress` | Script |
| `src/ServerScriptService/PlayerPlots.server.lua` | `ServerScriptService/PlayerPlots` | Script |
| `src/ServerScriptService/CoinPickup.server.lua` | `ServerScriptService/CoinPickup` | Script |
| `src/ServerScriptService/DebtHazard.server.lua` | `ServerScriptService/DebtHazard` | Script |
| `src/ServerScriptService/QuestionGate.server.lua` | `ServerScriptService/QuestionGate` | Script |
| `src/ServerScriptService/FinishTrail.server.lua` | `ServerScriptService/FinishTrail` | Script |
| `src/StarterPlayerScripts/LearningTrailClient.client.lua` | `StarterPlayer > StarterPlayerScripts > LearningTrailClient` | LocalScript |
| `src/StarterPlayerScripts/BuildParkClient.client.lua` | `StarterPlayer > StarterPlayerScripts > BuildParkClient` | LocalScript |

## Publishing To Roblox

1. In Roblox Studio, choose **File > Publish to Roblox**.
2. Create a new experience named `Money Muncher: Learning Trail`.
3. Open the **Creator Dashboard**.
4. Add icon, thumbnails, description, and age/maturity settings.
5. Keep it private while testing.
6. When ready, set the experience to public.

Suggested description:

> Run through a colorful money-learning map, collect coins, answer saving and investing questions, and unlock the next path.

## Next Build Ideas

- Add themed worlds: Saving Forest, Budget Bridge, Investment Mountain, Tax Tunnel.
- Add checkpoints after each question gate.
- Add more Money Park build pieces and plot upgrades.
- Add avatar shop items bought with earned coins.
- Add badges for completing each learning world.
- Add parent/teacher question packs later.
