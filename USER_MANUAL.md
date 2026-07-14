# Omena Consulting Dashboard User Manual

## Purpose

The dashboard monitors product, feature, and UI/UX delivery. It helps the team see what is on track, what is delayed, what is blocked, who owns the next action, and what leadership decisions are needed.

## Roles

- **Admin - dashboards only:** can view Portfolio Dashboard, Executive View, My Dashboard, and Incidents & Delays.
- **Master admin - reports and status:** can view dashboards, use My Dashboard, create status reports, edit reports they are allowed to manage, and use Status Center.
- **Role Manager:** can view all dashboards and admin pages, use My Dashboard for any owner, manage users, review reports, generate owner feedback, and monitor work balance.

## Weekly Status Workflow

1. Open **Status Center**.
2. Click **Add Status**.
3. Select the **Product**.
4. Enter the **Feature / workstream** being reported.
5. Select the **Owner** and optional **Participants**.
6. Confirm **Type of product** and **Role**.
7. Select the **Reporting week**.
8. Add **Start date**, **End date**, and **Baseline end date** if the original plan is known.
9. Select **Depends on** if the work depends on another workstream.
10. Add **Health**, **Progress**, **Stage**, and **Milestone**.
11. Write the **Summary**, **Win**, **Blocker or risk**, and **Next action**.
12. If there is a delay or risk, add:
    - **Delay root cause**
    - **Date change reason**
    - **Corrective action owner**
    - **Action target date**
    - **Decision needed**
    - **Action status**
13. Save the report.

## Schedule Rules

The app classifies delivery based on baseline and current end date:

- **Ahead of Schedule:** delivery is more than 5% earlier than planned.
- **On Time:** delivery is within the expected range.
- **Minor Delay:** delivery is delayed up to 10%.
- **Major Delay:** delivery is delayed more than 10%.

When a date changes, use **Date change reason** to explain why the date moved. This keeps leadership from guessing.

## Report Quality Rules

Report Analysis checks whether each report has enough information to make a decision. A strong report usually includes:

- Product
- Feature / workstream
- Owner
- Reporting week
- End date
- Summary
- Win
- Blocker or risk when needed
- Next action
- Corrective action owner
- Action target date
- Delay root cause when delayed
- Decision needed when risk is high

## Using Dashboards

### Portfolio Dashboard

Use it to review portfolio health, delayed work, products at risk, average progress, and workstream details. Click metric cards to open the related details.

### Executive View

Use it for leadership review. It summarizes the highest-priority risks, blockers, next actions, and schedule concerns.

### My Dashboard

Use it as the personal workspace for each PM or UI/UX owner. It automatically focuses on reports where the signed-in user is the owner or participant.

My Dashboard shows:

- Personal workstream count and project coverage.
- At-risk, blocker, and schedule-watch metrics.
- Average progress across the user's filtered work.
- Items that need clearer next actions or missing information.
- A personal action queue with blockers, decisions, next actions, and action owners.
- A personal delivery timeline with dates, dependencies, milestones, and schedule classification.
- Feedback suggestions based on report quality.

Role Managers can switch the owner filter to review another user's personal dashboard. Master admins can open a workstream from My Dashboard and update it in Status Center.

### Incidents & Delays

Use it to investigate delayed items, due-soon items, postponed work, blockers, and impacted projects.

### Delivery Timeline

Use it to see planned work across time. The timeline uses start/end dates, milestones, dependencies, and schedule status to show delivery movement.

## Using Status Center

Status Center combines submitted reports and editing in one workspace.

- Select a card on the left to edit it on the right.
- Use filters to focus by owner, type of product, reporting week, health, and role.
- Use **History** to review saved changes and audit events.
- Export filtered data to CSV, Excel, or PDF.
- Use **My Dashboard** first when you want to update only your own workstreams.

## Owner Feedback

Role Managers can use Owner Feedback and Owner Weekly Feedback to generate coaching notes based on submitted reports.

Good owner feedback should explain:

- What the owner reported.
- What is missing or unclear.
- What action the owner should take next.
- What delivery risk needs escalation.
- What lesson should be carried into the next week.

## Action Items

Action Items turns reports into follow-up work. It highlights:

- Escalations
- Blockers
- Missing next actions
- Schedule recovery items
- Report quality improvements

Each action should have an owner, target date, and status.

## Best Practices

- Use one clear owner per report.
- Keep participants separate from the owner.
- Do not leave next action blank.
- If the end date changes, always explain the reason.
- If the report is at risk, identify the decision needed.
- Close actions only after the work is truly resolved.
- Start the week from **My Dashboard** to review your own action queue before updating reports.
- Review Report Analysis before weekly leadership meetings.
