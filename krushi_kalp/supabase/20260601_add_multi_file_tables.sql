-- Table for Resource Supplementary Files
CREATE TABLE IF NOT EXISTS resource_files (
  id SERIAL PRIMARY KEY,
  resource_id INTEGER NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  display_name TEXT NOT NULL,
  file_order INTEGER DEFAULT 0,
  file_size_bytes BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE resource_files ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Allow public read access for resource_files" 
  ON resource_files FOR SELECT USING (true);
  
CREATE POLICY "Allow all access for authenticated admins" 
  ON resource_files FOR ALL TO authenticated USING (true);

-- Table for Mock Test Supplementary Files
CREATE TABLE IF NOT EXISTS mock_test_files (
  id SERIAL PRIMARY KEY,
  test_id INTEGER NOT NULL REFERENCES mock_tests(test_id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  display_name TEXT NOT NULL,
  file_order INTEGER DEFAULT 0,
  file_size_bytes BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE mock_test_files ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Allow public read access for mock_test_files" 
  ON mock_test_files FOR SELECT USING (true);
  
CREATE POLICY "Allow all access for authenticated admins" 
  ON mock_test_files FOR ALL TO authenticated USING (true);
