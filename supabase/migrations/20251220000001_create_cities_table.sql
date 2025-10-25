-- Create cities table if it doesn't exist
CREATE TABLE IF NOT EXISTS cities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  country TEXT NOT NULL,
  region TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_cities_country ON cities(country);
CREATE INDEX IF NOT EXISTS idx_cities_name ON cities(name);

-- Insert sample cities for Morocco
INSERT INTO cities (name, country, region) VALUES
  ('Casablanca', 'MA', 'Casablanca-Settat'),
  ('Rabat', 'MA', 'Rabat-Salé-Kénitra'),
  ('Marrakech', 'MA', 'Marrakech-Safi'),
  ('Fes', 'MA', 'Fès-Meknès'),
  ('Tangier', 'MA', 'Tanger-Tétouan-Al Hoceïma'),
  ('Agadir', 'MA', 'Souss-Massa'),
  ('Meknes', 'MA', 'Fès-Meknès'),
  ('Oujda', 'MA', 'Oriental'),
  ('Kenitra', 'MA', 'Rabat-Salé-Kénitra'),
  ('Tetouan', 'MA', 'Tanger-Tétouan-Al Hoceïma'),
  ('Safi', 'MA', 'Marrakech-Safi'),
  ('El Jadida', 'MA', 'Casablanca-Settat'),
  ('Nador', 'MA', 'Oriental'),
  ('Beni Mellal', 'MA', 'Béni Mellal-Khénifra'),
  ('Khouribga', 'MA', 'Béni Mellal-Khénifra')
ON CONFLICT DO NOTHING;

-- Enable RLS
ALTER TABLE cities ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Cities are viewable by everyone" ON cities;
DROP POLICY IF EXISTS "Cities are modifiable by admins only" ON cities;

-- Allow public read access to cities
CREATE POLICY "Cities are viewable by everyone"
  ON cities FOR SELECT
  USING (true);

-- Only admins can modify cities
CREATE POLICY "Cities are modifiable by admins only"
  ON cities FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');
