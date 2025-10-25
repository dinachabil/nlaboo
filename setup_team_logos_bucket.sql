-- Setup team-logos storage bucket for Supabase
-- Run this in your Supabase SQL editor

-- Create the team-logos bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'team-logos',
  'team-logos',
  true,
  10485760, -- 10MB limit per file
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
);

-- Enable RLS on the bucket
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view all team logos (public bucket)
CREATE POLICY "Team logos are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'team-logos');

-- Policy: Team owners can upload logos for their teams
CREATE POLICY "Team owners can upload team logos" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'team-logos'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN (
      SELECT id::text FROM public.teams WHERE owner_id = auth.uid()
    )
  );

-- Policy: Team owners can update their team logos
CREATE POLICY "Team owners can update team logos" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'team-logos'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN (
      SELECT id::text FROM public.teams WHERE owner_id = auth.uid()
    )
  );

-- Policy: Team owners can delete their team logos
CREATE POLICY "Team owners can delete team logos" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'team-logos'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN (
      SELECT id::text FROM public.teams WHERE owner_id = auth.uid()
    )
  );

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_storage_team_logos_bucket
ON storage.objects(bucket_id, name)
WHERE bucket_id = 'team-logos';