-- STORAGE BUCKETS SETUP FOR RWANDA SHOP
-- Run this after complete-supabase-setup.sql is successful
-- This creates all necessary storage buckets for your e-commerce platform

-- ================================
-- STORAGE BUCKETS NEEDED FOR RWANDA SHOP
-- ================================

-- Bucket 1: Product Images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
VALUES (
    'product-images', 
    'product-images', 
    true,  -- Public so customers can view product images
    5242880,  -- 5MB limit per image
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

-- Bucket 2: Documents (PDFs, catalogs, etc.)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
VALUES (
    'documents', 
    'documents', 
    true,  -- Public so customers can download catalogs
    10485760,  -- 10MB limit per document
    ARRAY['application/pdf', 'text/plain', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
) ON CONFLICT (id) DO NOTHING;

-- Bucket 3: User Avatars/Profile Pictures
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
VALUES (
    'avatars', 
    'avatars', 
    true,  -- Public so profile pictures are visible
    1048576,  -- 1MB limit per avatar
    ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Bucket 4: Order Attachments (receipts, delivery confirmations)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
VALUES (
    'order-attachments', 
    'order-attachments', 
    false,  -- Private - only order participants can see
    5242880,  -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'application/pdf']
) ON CONFLICT (id) DO NOTHING;

-- ================================
-- STORAGE POLICIES FOR PRODUCT IMAGES
-- ================================

-- Anyone can view product images
CREATE POLICY "Anyone can view product images" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'product-images');

-- Only admins can upload product images
CREATE POLICY "Admins can upload product images" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'product-images' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

-- Only admins can update/delete product images
CREATE POLICY "Admins can manage product images" 
ON storage.objects FOR UPDATE 
USING (
  bucket_id = 'product-images' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Admins can delete product images" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'product-images' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

-- ================================
-- STORAGE POLICIES FOR DOCUMENTS
-- ================================

-- Anyone can view public documents
CREATE POLICY "Anyone can view documents" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'documents');

-- Only admins can manage documents
CREATE POLICY "Admins can upload documents" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'documents' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Admins can update documents" 
ON storage.objects FOR UPDATE 
USING (
  bucket_id = 'documents' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Admins can delete documents" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'documents' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

-- ================================
-- STORAGE POLICIES FOR AVATARS
-- ================================

-- Anyone can view avatars
CREATE POLICY "Anyone can view avatars" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'avatars');

-- Users can upload their own avatar
CREATE POLICY "Users can upload own avatar" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'avatars' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can update their own avatar
CREATE POLICY "Users can update own avatar" 
ON storage.objects FOR UPDATE 
USING (
  bucket_id = 'avatars' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own avatar
CREATE POLICY "Users can delete own avatar" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'avatars' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- ================================
-- STORAGE POLICIES FOR ORDER ATTACHMENTS
-- ================================

-- Users can view attachments for their own orders
CREATE POLICY "Users can view own order attachments" 
ON storage.objects FOR SELECT 
USING (
  bucket_id = 'order-attachments' AND 
  (
    -- User owns the order
    EXISTS (
      SELECT 1 FROM public.orders o 
      JOIN public.profiles p ON o.client_id = p.id 
      WHERE p.user_id = auth.uid() 
      AND o.id::text = (storage.foldername(name))[1]
    ) 
    -- OR user is admin
    OR EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  )
);

-- Admins can upload order attachments
CREATE POLICY "Admins can upload order attachments" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'order-attachments' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

-- Admins can manage order attachments
CREATE POLICY "Admins can manage order attachments" 
ON storage.objects FOR UPDATE 
USING (
  bucket_id = 'order-attachments' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Admins can delete order attachments" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'order-attachments' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

-- ================================
-- VERIFICATION
-- ================================

-- Show all created buckets
SELECT 
    id as bucket_name,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
ORDER BY id;

-- Verify storage policies count
SELECT 
    schemaname,
    tablename,
    policyname
FROM pg_policies 
WHERE schemaname = 'storage' 
ORDER BY tablename, policyname;

SELECT 'STORAGE SETUP COMPLETE! 4 buckets created with proper policies.' as status;
