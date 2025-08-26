import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { ShoppingBag, Users, Package, TrendingUp } from 'lucide-react';

interface Stats {
  totalOrders: number;
  totalClients: number;
  totalProducts: number;
  totalRevenue: number;
}

const AdminDashboard: React.FC = () => {
  const [stats, setStats] = useState<Stats>({
    totalOrders: 0,
    totalClients: 0,
    totalProducts: 0,
    totalRevenue: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      console.log('Fetching dashboard stats...');
      
      // Fetch orders with error handling
      const ordersQuery = await supabase
        .from('orders')
        .select('*', { count: 'exact', head: true });
      
      if (ordersQuery.error) {
        console.warn('Orders count error:', ordersQuery.error);
      }

      // Fetch clients with error handling
      const clientsQuery = await supabase
        .from('profiles')
        .select('*', { count: 'exact', head: true })
        .eq('role', 'client');
        
      if (clientsQuery.error) {
        console.warn('Clients count error:', clientsQuery.error);
      }

      // Fetch products with error handling
      const productsQuery = await supabase
        .from('products')
        .select('*', { count: 'exact', head: true });
        
      if (productsQuery.error) {
        console.warn('Products count error:', productsQuery.error);
      }

      // Fetch revenue with error handling
      const ordersRevenueQuery = await supabase
        .from('orders')
        .select('total_amount')
        .eq('payment_status', 'paid');
        
      if (ordersRevenueQuery.error) {
        console.warn('Revenue fetch error:', ordersRevenueQuery.error);
      }

      const totalRevenue = ordersRevenueQuery.data?.reduce((sum, order) => sum + Number(order.total_amount), 0) || 0;

      const newStats = {
        totalOrders: ordersQuery.count || 0,
        totalClients: clientsQuery.count || 0,
        totalProducts: productsQuery.count || 0,
        totalRevenue,
      };
      
      console.log('Dashboard stats loaded:', newStats);
      setStats(newStats);
    } catch (error) {
      console.error('Error fetching dashboard stats:', error);
      // Set default stats on error
      setStats({
        totalOrders: 0,
        totalClients: 0,
        totalProducts: 0,
        totalRevenue: 0,
      });
    } finally {
      setLoading(false);
    }
  };

  const statCards = [
    {
      title: 'Total Orders',
      value: stats.totalOrders.toLocaleString(),
      icon: ShoppingBag,
      color: 'bg-blue-500',
      bgColor: 'bg-blue-50',
    },
    {
      title: 'Total Clients',
      value: stats.totalClients.toLocaleString(),
      icon: Users,
      color: 'bg-green-500',
      bgColor: 'bg-green-50',
    },
    {
      title: 'Total Products',
      value: stats.totalProducts.toLocaleString(),
      icon: Package,
      color: 'bg-yellow-500',
      bgColor: 'bg-yellow-50',
    },
    {
      title: 'Total Revenue',
      value: `${stats.totalRevenue.toLocaleString()} RWF`,
      icon: TrendingUp,
      color: 'bg-purple-500',
      bgColor: 'bg-purple-50',
    },
  ];

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Admin Dashboard</h1>
        <p className="text-gray-600">Welcome to Rwanda Shop administration panel</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {statCards.map((card) => {
          const Icon = card.icon;
          return (
            <div key={card.title} className={`${card.bgColor} rounded-xl p-6 border border-gray-200`}>
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600 mb-1">{card.title}</p>
                  <p className="text-2xl font-bold text-gray-900">{card.value}</p>
                </div>
                <div className={`${card.color} w-12 h-12 rounded-lg flex items-center justify-center`}>
                  <Icon className="w-6 h-6 text-white" />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
          <div className="space-y-3">
            <button className="w-full text-left px-4 py-3 bg-blue-50 hover:bg-blue-100 rounded-lg transition-colors">
              <span className="font-medium text-blue-900">View Recent Orders</span>
            </button>
            <button className="w-full text-left px-4 py-3 bg-green-50 hover:bg-green-100 rounded-lg transition-colors">
              <span className="font-medium text-green-900">Add New Product</span>
            </button>
            <button className="w-full text-left px-4 py-3 bg-purple-50 hover:bg-purple-100 rounded-lg transition-colors">
              <span className="font-medium text-purple-900">Upload Document</span>
            </button>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">System Status</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Database</span>
              <span className="px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">Online</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Payment System</span>
              <span className="px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">Active</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Email Service</span>
              <span className="px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">Active</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminDashboard;