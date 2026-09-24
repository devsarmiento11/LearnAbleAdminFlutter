import 'package:cloud_firestore/cloud_firestore.dart';

class ParentModel {
  final String id;
  final String username;

  final String firstName;
  final String middleName;
  final String lastName;

  final String childrenId;
  final String email;
  final String gender;

  final String status;
  final DateTime createdAt;

  const ParentModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.childrenId,
    required this.gender,
    required this.status,
    required this.createdAt,
  });

  String get fullName {
    final parts = [
      firstName,
      middleName,
      lastName,
    ].where((part) => part.trim().isNotEmpty);

    return parts.join(' ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'email': email,
      'childrenId': childrenId,
      'gender': gender,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      id: map['id'] ?? '',
      username: map['username']?.toString() ?? '',
      firstName: map['firstName'] ?? '',
      middleName: map['middleName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      childrenId: map['childrenId']?.toString() ?? '',
      gender: map['gender'] ?? '',
      status: map['status'] ?? 'Active',
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is Timestamp) return value.toDate();

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }
}
