-- ============================================================
-- MSHS Multimedia Club Join Portal — Supabase schema
-- ============================================================
-- Run this once in the Supabase SQL editor for your project.
--
-- This project now shares its Supabase project with the main
-- Multimedia Club website:
--   • Registering on the Join Portal creates a real Supabase Auth
--     account (email + password), so members can log in on the
--     main site with the same credentials.
--   • Applications are stored in `applications`, optionally linked
--     to the member's auth account via `user_id`.
--   • Club officers get an `admin` role (via the `profiles` table)
--     and can log in on admin.html to review, filter, search, and
--     update applications.
-- ============================================================

create extension if not exists "pgcrypto";

-- ============================================================
-- 1. profiles — one row per auth user, tracks role (member/admin)
-- ============================================================
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text,
  full_name   text,
  role        text not null default 'member' check (role in ('member', 'admin')),
  created_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Users can see their own profile (used by admin.html to check role).
create policy "Users can view their own profile"
  on public.profiles
  for select
  to authenticated
  using (id = auth.uid());

-- Auto-create a profile row whenever someone signs up (e.g. via the
-- Join Portal's registration form). New accounts default to 'member'.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data ->> 'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ------------------------------------------------------------
-- IMPORTANT — bootstrap your first admin manually:
-- 1. Register once through the Join Portal (or Supabase Auth)
--    using the account you want to be an admin.
-- 2. Then run, replacing the email:
--
--   update public.profiles set role = 'admin' where email = 'officer@example.com';
--
-- Only do this from the SQL editor / service role — never expose
-- a way for the public site to grant itself the admin role.
-- ------------------------------------------------------------

-- ============================================================
-- 2. applications — membership applications
-- ============================================================
create table if not exists public.applications (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid references auth.users(id) on delete set null,
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

create index if not exists applications_submitted_at_idx
  on public.applications (submitted_at desc);

create index if not exists applications_status_idx
  on public.applications (status);

create index if not exists applications_specialty_idx
  on public.applications (preferred_specialty);

create index if not exists applications_user_id_idx
  on public.applications (user_id);

-- ============================================================
-- Row Level Security — applications
-- ============================================================
alter table public.applications enable row level security;

-- Anyone (signed up or not) can submit an application — the Join
-- Portal calls auth.signUp() first, then inserts here, but we keep
-- this open to `anon` too so submissions never break on timing.
create policy "Anyone can submit an application"
  on public.applications
  for insert
  to anon, authenticated
  with check (true);

-- Only admins (checked via their own profiles row) can view applications.
create policy "Admins can view applications"
  on public.applications
  for select
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

-- Only admins can update applications (e.g. change status).
create policy "Admins can update applications"
  on public.applications
  for update
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  )
  with check (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

-- Only admins can delete applications.
create policy "Admins can delete applications"
  on public.applications
  for delete
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

-- No SELECT/UPDATE/DELETE policy exists for `anon`, and regular
-- `authenticated` members (role = 'member') aren't matched by the
-- admin policies above, so members can submit but never read,
-- edit, or delete applications — only admins can.
