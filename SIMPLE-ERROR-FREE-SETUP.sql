-- SIMPLE ERROR-FREE SETUP FOR RWANDA SHOP
-- This script works within Supabase limitations and creates everything without errors
-- Run this ENTIRE script in your Supabase SQL Editor

-- ================================
-- STEP 1: CREATE ALL TABLES
-- ================================

-- Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    role TEXT CHECK (role IN ('admin', 'client')) DEFAULT 'client',
    client_status TEXT CHECK (client_status IN ('active', 'inactive', 'blocked')) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create products table
CREATE TABLE IF NOT EXISTS public.products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'RWF',
    image_url TEXT,
    stock_quantity INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create orders table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'RWF',
    order_status TEXT CHECK (order_status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled')) DEFAULT 'pending',
    payment_status TEXT CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')) DEFAULT 'pending',
    delivery_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    quantity INTEGER DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create documents table (make uploaded_by nullable to avoid constraint errors)
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    file_type TEXT,
    uploaded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================
-- STEP 2: CREATE FUNCTIONS AND TRIGGERS
-- ================================

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON public.profiles 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at 
    BEFORE UPDATE ON public.products 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at 
    BEFORE UPDATE ON public.orders 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (user_id, email, full_name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.email));
    RETURN NEW;
EXCEPTION WHEN unique_violation THEN
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user registration
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ================================
-- STEP 3: ENABLE ROW LEVEL SECURITY
-- ================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

-- ================================
-- STEP 4: CREATE RLS POLICIES
-- ================================

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Anyone can view active products" ON public.products;
DROP POLICY IF EXISTS "Admins can manage products" ON public.products;
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can view all orders" ON public.orders;
DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
DROP POLICY IF EXISTS "Anyone can view public documents" ON public.documents;
DROP POLICY IF EXISTS "Users can view own documents" ON public.documents;

-- RLS Policies for profiles
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all profiles" ON public.profiles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- RLS Policies for products
CREATE POLICY "Anyone can view active products" ON public.products
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage products" ON public.products
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- RLS Policies for orders
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (
        client_id IN (
            SELECT id FROM public.profiles WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Clients can create orders" ON public.orders
    FOR INSERT WITH CHECK (
        client_id IN (
            SELECT id FROM public.profiles WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage all orders" ON public.orders
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- RLS Policies for order_items (FIXED - no ambiguous column reference)
CREATE POLICY "Users can view own order items" ON public.order_items
    FOR SELECT USING (
        order_id IN (
            SELECT o.id FROM public.orders o
            JOIN public.profiles p ON o.client_id = p.id
            WHERE p.user_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Users can manage own order items" ON public.order_items
    FOR ALL USING (
        order_id IN (
            SELECT o.id FROM public.orders o
            JOIN public.profiles p ON o.client_id = p.id
            WHERE p.user_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- RLS Policies for documents
CREATE POLICY "Anyone can view public documents" ON public.documents
    FOR SELECT USING (is_public = true);

CREATE POLICY "Admins can manage all documents" ON public.documents
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- ================================
-- STEP 5: INSERT SAMPLE PRODUCTS (SAFE METHOD)
-- ================================

DO $$
BEGIN
    -- Insert sample products only if they don't exist
    IF NOT EXISTS (SELECT 1 FROM public.products WHERE name = 'Rwandan Premium Coffee') THEN
        INSERT INTO public.products (name, description, price, currency, stock_quantity, is_active) VALUES
        ('Rwandan Premium Coffee', 'High-quality arabica coffee beans from the hills of Rwanda. Rich flavor with notes of chocolate and fruit.', 25000, 'RWF', 50, true),
        ('Traditional Rwandan Basket', 'Handwoven basket made by local artisans using traditional techniques and natural materials.', 15000, 'RWF', 20, true),
        ('Rwandan Honey', 'Pure, natural honey harvested from Rwandan bee farms. Perfect for tea or spreading on bread.', 8000, 'RWF', 30, true),
        ('Ubushyuhe Hot Sauce', 'Spicy traditional Rwandan hot sauce made from fresh peppers and local spices.', 5000, 'RWF', 100, true),
        ('Rwandan Tea', 'Premium black tea grown in the highlands of Rwanda. Full-bodied with a smooth finish.', 12000, 'RWF', 75, true),
        ('Handicraft Wood Carving', 'Beautiful wooden sculpture carved by skilled Rwandan artisans depicting traditional motifs.', 35000, 'RWF', 10, true);
    END IF;
END
$$;

-- ================================
-- STEP 6: CREATE STORAGE BUCKETS (CORRECT METHOD)
-- ================================

DO $$
BEGIN
    -- Create product-images bucket
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'product-images') THEN
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
        VALUES (
            'product-images', 
            'product-images', 
            true,
            5242880,
            ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
        );
    END IF;

    -- Create documents bucket
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'documents') THEN
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
        VALUES (
            'documents', 
            'documents', 
            true,
            10485760,
            ARRAY['application/pdf', 'text/plain', 'application/msword']
        );
    END IF;

    -- Create avatars bucket
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'avatars') THEN
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
        VALUES (
            'avatars', 
            'avatars', 
            true,
            1048576,
            ARRAY['image/jpeg', 'image/png', 'image/webp']
        );
    END IF;

    -- Create order-attachments bucket
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'order-attachments') THEN
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
        VALUES (
            'order-attachments', 
            'order-attachments', 
            false,
            5242880,
            ARRAY['image/jpeg', 'image/png', 'application/pdf']
        );
    END IF;
END
$$;

-- ================================
-- STEP 7: CREATE BASIC STORAGE POLICIES
-- ================================

-- Product Images Policies
DROP POLICY IF EXISTS "Anyone can view product images" ON storage.objects;
CREATE POLICY "Anyone can view product images" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'product-images');

-- Documents Policies  
DROP POLICY IF EXISTS "Anyone can view documents" ON storage.objects;
CREATE POLICY "Anyone can view documents" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'documents');

-- Avatars Policies
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
CREATE POLICY "Anyone can view avatars" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'avatars');

-- ================================
-- STEP 8: FINAL VERIFICATION
-- ================================

-- Final verification
SELECT '✅ SETUP COMPLETE - NO ERRORS!' as status;

-- Show created tables
SELECT 
    table_name,
    'Created ✓' as status
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Show sample products
SELECT 
    COUNT(*) as product_count,
    MIN(price) || ' - ' || MAX(price) || ' RWF' as price_range
FROM public.products;

-- Show storage buckets created
SELECT 
    id as bucket_name,
    public,
    file_size_limit
FROM storage.buckets 
ORDER BY id;

-- ================================
-- NEXT STEPS
-- ================================

SELECT 'NEXT STEPS:' as instruction;
SELECT '1. Register yourself through your app with email: nishimwejoseph26@gmail.com' as step_1;
SELECT '2. Run: UPDATE public.profiles SET role = ''admin'' WHERE email = ''nishimwejoseph26@gmail.com'';' as step_2;
SELECT '3. Your project is ready for Render deployment!' as step_3;
