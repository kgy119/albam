import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Employee(
      id: doc.id,
      workplaceId: data['workplaceId'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      contractImageUrl: data['contractImageUrl'],
      hourlyWage: data['hourlyWage'] ?? 0,
      bankName: data['bankName'],
      accountNumber: data['accountNumber'],
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
      'bankName': bankName,
      'accountNumber': accountNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}