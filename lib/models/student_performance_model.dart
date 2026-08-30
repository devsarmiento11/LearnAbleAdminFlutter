import 'package:cloud_firestore/cloud_firestore.dart';

class StudentPerformanceModel {
  final String studentId;
  final String schoolYear;

  final double englishAverage;
  final double mathematicsAverage;
  final double scienceAverage;
  final double overallAverage;

  final int activitiesCompleted;
  final int totalActivities;
  final int totalAttempts;

  final DateTime lastUpdated;

  const StudentPerformanceModel({
    required this.studentId,
    required this.schoolYear,
    required this.englishAverage,
    required this.mathematicsAverage,
    required this.scienceAverage,
    required this.overallAverage,
    required this.activitiesCompleted,
    required this.totalActivities,
    required this.totalAttempts,
    required this.lastUpdated,
  });

  double get completionPercentage {
    if (totalActivities <= 0) {
      return 0;
    }

    return (activitiesCompleted / totalActivities) * 100;
  }

  String get completionStatus {
    if (totalActivities <= 0 || activitiesCompleted <= 0) {
      return 'Not Started';
    }

    if (activitiesCompleted >= totalActivities) {
      return 'Completed';
    }

    return 'In Progress';
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'schoolYear': schoolYear,
      'englishAverage': englishAverage,
      'mathematicsAverage': mathematicsAverage,
      'scienceAverage': scienceAverage,
      'overallAverage': overallAverage,
      'activitiesCompleted': activitiesCompleted,
      'totalActivities': totalActivities,
      'totalAttempts': totalAttempts,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory StudentPerformanceModel.fromMap(Map<String, dynamic> map) {
    return StudentPerformanceModel(
      studentId: map['studentId']?.toString() ?? '',
      schoolYear: map['schoolYear']?.toString() ?? '',
      englishAverage: (map['englishAverage'] as num?)?.toDouble() ?? 0,
      mathematicsAverage: (map['mathematicsAverage'] as num?)?.toDouble() ?? 0,
      scienceAverage: (map['scienceAverage'] as num?)?.toDouble() ?? 0,
      overallAverage: (map['overallAverage'] as num?)?.toDouble() ?? 0,
      activitiesCompleted: (map['activitiesCompleted'] as num?)?.toInt() ?? 0,
      totalActivities: (map['totalActivities'] as num?)?.toInt() ?? 0,
      totalAttempts: (map['totalAttempts'] as num?)?.toInt() ?? 0,
      lastUpdated: map['lastUpdated'] is Timestamp
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.tryParse(map['lastUpdated']?.toString() ?? '') ??
                DateTime.now(),
    );
  }
}
