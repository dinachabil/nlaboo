-- Fix teams table RLS policies to allow proper joins

-- Drop existing policies
DROP POLICY IF EXISTS "Team owners can manage their teams" ON teams;
DROP POLICY IF EXISTS "Public can view teams" ON teams;
DROP POLICY IF EXISTS "Admins can manage all teams" ON teams;

-- Enable RLS
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;

-- Team owners can manage their teams
CREATE POLICY "Team owners can manage their teams" ON teams
    FOR ALL USING (auth.uid() = owner_id);

-- Allow public read access for teams (needed for match listings)
CREATE POLICY "Public can view teams" ON teams
    FOR SELECT USING (true);

-- Admins can manage all teams
CREATE POLICY "Admins can manage all teams" ON teams
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Also ensure matches table policies are correct
DROP POLICY IF EXISTS "Team owners can manage their matches" ON matches;
DROP POLICY IF EXISTS "Public can view open matches" ON matches;
DROP POLICY IF EXISTS "Admins can manage all matches" ON matches;

ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Team owners can manage their matches" ON matches
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM teams
            WHERE teams.id = matches.team_id AND teams.owner_id = auth.uid()
        )
    );

CREATE POLICY "Public can view open matches" ON matches
    FOR SELECT USING (status = 'open');

CREATE POLICY "Admins can manage all matches" ON matches
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );