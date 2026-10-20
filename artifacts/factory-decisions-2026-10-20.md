# Factory alignment — decisions (20 Oct 2026)

## Locked

| # | Topic | Decision |
|---|--------|----------|
| 1 | 6-week clock start | Live PM enters **V0 received date** (date the formal V0 / handover pack was received). Clock = that date + 6 weeks; gates at end of weeks 1, 3, 5, 6 from that anchor. |
| 2 | Accept handover | **Support PM only** (not Ops Manager). |
| 3 | Ownership stage | Required on **every** weekly update. |
| 4 | Legacy products | **No auto-migration**. Team updates roles/stage manually when ready. |
| 5 | Guide status | Updated to reflect partial live + pending Sprint A items. |
| 6 | Cloudflare Worker Hello World | **Delete** — unused; Pages is the real app. |

## Suggestion recorded for #1 (V0 date)

- Field name: **V0 received date** (or “Factory start date”).
- Who sets it: Live PM (Builder).
- Optional later: Ops Manager can correct if mistyped.
- Empty date = product is **not** on the 6-week runway (weekly status still works).
- Changing the date after gates started should be rare; show a confirm if Week > 1.

## Concerns recorded for #3 (ownership stage on every update)

- Support: some weekly rows are not factory products — still require a stage (default **Live ops** or **In delivery** based on role).
- UI/UX contributors: stage still required; default **In delivery (pre-handover)** unless product is already live.
- Avoid blocking save with cryptic errors — show a short helper under the field.

## Pending build (not done yet)

- A1 Runway W1–W6  
- A2 Gate evidence by week  
- A3 Handover accept screen (Support PM)  
- A4 Ownership stage in forms  
- A5 Week Close basics on Home  
