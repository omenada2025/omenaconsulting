-- Align functional ownership with AI Product Factory handbook:
-- Live PM (Builder) + Support PM; keep legacy Product Manager / Training / System Analyst.

alter table public.status_reports
  drop constraint if exists status_reports_role_check;

alter table public.status_reports
  add constraint status_reports_role_check check (
    role is null or role in (
      'Live PM (Builder)', 'Support PM', 'UI/UX',
      'Product Manager', 'Training', 'System Analyst'
    )
  );

alter table public.governance_items
  drop constraint if exists governance_items_functional_role_check;

alter table public.governance_items
  add constraint governance_items_functional_role_check check (
    functional_role in (
      'Live PM (Builder)', 'Support PM', 'UI/UX',
      'Product Manager', 'Training', 'System Analyst'
    )
  );

alter table public.product_artifacts
  drop constraint if exists product_artifacts_artifact_type_check;

alter table public.product_artifacts
  add constraint product_artifacts_artifact_type_check check (artifact_type in (
    'Product Reality Assessment', 'Application/Feature Inventory', 'Application Map',
    'AS-IS Functional Specification', 'Business Rules Catalogue', 'Workflow Catalogue',
    'Roles & Permissions Matrix', 'Data & Integration Map', 'Known Issues Register',
    'Product Gap Register', 'Product Risk Register', 'Product Readiness Assessment',
    'MSP Definition', 'Prioritized Product Backlog', 'TO-BE Product Definition',
    'Research Summary / User Insights', 'Wireframes / Concepts', 'High-Fidelity Designs (Figma)',
    'Design System References', 'Prototype / Usability Validation', 'Design Review Sign-off',
    'Developer Handoff Package', 'Release / Learn Notes',
    'Training Needs Assessment', 'Curriculum / Training Plan', 'Training Materials (deck, guide, video)',
    'Delivery Schedule / Sessions Log', 'Adoption / Completion Metrics', 'Handoff / Support Checklist',
    'Feedback & Improvement Log',
    'Launch Kit', 'Run Kit', 'Live Product Kit'
  ));

notify pgrst, 'reload schema';
