-- ============================================================
-- MSHS Multimedia Club Join Portal — Supabase schema
-- ============================================================
-- Run this once in the Supabase SQL editor for your project.
-- It creates the `applications` table and locks it down with
-- Row Level Security so that:
--   • anyone (anon, public) can SUBMIT an application (INSERT)
--   • nobody on the public/anon key can READ, UPDATE, or DELETE
--   • club officers/admins manage applications from the Supabase
--     Table Editor (or any tool using the service_role key),
--     which bypasses RLS by design.
-- ============================================================

-- Extension needed for gen_random_uuid()
create extension if not exists "pgcrypto";

create table if not exists public.applications (
  id                    uuid primary key default gen_random_uuid(),
  full_name             text not null,
  student_id            text not null,
  grade_level           text not null,
  section               text not null,
  email                 text not null,
  contact_number        text,
  preferred_specialty   text not null,
  status                text not null default 'Pending',
  submitted_at          timestamptz not null default now()
);

-- Helpful constraints so bad data can't sneak in
alter table public.applications
  add constraint applications_status_check
  check (status in ('Pending', 'Reviewed', 'Approved', 'Declined'));

alter table public.applications
  add constraint applications_specialty_check
  check (preferred_specialty in (
    'Photographer',
    'Videographer',
    'Graphic Designer',
    'Video Editor',
    'Writer',
    'Social Media Manager',
    'Any / Willing to Learn'
  ));

alter table public.applications
  add constraint applications_email_check
  check (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Index for officers sorting/filtering the dashboard by date or status
create index if not exists applications_submitted_at_idx
  on public.applications (submitted_at desc);

create index if not exists applications_status_idx
  on public.applications (status);

-- ============================================================
-- Row Level Security
-- ============================================================
alter table public.applications enable row level security;

-- Public/anon visitors may INSERT a new application (submit the form).
create policy "Anyone can submit an application"
  on public.applications
  for insert
  to anon
  with check (true);

-- No SELECT / UPDATE / DELETE policies are created for `anon` or
-- `authenticated`, which means the public site can never read,
-- edit, or delete applications — it can only write new rows.
-- Officers/admins review and manage submissions via the Supabase
-- Table Editor (or a separate internal admin tool) using the
-- service_role key, which always bypasses RLS.
