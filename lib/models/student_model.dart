import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;
  final String username;

  final String firstName;
  final String middleName;
  final String lastName;

  final String grade;
  final String studentSet;
  final String schoolYear;
  final String condition;

  final DateTime birthday;
  final int age;
  final String gender;

  final String address;

  final String motherFirstName;
  final String motherLastName;

  final String fatherFirstName;
  final String fatherLastName;

  final String guardianFirstName;
  final String guardianLastName;

  final String status;
  final DateTime createdAt;

  const StudentModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.grade,
    this.studentSet = '',
    this.schoolYear = '',
    required this.condition,
    required this.birthday,
    required this.age,
    this.gender = '',
    required this.address,
    required this.motherFirstName,
    required this.motherLastName,
    required this.fatherFirstName,
    required this.fatherLastName,
    required this.guardianFirstName,
    required this.guardianLastName,
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
    // Enrollment is managed by the promotion transaction. Profile edits merge
    // these fields without overwriting the saved school year or promotion log.
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'grade': grade,
      if (studentSet.isNotEmpty) 'set': studentSet,
      'condition': condition,
      'birthday': birthday.toIso8601String(),
      'age': age,
      'gender': gender,
      'address': address,
      'motherFirstName': motherFirstName,
      'motherLastName': motherLastName,
      'fatherFirstName': fatherFirstName,
      'fatherLastName': fatherLastName,
      'guardianFirstName': guardianFirstName,
      'guardianLastName': guardianLastName,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      username: map['username']?.toString() ?? '',
      firstName: map['firstName'] ?? '',
      middleName: map['middleName'] ?? '',
      lastName: map['lastName'] ?? '',
      grade: map['grade'] ?? '',
      studentSet: map['set']?.toString() ?? '',
      schoolYear: map['schoolYear']?.toString() ?? '',
      condition: map['condition'] ?? '',
      birthday: _parseDate(map['birthday']),
      age: _parseInt(map['age']),
      gender: map['gender']?.toString() ?? '',
      address: map['address'] ?? '',
      motherFirstName: map['motherFirstName'] ?? '',
      motherLastName: map['motherLastName'] ?? '',
      fatherFirstName: map['fatherFirstName'] ?? '',
      fatherLastName: map['fatherLastName'] ?? '',
      guardianFirstName: map['guardianFirstName'] ?? '',
      guardianLastName: map['guardianLastName'] ?? '',
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
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
