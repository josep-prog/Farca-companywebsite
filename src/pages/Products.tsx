import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { ShoppingCart, Package, Filter } from 'lucide-react';

interface Product {
  id: string;
  name: string;
  description: string | null;
  price: number;
  currency: string;
  image_url: string | null;
  stock_quantity: number;
}

const Products: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('name');

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      const { data, error } = await supabase
        .from('products')
        .select('*')
        .eq('is_active', true)
        .order('created_at', { ascending: false });

      if (error) {
        // If database tables don't exist, show demo products
        if (error.message?.includes('does not exist') || error.code === 'PGRST116') {
          console.warn('Database tables not found. Using demo data. Please run the database setup script.');
          setProducts(getDemoProducts());
          return;
        }
        throw error;
      }
      setProducts(data || []);
    } catch (error) {
      console.error('Error fetching products:', error);
      // Fallback to demo data if there's any error
      setProducts(getDemoProducts());
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
    {
      id: '4',
      name: 'Ubushyuhe Hot Sauce',
      description: 'Spicy traditional Rwandan hot sauce made from fresh peppers and local spices.',
      price: 5000,
      currency: 'RWF',
      image_url: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=500',
      stock_quantity: 100,
    },
    {
      id: '5',
      name: 'Rwandan Tea',
      description: 'Premium black tea grown in the highlands of Rwanda. Full-bodied with a smooth finish.',
      price: 12000,
      currency: 'RWF',
      image_url: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=500',
      stock_quantity: 75,
    },
    {
      id: '6',
      name: 'Handicraft Wood Carving',
      description: 'Beautiful wooden sculpture carved by skilled Rwandan artisans depicting traditional motifs.',
      price: 35000,
      currency: 'RWF',
      image_url: 'https://images.unsplash.com/photo-1578450671530-5b6a7c9c4c1d?w=500',
      stock_quantity: 10,
    },
  ];

  const filteredProducts = products
    .filter(product =>
      product.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (product.description && product.description.toLowerCase().includes(searchTerm.toLowerCase()))
    )
    .sort((a, b) => {
      switch (sortBy) {
        case 'price_asc':
          return Number(a.price) - Number(b.price);
        case 'price_desc':
          return Number(b.price) - Number(a.price);
        case 'name':
          return a.name.localeCompare(b.name);
        default:
          return 0;
      }
    });

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-4">Our Products</h1>
          <p className="text-gray-600">Discover authentic Rwandan products</p>
        </div>

        {/* Filters */}
        <div className="mb-8 flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <input
              type="text"
              placeholder="Search products..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          <div className="flex items-center space-x-2">
            <Filter className="w-5 h-5 text-gray-400" />
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="name">Sort by Name</option>
              <option value="price_asc">Price: Low to High</option>
              <option value="price_desc">Price: High to Low</option>
            </select>
          </div>
        </div>

        {/* Products Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {filteredProducts.map((product) => (
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
                    <Package className="w-12 h-12 text-gray-400" />
                  </div>
                )}
              </div>
              
              <div className="p-4">
                <h3 className="text-lg font-semibold text-gray-900 mb-2 line-clamp-2 group-hover:text-blue-600 transition-colors">
                  {product.name}
                </h3>
                
                <p className="text-gray-600 text-sm mb-3 line-clamp-2">
                  {product.description || 'Premium quality product from Rwanda'}
                </p>
                
                <div className="flex items-center justify-between mb-3">
                  <div className="text-xl font-bold text-blue-600">
                    {Number(product.price).toLocaleString()} {product.currency}
                  </div>
                  <div className="text-sm text-gray-500">
                    Stock: {product.stock_quantity}
                  </div>
                </div>
                
                <button className="w-full bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium transition-colors flex items-center justify-center space-x-2 disabled:opacity-50 disabled:cursor-not-allowed"
                  disabled={product.stock_quantity === 0}
                >
                  <ShoppingCart className="w-4 h-4" />
                  <span>{product.stock_quantity > 0 ? 'Add to Cart' : 'Out of Stock'}</span>
                </button>
              </div>
            </div>
          ))}
        </div>

        {filteredProducts.length === 0 && (
          <div className="text-center py-12">
            <Package className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-500 text-lg">
              {searchTerm ? 'No products found matching your search' : 'No products available'}
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Products;