import React, { useEffect, useState } from 'react';
import { format } from 'date-fns';
import { supabase } from '../../lib/supabase';
import { UserCheck, UserX, Trash2, Mail, Phone } from 'lucide-react';
import { toast } from 'react-hot-toast';
import { deleteClientAccount, updateClientStatus } from '../../lib/adminUtils';

interface Client {
  id: string;
  user_id: string;
  email: string;
  full_name: string;
  phone: string | null;
  client_status: 'active' | 'inactive' | 'blocked' | 'deleted';
  created_at: string;
}

const AdminClients: React.FC = () => {
  const [clients, setClients] = useState<Client[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchClients();
  }, []);

  const fetchClients = async () => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('role', 'client')
        .neq('client_status', 'deleted') // Exclude deleted clients from the list
        .order('created_at', { ascending: false });

      if (error) throw error;
      setClients(data || []);
    } catch (error) {
      console.error('Error fetching clients:', error);
      toast.error('Failed to load clients');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateClientStatus = async (clientId: string, status: 'active' | 'inactive' | 'blocked') => {
    try {
      await updateClientStatus(clientId, status);
      toast.success(`Client ${status === 'blocked' ? 'blocked' : status === 'active' ? 'activated' : 'deactivated'} successfully`);
      fetchClients();
    } catch (error) {
      console.error('Error updating client status:', error);
      toast.error('Failed to update client status');
    }
  };

  const handleDeleteClient = async (clientId: string, userId: string) => {
    if (!window.confirm(
      'Are you sure you want to delete this client? This will permanently remove their account and they will no longer be able to login. This action cannot be undone.'
    )) {
      return;
    }

    try {
      // Note: This currently only deletes the profile. In a full implementation,
      // you would also need to delete the auth user using Supabase Admin API
      await deleteClientAccount(clientId, userId);
      toast.success('Client account deleted successfully');
      fetchClients();
    } catch (error) {
      console.error('Error deleting client:', error);
      toast.error('Failed to delete client account');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800';
      case 'inactive': return 'bg-yellow-100 text-yellow-800';
      case 'blocked': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
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
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Clients Management</h1>
        <p className="text-gray-600">Manage client accounts and permissions</p>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Client Info
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Contact
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Join Date
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {clients.map((client) => (
                <tr key={client.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <div className="text-sm font-medium text-gray-900">{client.full_name}</div>
                      <div className="text-sm text-gray-500">ID: {client.id.slice(0, 8)}...</div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="space-y-1">
                      <div className="flex items-center text-sm text-gray-900">
                        <Mail className="w-4 h-4 mr-2 text-gray-400" />
                        {client.email}
                      </div>
                      {client.phone && (
                        <div className="flex items-center text-sm text-gray-500">
                          <Phone className="w-4 h-4 mr-2 text-gray-400" />
                          {client.phone}
                        </div>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <select
                      value={client.client_status}
                      onChange={(e) => handleUpdateClientStatus(client.id, e.target.value as 'active' | 'inactive' | 'blocked')}
                      className={`px-2 py-1 text-xs rounded-full ${getStatusColor(client.client_status)} border-none focus:ring-2 focus:ring-blue-500`}
                    >
                      <option value="active">Active</option>
                      <option value="inactive">Inactive</option>
                      <option value="blocked">Blocked</option>
                    </select>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {format(new Date(client.created_at), 'MMM dd, yyyy')}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div className="flex space-x-2">
                      {client.client_status === 'blocked' ? (
                        <button
                          onClick={() => handleUpdateClientStatus(client.id, 'active')}
                          className="text-green-600 hover:text-green-900"
                          title="Unblock client"
                        >
                          <UserCheck className="w-4 h-4" />
                        </button>
                      ) : (
                        <button
                          onClick={() => handleUpdateClientStatus(client.id, 'blocked')}
                          className="text-red-600 hover:text-red-900"
                          title="Block client"
                        >
                          <UserX className="w-4 h-4" />
                        </button>
                      )}
                      <button
                        onClick={() => handleDeleteClient(client.id, client.user_id)}
                        className="text-red-600 hover:text-red-900"
                        title="Delete client"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {clients.length === 0 && (
          <div className="text-center py-12">
            <p className="text-gray-500 text-lg">No clients found</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default AdminClients;