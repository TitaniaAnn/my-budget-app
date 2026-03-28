-- ============================================================
-- Receipts storage bucket + RLS policies
-- Run in Supabase SQL Editor (or via supabase db push)
-- ============================================================

-- Create private bucket for receipt images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'receipts',
  'receipts',
  false,                  -- private: URLs require a signed token
  10485760,              -- 10 MB max per file
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
ON CONFLICT (id) DO NOTHING;

-- Authenticated household members may upload to their own household folder.
-- Path convention: receipts/{household_id}/{filename}
CREATE POLICY "household members can upload receipt images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'receipts'
    AND auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.household_members
      WHERE user_id = auth.uid()
        AND household_id::text = (string_to_array(name, '/'))[1]
    )
  );

-- Members can read images belonging to their household.
CREATE POLICY "household members can read receipt images"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'receipts'
    AND auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.household_members
      WHERE user_id = auth.uid()
        AND household_id::text = (string_to_array(name, '/'))[1]
    )
  );

-- Uploader or household owner can delete receipt images.
CREATE POLICY "uploader can delete receipt images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'receipts'
    AND auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.household_members
      WHERE user_id = auth.uid()
        AND household_id::text = (string_to_array(name, '/'))[1]
    )
  );
