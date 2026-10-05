-- ============================================================
-- FIX: Cleanup duplicate active trucks before creating unique index
-- Run this in Supabase SQL Editor BEFORE running 0002_core_schema.sql
-- ============================================================

-- Step 1: For each partner, keep only the LATEST truck as active,
--         mark all older ones as inactive
UPDATE public.trucks AS t
SET is_active = FALSE, status = 'INACTIVE'
WHERE t.id NOT IN (
    -- Keep only the most recently created truck per partner
    SELECT DISTINCT ON (partner_id) id
    FROM public.trucks
    WHERE is_active = TRUE
    ORDER BY partner_id, created_at DESC
);

-- Step 2: Verify — should show max 1 active truck per partner
SELECT partner_id, COUNT(*) as active_count
FROM public.trucks
WHERE is_active = TRUE
GROUP BY partner_id
HAVING COUNT(*) > 1;
-- ^^^ This should return 0 rows. If rows appear, something is still wrong.

-- Step 3: Now safe to create the unique index
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_active_truck_per_partner
    ON public.trucks(partner_id)
    WHERE is_active = TRUE;
