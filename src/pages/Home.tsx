import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { ShoppingCart, Star, ArrowRight } from 'lucide-react';

interface Product {
  id: string;
  name: string;
  description: string | null;
  price: number;
  currency: string;
  image_url: string | null;
  stock_quantity: number;
}

const Home: React.FC = () => {
  const [featuredProducts, setFeaturedProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchFeaturedProducts();
  }, []);

  const fetchFeaturedProducts = async () => {
    try {
      console.log('Attempting to fetch products from Supabase...');
      const { data, error } = await supabase
        .from('products')
        .select('*')
        .eq('is_active', true)
        .limit(6)
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Supabase error details:', {
          message: error.message,
          code: error.code,
          details: error.details,
          hint: error.hint
        });
        
        // Check for specific error types
        if (error.message?.includes('does not exist') || error.code === 'PGRST116') {
          console.warn('Database tables not found. Using demo data. Please run the database setup script.');
          setFeaturedProducts(getDemoProducts());
          return;
        }
        
        // Check for RLS policy errors
        if (error.message?.includes('infinite recursion') || error.message?.includes('policy')) {
          console.warn('Database policy error detected. Using demo data. Please run the FIX-SUPABASE-CONNECTION.sql script.');
          setFeaturedProducts(getDemoProducts());
          return;
        }
        
        throw error;
      }
      
      console.log(`Successfully fetched ${data?.length || 0} products from database`);
      setFeaturedProducts(data || []);
    } catch (error) {
      console.error('Error fetching products:', error);
      console.log('Falling back to demo products...');
      // Fallback to demo data if there's any error
      setFeaturedProducts(getDemoProducts());
    } finally {
      setLoading(false);
    }
  };

  const getDemoProducts = (): Product[] => [
    {
      id: '1',
      name: 'Rwandan Premium Coffee',
      description: 'High-quality arabica coffee beans from the hills of Rwanda. Rich flavor with notes of chocolate and fruit.',
      price: 25000,
      currency: 'RWF',
      image_url: 'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=500',
      stock_quantity: 50,
    },
    {
      id: '2',
      name: 'Traditional Rwandan Basket',
      description: 'Handwoven basket made by local artisans using traditional techniques and natural materials.',
      price: 15000,
      currency: 'RWF',
      image_url: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=500',
      stock_quantity: 20,
    },
    {
      id: '3',
      name: 'Rwandan Honey',
      description: 'Pure, natural honey harvested from Rwandan bee farms. Perfect for tea or spreading on bread.',
      price: 8000,
      currency: 'RWF',
      image_url: 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=500',
      stock_quantity: 30,
    },
  ];

  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <section className="bg-gradient-to-br from-blue-50 via-white to-green-50 py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h1 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
              Welcome to <span className="text-blue-600">Rwanda Shop</span>
            </h1>
            <p className="text-xl text-gray-600 mb-8 max-w-3xl mx-auto">
              Discover authentic Rwandan products, from premium coffee to traditional crafts. 
              Supporting local artisans and bringing Rwanda's finest to your doorstep.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link
                to="/products"
                className="bg-blue-600 hover:bg-blue-700 text-white px-8 py-3 rounded-lg font-medium transition-colors inline-flex items-center justify-center space-x-2"
              >
                <ShoppingCart className="w-5 h-5" />
                <span>Shop Now</span>
              </Link>
              <Link
                to="/register"
                className="border-2 border-blue-600 text-blue-600 hover:bg-blue-50 px-8 py-3 rounded-lg font-medium transition-colors"
              >
                Join Us Today
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Featured Products */}
      <section className="py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">Featured Products</h2>
            <p className="text-gray-600 max-w-2xl mx-auto">
              Explore our handpicked selection of authentic Rwandan products
            </p>
          </div>

          {loading ? (
            <div className="flex items-center justify-center h-64">
              <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              {featuredProducts.map((product) => (
                <div key={product.id} className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-lg transition-shadow group">
                  <div className="aspect-w-16 aspect-h-9 bg-gray-100">
                    {product.image_url ? (
                      <img
                        src={product.image_url}
                        alt={product.name}
                        className="w-full h-48 object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                    ) : (
                      <div className="w-full h-48 flex items-center justify-center bg-gray-100">
                        <ShoppingCart className="w-12 h-12 text-gray-400" />
                      </div>
                    )}
                  </div>
                  
                  <div className="p-6">
                    <h3 className="text-xl font-semibold text-gray-900 mb-2 group-hover:text-blue-600 transition-colors">
                      {product.name}
                    </h3>
                    
                    <p className="text-gray-600 text-sm mb-4 line-clamp-3">
                      {product.description || 'Premium quality product from Rwanda'}
                    </p>
                    
                    <div className="flex items-center justify-between">
                      <div className="text-2xl font-bold text-blue-600">
                        {Number(product.price).toLocaleString()} {product.currency}
                      </div>
                      <div className="flex items-center text-yellow-500">
                        <Star className="w-4 h-4 fill-current" />
                        <Star className="w-4 h-4 fill-current" />
                        <Star className="w-4 h-4 fill-current" />
                        <Star className="w-4 h-4 fill-current" />
                        <Star className="w-4 h-4 fill-current" />
                        <span className="text-gray-500 text-sm ml-1">(5.0)</span>
                      </div>
                    </div>
                    
                    <button className="w-full mt-4 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium transition-colors flex items-center justify-center space-x-2">
                      <ShoppingCart className="w-4 h-4" />
                      <span>Add to Cart</span>
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}

          <div className="text-center mt-12">
            <Link
              to="/products"
              className="inline-flex items-center text-blue-600 hover:text-blue-700 font-medium space-x-2"
            >
              <span>View All Products</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="py-16 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">Why Choose Rwanda Shop?</h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="text-center">
              <div className="w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <ShoppingCart className="w-8 h-8 text-white" />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Authentic Products</h3>
              <p className="text-gray-600">
                Genuine Rwandan products sourced directly from local artisans and producers
              </p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-green-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <Star className="w-8 h-8 text-white" />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Premium Quality</h3>
              <p className="text-gray-600">
                We ensure every product meets the highest quality standards before reaching you
              </p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-yellow-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <ArrowRight className="w-8 h-8 text-white" />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Fast Delivery</h3>
              <p className="text-gray-600">
                Quick and reliable delivery across Rwanda with real-time tracking
              </p>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Home;