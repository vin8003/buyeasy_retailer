import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/firebase_auth_service.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const PhoneVerificationScreen({super.key, required this.phoneNumber});

  @override
  _PhoneVerificationScreenState createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _otpController = TextEditingController();
  late final TextEditingController _phoneController;
  final _firebaseAuthService = FirebaseAuthService();

  bool _isLoading = false;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    String phone = widget.phoneNumber;
    // Standardize phone format if needed, assuming +91 for now as per mobile app
    if (phone.startsWith('+91')) {
      phone = phone.substring(3);
    }
    _phoneController = TextEditingController(text: phone);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendFirebaseOtp();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendFirebaseOtp() async {
    setState(() => _isLoading = true);
    final phone = '+91${_phoneController.text.trim()}';

    try {
      await _firebaseAuthService.verifyPhoneNumber(
        phoneNumber: phone,
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        onVerificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showSnackBar('Verification failed: ${e.message}', isError: true);
        },
        onCodeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
          });
          _showSnackBar('OTP sent successfully');
        },
        onCodeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _verificationId = verificationId);
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error sending OTP: $e', isError: true);
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      setState(() => _isLoading = true);
      final userCredential = await _firebaseAuthService.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        final idToken = await user.getIdToken();
        final phone = '+91${_phoneController.text.trim()}';

        await context.read<app_auth.AuthProvider>().verifyOtp(
          phone,
          firebaseToken: idToken,
        );

        _showSnackBar('Phone verified successfully!');
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _manualVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnackBar('Please enter a valid 6-digit OTP', isError: true);
      return;
    }

    if (_verificationId == null) {
      _showSnackBar('Please wait for OTP to be sent', isError: true);
      return;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    await _signInWithCredential(credential);
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
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: 'OTP Code'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _manualVerify,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Verify'),
            ),
            TextButton(
              onPressed: _isLoading ? null : _sendFirebaseOtp,
              child: const Text('Resend OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
