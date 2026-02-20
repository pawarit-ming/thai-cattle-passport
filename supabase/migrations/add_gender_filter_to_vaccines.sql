-- Add gender_filter column to existing vaccines table
-- Run this ONLY if you already have the vaccines table created
-- (If creating fresh, use create_vaccines_table.sql instead)

ALTER TABLE public.vaccines ADD COLUMN IF NOT EXISTS gender_filter text;

-- Set Brucellosis as female-only
UPDATE public.vaccines SET gender_filter = 'FEMALE' WHERE id = 'BRUCELLOSIS';
