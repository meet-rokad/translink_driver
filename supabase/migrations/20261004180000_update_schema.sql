-- Create partner_profiles table if it does not exist
CREATE TABLE IF NOT EXISTS public.partner_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id TEXT UNIQUE NOT NULL,
    owner_name TEXT,
    mobile_number TEXT,
    email TEXT,
    gender TEXT,
    business_name TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    pincode TEXT,
    pan_number TEXT,
    gst_number TEXT,
    profile_pic TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure email and gender columns exist just in case it was created earlier
ALTER TABLE public.partner_profiles
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS gender TEXT;

-- Add new columns to trucks
ALTER TABLE public.trucks
ADD COLUMN IF NOT EXISTS current_location TEXT,
ADD COLUMN IF NOT EXISTS regular_starting_location TEXT,
ADD COLUMN IF NOT EXISTS regular_routes TEXT,
ADD COLUMN IF NOT EXISTS driver_name TEXT,
ADD COLUMN IF NOT EXISTS driver_mobile_number TEXT;
