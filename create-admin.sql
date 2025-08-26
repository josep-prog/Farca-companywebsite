-- CREATE ADMIN USER - Run this AFTER complete-supabase-setup.sql
-- AND after registering your first user through the application

-- Step 1: Check if profiles table exists
SELECT 'Checking if setup is complete...' as status;

SELECT CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles' AND table_schema = 'public')
    THEN 'profiles table exists ✓'
    ELSE 'ERROR: profiles table not found. Run complete-supabase-setup.sql first!'
END as profiles_status;

-- Step 2: Create admin user (replace email with your actual email)
UPDATE public.profiles 
SET role = 'admin' 
WHERE email = 'nishimwejoseph26@gmail.com';

-- Step 3: Verify admin was created
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM public.profiles WHERE role = 'admin')
        THEN 'Admin user created successfully ✓'
        ELSE 'ERROR: No admin user found. Make sure you registered the user first!'
    END as admin_status;

-- Step 4: Show admin user details
SELECT email, role, full_name, created_at 
FROM public.profiles 
WHERE role = 'admin';

-- Step 5: Insert sample documents (now that admin exists)
INSERT INTO public.documents (title, description, file_url, file_type, uploaded_by, is_public) VALUES
('Product Catalog 2024', 'Complete catalog of all available Rwandan products with detailed descriptions and pricing.', 'https://www.africau.edu/images/default/sample.pdf', 'application/pdf', (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1), true),
('Shipping Guidelines', 'Important information about shipping policies and delivery procedures.', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1), true),
('Quality Standards', 'Quality assurance standards and certification information for all products.', 'https://file-examples.com/storage/fe86045ec2c75bb0a0e4b87/2017/10/file_example_PDF_1MB.pdf', 'application/pdf', (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1), true)
ON CONFLICT DO NOTHING;

-- Step 6: Final verification
SELECT 'ADMIN SETUP COMPLETE!' as final_status;
SELECT COUNT(*) as total_products FROM public.products;
SELECT COUNT(*) as total_documents FROM public.documents;
SELECT COUNT(*) as admin_users FROM public.profiles WHERE role = 'admin';
