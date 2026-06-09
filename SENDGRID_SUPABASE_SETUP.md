# SendGrid + Supabase Email Setup

This project sends new user credentials through a Supabase Edge Function named `send-credentials`.

## Requirements

- A SendGrid API key with Mail Send permission.
- A verified sender or authenticated domain in SendGrid.
- Supabase CLI access to project `qjxdfqtzcrsopprcmicr`.

## Configure Supabase Secrets

Run these commands from the `dashboard` folder:

```powershell
supabase login
supabase link --project-ref qjxdfqtzcrsopprcmicr
supabase secrets set SENDGRID_API_KEY="SG.your-sendgrid-api-key"
supabase secrets set SENDGRID_FROM_EMAIL="verified-sender@yourdomain.com"
supabase secrets set SENDGRID_FROM_NAME="Product & UI/UX Pulse"
supabase secrets set SENDGRID_ALLOWED_ORIGIN="https://omenada2025.github.io"
```

For local testing, create `supabase/.env` using `supabase/.env.example` as a template. Do not commit real secrets.

## Deploy Function

```powershell
supabase functions deploy send-credentials --project-ref qjxdfqtzcrsopprcmicr
```

## App Behavior

When a Role Manager or Master Admin creates or activates a user, the app calls:

```text
https://qjxdfqtzcrsopprcmicr.supabase.co/functions/v1/send-credentials
```

If the function is not configured yet or SendGrid rejects the request, the app falls back to opening the email draft.
