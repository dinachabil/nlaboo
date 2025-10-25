-- Add age restriction columns to teams table
ALTER TABLE public.teams
ADD COLUMN min_age INTEGER DEFAULT 15 CHECK (min_age >= 10 AND min_age <= 60),
ADD COLUMN max_age INTEGER DEFAULT 40 CHECK (max_age >= 10 AND max_age <= 60);

-- Add constraint to ensure min_age <= max_age
ALTER TABLE public.teams
ADD CONSTRAINT check_age_range CHECK (min_age <= max_age);

-- Add index for age-based queries
CREATE INDEX idx_teams_age_range ON public.teams(min_age, max_age);

-- Update existing teams to have default age ranges
UPDATE public.teams SET min_age = 15, max_age = 40 WHERE min_age IS NULL;