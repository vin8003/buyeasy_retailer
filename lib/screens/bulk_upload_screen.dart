import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../providers/auth_provider.dart';

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  final ProductService _productService = ProductService();
  File? _selectedFile;
  bool _isLoading = false;
  String? _uploadError;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _uploadError = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() {
      _isLoading = true;
      _uploadError = null;
    });

    try {
      final result = await _productService.uploadProducts(
        token,
        _selectedFile!,
      );

      if (mounted) {
        _showResultDialog(result);
        setState(() {
          _selectedFile = null; // Clear selection on success
        });
      }
    } catch (e) {
      setState(() {
        _uploadError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    // result keys: message, total_rows, successful_rows, failed_rows, error_log (list)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Complete'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result['message'] ?? 'Upload processed'),
              const SizedBox(height: 16),
              _buildStat('Total Rows:', result['total_rows']),
              _buildStat(
                'Successful:',
                result['successful_rows'],
                color: Colors.green,
              ),
              _buildStat('Failed:', result['failed_rows'], color: Colors.red),

              if (result['error_log'] != null &&
                  (result['error_log'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Errors:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: (result['error_log'] as List).length,
                    itemBuilder: (context, index) {
                      final error = (result['error_log'] as List)[index];
                      return ListTile(
                        title: Text('Row ${error['row']}'),
                        subtitle: Text(error['error']),
                        dense: true,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, dynamic value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Text(
            value.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Product Upload')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Products via CSV/Excel',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supported formats: .csv, .xlsx\nRequired columns: name, price, quantity\nOptional columns: category, brand, description, image, unit',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // File Selection Area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile == null
                        ? Icons.upload_file
                        : Icons.description,
                    size: 48,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  if (_selectedFile != null) ...[
                    Text(
                      _selectedFile!.path.split('/').last,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickFile,
                      child: const Text('Change File'),
                    ),
                  ] else
                    ElevatedButton(
                      onPressed: _pickFile,
                      child: const Text('Select File'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_uploadError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _uploadError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedFile == null || _isLoading
                    ? null
                    : _uploadFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Upload Products'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
