-- REFACTORED: update_user_streak function
-- Handles IST timezone and dynamic weekly history shifting.

CREATE OR REPLACE FUNCTION update_user_streak(
  p_user_id uuid,
  p_duration_seconds integer,
  p_activity_type text -- 'test_attempt' or 'resource_read'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_existing user_streaks%ROWTYPE;
  v_today date := (now() AT TIME ZONE 'Asia/Kolkata')::date;
  v_minutes integer := p_duration_seconds / 60;
  v_weekly jsonb;
  v_new_weekly jsonb;
  v_diff integer;
  v_should_trigger boolean := false;
BEGIN
  -- 1. Trigger Heuristic (Industry Standard: 5 mins reading or any Activity completion)
  IF p_activity_type = 'test_attempt' OR p_duration_seconds >= 300 THEN
    v_should_trigger := true;
  END IF;

  IF NOT v_should_trigger THEN
    RETURN;
  END IF;

  -- 2. Fetch existing record
  SELECT * INTO v_existing FROM user_streaks WHERE user_id = p_user_id;

  -- 3. Case A: New User (First time activity)
  IF NOT FOUND THEN
    v_new_weekly := jsonb_build_array(0, 0, 0, 0, 0, 0, v_minutes);
    INSERT INTO user_streaks (
      user_id, streak_count, last_active_date,
      longest_streak, weekly_study_minutes,
      total_study_minutes, updated_at
    ) VALUES (
      p_user_id, 1, v_today,
      1, v_new_weekly,
      v_minutes, now()
    );
    RETURN;
  END IF;

  v_diff := v_today - v_existing.last_active_date;
  v_weekly := v_existing.weekly_study_minutes;

  -- 4. Case B: Same Day Activity
  IF v_diff = 0 THEN
    -- Accumulate minutes at index 6 (today)
    v_new_weekly := jsonb_set(
      v_weekly,
      '{6}',
      to_jsonb(COALESCE((v_weekly->6)::int, 0) + v_minutes)
    );
    
    UPDATE user_streaks SET
      weekly_study_minutes = v_new_weekly,
      total_study_minutes = total_study_minutes + v_minutes,
      updated_at = now()
    WHERE user_id = p_user_id;

  -- 5. Case C: Consecutive Day Activity (Streak Add)
  ELSIF v_diff = 1 THEN
    -- Shift array by 1 and increment streak
    v_new_weekly := jsonb_build_array(
      v_weekly->1, v_weekly->2, v_weekly->3,
      v_weekly->4, v_weekly->5, v_weekly->6,
      to_jsonb(v_minutes)
    );
    
    UPDATE user_streaks SET
      streak_count = streak_count + 1,
      longest_streak = GREATEST(longest_streak, v_existing.streak_count + 1),
      last_active_date = v_today,
      weekly_study_minutes = v_new_weekly,
      total_study_minutes = total_study_minutes + v_minutes,
      updated_at = now()
    WHERE user_id = p_user_id;

  -- 6. Case D: Missed Days (Streak Reset but History Preserved)
  ELSIF v_diff > 1 AND v_diff < 7 THEN
    -- Reset streak to 1, but shift the array by v_diff instead of wiping it.
    -- This keeps the previous week's activity visible on the heatmap.
    CASE v_diff
      WHEN 2 THEN v_new_weekly := jsonb_build_array(v_weekly->2, v_weekly->3, v_weekly->4, v_weekly->5, v_weekly->6, 0, v_minutes);
      WHEN 3 THEN v_new_weekly := jsonb_build_array(v_weekly->3, v_weekly->4, v_weekly->5, v_weekly->6, 0, 0, v_minutes);
      WHEN 4 THEN v_new_weekly := jsonb_build_array(v_weekly->4, v_weekly->5, v_weekly->6, 0, 0, 0, v_minutes);
      WHEN 5 THEN v_new_weekly := jsonb_build_array(v_weekly->5, v_weekly->6, 0, 0, 0, 0, v_minutes);
      WHEN 6 THEN v_new_weekly := jsonb_build_array(v_weekly->6, 0, 0, 0, 0, 0, v_minutes);
    END CASE;

    UPDATE user_streaks SET
      streak_count = 1,
      last_active_date = v_today,
      weekly_study_minutes = v_new_weekly,
      total_study_minutes = total_study_minutes + v_minutes,
      updated_at = now()
    WHERE user_id = p_user_id;

  -- 7. Case E: Long Absence (Full Reset)
  ELSE
    v_new_weekly := jsonb_build_array(0, 0, 0, 0, 0, 0, v_minutes);
    
    UPDATE user_streaks SET
      streak_count = 1,
      last_active_date = v_today,
      weekly_study_minutes = v_new_weekly,
      total_study_minutes = total_study_minutes + v_minutes,
      updated_at = now()
    WHERE user_id = p_user_id;
  END IF;

END;
$$;
