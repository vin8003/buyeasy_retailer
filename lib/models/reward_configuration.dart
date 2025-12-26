class RewardConfiguration {
  final double cashbackPercentage;
  final double maxRewardUsagePercent;
  final double maxRewardUsageFlat;
  final double conversionRate;
  final bool isActive;
  final bool isReferralEnabled;
  final double referralRewardPoints;
  final double refereeRewardPoints;
  final double minReferralOrderAmount;

  RewardConfiguration({
    required this.cashbackPercentage,
    required this.maxRewardUsagePercent,
    required this.maxRewardUsageFlat,
    required this.conversionRate,
    required this.isActive,
    this.isReferralEnabled = false,
    this.referralRewardPoints = 0,
    this.refereeRewardPoints = 0,
    this.minReferralOrderAmount = 0,
  });

  factory RewardConfiguration.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return RewardConfiguration(
      cashbackPercentage: parseDouble(json['cashback_percentage']),
      maxRewardUsagePercent: parseDouble(json['max_reward_usage_percent']),
      maxRewardUsageFlat: parseDouble(json['max_reward_usage_flat']),
      conversionRate: parseDouble(json['conversion_rate']),
      isActive: json['is_active'] ?? true,
      isReferralEnabled: json['is_referral_enabled'] ?? false,
      referralRewardPoints: parseDouble(json['referral_reward_points']),
      refereeRewardPoints: parseDouble(json['referee_reward_points']),
      minReferralOrderAmount: parseDouble(json['min_referral_order_amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cashback_percentage': cashbackPercentage,
      'max_reward_usage_percent': maxRewardUsagePercent,
      'max_reward_usage_flat': maxRewardUsageFlat,
      'conversion_rate': conversionRate,
      'is_active': isActive,
      'is_referral_enabled': isReferralEnabled,
      'referral_reward_points': referralRewardPoints,
      'referee_reward_points': refereeRewardPoints,
      'min_referral_order_amount': minReferralOrderAmount,
    };
  }
}
