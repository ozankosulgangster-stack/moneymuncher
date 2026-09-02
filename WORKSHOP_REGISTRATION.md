# GTA Workshop Registration Data

## Where registrations are stored

The live workshop form is a Netlify Form named `gta-workshop-interest`. Verified submissions are stored privately in the Netlify project database, not in Firebase or the public website repository.

Open the Netlify project, then go to:

`Forms` → `gta-workshop-interest` → `Verified submissions`

Check `Spam submissions` if an expected registration is missing. Use `Download as CSV` from the form detail page to create a working contact list.

## Information collected

Each submission contains:

- `parent_name`: parent or caregiver name
- `email`: email used for workshop updates
- `gta_area`: preferred GTA area
- `child_age_group`: age range only; no child name
- `preferred_time`: preferred session time
- `learning_interest`: optional topic request
- `workshop_updates_consent`: required consent value
- `source`: `gta-workshop-landing-page`
- Netlify submission ID and submission time

The hidden `subject` field makes notification messages easy to identify. It does not expose registrations publicly.

## Turn on registration alerts

In Netlify, open:

`Project configuration` → `Notifications` → `Emails and webhooks` → `Form submission notifications`

Add an email notification for `gta-workshop-interest`. Netlify uses the form's `email` field as the reply-to address.

## Contact families when the venue is confirmed

1. Export the form's verified submissions as CSV.
2. Filter to records where `workshop_updates_consent` is `yes`.
3. Remove duplicates by normalized email address.
4. Send the confirmed date, start/end time, venue address, accessibility details, parking/transit guidance, capacity, and cancellation instructions.
5. For a small group, send with recipients in BCC. For a larger list, import only consenting contacts into an email service that supports unsubscribe handling.
6. Keep the exported CSV private and delete copies that are no longer needed.

## Recommended status columns

Netlify remains the original submission record. In the exported working sheet, add:

- `status`: interested, invited, confirmed, waitlisted, attended, cancelled
- `invitation_sent_at`
- `confirmed_at`
- `notes`

Do not add child names or unnecessary personal information.

## Future Firebase structure

If automated registration management is needed later, use a server-authenticated function to copy verified Netlify submissions into:

`workshopEvents/gta-founder-workshop-2026/registrations/{registrationId}`

Keep client reads and writes denied. A trusted server function should validate submissions and write the fields above. Do not allow anonymous browsers to read the collection or write arbitrary email documents.
