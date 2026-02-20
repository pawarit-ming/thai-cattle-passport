-- Vaccine Catalog Table
-- Run this in Supabase SQL Editor

CREATE TABLE public.vaccines (
  id text PRIMARY KEY,
  name_th text NOT NULL,
  name_en text NOT NULL,
  total_doses int NOT NULL DEFAULT 1,
  dose_gap_days int,
  booster_interval_days int,
  gender_filter text,  -- NULL = ทุกเพศ, 'FEMALE' = เฉพาะเมีย, 'MALE' = เฉพาะผู้
  note text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.vaccines ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read vaccines
CREATE POLICY "Allow read for authenticated users" ON public.vaccines
  FOR SELECT TO authenticated USING (true);

-- Seed data
INSERT INTO public.vaccines (id, name_th, name_en, total_doses, dose_gap_days, booster_interval_days, gender_filter, note) VALUES
  ('FMD', 'โรคปากและเท้าเปื่อย', 'Foot and Mouth Disease', 2, 30, 180, NULL, NULL),
  ('HS', 'เฮโมรายิกเซพติซีเมีย', 'Haemorrhagic Septicaemia', 1, NULL, 365, NULL, NULL),
  ('BRUCELLOSIS', 'บรูเซลโลซีส', 'Brucellosis', 1, NULL, NULL, 'FEMALE', 'เฉพาะเพศเมีย อายุ 3-8 เดือน คุ้มโรคนาน 7 ปี'),
  ('BLACKLEG', 'แบลคเลก', 'Blackleg', 2, 30, 180, NULL, NULL),
  ('ANTHRAX', 'แอนแทรกซ์', 'Anthrax', 2, 30, 365, NULL, 'ในเขตระบาดฉีดซ้ำทุก 6 เดือน'),
  ('LSD', 'ลัมปี สกิน', 'Lumpy Skin Disease', 2, 30, 180, NULL, NULL);
