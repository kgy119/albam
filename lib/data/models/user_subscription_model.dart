class UserSubscription {
  final String id;
  final String userId;
  final String tier; // 'free', 'premium'
  final String subscriptionStatus; // 'active', 'cancelled', 'expired'
  final String? purchaseToken;
  final String? productId;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final bool autoRenew;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.tier,
    required this.subscriptionStatus,
    this.purchaseToken,
    this.productId,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    required this.autoRenew,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tier: json['tier'] as String,
      subscriptionStatus: json['subscription_status'] as String,
      purchaseToken: json['purchase_token'] as String?,
      productId: json['product_id'] as String?,
      subscriptionStartDate: json['subscription_start_date'] != null
          ? DateTime.parse(json['subscription_start_date'] as String)
          : null,
      subscriptionEndDate: json['subscription_end_date'] != null
          ? DateTime.parse(json['subscription_end_date'] as String)
          : null,
      autoRenew: json['auto_renew'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tier': tier,
      'subscription_status': subscriptionStatus,
      'purchase_token': purchaseToken,
      'product_id': productId,
      'subscription_start_date': subscriptionStartDate?.toIso8601String(),
      'subscription_end_date': subscriptionEndDate?.toIso8601String(),
      'auto_renew': autoRenew,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive {
    if (subscriptionStatus != 'active') return false;
    if (subscriptionEndDate == null) return true;
    return subscriptionEndDate!.isAfter(DateTime.now());
  }

  bool get isPremium => tier == 'premium' && isActive;
}