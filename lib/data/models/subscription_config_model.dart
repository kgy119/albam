class SubscriptionConfig {
  final String id;
  final String tier; // 'free', 'premium'
  final int maxWorkplaces;
  final int maxEmployeesPerWorkplace;
  final int price;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionConfig({
    required this.id,
    required this.tier,
    required this.maxWorkplaces,
    required this.maxEmployeesPerWorkplace,
    required this.price,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionConfig.fromJson(Map<String, dynamic> json) {
    return SubscriptionConfig(
      id: json['id'] as String,
      tier: json['tier'] as String,
      maxWorkplaces: json['max_workplaces'] as int,
      maxEmployeesPerWorkplace: json['max_employees_per_workplace'] as int,
      price: json['price'] as int,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tier': tier,
      'max_workplaces': maxWorkplaces,
      'max_employees_per_workplace': maxEmployeesPerWorkplace,
      'price': price,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}