-- Create Loads table (Posted by shippers, browsed by drivers)
CREATE TABLE IF NOT EXISTS public.driver_loads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    shipper_id UUID REFERENCES auth.users(id),
    shipper_name TEXT NOT NULL,
    shipper_contact TEXT NOT NULL,
    origin TEXT NOT NULL,
    destination TEXT NOT NULL,
    pickup_location TEXT NOT NULL,
    drop_location TEXT NOT NULL,
    pickup_date DATE NOT NULL,
    truck_type TEXT NOT NULL,
    material_type TEXT NOT NULL,
    distance TEXT,
    price NUMERIC NOT NULL,
    status TEXT DEFAULT 'available', -- available, assigned, completed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Trips table (When a driver accepts/books a load)
CREATE TABLE IF NOT EXISTS public.driver_trips (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    load_id UUID REFERENCES public.driver_loads(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES auth.users(id),
    truck_id UUID REFERENCES public.trucks(id),
    status TEXT DEFAULT 'confirmed', -- confirmed, in_transit, completed, cancelled
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Earnings table
CREATE TABLE IF NOT EXISTS public.driver_earnings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    driver_id UUID REFERENCES auth.users(id),
    trip_id UUID REFERENCES public.driver_trips(id) ON DELETE SET NULL,
    amount NUMERIC NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, received
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    description TEXT
);

-- Create Driver Activities table for the Activity log
CREATE TABLE IF NOT EXISTS public.driver_activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    driver_id UUID REFERENCES auth.users(id),
    activity_type TEXT NOT NULL, -- load_request, payment, trip_update, profile_update
    title TEXT NOT NULL,
    subtitle TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS Policies
ALTER TABLE public.driver_loads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_activities ENABLE ROW LEVEL SECURITY;

-- Loads: Anyone authenticated can read available loads
CREATE POLICY "Drivers can view available loads" 
ON public.driver_loads FOR SELECT 
TO authenticated 
USING (status = 'available');

-- Trips: Drivers can only see their own trips
CREATE POLICY "Drivers can view their own trips" 
ON public.driver_trips FOR SELECT 
TO authenticated 
USING (driver_id = auth.uid());

CREATE POLICY "Drivers can create trips" 
ON public.driver_trips FOR INSERT 
TO authenticated 
WITH CHECK (driver_id = auth.uid());

-- Earnings: Drivers can only view their own earnings
CREATE POLICY "Drivers can view their own earnings" 
ON public.driver_earnings FOR SELECT 
TO authenticated 
USING (driver_id = auth.uid());

-- Activities: Drivers can only view their own activities
CREATE POLICY "Drivers can view their own activities" 
ON public.driver_activities FOR SELECT 
TO authenticated 
USING (driver_id = auth.uid());
