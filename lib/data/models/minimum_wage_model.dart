class MinimumWageModel {
  final int year;
  final int wage;
  final DateTime effectiveDate;

  MinimumWageModel({
    required this.year,
    required this.wage,
    required this.effectiveDate,
  });

  // Supabase에서 데이터 가져올 때 사용
  factory MinimumWageModel.fromJson(Map<String, dynamic> json) {
    return MinimumWageModel(
      year: json['year'] as int? ?? 0,
      wage: json['wage'] as int? ?? 0,
      effectiveDate: json['effective_date'] != null
          ? DateTime.parse(json['effective_date'] as String)
          : DateTime.now(),
    );
  }

  // Supabase에 저장할 때 사용
  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'wage': wage,
      'effective_date': effectiveDate.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'MinimumWage(year: $year, wage: $wage)';
  }
}