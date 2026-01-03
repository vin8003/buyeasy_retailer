import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final bool autoRequestOtp;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.autoRequestOtp = true,
  });

  @override
  _PhoneVerificationScreenState createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _otpController = TextEditingController();
  late final TextEditingController _phoneController;

  bool _isCodeSent = false;
  // Use a flag for auto-send
  bool _hasAutoSent = false;

  @override
  void initState() {
    super.initState();
    String phone = widget.phoneNumber;
    // Standardize phone format
    if (phone.startsWith('+91')) {
      phone = phone.substring(3);
    }
    _phoneController = TextEditingController(text: phone);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoRequestOtp && !_hasAutoSent) {
        _sendBackendOtp();
        _hasAutoSent = true;
      } else if (!widget.autoRequestOtp) {
        setState(() {
          _isCodeSent = true;
          _hasAutoSent = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendBackendOtp() async {
    try {
      await context.read<app_auth.AuthProvider>().requestPhoneVerification();
      setState(() {
        _isCodeSent = true;
      });
      _showSnackBar('OTP sent successfully');
    } catch (e) {
      _showSnackBar('Error sending OTP: $e', isError: true);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnackBar('Please enter a valid 6-digit OTP', isError: true);
      return;
    }

    try {
      final phone = '+91${_phoneController.text.trim()}';
      await context.read<app_auth.AuthProvider>().verifyOtp(phone, otp: otp);

      _showSnackBar('Phone verified successfully!');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<app_auth.AuthProvider>().isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Enter the OTP sent to your phone number'),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixText: '+91 ',
              ),
              enabled: !_isCodeSent,
            ),
            const SizedBox(height: 16),
            if (_isCodeSent)
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'OTP Code'),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            const SizedBox(height: 24),

            if (_isCodeSent)
              ElevatedButton(
                onPressed: isLoading ? null : _verifyOtp,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Verify'),
              )
            else
              ElevatedButton(
                onPressed: isLoading ? null : _sendBackendOtp,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Send OTP'),
              ),

            if (_isCodeSent)
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        setState(() {
                          _isCodeSent = false;
                        });
                      },
                child: const Text('Change Number / Resend'),
              ),
          ],
        ),
      ),
    );
  }
}
