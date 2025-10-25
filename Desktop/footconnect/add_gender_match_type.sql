-- Add gender field to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR(10) CHECK (gender IN ('male', 'female'));

-- Add match_type field to matches table
ALTER TABLE matches ADD COLUMN IF NOT EXISTS match_type VARCHAR(10) DEFAULT 'mixed' CHECK (match_type IN ('male', 'female', 'mixed'));

-- Update existing users to have a default gender (optional, can be set later)
-- UPDATE users SET gender = 'male' WHERE gender IS NULL; -- Uncomment if you want to set defaults

-- Update RLS policies if needed (existing policies should work for new columns)