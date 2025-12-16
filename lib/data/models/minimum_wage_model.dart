import 'package:cloud_firestore/cloud_firestore.dart';

class MinimumWageModel {
  final int year;
  final int wage;
  final DateTime effectiveDate;

  MinimumWageModel({
    required this.year,
    required this.wage,
    required this.effectiveDate,
  });

  factory MinimumWageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MinimumWageModel(
      year: data['year'] ?? 0,
      wage: data['wage'] ?? 0,
      effectiveDate: (data['effectiveDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'year': year,
      'wage': wage,
      'effectiveDate': Timestamp.fromDate(effectiveDate),
    };
  }
}