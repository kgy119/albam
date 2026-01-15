class SubscriptionLimits {
  final String tier;
  final int maxWorkplaces;
  final int maxEmployeesPerWorkplace;
  final int currentWorkplaceCount;
  final bool canAddWorkplace;
  final int price;
  final String? description;

  SubscriptionLimits({
    required this.tier,
    required this.maxWorkplaces,
    required this.maxEmployeesPerWorkplace,
    required this.currentWorkplaceCount,
    required this.canAddWorkplace,
    required this.price,
    this.description,
  });

  factory SubscriptionLimits.fromJson(Map<String, dynamic> json) {
    return SubscriptionLimits(
      tier: json['tier'] as String? ?? 'free',
      maxWorkplaces: (json['max_workplaces'] as int?) ?? 1,
      maxEmployeesPerWorkplace: (json['max_employees_per_workplace'] as int?) ?? 3,
      currentWorkplaceCount: (json['current_workplaces'] as int?) ?? 0,
      canAddWorkplace: (json['can_add_workplace'] as bool?) ?? false,
      price: (json['price'] as int?) ?? 0,
      description: json['description'] as String?,
    );
  }

  bool get isPremium => tier == 'premium';
  bool get isFree => tier == 'free';

  int get remainingWorkplaces => maxWorkplaces - currentWorkplaceCount;
}