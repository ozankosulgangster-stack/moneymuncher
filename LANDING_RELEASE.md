# Landing page release — October 2, 2026

The homepage now guides families to the app/web demo, teachers to free printables, and adults to separate newsletter and GTA workshop interest lists. The previous homepage remains available as `/demo.html`; its original scripts, Firebase setup and assets are retained. The existing homepage Google Tag Manager and GA configuration is retained. No contact fields are explicitly sent to analytics by the new signup code.

Teacher Hub at `/teachers/` contains 14 free lessons for Grades 1–3 and 4–6. Each includes a branded PDF plan, worksheet and answer key (42 files). These mirror the app's free TeacherLesson content. Extended Teacher Studio lessons remain in the app's existing Plus subscription.

## Managing signups

In Netlify → moneymuncher → Forms, use:

- `moneymuncher-newsletter`: adult newsletter consent.
- `gta-workshop-interest`: workshop interest, including the existing workshop page.
- `email-preferences`: unsubscribe or deletion requests requiring owner review.

These are private Netlify form submissions, not an automated email platform. No campaign, welcome email, or workshop announcement is sent by this release. Before sending, apply preference requests, exclude QA/test addresses, deduplicate by email, use only the consented list, and include a working unsubscribe method. The preference form explicitly says requests are reviewed manually. Configure owner notifications in Netlify if needed. Signup-specific privacy is at `/signup-privacy.html`; the older app/game privacy page has not been rewritten by this release.

Workshop dates and locations are not confirmed; joining the list is not a booking. Form fields collect adult details only. Grade-band PDFs do not require signup.

## Validation

Checked mobile/desktop widths 375, 390, 768, 1024 and 1440; mobile menu; 7 lessons per grade filter; all 42 downloadable files have valid PDF content; required email/consent; simulated error recovery and success routing. Reviewed rendered PDFs and page screenshots. Local form tests mock Netlify responses; live registration must be verified after deploy.

## Publishing and recovery

Only the landing-page files, new assets, teacher downloads, newsletter pages, signup notice and preserved demo are included. Existing native app code and backend functions are not changed. Netlify builds the repository main branch. Restore the preceding published deploy from Netlify if rollback is needed.
