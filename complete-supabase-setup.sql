-- COMPLETE SUPABASE SETUP FOR RWANDA SHOP
-- Copy and paste this ENTIRE script into your Supabase SQL Editor and run it all at once
-- This script handles everything in the correct order

-- First, let's check if we're in Supabase by looking for auth schema
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') THEN
        RAISE EXCEPTION 'This script is designed for Supabase. Auth schema not found.';
    END IF;
    RAISE NOTICE 'Supabase detected. Proceeding with setup...';
END
$$;

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

-- Create documents table
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    file_type TEXT,
    uploaded_by UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================
-- STEP 2: CREATE TRIGGERS
-- ================================

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
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
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at 
    BEFORE UPDATE ON public.products 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at 
    BEFORE UPDATE ON public.orders 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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

-- RLS Policies for profiles
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all profiles" ON public.profiles
    FOR SELECT USING (
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

CREATE POLICY "Admins can view all orders" ON public.orders
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- RLS Policies for order_items (FIXED - no more ambiguous column reference)
CREATE POLICY "Users can view own order items" ON public.order_items
    FOR SELECT USING (
        order_id IN (
            SELECT o.id FROM public.orders o
            JOIN public.profiles p ON o.client_id = p.id
            WHERE p.user_id = auth.uid()
        )
    );

-- RLS Policies for documents
CREATE POLICY "Anyone can view public documents" ON public.documents
    FOR SELECT USING (is_public = true);

CREATE POLICY "Users can view own documents" ON public.documents
    FOR SELECT USING (
        uploaded_by IN (
            SELECT id FROM public.profiles WHERE user_id = auth.uid()
        )
    );

-- ================================
-- STEP 5: CREATE USER REGISTRATION TRIGGER
-- ================================

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (user_id, email, full_name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user registration
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ================================
-- STEP 6: INSERT SAMPLE DATA
-- ================================

-- Insert sample products
INSERT INTO public.products (name, description, price, currency, stock_quantity, is_active) VALUES
('Rwandan Premium Coffee', 'High-quality arabica coffee beans from the hills of Rwanda. Rich flavor with notes of chocolate and fruit.', 25000, 'RWF', 50, true),
('Traditional Rwandan Basket', 'Handwoven basket made by local artisans using traditional techniques and natural materials.', 15000, 'RWF', 20, true),
('Rwandan Honey', 'Pure, natural honey harvested from Rwandan bee farms. Perfect for tea or spreading on bread.', 8000, 'RWF', 30, true),
('Ubushyuhe Hot Sauce', 'Spicy traditional Rwandan hot sauce made from fresh peppers and local spices.', 5000, 'RWF', 100, true),
('Rwandan Tea', 'Premium black tea grown in the highlands of Rwanda. Full-bodied with a smooth finish.', 12000, 'RWF', 75, true),
('Handicraft Wood Carving', 'Beautiful wooden sculpture carved by skilled Rwandan artisans depicting traditional motifs.', 35000, 'RWF', 10, true)
ON CONFLICT DO NOTHING;

-- ================================
-- STEP 7: SETUP STORAGE BUCKET
-- ================================

-- Create storage bucket for documents
INSERT INTO storage.buckets (id, name, public) 
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for documents bucket
CREATE POLICY "Allow authenticated users to view documents" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'documents' AND auth.role() = 'authenticated');

CREATE POLICY "Allow admins to upload documents" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'documents' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Allow admins to update documents" 
ON storage.objects FOR UPDATE 
USING (
  bucket_id = 'documents' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Allow admins to delete documents" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'documents' AND 
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);

-- ================================
-- STEP 8: VERIFICATION
-- ================================

-- Verify setup completion
SELECT 'DATABASE SETUP COMPLETE!' as status;

-- Show created tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Show sample products count
SELECT COUNT(*) as sample_products_count FROM public.products;

-- Show storage bucket
SELECT name, public FROM storage.buckets WHERE id = 'documents';

-- Show next steps
SELECT 'NEXT: Register a user, then run create-admin.sql to complete setup!' as next_step;

-- ================================
-- NEXT STEPS (MANUAL)
-- ================================

/*
NEXT STEPS TO COMPLETE SETUP:

1. Register your first user through your application
2. Then run this command to make them admin:
   UPDATE public.profiles SET role = 'admin' WHERE email = 'nishimwejoseph26@gmail.com';

3. After creating admin, you can insert sample documents:
   INSERT INTO public.documents (title, description, file_url, file_type, uploaded_by, is_public) VALUES
   ('Product Catalog 2024', 'Complete catalog of all available Rwandan products', 'https://www.africau.edu/images/default/sample.pdf', 'application/pdf', (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1), true);
*/
