import 'package:cloud_firestore/cloud_firestore.dart';

class Workplace {
  final String id;
  final String name;
  final String ownerId; // 사업장 소유자 ID
  final DateTime createdAt;
  final DateTime updatedAt;

  Workplace({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Firestore에서 데이터 가져올 때 사용
  factory Workplace.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Workplace(
      id: doc.id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Firestore에 저장할 때 사용
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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
}