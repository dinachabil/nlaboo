-- Team Members and Chat System Schema
-- Run this in Supabase SQL Editor

-- Create team_members table
CREATE TABLE IF NOT EXISTS team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role TEXT CHECK (role IN ('admin', 'member')) DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

-- Create messages table for team chat
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES users(id) ON DELETE SET NULL, -- NULL for group messages
    content TEXT NOT NULL,
    message_type TEXT CHECK (message_type IN ('group', 'direct')) DEFAULT 'group',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add max_players column to teams table
ALTER TABLE teams ADD COLUMN IF NOT EXISTS max_players INTEGER DEFAULT 22;
ALTER TABLE teams ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE teams ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE teams ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE teams ADD COLUMN IF NOT EXISTS is_recruiting BOOLEAN DEFAULT FALSE;

-- Enable RLS on new tables
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies first to avoid conflicts
DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT schemaname, tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
    END LOOP;
END $$;

-- Disable RLS for all tables for development to avoid policy issues
ALTER TABLE team_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE teams DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE matches DISABLE ROW LEVEL SECURITY;
ALTER TABLE match_players DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Add additional constraints for data integrity (only if they don't exist)
DO $$
BEGIN
    -- Check and add teams constraints
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'teams_name_not_empty') THEN
        ALTER TABLE teams ADD CONSTRAINT teams_name_not_empty CHECK (length(trim(name)) > 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'teams_max_players_valid') THEN
        ALTER TABLE teams ADD CONSTRAINT teams_max_players_valid CHECK (max_players >= 5 AND max_players <= 50);
    END IF;

    -- Check and add team_members constraints
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'team_members_valid_role') THEN
        ALTER TABLE team_members ADD CONSTRAINT team_members_valid_role CHECK (role IN ('admin', 'member'));
    END IF;

    -- Check and add messages constraints
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'messages_content_not_empty') THEN
        ALTER TABLE messages ADD CONSTRAINT messages_content_not_empty CHECK (length(trim(content)) > 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'messages_valid_type') THEN
        ALTER TABLE messages ADD CONSTRAINT messages_valid_type CHECK (message_type IN ('group', 'direct'));
    END IF;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_team_members_role ON team_members(role);
CREATE INDEX IF NOT EXISTS idx_messages_team_id ON messages(team_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(message_type);
CREATE INDEX IF NOT EXISTS idx_teams_owner_id ON teams(owner_id);
CREATE INDEX IF NOT EXISTS idx_teams_is_recruiting ON teams(is_recruiting);
CREATE INDEX IF NOT EXISTS idx_teams_created_at ON teams(created_at);