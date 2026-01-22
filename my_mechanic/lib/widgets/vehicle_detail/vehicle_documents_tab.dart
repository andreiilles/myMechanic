import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/vehicle.dart';
import '../../models/vehicle_document.dart';
import '../../utils/platform_utils.dart';

class VehicleDocumentsTab extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDocumentsTab({super.key, required this.vehicle});

  @override
  State<VehicleDocumentsTab> createState() => _VehicleDocumentsTabState();
}

class _VehicleDocumentsTabState extends State<VehicleDocumentsTab> {
  final _supabase = Supabase.instance.client;
  List<VehicleDocument> _documents = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _supabase
          .from('vehicle_documents')
          .select()
          .eq('vehicle_id', widget.vehicle.id!)
          .order('uploaded_at', ascending: false);

      setState(() {
        _documents = (response as List)
            .map((json) => VehicleDocument.fromJson(json))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        _showError('Failed to load documents: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        withData: true,
      );

      if (result == null) return;

      final file = result.files.first;
      if (file.bytes == null) {
        _showError('Could not read file');
        return;
      }

      setState(() => _isUploading = true);

      // Upload to Supabase Storage
      final fileName = '${widget.vehicle.id}_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = 'vehicle_documents/$fileName';

      await _supabase.storage
          .from('vehicle-documents')
          .uploadBinary(path, file.bytes!);

      // Get public URL
      final fileUrl = _supabase.storage
          .from('vehicle-documents')
          .getPublicUrl(path);

      // Save document info to database
      final document = VehicleDocument(
        vehicleId: widget.vehicle.id!,
        documentName: file.name,
        documentType: file.extension ?? 'unknown',
        fileUrl: fileUrl,
        fileSize: file.size,
        uploadedAt: DateTime.now(),
      );

      await _supabase
          .from('vehicle_documents')
          .insert(document.toJson());

      await _loadDocuments();
      
      if (mounted) {
        _showSuccess('Document uploaded successfully');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to upload document: $e');
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteDocument(VehicleDocument document) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    try {
      // Delete from storage
      final path = document.fileUrl.split('/').last;
      await _supabase.storage
          .from('vehicle-documents')
          .remove(['vehicle_documents/$path']);

      // Delete from database
      await _supabase
          .from('vehicle_documents')
          .delete()
          .eq('id', document.id!);

      await _loadDocuments();
      
      if (mounted) {
        _showSuccess('Document deleted');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to delete document: $e');
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    if (PlatformUtils.isIOS) {
      return await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Delete Document'),
          content: const Text('Are you sure you want to delete this document?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Delete'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ) ?? false;
    }

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showError(String message) {
    if (PlatformUtils.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (!PlatformUtils.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: PlatformUtils.isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      );
    }

    if (_documents.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildUploadButton(),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _documents.length,
            itemBuilder: (context, index) {
              final document = _documents[index];
              return _buildDocumentCard(document);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PlatformUtils.isIOS ? CupertinoIcons.doc : Icons.description,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No documents',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Store insurance, registration, and other documents',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    if (PlatformUtils.isIOS) {
      return CupertinoButton.filled(
        onPressed: _isUploading ? null : _pickAndUploadDocument,
        child: _isUploading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add, size: 20),
                  SizedBox(width: 8),
                  Text('Upload Document'),
                ],
              ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : _pickAndUploadDocument,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add),
        label: const Text('Upload Document'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(VehicleDocument document) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final fileSizeMB = (document.fileSize / (1024 * 1024)).toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          _getFileIcon(document.documentType),
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          document.documentName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${dateFormat.format(document.uploadedAt)} • $fileSizeMB MB',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                PlatformUtils.isIOS ? CupertinoIcons.eye : Icons.visibility,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => _openDocument(document),
            ),
            IconButton(
              icon: Icon(
                PlatformUtils.isIOS ? CupertinoIcons.delete : Icons.delete,
                color: Colors.red,
              ),
              onPressed: () => _deleteDocument(document),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return PlatformUtils.isIOS ? CupertinoIcons.doc_text_fill : Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return PlatformUtils.isIOS ? CupertinoIcons.photo_fill : Icons.image;
      case 'doc':
      case 'docx':
        return PlatformUtils.isIOS ? CupertinoIcons.doc_fill : Icons.description;
      default:
        return PlatformUtils.isIOS ? CupertinoIcons.doc : Icons.insert_drive_file;
    }
  }

  Future<void> _openDocument(VehicleDocument document) async {
    // TODO: Implement document viewer or download
    _showError('Document viewing coming soon. URL: ${document.fileUrl}');
  }
}
