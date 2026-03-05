-- Drop old tables if they exist (CASCADE to remove foreign keys in order_items)
DROP TABLE IF EXISTS public.study_materials CASCADE;
DROP TABLE IF EXISTS public.current_affairs CASCADE;

-- Create the unified resources table
CREATE TABLE public.resources (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  title text NOT NULL,
  description text,
  type text NOT NULL CHECK (type IN ('current_affair', 'study_material')),
  category text, -- e.g., 'Notes', 'Papers', 'Daily Update'
  file_url text, -- Path to PDF/File
  thumbnail_url text, -- Path to Cover Image
  price numeric DEFAULT 0.00 CHECK (price >= 0::numeric),
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT resources_pkey PRIMARY KEY (id)
);

-- RLS Policies for resources
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;

-- Public read access for active resources
CREATE POLICY "Public read active resources"
ON public.resources FOR SELECT
USING (is_active = true);

-- Admin full access
CREATE POLICY "Admin full access resources"
ON public.resources
FOR ALL
USING (
  auth.uid() IN (
    SELECT id FROM public.users WHERE role = 'Admin' OR role = 'admin'
  )
);


-- Modify order_items to reference the new resources table
-- Note: The previous CASCADE drop might have removed the material_id column or constraint.
-- We will ensure the column exists and points to resources.

-- Check if material_id exists, if so rename it or drop/recreate. The simplest path for a clean slate:
-- If order_items table structure needs alignment:

ALTER TABLE public.order_items
DROP COLUMN IF EXISTS material_id;

ALTER TABLE public.order_items
ADD COLUMN resource_id bigint;

ALTER TABLE public.order_items
ADD CONSTRAINT order_items_resource_id_fkey FOREIGN KEY (resource_id) REFERENCES public.resources(id);

-- Update the check constraint to ensure either test_id OR resource_id is present
ALTER TABLE public.order_items
DROP CONSTRAINT IF EXISTS check_item_type;

ALTER TABLE public.order_items
ADD CONSTRAINT check_item_type CHECK (
  (test_id IS NOT NULL AND resource_id IS NULL) OR
  (test_id IS NULL AND resource_id IS NOT NULL)
);

-- Index for faster lookups
CREATE INDEX idx_resources_type ON public.resources(type);
CREATE INDEX idx_resources_category ON public.resources(category);
