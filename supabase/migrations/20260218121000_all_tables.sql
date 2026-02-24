/*
  # Consolidated Migration: All Tables and Policies
  This file combines every migration in chronological order so a single run recreates
  schema, RLS, helper functions, seeds, and admin users.
*/

-- ===== 20260217183031_create_dental_clinic_schema.sql =====
/*
  # Dental Clinic Management System - Complete Schema

  ## Overview
  This migration creates the full database schema for a dental clinic management system.

  ## New Tables

  ### users_profile
  - Extends Supabase auth.users with role and clinic assignment
  - Columns: id, name, email, role (admin/doctor/receptionist), clinic_id, avatar_url, is_active

  ### clinics
  - Clinic locations/branches
  - Columns: id, clinic_name, address, phone, email, created_at

  ### patients
  - Patient records with medical and dental history
  - Columns: id, name, age, gender, contact, email, address, medical_history, dental_history, notes, doctor_id, clinic_id, created_at

  ### patient_files
  - Uploaded files (images, PDFs) linked to patients
  - Columns: id, patient_id, file_url, file_type, file_name, uploaded_by, created_at

  ### appointments
  - Appointment scheduling
  - Columns: id, patient_id, doctor_id, clinic_id, appointment_date, appointment_time, status, notes, created_at

  ### medicines
  - Master medicine list
  - Columns: id, medicine_name, created_at

  ### prescriptions
  - Doctor prescriptions linked to patients
  - Columns: id, patient_id, doctor_id, treatments, medicines (jsonb), notes, created_at

  ### invoices
  - Billing/invoices
  - Columns: id, patient_id, clinic_id, doctor_id, items (jsonb), doctor_fee, total_amount, status, created_at

  ## Security
  - RLS enabled on all tables
  - Authenticated users can read all data (clinic staff)
  - Role-based write permissions enforced at application level
*/

-- CLINICS TABLE
CREATE TABLE IF NOT EXISTS clinics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_name text NOT NULL,
  address text DEFAULT '',
  phone text DEFAULT '',
  email text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE clinics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view clinics"
  ON clinics FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert clinics"
  ON clinics FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update clinics"
  ON clinics FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete clinics"
  ON clinics FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- USERS PROFILE TABLE
CREATE TABLE IF NOT EXISTS users_profile (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL DEFAULT '',
  email text NOT NULL DEFAULT '',
  role text NOT NULL DEFAULT 'receptionist' CHECK (role IN ('admin', 'doctor', 'receptionist')),
  clinic_id uuid REFERENCES clinics(id) ON DELETE SET NULL,
  avatar_url text DEFAULT '',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE users_profile ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view profiles"
  ON users_profile FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON users_profile FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update profiles"
  ON users_profile FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete profiles"
  ON users_profile FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- PATIENTS TABLE
CREATE TABLE IF NOT EXISTS patients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  age integer DEFAULT 0,
  gender text DEFAULT 'other' CHECK (gender IN ('male', 'female', 'other')),
  contact text DEFAULT '',
  email text DEFAULT '',
  address text DEFAULT '',
  medical_history text DEFAULT '',
  dental_history text DEFAULT '',
  notes text DEFAULT '',
  doctor_id uuid REFERENCES users_profile(id) ON DELETE SET NULL,
  clinic_id uuid REFERENCES clinics(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view patients"
  ON patients FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert patients"
  ON patients FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update patients"
  ON patients FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete patients"
  ON patients FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- PATIENT FILES TABLE
CREATE TABLE IF NOT EXISTS patient_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  file_url text NOT NULL,
  file_type text DEFAULT 'other',
  file_name text DEFAULT '',
  uploaded_by uuid REFERENCES users_profile(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE patient_files ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view patient files"
  ON patient_files FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert patient files"
  ON patient_files FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete patient files"
  ON patient_files FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- APPOINTMENTS TABLE
CREATE TABLE IF NOT EXISTS appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id uuid REFERENCES users_profile(id) ON DELETE SET NULL,
  clinic_id uuid REFERENCES clinics(id) ON DELETE SET NULL,
  appointment_date date NOT NULL,
  appointment_time time DEFAULT '09:00:00',
  status text DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'confirmed', 'completed', 'cancelled', 'no-show')),
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view appointments"
  ON appointments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert appointments"
  ON appointments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update appointments"
  ON appointments FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete appointments"
  ON appointments FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- MEDICINES TABLE
CREATE TABLE IF NOT EXISTS medicines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  medicine_name text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE medicines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view medicines"
  ON medicines FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert medicines"
  ON medicines FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update medicines"
  ON medicines FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete medicines"
  ON medicines FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- PRESCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS prescriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id uuid REFERENCES users_profile(id) ON DELETE SET NULL,
  treatments text DEFAULT '',
  medicines jsonb DEFAULT '[]'::jsonb,
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view prescriptions"
  ON prescriptions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert prescriptions"
  ON prescriptions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update prescriptions"
  ON prescriptions FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete prescriptions"
  ON prescriptions FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- INVOICES TABLE
CREATE TABLE IF NOT EXISTS invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  clinic_id uuid REFERENCES clinics(id) ON DELETE SET NULL,
  doctor_id uuid REFERENCES users_profile(id) ON DELETE SET NULL,
  items jsonb DEFAULT '[]'::jsonb,
  doctor_fee numeric DEFAULT 0,
  total_amount numeric DEFAULT 0,
  status text DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'paid', 'partial', 'cancelled')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view invoices"
  ON invoices FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert invoices"
  ON invoices FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update invoices"
  ON invoices FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete invoices"
  ON invoices FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_patients_doctor_id ON patients(doctor_id);
CREATE INDEX IF NOT EXISTS idx_patients_clinic_id ON patients(clinic_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_patient_id ON prescriptions(patient_id);
CREATE INDEX IF NOT EXISTS idx_invoices_patient_id ON invoices(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_files_patient_id ON patient_files(patient_id);

-- Function to auto-create user profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO users_profile (id, name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'receptionist')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Seed default medicines
INSERT INTO medicines (medicine_name) VALUES
  ('Amoxicillin'),
  ('Metronidazole'),
  ('Ibuprofen'),
  ('Paracetamol'),
  ('Clindamycin'),
  ('Diclofenac'),
  ('Omeprazole'),
  ('Chlorhexidine Mouthwash'),
  ('Benzocaine Gel'),
  ('Lidocaine')
ON CONFLICT (medicine_name) DO NOTHING;

-- Seed a default clinic
INSERT INTO clinics (clinic_name, address, phone, email) VALUES
  ('Dr Ali Dental Centre Dental Clinic', '123 Healthcare Boulevard, Medical District', '+1 (555) 123-4567', 'DrAliDentalCentre1@gmail.com')
ON CONFLICT DO NOTHING;

-- ===== 20260217192743_fix_users_profile_rls.sql =====
DROP POLICY IF EXISTS "Users can update profiles" ON public.users_profile;
DROP POLICY IF EXISTS "Authenticated users can delete profiles" ON public.users_profile;

CREATE POLICY "Admins can update any profile"
  ON public.users_profile
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users_profile up
      WHERE up.id = auth.uid() AND up.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users_profile up
      WHERE up.id = auth.uid() AND up.role = 'admin'
    )
  );

CREATE POLICY "Users can update own profile"
  ON public.users_profile
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can delete profiles"
  ON public.users_profile
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users_profile up
      WHERE up.id = auth.uid() AND up.role = 'admin'
    )
  );

-- ===== 20260217193717_rebuild_rls_clinic_scoped_and_storage.sql =====
CREATE OR REPLACE FUNCTION get_my_clinic_id()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT clinic_id FROM public.users_profile WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION get_my_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT role FROM public.users_profile WHERE id = auth.uid()
$$;

DROP POLICY IF EXISTS "Authenticated users can view clinics" ON clinics;
DROP POLICY IF EXISTS "Authenticated users can insert clinics" ON clinics;
DROP POLICY IF EXISTS "Authenticated users can update clinics" ON clinics;
DROP POLICY IF EXISTS "Authenticated users can delete clinics" ON clinics;

CREATE POLICY "clinics_select"
  ON clinics FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR id = get_my_clinic_id()
  );

CREATE POLICY "clinics_insert"
  ON clinics FOR INSERT TO authenticated
  WITH CHECK (get_my_role() = 'admin');

CREATE POLICY "clinics_update"
  ON clinics FOR UPDATE TO authenticated
  USING (get_my_role() = 'admin')
  WITH CHECK (get_my_role() = 'admin');

CREATE POLICY "clinics_delete"
  ON clinics FOR DELETE TO authenticated
  USING (get_my_role() = 'admin');

DROP POLICY IF EXISTS "Authenticated users can view profiles" ON users_profile;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users_profile;
DROP POLICY IF EXISTS "Users can update profiles" ON users_profile;
DROP POLICY IF EXISTS "Authenticated users can delete profiles" ON users_profile;
DROP POLICY IF EXISTS "Admins can update any profile" ON users_profile;
DROP POLICY IF EXISTS "Users can update own profile" ON users_profile;
DROP POLICY IF EXISTS "Admins can delete profiles" ON users_profile;

CREATE POLICY "users_profile_select"
  ON users_profile FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR id = auth.uid()
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "users_profile_insert"
  ON users_profile FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id OR get_my_role() = 'admin');

CREATE POLICY "users_profile_update"
  ON users_profile FOR UPDATE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR auth.uid() = id
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR auth.uid() = id
  );

CREATE POLICY "users_profile_delete"
  ON users_profile FOR DELETE TO authenticated
  USING (get_my_role() = 'admin');

DROP POLICY IF EXISTS "Authenticated users can view patients" ON patients;
DROP POLICY IF EXISTS "Authenticated users can insert patients" ON patients;
DROP POLICY IF EXISTS "Authenticated users can update patients" ON patients;
DROP POLICY IF EXISTS "Authenticated users can delete patients" ON patients;

CREATE POLICY "patients_select"
  ON patients FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "patients_insert"
  ON patients FOR INSERT TO authenticated
  WITH CHECK (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "patients_update"
  ON patients FOR UPDATE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (clinic_id = get_my_clinic_id() AND get_my_role() IN ('doctor', 'receptionist'))
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR (clinic_id = get_my_clinic_id() AND get_my_role() IN ('doctor', 'receptionist'))
  );

CREATE POLICY "patients_delete"
  ON patients FOR DELETE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (clinic_id = get_my_clinic_id() AND get_my_role() = 'doctor')
  );

DROP POLICY IF EXISTS "Authenticated users can view patient files" ON patient_files;
DROP POLICY IF EXISTS "Authenticated users can insert patient files" ON patient_files;
DROP POLICY IF EXISTS "Authenticated users can delete patient files" ON patient_files;

CREATE POLICY "patient_files_select"
  ON patient_files FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = patient_files.patient_id
      AND (p.clinic_id = get_my_clinic_id() OR get_my_role() = 'admin')
    )
  );

CREATE POLICY "patient_files_insert"
  ON patient_files FOR INSERT TO authenticated
  WITH CHECK (
    get_my_role() = 'admin'
    OR EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = patient_files.patient_id
      AND p.clinic_id = get_my_clinic_id()
    )
  );

CREATE POLICY "patient_files_delete"
  ON patient_files FOR DELETE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (
      uploaded_by = auth.uid()
      AND EXISTS (
        SELECT 1 FROM patients p
        WHERE p.id = patient_files.patient_id
        AND p.clinic_id = get_my_clinic_id()
      )
    )
  );

DROP POLICY IF EXISTS "Authenticated users can view appointments" ON appointments;
DROP POLICY IF EXISTS "Authenticated users can insert appointments" ON appointments;
DROP POLICY IF EXISTS "Authenticated users can update appointments" ON appointments;
DROP POLICY IF EXISTS "Authenticated users can delete appointments" ON appointments;

CREATE POLICY "appointments_select"
  ON appointments FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "appointments_insert"
  ON appointments FOR INSERT TO authenticated
  WITH CHECK (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "appointments_update"
  ON appointments FOR UPDATE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "appointments_delete"
  ON appointments FOR DELETE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (clinic_id = get_my_clinic_id() AND get_my_role() IN ('doctor', 'receptionist'))
  );

DROP POLICY IF EXISTS "Authenticated users can view medicines" ON medicines;
DROP POLICY IF EXISTS "Authenticated users can insert medicines" ON medicines;
DROP POLICY IF EXISTS "Authenticated users can update medicines" ON medicines;
DROP POLICY IF EXISTS "Authenticated users can delete medicines" ON medicines;

CREATE POLICY "medicines_select"
  ON medicines FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "medicines_insert"
  ON medicines FOR INSERT TO authenticated
  WITH CHECK (get_my_role() = 'admin');

CREATE POLICY "medicines_update"
  ON medicines FOR UPDATE TO authenticated
  USING (get_my_role() = 'admin')
  WITH CHECK (get_my_role() = 'admin');

CREATE POLICY "medicines_delete"
  ON medicines FOR DELETE TO authenticated
  USING (get_my_role() = 'admin');

DROP POLICY IF EXISTS "Authenticated users can view prescriptions" ON prescriptions;
DROP POLICY IF EXISTS "Authenticated users can insert prescriptions" ON prescriptions;
DROP POLICY IF EXISTS "Authenticated users can update prescriptions" ON prescriptions;
DROP POLICY IF EXISTS "Authenticated users can delete prescriptions" ON prescriptions;

CREATE POLICY "prescriptions_select"
  ON prescriptions FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = prescriptions.patient_id
      AND p.clinic_id = get_my_clinic_id()
    )
  );

CREATE POLICY "prescriptions_insert"
  ON prescriptions FOR INSERT TO authenticated
  WITH CHECK (
    get_my_role() = 'admin'
    OR (
      get_my_role() = 'doctor'
      AND EXISTS (
        SELECT 1 FROM patients p
        WHERE p.id = prescriptions.patient_id
        AND p.clinic_id = get_my_clinic_id()
      )
    )
  );

CREATE POLICY "prescriptions_update"
  ON prescriptions FOR UPDATE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (doctor_id = auth.uid() AND get_my_role() = 'doctor')
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR (doctor_id = auth.uid() AND get_my_role() = 'doctor')
  );

CREATE POLICY "prescriptions_delete"
  ON prescriptions FOR DELETE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (doctor_id = auth.uid() AND get_my_role() = 'doctor')
  );

DROP POLICY IF EXISTS "Authenticated users can view invoices" ON invoices;
DROP POLICY IF EXISTS "Authenticated users can insert invoices" ON invoices;
DROP POLICY IF EXISTS "Authenticated users can update invoices" ON invoices;
DROP POLICY IF EXISTS "Authenticated users can delete invoices" ON invoices;

CREATE POLICY "invoices_select"
  ON invoices FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "invoices_insert"
  ON invoices FOR INSERT TO authenticated
  WITH CHECK (
    get_my_role() = 'admin'
    OR (clinic_id = get_my_clinic_id() AND get_my_role() IN ('doctor', 'receptionist'))
  );

CREATE POLICY "invoices_update"
  ON invoices FOR UPDATE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "invoices_delete"
  ON invoices FOR DELETE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (clinic_id = get_my_clinic_id() AND get_my_role() = 'doctor')
  );

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'patient-files',
  'patient-files',
  false,
  52428800,
  ARRAY['image/jpeg','image/png','image/gif','image/webp','application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = 52428800,
  allowed_mime_types = ARRAY['image/jpeg','image/png','image/gif','image/webp','application/pdf'];

DROP POLICY IF EXISTS "patient_files_storage_select" ON storage.objects;
DROP POLICY IF EXISTS "patient_files_storage_insert" ON storage.objects;
DROP POLICY IF EXISTS "patient_files_storage_delete" ON storage.objects;

CREATE POLICY "patient_files_storage_select"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'patient-files');

CREATE POLICY "patient_files_storage_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'patient-files' AND auth.uid() IS NOT NULL);

CREATE POLICY "patient_files_storage_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'patient-files' AND auth.uid() IS NOT NULL);

-- ===== 20260217194937_make_patient_files_bucket_public.sql =====
UPDATE storage.buckets
SET public = true
WHERE id = 'patient-files';

-- ===== 20260217195520_add_prescription_dates.sql =====
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'prescriptions' AND column_name = 'start_date'
  ) THEN
    ALTER TABLE prescriptions ADD COLUMN start_date date;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'prescriptions' AND column_name = 'end_date'
  ) THEN
    ALTER TABLE prescriptions ADD COLUMN end_date date;
  END IF;
END $$;

-- ===== 20260217200657_add_amount_paid_to_invoices.sql =====
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'invoices' AND column_name = 'amount_paid'
  ) THEN
    ALTER TABLE invoices ADD COLUMN amount_paid numeric NOT NULL DEFAULT 0;
  END IF;
END $$;

-- ===== 20260217202051_add_structured_medicine_fields.sql =====
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'medicines' AND column_name = 'medicine_type'
  ) THEN
    ALTER TABLE medicines ADD COLUMN medicine_type text DEFAULT '';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'medicines' AND column_name = 'strength'
  ) THEN
    ALTER TABLE medicines ADD COLUMN strength text DEFAULT '';
  END IF;
END $$;

-- ===== 20260217202705_create_dental_services_table.sql =====
CREATE TABLE IF NOT EXISTS dental_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name text NOT NULL,
  category text NOT NULL DEFAULT '',
  default_price numeric(12,2) NOT NULL DEFAULT 0,
  description text NOT NULL DEFAULT '',
  is_active boolean NOT NULL DEFAULT true,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE dental_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read active services"
  ON dental_services FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "Admins can insert services"
  ON dental_services FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users_profile
      WHERE users_profile.id = auth.uid() AND users_profile.role = 'admin'
    )
  );

CREATE POLICY "Admins can update services"
  ON dental_services FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profile
      WHERE users_profile.id = auth.uid() AND users_profile.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users_profile
      WHERE users_profile.id = auth.uid() AND users_profile.role = 'admin'
    )
  );

CREATE POLICY "Admins can delete services"
  ON dental_services FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profile
      WHERE users_profile.id = auth.uid() AND users_profile.role = 'admin'
    )
  );

INSERT INTO dental_services (service_name, category, default_price, sort_order) VALUES
  ('Consultation / Checkup', 'General Treatments', 500, 1),
  ('Oral Examination', 'General Treatments', 500, 2),
  ('Dental Cleaning (Scaling and Polishing)', 'General Treatments', 2500, 3),
  ('Deep Cleaning (Root Planing and Scaling)', 'General Treatments', 5000, 4),
  ('Fluoride Treatment', 'General Treatments', 1500, 5),
  ('Dental X-Ray', 'General Treatments', 1000, 6),
  ('Emergency Treatment', 'General Treatments', 3000, 7),
  ('Tooth Filling (Composite)', 'Restorative Treatments', 4000, 1),
  ('Tooth Filling (Amalgam)', 'Restorative Treatments', 2500, 2),
  ('Root Canal Treatment (RCT)', 'Restorative Treatments', 12000, 3),
  ('Re-Root Canal Treatment', 'Restorative Treatments', 15000, 4),
  ('Crown Placement', 'Restorative Treatments', 18000, 5),
  ('Bridge Placement', 'Restorative Treatments', 25000, 6),
  ('Core Build-Up', 'Restorative Treatments', 5000, 7),
  ('Teeth Whitening', 'Cosmetic Treatments', 15000, 1),
  ('Smile Design', 'Cosmetic Treatments', 50000, 2),
  ('Veneers', 'Cosmetic Treatments', 20000, 3),
  ('Composite Bonding', 'Cosmetic Treatments', 8000, 4),
  ('Cosmetic Contouring', 'Cosmetic Treatments', 5000, 5),
  ('Tooth Reshaping', 'Cosmetic Treatments', 4000, 6),
  ('Braces Consultation', 'Orthodontic Treatments', 1000, 1),
  ('Metal Braces', 'Orthodontic Treatments', 60000, 2),
  ('Ceramic Braces', 'Orthodontic Treatments', 80000, 3),
  ('Clear Aligners', 'Orthodontic Treatments', 120000, 4),
  ('Retainers', 'Orthodontic Treatments', 10000, 5),
  ('Tooth Extraction', 'Oral Surgery', 2000, 1),
  ('Surgical Extraction', 'Oral Surgery', 5000, 2),
  ('Wisdom Tooth Removal', 'Oral Surgery', 8000, 3),
  ('Minor Oral Surgery', 'Oral Surgery', 10000, 4),
  ('Incision and Drainage', 'Oral Surgery', 3000, 5),
  ('Implant Placement', 'Implant Procedures', 80000, 1),
  ('Implant Crown', 'Implant Procedures', 25000, 2),
  ('Bone Grafting', 'Implant Procedures', 30000, 3),
  ('Sinus Lift', 'Implant Procedures', 40000, 4),
  ('Complete Denture', 'Prosthetic Treatments', 30000, 1),
  ('Partial Denture', 'Prosthetic Treatments', 15000, 2),
  ('Denture Repair', 'Prosthetic Treatments', 3000, 3),
  ('Denture Relining', 'Prosthetic Treatments', 5000, 4),
  ('Child Consultation', 'Children Treatments', 500, 1),
  ('Child Cleaning', 'Children Treatments', 1500, 2),
  ('Space Maintainer', 'Children Treatments', 5000, 3),
  ('Fluoride Application', 'Children Treatments', 1000, 4),
  ('Gum Therapy', 'Gum Treatments', 4000, 1),
  ('Periodontal Treatment', 'Gum Treatments', 8000, 2),
  ('Gum Surgery', 'Gum Treatments', 15000, 3),
  ('Root Canal Therapy', 'Root Canal Procedures', 12000, 1),
  ('Pulp Capping', 'Root Canal Procedures', 3000, 2)
ON CONFLICT DO NOTHING;

-- ===== 20260217205223_add_clinic_admin_role_and_clinic_service_prices.sql =====
ALTER TABLE users_profile
  DROP CONSTRAINT IF EXISTS users_profile_role_check;

ALTER TABLE users_profile
  ADD CONSTRAINT users_profile_role_check
  CHECK (role IN ('admin', 'clinic_admin', 'doctor', 'receptionist'));

CREATE TABLE IF NOT EXISTS clinic_service_prices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  service_id uuid NOT NULL REFERENCES dental_services(id) ON DELETE CASCADE,
  price numeric NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE (clinic_id, service_id)
);

ALTER TABLE clinic_service_prices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "csp_select"
  ON clinic_service_prices FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "csp_insert"
  ON clinic_service_prices FOR INSERT TO authenticated
  WITH CHECK (
    get_my_role() = 'admin'
    OR (get_my_role() = 'clinic_admin' AND clinic_id = get_my_clinic_id())
  );

CREATE POLICY "csp_update"
  ON clinic_service_prices FOR UPDATE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (get_my_role() = 'clinic_admin' AND clinic_id = get_my_clinic_id())
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR (get_my_role() = 'clinic_admin' AND clinic_id = get_my_clinic_id())
  );

CREATE POLICY "csp_delete"
  ON clinic_service_prices FOR DELETE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (get_my_role() = 'clinic_admin' AND clinic_id = get_my_clinic_id())
  );

CREATE INDEX IF NOT EXISTS idx_clinic_service_prices_clinic_id ON clinic_service_prices(clinic_id);
CREATE INDEX IF NOT EXISTS idx_clinic_service_prices_service_id ON clinic_service_prices(service_id);

DROP POLICY IF EXISTS "clinics_select" ON clinics;
DROP POLICY IF EXISTS "clinics_insert" ON clinics;
DROP POLICY IF EXISTS "clinics_update" ON clinics;
DROP POLICY IF EXISTS "clinics_delete" ON clinics;

CREATE POLICY "clinics_select"
  ON clinics FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR id = get_my_clinic_id()
  );

CREATE POLICY "clinics_insert"
  ON clinics FOR INSERT TO authenticated
  WITH CHECK (get_my_role() = 'admin');

CREATE POLICY "clinics_update"
  ON clinics FOR UPDATE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (get_my_role() = 'clinic_admin' AND id = get_my_clinic_id())
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR (get_my_role() = 'clinic_admin' AND id = get_my_clinic_id())
  );

CREATE POLICY "clinics_delete"
  ON clinics FOR DELETE TO authenticated
  USING (get_my_role() = 'admin');

DROP POLICY IF EXISTS "users_profile_select" ON users_profile;
DROP POLICY IF EXISTS "users_profile_insert" ON users_profile;
DROP POLICY IF EXISTS "users_profile_update" ON users_profile;
DROP POLICY IF EXISTS "users_profile_delete" ON users_profile;

CREATE POLICY "users_profile_select"
  ON users_profile FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR id = auth.uid()
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "users_profile_insert"
  ON users_profile FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = id
    OR get_my_role() = 'admin'
    OR (get_my_role() = 'clinic_admin' AND clinic_id = get_my_clinic_id())
  );

CREATE POLICY "users_profile_update"
  ON users_profile FOR UPDATE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR auth.uid() = id
    OR (get_my_role() = 'clinic_admin' AND clinic_id = get_my_clinic_id())
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR auth.uid() = id
    OR (get_my_role() = 'clinic_admin' AND clinic_id = get_my_clinic_id())
  );

CREATE POLICY "users_profile_delete"
  ON users_profile FOR DELETE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (get_my_role() = 'clinic_admin' AND clinic_id = get_my_clinic_id() AND id != auth.uid())
  );

DROP POLICY IF EXISTS "patients_select" ON patients;
DROP POLICY IF EXISTS "patients_insert" ON patients;
DROP POLICY IF EXISTS "patients_update" ON patients;
DROP POLICY IF EXISTS "patients_delete" ON patients;

CREATE POLICY "patients_select"
  ON patients FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "patients_insert"
  ON patients FOR INSERT TO authenticated
  WITH CHECK (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "patients_update"
  ON patients FOR UPDATE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "patients_delete"
  ON patients FOR DELETE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (clinic_id = get_my_clinic_id() AND get_my_role() IN ('clinic_admin', 'doctor'))
  );

DROP POLICY IF EXISTS "patient_files_select" ON patient_files;
DROP POLICY IF EXISTS "patient_files_insert" ON patient_files;
DROP POLICY IF EXISTS "patient_files_delete" ON patient_files;

CREATE POLICY "patient_files_select"
  ON patient_files FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = patient_files.patient_id
      AND p.clinic_id = get_my_clinic_id()
    )
  );

CREATE POLICY "patient_files_insert"
  ON patient_files FOR INSERT TO authenticated
  WITH CHECK (
    get_my_role() = 'admin'
    OR EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = patient_files.patient_id
      AND p.clinic_id = get_my_clinic_id()
    )
  );

CREATE POLICY "patient_files_delete"
  ON patient_files FOR DELETE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR get_my_role() = 'clinic_admin'
    OR (
      uploaded_by = auth.uid()
      AND EXISTS (
        SELECT 1 FROM patients p
        WHERE p.id = patient_files.patient_id
        AND p.clinic_id = get_my_clinic_id()
      )
    )
  );

DROP POLICY IF EXISTS "appointments_select" ON appointments;
DROP POLICY IF EXISTS "appointments_insert" ON appointments;
DROP POLICY IF EXISTS "appointments_update" ON appointments;
DROP POLICY IF EXISTS "appointments_delete" ON appointments;

CREATE POLICY "appointments_select"
  ON appointments FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "appointments_insert"
  ON appointments FOR INSERT TO authenticated
  WITH CHECK (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "appointments_update"
  ON appointments FOR UPDATE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "appointments_delete"
  ON appointments FOR DELETE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

DROP POLICY IF EXISTS "medicines_select" ON medicines;
DROP POLICY IF EXISTS "medicines_insert" ON medicines;
DROP POLICY IF EXISTS "medicines_update" ON medicines;
DROP POLICY IF EXISTS "medicines_delete" ON medicines;

CREATE POLICY "medicines_select"
  ON medicines FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "medicines_insert"
  ON medicines FOR INSERT TO authenticated
  WITH CHECK (get_my_role() IN ('admin', 'clinic_admin', 'doctor'));

CREATE POLICY "medicines_update"
  ON medicines FOR UPDATE TO authenticated
  USING (get_my_role() IN ('admin', 'clinic_admin'))
  WITH CHECK (get_my_role() IN ('admin', 'clinic_admin'));

CREATE POLICY "medicines_delete"
  ON medicines FOR DELETE TO authenticated
  USING (get_my_role() IN ('admin', 'clinic_admin'));

DROP POLICY IF EXISTS "prescriptions_select" ON prescriptions;
DROP POLICY IF EXISTS "prescriptions_insert" ON prescriptions;
DROP POLICY IF EXISTS "prescriptions_update" ON prescriptions;
DROP POLICY IF EXISTS "prescriptions_delete" ON prescriptions;

CREATE POLICY "prescriptions_select"
  ON prescriptions FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = prescriptions.patient_id
      AND p.clinic_id = get_my_clinic_id()
    )
  );

CREATE POLICY "prescriptions_insert"
  ON prescriptions FOR INSERT TO authenticated
  WITH CHECK (
    get_my_role() = 'admin'
    OR (
      get_my_role() IN ('clinic_admin', 'doctor')
      AND EXISTS (
        SELECT 1 FROM patients p
        WHERE p.id = prescriptions.patient_id
        AND p.clinic_id = get_my_clinic_id()
      )
    )
  );

CREATE POLICY "prescriptions_update"
  ON prescriptions FOR UPDATE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR get_my_role() = 'clinic_admin'
    OR (doctor_id = auth.uid() AND get_my_role() = 'doctor')
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR get_my_role() = 'clinic_admin'
    OR (doctor_id = auth.uid() AND get_my_role() = 'doctor')
  );

CREATE POLICY "prescriptions_delete"
  ON prescriptions FOR DELETE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR get_my_role() = 'clinic_admin'
    OR (doctor_id = auth.uid() AND get_my_role() = 'doctor')
  );

DROP POLICY IF EXISTS "invoices_select" ON invoices;
DROP POLICY IF EXISTS "invoices_insert" ON invoices;
DROP POLICY IF EXISTS "invoices_update" ON invoices;
DROP POLICY IF EXISTS "invoices_delete" ON invoices;

CREATE POLICY "invoices_select"
  ON invoices FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "invoices_insert"
  ON invoices FOR INSERT TO authenticated
  WITH CHECK (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "invoices_update"
  ON invoices FOR UPDATE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR clinic_id = get_my_clinic_id()
  );

-- ===== 20260217212605_add_medicine_type_and_structured_fields.sql =====
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'medicines' AND column_name = 'medicine_type'
  ) THEN
    ALTER TABLE medicines ADD COLUMN medicine_type text NOT NULL DEFAULT 'Tablet';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'medicines' AND column_name = 'strength'
  ) THEN
    ALTER TABLE medicines ADD COLUMN strength text DEFAULT '';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'medicines' AND column_name = 'form'
  ) THEN
    ALTER TABLE medicines ADD COLUMN form text DEFAULT '';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'medicines' AND column_name = 'default_dosage'
  ) THEN
    ALTER TABLE medicines ADD COLUMN default_dosage text DEFAULT '';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_medicines_type ON medicines(medicine_type);
CREATE INDEX IF NOT EXISTS idx_medicines_name ON medicines(medicine_name);

-- ===== 20260217213939_allow_public_access_to_active_services.sql =====
DO $$
BEGIN
  DROP POLICY IF EXISTS "Public can view active services" ON dental_services;
END $$;

CREATE POLICY "Public can view active services"
  ON dental_services
  FOR SELECT
  TO anon
  USING (is_active = true);

-- ===== 20260218093035_fix_handle_new_user_trigger.sql =====
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO users_profile (id, name, email, role, clinic_id, is_active)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'receptionist'),
    (NEW.raw_user_meta_data->>'clinic_id')::uuid,
    COALESCE((NEW.raw_user_meta_data->>'is_active')::boolean, true)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===== 20260218100355_rebuild_users_system_clean.sql =====
DROP TABLE IF EXISTS users_profile CASCADE;

CREATE TABLE users_profile (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  name text NOT NULL,
  role text NOT NULL DEFAULT 'receptionist' CHECK (role IN ('admin', 'clinic_admin', 'doctor', 'receptionist')),
  clinic_id uuid REFERENCES clinics(id) ON DELETE SET NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE users_profile ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO users_profile (id, email, name, role, clinic_id, is_active)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'receptionist'),
    CASE 
      WHEN NEW.raw_user_meta_data->>'clinic_id' IS NOT NULL 
      THEN (NEW.raw_user_meta_data->>'clinic_id')::uuid 
      ELSE NULL 
    END,
    COALESCE((NEW.raw_user_meta_data->>'is_active')::boolean, true)
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    role = EXCLUDED.role,
    clinic_id = EXCLUDED.clinic_id,
    is_active = EXCLUDED.is_active,
    updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE OR REPLACE FUNCTION get_my_clinic_id()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT clinic_id FROM users_profile WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION get_my_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT role FROM users_profile WHERE id = auth.uid()
$$;

CREATE POLICY "users_profile_select"
  ON users_profile FOR SELECT TO authenticated
  USING (
    get_my_role() = 'admin'
    OR id = auth.uid()
    OR clinic_id = get_my_clinic_id()
  );

CREATE POLICY "users_profile_insert"
  ON users_profile FOR INSERT TO authenticated
  WITH CHECK (
    get_my_role() = 'admin'
    OR (get_my_role() = 'clinic_admin' AND clinic_id = get_my_clinic_id())
  );

CREATE POLICY "users_profile_update"
  ON users_profile FOR UPDATE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (get_my_role() = 'clinic_admin' AND clinic_id = get_my_clinic_id())
    OR id = auth.uid()
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR (get_my_role() = 'clinic_admin' AND clinic_id = get_my_clinic_id())
    OR id = auth.uid()
  );

CREATE POLICY "users_profile_delete"
  ON users_profile FOR DELETE TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (get_my_role() = 'clinic_admin' AND clinic_id = get_my_clinic_id() AND id != auth.uid())
  );

CREATE INDEX IF NOT EXISTS idx_users_profile_clinic_id ON users_profile(clinic_id);
CREATE INDEX IF NOT EXISTS idx_users_profile_role ON users_profile(role);
CREATE INDEX IF NOT EXISTS idx_users_profile_is_active ON users_profile(is_active);

-- ===== 20260218100731_reset_super_admin_password.sql =====
UPDATE auth.users 
SET 
  encrypted_password = crypt('Admin@123', gen_salt('bf')),
  updated_at = now()
WHERE email = 'admin@dadcDr Ali Dental Centre.com';

-- ===== 20260218100917_fix_super_admin_password_properly.sql =====
-- Ensure the referenced auth user exists before touching users_profile
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users WHERE id = 'a1b2c3d4-0000-0000-0000-000000000001'
  ) THEN
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      aud,
      role,
      created_at,
      updated_at,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change
    ) VALUES (
      'a1b2c3d4-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000000',
      'admin@Dr Ali Dental Centre.com',
      crypt('Admin123!', gen_salt('bf')),
      now(),
      '{"provider": "email", "providers": ["email"]}',
      '{"name": "Super Admin", "role": "admin"}',
      'authenticated',
      'authenticated',
      now(),
      now(),
      '',
      '',
      '',
      ''
    );
  END IF;
END $$;

INSERT INTO users_profile (id, email, name, role, clinic_id, is_active)
VALUES ('a1b2c3d4-0000-0000-0000-000000000001', 'admin@Dr Ali Dental Centre.com', 'Super Admin', 'admin', NULL, true)
ON CONFLICT (id) DO UPDATE SET
  name = 'Super Admin',
  role = 'admin',
  clinic_id = NULL,
  is_active = true;

UPDATE auth.users 
SET 
  encrypted_password = crypt('Admin123!', gen_salt('bf')),
  email_confirmed_at = COALESCE(email_confirmed_at, now()),
  updated_at = now()
WHERE id = 'a1b2c3d4-0000-0000-0000-000000000001';

-- ===== 20260218100949_reset_admin_password_final.sql =====
UPDATE auth.users 
SET 
  encrypted_password = crypt('admin123', gen_salt('bf')),
  email_confirmed_at = now(),
  confirmation_token = '',
  raw_user_meta_data = jsonb_build_object(
    'name', 'Super Admin',
    'role', 'admin'
  ),
  updated_at = now()
WHERE id = 'a1b2c3d4-0000-0000-0000-000000000001';

UPDATE users_profile 
SET 
  name = 'Super Admin',
  role = 'admin',
  clinic_id = NULL,
  is_active = true,
  updated_at = now()
WHERE id = 'a1b2c3d4-0000-0000-0000-000000000001';

-- ===== 20260218101618_create_fresh_super_admin.sql =====
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  aud,
  role,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change
)
VALUES (
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'admin@gmail.com',
  crypt('admin123', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"name": "Super Admin", "role": "admin"}',
  'authenticated',
  'authenticated',
  now(),
  now(),
  '',
  '',
  '',
  ''
);

-- ===== 20260218103158_recreate_super_admin_with_identity.sql =====
DELETE FROM users_profile WHERE id = '3bce86d8-6022-4c24-a105-71057c7ed5c3';
DELETE FROM auth.identities WHERE user_id = '3bce86d8-6022-4c24-a105-71057c7ed5c3';
DELETE FROM auth.users WHERE id = '3bce86d8-6022-4c24-a105-71057c7ed5c3';

DO $$
DECLARE
  new_user_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    aud,
    role,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change
  ) VALUES (
    new_user_id,
    '00000000-0000-0000-0000-000000000000',
    'admin@dadc.com',
    crypt('Admin123!', gen_salt('bf')),
    now(),
    '{"provider": "email", "providers": ["email"]}',
    '{"name": "Super Admin", "role": "admin"}',
    'authenticated',
    'authenticated',
    now(),
    now(),
    '',
    '',
    '',
    ''
  );

  INSERT INTO auth.identities (
    id,
    user_id,
    provider_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    new_user_id,
    'admin@dadc.com',
    jsonb_build_object(
      'sub', new_user_id::text,
      'email', 'admin@dadc.com',
      'email_verified', true,
      'phone_verified', false
    ),
    'email',
    now(),
    now(),
    now()
  );

  UPDATE users_profile 
  SET role = 'admin', name = 'Super Admin'
  WHERE id = new_user_id;
END $$;

-- ===== 20260218103256_fix_users_profile_select_policy.sql =====
DROP POLICY IF EXISTS "users_profile_select" ON users_profile;

CREATE POLICY "users_profile_select" ON users_profile
  FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM users_profile up 
      WHERE up.id = auth.uid() 
      AND (
        up.role = 'admin' 
        OR (up.clinic_id IS NOT NULL AND up.clinic_id = users_profile.clinic_id)
      )
    )
  );

-- ===== 20260218103650_fix_user_trigger_timing.sql =====
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ===== 20260218103736_drop_auto_profile_trigger.sql =====
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- ===== 20260218104021_fix_users_profile_select_recursion.sql =====
DROP POLICY IF EXISTS "users_profile_select" ON users_profile;

CREATE POLICY "users_profile_select" ON users_profile
  FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    OR get_my_role() = 'admin'
    OR (get_my_role() = 'clinic_admin' AND clinic_id = get_my_clinic_id())
    OR (get_my_role() IN ('doctor', 'receptionist') AND clinic_id = get_my_clinic_id())
  );

-- ===== 20260218104557_fix_infinite_recursion_in_rls.sql =====
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM users_profile WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION get_my_clinic_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT clinic_id FROM users_profile WHERE id = auth.uid()
$$;

-- ===== 20260218105716_fix_users_profile_rls_final.sql =====
DROP POLICY IF EXISTS "users_profile_select" ON users_profile;
DROP POLICY IF EXISTS "users_profile_insert" ON users_profile;
DROP POLICY IF EXISTS "users_profile_update" ON users_profile;
DROP POLICY IF EXISTS "users_profile_delete" ON users_profile;

CREATE POLICY "users_profile_select" ON users_profile
FOR SELECT TO authenticated
USING (
  id = auth.uid()
  OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  OR (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('clinic_admin', 'doctor', 'receptionist')
    AND clinic_id = (
      SELECT up.clinic_id FROM users_profile up WHERE up.id = auth.uid()
    )
  )
);

CREATE POLICY "users_profile_insert" ON users_profile
FOR INSERT TO authenticated
WITH CHECK (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  OR (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'clinic_admin'
    AND clinic_id = (
      SELECT up.clinic_id FROM users_profile up WHERE up.id = auth.uid()
    )
  )
);

CREATE POLICY "users_profile_update" ON users_profile
FOR UPDATE TO authenticated
USING (
  id = auth.uid()
  OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  OR (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'clinic_admin'
    AND clinic_id = (
      SELECT up.clinic_id FROM users_profile up WHERE up.id = auth.uid()
    )
  )
)
WITH CHECK (
  id = auth.uid()
  OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  OR (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'clinic_admin'
    AND clinic_id = (
      SELECT up.clinic_id FROM users_profile up WHERE up.id = auth.uid()
    )
  )
);

CREATE POLICY "users_profile_delete" ON users_profile
FOR DELETE TO authenticated
USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  OR (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'clinic_admin'
    AND clinic_id = (
      SELECT up.clinic_id FROM users_profile up WHERE up.id = auth.uid()
    )
    AND id <> auth.uid()
  )
);

-- ===== 20260218105740_fix_rls_with_bypass_functions.sql =====
DROP POLICY IF EXISTS "users_profile_select" ON users_profile;
DROP POLICY IF EXISTS "users_profile_insert" ON users_profile;
DROP POLICY IF EXISTS "users_profile_update" ON users_profile;
DROP POLICY IF EXISTS "users_profile_delete" ON users_profile;

CREATE OR REPLACE FUNCTION get_my_clinic_id_bypass()
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result uuid;
BEGIN
  SELECT clinic_id INTO result FROM users_profile WHERE id = auth.uid();
  RETURN result;
END;
$$;

CREATE POLICY "users_profile_select" ON users_profile
FOR SELECT TO authenticated
USING (
  id = auth.uid()
  OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  OR (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('clinic_admin', 'doctor', 'receptionist')
    AND clinic_id = get_my_clinic_id_bypass()
  )
);

CREATE POLICY "users_profile_insert" ON users_profile
FOR INSERT TO authenticated
WITH CHECK (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  OR (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'clinic_admin'
    AND clinic_id = get_my_clinic_id_bypass()
  )
);

CREATE POLICY "users_profile_update" ON users_profile
FOR UPDATE TO authenticated
USING (
  id = auth.uid()
  OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  OR (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'clinic_admin'
    AND clinic_id = get_my_clinic_id_bypass()
  )
)
WITH CHECK (
  id = auth.uid()
  OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  OR (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'clinic_admin'
    AND clinic_id = get_my_clinic_id_bypass()
  )
);

CREATE POLICY "users_profile_delete" ON users_profile
FOR DELETE TO authenticated
USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  OR (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'clinic_admin'
    AND clinic_id = get_my_clinic_id_bypass()
    AND id <> auth.uid()
  )
);

-- ===== 20260218110334_add_doctor_foreign_keys.sql =====
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'patients_doctor_id_fkey' 
    AND table_name = 'patients'
  ) THEN
    ALTER TABLE patients 
    ADD CONSTRAINT patients_doctor_id_fkey 
    FOREIGN KEY (doctor_id) REFERENCES users_profile(id) ON DELETE SET NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'appointments_doctor_id_fkey' 
    AND table_name = 'appointments'
  ) THEN
    ALTER TABLE appointments 
    ADD CONSTRAINT appointments_doctor_id_fkey 
    FOREIGN KEY (doctor_id) REFERENCES users_profile(id) ON DELETE SET NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'invoices_doctor_id_fkey' 
    AND table_name = 'invoices'
  ) THEN
    ALTER TABLE invoices 
    ADD CONSTRAINT invoices_doctor_id_fkey 
    FOREIGN KEY (doctor_id) REFERENCES users_profile(id) ON DELETE SET NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'prescriptions_doctor_id_fkey' 
    AND table_name = 'prescriptions'
  ) THEN
    ALTER TABLE prescriptions 
    ADD CONSTRAINT prescriptions_doctor_id_fkey 
    FOREIGN KEY (doctor_id) REFERENCES users_profile(id) ON DELETE SET NULL;
  END IF;
END $$;

-- ===== 20260218110611_fix_helper_functions_use_jwt.sql =====
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'role',
    'unknown'
  )
$$;

CREATE OR REPLACE FUNCTION get_my_clinic_id()
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result uuid;
BEGIN
  SELECT clinic_id INTO result FROM users_profile WHERE id = auth.uid();
  RETURN result;
END;
$$;

-- ===== 20260218111514_fix_get_my_role_use_db_lookup.sql =====
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  result text;
BEGIN
  SELECT role INTO result FROM users_profile WHERE id = auth.uid();
  RETURN COALESCE(result, 'unknown');
END;
$$;

-- ===== 20260218111947_allow_doctors_to_manage_medicines.sql =====
DROP POLICY IF EXISTS medicines_update ON medicines;
CREATE POLICY "medicines_update"
  ON medicines FOR UPDATE
  TO authenticated
  USING (get_my_role() IN ('admin', 'clinic_admin', 'doctor'))
  WITH CHECK (get_my_role() IN ('admin', 'clinic_admin', 'doctor'));

DROP POLICY IF EXISTS medicines_delete ON medicines;
CREATE POLICY "medicines_delete"
  ON medicines FOR DELETE
  TO authenticated
  USING (get_my_role() IN ('admin', 'clinic_admin', 'doctor'));

-- ===== 20260218112802_fix_users_profile_rls_simplified.sql =====
DROP POLICY IF EXISTS "users_profile_select" ON users_profile;
DROP POLICY IF EXISTS "users_profile_insert" ON users_profile;
DROP POLICY IF EXISTS "users_profile_update" ON users_profile;
DROP POLICY IF EXISTS "users_profile_delete" ON users_profile;

CREATE POLICY "users_profile_select"
  ON users_profile FOR SELECT
  TO authenticated
  USING (
    id = auth.uid()
    OR ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
    OR (
      clinic_id IS NOT NULL 
      AND clinic_id = (
        SELECT up.clinic_id FROM users_profile up WHERE up.id = auth.uid()
      )
    )
  );

CREATE POLICY "users_profile_insert"
  ON users_profile FOR INSERT
  TO authenticated
  WITH CHECK (
    ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
  );

CREATE POLICY "users_profile_update"
  ON users_profile FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid()
    OR ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
  )
  WITH CHECK (
    id = auth.uid()
    OR ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
  );

CREATE POLICY "users_profile_delete"
  ON users_profile FOR DELETE
  TO authenticated
  USING (
    ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
    AND id <> auth.uid()
  );

-- ===== 20260218112828_remove_clinic_admin_from_all_rls_policies.sql =====
DROP POLICY IF EXISTS "dental_services_insert" ON dental_services;
DROP POLICY IF EXISTS "dental_services_update" ON dental_services;
DROP POLICY IF EXISTS "dental_services_delete" ON dental_services;

CREATE POLICY "dental_services_insert"
  ON dental_services FOR INSERT
  TO authenticated
  WITH CHECK (get_my_role() = 'admin');

CREATE POLICY "dental_services_update"
  ON dental_services FOR UPDATE
  TO authenticated
  USING (get_my_role() = 'admin')
  WITH CHECK (get_my_role() = 'admin');

CREATE POLICY "dental_services_delete"
  ON dental_services FOR DELETE
  TO authenticated
  USING (get_my_role() = 'admin');

DROP POLICY IF EXISTS "csp_insert" ON clinic_service_prices;
DROP POLICY IF EXISTS "csp_update" ON clinic_service_prices;
DROP POLICY IF EXISTS "csp_delete" ON clinic_service_prices;

CREATE POLICY "csp_insert"
  ON clinic_service_prices FOR INSERT
  TO authenticated
  WITH CHECK (get_my_role() = 'admin');

CREATE POLICY "csp_update"
  ON clinic_service_prices FOR UPDATE
  TO authenticated
  USING (get_my_role() = 'admin')
  WITH CHECK (get_my_role() = 'admin');

CREATE POLICY "csp_delete"
  ON clinic_service_prices FOR DELETE
  TO authenticated
  USING (get_my_role() = 'admin');

DROP POLICY IF EXISTS "clinics_update" ON clinics;

CREATE POLICY "clinics_update"
  ON clinics FOR UPDATE
  TO authenticated
  USING (get_my_role() = 'admin')
  WITH CHECK (get_my_role() = 'admin');

DROP POLICY IF EXISTS "patients_delete" ON patients;

CREATE POLICY "patients_delete"
  ON patients FOR DELETE
  TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (clinic_id = get_my_clinic_id() AND get_my_role() = 'doctor')
  );

DROP POLICY IF EXISTS "patient_files_delete" ON patient_files;

CREATE POLICY "patient_files_delete"
  ON patient_files FOR DELETE
  TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (
      uploaded_by = auth.uid()
      AND EXISTS (
        SELECT 1 FROM patients p
        WHERE p.id = patient_files.patient_id
        AND p.clinic_id = get_my_clinic_id()
      )
    )
  );

DROP POLICY IF EXISTS "medicines_insert" ON medicines;
DROP POLICY IF EXISTS "medicines_update" ON medicines;
DROP POLICY IF EXISTS "medicines_delete" ON medicines;

CREATE POLICY "medicines_insert"
  ON medicines FOR INSERT
  TO authenticated
  WITH CHECK (get_my_role() IN ('admin', 'doctor'));

CREATE POLICY "medicines_update"
  ON medicines FOR UPDATE
  TO authenticated
  USING (get_my_role() IN ('admin', 'doctor'))
  WITH CHECK (get_my_role() IN ('admin', 'doctor'));

CREATE POLICY "medicines_delete"
  ON medicines FOR DELETE
  TO authenticated
  USING (get_my_role() IN ('admin', 'doctor'));

DROP POLICY IF EXISTS "prescriptions_insert" ON prescriptions;
DROP POLICY IF EXISTS "prescriptions_update" ON prescriptions;
DROP POLICY IF EXISTS "prescriptions_delete" ON prescriptions;

CREATE POLICY "prescriptions_insert"
  ON prescriptions FOR INSERT
  TO authenticated
  WITH CHECK (
    get_my_role() = 'admin'
    OR (
      get_my_role() = 'doctor'
      AND EXISTS (
        SELECT 1 FROM patients p
        WHERE p.id = prescriptions.patient_id
        AND p.clinic_id = get_my_clinic_id()
      )
    )
  );

CREATE POLICY "prescriptions_update"
  ON prescriptions FOR UPDATE
  TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (doctor_id = auth.uid() AND get_my_role() = 'doctor')
  )
  WITH CHECK (
    get_my_role() = 'admin'
    OR (doctor_id = auth.uid() AND get_my_role() = 'doctor')
  );

CREATE POLICY "prescriptions_delete"
  ON prescriptions FOR DELETE
  TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (doctor_id = auth.uid() AND get_my_role() = 'doctor')
  );

DROP POLICY IF EXISTS "invoices_delete" ON invoices;

CREATE POLICY "invoices_delete"
  ON invoices FOR DELETE
  TO authenticated
  USING (
    get_my_role() = 'admin'
    OR (clinic_id = get_my_clinic_id() AND get_my_role() = 'doctor')
  );

-- ===== 20260218113541_fix_users_profile_infinite_recursion.sql =====
CREATE OR REPLACE FUNCTION get_my_clinic_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT clinic_id FROM users_profile WHERE id = auth.uid();
$$;

DROP POLICY IF EXISTS "users_profile_select" ON users_profile;

CREATE POLICY "users_profile_select"
  ON users_profile
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid()
    OR ((auth.jwt() -> 'user_metadata') ->> 'role') = 'admin'
    OR (clinic_id IS NOT NULL AND clinic_id = get_my_clinic_id())
  );

-- ===== 20260218120000_restore_handle_new_user_and_backfill.sql =====
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

UPDATE auth.users u
SET raw_user_meta_data = COALESCE(u.raw_user_meta_data, '{}'::jsonb)
  || jsonb_build_object(
    'role', COALESCE(up.role, u.raw_user_meta_data->>'role', 'receptionist'),
    'name', COALESCE(u.raw_user_meta_data->>'name', up.name, split_part(u.email, '@', 1))
  )
FROM users_profile up
WHERE u.id = up.id
  AND (u.raw_user_meta_data->>'role') IS NULL;

UPDATE auth.users u
SET raw_user_meta_data = COALESCE(u.raw_user_meta_data, '{}'::jsonb)
  || jsonb_build_object(
    'role', COALESCE(u.raw_user_meta_data->>'role', 'receptionist'),
    'name', COALESCE(u.raw_user_meta_data->>'name', split_part(u.email, '@', 1))
  )
WHERE (u.raw_user_meta_data->>'role') IS NULL;

-- ===== default_admin_seed.sql =====
DO $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Reuse an existing admin user by email if present, otherwise create a deterministic ID
  SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower('admin@dadc.com') LIMIT 1;

  IF v_user_id IS NULL THEN
    v_user_id := '11111111-1111-1111-1111-111111111111';

    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      aud,
      role,
      created_at,
      updated_at,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change
    ) VALUES (
      v_user_id,
      '00000000-0000-0000-0000-000000000000',
      'admin@dadc.com',
      crypt('Admin123!', gen_salt('bf')),
      now(),
      '{"provider": "email", "providers": ["email"]}',
      '{"name": "Default Admin", "role": "admin"}',
      'authenticated',
      'authenticated',
      now(),
      now(),
      '',
      '',
      '',
      ''
    )
    ON CONFLICT (id) DO UPDATE SET
      encrypted_password = EXCLUDED.encrypted_password,
      email_confirmed_at = EXCLUDED.email_confirmed_at,
      raw_app_meta_data = EXCLUDED.raw_app_meta_data,
      raw_user_meta_data = EXCLUDED.raw_user_meta_data,
      updated_at = now();
  ELSE
    UPDATE auth.users
    SET
      encrypted_password = crypt('Admin123!', gen_salt('bf')),
      email_confirmed_at = now(),
      raw_app_meta_data = '{"provider": "email", "providers": ["email"]}',
      raw_user_meta_data = jsonb_build_object('name', 'Default Admin', 'role', 'admin'),
      updated_at = now()
    WHERE id = v_user_id;
  END IF;

  INSERT INTO auth.identities (
    id,
    user_id,
    provider_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_user_id,
    'admin@dadc.com',
    jsonb_build_object(
      'sub', v_user_id::text,
      'email', 'admin@dadc.com',
      'email_verified', true,
      'phone_verified', false
    ),
    'email',
    now(),
    now(),
    now()
  )
  ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = now();

  INSERT INTO users_profile (id, email, name, role, clinic_id, is_active, created_at, updated_at)
  VALUES (
    v_user_id,
    'admin@dadc.com',
    'Default Admin',
    'admin',
    NULL,
    true,
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    role = EXCLUDED.role,
    clinic_id = EXCLUDED.clinic_id,
    is_active = EXCLUDED.is_active,
    updated_at = now();
END $$;
