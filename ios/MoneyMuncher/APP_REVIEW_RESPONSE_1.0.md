# App Review Response — Version 1.0 (Build 6)

Submission ID: `a16d0f5f-4fa2-4c51-8555-9d07dc4b1167`

Thank you for reviewing Money Muncher. We addressed each item as follows.

## Guideline 2.1(a) — Sign In on iPad

We corrected the Sign In flow for iPad. Tapping **Sign In** now immediately displays an inline "Signing in" state, prevents duplicate taps, reports missing or incorrect credentials directly inside the account dialog, and displays a clear network-timeout message if the account service does not respond. Pressing Return on the iPad keyboard now invokes Sign In rather than Sign Up. The native WKWebView also implements JavaScript-dialog presentation as a fallback.

Review path:

1. Open **Family Area > Family Sign Up**.
2. At **Parent Check**, enter `13` and tap **Unlock**.
3. The account dialog opens automatically. Enter the review credentials and tap **Sign In**.

- Review account email: `[ADD VERIFIED DEMO EMAIL]`
- Review account password: `[ADD DEMO PASSWORD]`
- Clean-install device test: `[ADD EXACT DEVICE AND OS AFTER TESTING BUILD 6]`

## Guideline 4.7.4 — Complete non-embedded software index

Developer and publisher for every item: **Ozan Kosulgan (Money Muncher)**. All items are first-party educational experiences hosted on `moneymuncher.ca`. They contain no advertising, in-app purchases, brokerage activity, or real-money trading.

1. **Money Muncher Learning Hub**
   - Developer: Ozan Kosulgan (Money Muncher)
   - URL: `https://www.moneymuncher.ca/`
2. **Money Muncher Cup Rush**
   - Developer: Ozan Kosulgan (Money Muncher)
   - URL: `https://www.moneymuncher.ca/kids/play/`
3. **Everyday Quest Generator**
   - Developer: Ozan Kosulgan (Money Muncher)
   - URL: `https://www.moneymuncher.ca/kids/#questGeneratorTitle`
4. **Money Muncher Market Lab**
   - Developer: Ozan Kosulgan (Money Muncher)
   - URL: `https://www.moneymuncher.ca/market-lab/`
5. **Classroom Market**
   - Developer: Ozan Kosulgan (Money Muncher)
   - URL: `https://www.moneymuncher.ca/kids/classroom-market/`
6. **Money Muncher Badge Shop**
   - Developer: Ozan Kosulgan (Money Muncher)
   - URL: `https://www.moneymuncher.ca/kids/rewards/`

The same index with descriptions and metadata is publicly available at:
`https://www.moneymuncher.ca/app-review/`

## Previously addressed items

- Support URL: `https://moneymuncher.ca/support.html`
- Permanent account deletion remains available in-app at **Family Area > Account & Data > Delete account**.
- Account email verification does not prevent permanent deletion.
- Cup Rush includes visible touch controls for iPhone and iPad.
