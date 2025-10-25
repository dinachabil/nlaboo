-- Add team1_id, team2_id, match_type, and owner_id columns to matches table
-- Run this in Supabase SQL Editor

-- Add team1_id column
ALTER TABLE matches ADD COLUMN IF NOT EXISTS team1_id UUID REFERENCES teams(id) ON DELETE CASCADE;

-- Add team2_id column
ALTER TABLE matches ADD COLUMN IF NOT EXISTS team2_id UUID REFERENCES teams(id) ON DELETE CASCADE;

-- Add match_type column
ALTER TABLE matches ADD COLUMN IF NOT EXISTS match_type TEXT CHECK (match_type IN ('male', 'female', 'mixed')) DEFAULT 'male';

-- Add owner_id column if not exists
ALTER TABLE matches ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES users(id) ON DELETE CASCADE;

-- Update existing matches to set owner_id from team owner if team_id exists
UPDATE matches
SET owner_id = teams.owner_id
FROM teams
WHERE matches.team_id = teams.id AND matches.owner_id IS NULL;

-- Drop the old team_id column after migrating data
-- Note: This will be done after confirming migration works
-- ALTER TABLE matches DROP COLUMN IF EXISTS team_id;