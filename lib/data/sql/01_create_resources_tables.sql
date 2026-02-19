-- Create study_materials table
CREATE TABLE public.study_materials (
  material_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  title text NOT NULL,
  description text,
  price numeric DEFAULT 0.00 CHECK (price >= 0::numeric),
  file_path text,
  cover_image_path text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT study_materials_pkey PRIMARY KEY (material_id)
);

-- Create current_affairs table
CREATE TABLE public.current_affairs (
  fair_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  title text NOT NULL,
  content text,
  file_path text,
  publish_date date DEFAULT CURRENT_DATE,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT current_affairs_pkey PRIMARY KEY (fair_id)
);

-- Modify order_items to support materials
ALTER TABLE public.order_items
ADD COLUMN material_id bigint;

ALTER TABLE public.order_items
ALTER COLUMN test_id DROP NOT NULL;

ALTER TABLE public.order_items
ADD CONSTRAINT order_items_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.study_materials(material_id);

ALTER TABLE public.order_items
ADD CONSTRAINT check_item_type CHECK (
  (test_id IS NOT NULL AND material_id IS NULL) OR
  (test_id IS NULL AND material_id IS NOT NULL)
);

-- RLS Policies (Examples - Adjust as needed for your specific roles)

-- Enable RLS
ALTER TABLE public.study_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.current_affairs ENABLE ROW LEVEL SECURITY;

-- Study Materials Policies
CREATE POLICY "Public read access for active study materials"
ON public.study_materials FOR SELECT
USING (is_active = true);

-- Current Affairs Policies
CREATE POLICY "Public read access for active current affairs"
ON public.current_affairs FOR SELECT
USING (is_active = true);

-- Admin policies (assuming admin checks exist in app or via role)
CREATE POLICY "Admin full access study_materials" ON public.study_materials FOR ALL USING (auth.uid() IN (SELECT id FROM public.users WHERE role = 'Admin'));
CREATE POLICY "Admin full access current_affairs" ON public.current_affairs FOR ALL USING (auth.uid() IN (SELECT id FROM public.users WHERE role = 'Admin'));
