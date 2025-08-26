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

      // Check if user is blocked
      if (data.client_status === 'blocked' && data.role !== 'admin') {
        console.log('User account is blocked');
        toast.error('Your account has been blocked. Please contact support.');
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
    const { error } = await supabase.auth.signInWithPassword({
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
    console.log('Sign in successful');
  };

  const signUp = async (email: string, password: string, fullName: string, phone?: string) => {
    console.log('Attempting to sign up user:', email);
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    });

    if (error) {
      console.error('Sign up error:', error);
      throw error;
    }

    if (data.user) {
      // Create profile - use upsert to handle conflicts gracefully
      console.log('Creating profile for user:', data.user.id);
      const { error: profileError } = await supabase.from('profiles').upsert({
        user_id: data.user.id,
        email,
        full_name: fullName,
        phone: phone || null,
        role: 'client',
      }, {
        onConflict: 'user_id'
      });

      if (profileError) {
        console.error('Profile creation error:', profileError);
        // Don't throw error if profile already exists
        if (profileError.code !== '23505') { // Not a unique violation
          throw profileError;
        } else {
          console.log('Profile already exists, continuing...');
        }
      } else {
        console.log('Profile created successfully');
      }
    }
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