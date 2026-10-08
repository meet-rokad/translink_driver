-- ============================================================
-- 1. Ensure UNIQUE constraint on partners(profile_id)
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'uq_partners_profile_id'
    ) THEN
        ALTER TABLE public.partners ADD CONSTRAINT uq_partners_profile_id UNIQUE (profile_id);
    END IF;
END $$;

-- ============================================================
-- 2. Create truck_catalog table if not exists
-- ============================================================
CREATE TABLE IF NOT EXISTS public.truck_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand TEXT NOT NULL,
    model_name TEXT NOT NULL,
    truck_type TEXT NOT NULL,
    body_type TEXT NOT NULL,
    capacity_kg INTEGER NOT NULL,
    capacity_tons NUMERIC(8,2) NOT NULL,
    length_ft NUMERIC(5,2),
    width_ft NUMERIC(5,2),
    height_ft NUMERIC(5,2),
    fuel_type TEXT DEFAULT 'diesel',
    photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_truck_catalog_brand ON public.truck_catalog(brand);
CREATE INDEX IF NOT EXISTS idx_truck_catalog_truck_type ON public.truck_catalog(truck_type);
CREATE INDEX IF NOT EXISTS idx_truck_catalog_capacity ON public.truck_catalog(capacity_kg);

-- Allow public read on truck_catalog for vehicle selection
ALTER TABLE public.truck_catalog ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access to truck_catalog" ON public.truck_catalog;
CREATE POLICY "Allow public read access to truck_catalog"
    ON public.truck_catalog FOR SELECT
    TO public
    USING (true);

-- Allow authenticated insert/update if needed
DROP POLICY IF EXISTS "Allow authenticated users to insert truck_catalog" ON public.truck_catalog;
CREATE POLICY "Allow authenticated users to insert truck_catalog"
    ON public.truck_catalog FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- 3. Trigger: Auto sync Partner & Default Driver on Profile creation
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_profile_partner_sync()
RETURNS TRIGGER AS $$
BEGIN
    -- If role is partner, ensure row exists in partners table
    IF NEW.role = 'partner' THEN
        INSERT INTO public.partners (
            profile_id,
            owner_name,
            mobile_number,
            email,
            city,
            state,
            partner_type,
            onboarding_status,
            verification_status
        ) VALUES (
            NEW.id,
            COALEsCE(NEW.full_name, 'Partner'),
            COALESCE(NEW.mobile_number, ''),
            NEW.email,
            NEW.city,
            NEW.state,
            'individual_owner',
            'in_progress',
            'pending'
        )
        ON CONFLICT (profile_id) DO UPDATE SET
            owner_name = EXCLUDED.owner_name,
            mobile_number = EXCLUDED.mobile_number,
            email = EXCLUDED.email,
            city = EXCLUDED.city,
            state = EXCLUDED.state,
            updated_at = now();

        -- Also ensure a corresponding driver record exists in drivers table
        INSERT INTO public.drivers (
            partner_id,
            profile_id,
            driver_name,
            mobile_number,
            city,
            state,
            is_available
        )
        SELECT 
            p.id,
            NEW.id,
            COALESCE(NEW.full_name, 'Driver'),
            COALESCE(NEW.mobile_number, ''),
            NEW.city,
            NEW.state,
            true
        FROM public.partners p
        WHERE p.profile_id = NEW.id
        ON CONFLICT DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_profile_to_partner ON public.profiles;
CREATE TRIGGER trg_sync_profile_to_partner
    AFTER INSERT OR UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_profile_partner_sync();
