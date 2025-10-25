# Supabase Database Setup

## 1. Create Tables

Run these SQL commands in your Supabase SQL Editor:

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role TEXT CHECK (role IN ('player', 'team', 'admin')) DEFAULT 'player',
    age INTEGER,
    phone TEXT,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Teams table
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Matches table
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    match_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location TEXT NOT NULL,
    status TEXT CHECK (status IN ('open', 'closed')) DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Match players table (junction table)
CREATE TABLE match_players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(match_id, user_id)
);

-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL,
    related_id UUID,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 2. Enable Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
```

## 3. Create RLS Policies

```sql
-- Users policies
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can update all users" ON users
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Teams policies
CREATE POLICY "Team owners can manage their teams" ON teams
    FOR ALL USING (auth.uid() = owner_id);

CREATE POLICY "Public can view teams" ON teams
    FOR SELECT USING (true);

-- Matches policies
CREATE POLICY "Team owners can manage their matches" ON matches
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM teams
            WHERE teams.id = matches.team_id AND teams.owner_id = auth.uid()
        )
    );

CREATE POLICY "Public can view open matches" ON matches
    FOR SELECT USING (status = 'open');

CREATE POLICY "Admins can manage all matches" ON matches
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Match players policies
CREATE POLICY "Users can manage their match participations" ON match_players
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Public can view match players" ON match_players
    FOR SELECT USING (true);

-- Notifications policies
CREATE POLICY "Users can view own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can create notifications" ON notifications
    FOR INSERT WITH CHECK (true);
```

## 4. Test the Setup

After running the SQL commands above, test that:

1. **Tables exist**: Check in Supabase Dashboard > Database > Tables
2. **RLS is enabled**: Each table should show "Row Level Security: Enabled"
3. **Policies are active**: Check the "Policies" tab for each table

## 5. Troubleshooting

If authentication still fails:

1. **Check Supabase Auth settings**: Go to Authentication > Settings and ensure Email/Password is enabled
2. **Verify RLS policies**: Make sure the policies allow users to insert their own records
3. **Check user creation**: The signup process should create both auth user and database user record

## 6. Create Storage Bucket for Avatars

Create a storage bucket for user avatars:

1. Go to Supabase Dashboard > Storage
2. Click "Create bucket"
3. Name: `avatars`
4. Make it public (uncheck "Private")

### Storage Policies for Avatars:

```sql
-- Allow authenticated users to upload their own avatars
CREATE POLICY "Users can upload their own avatars" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow public access to view avatars
CREATE POLICY "Public can view avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

-- Allow users to update their own avatars
CREATE POLICY "Users can update their own avatars" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow users to delete their own avatars
CREATE POLICY "Users can delete their own avatars" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );
```

## 8. Add Missing Columns (if table already exists)

If you already created the users table without the bio column, run this:

```sql
-- Add bio column to existing users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT;
```

## 9. Sample Data (Optional)

To test with sample data:

```sql
-- Insert a test user (after signup)
-- Note: This is handled automatically by the app during signup

-- Insert a test team
INSERT INTO teams (name, owner_id) VALUES ('Test Team', 'user-uuid-here');

-- Insert a test match
INSERT INTO matches (team_id, match_date, location)
VALUES ('team-uuid-here', '2024-12-25 15:00:00+00', 'Test Stadium');