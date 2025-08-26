import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { 
  LayoutDashboard, 
  ShoppingBag, 
  Users, 
  Package, 
  FileText, 
  Settings,
  ShoppingCart
} from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';

const Sidebar: React.FC = () => {
  const location = useLocation();
  const { isAdmin } = useAuth();

  const adminMenuItems = [
    { path: '/admin', label: 'Dashboard', icon: LayoutDashboard },
    { path: '/admin/orders', label: 'Orders', icon: ShoppingBag },
    { path: '/admin/clients', label: 'Clients', icon: Users },
    { path: '/admin/products', label: 'Products', icon: Package },
    { path: '/admin/documents', label: 'Documents', icon: FileText },
  ];

  const clientMenuItems = [
    { path: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { path: '/dashboard/orders', label: 'My Orders', icon: ShoppingBag },
    { path: '/dashboard/documents', label: 'Documents', icon: FileText },
  ];

  const menuItems = isAdmin ? adminMenuItems : clientMenuItems;

  return (
    <div className="w-64 bg-white shadow-lg h-screen sticky top-0">
      <div className="p-6 border-b">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 bg-gradient-to-r from-blue-600 to-green-600 rounded-lg flex items-center justify-center">
            <ShoppingCart className="w-5 h-5 text-white" />
          </div>
          <span className="text-xl font-bold text-gray-900">
            {isAdmin ? 'Admin Panel' : 'Dashboard'}
          </span>
        </div>
      </div>

      <nav className="mt-6">
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          const Icon = item.icon;

          return (
            <Link
              key={item.path}
              to={item.path}
              className={`flex items-center px-6 py-3 text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-blue-50 text-blue-700 border-r-2 border-blue-700'
                  : 'text-gray-700 hover:bg-gray-50 hover:text-blue-600'
              }`}
            >
              <Icon className="w-5 h-5 mr-3" />
              {item.label}
            </Link>
          );
        })}
      </nav>
    </div>
  );
};

export default Sidebar;