import 'package:cloud_firestore/cloud_firestore.dart';

class ArchivedStudentSummary {
  final String studentId;
  final String studentName;

  final String schoolYear;
  final String grade;
  final String condition;

  final double englishAverage;
  final double mathematicsAverage;
  final double scienceAverage;
  final double overallAverage;

  final int activitiesCompleted;
  final int totalActivities;
  final int totalAttempts;

  final String completionStatus;

  final DateTime archivedAt;

  const ArchivedStudentSummary({
    required this.studentId,
    required this.studentName,
    required this.schoolYear,
    required this.grade,
    required this.condition,
    required this.englishAverage,
    required this.mathematicsAverage,
    required this.scienceAverage,
    required this.overallAverage,
    required this.activitiesCompleted,
    required this.totalActivities,
    required this.totalAttempts,
    required this.completionStatus,
    required this.archivedAt,
  });

  // =========================================================
  // PROGRESS
  // =========================================================

  double get completionPercentage {
    if (totalActivities == 0) {
      return 0;
    }

    return activitiesCompleted / totalActivities;
  }

  // =========================================================
  // TO MAP
  //
  // Firebase-ready for later.
  // =========================================================

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'schoolYear': schoolYear,
      'grade': grade,
      'condition': condition,
      'englishAverage': englishAverage,
      'mathematicsAverage': mathematicsAverage,
      'scienceAverage': scienceAverage,
      'overallAverage': overallAverage,
      'activitiesCompleted': activitiesCompleted,
      'totalActivities': totalActivities,
      'totalAttempts': totalAttempts,
      'completionStatus': completionStatus,
      'archivedAt': archivedAt.toIso8601String(),
    };
  }

  // =========================================================
  // FROM MAP
  // =========================================================

  factory ArchivedStudentSummary.fromMap(Map<String, dynamic> map) {
    return ArchivedStudentSummary(
      studentId: map['studentId']?.toString() ?? '',

      studentName: map['studentName']?.toString() ?? '',

      schoolYear: map['schoolYear']?.toString() ?? '',

      grade: map['grade']?.toString() ?? '',

      condition: map['condition']?.toString() ?? '',

      englishAverage: (map['englishAverage'] as num?)?.toDouble() ?? 0,

      mathematicsAverage: (map['mathematicsAverage'] as num?)?.toDouble() ?? 0,

      scienceAverage: (map['scienceAverage'] as num?)?.toDouble() ?? 0,

      overallAverage: (map['overallAverage'] as num?)?.toDouble() ?? 0,

      activitiesCompleted: (map['activitiesCompleted'] as num?)?.toInt() ?? 0,

      totalActivities: (map['totalActivities'] as num?)?.toInt() ?? 0,

      totalAttempts: (map['totalAttempts'] as num?)?.toInt() ?? 0,

      completionStatus: map['completionStatus']?.toString() ?? 'Incomplete',

      archivedAt: map['archivedAt'] is Timestamp
          ? (map['archivedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['archivedAt']?.toString() ?? '') ??
                DateTime.now(),
    );
  }
}
