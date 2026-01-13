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
      tier: json['tier'] as String,
      maxWorkplaces: json['max_workplaces'] as int,
      maxEmployeesPerWorkplace: json['max_employees_per_workplace'] as int,
      currentWorkplaceCount: json['current_workplace_count'] as int,
      canAddWorkplace: json['can_add_workplace'] as bool,
      price: json['price'] as int,
      description: json['description'] as String?,
    );
  }

  bool get isPremium => tier == 'premium';
  bool get isFree => tier == 'free';

  int get remainingWorkplaces => maxWorkplaces - currentWorkplaceCount;
}