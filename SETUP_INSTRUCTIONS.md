# Rwanda Shop Database Setup Instructions

## Overview
This project contains SQL scripts to set up a complete e-commerce database for a Rwanda Shop application using Supabase/PostgreSQL.

## Execution Order (CRITICAL!)

**⚠️ IMPORTANT: Execute the scripts in this exact order to avoid errors:**

### 1. First: Run `database-setup.sql`
This script creates all the core tables, policies, and sample data.

**Run this in your Supabase SQL Editor:**
```sql
-- Copy and paste the entire content of database-setup.sql
```

### 2. Second: Run `storage-setup.sql` 
This script creates storage buckets and policies for document management.

**Run this in your Supabase SQL Editor:**
```sql
-- Copy and paste the entire content of storage-setup.sql
```

### 3. Third: Create your admin user
After running both scripts above, you can create an admin user:

```sql
-- First, register a user through your application interface
-- Then run this command to make them admin:
UPDATE public.profiles 
SET role = 'admin' 
WHERE email = 'nishimwejoseph26@gmail.com';
```

## Common Errors and Solutions

### Error 1: "Column reference 'id' is ambiguous"
- **Cause**: SQL query doesn't specify which table's 'id' column to use in a JOIN
- **Solution**: ✅ Fixed in database-setup.sql (now uses `o.id` instead of `id`)

### Error 2: "Relation 'public.profiles' does not exist" 
- **Cause**: Trying to run storage-setup.sql before database-setup.sql
- **Solution**: ✅ Fixed with dependency check in storage-setup.sql
- **Prevention**: Always run database-setup.sql first!

### Error 3: UPDATE profiles fails with "relation does not exist"
- **Cause**: Trying to update profiles table before it's created
- **Solution**: Run database-setup.sql first, then your UPDATE command

## Database Schema Overview

### Tables Created:
- `profiles` - User profiles with role management (admin/client)
- `products` - Product catalog with pricing in RWF
- `orders` - Order management with status tracking  
- `order_items` - Individual items within orders
- `documents` - Document management for client access

### Key Features:
- Row Level Security (RLS) on all tables
- Role-based access control (admin vs client)
- Automatic user profile creation via triggers
- Sample data insertion
- Storage bucket for documents

## Testing Your Setup

Run these queries to verify everything is working:

```sql
-- Check if all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check if sample products were inserted
SELECT name, price, currency FROM public.products LIMIT 3;

-- Check if profiles table is ready for users
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND table_schema = 'public';
```

## Creating Admin Users

1. **Register the user** through your application's normal registration flow
2. **Update their role** to admin:
```sql
UPDATE public.profiles 
SET role = 'admin' 
WHERE email = 'your-email@example.com';
```

## Troubleshooting

If you encounter any errors:

1. **Check execution order** - database-setup.sql must be run first
2. **Clear and restart** - If needed, drop all tables and start fresh
3. **Check Supabase logs** - Look for detailed error messages in Supabase dashboard

## Sample Data Included

The setup includes:
- 6 sample Rwandan products (coffee, baskets, honey, etc.)
- 3 sample documents (catalogs, guidelines)
- Trigger function for automatic user profile creation
