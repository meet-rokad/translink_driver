-- Enable pgcrypto extension for gen_random_uuid() (built-in for modern postgres)
create extension if not exists "pgcrypto";

-- 1. Users Table (extends auth.users)
create table public.users (
  id uuid references auth.users not null primary key,
  full_name text,
  phone_number text,
  role text check (role in ('driver', 'transporter', 'load_owner')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
alter table public.users enable row level security;
create policy "Users can view their own profile." on public.users for select using (auth.uid() = id);
create policy "Users can update their own profile." on public.users for update using (auth.uid() = id);

-- Trigger to create a profile automatically when a user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, full_name, phone_number, role)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.phone,
    new.raw_user_meta_data->>'role'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- 2. Subscription Plans
create table public.subscription_plans (
  id uuid default gen_random_uuid() primary key,
  plan_name text not null,
  price numeric not null,
  duration_days integer not null,
  features jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
alter table public.subscription_plans enable row level security;
create policy "Anyone can view subscription plans." on public.subscription_plans for select using (true);

-- 3. User Subscriptions
create table public.user_subscriptions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) not null,
  plan_id uuid references public.subscription_plans(id) not null,
  status text check (status in ('active', 'expired', 'cancelled')) default 'active',
  valid_upto timestamp with time zone not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
alter table public.user_subscriptions enable row level security;
create policy "Users can view their own subscriptions." on public.user_subscriptions for select using (auth.uid() = user_id);

-- 4. Loads
create table public.loads (
  id uuid default gen_random_uuid() primary key,
  owner_id uuid references public.users(id) not null,
  pickup_location text not null,
  drop_location text not null,
  material_type text not null,
  weight_tons numeric not null,
  offered_price numeric not null,
  status text check (status in ('pending', 'assigned', 'completed', 'cancelled')) default 'pending',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
alter table public.loads enable row level security;
create policy "Anyone can view pending loads." on public.loads for select using (status = 'pending' or auth.uid() = owner_id);
create policy "Load owners can insert loads." on public.loads for insert with check (auth.uid() = owner_id);
create policy "Load owners can update their loads." on public.loads for update using (auth.uid() = owner_id);

-- 5. Vehicles (Trucks)
create table public.vehicles (
  id uuid default gen_random_uuid() primary key,
  owner_id uuid references public.users(id) not null,
  vehicle_number text not null unique,
  vehicle_type text not null,
  capacity_tons numeric not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
alter table public.vehicles enable row level security;
create policy "Users can view their own vehicles." on public.vehicles for select using (auth.uid() = owner_id);
create policy "Users can insert their own vehicles." on public.vehicles for insert with check (auth.uid() = owner_id);
create policy "Users can update their own vehicles." on public.vehicles for update using (auth.uid() = owner_id);
create policy "Users can delete their own vehicles." on public.vehicles for delete using (auth.uid() = owner_id);


-- 6. Trips
create table public.trips (
  id uuid default gen_random_uuid() primary key,
  load_id uuid references public.loads(id) not null,
  driver_id uuid references public.users(id) not null,
  vehicle_id uuid references public.vehicles(id),
  status text check (status in ('started', 'in_transit', 'delivered', 'cancelled')) default 'started',
  start_time timestamp with time zone default timezone('utc'::text, now()) not null,
  end_time timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
alter table public.trips enable row level security;
create policy "Drivers and owners can view trips." on public.trips for select using (auth.uid() = driver_id or auth.uid() in (select owner_id from public.loads where id = load_id));
create policy "Drivers can update trip status." on public.trips for update using (auth.uid() = driver_id);

-- 7. Earnings
create table public.earnings (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) not null,
  trip_id uuid references public.trips(id) not null,
  amount numeric not null,
  earned_at timestamp with time zone default timezone('utc'::text, now()) not null
);
alter table public.earnings enable row level security;
create policy "Users can view their own earnings." on public.earnings for select using (auth.uid() = user_id);
