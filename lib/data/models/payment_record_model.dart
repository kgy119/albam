class PaymentRecord {
  final String id;
  final String employeeId;
  final int year;
  final int month;
  final double amount;
  final DateTime paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentRecord({
    required this.id,
    required this.employeeId,
    required this.year,
    required this.month,
    required this.amount,
    required this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      year: json['year'] as int,
      month: json['month'] as int,
      amount: (json['amount'] as num).toDouble(),
      paidAt: DateTime.parse(json['paid_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'year': year,
      'month': month,
      'amount': amount,
      'paid_at': paidAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}