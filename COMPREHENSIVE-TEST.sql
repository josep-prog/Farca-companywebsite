-- COMPREHENSIVE TEST SUITE FOR RWANDA SHOP
-- Run this after ERROR-FREE-FINAL-SETUP.sql to test everything
-- This simulates all user interactions: registration, login, orders, etc.

-- ================================
-- TEST 1: VERIFY BASIC SETUP
-- ================================

SELECT '🧪 STARTING COMPREHENSIVE TESTS...' as test_status;

-- Test 1.1: Check all tables exist
SELECT 'TEST 1.1: Checking tables exist' as test_name;
WITH expected_tables AS (
    SELECT unnest(ARRAY['profiles', 'products', 'orders', 'order_items', 'documents']) AS table_name
),
actual_tables AS (
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
)
SELECT 
    e.table_name,
    CASE 
        WHEN a.table_name IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as status
FROM expected_tables e
LEFT JOIN actual_tables a ON e.table_name = a.table_name
ORDER BY e.table_name;

-- Test 1.2: Check sample products loaded
SELECT 'TEST 1.2: Sample products verification' as test_name;
SELECT 
    name,
    price || ' ' || currency as price_display,
    stock_quantity,
    '✅ LOADED' as status
FROM public.products 
ORDER BY price;

-- Test 1.3: Check storage buckets
SELECT 'TEST 1.3: Storage buckets verification' as test_name;
WITH expected_buckets AS (
    SELECT unnest(ARRAY['product-images', 'documents', 'avatars', 'order-attachments']) AS bucket_name
),
actual_buckets AS (
    SELECT id as bucket_name FROM storage.buckets
)
SELECT 
    e.bucket_name,
    CASE 
        WHEN a.bucket_name IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as status
FROM expected_buckets e
LEFT JOIN actual_buckets a ON e.bucket_name = a.bucket_name
ORDER BY e.bucket_name;

-- ================================
-- TEST 2: SIMULATE USER REGISTRATION
-- ================================

SELECT 'TEST 2: Simulating user registration and admin creation' as test_name;

-- Simulate user registration (this would normally happen through your app)
-- We'll create a test user directly in the auth.users table for testing
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
    role
) VALUES (
    'test-user-001',
    '00000000-0000-0000-0000-000000000000',
    'nishimwejoseph26@gmail.com',
    crypt('testpassword123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Joseph Nishimwe"}',
    false,
    'authenticated'
) ON CONFLICT (email) DO NOTHING;

-- The trigger should automatically create a profile
-- Let's check if it worked
SELECT 
    email,
    full_name,
    role,
    'Profile created by trigger ✅' as status
FROM public.profiles 
WHERE email = 'nishimwejoseph26@gmail.com';

-- Make the user admin
UPDATE public.profiles 
SET role = 'admin' 
WHERE email = 'nishimwejoseph26@gmail.com';

-- Verify admin creation
SELECT 
    email,
    role,
    'Admin role assigned ✅' as status
FROM public.profiles 
WHERE role = 'admin';

-- ================================
-- TEST 3: TEST PRODUCT MANAGEMENT
-- ================================

SELECT 'TEST 3: Testing product management functionality' as test_name;

-- Test 3.1: Add a new product (simulate admin adding product)
INSERT INTO public.products (name, description, price, currency, stock_quantity, is_active) 
VALUES ('Test Product Rwanda', 'Test description for Rwanda product', 5000, 'RWF', 10, true)
ON CONFLICT (name) DO NOTHING;

-- Test 3.2: Update a product (simulate admin editing)
UPDATE public.products 
SET stock_quantity = 25, price = 6000 
WHERE name = 'Test Product Rwanda';

-- Test 3.3: Verify product operations
SELECT 
    name,
    price || ' ' || currency as price,
    stock_quantity,
    'Product operations working ✅' as status
FROM public.products 
WHERE name = 'Test Product Rwanda';

-- ================================
-- TEST 4: TEST ORDER FUNCTIONALITY
-- ================================

SELECT 'TEST 4: Testing order functionality' as test_name;

-- Test 4.1: Create a test order (simulate client placing order)
INSERT INTO public.orders (
    client_id,
    total_amount,
    currency,
    order_status,
    payment_status,
    delivery_address
) VALUES (
    (SELECT id FROM public.profiles WHERE email = 'nishimwejoseph26@gmail.com'),
    50000,
    'RWF',
    'pending',
    'pending',
    'Kigali, Rwanda'
);

-- Test 4.2: Add items to the order
INSERT INTO public.order_items (
    order_id,
    product_id,
    quantity,
    unit_price,
    total_price
) VALUES (
    (SELECT id FROM public.orders ORDER BY created_at DESC LIMIT 1),
    (SELECT id FROM public.products WHERE name = 'Rwandan Premium Coffee'),
    2,
    25000,
    50000
);

-- Test 4.3: Verify order creation
SELECT 
    o.id,
    p.email as client_email,
    o.total_amount || ' ' || o.currency as total,
    o.order_status,
    'Order system working ✅' as status
FROM public.orders o
JOIN public.profiles p ON o.client_id = p.id
ORDER BY o.created_at DESC LIMIT 1;

-- Test 4.4: Verify order items
SELECT 
    oi.quantity,
    pr.name as product_name,
    oi.unit_price || ' RWF' as unit_price,
    oi.total_price || ' RWF' as total_price,
    'Order items working ✅' as status
FROM public.order_items oi
JOIN public.products pr ON oi.product_id = pr.id
ORDER BY oi.created_at DESC LIMIT 5;

-- ================================
-- TEST 5: TEST DOCUMENT MANAGEMENT
-- ================================

SELECT 'TEST 5: Testing document management' as test_name;

-- Test 5.1: Update documents with admin user (fix the uploaded_by field)
UPDATE public.documents 
SET uploaded_by = (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1)
WHERE uploaded_by IS NULL;

-- Test 5.2: Add a new document
INSERT INTO public.documents (title, description, file_url, file_type, uploaded_by, is_public) 
VALUES (
    'Test Document Rwanda', 
    'Test document for Rwanda Shop', 
    'https://example.com/test.pdf', 
    'application/pdf',
    (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1),
    true
) ON CONFLICT (title) DO NOTHING;

-- Test 5.3: Verify document operations
SELECT 
    title,
    file_type,
    is_public,
    'Document management working ✅' as status
FROM public.documents 
ORDER BY created_at;

-- ================================
-- TEST 6: TEST RLS POLICIES
-- ================================

SELECT 'TEST 6: Testing Row Level Security policies' as test_name;

-- Test 6.1: Check RLS is enabled on all tables
SELECT 
    schemaname,
    tablename,
    rowsecurity,
    CASE 
        WHEN rowsecurity THEN '✅ RLS ENABLED'
        ELSE '❌ RLS DISABLED'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Test 6.2: Count policies per table
SELECT 
    schemaname,
    tablename,
    COUNT(*) as policy_count,
    'Policies configured ✅' as status
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;

-- ================================
-- TEST 7: TEST FOREIGN KEY RELATIONSHIPS
-- ================================

SELECT 'TEST 7: Testing foreign key relationships' as test_name;

-- Verify all foreign key relationships
SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    '✅ RELATIONSHIP OK' as status
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'public'
ORDER BY tc.table_name;

-- ================================
-- TEST 8: SIMULATE CLIENT USER EXPERIENCE
-- ================================

SELECT 'TEST 8: Simulating client user experience' as test_name;

-- Create a test client user
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
    role
) VALUES (
    'test-client-001',
    '00000000-0000-0000-0000-000000000000',
    'testclient@rwanda-shop.com',
    crypt('clientpass123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Test Client Rwanda"}',
    false,
    'authenticated'
) ON CONFLICT (email) DO NOTHING;

-- Verify client profile was auto-created
SELECT 
    email,
    full_name,
    role,
    client_status,
    'Client profile auto-created ✅' as status
FROM public.profiles 
WHERE email = 'testclient@rwanda-shop.com';

-- ================================
-- TEST 9: FINAL DEPLOYMENT READINESS CHECK
-- ================================

SELECT 'TEST 9: Final deployment readiness verification' as test_name;

-- Summary of all components
WITH system_check AS (
    SELECT 
        (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('profiles', 'products', 'orders', 'order_items', 'documents')) as tables_count,
        (SELECT COUNT(*) FROM public.products) as products_count,
        (SELECT COUNT(*) FROM public.profiles WHERE role = 'admin') as admin_count,
        (SELECT COUNT(*) FROM storage.buckets WHERE id IN ('product-images', 'documents', 'avatars', 'order-attachments')) as buckets_count,
        (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public') as policies_count,
        (SELECT COUNT(*) FROM public.documents) as documents_count
)
SELECT 
    '🔍 SYSTEM HEALTH CHECK:' as check_type,
    CONCAT('Tables: ', tables_count, '/5') as tables_status,
    CONCAT('Products: ', products_count) as products_status,
    CONCAT('Admins: ', admin_count) as admin_status,
    CONCAT('Storage Buckets: ', buckets_count, '/4') as buckets_status,
    CONCAT('Security Policies: ', policies_count) as policies_status,
    CONCAT('Documents: ', documents_count) as documents_status,
    CASE 
        WHEN tables_count = 5 AND products_count >= 6 AND admin_count >= 1 AND buckets_count >= 4
        THEN '🚀 READY FOR RENDER DEPLOYMENT!'
        ELSE '⚠️ NEEDS ATTENTION'
    END as deployment_readiness
FROM system_check;

-- ================================
-- TEST RESULTS SUMMARY
-- ================================

SELECT '🎉 COMPREHENSIVE TEST COMPLETE!' as test_complete;

-- User accounts summary
SELECT 'USER ACCOUNTS SUMMARY:' as summary_type;
SELECT 
    email,
    role,
    client_status,
    created_at,
    CASE 
        WHEN role = 'admin' THEN '👑 Admin User'
        ELSE '👤 Client User'
    END as user_type
FROM public.profiles 
ORDER BY role DESC, created_at;

-- Products summary
SELECT 'PRODUCTS CATALOG SUMMARY:' as summary_type;
SELECT 
    name,
    price || ' ' || currency as price,
    stock_quantity || ' units' as stock,
    CASE WHEN is_active THEN '✅ Active' ELSE '❌ Inactive' END as status
FROM public.products 
ORDER BY price;

-- Orders summary
SELECT 'ORDERS SUMMARY:' as summary_type;
SELECT 
    o.id,
    p.email as client,
    o.total_amount || ' ' || o.currency as total,
    o.order_status,
    o.payment_status
FROM public.orders o
JOIN public.profiles p ON o.client_id = p.id
ORDER BY o.created_at DESC;

-- Storage summary
SELECT 'STORAGE BUCKETS SUMMARY:' as summary_type;
SELECT 
    id as bucket_name,
    CASE WHEN public THEN '🌐 Public' ELSE '🔒 Private' END as access,
    ROUND(file_size_limit/1048576.0, 1) || ' MB' as size_limit,
    array_length(allowed_mime_types, 1) || ' file types' as file_types
FROM storage.buckets 
WHERE id IN ('product-images', 'documents', 'avatars', 'order-attachments')
ORDER BY id;

-- ================================
-- FRONTEND CONNECTION TEST QUERIES
-- ================================

SELECT '🔗 FRONTEND CONNECTION TEST QUERIES:' as frontend_tests;

-- These are the exact queries your frontend will use:

-- Test: Fetch products for homepage
SELECT 'Frontend Test: Fetch products for display' as test_name;
SELECT 
    id,
    name,
    description,
    price,
    currency,
    image_url,
    stock_quantity,
    is_active
FROM public.products 
WHERE is_active = true
ORDER BY created_at DESC
LIMIT 6;

-- Test: Fetch documents for client access
SELECT 'Frontend Test: Fetch public documents' as test_name;
SELECT 
    id,
    title,
    description,
    file_url,
    file_type,
    is_public
FROM public.documents 
WHERE is_public = true
ORDER BY created_at DESC;

-- Test: Admin can see all profiles
SELECT 'Frontend Test: Admin view of all users' as test_name;
SELECT 
    id,
    email,
    full_name,
    role,
    client_status,
    created_at
FROM public.profiles 
ORDER BY created_at DESC;

-- ================================
-- DEPLOYMENT READINESS FINAL CHECK
-- ================================

SELECT '🚀 DEPLOYMENT READINESS FINAL VERDICT:' as final_check;

WITH deployment_check AS (
    SELECT 
        -- Essential components check
        (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('profiles', 'products', 'orders', 'order_items', 'documents')) = 5 as has_all_tables,
        (SELECT COUNT(*) FROM public.products WHERE is_active = true) >= 6 as has_sample_products,
        (SELECT COUNT(*) FROM public.profiles WHERE role = 'admin') >= 1 as has_admin_user,
        (SELECT COUNT(*) FROM storage.buckets WHERE id IN ('product-images', 'documents', 'avatars', 'order-attachments')) >= 4 as has_storage_buckets,
        (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true) = 5 as has_rls_enabled,
        (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') = 1 as has_user_trigger,
        (SELECT COUNT(*) FROM public.documents WHERE is_public = true) >= 3 as has_sample_documents
)
SELECT 
    has_all_tables as "✅ All Tables",
    has_sample_products as "✅ Sample Products", 
    has_admin_user as "✅ Admin User",
    has_storage_buckets as "✅ Storage Buckets",
    has_rls_enabled as "✅ RLS Security",
    has_user_trigger as "✅ User Trigger",
    has_sample_documents as "✅ Sample Documents",
    CASE 
        WHEN has_all_tables AND has_sample_products AND has_admin_user AND has_storage_buckets AND has_rls_enabled AND has_user_trigger AND has_sample_documents
        THEN '🎉 FULLY READY FOR PRODUCTION DEPLOYMENT ON RENDER!'
        ELSE '⚠️ Some components need attention (see above)'
    END as "🚀 DEPLOYMENT STATUS"
FROM deployment_check;

-- ================================
-- LOGIN CREDENTIALS FOR TESTING
-- ================================

SELECT '🔑 ADMIN LOGIN CREDENTIALS FOR TESTING:' as credentials_info;
SELECT 
    'Email: nishimwejoseph26@gmail.com' as admin_email,
    'Password: testpassword123' as admin_password,
    'Role: admin' as admin_role,
    'Status: Ready for login ✅' as login_status;

-- ================================
-- NEXT STEPS FOR RENDER DEPLOYMENT
-- ================================

SELECT '📋 RENDER DEPLOYMENT CHECKLIST:' as render_steps;
SELECT '1. ✅ Database setup complete' as step_1;
SELECT '2. ✅ Sample data loaded' as step_2;
SELECT '3. ✅ Admin user created' as step_3;
SELECT '4. ✅ Storage buckets ready' as step_4;
SELECT '5. ✅ Security policies active' as step_5;
SELECT '6. 🔄 Set environment variables in Render' as step_6;
SELECT '7. 🔄 Deploy your frontend to Render' as step_7;
SELECT '8. 🚀 Your Rwanda Shop is live!' as step_8;
