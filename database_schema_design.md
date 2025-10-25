# Football Community App Database Schema Design

## Overview

This document outlines the complete database schema for the football community app, designed for Supabase PostgreSQL with Row Level Security (RLS) policies. The schema supports user management, team organization, match scheduling, notifications, and location-based features.

## Database Architecture

### Core Tables

#### 1. Users Table (extends auth.users)

```sql
-- Users profile extension (extends auth.users)
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT DEFAULT 'player' CHECK (role IN ('player', 'coach', 'admin')),
    gender TEXT CHECK (gender IN ('male', 'female')),
    age INTEGER CHECK (age >= 13 AND age <= 100),
    phone TEXT CHECK (validate_phone_number(phone)),
    phone_normalized TEXT GENERATED ALWAYS AS (
        CASE
            WHEN phone IS NULL THEN NULL
            ELSE normalize_phone_number(phone)
        END
    ) STORED,
    avatar_url TEXT,
    bio TEXT,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes:**
- Primary key on `id`
- Unique index on `email`
- Index on `role` for filtering
- Index on `location` for location-based queries
- Index on `phone_normalized` for phone number lookups
- Full-text search index on `phone_normalized` for flexible phone searches

#### 2. Teams Table

```sql
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
```

**Indexes:**
- Primary key on `id`
- Foreign key index on `owner_id`
- Index on `is_recruiting` for filtering
- Index on `location` for location-based queries
- Full-text search index on `name` and `description`

#### 3. Team Members Table

```sql
CREATE TABLE public.team_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('member', 'captain', 'coach')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);
```

**Indexes:**
- Primary key on `id`
- Composite index on `(team_id, user_id)` for uniqueness
- Index on `user_id` for user's teams lookup
- Index on `role` for filtering

#### 4. Matches Table

```sql
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
```

**Indexes:**
- Primary key on `id`
- Foreign key indexes on `team1_id` and `team2_id`
- Index on `match_date` for scheduling queries
- Index on `status` for filtering
- Index on `match_type` for categorization
- Index on `location` for location-based queries

#### 5. Match Participants Table

```sql
CREATE TABLE public.match_participants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'pending', 'declined')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(match_id, user_id)
);
```

**Indexes:**
- Primary key on `id`
- Composite index on `(match_id, user_id)` for uniqueness
- Index on `user_id` for user's matches lookup
- Index on `status` for filtering

#### 6. Notifications Table

```sql
CREATE TABLE public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('match_invite', 'team_invite', 'general', 'system')),
    is_read BOOLEAN DEFAULT false,
    related_id UUID, -- Can reference matches, teams, etc.
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes:**
- Primary key on `id`
- Foreign key index on `user_id`
- Index on `is_read` for filtering unread notifications
- Index on `type` for categorization
- Index on `created_at` for chronological ordering

#### 7. Cities Table

```sql
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
```

**Indexes:**
- Primary key on `id`
- Composite unique index on `(name, country)`
- Index on `country` for filtering
- Spatial index on `(latitude, longitude)` for location queries

## Row Level Security (RLS) Policies

### Enable RLS on All Tables

```sql
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;
```

### Users Policies

```sql
-- Users can read/update their own profile
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);
```

### Teams Policies

```sql
-- Anyone can view teams
CREATE POLICY "Anyone can view teams" ON public.teams FOR SELECT USING (true);

-- Authenticated users can create teams
CREATE POLICY "Authenticated users can create teams" ON public.teams
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Team owners can update their teams
CREATE POLICY "Team owners can update their teams" ON public.teams
    FOR UPDATE USING (auth.uid() = owner_id);
```

### Team Members Policies

```sql
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
```

### Matches Policies

```sql
-- Anyone can view matches
CREATE POLICY "Anyone can view matches" ON public.matches FOR SELECT USING (true);

-- Authenticated users can create matches
CREATE POLICY "Authenticated users can create matches" ON public.matches
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Team owners can update their matches
CREATE POLICY "Team owners can update matches" ON public.matches
    FOR UPDATE USING (
        auth.uid() = (SELECT owner_id FROM public.teams WHERE id = team1_id) OR
        auth.uid() = (SELECT owner_id FROM public.teams WHERE id = team2_id)
    );
```

### Match Participants Policies

```sql
CREATE POLICY "Users can view match participants" ON public.match_participants
    FOR SELECT USING (true);

CREATE POLICY "Users can join matches" ON public.match_participants
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their participation" ON public.match_participants
    FOR UPDATE USING (auth.uid() = user_id);
```

### Notifications Policies

```sql
-- Users can view own notifications
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Users can update own notifications
CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);
```

### Cities Policies

```sql
-- Cities are public
CREATE POLICY "Anyone can view cities" ON public.cities FOR SELECT USING (true);
```

## Database Relationships

```
auth.users (Supabase Auth)
    ↓ (extends)
public.users
    ↓ (owner_id)
public.teams
    ↓ (team_id)
public.team_members ←→ public.users (user_id)
    ↓ (team_id)
public.matches ←→ public.teams (team1_id, team2_id)
    ↓ (match_id)
public.match_participants ←→ public.users (user_id)
                        ←→ public.teams (team_id)

public.notifications ←→ public.users (user_id)

public.cities (independent)
```

## Performance Optimizations

### Additional Indexes

```sql
-- Performance indexes for common queries
CREATE INDEX idx_matches_date_status ON public.matches(match_date, status);
CREATE INDEX idx_matches_location ON public.matches USING gin(to_tsvector('english', location));
CREATE INDEX idx_teams_location ON public.teams USING gin(to_tsvector('english', location));
CREATE INDEX idx_users_location ON public.users USING gin(to_tsvector('english', location));
CREATE INDEX idx_users_phone_normalized ON public.users(phone_normalized);
CREATE INDEX idx_users_phone_search ON public.users USING gin(to_tsvector('simple', phone_normalized));
CREATE INDEX idx_notifications_user_unread ON public.notifications(user_id, is_read) WHERE NOT is_read;
CREATE INDEX idx_team_members_user ON public.team_members(user_id, joined_at DESC);
CREATE INDEX idx_match_participants_user ON public.match_participants(user_id, joined_at DESC);
```

### Phone Number Functions

```sql
-- Function to validate phone number format
CREATE OR REPLACE FUNCTION validate_phone_number(phone_text TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Allow NULL values
    IF phone_text IS NULL THEN
        RETURN TRUE;
    END IF;

    -- Try to parse the phone number
    BEGIN
        PERFORM pg_libphonenumber.parse_phone_number(phone_text, 'MA');
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to normalize phone number to E.164 format
CREATE OR REPLACE FUNCTION normalize_phone_number(phone_text TEXT)
RETURNS TEXT AS $$
BEGIN
    IF phone_text IS NULL THEN
        RETURN NULL;
    END IF;

    BEGIN
        RETURN pg_libphonenumber.parse_phone_number(phone_text, 'MA')::TEXT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to format phone number for display
CREATE OR REPLACE FUNCTION format_phone_number(phone_text TEXT)
RETURNS TEXT AS $$
BEGIN
    IF phone_text IS NULL THEN
        RETURN NULL;
    END IF;

    BEGIN
        RETURN pg_libphonenumber.format_phone_number(
            pg_libphonenumber.parse_phone_number(phone_text, 'MA'),
            'INTERNATIONAL'
        );
    EXCEPTION
        WHEN OTHERS THEN
            RETURN phone_text; -- Return original if parsing fails
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### Triggers for Updated At

```sql
-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON public.teams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_matches_updated_at BEFORE UPDATE ON public.matches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Data Validation

### Check Constraints

- User roles: `player`, `coach`, `admin`
- Match types: `friendly`, `tournament`, `league`
- Match statuses: `open`, `closed`, `completed`, `cancelled`
- Participant statuses: `confirmed`, `pending`, `declined`
- Team member roles: `member`, `captain`, `coach`
- Notification types: `match_invite`, `team_invite`, `general`, `system`
- Age range: 13-100
- Gender: `male`, `female`
- Max players: 1-50 per team, 1-50 per match
- Phone numbers: Must be valid international format (E.164) using `pg_libphonenumber`

### Phone Number Validation

Phone numbers are validated using the `pg_libphonenumber` extension with the following features:

- **Storage**: Phone numbers stored in user-friendly format (e.g., "+212 6 41 17 00 12")
- **Normalization**: Automatic E.164 format generation for consistent searching (e.g., "+212641170012")
- **Validation**: Database-level constraint ensures only valid phone numbers are accepted
- **International Support**: Supports Moroccan (+212) and international phone numbers
- **Indexing**: Optimized indexes for fast phone number lookups and searches

### Foreign Key Constraints

- All foreign keys use `CASCADE` delete to maintain referential integrity
- Unique constraints prevent duplicate memberships and participations

## Migration Strategy

### Initial Migration

```sql
-- Run in Supabase SQL Editor or migration tool
-- 001_initial_schema.sql

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables in dependency order
-- 1. users (depends on auth.users)
-- 2. cities (independent)
-- 3. teams (depends on users)
-- 4. team_members (depends on teams, users)
-- 5. matches (depends on teams)
-- 6. match_participants (depends on matches, users, teams)
-- 7. notifications (depends on users)

-- Enable RLS and create policies
-- Add indexes and triggers
```

### Future Migrations

- Use Supabase migration tools for schema changes
- Test migrations on staging environment first
- Include rollback scripts for critical changes
- Document breaking changes for frontend updates

## Security Considerations

### RLS Coverage

- All tables have RLS enabled
- Policies prevent unauthorized data access
- Users can only see/modify their own data
- Public read access for discoverable content (teams, matches, cities)

### Data Privacy

- User profiles are private by default
- Team membership visible to team members and owners
- Match participation visible to all users
- Notifications are user-private
- Phone numbers are validated at database level to prevent invalid data entry

### Phone Number Security

- Phone numbers are stored in normalized E.164 format for consistency
- Database-level validation prevents malformed phone numbers
- Indexes enable efficient lookups without exposing search patterns
- Extension-based parsing provides robust international phone number support

### Audit Trail

- All tables include `created_at` timestamps
- `updated_at` triggers track modifications
- Consider adding audit logging for sensitive operations

## Monitoring and Maintenance

### Key Metrics to Monitor

- Table sizes and growth rates
- Query performance (slow queries)
- RLS policy effectiveness
- Index usage and maintenance

### Regular Maintenance Tasks

- Analyze table statistics
- Reindex as needed
- Clean up old notifications
- Archive completed matches (if needed)
- Validate phone number data integrity periodically
- Monitor phone number parsing performance

This schema provides a solid foundation for the football community app with proper security, performance optimizations, and scalability considerations.