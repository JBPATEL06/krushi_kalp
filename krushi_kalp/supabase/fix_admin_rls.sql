-- [ADMIN RLS FIX]
-- Enable full access for administrative actions on resources and banners

-- 1. Resources Table
-- Ensure RLS is enabled
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they conflict (standardizing)
DROP POLICY IF EXISTS "Enable all access for admin on resources" ON resources;
DROP POLICY IF EXISTS "Enable read access for all users" ON resources;

-- Allow all users to read active resources
CREATE POLICY "Enable read access for all users" ON resources
FOR SELECT USING (true);

-- Allow authenticated users with admin claims (or specifically identified roles) to manage
-- For testing/initial setup, we allow authenticated users to perform DML on resources.
-- In a locked-down env, you'd check auth.jwt() -> 'role' or a custom claim.
CREATE POLICY "Enable all access for admin on resources" ON resources
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);


-- 2. Banners Table
-- Ensure RLS is enabled
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Enable all access for admin on banners" ON banners;
DROP POLICY IF EXISTS "Enable read access for all users on banners" ON banners;

-- Allow all users to read banners
CREATE POLICY "Enable read access for all users on banners" ON banners
FOR SELECT USING (true);

-- Allow authenticated users to manage banners
CREATE POLICY "Enable all access for admin on banners" ON banners
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 3. Storage Policies (Standardizing access for admin)

-- Policy for 'mock_test' bucket (Resources)
DROP POLICY IF EXISTS "Allow authenticated to upload to mock_test" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated to update in mock_test" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated to delete from mock_test" ON storage.objects;

CREATE POLICY "Allow authenticated to upload to mock_test" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'mock_test');
CREATE POLICY "Allow authenticated to update in mock_test" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'mock_test');
CREATE POLICY "Allow authenticated to delete from mock_test" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'mock_test');

-- Policy for 'banners' bucket (Home Banners)
DROP POLICY IF EXISTS "Allow authenticated to upload to banners" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated to update in banners" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated to delete from banners" ON storage.objects;

CREATE POLICY "Allow authenticated to upload to banners" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'banners');
CREATE POLICY "Allow authenticated to update in banners" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'banners');
CREATE POLICY "Allow authenticated to delete from banners" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'banners');
