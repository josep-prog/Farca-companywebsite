# Rwanda Shop - Complete Setup Guide

## ✅ Fixed Issues

All the major issues have been resolved:

1. ✅ **SQL Error (42501)**: Removed unauthorized auth.users table modifications
2. ✅ **Node.js Compatibility**: Upgraded to Node.js 20+ for React Router v7
3. ✅ **JSX Syntax Error**: Fixed duplicate closing tags in App.tsx
4. ✅ **Database Tables**: Created comprehensive database schema
5. ✅ **Authentication**: Implemented role-based login with proper redirects
6. ✅ **Admin Dashboard**: All 4 pages working (Orders, Clients, Products, Documents)
7. ✅ **Client Dashboard**: Both pages working (Orders, Documents)
8. ✅ **Document System**: Upload/download functionality implemented
9. ✅ **Profile Dropdown**: Working with Profile, Dashboard, Logout options

## 🚀 Quick Start

### 1. Database Setup

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Open **SQL Editor**
3. Copy and paste the contents of `database-setup.sql`
4. Click **Run** to execute the script

### 2. Storage Setup (Optional - for file uploads)

1. In Supabase Dashboard, go to **Storage**
2. Copy and paste the contents of `storage-setup.sql` in SQL Editor
3. Click **Run** to create the documents bucket

### 3. Start Development Server

```bash
# Make sure Node.js 20+ is active
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 20

# Start the application
npm run dev
```

### 4. Create Admin User

1. Visit `http://localhost:5174` (or the port shown in terminal)
2. Click **Login** → **Sign up here**
3. Register a new account with your admin email
4. After registration, go to Supabase SQL Editor
5. Run this command to make the user admin:

```sql
UPDATE public.profiles 
SET role = 'admin' 
WHERE email = 'your-admin-email@example.com';
```

6. Logout and login again to access admin dashboard

## 🎯 Feature Overview

### Public Pages
- **Home** (`/`): Product showcase with hero section
- **Products** (`/products`): Searchable product catalog
- **Login** (`/login`): Unified login for admin and clients
- **Register** (`/register`): User registration

### Admin Dashboard (`/admin`)
- **Dashboard**: Overview with statistics
- **Orders**: Manage all customer orders with status updates
- **Clients**: Manage user accounts (activate/block/delete)
- **Products**: Add, edit, delete products
- **Documents**: Upload documents for clients

### Client Dashboard (`/dashboard`)
- **Dashboard**: Personal overview
- **Orders**: View order history
- **Documents**: Download available documents

## 🔧 Environment Variables

Make sure your `.env` file is configured:

```env
# Supabase Configuration (Required)
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key

# Email Configuration (Optional)
VITE_SENDER_EMAIL=your-email@gmail.com
VITE_APP_PASSWORD=your-app-password

# App Configuration
VITE_ADMIN_EMAIL=admin@example.com
```

## 📱 Testing the Application

### Test Admin Features:
1. Login as admin
2. Add/edit products in Products page
3. Upload documents in Documents page
4. View client management in Clients page
5. Monitor orders in Orders page

### Test Client Features:
1. Register a new client account
2. Browse products on homepage
3. View client dashboard
4. Access documents from admin

### Test Document System:
1. Admin uploads document with public visibility
2. Document appears in client documents page
3. Client can view and download documents

## 🎨 Customization

### Adding New Products:
- Use Admin Dashboard → Products → Add Product
- Or insert directly via SQL:

```sql
INSERT INTO public.products (name, description, price, currency, stock_quantity) 
VALUES ('New Product', 'Description', 15000, 'RWF', 50);
```

### Creating Sample Orders:
```sql
-- First, get a client ID
SELECT id FROM public.profiles WHERE role = 'client' LIMIT 1;

-- Create a sample order (replace client_id with actual ID)
INSERT INTO public.orders (client_id, total_amount, order_status, payment_status)
VALUES ('client-uuid-here', 25000, 'pending', 'pending');
```

## 🔄 Data Flow

1. **Authentication**: Supabase Auth → Profile creation via trigger
2. **Role-based Access**: Login redirects based on profile.role
3. **Real-time Updates**: All dashboard data fetches latest from database
4. **Document Sharing**: Admin uploads → Public documents visible to clients
5. **Order Management**: Admin can update status → Clients see real-time updates

## 🚦 Production Deployment

When ready to deploy:

1. Run `npm run build` to create production build
2. Deploy the `dist` folder to your hosting service
3. Update Supabase URL restrictions for production domain
4. Set up proper environment variables in production

## 📞 Support

If you encounter any issues:

1. Check the browser console for errors
2. Verify Supabase connection and RLS policies
3. Ensure Node.js 20+ is being used
4. Check that all environment variables are set correctly

The application now includes comprehensive error handling and will show helpful messages when database tables are missing or when there are connection issues.
