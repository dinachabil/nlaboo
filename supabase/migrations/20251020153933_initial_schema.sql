-- Football Community App - Initial Supabase Migration
-- Run this in Supabase SQL Editor to set up the database

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table (extends auth.users)
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT DEFAULT 'player' CHECK (role IN ('player', 'coach', 'admin')),
    gender TEXT CHECK (gender IN ('male', 'female')),
    age INTEGER CHECK (age >= 13 AND age <= 100),
    phone TEXT,
    avatar_url TEXT,
    bio TEXT,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create teams table
CREATE TABLE public.teams (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    owner_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    location TEXT,
    description TEXT,
    logo_url TEXT,
    max_players INTEGER DEFAULT 11 CHECK (max_players > 0),
    is_recruiting BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create team_members table
CREATE TABLE public.team_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('member', 'captain', 'coach')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

-- Create matches table
CREATE TABLE public.matches (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    team1_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    team2_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    match_date TIMESTAMPTZ NOT NULL,
    location TEXT NOT NULL,
    title TEXT,
    max_players INTEGER DEFAULT 22,
    match_type TEXT DEFAULT 'friendly' CHECK (match_type IN ('friendly', 'tournament', 'league')),
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'closed', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create match_participants table
CREATE TABLE public.match_participants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'pending', 'declined')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(match_id, user_id)
);

-- Create notifications table
CREATE TABLE public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('match_invite', 'team_invite', 'general', 'system')),
    is_read BOOLEAN DEFAULT false,
    related_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create cities table
CREATE TABLE public.cities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    country TEXT NOT NULL,
    region TEXT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(name, country)
);

-- Enable Row Level Security on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users policies
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Teams policies
CREATE POLICY "Anyone can view teams" ON public.teams FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create teams" ON public.teams
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Team owners can update their teams" ON public.teams
    FOR UPDATE USING (auth.uid() = owner_id);

-- Team members policies
CREATE POLICY "Team members can view team membership" ON public.team_members
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
    );
CREATE POLICY "Team owners can manage members" ON public.team_members
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
    );
CREATE POLICY "Users can join teams" ON public.team_members
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Matches policies
CREATE POLICY "Anyone can view matches" ON public.matches FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create matches" ON public.matches
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Team owners can update matches" ON public.matches
    FOR UPDATE USING (
        auth.uid() = (SELECT owner_id FROM public.teams WHERE id = team1_id) OR
        auth.uid() = (SELECT owner_id FROM public.teams WHERE id = team2_id)
    );

-- Match participants policies
CREATE POLICY "Users can view match participants" ON public.match_participants
    FOR SELECT USING (true);
CREATE POLICY "Users can join matches" ON public.match_participants
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their participation" ON public.match_participants
    FOR UPDATE USING (auth.uid() = user_id);

-- Notifications policies
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Cities policies
CREATE POLICY "Anyone can view cities" ON public.cities FOR SELECT USING (true);

-- Performance Indexes

-- Users indexes
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_users_location ON public.users USING gin(to_tsvector('english', location));

-- Teams indexes
CREATE INDEX idx_teams_owner ON public.teams(owner_id);
CREATE INDEX idx_teams_recruiting ON public.teams(is_recruiting);
CREATE INDEX idx_teams_location ON public.teams USING gin(to_tsvector('english', location));
CREATE INDEX idx_teams_name_description ON public.teams USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- Team members indexes
CREATE INDEX idx_team_members_team_user ON public.team_members(team_id, user_id);
CREATE INDEX idx_team_members_user ON public.team_members(user_id, joined_at DESC);
CREATE INDEX idx_team_members_role ON public.team_members(role);

-- Matches indexes
CREATE INDEX idx_matches_team1 ON public.matches(team1_id);
CREATE INDEX idx_matches_team2 ON public.matches(team2_id);
CREATE INDEX idx_matches_date ON public.matches(match_date);
CREATE INDEX idx_matches_status ON public.matches(status);
CREATE INDEX idx_matches_type ON public.matches(match_type);
CREATE INDEX idx_matches_date_status ON public.matches(match_date, status);
CREATE INDEX idx_matches_location ON public.matches USING gin(to_tsvector('english', location));

-- Match participants indexes
CREATE INDEX idx_match_participants_match_user ON public.match_participants(match_id, user_id);
CREATE INDEX idx_match_participants_user ON public.match_participants(user_id, joined_at DESC);
CREATE INDEX idx_match_participants_status ON public.match_participants(status);

-- Notifications indexes
CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id, is_read) WHERE NOT is_read;
CREATE INDEX idx_notifications_type ON public.notifications(type);
CREATE INDEX idx_notifications_created ON public.notifications(created_at DESC);

-- Cities indexes
CREATE INDEX idx_cities_country ON public.cities(country);
CREATE INDEX idx_cities_name_country ON public.cities(name, country);

-- Updated At Triggers

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON public.teams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_matches_updated_at BEFORE UPDATE ON public.matches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Sample Data (Optional - for testing)

-- Insert some sample cities
INSERT INTO public.cities (name, country, region, latitude, longitude) VALUES
('Casablanca', 'Morocco', 'Grand Casablanca', 33.5731104, -7.5898434),
('Rabat', 'Morocco', 'Rabat-Salé-Zemmour-Zaër', 34.020882, -6.8416502),
('Marrakech', 'Morocco', 'Marrakech-Tensift-Al Haouz', 31.6294723, -7.9810845),
('Fès', 'Morocco', 'Fès-Boulemane', 34.0331261, -5.0002825),
('Tanger', 'Morocco', 'Tanger-Tétouan', 35.7594651, -5.8339543),
('Agadir', 'Morocco', 'Souss-Massa-Draâ', 30.4277547, -9.5981072);

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Football Community App database schema created successfully!';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Configure Supabase Auth settings';
    RAISE NOTICE '2. Set up Edge Functions (see supabase_backend_architecture_plan.md)';
    RAISE NOTICE '3. Test the schema with sample data';
END $$;