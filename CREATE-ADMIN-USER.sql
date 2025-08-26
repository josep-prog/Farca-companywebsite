-- 🔑 CREATE ADMIN USER - SIMPLE VERSION
-- This creates the admin user you're trying to login with
-- Run this in your Supabase SQL Editor

-- ================================
-- STEP 1: CHECK EXISTING USERS
-- ================================

-- See what users already exist
SELECT 
    '👥 Checking existing auth users...' as check_type;

SELECT 
    id,
    email,
    created_at,
    email_confirmed_at IS NOT NULL as email_confirmed
FROM auth.users
ORDER BY created_at DESC;

-- Check profiles
SELECT 
    '👤 Checking existing profiles...' as check_type;

SELECT 
    p.id,
    p.user_id,
    p.email,
    p.full_name,
    p.role,
    '✅ Profile exists' as status
FROM public.profiles p
ORDER BY p.created_at DESC;

-- ================================
-- STEP 2: CREATE ADMIN USER IN AUTH
-- ================================

-- Create the auth user first
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
    is_super_admin,
    role,
    aud,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change,
    phone_change_token,
    phone_change
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
    false,
    'authenticated',
    'authenticated',
    '',
    '',
    '',
    '',
    '',
    ''
) ON CONFLICT (email) DO NOTHING;

-- ================================
-- STEP 3: CREATE ADMIN PROFILE
-- ================================

-- Create the profile for the admin user
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
) ON CONFLICT (user_id) DO UPDATE SET role = 'admin';

-- ================================
-- STEP 4: VERIFY ADMIN USER CREATED
-- ================================

SELECT 
    '🎯 Admin user verification:' as check_type;

-- Check auth user
SELECT 
    u.email,
    u.email_confirmed_at IS NOT NULL as email_confirmed,
    p.role,
    '✅ Ready for login' as status
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.user_id
WHERE u.email = 'nishimwejoseph26@gmail.com';

-- Final status
SELECT '🔑 ADMIN USER CREATED!' as completion_status;
SELECT 'Email: nishimwejoseph26@gmail.com' as login_email;
SELECT 'Password: admin123' as login_password;
SELECT 'Role: admin' as user_role;

/*
🎯 WHAT THIS SCRIPT DID:

✅ Created auth.users entry for nishimwejoseph26@gmail.com
✅ Set password to: admin123
✅ Created profiles entry with admin role
✅ Email is confirmed automatically

🔑 LOGIN CREDENTIALS:
- Email: nishimwejoseph26@gmail.com
- Password: admin123
- Role: admin

📝 NOTES:
- Try logging in with these credentials now
- The 400 auth error should be fixed
- If you prefer a different password, you can change it after logging in
*/
