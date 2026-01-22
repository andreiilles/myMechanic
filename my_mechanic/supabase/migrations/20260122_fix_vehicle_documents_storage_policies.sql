-- Fix storage policies for vehicle documents
-- The original policies were too restrictive and prevented users from uploading documents

-- Drop existing storage policies for vehicle-documents bucket
DROP POLICY IF EXISTS "Users can upload documents for their own vehicles" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own vehicle documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own vehicle documents" ON storage.objects;

-- Create new storage policies that work with the actual file structure
-- Files are stored as: vehicle_documents/{vehicle_id}_{timestamp}_{filename}

-- Policy for uploading documents
-- Users can upload documents if they own the vehicle
CREATE POLICY "Users can upload vehicle documents"
    ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'vehicle-documents' AND
        auth.uid() IS NOT NULL AND
        -- Extract vehicle_id from the path and verify ownership
        (split_part((storage.foldername(name))[2], '_', 1))::uuid IN (
            SELECT id FROM vehicles WHERE owner_id = auth.uid()
        )
    );

-- Policy for viewing documents
-- Users can view documents for their own vehicles
CREATE POLICY "Users can view vehicle documents"
    ON storage.objects
    FOR SELECT
    USING (
        bucket_id = 'vehicle-documents' AND
        auth.uid() IS NOT NULL AND
        -- Extract vehicle_id from the path and verify ownership
        (split_part((storage.foldername(name))[2], '_', 1))::uuid IN (
            SELECT id FROM vehicles WHERE owner_id = auth.uid()
        )
    );

-- Policy for deleting documents
-- Users can delete documents for their own vehicles
CREATE POLICY "Users can delete vehicle documents"
    ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'vehicle-documents' AND
        auth.uid() IS NOT NULL AND
        -- Extract vehicle_id from the path and verify ownership
        (split_part((storage.foldername(name))[2], '_', 1))::uuid IN (
            SELECT id FROM vehicles WHERE owner_id = auth.uid()
        )
    );

-- Also allow mechanics to view documents for vehicles they have access to
CREATE POLICY "Mechanics can view vehicle documents"
    ON storage.objects
    FOR SELECT
    USING (
        bucket_id = 'vehicle-documents' AND
        auth.uid() IS NOT NULL AND
        -- Extract vehicle_id from the path and check mechanic access
        (split_part((storage.foldername(name))[2], '_', 1))::uuid IN (
            SELECT vehicle_id 
            FROM vehicle_access 
            WHERE user_id = auth.uid()
        )
    );
