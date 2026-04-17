-- 1. Resolve Admin Performance RPC Ambiguity
-- Drop the overloaded function with arguments since the app calls the one without arguments.
-- This fixes the PGRST203 error.
DROP FUNCTION IF EXISTS public.get_admin_performance(text);

-- 2. Create Updating Function for Freshness
-- This function ensures that the 'updated_at' column is always set to NOW() on update.
-- This will trigger the app's freshness check and force a re-download of modified files.
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 3. Add Triggers to Resources Table
DROP TRIGGER IF EXISTS set_updated_at ON public.resources;
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON public.resources
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- 4. Add Triggers to Mock Tests Table
DROP TRIGGER IF EXISTS set_updated_at ON public.mock_tests;
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON public.mock_tests
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Note: After running this, updating any row in these tables (e.g., via Dashboard) 
-- will automatically update 'updated_at', and users will see the "New File" 
-- indicator or be forced to re-download if they had an old version.
