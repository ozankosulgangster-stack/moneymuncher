# Publishing MoneyMuncher

This workspace is ready to publish, but this machine currently has no GitHub/Netlify auth configured.

## GitHub API publish

Set these environment variables, then run:

```bash
GITHUB_TOKEN=... GITHUB_OWNER=your-github-username GITHUB_REPO=moneymuncher npm run publish:github
```

On PowerShell:

```powershell
$env:GITHUB_TOKEN="..."
$env:GITHUB_OWNER="your-github-username"
$env:GITHUB_REPO="moneymuncher"
npm run publish:github
```

## Netlify

This project includes:

- `netlify.toml`
- `netlify/functions/api.js`
- `@netlify/blobs` storage for deployed user progress

Once the GitHub repo is created, connect it in Netlify:

1. Netlify → Add new site → Import existing project
2. Choose GitHub → `moneymuncher`
3. Build command: leave empty or `npm run check`
4. Publish directory: `.`
5. Functions directory: `netlify/functions`

Or install/use Netlify CLI after login:

```bash
npx netlify deploy --prod --dir .
```
