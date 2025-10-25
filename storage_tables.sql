-- Storage usage tracking tables for Supabase
-- Run this in your Supabase SQL editor

-- Create user storage usage table
CREATE TABLE public.user_storage_usage (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    used_bytes BIGINT DEFAULT 0 CHECK (used_bytes >= 0),
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Create team storage usage table
CREATE TABLE public.team_storage_usage (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    used_bytes BIGINT DEFAULT 0 CHECK (used_bytes >= 0),
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(team_id)
);

-- Enable RLS
ALTER TABLE public.user_storage_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_storage_usage ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user storage usage
CREATE POLICY "Users can view their own storage usage" ON public.user_storage_usage
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own storage usage" ON public.user_storage_usage
    FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for team storage usage
CREATE POLICY "Team members can view team storage usage" ON public.team_storage_usage
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.teams
            WHERE id = team_id AND owner_id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM public.team_members
            WHERE team_id = team_storage_usage.team_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Team owners can update team storage usage" ON public.team_storage_usage
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.teams
            WHERE id = team_id AND owner_id = auth.uid()
        )
    );

-- Function to update user storage usage
CREATE OR REPLACE FUNCTION update_user_storage_usage(p_user_id UUID, p_bytes_delta BIGINT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.user_storage_usage (user_id, used_bytes, last_updated)
    VALUES (p_user_id, GREATEST(0, p_bytes_delta), NOW())
    ON CONFLICT (user_id)
    DO UPDATE SET
        used_bytes = GREATEST(0, user_storage_usage.used_bytes + p_bytes_delta),
        last_updated = NOW();
END;
$$;

-- Function to update team storage usage
CREATE OR REPLACE FUNCTION update_team_storage_usage(p_team_id UUID, p_bytes_delta BIGINT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.team_storage_usage (team_id, used_bytes, last_updated)
    VALUES (p_team_id, GREATEST(0, p_bytes_delta), NOW())
    ON CONFLICT (team_id)
    DO UPDATE SET
        used_bytes = GREATEST(0, team_storage_usage.used_bytes + p_bytes_delta),
        last_updated = NOW();
END;
$$;

-- Indexes for performance
CREATE INDEX idx_user_storage_usage_user_id ON public.user_storage_usage(user_id);
CREATE INDEX idx_team_storage_usage_team_id ON public.team_storage_usage(team_id);
CREATE INDEX idx_user_storage_usage_updated ON public.user_storage_usage(last_updated DESC);
CREATE INDEX idx_team_storage_usage_updated ON public.team_storage_usage(last_updated DESC);

-- Function to clean up old storage usage records (optional maintenance)
CREATE OR REPLACE FUNCTION cleanup_storage_usage()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    -- Remove records for deleted users/teams (should be handled by CASCADE, but just in case)
    DELETE FROM public.user_storage_usage
    WHERE user_id NOT IN (SELECT id FROM public.users);

    DELETE FROM public.team_storage_usage
    WHERE team_id NOT IN (SELECT id FROM public.teams);
END;
$$;