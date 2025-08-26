-- 🔑 ULTRA-SIMPLE ADMIN USER CREATION
-- No ON CONFLICT clauses to avoid constraint errors
-- Run this in your Supabase SQL Editor

-- ================================
-- STEP 1: CHECK WHAT EXISTS
-- ================================

-- Check existing users first
SELECT 
    'Existing users:' as info,
    COUNT(*) as user_count
FROM auth.users;

SELECT 
    email,
    created_at
FROM auth.users
WHERE email = 'nishimwejoseph26@gmail.com';

-- Check existing profiles
SELECT 
    'Existing profiles:' as info,
    COUNT(*) as profile_count
FROM public.profiles;

-- ================================
-- STEP 2: CREATE USER SIMPLE WAY
-- ================================

-- Delete existing user first (if exists) to avoid conflicts
DELETE FROM public.profiles WHERE email = 'nishimwejoseph26@gmail.com';
DELETE FROM auth.users WHERE email = 'nishimwejoseph26@gmail.com';

-- Create fresh auth user
INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    role,
    aud
) VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    'nishimwejoseph26@gmail.com',
    crypt('admin123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Joseph Nishimwe"}',
    'authenticated',
    'authenticated'
);

-- Create corresponding profile
INSERT INTO public.profiles (
    user_id,
    email,
    full_name,
    role
) VALUES (
    (SELECT id FROM auth.users WHERE email = 'nishimwejoseph26@gmail.com'),
    'nishimwejoseph26@gmail.com',
    'Joseph Nishimwe',
    'admin'
);

-- ================================
-- STEP 3: VERIFY CREATION
-- ================================

SELECT '🎉 Admin user created successfully!' as status;

-- Show the created user
SELECT 
    u.email,
    u.email_confirmed_at IS NOT NULL as email_confirmed,
    p.role,
    'Ready for login' as status
FROM auth.users u
JOIN public.profiles p ON u.id = p.user_id
WHERE u.email = 'nishimwejoseph26@gmail.com';

SELECT 'Login with: nishimwejoseph26@gmail.com / admin123' as credentials;
