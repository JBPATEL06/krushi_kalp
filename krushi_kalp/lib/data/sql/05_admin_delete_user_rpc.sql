-- RPC to delete a user and all their related data, including Supabase Auth (Google Auth)
-- This requires SECURITY DEFINER to have permissions to delete from auth.users
-- Run this in your Supabase SQL Editor

CREATE OR REPLACE FUNCTION admin_delete_user_data(target_user_id UUID)
RETURNS void AS $$
BEGIN
    -- 1. Delete related records in all tables (assuming no cascade)
    DELETE FROM public.results WHERE user_id = target_user_id;
    DELETE FROM public.order_items WHERE order_id IN (SELECT order_id FROM public.orders WHERE user_id = target_user_id);
    DELETE FROM public.orders WHERE user_id = target_user_id;
    DELETE FROM public.messages WHERE user_id = target_user_id;
    DELETE FROM public.notifications WHERE user_id = target_user_id;
    DELETE FROM public.reviews WHERE user_id = target_user_id;

    -- 2. Delete from public.users
    DELETE FROM public.users WHERE id = target_user_id;

    -- 3. Delete from auth.users
    -- This is the "hard delete" that forces Google to see it as a new login next time.
    DELETE FROM auth.users WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution to authenticated users (admin logic should be handled in Flutter, but you can also check role here)
GRANT EXECUTE ON FUNCTION admin_delete_user_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_delete_user_data(UUID) TO service_role;
