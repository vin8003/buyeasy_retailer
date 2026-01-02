import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  final ProductService _productService = ProductService();
  XFile? _selectedFile;
  bool _isLoading = false;
  String? _uploadError;

  // New state variables for 2-step flow
  int _currentStep = 0; // 0: Check, 1: Complete
  Map<String, dynamic>? _checkResult;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single.xFile;
          _uploadError = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  void _reset() {
    setState(() {
      _currentStep = 0;
      _selectedFile = null;
      _checkResult = null;
      _uploadError = null;
    });
  }

  Future<void> _processUpload() async {
    if (_selectedFile == null) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() {
      _isLoading = true;
      _uploadError = null;
    });

    try {
      if (_currentStep == 0) {
        // Step 1: Check
        final result = await _productService.checkBulkUpload(
          token,
          _selectedFile!,
        );
        setState(() {
          _checkResult = result;
          // Clean up file selection after check
          _selectedFile = null;
        });
      } else {
        // Step 2: Complete
        final result = await _productService.completeBulkUpload(
          token,
          _selectedFile!,
        );
        if (mounted) {
          _showFinalSuccessDialog(result);
        }
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

  void _showFinalSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result['message'] ?? 'Products added successfully'),
            const SizedBox(height: 10),
            Text('Success: ${result['success_count']}'),
            Text('Failed: ${result['failed_count']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _reset(); // Reset screen
            },
            child: const Text('New Upload'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(ctx); // Close screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(String url, String filename) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error downloading file: $e')));
    }
  }

  Widget _buildStep1Check() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Check & Match',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload your product list (CSV/Excel) to check against our Master Catalog.\n'
          'Matches will be added automatically.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildFilePicker(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _selectedFile == null || _isLoading
                ? null
                : _processUpload,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Check Products'),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Review() {
    if (_checkResult == null) return const SizedBox.shrink();

    final matchedCount = _checkResult!['matched_count'] ?? 0;
    final unmatchedCount = _checkResult!['unmatched_count'] ?? 0;
    final matchedUrl = _checkResult!['matched_file_url'];
    final unmatchedUrl = _checkResult!['unmatched_file_url'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Review Results',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              _buildStat(
                'Matched Products (Added):',
                matchedCount,
                color: Colors.green,
              ),
              if (matchedCount > 0 && matchedUrl != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _downloadFile(matchedUrl, 'matched.xlsx'),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download Report'),
                  ),
                ),
              const Divider(),
              _buildStat(
                'Unmatched Products:',
                unmatchedCount,
                color: Colors.orange,
              ),
              if (unmatchedCount > 0 && unmatchedUrl != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'These products were not found in the Master Catalog.\n'
                  'Download the template below, fill in the details, and upload it to complete the process.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      _downloadFile(unmatchedUrl, 'unmatched_template.xlsx'),
                  icon: const Icon(Icons.download),
                  label: const Text('Download Unmatched Template'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (unmatchedCount > 0) ...[
          const Text(
            'Upload Filled Template (Unmatched)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildFilePicker(label: 'Select Filled Template'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedFile == null || _isLoading
                  ? null
                  : () {
                      setState(() {
                        _currentStep = 1;
                      });
                      _processUpload();
                    },
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Complete Upload'),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _reset,
              child: const Text('Start New Upload'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilePicker({String label = 'Select File'}) {
    return Container(
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
            _selectedFile == null ? Icons.upload_file : Icons.description,
            size: 48,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          if (_selectedFile != null) ...[
            Text(
              _selectedFile!.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _pickFile, child: const Text('Change File')),
          ] else
            ElevatedButton(onPressed: _pickFile, child: Text(label)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, dynamic value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Product Upload'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (_uploadError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _uploadError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            if (_checkResult == null)
              _buildStep1Check()
            else
              _buildStep2Review(),
          ],
        ),
      ),
    );
  }
}
