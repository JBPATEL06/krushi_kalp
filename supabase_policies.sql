-- Policy to allow users to delete their own cart items
-- Run this in your Supabase SQL Editor

CREATE POLICY "Users can delete their own order items"
ON "public"."order_items"
AS PERMISSIVE
FOR DELETE
TO public
USING (
  (SELECT auth.uid()) IN (
    SELECT orders.user_id
    FROM orders
    WHERE orders.order_id = order_items.order_id
  )
);
