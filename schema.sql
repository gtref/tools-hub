-- 1. Drop existing tables completely (with CASCADE to remove old foreign keys)
drop table if exists public.upvotes cascade;
drop table if exists public.packages cascade;
drop table if exists public.profiles cascade;

-- 2. Create Profiles / Dedicated Users Table
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  avatar_url text,
  plan text default 'free' check (plan in ('free', 'pro')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Create Packages Table with user reference & category
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

-- 4. Create Upvotes Table with unique constraint per user/package
create table public.upvotes (
  id uuid primary key default gen_random_uuid(),
  package_id uuid references public.packages(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade,
  voter_ip text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint unique_user_upvote unique (package_id, user_id)
);

-- 5. Enable Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.packages enable row level security;
alter table public.upvotes enable row level security;

-- 6. RLS Policies for Profiles
create policy "Anyone can view profiles" on public.profiles
  for select using (true);

create policy "Users can update their own profile" on public.profiles
  for update using (auth.uid() = id);

create policy "Users can insert their own profile" on public.profiles
  for insert with check (auth.uid() = id or auth.uid() is null);

-- 7. RLS Policies for Packages
create policy "Anyone can read packages" on public.packages 
  for select using (true);

create policy "Anyone can insert packages" on public.packages
  for insert with check (true);

create policy "Package owners can update their packages" on public.packages
  for update using (auth.uid() = user_id);

create policy "Package owners can delete their packages" on public.packages
  for delete using (auth.uid() = user_id);

-- 8. RLS Policies for Upvotes
create policy "Anyone can read upvotes" on public.upvotes 
  for select using (true);

create policy "Anyone can insert upvotes" on public.upvotes 
  for insert with check (true);

create policy "Users can remove their upvote" on public.upvotes
  for delete using (auth.uid() = user_id or user_id is null);

-- 9. Automatic Profile Creation Trigger on Sign-up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, avatar_url)
  values (
    new.id,
    coalesce(split_part(new.email, '@', 1), 'developer'),
    'https://api.dicebear.com/7.x/identicon/svg?seed=' || new.id
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 10. Performance Indexes
create index idx_profiles_username on public.profiles(username);
create index idx_packages_created_at on public.packages(created_at desc);
create index idx_packages_user_id on public.packages(user_id);
create index idx_upvotes_package_id on public.upvotes(package_id);
create index idx_upvotes_user_id on public.upvotes(user_id);

-- 11. Supabase Storage Bucket & RLS Policies for Files (10MB Max Size)
-- 11. Supabase Storage Bucket & RLS Policies for Files & User Buckets (10MB Max Size)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('files', 'files', true, 10485760, null)
on conflict (id) do update set
  public = true,
  file_size_limit = 10485760;

-- Bucket level policies
create policy "Anyone can read storage buckets" on storage.buckets
  for select using (true);

create policy "Authenticated users can create storage buckets" on storage.buckets
  for insert with check (auth.role() = 'authenticated');

-- Object level policies
create policy "Anyone can read storage files" on storage.objects
  for select using (true);

create policy "Anyone can upload storage files" on storage.objects
  for insert with check (true);

create policy "Anyone can update storage files" on storage.objects
  for update using (true);

create policy "Anyone can delete storage files" on storage.objects
  for delete using (true);
