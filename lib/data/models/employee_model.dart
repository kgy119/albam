class Employee {
  final String id;
  final String workplaceId;
  final String name;
  final String phoneNumber;
  final String? contractImageUrl;
  final int hourlyWage;
  final String? bankName;
  final String? accountNumber;
  final String employmentStatus; // ✅ 추가
  final DateTime? resignedAt; // ✅ 추가
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
    this.employmentStatus = 'active', // ✅ 기본값
    this.resignedAt, // ✅ 추가
    required this.createdAt,
    required this.updatedAt,
  });

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
      employmentStatus: json['employment_status'] as String? ?? 'active', // ✅ 추가
      resignedAt: json['resigned_at'] != null // ✅ 추가
          ? DateTime.parse(json['resigned_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

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
      'employment_status': employmentStatus, // ✅ 추가
      'resigned_at': resignedAt?.toIso8601String(), // ✅ 추가
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ✅ 퇴사 여부 확인 헬퍼
  bool get isActive => employmentStatus == 'active';
  bool get isResigned => employmentStatus == 'resigned';

  Employee copyWith({
    String? name,
    String? phoneNumber,
    String? contractImageUrl,
    int? hourlyWage,
    String? bankName,
    String? accountNumber,
    String? employmentStatus, // ✅ 추가
    DateTime? resignedAt, // ✅ 추가
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
      employmentStatus: employmentStatus ?? this.employmentStatus, // ✅ 추가
      resignedAt: resignedAt ?? this.resignedAt, // ✅ 추가
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}