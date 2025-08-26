import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { ShoppingBag, FileText, Package, Clock } from 'lucide-react';

interface Stats {
  totalOrders: number;
  pendingOrders: number;
  completedOrders: number;
  totalDocuments: number;
}

const ClientDashboard: React.FC = () => {
  const { profile } = useAuth();
  const [stats, setStats] = useState<Stats>({
    totalOrders: 0,
    pendingOrders: 0,
    completedOrders: 0,
    totalDocuments: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (profile) {
      fetchStats();
    }
  }, [profile]);

  const fetchStats = async () => {
    if (!profile) return;

    try {
      // Fetch user's orders
      const { data: orders, error: ordersError } = await supabase
        .from('orders')
        .select('order_status')
        .eq('client_id', profile.id);

      if (ordersError) throw ordersError;

      // Fetch documents count
      const { count: documentsCount } = await supabase
        .from('documents')
        .select('*', { count: 'exact', head: true })
        .eq('is_public', true);

      const totalOrders = orders?.length || 0;
      const pendingOrders = orders?.filter(order => 
        ['pending', 'confirmed', 'processing'].includes(order.order_status)
      ).length || 0;
      const completedOrders = orders?.filter(order => 
        order.order_status === 'delivered'
      ).length || 0;

      setStats({
        totalOrders,
        pendingOrders,
        completedOrders,
        totalDocuments: documentsCount || 0,
      });
    } catch (error) {
      console.error('Error fetching stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const statCards = [
    {
      title: 'Total Orders',
      value: stats.totalOrders.toString(),
      icon: ShoppingBag,
      color: 'bg-blue-500',
      bgColor: 'bg-blue-50',
    },
    {
      title: 'Pending Orders',
      value: stats.pendingOrders.toString(),
      icon: Clock,
      color: 'bg-yellow-500',
      bgColor: 'bg-yellow-50',
    },
    {
      title: 'Completed Orders',
      value: stats.completedOrders.toString(),
      icon: Package,
      color: 'bg-green-500',
      bgColor: 'bg-green-50',
    },
    {
      title: 'Available Documents',
      value: stats.totalDocuments.toString(),
      icon: FileText,
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
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Welcome back, {profile?.full_name}!</h1>
        <p className="text-gray-600">Here's an overview of your account activity</p>
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
            <a
              href="/products"
              className="block w-full text-left px-4 py-3 bg-blue-50 hover:bg-blue-100 rounded-lg transition-colors"
            >
              <span className="font-medium text-blue-900">Browse Products</span>
            </a>
            <a
              href="/dashboard/orders"
              className="block w-full text-left px-4 py-3 bg-green-50 hover:bg-green-100 rounded-lg transition-colors"
            >
              <span className="font-medium text-green-900">View My Orders</span>
            </a>
            <a
              href="/dashboard/documents"
              className="block w-full text-left px-4 py-3 bg-purple-50 hover:bg-purple-100 rounded-lg transition-colors"
            >
              <span className="font-medium text-purple-900">Access Documents</span>
            </a>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Account Information</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Email</span>
              <span className="font-medium">{profile?.email}</span>
            </div>
            {profile?.phone && (
              <div className="flex items-center justify-between">
                <span className="text-gray-600">Phone</span>
                <span className="font-medium">{profile.phone}</span>
              </div>
            )}
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Account Status</span>
              <span className={`px-2 py-1 text-xs rounded-full ${
                profile?.client_status === 'active' 
                  ? 'bg-green-100 text-green-800' 
                  : 'bg-yellow-100 text-yellow-800'
              }`}>
                {profile?.client_status}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ClientDashboard;