-- ============================================================
-- 1. Ensure phone_number column exists on customers for backwards compatibility
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'customers' 
          AND column_name = 'phone_number'
    ) THEN
        ALTER TABLE public.customers ADD COLUMN phone_number TEXT;
    END IF;
END $$;

-- ============================================================
-- 2. Ensure mobile_number column exists on customers as alias
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'customers' 
          AND column_name = 'mobile_number'
    ) THEN
        ALTER TABLE public.customers ADD COLUMN mobile_number TEXT;
    END IF;
END $$;

-- ============================================================
-- 3. Ensure status column exists on partners as fallback
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'partners' 
          AND column_name = 'status'
    ) THEN
        ALTER TABLE public.partners ADD COLUMN status TEXT DEFAULT 'ACTIVE';
    END IF;
END $$;
