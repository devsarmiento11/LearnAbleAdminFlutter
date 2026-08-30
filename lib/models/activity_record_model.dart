import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityRecordModel {
  final String id;
  final String studentId;
  final String studentName;
  final String activityName;
  final String learningArea;
  final double score;
  final int attempts;
  final String schoolYear;
  final DateTime completedAt;

  const ActivityRecordModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.activityName,
    required this.learningArea,
    required this.score,
    required this.attempts,
    required this.schoolYear,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'activityName': activityName,
      'learningArea': learningArea,
      'score': score,
      'attempts': attempts,
      'schoolYear': schoolYear,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory ActivityRecordModel.fromMap(Map<String, dynamic> map) {
    return ActivityRecordModel(
      id: map['id']?.toString() ?? '',
      studentId: (map['studentId'] ?? map['userId'])?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      activityName: map['activityName']?.toString() ?? '',
      learningArea: map['learningArea']?.toString() ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0,
      attempts: (map['attempts'] as num?)?.toInt() ?? 1,
      schoolYear: map['schoolYear']?.toString() ?? '',
      completedAt: map['completedAt'] is Timestamp
          ? (map['completedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['completedAt']?.toString() ?? '') ??
                DateTime.now(),
    );
  }
}
