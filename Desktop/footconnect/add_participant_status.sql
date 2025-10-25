-- Add status column to match_players table for participant management
ALTER TABLE match_players ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'joined' CHECK (status IN ('pending', 'joined', 'declined'));

-- Update existing records to have 'joined' status
UPDATE match_players SET status = 'joined' WHERE status IS NULL;