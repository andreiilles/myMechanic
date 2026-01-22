-- Create vehicle_documents table
CREATE TABLE vehicle_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    document_name TEXT NOT NULL,
    document_type TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index on vehicle_id for faster queries
CREATE INDEX idx_vehicle_documents_vehicle_id ON vehicle_documents(vehicle_id);

-- Enable RLS
ALTER TABLE vehicle_documents ENABLE ROW LEVEL SECURITY;

-- RLS Policies for vehicle_documents
-- Users can view documents for their own vehicles
CREATE POLICY "Users can view their own vehicle documents"
    ON vehicle_documents
    FOR SELECT
    USING (
        vehicle_id IN (
            SELECT id FROM vehicles WHERE user_id = auth.uid()
        )
    );

-- Users can insert documents for their own vehicles
CREATE POLICY "Users can insert documents for their own vehicles"
    ON vehicle_documents
    FOR INSERT
    WITH CHECK (
        vehicle_id IN (
            SELECT id FROM vehicles WHERE user_id = auth.uid()
        )
    );

-- Users can update documents for their own vehicles
CREATE POLICY "Users can update their own vehicle documents"
    ON vehicle_documents
    FOR UPDATE
    USING (
        vehicle_id IN (
            SELECT id FROM vehicles WHERE user_id = auth.uid()
        )
    );

-- Users can delete documents for their own vehicles
CREATE POLICY "Users can delete their own vehicle documents"
    ON vehicle_documents
    FOR DELETE
    USING (
        vehicle_id IN (
            SELECT id FROM vehicles WHERE user_id = auth.uid()
        )
    );

-- Create storage bucket for vehicle documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('vehicle-documents', 'vehicle-documents', true);

-- Storage policies
-- Users can upload documents for their own vehicles
CREATE POLICY "Users can upload documents for their own vehicles"
    ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'vehicle-documents' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can view their own vehicle documents
CREATE POLICY "Users can view their own vehicle documents"
    ON storage.objects
    FOR SELECT
    USING (bucket_id = 'vehicle-documents');

-- Users can delete their own vehicle documents
CREATE POLICY "Users can delete their own vehicle documents"
    ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'vehicle-documents' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );
