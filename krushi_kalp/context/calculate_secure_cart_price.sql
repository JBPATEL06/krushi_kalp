-- ==============================================================================
-- KRUSHI KALP: SECURE SERVER-SIDE CART PRICING
-- Schema-verified against actual Supabase table definitions.
-- Deploy in Supabase SQL Editor.
-- ==============================================================================

CREATE OR REPLACE FUNCTION calculate_secure_cart_price(
  p_order_id UUID,
  p_user_id UUID,
  p_coupon_code TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_base_total      DECIMAL := 0;
  v_discount_total  DECIMAL := 0;
  v_final_total     DECIMAL := 0;
  v_has_auto_sale   BOOLEAN := FALSE;

  v_item            RECORD;
  v_item_price      DECIMAL;
  v_item_discount   DECIMAL := 0;
  v_item_type       TEXT;

  v_best_sale       RECORD;
  v_coupon          RECORD;
  v_global_discount DECIMAL := 0;
BEGIN
  -- 1. Verify order belongs to user and is PENDING
  IF NOT EXISTS (
    SELECT 1 FROM orders
    WHERE order_id = p_order_id
      AND user_id = p_user_id
      AND status = 'PENDING'
  ) THEN
    RAISE EXCEPTION 'Pending cart order not found or unauthorized';
  END IF;

  -- 2. Loop through all items in this order
  FOR v_item IN
    SELECT test_id, resource_id
    FROM order_items
    WHERE order_id = p_order_id
  LOOP
    v_item_price    := NULL;
    v_item_discount := 0;
    v_item_type     := NULL;

    -- Fetch price from correct table using correct PK
    IF v_item.test_id IS NOT NULL THEN
      SELECT price INTO v_item_price
      FROM mock_tests
      WHERE test_id = v_item.test_id AND is_active = true;
      v_item_type := 'mock_test';

    ELSIF v_item.resource_id IS NOT NULL THEN
      SELECT price INTO v_item_price
      FROM resources
      WHERE id = v_item.resource_id AND is_active = true;
      v_item_type := 'resource';
    END IF;

    CONTINUE WHEN v_item_price IS NULL;

    v_base_total := v_base_total + v_item_price;

    -- Per-item auto-sale check
    -- target_type: ALL applies to all; TEST applies only to mock_tests
    SELECT offer_id, discount_type, discount_value, max_discount, min_order_value
    INTO v_best_sale
    FROM offers
    WHERE is_active = true
      AND is_real = true
      AND is_sale = true
      AND (
        target_type = 'ALL'
        OR (v_item_type = 'mock_test' AND target_type = 'TEST')
      )
      AND start_date <= NOW()
      AND end_date >= NOW()
    ORDER BY discount_value DESC
    LIMIT 1;

    IF FOUND THEN
      v_has_auto_sale := TRUE;
      IF v_item_price >= COALESCE(v_best_sale.min_order_value, 0) THEN
        IF v_best_sale.discount_type = 'PERCENTAGE' THEN
          v_item_discount := (v_item_price * v_best_sale.discount_value) / 100.0;
        ELSE
          v_item_discount := v_best_sale.discount_value;
        END IF;
        IF v_best_sale.max_discount IS NOT NULL AND v_item_discount > v_best_sale.max_discount THEN
          v_item_discount := v_best_sale.max_discount;
        END IF;
      END IF;
    END IF;

    v_discount_total := v_discount_total + v_item_discount;
  END LOOP;

  -- 3. Subtotal after per-item sales
  v_final_total := v_base_total - v_discount_total;

  -- 4. Apply global coupon if no auto-sale is active
  IF NOT v_has_auto_sale AND p_coupon_code IS NOT NULL AND p_coupon_code != '' THEN
    SELECT offer_id, discount_type, discount_value, max_discount, min_order_value
    INTO v_coupon
    FROM offers
    WHERE code = p_coupon_code
      AND is_active = true
      AND is_real = true
      AND is_sale = false
      AND start_date <= NOW()
      AND end_date >= NOW();

    IF FOUND AND v_final_total >= COALESCE(v_coupon.min_order_value, 0) THEN
      IF v_coupon.discount_type = 'PERCENTAGE' THEN
        v_global_discount := (v_final_total * v_coupon.discount_value) / 100.0;
      ELSE
        v_global_discount := v_coupon.discount_value;
      END IF;
      IF v_coupon.max_discount IS NOT NULL AND v_global_discount > v_coupon.max_discount THEN
        v_global_discount := v_coupon.max_discount;
      END IF;
      v_discount_total := v_discount_total + v_global_discount;
      v_final_total    := v_final_total - v_global_discount;
    END IF;
  END IF;

  IF v_final_total < 0 THEN v_final_total := 0; END IF;

  RETURN jsonb_build_object(
    'base_total',       v_base_total,
    'final_total',      v_final_total,
    'discount_applied', v_discount_total
  );
END;
$$;
