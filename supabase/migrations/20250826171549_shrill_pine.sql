/*
  # Rwanda E-commerce Platform Database Schema

  1. Tables Created:
    - `profiles` - User profiles with role management (admin/client)
    - `products` - Product catalog with pricing in RWF
    - `orders` - Order management with status tracking
    - `order_items` - Individual items within orders
    - `documents` - Document management for client access

  2. Security:
    - Enable RLS on all tables
    - Policies for role-based access (admin vs client)
    - Secure document access controls

  3. Features:
    - Real-time updates for products and orders
    - Status tracking for orders and deliveries
    - Client account management (active/inactive, block/unblock)
*/

-- Create enum types
CREATE TYPE user_role AS ENUM ('admin', 'client');
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded');
CREATE TYPE client_status AS ENUM ('active', 'inactive', 'blocked');

-- Profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text NOT NULL,
  phone text,
  role user_role DEFAULT 'client',
  client_status client_status DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  price decimal(10,2) NOT NULL,
  currency text DEFAULT 'RWF',
  image_url text,
  stock_quantity integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  total_amount decimal(10,2) NOT NULL,
  currency text DEFAULT 'RWF',
  order_status order_status DEFAULT 'pending',
  payment_status payment_status DEFAULT 'pending',
  delivery_address text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE CASCADE,
  quantity integer NOT NULL DEFAULT 1,
  unit_price decimal(10,2) NOT NULL,
  total_price decimal(10,2) NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Documents table
CREATE TABLE IF NOT EXISTS documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  file_url text NOT NULL,
  file_type text,
  uploaded_by uuid REFERENCES profiles(id) ON DELETE CASCADE,
  is_public boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can view all profiles"
  ON profiles FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- RLS Policies for products
CREATE POLICY "Anyone can view active products"
  ON products FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "Admins can manage products"
  ON products FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- RLS Policies for orders
CREATE POLICY "Clients can view own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (
    client_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Clients can create own orders"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (
    client_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all orders"
  ON orders FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- RLS Policies for order_items
CREATE POLICY "Users can view own order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    order_id IN (
      SELECT o.id FROM orders o
      JOIN profiles p ON o.client_id = p.id
      WHERE p.user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can insert own order items"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    order_id IN (
      SELECT o.id FROM orders o
      JOIN profiles p ON o.client_id = p.id
      WHERE p.user_id = auth.uid()
    )
  );

-- RLS Policies for documents
CREATE POLICY "Anyone can view public documents"
  ON documents FOR SELECT
  TO authenticated
  USING (is_public = true);

CREATE POLICY "Admins can manage documents"
  ON documents FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- Insert sample data
INSERT INTO profiles (user_id, email, full_name, role) VALUES
  ('00000000-0000-0000-0000-000000000000', 'admin@rwanda-shop.com', 'Admin User', 'admin');

INSERT INTO products (name, description, price, image_url, stock_quantity) VALUES
  ('Rwandan Coffee Premium', 'High-quality Arabica coffee from the hills of Rwanda', 25000, 'https://images.pexels.com/photos/1695052/pexels-photo-1695052.jpeg', 50),
  ('Traditional Basket', 'Handwoven traditional Rwandan basket (Agaseke)', 15000, 'https://images.pexels.com/photos/5668858/pexels-photo-5668858.jpeg', 30),
  ('Rwanda Tea Selection', 'Premium black tea from Rwanda plantations', 18000, 'https://images.pexels.com/photos/1638280/pexels-photo-1638280.jpeg', 40);