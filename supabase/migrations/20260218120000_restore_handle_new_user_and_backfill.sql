/*
  # Restore handle_new_user trigger and backfill profiles

  Purpose
  - Recreate the automatic profile sync trigger that was dropped in an earlier migration
  - Backfill users_profile for any existing auth.users rows that lack a profile
  - Ensure auth.users.raw_user_meta_data has role/name so JWTs satisfy RLS checks
*/

-- Recreate handle_new_user with upsert semantics
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO users_profile (id, email, name, role, clinic_id, is_active, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'receptionist'),
    NULLIF(NEW.raw_user_meta_data->>'clinic_id', '')::uuid,
    COALESCE((NEW.raw_user_meta_data->>'is_active')::boolean, true),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    role = EXCLUDED.role,
    clinic_id = EXCLUDED.clinic_id,
    is_active = EXCLUDED.is_active,
    updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Backfill missing users_profile rows from existing auth.users
INSERT INTO users_profile (id, email, name, role, clinic_id, is_active, created_at, updated_at)
SELECT
  u.id,
  u.email,
  COALESCE(u.raw_user_meta_data->>'name', split_part(u.email, '@', 1)),
  COALESCE(u.raw_user_meta_data->>'role', 'receptionist'),
  NULLIF(u.raw_user_meta_data->>'clinic_id', '')::uuid,
  COALESCE((u.raw_user_meta_data->>'is_active')::boolean, true),
  now(),
  now()
FROM auth.users u
LEFT JOIN users_profile up ON up.id = u.id
WHERE up.id IS NULL;

-- Ensure auth.users metadata carries role/name so RLS checks using JWT pass
UPDATE auth.users u
SET raw_user_meta_data = COALESCE(u.raw_user_meta_data, '{}'::jsonb)
  || jsonb_build_object(
    'role', COALESCE(up.role, u.raw_user_meta_data->>'role', 'receptionist'),
    'name', COALESCE(u.raw_user_meta_data->>'name', up.name, split_part(u.email, '@', 1))
  )
FROM users_profile up
WHERE u.id = up.id
  AND (u.raw_user_meta_data->>'role') IS NULL;

-- Fallback: for any users still missing role after the join above
UPDATE auth.users u
SET raw_user_meta_data = COALESCE(u.raw_user_meta_data, '{}'::jsonb)
  || jsonb_build_object(
    'role', COALESCE(u.raw_user_meta_data->>'role', 'receptionist'),
    'name', COALESCE(u.raw_user_meta_data->>'name', split_part(u.email, '@', 1))
  )
WHERE (u.raw_user_meta_data->>'role') IS NULL;
