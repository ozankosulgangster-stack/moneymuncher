# Money Muncher Kids Launch Plan

## Target URL

Publish the first public build at:

`https://moneymuncher.ca/kids`

The Unity WebGL game should live at:

`https://moneymuncher.ca/kids/play`

## Launch Position

Money Muncher Kids is a browser arcade game for learning money basics through play:

- collecting coins
- saving coins
- avoiding debt
- noticing tax penalties
- buying simple gear upgrades
- playing a soccer-themed second level

## Privacy-Safe Launch Rules

The first kids release should not include:

- accounts
- chat
- usernames
- public leaderboard
- ads
- analytics trackers
- email collection
- payment collection
- external links inside the Unity game

Allowed for launch:

- local high score
- local gear progress
- local saved coins

## Build Steps

1. Open `Unity_MoneyMuncher` in Unity.
2. Click `Money Muncher > Build Campaign Levels`.
3. Click `Money Muncher > Build Kids WebGL`.
4. Confirm the Unity build appears in `Website/kids/play`.
5. Open `Website/kids/index.html` locally to check the kids page.
6. Upload the contents of `Website/kids` to the `/kids` directory on `moneymuncher.ca`.

## Server Notes

Unity WebGL builds may output `.wasm`, `.data`, `.br`, or `.gz` files. The server needs correct MIME and compression headers. Example Nginx and Apache snippets are in:

- `Website/kids/deploy/nginx-moneymuncher-kids.conf`
- `Website/kids/deploy/apache-htaccess`

## Pre-Launch Checklist

- WebGL build loads at `/kids/play`.
- Level 1 starts.
- Level 1 shop appears after the timer.
- Level 2 button works.
- Soccer ball goal scoring works.
- Restart button works.
- Privacy page is reachable.
- No analytics or ad scripts are present.
- No account, chat, or text input is present.
