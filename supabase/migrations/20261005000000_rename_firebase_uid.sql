-- Rename the column
ALTER TABLE public.partners RENAME COLUMN firebase_uid TO auth_id;

-- Make sure auth_id is unique
ALTER TABLE public.partners ADD CONSTRAINT partners_auth_id_unique UNIQUE (auth_id);

-- Optional: Link auth_id directly to auth.users if not already done
-- ALTER TABLE public.partners ADD CONSTRAINT partners_auth_id_fkey FOREIGN KEY (auth_id) REFERENCES auth.users(id) ON DELETE CASCADE;
