import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reward_configuration.dart';
import '../services/reward_service.dart';
import '../providers/auth_provider.dart';

class RewardSettingsScreen extends StatefulWidget {
  const RewardSettingsScreen({super.key});

  @override
  _RewardSettingsScreenState createState() => _RewardSettingsScreenState();
}

class _RewardSettingsScreenState extends State<RewardSettingsScreen> {
  final RewardService _rewardService = RewardService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _cashbackController = TextEditingController();
  final _maxUsagePercentController = TextEditingController();
  final _maxUsageFlatController = TextEditingController();
  final _conversionRateController = TextEditingController();
  final _referralRewardController = TextEditingController();
  final _refereeRewardController = TextEditingController();
  final _minReferralOrderController = TextEditingController();
  bool _isActive = true;
  bool _isReferralEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchConfig();
  }

  // Using _fetchData instead of _fetchConfig to avoid naming collision if any,
  // but the code actually used _fetchConfig. Let's stick to what's there.
  Future<void> _fetchConfig() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        final config = await _rewardService.getRewardConfiguration(token);
        setState(() {
          _cashbackController.text = config.cashbackPercentage.toString();
          _maxUsagePercentController.text = config.maxRewardUsagePercent
              .toString();
          _maxUsageFlatController.text = config.maxRewardUsageFlat.toString();
          _conversionRateController.text = config.conversionRate.toString();
          _referralRewardController.text = config.referralRewardPoints
              .toString();
          _refereeRewardController.text = config.refereeRewardPoints.toString();
          _minReferralOrderController.text = config.minReferralOrderAmount
              .toString();
          _isActive = config.isActive;
          _isReferralEnabled = config.isReferralEnabled;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        final newConfig = RewardConfiguration(
          cashbackPercentage: double.parse(_cashbackController.text),
          maxRewardUsagePercent: double.parse(_maxUsagePercentController.text),
          maxRewardUsageFlat: double.parse(_maxUsageFlatController.text),
          conversionRate: double.parse(_conversionRateController.text),
          referralRewardPoints: double.parse(_referralRewardController.text),
          refereeRewardPoints: double.parse(_refereeRewardController.text),
          minReferralOrderAmount: double.parse(
            _minReferralOrderController.text,
          ),
          isActive: _isActive,
          isReferralEnabled: _isReferralEnabled,
        );

        await _rewardService.updateRewardConfiguration(token, newConfig);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reward Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Rewards Program'),
                      value: _isActive,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _cashbackController,
                      decoration: const InputDecoration(
                        labelText: 'Cashback Percentage (%)',
                        helperText: 'Percentage of order value given as points',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maxUsagePercentController,
                      decoration: const InputDecoration(
                        labelText: 'Max Usage Percentage (%)',
                        helperText:
                            'Max % of order capable of being paid with points',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maxUsageFlatController,
                      decoration: const InputDecoration(
                        labelText: 'Max Usage Flat Amount',
                        helperText:
                            'Max flat amount capable of being paid with points',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _conversionRateController,
                      decoration: const InputDecoration(
                        labelText: 'Conversion Rate',
                        helperText: 'Value of 1 point in currency',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const Text(
                      'Referral Program Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Enable Referral Program'),
                      value: _isReferralEnabled,
                      onChanged: (val) =>
                          setState(() => _isReferralEnabled = val),
                    ),
                    if (_isReferralEnabled) ...[
                      TextFormField(
                        controller: _referralRewardController,
                        decoration: const InputDecoration(
                          labelText: 'Referrer Reward Points',
                          helperText: 'Points awarded to the person who refers',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _refereeRewardController,
                        decoration: const InputDecoration(
                          labelText: 'Referee Reward Points',
                          helperText: 'Points awarded to the new customer',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _minReferralOrderController,
                        decoration: const InputDecoration(
                          labelText: 'Min Order Amount for Referral Reward',
                          helperText:
                              'Minimum first order value to trigger rewards',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveConfig,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Save Settings'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
