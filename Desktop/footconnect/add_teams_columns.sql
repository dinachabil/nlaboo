-- Add missing columns to teams table for complete team functionality
-- Run this in Supabase SQL Editor

-- Add location column
ALTER TABLE teams ADD COLUMN IF NOT EXISTS location TEXT;

-- Add description column
ALTER TABLE teams ADD COLUMN IF NOT EXISTS description TEXT;

-- Add logo_url column
ALTER TABLE teams ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- Add max_players column with default value
ALTER TABLE teams ADD COLUMN IF NOT EXISTS max_players INTEGER DEFAULT 11;

-- Add is_recruiting column with default value
ALTER TABLE teams ADD COLUMN IF NOT EXISTS is_recruiting BOOLEAN DEFAULT FALSE;

-- Create team_members table if it doesn't exist
CREATE TABLE IF NOT EXISTS team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role TEXT CHECK (role IN ('admin', 'member')) DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

-- Enable RLS on team_members
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;

-- RLS Policies for team_members
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Team members can view team members" ON team_members;
DROP POLICY IF EXISTS "Team admins can manage team members" ON team_members;
DROP POLICY IF EXISTS "Users can view own memberships" ON team_members;

-- Team members can view members of their team
CREATE POLICY "Team members can view team members" ON team_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            WHERE tm.team_id = team_members.team_id
            AND tm.user_id = auth.uid()
        )
    );

-- Team admins can manage team members
CREATE POLICY "Team admins can manage team members" ON team_members
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM team_members tm
            WHERE tm.team_id = team_members.team_id
            AND tm.user_id = auth.uid()
            AND tm.role = 'admin'
        )
    );

-- Users can view their own memberships
CREATE POLICY "Users can view own memberships" ON team_members
    FOR SELECT USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_team_members_role ON team_members(role);

-- Update existing teams to have an admin member (the owner)
INSERT INTO team_members (team_id, user_id, role)
SELECT id, owner_id, 'admin'
FROM teams
WHERE NOT EXISTS (
    SELECT 1 FROM team_members
    WHERE team_members.team_id = teams.id
    AND team_members.user_id = teams.owner_id
);