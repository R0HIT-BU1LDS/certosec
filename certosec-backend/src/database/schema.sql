-- ============================================================
-- CertoSec V2 - Supabase PostgreSQL schema
-- Run this in the Supabase SQL editor.
-- All application access goes through the backend (service-role client,
-- which bypasses RLS). RLS is enabled as defence-in-depth only.
-- ============================================================

-- ---------- PROFILES (maps 1:1 to auth.users) ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique,
  full_name text not null default '',
  role text not null default 'verifier'
    check (role in ('admin', 'verifier')),
  institution_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- STUDENTS ----------
create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  student_uid text not null unique,
  full_name text not null,
  email text,
  course text not null,
  department text not null,
  batch text not null,
  phone text,
  profile_photo_url text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- CERTIFICATES ----------
create table if not exists public.certificates (
  id uuid primary key default gen_random_uuid(),
  certificate_uid text not null unique,
  student_id uuid references public.students (id) on delete set null,
  -- Immutable snapshot fields below are part of the canonical hash payload.
  student_uid text not null,
  student_name text not null,
  title text not null,
  description text,
  course text not null,
  department text not null,
  batch text not null,
  issue_date date not null,
  certificate_hash text not null,
  issuer_name text,
  -- Storage / blockchain proof
  pdf_path text,
  pdf_url text,
  transaction_hash text unique,
  block_number bigint,
  block_timestamp timestamptz,
  issuer_address text,
  contract_address text,
  network text,
  status text not null default 'pending'
    check (status in ('pending', 'issued', 'verified', 'revoked')),
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_certificates_certificate_hash
  on public.certificates (certificate_hash);
create index if not exists idx_certificates_status
  on public.certificates (status);
create index if not exists idx_certificates_student_id
  on public.certificates (student_id);
create index if not exists idx_certificates_issue_date
  on public.certificates (issue_date desc);

-- ---------- AUDIT LOGS ----------
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete set null,
  action text not null,
  entity_type text,
  entity_id text,
  ip_address text,
  user_agent text,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_audit_logs_action on public.audit_logs (action);
create index if not exists idx_audit_logs_created_at
  on public.audit_logs (created_at desc);

-- ---------- updated_at trigger ----------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_students_updated_at on public.students;
create trigger trg_students_updated_at
  before update on public.students
  for each row execute function public.set_updated_at();

drop trigger if exists trg_certificates_updated_at on public.certificates;
create trigger trg_certificates_updated_at
  before update on public.certificates
  for each row execute function public.set_updated_at();

-- ---------- RLS (defence-in-depth; backend uses service role) ----------
alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table public.certificates enable row level security;
alter table public.audit_logs enable row level security;

-- ---------- Bootstrap admin ----------
-- The backend upserts this user's profile as `admin` on first login.
-- (Optional - you can also insert directly here.)
-- insert into public.profiles (id, email, full_name, role, institution_name)
-- select id, email, coalesce(raw_user_meta_data->>'full_name', email),
--        'admin', 'CertoSec University Network'
-- from auth.users
-- where lower(email) = lower('admin@example.com')
-- on conflict (id) do nothing;
