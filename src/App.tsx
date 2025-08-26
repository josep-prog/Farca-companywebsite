import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import Layout from './components/Layout/Layout';
import DashboardLayout from './components/Dashboard/DashboardLayout';
import PrivateRoute from './components/PrivateRoute';
import Home from './pages/Home';
import Products from './pages/Products';
import Login from './pages/Login';
import Register from './pages/Register';

// Admin Pages
import AdminDashboard from './pages/admin/AdminDashboard';
import AdminOrders from './pages/admin/AdminOrders';
import AdminClients from './pages/admin/AdminClients';
import AdminProducts from './pages/admin/AdminProducts';
import AdminDocuments from './pages/admin/AdminDocuments';

// Client Pages
import ClientDashboard from './pages/client/ClientDashboard';
import ClientOrders from './pages/client/ClientOrders';
import ClientDocuments from './pages/client/ClientDocuments';

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          {/* Public Routes */}
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          
          {/* Routes with Layout */}
          <Route path="/" element={
            <Layout>
              <Home />
            </Layout>
          } />
          
          <Route path="/products" element={
            <Layout>
              <Products />
            </Layout>
          } />

          {/* Admin Dashboard Routes */}
          <Route path="/admin" element={
            <PrivateRoute adminOnly>
              <DashboardLayout>
                <AdminDashboard />
              </DashboardLayout>
            </PrivateRoute>
          } />
          
          <Route path="/admin/orders" element={
            <PrivateRoute adminOnly>
              <DashboardLayout>
                <AdminOrders />
              </DashboardLayout>
            </PrivateRoute>
          } />
          
          <Route path="/admin/clients" element={
            <PrivateRoute adminOnly>
              <DashboardLayout>
                <AdminClients />
              </DashboardLayout>
            </PrivateRoute>
          } />
          
          <Route path="/admin/products" element={
            <PrivateRoute adminOnly>
              <DashboardLayout>
                <AdminProducts />
              </DashboardLayout>
            </PrivateRoute>
          } />
          
          <Route path="/admin/documents" element={
            <PrivateRoute adminOnly>
              <DashboardLayout>
                <AdminDocuments />
              </DashboardLayout>
            </PrivateRoute>
          } />

          {/* Client Dashboard Routes */}
          <Route path="/dashboard" element={
            <PrivateRoute>
              <DashboardLayout>
                <ClientDashboard />
              </DashboardLayout>
            </PrivateRoute>
          } />
          
          <Route path="/dashboard/orders" element={
            <PrivateRoute>
              <DashboardLayout>
                <ClientOrders />
              </DashboardLayout>
            </PrivateRoute>
          } />
          
          <Route path="/dashboard/documents" element={
            <PrivateRoute>
              <DashboardLayout>
                <ClientDocuments />
              </DashboardLayout>
            </PrivateRoute>
          } />

          {/* Catch all route */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;