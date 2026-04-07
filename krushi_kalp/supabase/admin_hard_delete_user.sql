-- RPC: admin_hard_delete_user
-- Purpose: Allows an Administrator to permanently delete any user account (Google or Email).
-- Security: SECURITY DEFINER + Role Check.

CREATE OR REPLACE FUNCTION admin_hard_delete_user(target_user_id UUID)
RETURNS void AS $$
BEGIN
    -- Check if the current user is an Admin
    IF NOT EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() AND role = 'Admin'
    ) THEN
        RAISE EXCEPTION 'Access Denied: Only Administrators can perform hard deletes.';
    END IF;

    -- 1. Delete from public schema (FKs should handle cascade if configured)
    DELETE FROM public.users WHERE id = target_user_id;

    -- 2. Delete from auth schema (Requires SECURITY DEFINER)
    DELETE FROM auth.users WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
