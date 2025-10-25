-- Complete RLS policy fix - drop all and recreate properly

-- Drop ALL existing policies first
DROP POLICY IF EXISTS "Allow user registration" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Authenticated users can view users" ON users;
DROP POLICY IF EXISTS "Authenticated users can delete users" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can delete users" ON users;

DROP POLICY IF EXISTS "Team owners can manage their teams" ON teams;
DROP POLICY IF EXISTS "Public can view teams" ON teams;
DROP POLICY IF EXISTS "Authenticated users can manage teams" ON teams;
DROP POLICY IF EXISTS "Admins can manage all teams" ON teams;

DROP POLICY IF EXISTS "Team owners can manage their matches" ON matches;
DROP POLICY IF EXISTS "Public can view open matches" ON matches;
DROP POLICY IF EXISTS "Authenticated users can manage matches" ON matches;
DROP POLICY IF EXISTS "Admins can manage all matches" ON matches;

DROP POLICY IF EXISTS "Users can manage their match participations" ON match_players;
DROP POLICY IF EXISTS "Public can view match players" ON match_players;
DROP POLICY IF EXISTS "Authenticated users can manage match players" ON match_players;
DROP POLICY IF EXISTS "Admins can manage all match players" ON match_players;

-- Ensure RLS is enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_players ENABLE ROW LEVEL SECURITY;

-- Create clean policies
CREATE POLICY "Allow user registration" ON users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Authenticated users can view users" ON users
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete users" ON users
    FOR DELETE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Team owners can manage their teams" ON teams
    FOR ALL USING (auth.uid() = owner_id);

CREATE POLICY "Public can view teams" ON teams
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage teams" ON teams
    FOR ALL USING (auth.uid() IS NOT NULL);

CREATE POLICY "Team owners can manage their matches" ON matches
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM teams
            WHERE teams.id = matches.team_id AND teams.owner_id = auth.uid()
        )
    );

CREATE POLICY "Public can view open matches" ON matches
    FOR SELECT USING (status = 'open');

CREATE POLICY "Authenticated users can manage matches" ON matches
    FOR ALL USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can manage their match participations" ON match_players
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Public can view match players" ON match_players
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage match players" ON match_players
    FOR ALL USING (auth.uid() IS NOT NULL);