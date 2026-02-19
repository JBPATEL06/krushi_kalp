-- Update resources table to allow new types
-- First, try to drop the existing constraint. 
-- Note: The default name for an inline check constraint on column 'type' in table 'resources' is 'resources_type_check'.
ALTER TABLE public.resources DROP CONSTRAINT IF EXISTS resources_type_check;

-- Add the new constraint with expanded types
ALTER TABLE public.resources ADD CONSTRAINT resources_type_check
CHECK (type IN ('current_affair', 'study_material', 'ebook', 'pyq'));
