-- Storage Setup for Rwanda Shop Documents
-- Run this script in your Supabase SQL Editor after running database-setup.sql
-- IMPORTANT: Make sure database-setup.sql has been executed first!

-- Check if profiles table exists (this should return 1 if setup was done correctly)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
        RAISE EXCEPTION 'ERROR: public.profiles table does not exist. Please run database-setup.sql first!';
    END IF;
END
$$;

-- Create storage bucket for documents
INSERT INTO storage.buckets (id, name, public) 
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for documents bucket
CREATE POLICY "Allow authenticated users to view documents" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'documents' AND auth.role() = 'authenticated');

CREATE POLICY "Allow admins to upload documents" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'documents' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Allow admins to update documents" 
ON storage.objects FOR UPDATE 
USING (
  bucket_id = 'documents' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Allow admins to delete documents" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'documents' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);
