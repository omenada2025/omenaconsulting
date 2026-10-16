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

1. Cloudflare → **My Profile** → **API Tokens** → create token with **Cloudflare Pages — Edit**.
2. In GitHub repo **Settings → Secrets → Actions**, add:
   - `CLOUDFLARE_API_TOKEN`
   - `CLOUDFLARE_ACCOUNT_ID`
3. Push to `main` (or run **Deploy to Cloudflare Pages** workflow manually).

Workflow file: `.github/workflows/cloudflare-pages.yml`

## Key pages to share

| Page | Path |
|------|------|
| Team explanation guide | `/guide-factory-dashboard-changes.html` |
| After-implementation mock | `/preview-after-factory-alignment.html` |
| Approval pack | `/proposal-workflow-roles-uiux-approval.html` |
| Live dashboard | `/` or `/index.html` |
