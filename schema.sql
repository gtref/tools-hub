-- 1. Drop existing tables completely (with CASCADE to remove old foreign keys)
drop table if exists public.upvotes cascade;
drop table if exists public.packages cascade;

-- 2. Create Packages Table with user reference & category
create table public.packages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  title text not null,
  description text not null,
  category text default 'CLI Tool',
  repo_url text not null,
  submitted_by text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Create Upvotes Table with unique constraint per user/package
create table public.upvotes (
  id uuid primary key default gen_random_uuid(),
  package_id uuid references public.packages(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade,
  voter_ip text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint unique_user_upvote unique (package_id, user_id)
);

-- 4. Enable Row Level Security (RLS)
alter table public.packages enable row level security;
alter table public.upvotes enable row level security;

-- 5. RLS Policies for Packages
create policy "Anyone can read packages" on public.packages 
  for select using (true);

create policy "Anyone can insert packages" on public.packages
  for insert with check (true);

create policy "Package owners can update their packages" on public.packages
  for update using (auth.uid() = user_id);

create policy "Package owners can delete their packages" on public.packages
  for delete using (auth.uid() = user_id);

-- 6. RLS Policies for Upvotes
create policy "Anyone can read upvotes" on public.upvotes 
  for select using (true);

create policy "Anyone can insert upvotes" on public.upvotes 
  for insert with check (true);

create policy "Users can remove their upvote" on public.upvotes
  for delete using (auth.uid() = user_id or user_id is null);

-- 7. Performance Indexes
create index idx_packages_created_at on public.packages(created_at desc);
create index idx_packages_user_id on public.packages(user_id);
create index idx_upvotes_package_id on public.upvotes(package_id);
create index idx_upvotes_user_id on public.upvotes(user_id);
