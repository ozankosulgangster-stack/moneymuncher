# Roblox Studio Setup Guide

## 1. Create The Project

Open Roblox Studio and create a new **Baseplate**.

In **Home > Game Settings**:

- Name: `Money Muncher: Learning Trail`
- Genre: `Adventure`
- Devices: Computer, Tablet, Phone
- Enable Studio API access only while testing DataStore saving locally.

## 2. Add Scripts

Use the Roblox Explorer panel.

Create these objects:

- `ReplicatedStorage > ModuleScript` named `MoneyQuestions`
- `ServerScriptService > Script` named `MapBuilder`
- `ServerScriptService > Script` named `PlayerProgress`
- `ServerScriptService > Script` named `CoinPickup`
- `ServerScriptService > Script` named `QuestionGate`
- `ServerScriptService > Script` named `FinishTrail`
- `StarterPlayer > StarterPlayerScripts > LocalScript` named `LearningTrailClient`

Copy the matching source file contents from `Roblox_MoneyMuncher/src`.

## 3. Test

Press **Play**.

You should see:

- A colorful side-scrolling trail
- Coins along the path
- Three question gates
- A UI question prompt when you reach a gate
- Gates opening when you answer correctly

## 4. Publish

Use **File > Publish to Roblox**.

After the first publish, go to the Creator Dashboard and keep the game private until it has been tested.

## 5. Public Launch Checklist

- No chat mechanics added.
- No purchases until we deliberately design them.
- No personal data collection.
- Questions are age-appropriate.
- Mobile controls tested.
- First level can be completed by a new player.
