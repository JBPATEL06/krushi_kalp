-- ==============================================================================
-- KRUSHI KALP: SERVER-SIDE DISPLAY PRICING (Store UI + Checkout)
-- Replaces the hardcoded client-side PriceCalculator Dart class.
-- Returns final_price, mrp_display (strikethrough), and discount_label for UI.
-- Deploy in Supabase SQL Editor.
-- ==============================================================================

CREATE OR REPLACE FUNCTION calculate_display_price(
  p_item_type   TEXT,         -- 'mock_test' or 'resource'
  p_item_id     BIGINT,
  p_user_id     UUID DEFAULT NULL,
  p_coupon_code TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_base_price    DECIMAL;
  v_final_price   DECIMAL;
  v_mrp_display   DECIMAL;   -- Strikethrough price shown to user
  v_discount      DECIMAL := 0;
  v_offer         RECORD;
  v_discount_label TEXT := NULL;
BEGIN
  -- 1. Fetch base price
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
    RAISE EXCEPTION 'Item not found or inactive: % id=%', p_item_type, p_item_id;
  END IF;

  v_final_price  := v_base_price;
  v_mrp_display  := v_base_price;

  -- 2a. Check for active REAL Sale offers (is_sale=true, is_real=true)
  --     These reduce the selling price. Best offer wins.
  SELECT offer_id, discount_type, discount_value, max_discount, min_order_value
  INTO v_offer
  FROM offers
  WHERE is_active = true
    AND is_real   = true
    AND is_sale   = true
    AND (
      target_type = 'ALL'
      OR (p_item_type = 'mock_test' AND target_type = 'TEST')
      OR (p_item_type = 'resource'  AND target_type IN ('RESOURCE','EBOOK','MATERIAL'))
    )
    AND start_date <= NOW()
    AND end_date   >= NOW()
  ORDER BY discount_value DESC
  LIMIT 1;

  IF FOUND AND v_base_price >= COALESCE(v_offer.min_order_value, 0) THEN
    IF v_offer.discount_type = 'PERCENTAGE' THEN
      v_discount := (v_base_price * v_offer.discount_value) / 100.0;
    ELSE
      v_discount := v_offer.discount_value;
    END IF;
    IF v_offer.max_discount IS NOT NULL AND v_discount > v_offer.max_discount THEN
      v_discount := v_offer.max_discount;
    END IF;
    v_final_price  := v_base_price - v_discount;
    v_mrp_display  := v_base_price;  -- Original price is the strikethrough

    IF v_offer.discount_type = 'PERCENTAGE' THEN
      v_discount_label := v_offer.discount_value::int || '% OFF';
    ELSE
      v_discount_label := '₹' || v_offer.discount_value::int || ' OFF';
    END IF;

  -- 2b. Check for FAKE Sale offers (is_sale=true, is_real=false)
  --     These inflate the MRP display to create perceived discount.
  ELSE
    SELECT offer_id, discount_type, discount_value, min_order_value
    INTO v_offer
    FROM offers
    WHERE is_active = true
      AND is_real   = false
      AND is_sale   = true
      AND (
        target_type = 'ALL'
        OR (p_item_type = 'mock_test' AND target_type = 'TEST')
        OR (p_item_type = 'resource'  AND target_type IN ('RESOURCE','EBOOK','MATERIAL'))
      )
      AND start_date <= NOW()
      AND end_date   >= NOW()
    ORDER BY discount_value DESC
    LIMIT 1;

    IF FOUND AND v_base_price >= COALESCE(v_offer.min_order_value, 0) THEN
      -- Inflate MRP, keep selling price at base
      IF v_offer.discount_type = 'PERCENTAGE' THEN
        DECLARE rate DECIMAL := v_offer.discount_value / 100.0;
        BEGIN
          IF rate >= 1 THEN rate := 0.99; END IF;
          v_mrp_display := v_base_price / (1 - rate);
        END;
      ELSE
        v_mrp_display := v_base_price + v_offer.discount_value;
      END IF;

      -- Discount label is the implied percentage
      IF v_mrp_display > 0 THEN
        v_discount_label := ROUND(((v_mrp_display - v_base_price) / v_mrp_display) * 100)::int || '% OFF';
      END IF;

    -- 2c. No active sale — check coupon if provided
    ELSIF p_coupon_code IS NOT NULL AND p_coupon_code != '' THEN
      SELECT offer_id, discount_type, discount_value, max_discount, min_order_value
      INTO v_offer
      FROM offers
      WHERE code      = UPPER(p_coupon_code)
        AND is_active = true
        AND is_real   = true
        AND is_sale   = false
        AND start_date <= NOW()
        AND end_date   >= NOW();

      IF FOUND AND v_base_price >= COALESCE(v_offer.min_order_value, 0) THEN
        IF v_offer.discount_type = 'PERCENTAGE' THEN
          v_discount := (v_base_price * v_offer.discount_value) / 100.0;
        ELSE
          v_discount := v_offer.discount_value;
        END IF;
        IF v_offer.max_discount IS NOT NULL AND v_discount > v_offer.max_discount THEN
          v_discount := v_offer.max_discount;
        END IF;
        v_final_price  := v_base_price - v_discount;
        v_mrp_display  := v_base_price;

        IF v_offer.discount_type = 'PERCENTAGE' THEN
          v_discount_label := v_offer.discount_value::int || '% OFF';
        ELSE
          v_discount_label := '₹' || v_offer.discount_value::int || ' OFF';
        END IF;
      END IF;
    END IF;
  END IF;

  IF v_final_price < 0 THEN v_final_price := 0; END IF;

  RETURN jsonb_build_object(
    'base_price',      v_base_price,
    'final_price',     v_final_price,
    'mrp_display',     ROUND(v_mrp_display::numeric, 0),
    'discount_label',  v_discount_label,
    'has_discount',    (v_final_price < v_mrp_display)
  );
END;
$$;

-- Grant execute to authenticated and anon roles
GRANT EXECUTE ON FUNCTION calculate_display_price(TEXT, BIGINT, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_display_price(TEXT, BIGINT, UUID, TEXT) TO anon;
