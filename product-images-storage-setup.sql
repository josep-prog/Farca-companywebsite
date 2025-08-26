-- Create the product-images storage bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('product-images', 'product-images', true);

-- Create policy to allow authenticated users to upload images
CREATE POLICY "Allow authenticated users to upload product images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'product-images');

-- Create policy to allow public read access to product images
CREATE POLICY "Allow public access to product images" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'product-images');

-- Create policy to allow authenticated users to update their uploaded images
CREATE POLICY "Allow authenticated users to update product images" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'product-images');

-- Create policy to allow authenticated users to delete product images
CREATE POLICY "Allow authenticated users to delete product images" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'product-images');
