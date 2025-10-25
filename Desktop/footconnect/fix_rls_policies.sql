-- Fix Row Level Security Policies for proper authentication flow

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_players ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can delete users" ON users;
DROP POLICY IF EXISTS "Allow user registration" ON users;

-- Users table policies
-- Allow unauthenticated users to insert (for signup)
CREATE POLICY "Allow user registration" ON users
    FOR INSERT WITH CHECK (true);

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Admins can view all users
CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Admins can delete users
CREATE POLICY "Admins can delete users" ON users
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Teams table policies
-- Team owners can manage their teams
CREATE POLICY "Team owners can manage their teams" ON teams
    FOR ALL USING (auth.uid() = owner_id);

-- Public can view teams (for matches)
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

-- Matches table policies
-- Team owners can manage their matches
CREATE POLICY "Team owners can manage their matches" ON matches
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM teams
            WHERE teams.id = matches.team_id AND teams.owner_id = auth.uid()
        )
    );

-- Public can view open matches
CREATE POLICY "Public can view open matches" ON matches
    FOR SELECT USING (status = 'open');

-- Admins can manage all matches
CREATE POLICY "Admins can manage all matches" ON matches
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Match players table policies
-- Users can manage their match participations
CREATE POLICY "Users can manage their match participations" ON match_players
    FOR ALL USING (auth.uid() = user_id);

-- Public can view match players
CREATE POLICY "Public can view match players" ON match_players
    FOR SELECT USING (true);

-- Admins can manage all match players
CREATE POLICY "Admins can manage all match players" ON match_players
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );