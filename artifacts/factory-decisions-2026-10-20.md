# Factory alignment — decisions (20 Oct 2026)

## Locked

| # | Topic | Decision |
|---|--------|----------|
| 1 | 6-week clock start | Live PM enters **V0 received date** (date the formal V0 / handover pack was received). Clock = that date + 6 weeks; gates at end of weeks 1, 3, 5, 6 from that anchor. |
| 2 | Accept handover | **Support PM only** (not Ops Manager). |
| 3 | Ownership stage | Required on **every** weekly update. |
| 4 | Legacy products | **No auto-migration**. Team updates roles/stage manually when ready. |
| 5 | Guide status | Updated to reflect Sprint A+B shipped (+C polish). |
| 6 | Cloudflare Worker Hello World | **Delete** — unused; Pages is the real app. |
| 7 | Multiple versions | Track **product + version/cycle**. Support PM owns current live version; Live PM owns next factory cycle in parallel. Accept moves live pointer; kits and history are per version. |

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

## Sprint A build (shipped 20 Oct 2026)

- A1 Runway W1–W6 — report Factory cycle panel  
- A2 Gate evidence by week — listed on gate weeks  
- A3 Handover Accept — Support PM only; kits gate  
- A4 Ownership stage + V0 date + version label on intake/edit forms  
- A5 Week Close + factory gate steps on Home  
- Migration: `20261020180000_factory_cycle_fields.sql` (run in Supabase SQL Editor)  

## Factory leftovers + Sprint B/C (shipped 21 Oct 2026)

- Confirm dialog when changing V0 received date after factory week > 1  
- Ownership stage helper copy on intake + edit forms  
- **P1:** governance readiness bar + optional artifact links; global scope clear chips; meeting session Agenda→Decisions→Actions→Send; Executive top products + decision queue; Incidents Schedule|Blockers; Administration hub; Home RACI labels; unresolved identity count on Report Quality  
- **P2 polish:** mobile bottom nav; permission banners; optional `validation_status` / `test_environment`; glossary purge of Master/Role Manager user-facing copy; legacy System Analyst chip + Live PM analytics map; weekly review email workaround note  
- Migration: `20261021120000_validation_signals.sql` (run in Supabase SQL Editor)  
