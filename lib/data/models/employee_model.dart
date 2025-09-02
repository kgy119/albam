import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String id;
  final String workplaceId;
  final String name;
  final String phoneNumber;
  final String? contractImageUrl;
  final int hourlyWage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.workplaceId,
    required this.name,
    required this.phoneNumber,
    this.contractImageUrl,
    required this.hourlyWage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Employee(
      id: doc.id,
      workplaceId: data['workplaceId'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      contractImageUrl: data['contractImageUrl'],
      hourlyWage: data['hourlyWage'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workplaceId': workplaceId,
      'name': name,
      'phoneNumber': phoneNumber,
      'contractImageUrl': contractImageUrl,
      'hourlyWage': hourlyWage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}