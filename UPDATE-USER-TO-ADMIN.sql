-- Make the registered user an admin
UPDATE public.profiles 
SET role = 'admin' 
WHERE email = 'nishimwejoseph26@gmail.com';

-- Verify the update
SELECT 
    email,
    full_name,
    role,
    'User is now admin!' as status
FROM public.profiles 
WHERE email = 'nishimwejoseph26@gmail.com';
