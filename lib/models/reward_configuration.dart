class RewardConfiguration {
  final double cashbackPercentage;
  final double maxRewardUsagePercent;
  final double maxRewardUsageFlat;
  final double conversionRate;
  final bool isActive;

  RewardConfiguration({
    required this.cashbackPercentage,
    required this.maxRewardUsagePercent,
    required this.maxRewardUsageFlat,
    required this.conversionRate,
    required this.isActive,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cashback_percentage': cashbackPercentage,
      'max_reward_usage_percent': maxRewardUsagePercent,
      'max_reward_usage_flat': maxRewardUsageFlat,
      'conversion_rate': conversionRate,
      'is_active': isActive,
    };
  }
}
