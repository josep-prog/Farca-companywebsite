import React, { createContext, useContext, useEffect, useState } from 'react';
import { User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import { Database } from '../lib/supabase';
import { toast } from 'react-hot-toast';

type Profile = Database['public']['Tables']['profiles']['Row'];

interface AuthContextType {
  user: User | null;
  profile: Profile | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, fullName: string, phone?: string) => Promise<void>;
  signOut: () => Promise<void>;
  isAdmin: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchProfile(session.user.id);
      } else {
        setLoading(false);
      }
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchProfile(session.user.id);
      } else {
        setProfile(null);
        setLoading(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const fetchProfile = async (userId: string) => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('user_id', userId)
        .single();

      if (error) {
        // If profile doesn't exist, user was deleted - sign them out
        if (error.code === 'PGRST116') {
          console.log('User profile not found - account may have been deleted');
          toast.error('Your account has been removed. Please contact support if this is an error.');
          await signOut();
          return;
        }
        throw error;
      }

      // Check if user is blocked or deleted
      if ((data.client_status === 'blocked' || data.client_status === 'deleted') && data.role !== 'admin') {
        const message = data.client_status === 'deleted' 
          ? 'Your account has been deleted. Please contact support if this is an error.'
          : 'Your account has been blocked. Please contact support.';
        console.log(`User account is ${data.client_status}`);
        toast.error(message);
        await signOut();
        return;
      }

      setProfile(data);
    } catch (error) {
      console.error('Error fetching profile:', error);
      // If there's an error fetching profile, sign out for security
      await signOut();
    } finally {
      setLoading(false);
    }
  };

  const signIn = async (email: string, password: string) => {
    console.log('Attempting to sign in user:', email);
    
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    
    if (error) {
      console.error('Sign in error details:', {
        message: error.message,
        status: error.status,
      });
      throw error;
    }
    
    // If sign in successful, check account status immediately
    if (data.user) {
      try {
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('client_status, role')
          .eq('user_id', data.user.id)
          .single();
          
        if (profileError && profileError.code === 'PGRST116') {
          // Profile doesn't exist - account was hard deleted
          await supabase.auth.signOut();
          throw new Error('Your account no longer exists. Please contact support if this is an error.');
        }
        
        if (profile && profile.client_status === 'deleted' && profile.role !== 'admin') {
          // Account is soft deleted
          await supabase.auth.signOut();
          throw new Error('Your account has been deleted. Please contact support if this is an error.');
        }
        
        if (profile && profile.client_status === 'blocked' && profile.role !== 'admin') {
          // Account is blocked
          await supabase.auth.signOut();
          throw new Error('Your account has been blocked. Please contact support.');
        }
      } catch (checkError: any) {
        // If it's our custom error message, throw it
        if (checkError.message.includes('account') || checkError.message.includes('blocked') || checkError.message.includes('deleted')) {
          throw checkError;
        }
        // For other errors, continue with normal flow (will be caught by fetchProfile)
        console.warn('Profile check during login failed:', checkError);
      }
    }
    
    console.log('Sign in successful');
  };

  const signUp = async (email: string, password: string, fullName: string, phone?: string) => {
    console.log('Attempting to sign up user:', email);

    // Try to sign up first
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          phone: phone || null,
        }
      }
    });

    if (error) {
      // If user already exists in auth, they might have a deleted profile
      if (error.message.includes('already registered') || error.message.includes('already been registered')) {
        console.log('User already exists in auth, checking profile status...');
        
        // Try to sign them in to get their user ID
        const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
          email,
          password,
        });
        
        if (signInData.user) {
          // Check if their profile is deleted
          const { data: profile, error: profileFetchError } = await supabase
            .from('profiles')
            .select('*')
            .eq('user_id', signInData.user.id)
            .single();
            
          if (profileFetchError && profileFetchError.code === 'PGRST116') {
            // Profile doesn't exist, create it
            console.log('Creating missing profile for existing auth user');
            const { error: createError } = await supabase
              .from('profiles')
              .insert({
                user_id: signInData.user.id,
                email,
                full_name: fullName,
                phone: phone || null,
                role: 'client',
                client_status: 'active',
              });
              
            if (createError) {
              console.error('Error creating profile for existing user:', createError);
              throw new Error('Failed to create profile. Please contact support.');
            }
            
            console.log('Profile created for existing auth user');
            // Sign them out so they need to confirm email if required
            await supabase.auth.signOut();
            return;
          }
            
          if (profile && profile.client_status === 'deleted') {
            // Reactivate the deleted account
            const { error: updateError } = await supabase
              .from('profiles')
              .update({
                client_status: 'active',
                full_name: fullName,
                phone: phone || null,
                updated_at: new Date().toISOString()
              })
              .eq('user_id', signInData.user.id);
              
            if (updateError) {
              console.error('Error reactivating account:', updateError);
              throw new Error('Failed to reactivate account. Please contact support.');
            }
            
            console.log('Deleted account reactivated successfully');
            // Sign them out so they go through normal login flow
            await supabase.auth.signOut();
            return;
          }
          
          // Account exists and is not deleted
          throw new Error('An account with this email already exists. Please try logging in instead.');
        } else {
          // Could not sign in - might be wrong password or other issue
          throw new Error('An account with this email already exists. Please try logging in instead.');
        }
      }
      
      console.error('Sign up error:', error);
      throw error;
    }

    // Registration successful - profile will be created by the database trigger
    // or we can create it manually if needed
    if (data.user && data.session) {
      console.log('User registered successfully:', data.user.id);
      
      // The handle_new_user trigger should create the profile automatically
      // But let's check if it exists and create if needed
      setTimeout(async () => {
        try {
          const { data: profile, error: checkError } = await supabase
            .from('profiles')
            .select('id')
            .eq('user_id', data.user!.id)
            .single();
            
          if (checkError && checkError.code === 'PGRST116') {
            // Profile doesn't exist, create it manually
            console.log('Creating profile manually (trigger may have failed)');
            await supabase.from('profiles').insert({
              user_id: data.user!.id,
              email,
              full_name: fullName,
              phone: phone || null,
              role: 'client',
              client_status: 'active',
            });
          }
        } catch (profileError) {
          console.error('Error ensuring profile exists:', profileError);
        }
      }, 2000); // Wait 2 seconds for trigger to complete
    }
    
    console.log('Sign up completed successfully');
  };

  const signOut = async () => {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
  };

  const isAdmin = profile?.role === 'admin';

  const value = {
    user,
    profile,
    loading,
    signIn,
    signUp,
    signOut,
    isAdmin,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};