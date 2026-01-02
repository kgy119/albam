class Workplace {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Workplace({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Supabase에서 데이터 가져올 때 사용
  factory Workplace.fromJson(Map<String, dynamic> json) {
    return Workplace(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
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
      'name': name,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Insert용 (id 제외)
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'owner_id': ownerId,
      // created_at, updated_at은 DB에서 자동 생성
    };
  }

  // Update용
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      // updated_at은 트리거에서 자동 업데이트
    };
  }

  // 사업장 정보 수정용
  Workplace copyWith({
    String? name,
    DateTime? updatedAt,
  }) {
    return Workplace(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Workplace(id: $id, name: $name, ownerId: $ownerId)';
  }
}