-- 1. Drop existing tables completely (with CASCADE to remove old foreign keys)
drop table if exists public.tips cascade;
drop table if exists public.invites cascade;
drop table if exists public.messages cascade;
drop table if exists public.snippets cascade;
drop table if exists public.posts cascade;
drop table if exists public.upvotes cascade;
drop table if exists public.packages cascade;
drop table if exists public.profiles cascade;

-- 2. Create Profiles / Dedicated Users Table
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  avatar_url text,
  bio text,
  website_url text,
  github_url text,
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

-- 5. Create Posts Table (Blogging system & Developer Feed)
create table public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  author_name text not null,
  title text not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. Create Code Snippets Table
create table public.snippets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  author_name text not null,
  title text not null,
  language text default 'javascript',
  code text not null,
  description text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 7. Create Private Messages Table
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid references auth.users(id) on delete cascade not null,
  receiver_id uuid references auth.users(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 8. Create Invite Codes Table
create table public.invites (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  is_used boolean default false,
  used_by uuid references auth.users(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 9. Create Micro-Tips Table
create table public.tips (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid references auth.users(id) on delete set null,
  receiver_id uuid references auth.users(id) on delete set null,
  amount numeric(10,2) not null,
  timestamp timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.packages enable row level security;
alter table public.upvotes enable row level security;
alter table public.posts enable row level security;
alter table public.snippets enable row level security;
alter table public.messages enable row level security;
alter table public.invites enable row level security;
alter table public.tips enable row level security;

-- RLS Policies for Profiles
create policy "Anyone can view profiles" on public.profiles for select using (true);
create policy "Users can update their own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert their own profile" on public.profiles for insert with check (auth.uid() = id or auth.uid() is null);

-- RLS Policies for Packages
create policy "Anyone can read packages" on public.packages for select using (true);
create policy "Anyone can insert packages" on public.packages for insert with check (true);
create policy "Package owners can update their packages" on public.packages for update using (auth.uid() = user_id);
create policy "Package owners can delete their packages" on public.packages for delete using (auth.uid() = user_id);

-- RLS Policies for Upvotes
create policy "Anyone can read upvotes" on public.upvotes for select using (true);
create policy "Anyone can insert upvotes" on public.upvotes for insert with check (true);
create policy "Users can remove their upvote" on public.upvotes for delete using (auth.uid() = user_id or user_id is null);

-- RLS Policies for Posts
create policy "Anyone can view posts" on public.posts for select using (true);
create policy "Authenticated users can create posts" on public.posts for insert with check (auth.uid() = user_id or user_id is null);
create policy "Post owners can update posts" on public.posts for update using (auth.uid() = user_id);
create policy "Post owners can delete posts" on public.posts for delete using (auth.uid() = user_id);

-- RLS Policies for Snippets
create policy "Anyone can view snippets" on public.snippets for select using (true);
create policy "Authenticated users can create snippets" on public.snippets for insert with check (auth.uid() = user_id or user_id is null);
create policy "Snippet owners can update snippets" on public.snippets for update using (auth.uid() = user_id);
create policy "Snippet owners can delete snippets" on public.snippets for delete using (auth.uid() = user_id);

-- RLS Policies for Private Messages
create policy "Users can view messages sent to or by them" on public.messages for select using (auth.uid() = sender_id or auth.uid() = receiver_id);
create policy "Users can send messages" on public.messages for insert with check (auth.uid() = sender_id);

-- RLS Policies for Invites
create policy "Anyone can read invites" on public.invites for select using (true);
create policy "Anyone can update invites" on public.invites for update using (true);
create policy "Anyone can insert invites" on public.invites for insert with check (true);

-- RLS Policies for Tips
create policy "Anyone can view tips" on public.tips for select using (true);
create policy "Anyone can send tips" on public.tips for insert with check (true);

-- Automatic Profile Creation Trigger on Sign-up
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

-- Performance Indexes
create index idx_profiles_username on public.profiles(username);
create index idx_packages_created_at on public.packages(created_at desc);
create index idx_packages_user_id on public.packages(user_id);
create index idx_upvotes_package_id on public.upvotes(package_id);
create index idx_upvotes_user_id on public.upvotes(user_id);
create index idx_posts_created_at on public.posts(created_at desc);
create index idx_posts_user_id on public.posts(user_id);
create index idx_snippets_created_at on public.snippets(created_at desc);
create index idx_snippets_user_id on public.snippets(user_id);
create index idx_messages_sender_receiver on public.messages(sender_id, receiver_id);
create index idx_invites_code on public.invites(code);

-- Seed Initial Invite Codes
insert into public.invites (code) values
  ('DEV2026'),
  ('WEBDEV-VIP'),
  ('WELCOME-HUB'),
  ('BETA-TESTER')
on conflict (code) do nothing;

-- Supabase Storage Bucket & RLS Policies for Files & User Buckets (10MB Max Size)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('files', 'files', true, 10485760, null)
on conflict (id) do update set
  public = true,
  file_size_limit = 10485760;

create policy "Anyone can read storage buckets" on storage.buckets for select using (true);
create policy "Authenticated users can create storage buckets" on storage.buckets for insert with check (auth.role() = 'authenticated');
create policy "Anyone can read storage files" on storage.objects for select using (true);
create policy "Anyone can upload storage files" on storage.objects for insert with check (true);
create policy "Anyone can update storage files" on storage.objects for update using (true);
create policy "Anyone can delete storage files" on storage.objects for delete using (true);
