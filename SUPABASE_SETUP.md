# Supabase Setup

This dashboard uses Supabase as the shared database for Omena Consulting status reports.

## 1. Create Or Update The Table

Open your Supabase project, go to **SQL Editor**, and run the contents of `supabase-schema.sql`.

Run it again after this dashboard update so Supabase adds:

- `role` for Product Manager vs UI/UX filtering
- `due_date` for report tracking
- `status_reports_update_all` so submitted reports can be edited

The included policies allow anonymous read, insert, update, and delete for the prototype. For production, replace these with Supabase Auth-based policies.

## 2. Configure Credentials

The deployed app expects `supabase-config.js` next to `index.html`:

```js
window.SUPABASE_CONFIG = {
  url: "https://YOUR_PROJECT_REF.supabase.co",
  anonKey: "YOUR_SUPABASE_ANON_KEY",
  table: "status_reports"
};
```

For this project, the app is already configured for project `vwvmfuktrkpzrzlklbkr`.

## 3. Deploy With GitHub Pages

In GitHub, open the repository settings:

1. Go to **Settings**.
2. Open **Pages**.
3. Set source to **Deploy from a branch**.
4. Choose branch `main` and folder `/root`.
5. Save.

GitHub will provide a public URL after the first Pages build finishes.


