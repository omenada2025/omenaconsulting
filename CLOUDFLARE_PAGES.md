# Publish dashboard on Cloudflare Pages

The site already deploys to **GitHub Pages**. Cloudflare Pages can serve the **same repo** as a second public URL.

## Option A — Connect Git (recommended, one-time)

1. Open [Cloudflare Dashboard → Workers & Pages](https://dash.cloudflare.com/?to=/:account/workers-and-pages).
2. **Create application** → **Pages** → **Connect to Git**.
3. Authorize GitHub and select **`omenada2025/omenaconsulting`**.
4. Build settings:
   - **Framework preset:** None
   - **Build command:** *(leave empty)*
   - **Build output directory:** `/` (repository root)
5. Save and deploy.

After the first deploy, team guide URL will look like:

`https://omenaconsulting.pages.dev/guide-factory-dashboard-changes.html`

(or your custom domain if you attach one).

## Option B — GitHub Action (API token)

Fastest from this machine:

```powershell
.\scripts\setup-cloudflare-secrets.ps1
```

Or manually:

1. Cloudflare → **My Profile** → **API Tokens** → create token with **Cloudflare Pages — Edit** (or Workers Edit template).
2. Copy **Account ID** from Workers & Pages overview.
3. In GitHub → **Settings → Secrets → Actions**, add:
   - `CLOUDFLARE_API_TOKEN`
   - `CLOUDFLARE_ACCOUNT_ID`
4. Push to `main` (or **Actions → Deploy to Cloudflare Pages → Run workflow**).

Workflow file: `.github/workflows/cloudflare-pages.yml` (skips cleanly if secrets are missing).

## Key pages to share

| Page | Path |
|------|------|
| Team explanation guide | `/guide-factory-dashboard-changes.html` |
| After-implementation mock | `/preview-after-factory-alignment.html` |
| Approval pack | `/proposal-workflow-roles-uiux-approval.html` |
| Live dashboard | `/` or `/index.html` |

## Protecting team docs (password / SSO)

GitHub Pages on a **public** repo cannot natively password-protect a URL.

### Already in place (light gate)

Sensitive HTML pages load `access-gate.js` (team share password). This stops casual visitors; it is **not** strong security (the page files remain in a public repo).

Default password: `OmenaTeam2026!`  
Change it by updating `EXPECTED_HASH` in `access-gate.js` (SHA-256 hex of the new password).

### Strong protection — Cloudflare Access (recommended)

1. Put the site on **Cloudflare Pages** (Option A above).
2. Cloudflare Dashboard → **Zero Trust** → **Access** → **Applications** → **Add an application**.
3. Type: **Self-hosted**.
4. Application domain: your `*.pages.dev` host (or custom domain).
5. Policy: allow only `@zenatech.com` (or specific emails) via One-time PIN / Google / Microsoft.
6. Optional path policy: protect only `/guide-factory-*`, `/proposal-*`, `/preview-*`.

Then the public cannot open the guide without Cloudflare login — even if they have the URL.
