# Rwanda Shop - E-commerce Platform

A modern e-commerce platform built with React, TypeScript, Vite, and Supabase, showcasing authentic Rwandan products.

## 🛠️ Tech Stack

- **Frontend**: React 18, TypeScript, Vite
- **Styling**: Tailwind CSS
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Icons**: Lucide React
- **Routing**: React Router v7
- **Forms**: React Hook Form
- **Notifications**: React Hot Toast

## 🚀 Getting Started

### Prerequisites

- Node.js 20+ (for React Router v7 compatibility)
- npm or yarn
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd project
   ```

2. **Install Node.js 20+ using nvm (recommended)**
   ```bash
   # Install nvm if not already installed
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
   
   # Restart terminal or source profile
   export NVM_DIR="$HOME/.nvm"
   [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
   
   # Install and use Node.js 20
   nvm install 20
   nvm use 20
   ```

3. **Install dependencies**
   ```bash
   npm install
   ```

4. **Set up environment variables**
   
   Copy the `.env` file and update with your Supabase credentials:
   ```bash
   cp .env.example .env
   ```
   
   Update the following in your `.env` file:
   ```env
   VITE_SUPABASE_URL=your_supabase_project_url
   VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
   VITE_SENDER_EMAIL=your_email@example.com
   VITE_APP_PASSWORD=your_email_app_password
   VITE_ADMIN_EMAIL=admin@example.com
   ```

5. **Set up the database**
   
   a. Go to your Supabase project dashboard
   
   b. Open the SQL Editor
   
   c. Copy and paste the contents of `database-setup.sql` into the SQL Editor
   
   d. Run the script to create all tables, policies, and sample data

6. **Start the development server**
   ```bash
   npm run dev
   ```

The application will be available at `http://localhost:5173`

## 📊 Database Schema

The application uses the following main tables:

- **profiles**: User profiles with roles (admin/client)
- **products**: Product catalog with pricing and inventory
- **orders**: Customer orders with status tracking
- **order_items**: Individual items within orders
- **documents**: File storage for documents

## 🔐 Authentication & Authorization

- Uses Supabase Auth for user authentication
- Role-based access control (admin/client)
- Row Level Security (RLS) policies protect data access
- Automatic profile creation on user registration

## 🎨 Features

### Public Features
- Browse products catalog
- View product details
- Search and filter products
- Responsive design

### User Features (Client)
- User registration and login
- Personal dashboard
- Order management
- Document access

### Admin Features
- Admin dashboard
- Product management
- Order management
- Client management
- Document management

## 🚧 Development

### Available Scripts

```bash
npm run dev        # Start development server
npm run build      # Build for production
npm run preview    # Preview production build
npm run lint       # Run ESLint
```

### Project Structure

```
src/
├── components/       # Reusable UI components
│   ├── Dashboard/    # Dashboard layout components
│   ├── Layout/       # Main layout components
│   └── ...          # Other shared components
├── contexts/        # React contexts (Auth, etc.)
├── lib/            # Utilities and configurations
├── pages/          # Page components
│   ├── admin/      # Admin dashboard pages
│   ├── client/     # Client dashboard pages
│   └── ...         # Public pages
└── main.tsx        # Application entry point
```

### Dashboard Features

#### Admin Dashboard (`/admin`)
- **Overview**: Statistics and quick actions
- **Orders** (`/admin/orders`): View and manage all customer orders with status updates
- **Clients** (`/admin/clients`): Manage client accounts (activate/deactivate/block)
- **Products** (`/admin/products`): Add, edit, and manage product catalog
- **Documents** (`/admin/documents`): Upload and manage documents for clients

#### Client Dashboard (`/dashboard`)
- **Overview**: Personal account statistics
- **Orders** (`/dashboard/orders`): View order history and status
- **Documents** (`/dashboard/documents`): Access and download available documents

## 🐛 Troubleshooting

### Common Issues

1. **"Unexpected reserved word" error**
   - Ensure you're using Node.js 18+ (preferably 20+)
   - Run `node --version` to check your version

2. **Database connection errors (404)**
   - Verify your Supabase URL and keys in `.env`
   - Ensure you've run the `database-setup.sql` script
   - Check if RLS policies are properly configured

3. **"Missing script: server" error**
   - This project uses Vite, not a separate server
   - Use `npm run dev` instead of `npm run server`

4. **React Router engine warnings**
   - Upgrade to Node.js 20+ to resolve compatibility warnings

## 🔄 Demo Mode

If the database isn't set up, the application will automatically fall back to demo data for products. Look for console warnings about "Database tables not found" to identify when this is happening.

## 📝 Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `VITE_SUPABASE_URL` | Your Supabase project URL | Yes |
| `VITE_SUPABASE_ANON_KEY` | Your Supabase anonymous key | Yes |
| `VITE_SENDER_EMAIL` | Email for notifications | Optional |
| `VITE_APP_PASSWORD` | App password for email | Optional |
| `VITE_ADMIN_EMAIL` | Admin email address | Optional |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
