# Omena Consulting — Portfolio status dashboard

Shared static dashboard backed by **Supabase**, edited in this repo and published to **GitHub Pages**.

| | |
|--|--|
| **Live site** | https://omenada2025.github.io/omenaconsulting/ |
| **Repo** | https://github.com/omenada2025/omenaconsulting |
| **Local folder** | this workspace (`dashboard`) |

## Edit locally

1. Open this folder in Cursor.
2. Start a local preview:

```powershell
.\scripts\preview-local.ps1
```

3. Change files (usually `index.html`, guides, or `supabase-config.js`).
4. Refresh the browser at http://127.0.0.1:8765/

Config for Supabase lives in `supabase-config.js` (already present for project `vwvmfuktrkpzrzlklbkr`).

## Deploy live

Every push to **`main`** deploys automatically via GitHub Actions → GitHub Pages.

```powershell
.\scripts\deploy-live.ps1 -Message "Describe your change"
```

Or manually:

```powershell
git add <files>
git commit -m "Describe your change"
git push origin main
```

Then open https://github.com/omenada2025/omenaconsulting/actions and wait for **Deploy static dashboard to Pages** to succeed. Hard-refresh the live site (Ctrl+F5).

## Important pages

| Page | Path |
|------|------|
| App | `/` · `index.html` |
| Team change guide (password gated) | `/guide-factory-dashboard-changes.html` |
| Approval pack | `/proposal-workflow-roles-uiux-approval.html` |
| Manuals index | `/manuals.html` |

Team-doc password is set in `access-gate.js` (see file header).

## Cloudflare (optional)

GitHub Pages is the primary live host. For Cloudflare as well, see `CLOUDFLARE_PAGES.md`.  
The Cloudflare workflow only runs when you trigger it manually and secrets are configured.

## Database changes

SQL migrations live in `supabase/migrations/`. Apply pending ones with:

```powershell
.\scripts\apply-pending-migrations.ps1
```

(or paste into the Supabase SQL Editor).
