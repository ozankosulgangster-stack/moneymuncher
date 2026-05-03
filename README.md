# MoneyMuncher Alpha

A first playable web prototype for moneymuncher.ca.

## What it includes

- Kid-facing landing page
- Interactive financial choices game
- Stats: coins, saved, joy, wisdom
- Login with server-side user records
- Money World Map with level nodes
- Locked/unlocked level progression saved to `data/db.json`
- 5 prototype levels:
  1. Snack Shop — needs vs wants
  2. Toy Market — impulse control
  3. Savings Bank — goals and patience
  4. Sharing Square — giving and community
  5. Family Budget — planning together
- Teacher / parent community hub concept
- Quest idea input prototype

## Run locally

```bash
npm start
```

Then open:

```text
http://127.0.0.1:4173
```

## Notes

Premium is intentionally removed for now. User login and progress are stored on the local Node server in `data/db.json`. This is much closer to real app storage than browser-only `localStorage`, but production should use a real database and parent-safe authentication.
