-- 1. Drop existing tables completely (with CASCADE to remove old foreign keys)
drop table if exists public.upvotes cascade;
drop table if exists public.packages cascade;

-- 2. Create Packages Table (No auth.users dependency)
create table public.packages (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  repo_url text not null,
  submitted_by text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Create Upvotes Table (Allows anonymous upvotes)
create table public.upvotes (
  id uuid primary key default gen_random_uuid(),
  package_id uuid references public.packages(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. Enable RLS
alter table public.packages enable row level security;
alter table public.upvotes enable row level security;

-- 5. Open RLS Policies (Public access for read & write)
create policy "Anyone can read packages" on public.packages 
  for select using (true);

create policy "Anyone can submit packages" on public.packages 
  for insert with check (true);

create policy "Anyone can read upvotes" on public.upvotes 
  for select using (true);

create policy "Anyone can insert upvotes" on public.upvotes 
  for insert with check (true);
