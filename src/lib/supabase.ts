import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

// Get the current origin, handling both development and production
const getRedirectUrl = () => {
  if (typeof window !== 'undefined') {
    return window.location.origin;
  }
  // Fallback for server-side or build time
  return import.meta.env.PROD ? 'https://farca-companywebsite.onrender.com' : 'http://localhost:3000';
};

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    redirectTo: getRedirectUrl(),
  },
});

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          user_id: string;
          email: string;
          full_name: string;
          phone: string | null;
          role: 'admin' | 'client';
          client_status: 'active' | 'inactive' | 'blocked';
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          email: string;
          full_name: string;
          phone?: string | null;
          role?: 'admin' | 'client';
          client_status?: 'active' | 'inactive' | 'blocked';
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          email?: string;
          full_name?: string;
          phone?: string | null;
          role?: 'admin' | 'client';
          client_status?: 'active' | 'inactive' | 'blocked';
          created_at?: string;
          updated_at?: string;
        };
      };
      products: {
        Row: {
          id: string;
          name: string;
          description: string | null;
          price: number;
          currency: string;
          image_url: string | null;
          stock_quantity: number;
          is_active: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          description?: string | null;
          price: number;
          currency?: string;
          image_url?: string | null;
          stock_quantity?: number;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          name?: string;
          description?: string | null;
          price?: number;
          currency?: string;
          image_url?: string | null;
          stock_quantity?: number;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
      };
      orders: {
        Row: {
          id: string;
          client_id: string;
          total_amount: number;
          currency: string;
          order_status: 'pending' | 'confirmed' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
          payment_status: 'pending' | 'paid' | 'failed' | 'refunded';
          delivery_address: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          client_id: string;
          total_amount: number;
          currency?: string;
          order_status?: 'pending' | 'confirmed' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
          payment_status?: 'pending' | 'paid' | 'failed' | 'refunded';
          delivery_address?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          client_id?: string;
          total_amount?: number;
          currency?: string;
          order_status?: 'pending' | 'confirmed' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
          payment_status?: 'pending' | 'paid' | 'failed' | 'refunded';
          delivery_address?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      order_items: {
        Row: {
          id: string;
          order_id: string;
          product_id: string;
          quantity: number;
          unit_price: number;
          total_price: number;
          created_at: string;
        };
        Insert: {
          id?: string;
          order_id: string;
          product_id: string;
          quantity?: number;
          unit_price: number;
          total_price: number;
          created_at?: string;
        };
        Update: {
          id?: string;
          order_id?: string;
          product_id?: string;
          quantity?: number;
          unit_price?: number;
          total_price?: number;
          created_at?: string;
        };
      };
      documents: {
        Row: {
          id: string;
          title: string;
          description: string | null;
          file_url: string;
          file_type: string | null;
          uploaded_by: string;
          is_public: boolean;
          created_at: string;
        };
        Insert: {
          id?: string;
          title: string;
          description?: string | null;
          file_url: string;
          file_type?: string | null;
          uploaded_by: string;
          is_public?: boolean;
          created_at?: string;
        };
        Update: {
          id?: string;
          title?: string;
          description?: string | null;
          file_url?: string;
          file_type?: string | null;
          uploaded_by?: string;
          is_public?: boolean;
          created_at?: string;
        };
      };
    };
  };
};