
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user() cascade;

drop policy if exists "Anyone can read storage buckets" on storage.buckets;
drop policy if exists "Authenticated users can create storage buckets" on storage.buckets;
drop policy if exists "Anyone can read storage files" on storage.objects;
drop policy if exists "Anyone can upload storage files" on storage.objects;
drop policy if exists "Authenticated users can upload storage files" on storage.objects;
drop policy if exists "Anyone can update storage files" on storage.objects;
drop policy if exists "Users can update storage files" on storage.objects;
drop policy if exists "Anyone can delete storage files" on storage.objects;
drop policy if exists "Users can delete storage files" on storage.objects;

drop table if exists public.mcp_api_keys cascade;
drop table if exists public.tips cascade;
drop table if exists public.invites cascade;
drop table if exists public.messages cascade;
drop table if exists public.snippets cascade;
drop table if exists public.posts cascade;
drop table if exists public.upvotes cascade;
drop table if exists public.packages cascade;
drop table if exists public.profiles cascade;

create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    username text unique not null,
    avatar_url text,
    bio text,
    website_url text,
    github_url text,
    plan text not null default 'free' check (plan in ('free', 'pro')),
    state text not null default 'user',
    created_at timestamptz not null default timezone('utc', now())
);

create table public.packages (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) on delete set null,
    title text not null,
    description text not null,
    category text not null default 'CLI Tool',
    repo_url text not null,
    submitted_by text not null,
    created_at timestamptz not null default timezone('utc', now())
);

create table public.upvotes (
    id uuid primary key default gen_random_uuid(),
    package_id uuid not null references public.packages(id) on delete cascade,
    user_id uuid references auth.users(id) on delete cascade,
    voter_ip text,
    created_at timestamptz not null default timezone('utc', now()),
    constraint unique_user_upvote unique (package_id, user_id)
);

create table public.posts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) on delete cascade,
    author_name text not null,
    title text not null,
    content text not null,
    created_at timestamptz not null default timezone('utc', now())
);

create table public.snippets (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) on delete cascade,
    author_name text not null,
    title text not null,
    language text not null default 'javascript',
    code text not null,
    description text,
    created_at timestamptz not null default timezone('utc', now())
);

create table public.messages (
    id uuid primary key default gen_random_uuid(),
    sender_id uuid not null references auth.users(id) on delete cascade,
    receiver_id uuid not null references auth.users(id) on delete cascade,
    content text not null,
    created_at timestamptz not null default timezone('utc', now())
);

create table public.invites (
    id uuid primary key default gen_random_uuid(),
    code text unique not null,
    is_used boolean not null default false,
    used_by uuid references auth.users(id) on delete set null,
    created_at timestamptz not null default timezone('utc', now())
);

create table public.tips (
    id uuid primary key default gen_random_uuid(),
    sender_id uuid references auth.users(id) on delete set null,
    receiver_id uuid references auth.users(id) on delete set null,
    amount numeric(10,2) not null check (amount > 0),
    timestamp timestamptz not null default timezone('utc', now())
);

create table public.mcp_api_keys (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    name text not null,
    key_hash text not null unique,
    key_prefix text not null,
    created_at timestamptz not null default timezone('utc', now()),
    last_used_at timestamptz,
    revoked_at timestamptz
);

alter table public.profiles enable row level security;
alter table public.packages enable row level security;
alter table public.upvotes enable row level security;
alter table public.posts enable row level security;
alter table public.snippets enable row level security;
alter table public.messages enable row level security;
alter table public.invites enable row level security;
alter table public.tips enable row level security;
alter table public.mcp_api_keys enable row level security;

create policy "Anyone can view profiles"
on public.profiles
for select
using (true);

create policy "Users can insert their own profile"
on public.profiles
for insert
with check (auth.uid() = id);

create policy "Users can update their own profile"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "Anyone can read packages"
on public.packages
for select
using (true);

create policy "Authenticated users can create packages"
on public.packages
for insert
with check (auth.uid() = user_id);

create policy "Package owners can update their packages"
on public.packages
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete their own MCP keys"
on public.mcp_api_keys
for delete
using (auth.uid() = user_id);

create policy "Package owners can delete their packages"
on public.packages
for delete
using (auth.uid() = user_id);

create policy "Anyone can read upvotes"
on public.upvotes
for select
using (true);

create policy "Authenticated users can create upvotes"
on public.upvotes
for insert
with check (auth.uid() = user_id);

create policy "Users can remove their own upvotes"
on public.upvotes
for delete
using (auth.uid() = user_id);

create policy "Anyone can view posts"
on public.posts
for select
using (true);

create policy "Authenticated users can create posts"
on public.posts
for insert
with check (auth.uid() = user_id);

create policy "Post owners can update posts"
on public.posts
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Post owners can delete posts"
on public.posts
for delete
using (auth.uid() = user_id);

create policy "Anyone can view snippets"
on public.snippets
for select
using (true);

create policy "Authenticated users can create snippets"
on public.snippets
for insert
with check (auth.uid() = user_id);

create policy "Snippet owners can update snippets"
on public.snippets
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Snippet owners can delete snippets"
on public.snippets
for delete
using (auth.uid() = user_id);

create policy "Users can view their own messages"
on public.messages
for select
using (
    auth.uid() = sender_id
    or auth.uid() = receiver_id
);

create policy "Users can send messages"
on public.messages
for insert
with check (auth.uid() = sender_id);

create policy "Anyone can read invites"
on public.invites
for select
using (true);

create policy "Authenticated users can update invites"
on public.invites
for update
using (auth.uid() is not null)
with check (auth.uid() is not null);

create policy "Anyone can view tips"
on public.tips
for select
using (true);

create policy "Authenticated users can send tips"
on public.tips
for insert
with check (
    auth.uid() = sender_id
    and amount > 0
);

create policy "Users can view their own MCP keys"
on public.mcp_api_keys
for select
using (auth.uid() = user_id);

create policy "Users can create their own MCP keys"
on public.mcp_api_keys
for insert
with check (auth.uid() = user_id);

create policy "Users can revoke their own MCP keys"
on public.mcp_api_keys
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    base_username text;
    final_username text;
begin
    base_username := coalesce(
        split_part(new.email, '@', 1),
        'developer'
    );

    final_username := base_username;

    if exists (
        select 1
        from public.profiles
        where username = final_username
    ) then
        final_username :=
            base_username || '_' ||
            substr(new.id::text, 1, 8);
    end if;

    insert into public.profiles (
        id,
        username,
        avatar_url,
        state
    )
    values (
        new.id,
        final_username,
        'https://api.dicebear.com/7.x/identicon/svg?seed=' || new.id,
        'user'
    )
    on conflict (id) do nothing;

    return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

create index idx_profiles_username
on public.profiles(username);

create index idx_packages_created_at
on public.packages(created_at desc);

create index idx_packages_user_id
on public.packages(user_id);

create index idx_upvotes_package_id
on public.upvotes(package_id);

create index idx_upvotes_user_id
on public.upvotes(user_id);

create index idx_posts_created_at
on public.posts(created_at desc);

create index idx_posts_user_id
on public.posts(user_id);

create index idx_snippets_created_at
on public.snippets(created_at desc);

create index idx_snippets_user_id
on public.snippets(user_id);

create index idx_messages_sender_receiver
on public.messages(sender_id, receiver_id);

create index idx_invites_code
on public.invites(code);

create index idx_tips_receiver_id
on public.tips(receiver_id);

create index idx_tips_sender_id
on public.tips(sender_id);

create index idx_mcp_api_keys_user_id
on public.mcp_api_keys(user_id);

create index idx_mcp_api_keys_hash
on public.mcp_api_keys(key_hash);

insert into public.invites (code)
values
    ('DEV2026'),
    ('WEBDEV-VIP'),
    ('WELCOME-HUB'),
    ('BETA-TESTER')
on conflict (code) do nothing;

insert into storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
values (
    'files',
    'files',
    true,
    10485760,
    null
)
on conflict (id)
do update set
    public = true,
    file_size_limit = 10485760;

create policy "Anyone can read storage files"
on storage.objects
for select
using (
    bucket_id = 'files'
);

create policy "Authenticated users can upload storage files"
on storage.objects
for insert
with check (
    bucket_id = 'files'
    and auth.role() = 'authenticated'
);

create policy "Users can update storage files"
on storage.objects
for update
using (
    bucket_id = 'files'
    and auth.role() = 'authenticated'
)
with check (
    bucket_id = 'files'
    and auth.role() = 'authenticated'
);

create policy "Users can delete storage files"
on storage.objects
for delete
using (
    bucket_id = 'files'
    and auth.role() = 'authenticated'
);

