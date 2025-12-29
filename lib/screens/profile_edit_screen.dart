import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'phone_verification_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserModel user;

  const ProfileEditScreen({super.key, required this.user});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info
  late TextEditingController _shopNameController;
  late TextEditingController _shopDescriptionController;

  // Contact Info
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _whatsappNumberController;

  // Address Info
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _countryController;

  // Business Info
  late TextEditingController _businessTypeController;
  late TextEditingController _gstNumberController;
  late TextEditingController _panNumberController;

  // Service Settings
  late TextEditingController _deliveryRadiusController;
  late TextEditingController _pincodesController;
  late TextEditingController _minOrderAmountController;
  bool _offersDelivery = true;
  bool _offersPickup = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController(text: widget.user.shopName);
    _shopDescriptionController = TextEditingController(
      text: widget.user.shopDescription,
    );

    _contactEmailController = TextEditingController(
      text: widget.user.contactEmail,
    );
    _contactPhoneController = TextEditingController(
      text: widget.user.contactPhone,
    );
    _whatsappNumberController = TextEditingController(
      text: widget.user.whatsappNumber,
    );

    _addressLine1Controller = TextEditingController(
      text: widget.user.addressLine1,
    );
    _addressLine2Controller = TextEditingController(
      text: widget.user.addressLine2,
    );
    _cityController = TextEditingController(text: widget.user.city);
    _stateController = TextEditingController(text: widget.user.state);
    _pincodeController = TextEditingController(text: widget.user.pincode);
    _countryController = TextEditingController(text: widget.user.country);

    _businessTypeController = TextEditingController(
      text: widget.user.businessType,
    );
    _gstNumberController = TextEditingController(text: widget.user.gstNumber);
    _panNumberController = TextEditingController(text: widget.user.panNumber);

    _deliveryRadiusController = TextEditingController(
      text: widget.user.deliveryRadius.toString(),
    );
    _pincodesController = TextEditingController(
      text: widget.user.serviceablePincodes.join(', '),
    );
    _minOrderAmountController = TextEditingController(
      text: widget.user.minimumOrderAmount.toString(),
    );

    _offersDelivery = widget.user.offersDelivery;
    _offersPickup = widget.user.offersPickup;
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopDescriptionController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _whatsappNumberController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _businessTypeController.dispose();
    _gstNumberController.dispose();
    _panNumberController.dispose();
    _deliveryRadiusController.dispose();
    _pincodesController.dispose();
    _minOrderAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final pincodesList = _pincodesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.length == 6)
          .toList();

      final data = {
        'shop_name': _shopNameController.text,
        'shop_description': _shopDescriptionController.text,
        'contact_email': _contactEmailController.text,
        'contact_phone': _contactPhoneController.text,
        'whatsapp_number': _whatsappNumberController.text,
        'address_line1': _addressLine1Controller.text,
        'address_line2': _addressLine2Controller.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
        'country': _countryController.text,
        'business_type': _businessTypeController.text,
        'gst_number': _gstNumberController.text,
        'pan_number': _panNumberController.text,
        'offers_delivery': _offersDelivery,
        'offers_pickup': _offersPickup,
        'delivery_radius': int.parse(_deliveryRadiusController.text),
        'serviceable_pincodes': pincodesList,
        'minimum_order_amount': double.parse(_minOrderAmountController.text),
      };

      await context.read<AuthProvider>().updateProfile(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Full Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.user.isPhoneVerified) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Your phone number is not verified.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhoneVerificationScreen(
                                phoneNumber: widget.user.phoneNumber,
                              ),
                            ),
                          );
                        },
                        child: const Text('Verify'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              _buildSectionHeader('Basic Store Information'),
              _buildTextField(_shopNameController, 'Shop Name', required: true),
              _buildTextField(
                _shopDescriptionController,
                'Shop Description',
                maxLines: 3,
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('Contact Information'),
              _buildTextField(
                _contactEmailController,
                'Contact Email',
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                _contactPhoneController,
                'Contact Phone',
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                _whatsappNumberController,
                'WhatsApp Number',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('Address Details'),
              _buildTextField(
                _addressLine1Controller,
                'Address Line 1',
                required: true,
              ),
              _buildTextField(_addressLine2Controller, 'Address Line 2'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _cityController,
                      'City',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      _stateController,
                      'State',
                      required: true,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _pincodeController,
                      'Pincode',
                      required: true,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      _countryController,
                      'Country',
                      required: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('Business Information'),
              _buildTextField(_businessTypeController, 'Business Type'),
              _buildTextField(_gstNumberController, 'GST Number'),
              _buildTextField(_panNumberController, 'PAN Number'),

              const SizedBox(height: 32),
              _buildSectionHeader('Service & Delivery Settings'),
              SwitchListTile(
                title: const Text('Offers Delivery'),
                value: _offersDelivery,
                onChanged: (val) => setState(() => _offersDelivery = val),
              ),
              SwitchListTile(
                title: const Text('Offers Pickup'),
                value: _offersPickup,
                onChanged: (val) => setState(() => _offersPickup = val),
              ),
              _buildTextField(
                _deliveryRadiusController,
                'Delivery Radius (km)',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                _minOrderAmountController,
                'Minimum Order Amount',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                _pincodesController,
                'Serviceable Pincodes',
                helperText: 'Comma separated 6-digit codes',
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final codes = value.split(',').map((e) => e.trim());
                    for (var code in codes) {
                      if (code.isNotEmpty &&
                          (code.length != 6 || int.tryParse(code) == null)) {
                        return 'Invalid pincode: $code';
                      }
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Full Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Divider(thickness: 1),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator:
            validator ??
            (value) {
              if (required && (value == null || value.isEmpty)) {
                return 'Please enter $label';
              }
              return null;
            },
      ),
    );
  }
}
