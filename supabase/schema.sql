-- Alumni Mentorship Platform — schema, triggers, and RLS policies.
-- Run this in the Supabase SQL Editor (Dashboard → SQL → New query → Run).
-- Safe to re-run: objects use `if not exists` / `or replace` where possible.

-- ============================================================================
-- Extensions
-- ============================================================================
create extension if not exists "pgcrypto";     -- gen_random_uuid()
create extension if not exists "supabase_vault"; -- available by default on new projects

-- ============================================================================
-- profiles (1:1 with auth.users)
-- ============================================================================
create table if not exists public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  email           text not null,
  full_name       text not null default '',
  role            text not null default 'student'
                  check (role in ('student', 'alumni', 'admin')),
  graduation_year integer,
  program         text,
  avatar_url      text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- Auto-create a profile row whenever a new auth.users row is created.
-- The `role` is read from raw_user_meta_data (passed at signUp time).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'student')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep updated_at fresh.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

-- ============================================================================
-- mentors (alumni who opt in to mentor)
-- ============================================================================
create table if not exists public.mentors (
  id                uuid primary key references public.profiles(id) on delete cascade,
  domain            text not null default '',
  experience_years  integer not null default 0,
  bio               text not null default '',
  availability      text not null default 'accepting'
                    check (availability in ('accepting', 'booked', 'break')),
  skills            text[] not null default '{}',
  linkedin_url      text,
  is_featured       boolean not null default false,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

drop trigger if exists mentors_touch_updated_at on public.mentors;
create trigger mentors_touch_updated_at
  before update on public.mentors
  for each row execute function public.touch_updated_at();

-- ============================================================================
-- booking_requests
-- ============================================================================
create table if not exists public.booking_requests (
  id            uuid primary key default gen_random_uuid(),
  student_id    uuid not null references public.profiles(id) on delete cascade,
  mentor_id     uuid not null references public.mentors(id) on delete cascade,
  topic         text not null,
  session_type  text not null default 'video'
                check (session_type in ('video', 'in_person', 'async')),
  preferred_at  timestamptz,
  message       text not null default '',
  status        text not null default 'pending'
                check (status in ('pending', 'accepted', 'declined', 'rescheduled', 'completed')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists booking_requests_student_idx on public.booking_requests(student_id);
create index if not exists booking_requests_mentor_idx  on public.booking_requests(mentor_id);
create index if not exists booking_requests_status_idx  on public.booking_requests(status);

drop trigger if exists booking_requests_touch_updated_at on public.booking_requests;
create trigger booking_requests_touch_updated_at
  before update on public.booking_requests
  for each row execute function public.touch_updated_at();

-- ============================================================================
-- forum_posts
-- ============================================================================
create table if not exists public.forum_posts (
  id          uuid primary key default gen_random_uuid(),
  author_id   uuid not null references public.profiles(id) on delete cascade,
  type        text not null default 'discussion'
              check (type in ('question', 'insight', 'discussion')),
  title       text not null,
  body        text not null default '',
  tags        text[] not null default '{}',
  upvotes     integer not null default 0,
  answered    boolean not null default false,
  created_at  timestamptz not null default now()
);

create index if not exists forum_posts_created_idx on public.forum_posts(created_at desc);
create index if not exists forum_posts_author_idx  on public.forum_posts(author_id);

-- ============================================================================
-- forum_replies (single-level threading via parent_reply_id)
-- ============================================================================
create table if not exists public.forum_replies (
  id              uuid primary key default gen_random_uuid(),
  post_id         uuid not null references public.forum_posts(id) on delete cascade,
  author_id       uuid not null references public.profiles(id) on delete cascade,
  parent_reply_id uuid references public.forum_replies(id) on delete cascade,
  body            text not null,
  upvotes         integer not null default 0,
  created_at      timestamptz not null default now()
);

create index if not exists forum_replies_post_idx on public.forum_replies(post_id);

-- ============================================================================
-- Role helper functions (used by RLS policies)
-- Defined after the tables they reference exist.
-- ============================================================================
-- Returns the role of the currently authenticated user, or NULL.
create or replace function public.current_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.role from public.profiles p where p.id = auth.uid();
$$;

-- True if the current user is an admin.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_role() = 'admin', false);
$$;

-- True if the current user has a mentor profile (i.e. is an alumni mentor).
create or replace function public.is_mentor()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(select 1 from public.mentors m where m.id = auth.uid());
$$;

-- ============================================================================
-- Row Level Security
-- ============================================================================
alter table public.profiles          enable row level security;
alter table public.mentors           enable row level security;
alter table public.booking_requests enable row level security;
alter table public.forum_posts       enable row level security;
alter table public.forum_replies     enable row level security;

-- profiles: everyone authenticated can read; users can update their own.
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated using (true);

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
  for update to authenticated using (id = auth.uid() or public.is_admin());

-- mentors: everyone authenticated can read; alumni manage their own row; admins full.
drop policy if exists mentors_select on public.mentors;
create policy mentors_select on public.mentors
  for select to authenticated using (true);

drop policy if exists mentors_insert on public.mentors;
create policy mentors_insert on public.mentors
  for insert to authenticated with check (id = auth.uid());

drop policy if exists mentors_update on public.mentors;
create policy mentors_update on public.mentors
  for update to authenticated using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

drop policy if exists mentors_delete on public.mentors;
create policy mentors_delete on public.mentors
  for delete to authenticated using (id = auth.uid() or public.is_admin());

-- booking_requests: parties can read; students create; parties can update status.
drop policy if exists bookings_select on public.booking_requests;
create policy bookings_select on public.booking_requests
  for select to authenticated
  using (student_id = auth.uid() or mentor_id = auth.uid() or public.is_admin());

drop policy if exists bookings_insert on public.booking_requests;
create policy bookings_insert on public.booking_requests
  for insert to authenticated
  with check (student_id = auth.uid());

drop policy if exists bookings_update on public.booking_requests;
create policy bookings_update on public.booking_requests
  for update to authenticated
  using (student_id = auth.uid() or mentor_id = auth.uid() or public.is_admin())
  with check (student_id = auth.uid() or mentor_id = auth.uid() or public.is_admin());

drop policy if exists bookings_delete on public.booking_requests;
create policy bookings_delete on public.booking_requests
  for delete to authenticated
  using (student_id = auth.uid() or public.is_admin());

-- forum_posts: everyone authenticated reads; author creates/updates/deletes own; admin moderates.
drop policy if exists posts_select on public.forum_posts;
create policy posts_select on public.forum_posts
  for select to authenticated using (true);

drop policy if exists posts_insert on public.forum_posts;
create policy posts_insert on public.forum_posts
  for insert to authenticated with check (author_id = auth.uid());

drop policy if exists posts_update on public.forum_posts;
create policy posts_update on public.forum_posts
  for update to authenticated
  using (author_id = auth.uid() or public.is_admin())
  with check (author_id = auth.uid() or public.is_admin());

drop policy if exists posts_delete on public.forum_posts;
create policy posts_delete on public.forum_posts
  for delete to authenticated using (author_id = auth.uid() or public.is_admin());

-- forum_replies: same pattern.
drop policy if exists replies_select on public.forum_replies;
create policy replies_select on public.forum_replies
  for select to authenticated using (true);

drop policy if exists replies_insert on public.forum_replies;
create policy replies_insert on public.forum_replies
  for insert to authenticated with check (author_id = auth.uid());

drop policy if exists replies_update on public.forum_replies;
create policy replies_update on public.forum_replies
  for update to authenticated
  using (author_id = auth.uid() or public.is_admin())
  with check (author_id = auth.uid() or public.is_admin());

drop policy if exists replies_delete on public.forum_replies;
create policy replies_delete on public.forum_replies
  for delete to authenticated using (author_id = auth.uid() or public.is_admin());

-- ============================================================================
-- Realtime (ready for v1.1 — not wired in the MVP client yet)
-- ============================================================================
do $$
begin
  begin
    alter publication supabase_realtime add table public.forum_posts;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.forum_replies;
  exception when duplicate_object then null;
  end;
end $$;