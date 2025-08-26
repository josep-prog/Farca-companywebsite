import { supabase } from './supabase';

/**
 * Admin utility functions for managing users
 * These functions require admin privileges and handle both profile and auth operations
 */

/**
 * Soft delete a client account - marks account as deleted instead of removing it
 * This prevents access while maintaining data integrity and handles auth conflicts
 */
export const deleteClientAccount = async (clientId: string, userId: string) => {
  try {
    // Use soft delete - mark as deleted instead of removing the profile
    const { error: profileError } = await supabase
      .from('profiles')
      .update({ 
        client_status: 'deleted',
        updated_at: new Date().toISOString() 
      })
      .eq('id', clientId);

    if (profileError) {
      console.error('Error marking profile as deleted:', profileError);
      throw profileError;
    }

    // Note: The auth user still exists in Supabase Auth but cannot access the app
    // because the AuthContext will automatically sign out users with 'deleted' status
    
    console.log('Client account marked as deleted successfully');
    return { success: true };
  } catch (error) {
    console.error('Error deleting client account:', error);
    throw error;
  }
};

/**
 * Update client status (active, inactive, blocked)
 */
export const updateClientStatus = async (clientId: string, status: 'active' | 'inactive' | 'blocked') => {
  try {
    const { error } = await supabase
      .from('profiles')
      .update({ 
        client_status: status, 
        updated_at: new Date().toISOString() 
      })
      .eq('id', clientId);

    if (error) throw error;
    
    return { success: true };
  } catch (error) {
    console.error('Error updating client status:', error);
    throw error;
  }
};

/**
 * Check if a user is blocked or deleted
 */
export const checkUserStatus = async (userId: string) => {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('client_status')
      .eq('user_id', userId)
      .single();

    if (error) {
      // If profile doesn't exist, user was deleted
      if (error.code === 'PGRST116') {
        return { status: 'deleted', exists: false };
      }
      throw error;
    }

    return { status: data.client_status, exists: true };
  } catch (error) {
    console.error('Error checking user status:', error);
    return { status: 'unknown', exists: false };
  }
};
