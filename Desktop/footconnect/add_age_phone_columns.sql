-- Add age and phone columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS age INTEGER;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

-- Update RLS policies to allow these new columns
-- (Existing policies should work since they allow all operations on users table)