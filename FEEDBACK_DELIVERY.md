# Weekly owner feedback delivery

The weekly batch is due Monday at 09:00 America/Toronto. The existing Codex automation also checks Monday–Friday at 09:00, 13:00, and 17:00 for incomplete batches. Completed checks stay quiet. Additional checks send only missing feedback, never another batch for the same week. The local executor and Gmail connection must be available; this is recovery scheduling, not a delivery guarantee.

Generate a unique run folder with `send-weekly-feedback.ps1 -AllOwners -Week YYYY-MM-DD -DryRun -SenderEmail rdaniglad@gmail.com -PreviewDirectory artifacts/feedback-delivery/YYYY-MM-DD/run-TIMESTAMP`. Use only recipient manifests named `<owner>-YYYY-MM-DD.json`; `*.gmail-delivery.json` files are audit checkpoints, not recipient manifests. Users without assigned projects are not feedback recipients. Validate the project coverage and approved template before sending.

For each manifest:

1. Confirm the connected Gmail profile is `rdaniglad@gmail.com`.
2. Run `scripts/feedback-delivery-history.ps1 -Action Check -ManifestPath <manifest.json>`. It checks sent history by email or owner and stops if history cannot be read after bounded retries.
3. Check Gmail Sent for the recipient and exact subject. If it already exists, reconcile its Gmail message ID with the Register command below; do not send again.
4. Send the validated HTML using the Gmail connector and wait for the confirmed message ID. Never use SendGrid, Resend, or the legacy feedback endpoint.
5. Immediately run `scripts/feedback-delivery-history.ps1 -Action Register -ManifestPath <manifest.json> -GmailMessageId <confirmed-id>`. It reads content from the JSON file, persists an audit checkpoint, records the send in Supabase, and reconciles an uncertain database response before reporting failure.
6. Stop on an ambiguous send or registration outcome. Use Gmail and audit checkpoints to reconcile before continuing. Never blindly retry a Gmail send. After interruption, resume missing owners using both Gmail and Supabase to avoid duplicates.

`Register` only records a confirmed Gmail delivery; it does not send mail. Keep complete email contents out of shell command strings. JSON file input avoids failures caused by straight or smart apostrophes in report content. Never print configuration keys or commit generated email artifacts.

Run `scripts/test-feedback-history.ps1` for offline checks of UTF-8 content, case-insensitive duplicate matching, repeated registration, uncertain POST outcomes, and read-failure retries. These tests use a fake configuration and mocked HTTP operations and do not send email or contact production.
