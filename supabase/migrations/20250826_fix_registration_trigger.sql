-- Fix the registration trigger function to handle phone number and metadata properly

-- Update the trigger function to handle full_name and phone from user metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (user_id, email, full_name, phone, role, client_status)
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
        NEW.raw_user_meta_data ->> 'phone',
        'client',
        'active'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add RLS policy to allow profile creation during registration
CREATE POLICY "Allow profile creation during registration" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Also add policy for registration without auth context (for trigger)
CREATE POLICY "Allow system to create profiles" ON public.profiles
    FOR INSERT WITH CHECK (true);

-- Drop the overly permissive policy if it exists
DROP POLICY IF EXISTS "Allow system to create profiles" ON public.profiles;

-- Create a more secure policy for automatic profile creation
CREATE POLICY "Allow automatic profile creation" ON public.profiles
    FOR INSERT WITH CHECK (
        -- Allow if the current auth user matches the user_id being inserted
        auth.uid() = user_id OR
        -- Or if this is a system operation (trigger context)
        current_setting('role') = 'postgres'
    );
