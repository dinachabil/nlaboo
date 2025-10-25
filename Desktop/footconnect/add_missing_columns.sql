-- Add missing columns to users table for consistency with application code
ALTER TABLE users ADD COLUMN IF NOT EXISTS position TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT;

-- Update RLS policies if needed (existing policies should work for new columns)