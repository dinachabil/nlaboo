-- Add team_join_requests table for managing team membership requests

CREATE TABLE IF NOT EXISTS public.team_join_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    message TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(team_id, user_id, status)
);

-- Enable RLS
ALTER TABLE public.team_join_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own join requests" ON public.team_join_requests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Team owners can view requests for their teams" ON public.team_join_requests
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
    );

CREATE POLICY "Users can create join requests" ON public.team_join_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Team owners can update requests" ON public.team_join_requests
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
    );

CREATE POLICY "Users can delete own pending requests" ON public.team_join_requests
    FOR DELETE USING (auth.uid() = user_id AND status = 'pending');

-- Indexes
CREATE INDEX idx_team_join_requests_team ON public.team_join_requests(team_id, status);
CREATE INDEX idx_team_join_requests_user ON public.team_join_requests(user_id, status);
CREATE INDEX idx_team_join_requests_created ON public.team_join_requests(created_at DESC);

-- Trigger for updated_at
CREATE TRIGGER update_team_join_requests_updated_at BEFORE UPDATE ON public.team_join_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
