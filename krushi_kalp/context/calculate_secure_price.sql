-- ==============================================================================
-- KRUSHI KALP: SECURE SERVER-SIDE PRICING
-- Schema-verified against actual Supabase table definitions.
-- Deploy in Supabase SQL Editor.
-- ==============================================================================

CREATE OR REPLACE FUNCTION calculate_secure_price(
  p_item_type TEXT,       -- 'mock_test' or 'resource'
  p_item_id BIGINT,
  p_user_id UUID,
  p_coupon_code TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_base_price DECIMAL;
  v_final_price DECIMAL;
  v_discount DECIMAL := 0;
  v_offer_id BIGINT := NULL;
  v_offer RECORD;
BEGIN
  -- 1. Fetch base price using correct PKs (no mrp column on either table)
  IF p_item_type = 'mock_test' THEN
    SELECT price INTO v_base_price
    FROM mock_tests
    WHERE test_id = p_item_id AND is_active = true;

  ELSIF p_item_type = 'resource' THEN
    SELECT price INTO v_base_price
    FROM resources
    WHERE id = p_item_id AND is_active = true;

  ELSE
    RAISE EXCEPTION 'Invalid item type: %', p_item_type;
  END IF;

  IF v_base_price IS NULL THEN
    RAISE EXCEPTION 'Item not found or inactive';
  END IF;

  v_final_price := v_base_price;

  -- 2. Check for active Sale offers (is_sale = true, target_type ALL or TEST for mock_test)
  --    offers.target_type values: ALL, USER, TEST, BUNDLE
  SELECT offer_id, discount_type, discount_value, max_discount, min_order_value
  INTO v_offer
  FROM offers
  WHERE is_active = true
    AND is_real = true
    AND is_sale = true
    AND (
      target_type = 'ALL'
      OR (p_item_type = 'mock_test' AND target_type = 'TEST')
    )
    AND start_date <= NOW()
    AND end_date >= NOW()
  ORDER BY discount_value DESC
  LIMIT 1;

  IF FOUND THEN
    IF v_base_price >= COALESCE(v_offer.min_order_value, 0) THEN
      v_offer_id := v_offer.offer_id;
      IF v_offer.discount_type = 'PERCENTAGE' THEN
        v_discount := (v_base_price * v_offer.discount_value) / 100.0;
      ELSE
        v_discount := v_offer.discount_value;
      END IF;
      IF v_offer.max_discount IS NOT NULL AND v_discount > v_offer.max_discount THEN
        v_discount := v_offer.max_discount;
      END IF;
      v_final_price := v_base_price - v_discount;
    END IF;

  -- 3. No active sale — check coupon code
  ELSIF p_coupon_code IS NOT NULL AND p_coupon_code != '' THEN
    SELECT offer_id, discount_type, discount_value, max_discount, min_order_value
    INTO v_offer
    FROM offers
    WHERE code = p_coupon_code
      AND is_active = true
      AND is_real = true
      AND is_sale = false
      AND start_date <= NOW()
      AND end_date >= NOW();

    IF FOUND THEN
      IF v_base_price >= COALESCE(v_offer.min_order_value, 0) THEN
        v_offer_id := v_offer.offer_id;
        IF v_offer.discount_type = 'PERCENTAGE' THEN
          v_discount := (v_base_price * v_offer.discount_value) / 100.0;
        ELSE
          v_discount := v_offer.discount_value;
        END IF;
        IF v_offer.max_discount IS NOT NULL AND v_discount > v_offer.max_discount THEN
          v_discount := v_offer.max_discount;
        END IF;
        v_final_price := v_base_price - v_discount;
      END IF;
    END IF;
  END IF;

  IF v_final_price < 0 THEN v_final_price := 0; END IF;

  RETURN jsonb_build_object(
    'base_price',        v_base_price,
    'final_price',       v_final_price,
    'discount_applied',  v_discount,
    'applied_offer_id',  v_offer_id
  );
END;
$$;
