-- Add missing columns to return_requirements that match the Dart model
ALTER TABLE public.return_requirements
ADD COLUMN IF NOT EXISTS origin TEXT,
ADD COLUMN IF NOT EXISTS destination TEXT,
ADD COLUMN IF NOT EXISTS route_date DATE,
ADD COLUMN IF NOT EXISTS availability_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS current_location TEXT,
ADD COLUMN IF NOT EXISTS notes TEXT;
