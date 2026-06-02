-- RPC: complete_checkout_v1
-- Deployed: 2026-05-29
-- Fix: Changed ON CONFLICT DO NOTHING → ON CONFLICT DO UPDATE
-- Reason: Direct checkout users who previously abandoned a cart for the same item
--         had an access row with a different payment_id. The old DO NOTHING silently
--         skipped activation, leaving is_active = false after a real payment.

CREATE OR REPLACE FUNCTION public.complete_checkout_v1(
  p_order_id          uuid,
  p_gateway_payment_id text,
  p_amount            numeric,
  p_offer_id          bigint  DEFAULT NULL,
  p_discount_amount   numeric DEFAULT 0,
  p_user_id           uuid    DEFAULT NULL,
  p_gateway           text    DEFAULT 'Razorpay'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_payment       RECORD;
  v_offer_code    text;
  v_item_type     text;
  v_item_id       bigint;
  v_item_snapshot jsonb;
BEGIN
  -- 1. Fetch and lock payment record
  SELECT * INTO v_payment
  FROM public.payment
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'Payment record not found.');
  END IF;

  -- 2. Prevent double-processing
  IF v_payment.status = 'SUCCESS' THEN
    RETURN jsonb_build_object('success', true, 'message', 'Already completed.');
  END IF;

  -- 3. Resolve offer code
  IF p_offer_id IS NOT NULL THEN
    SELECT code INTO v_offer_code
    FROM public.offers
    WHERE offer_id = p_offer_id;
  END IF;

  -- 4. Update payment to SUCCESS
  UPDATE public.payment
  SET
    status             = 'SUCCESS',
    gateway_payment_id = p_gateway_payment_id,
    gateway            = p_gateway,
    offer_code         = v_offer_code,
    amount             = p_amount,
    discount_amount    = p_discount_amount,
    updated_at         = NOW()
  WHERE id = p_order_id;

  -- 5. Handle Cart Items (activate existing access rows linked to this payment)
  UPDATE public.access
  SET
    is_active   = true,
    granted_at  = NOW(),
    access_type = 'paid'
  WHERE payment_id = p_order_id;

  -- 6. Handle Direct Items (read from metadata, insert or activate existing row)
  v_item_type     := v_payment.metadata->>'item_type';
  v_item_id       := (v_payment.metadata->>'item_id')::bigint;
  v_item_snapshot := v_payment.metadata->'item_snapshot';

  IF v_item_type IS NOT NULL AND v_item_id IS NOT NULL THEN
    -- If snapshot is missing or empty, fetch live from DB
    IF v_item_snapshot IS NULL OR v_item_snapshot = '{}'::jsonb THEN
      IF v_item_type = 'test' THEN
        SELECT row_to_json(t)::jsonb INTO v_item_snapshot
        FROM public.mock_tests t WHERE t.test_id = v_item_id;
      ELSIF v_item_type = 'resource' THEN
        SELECT row_to_json(r)::jsonb INTO v_item_snapshot
        FROM public.resources r WHERE r.id = v_item_id;
      END IF;
    END IF;

    -- FIX: Use DO UPDATE instead of DO NOTHING.
    -- If a row already exists (e.g. from an abandoned cart with a different payment_id),
    -- activate it and link it to this successful payment instead of silently skipping.
    INSERT INTO public.access (
      user_id, payment_id, item_type, item_id,
      item_snapshot, price_paid, granted_at, is_active, access_type
    )
    VALUES (
      v_payment.user_id, p_order_id, v_item_type, v_item_id,
      COALESCE(v_item_snapshot, '{}'::jsonb), p_amount, NOW(), true, 'paid'
    )
    ON CONFLICT (user_id, item_type, item_id)
    DO UPDATE SET
      is_active   = true,
      access_type = 'paid',
      payment_id  = p_order_id,
      price_paid  = p_amount,
      granted_at  = NOW();
  END IF;

  RETURN jsonb_build_object('success', true, 'message', 'Checkout complete. Access granted.');

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'message', SQLERRM);
END;
$function$;
