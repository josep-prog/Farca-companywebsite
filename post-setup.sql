-- Post-Setup SQL Commands
-- Run these commands AFTER you have:
-- 1. Executed database-setup.sql
-- 2. Executed storage-setup.sql  
-- 3. Registered your first user through the application

-- Step 1: Create admin user
-- Replace 'nishimwejoseph26@gmail.com' with your actual admin email
UPDATE public.profiles 
SET role = 'admin' 
WHERE email = 'nishimwejoseph26@gmail.com';

-- Verify admin user was created
SELECT email, role, created_at 
FROM public.profiles 
WHERE role = 'admin';

-- Step 2: Insert sample documents (now that admin user exists)
INSERT INTO public.documents (title, description, file_url, file_type, uploaded_by, is_public) VALUES
('Product Catalog 2024', 'Complete catalog of all available Rwandan products with detailed descriptions and pricing.', 'https://www.africau.edu/images/default/sample.pdf', 'application/pdf', (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1), true),
('Shipping Guidelines', 'Important information about shipping policies and delivery procedures.', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1), true),
('Quality Standards', 'Quality assurance standards and certification information for all products.', 'https://file-examples.com/storage/fe86045ec2c75bb0a0e4b87/2017/10/file_example_PDF_1MB.pdf', 'application/pdf', (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1), true);

-- Step 3: Verify everything is working
SELECT 'Setup Complete!' as status;

-- Check all tables have been created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check sample products
SELECT COUNT(*) as product_count FROM public.products;

-- Check documents were inserted
SELECT COUNT(*) as document_count FROM public.documents;

-- Check admin user exists
SELECT email, role FROM public.profiles WHERE role = 'admin';
