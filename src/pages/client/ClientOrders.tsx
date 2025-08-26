import React, { useEffect, useState } from 'react';
import { format } from 'date-fns';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { Package, Clock, CheckCircle, XCircle } from 'lucide-react';

interface Order {
  id: string;
  total_amount: number;
  currency: string;
  order_status: string;
  payment_status: string;
  delivery_address: string;
  created_at: string;
  order_items: Array<{
    id: string;
    quantity: number;
    unit_price: number;
    products: {
      name: string;
      image_url: string;
    };
  }>;
}

const ClientOrders: React.FC = () => {
  const { profile } = useAuth();
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (profile) {
      fetchOrders();
    }
  }, [profile]);

  const fetchOrders = async () => {
    if (!profile) return;

    try {
      const { data, error } = await supabase
        .from('orders')
        .select(`
          *,
          order_items (
            id,
            quantity,
            unit_price,
            products (
              name,
              image_url
            )
          )
        `)
        .eq('client_id', profile.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setOrders(data || []);
    } catch (error) {
      console.error('Error fetching orders:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'delivered':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'cancelled':
        return <XCircle className="w-5 h-5 text-red-500" />;
      case 'pending':
      case 'confirmed':
      case 'processing':
        return <Clock className="w-5 h-5 text-yellow-500" />;
      default:
        return <Package className="w-5 h-5 text-blue-500" />;
    }
  };

  const getStatusColor = (status: string, type: 'order' | 'payment') => {
    if (type === 'order') {
      switch (status) {
        case 'pending': return 'bg-yellow-100 text-yellow-800';
        case 'confirmed': return 'bg-blue-100 text-blue-800';
        case 'processing': return 'bg-purple-100 text-purple-800';
        case 'shipped': return 'bg-indigo-100 text-indigo-800';
        case 'delivered': return 'bg-green-100 text-green-800';
        case 'cancelled': return 'bg-red-100 text-red-800';
        default: return 'bg-gray-100 text-gray-800';
      }
    } else {
      switch (status) {
        case 'pending': return 'bg-yellow-100 text-yellow-800';
        case 'paid': return 'bg-green-100 text-green-800';
        case 'failed': return 'bg-red-100 text-red-800';
        case 'refunded': return 'bg-gray-100 text-gray-800';
        default: return 'bg-gray-100 text-gray-800';
      }
    }
  };

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
        <h1 className="text-3xl font-bold text-gray-900 mb-2">My Orders</h1>
        <p className="text-gray-600">Track your order history and current status</p>
      </div>

      <div className="space-y-6">
        {orders.map((order) => (
          <div key={order.id} className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  {getStatusIcon(order.order_status)}
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900">
                      Order #{order.id.slice(0, 8)}
                    </h3>
                    <p className="text-sm text-gray-500">
                      Placed on {format(new Date(order.created_at), 'MMMM dd, yyyy HH:mm')}
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-xl font-bold text-gray-900">
                    {Number(order.total_amount).toLocaleString()} {order.currency}
                  </div>
                  <div className="flex space-x-2 mt-1">
                    <span className={`px-2 py-1 text-xs rounded-full ${getStatusColor(order.order_status, 'order')}`}>
                      {order.order_status}
                    </span>
                    <span className={`px-2 py-1 text-xs rounded-full ${getStatusColor(order.payment_status, 'payment')}`}>
                      {order.payment_status}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div className="p-6">
              <div className="space-y-4">
                {order.order_items?.map((item) => (
                  <div key={item.id} className="flex items-center space-x-4">
                    <div className="w-16 h-16 bg-gray-100 rounded-lg flex items-center justify-center overflow-hidden">
                      {item.products.image_url ? (
                        <img
                          src={item.products.image_url}
                          alt={item.products.name}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <Package className="w-6 h-6 text-gray-400" />
                      )}
                    </div>
                    <div className="flex-1">
                      <h4 className="font-medium text-gray-900">{item.products.name}</h4>
                      <p className="text-sm text-gray-500">
                        Quantity: {item.quantity} × {Number(item.unit_price).toLocaleString()} RWF
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="font-medium text-gray-900">
                        {Number(item.unit_price * item.quantity).toLocaleString()} RWF
                      </p>
                    </div>
                  </div>
                ))}
              </div>

              {order.delivery_address && (
                <div className="mt-6 pt-4 border-t border-gray-200">
                  <h4 className="font-medium text-gray-900 mb-2">Delivery Address</h4>
                  <p className="text-gray-600">{order.delivery_address}</p>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {orders.length === 0 && (
        <div className="text-center py-12">
          <Package className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <p className="text-gray-500 text-lg mb-4">No orders found</p>
          <a
            href="/products"
            className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg transition-colors"
          >
            Start Shopping
          </a>
        </div>
      )}
    </div>
  );
};

export default ClientOrders;