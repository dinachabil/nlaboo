-- Performance optimization indexes
-- Add indexes for frequently queried columns

-- Matches table indexes
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_matches_date ON matches(match_date);
CREATE INDEX IF NOT EXISTS idx_matches_location ON matches(location);
CREATE INDEX IF NOT EXISTS idx_matches_team1 ON matches(team1_id);
CREATE INDEX IF NOT EXISTS idx_matches_team2 ON matches(team2_id);

-- Teams table indexes
CREATE INDEX IF NOT EXISTS idx_teams_owner ON teams(owner_id);
CREATE INDEX IF NOT EXISTS idx_teams_location ON teams(location);
CREATE INDEX IF NOT EXISTS idx_teams_recruiting ON teams(is_recruiting);
CREATE INDEX IF NOT EXISTS idx_teams_created ON teams(created_at DESC);

-- Team members table indexes
CREATE INDEX IF NOT EXISTS idx_team_members_team ON team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user ON team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_team_members_role ON team_members(role);

-- Team join requests table indexes
CREATE INDEX IF NOT EXISTS idx_join_requests_team ON team_join_requests(team_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_user ON team_join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_status ON team_join_requests(status);
CREATE INDEX IF NOT EXISTS idx_join_requests_team_status ON team_join_requests(team_id, status);

-- Match participants table indexes
CREATE INDEX IF NOT EXISTS idx_match_participants_match ON match_participants(match_id);
CREATE INDEX IF NOT EXISTS idx_match_participants_user ON match_participants(user_id);

-- Notifications table indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);

-- Users table indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_matches_status_date ON matches(status, match_date);
CREATE INDEX IF NOT EXISTS idx_teams_recruiting_created ON teams(is_recruiting, created_at DESC);
