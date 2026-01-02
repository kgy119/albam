class Employee {
  final String id;
  final String workplaceId;
  final String name;
  final String phoneNumber;
  final String? contractImageUrl;
  final int hourlyWage;
  final String? bankName;
  final String? accountNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.workplaceId,
    required this.name,
    required this.phoneNumber,
    this.contractImageUrl,
    required this.hourlyWage,
    this.bankName,
    this.accountNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  // Supabase에서 데이터 가져올 때 사용
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      workplaceId: json['workplace_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      contractImageUrl: json['contract_image_url'] as String?,
      hourlyWage: json['hourly_wage'] as int? ?? 0,
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  // Supabase에 저장할 때 사용
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workplace_id': workplaceId,
      'name': name,
      'phone_number': phoneNumber,
      'contract_image_url': contractImageUrl,
      'hourly_wage': hourlyWage,
      'bank_name': bankName,
      'account_number': accountNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Insert용 (id 제외)
  Map<String, dynamic> toInsertJson() {
    return {
      'workplace_id': workplaceId,
      'name': name,
      'phone_number': phoneNumber,
      'contract_image_url': contractImageUrl,
      'hourly_wage': hourlyWage,
      'bank_name': bankName,
      'account_number': accountNumber,
      // created_at, updated_at은 DB에서 자동 생성
    };
  }

  // Update용
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'contract_image_url': contractImageUrl,
      'hourly_wage': hourlyWage,
      'bank_name': bankName,
      'account_number': accountNumber,
      // updated_at은 트리거에서 자동 업데이트
    };
  }

  // 직원 정보 복사
  Employee copyWith({
    String? name,
    String? phoneNumber,
    String? contractImageUrl,
    int? hourlyWage,
    String? bankName,
    String? accountNumber,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id,
      workplaceId: workplaceId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contractImageUrl: contractImageUrl ?? this.contractImageUrl,
      hourlyWage: hourlyWage ?? this.hourlyWage,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Employee(id: $id, name: $name, workplaceId: $workplaceId, hourlyWage: $hourlyWage)';
  }
}