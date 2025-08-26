-- 🔑 SIMPLE: MAKE REGISTERED USER AN ADMIN
-- First register through your app, then run this
-- This just updates the role to admin

-- Check current users
SELECT 
    email,
    full_name,
    role,
    created_at
FROM public.profiles
ORDER BY created_at DESC;

-- Update the user role to admin
UPDATE public.profiles 
SET role = 'admin' 
WHERE email = 'nishimwejoseph26@gmail.com';

-- Verify the update
SELECT 
    email,
    full_name,
    role,
    'Now an admin!' as status
FROM public.profiles 
WHERE email = 'nishimwejoseph26@gmail.com';

SELECT '🎉 User is now an admin!' as result;
