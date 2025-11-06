# Vehicle Image Upload Setup

## Supabase Storage Setup

To enable vehicle image uploads, you need to set up a storage bucket in Supabase:

### Option 1: Using SQL Migration (Recommended)

Run the migration file located at:
```
supabase/migrations/create_vehicle_images_bucket.sql
```

This will:
- Create a public storage bucket called `vehicle-images`
- Set up storage policies for authenticated users to upload, update, and delete images
- Allow public read access to the images

### Option 2: Manual Setup via Supabase Dashboard

1. **Login to Supabase Dashboard**
   - Go to https://app.supabase.com
   - Select your project

2. **Create Storage Bucket**
   - Navigate to Storage in the left sidebar
   - Click "New bucket"
   - Name: `vehicle-images`
   - Public bucket: **Yes** (enable)
   - Click "Create bucket"

3. **Set Storage Policies**
   - Click on the `vehicle-images` bucket
   - Go to "Policies" tab
   - Add the following policies:

   **Upload Policy:**
   ```sql
   create policy "Users can upload vehicle images"
   on storage.objects for insert
   to authenticated
   with check (bucket_id = 'vehicle-images');
   ```

   **Update Policy:**
   ```sql
   create policy "Users can update vehicle images"
   on storage.objects for update
   to authenticated
   using (bucket_id = 'vehicle-images');
   ```

   **Delete Policy:**
   ```sql
   create policy "Users can delete vehicle images"
   on storage.objects for delete
   to authenticated
   using (bucket_id = 'vehicle-images');
   ```

   **Read Policy:**
   ```sql
   create policy "Public can view vehicle images"
   on storage.objects for select
   to public
   using (bucket_id = 'vehicle-images');
   ```

## Database Migration

Make sure you've also run the vehicle image_url column migration:
```
supabase/migrations/add_vehicle_image_url.sql
```

This adds the `image_url` column to the vehicles table.

## Features

Once set up, users can:
- Take a photo or select from gallery
- Upload vehicle images
- View uploaded images
- Remove/replace vehicle images
- Images are automatically optimized (max 1200x1200px, 85% quality)
- Old images are automatically deleted when replaced

## Platform Requirements

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos of your vehicles</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select vehicle images</string>
```

### Android
Permissions are already included in the `image_picker` package.
For Android 13+ (API 33+), additional permissions may be needed in `AndroidManifest.xml`.

## Testing

1. Run the app
2. Navigate to a vehicle detail screen
3. Tap the camera icon on the vehicle image
4. Choose "Take Photo" or "Choose from Gallery"
5. Select/take an image
6. Wait for upload to complete
7. Image should display on the vehicle

## Troubleshooting

**Upload fails:**
- Check Supabase storage bucket exists and is public
- Verify storage policies are set correctly
- Check network connection
- Ensure user is authenticated

**Image not displaying:**
- Check the image_url in the database
- Verify the URL is publicly accessible
- Check browser console for CORS errors
- Ensure storage bucket is set to public

**Permissions issues:**
- iOS: Check Info.plist has camera and photo library descriptions
- Android: Check AndroidManifest.xml has required permissions
- Restart the app after adding permissions
