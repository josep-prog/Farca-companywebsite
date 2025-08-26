-- DEPLOYMENT READINESS CHECK FOR RWANDA SHOP
-- Run this to verify everything is ready for production deployment on Render

-- ================================
-- STEP 1: VERIFY ALL TABLES EXIST
-- ================================

SELECT 'CHECKING DATABASE TABLES...' as check_type;

SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('profiles', 'products', 'orders', 'order_items', 'documents') 
        THEN '✓ Required table exists'
        ELSE '? Additional table'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ================================
-- STEP 2: VERIFY SAMPLE DATA EXISTS
-- ================================

SELECT 'CHECKING SAMPLE DATA...' as check_type;

-- Check products
SELECT 
    COUNT(*) as product_count,
    CASE 
        WHEN COUNT(*) >= 6 THEN '✓ Sample products loaded'
        WHEN COUNT(*) > 0 THEN '⚠ Some products exist'
        ELSE '✗ No products found'
    END as products_status
FROM public.products;

-- Check if we have products in RWF currency
SELECT 
    currency,
    COUNT(*) as count,
    MIN(price) as min_price,
    MAX(price) as max_price
FROM public.products 
GROUP BY currency;

-- ================================
-- STEP 3: VERIFY USER MANAGEMENT SETUP
-- ================================

SELECT 'CHECKING USER MANAGEMENT...' as check_type;

-- Check if user registration trigger exists
SELECT 
    trigger_name,
    event_object_table,
    '✓ Auto-profile creation ready' as status
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- Check admin users
SELECT 
    COUNT(*) as admin_count,
    CASE 
        WHEN COUNT(*) >= 1 THEN '✓ Admin user(s) exist'
        WHEN COUNT(*) = 0 THEN '⚠ No admin users yet - run create-admin.sql'
    END as admin_status
FROM public.profiles 
WHERE role = 'admin';

-- Show admin users if they exist
SELECT email, full_name, created_at 
FROM public.profiles 
WHERE role = 'admin';

-- ================================
-- STEP 4: VERIFY ROW LEVEL SECURITY
-- ================================

SELECT 'CHECKING SECURITY POLICIES...' as check_type;

-- Check RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity THEN '✓ RLS enabled'
        ELSE '✗ RLS disabled'
    END as security_status
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Count policies per table
SELECT 
    schemaname,
    tablename,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;

-- ================================
-- STEP 5: VERIFY STORAGE BUCKETS
-- ================================

SELECT 'CHECKING STORAGE BUCKETS...' as check_type;

-- Check storage buckets
SELECT 
    id as bucket_id,
    name,
    public,
    file_size_limit,
    CASE 
        WHEN id IN ('product-images', 'documents', 'avatars', 'order-attachments')
        THEN '✓ Required bucket'
        ELSE '? Additional bucket'
    END as bucket_status
FROM storage.buckets 
ORDER BY id;

-- Count storage policies
SELECT 
    COUNT(*) as storage_policy_count,
    CASE 
        WHEN COUNT(*) >= 12 THEN '✓ Storage policies configured'
        ELSE '⚠ Missing storage policies'
    END as storage_policies_status
FROM pg_policies 
WHERE schemaname = 'storage';

-- ================================
-- STEP 6: VERIFY FOREIGN KEY RELATIONSHIPS
-- ================================

SELECT 'CHECKING RELATIONSHIPS...' as check_type;

-- Check foreign key constraints
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    '✓ Relationship configured' as status
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- ================================
-- STEP 7: DEPLOYMENT READINESS SUMMARY
-- ================================

SELECT 'DEPLOYMENT READINESS SUMMARY' as check_type;

WITH readiness_check AS (
    SELECT 
        -- Check tables
        (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('profiles', 'products', 'orders', 'order_items', 'documents')) = 5 as all_tables_exist,
        
        -- Check sample data
        (SELECT COUNT(*) FROM public.products) >= 6 as sample_products_exist,
        
        -- Check admin user
        (SELECT COUNT(*) FROM public.profiles WHERE role = 'admin') >= 1 as admin_exists,
        
        -- Check RLS enabled
        (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true) = 5 as rls_enabled,
        
        -- Check storage buckets
        (SELECT COUNT(*) FROM storage.buckets WHERE id IN ('product-images', 'documents', 'avatars', 'order-attachments')) >= 3 as buckets_exist,
        
        -- Check user trigger
        (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') = 1 as user_trigger_exists
)
SELECT 
    all_tables_exist,
    sample_products_exist,
    admin_exists,
    rls_enabled,
    buckets_exist,
    user_trigger_exists,
    CASE 
        WHEN all_tables_exist AND sample_products_exist AND admin_exists AND rls_enabled AND buckets_exist AND user_trigger_exists
        THEN '🚀 READY FOR DEPLOYMENT!'
        ELSE '⚠ NEEDS ATTENTION - See details above'
    END as deployment_status
FROM readiness_check;

-- Final counts for verification
SELECT 'FINAL DATA VERIFICATION' as check_type;
SELECT COUNT(*) as total_tables FROM information_schema.tables WHERE table_schema = 'public';
SELECT COUNT(*) as total_products FROM public.products;
SELECT COUNT(*) as total_profiles FROM public.profiles;
SELECT COUNT(*) as total_orders FROM public.orders;
SELECT COUNT(*) as total_documents FROM public.documents;
SELECT COUNT(*) as total_storage_buckets FROM storage.buckets;
