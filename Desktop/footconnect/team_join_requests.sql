-- Team Join Requests Schema
-- Run this in Supabase SQL Editor

-- Create team_join_requests table
CREATE TABLE IF NOT EXISTS team_join_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

-- Enable RLS
ALTER TABLE team_join_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view their own join requests
CREATE POLICY "Users can view own join requests" ON team_join_requests
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create join requests
CREATE POLICY "Users can create join requests" ON team_join_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Team admins can view join requests for their teams
CREATE POLICY "Team admins can view join requests" ON team_join_requests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM teams
            WHERE teams.id = team_join_requests.team_id
            AND teams.owner_id = auth.uid()
        )
    );

-- Team admins can update join requests for their teams
CREATE POLICY "Team admins can update join requests" ON team_join_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM teams
            WHERE teams.id = team_join_requests.team_id
            AND teams.owner_id = auth.uid()
        )
    );

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_team_join_requests_team_id ON team_join_requests(team_id);
CREATE INDEX IF NOT EXISTS idx_team_join_requests_user_id ON team_join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_team_join_requests_status ON team_join_requests(status);