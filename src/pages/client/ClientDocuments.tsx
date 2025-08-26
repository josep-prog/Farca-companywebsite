import React, { useEffect, useState } from 'react';
import { format } from 'date-fns';
import { supabase } from '../../lib/supabase';
import { Download, Eye, FileText } from 'lucide-react';

interface Document {
  id: string;
  title: string;
  description: string | null;
  file_url: string;
  file_type: string | null;
  created_at: string;
}

const ClientDocuments: React.FC = () => {
  const [documents, setDocuments] = useState<Document[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDocuments();
  }, []);

  const fetchDocuments = async () => {
    try {
      const { data, error } = await supabase
        .from('documents')
        .select('*')
        .eq('is_public', true)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setDocuments(data || []);
    } catch (error) {
      console.error('Error fetching documents:', error);
    } finally {
      setLoading(false);
    }
  };

  const getFileIcon = (fileType: string | null) => {
    if (!fileType) return FileText;
    if (fileType.includes('pdf')) return FileText;
    if (fileType.includes('image')) return Eye;
    if (fileType.includes('video')) return Eye;
    return FileText;
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
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Documents</h1>
        <p className="text-gray-600">Access and download available documents</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {documents.map((doc) => {
          const FileIcon = getFileIcon(doc.file_type);
          return (
            <div key={doc.id} className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-shadow">
              <div className="p-6">
                <div className="flex items-start justify-between mb-4">
                  <FileIcon className="w-8 h-8 text-blue-600" />
                  <span className="text-xs text-gray-500">
                    {format(new Date(doc.created_at), 'MMM dd, yyyy')}
                  </span>
                </div>
                
                <h3 className="text-lg font-semibold text-gray-900 mb-2 line-clamp-2">
                  {doc.title}
                </h3>
                
                {doc.description && (
                  <p className="text-gray-600 text-sm mb-4 line-clamp-3">
                    {doc.description}
                  </p>
                )}
                
                <div className="flex space-x-2 mt-auto">
                  <a
                    href={doc.file_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex-1 bg-blue-50 hover:bg-blue-100 text-blue-700 px-3 py-2 rounded-lg text-sm font-medium transition-colors flex items-center justify-center space-x-1"
                  >
                    <Eye className="w-4 h-4" />
                    <span>View</span>
                  </a>
                  
                  <a
                    href={doc.file_url}
                    download
                    className="flex-1 bg-green-50 hover:bg-green-100 text-green-700 px-3 py-2 rounded-lg text-sm font-medium transition-colors flex items-center justify-center space-x-1"
                  >
                    <Download className="w-4 h-4" />
                    <span>Download</span>
                  </a>
                </div>
                
                {doc.file_type && (
                  <div className="mt-3 pt-3 border-t border-gray-100">
                    <span className="text-xs text-gray-500">
                      File type: {doc.file_type}
                    </span>
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {documents.length === 0 && (
        <div className="text-center py-12">
          <FileText className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <p className="text-gray-500 text-lg">No documents available</p>
          <p className="text-gray-400 text-sm">Check back later for new documents</p>
        </div>
      )}
    </div>
  );
};

export default ClientDocuments;