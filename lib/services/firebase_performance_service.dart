import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_performance_model.dart';
import 'firebase_activity_service.dart';
import 'performance_service.dart';

class FirebasePerformanceService implements PerformanceService {
  FirebasePerformanceService({
    FirebaseFirestore? firestore,
    FirebaseActivityService? activities,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _activities = activities ?? FirebaseActivityService.instance;
  static final FirebasePerformanceService instance =
      FirebasePerformanceService();
  final FirebaseFirestore _firestore;
  final FirebaseActivityService _activities;
  CollectionReference<Map<String, dynamic>> get _saved =>
      _firestore.collection('studentPerformance');

  Future<StudentPerformanceModel> _calculate(
    String studentId,
    String schoolYear,
  ) async {
    final records = await _activities.getStudentActivities(
      studentId: studentId,
      schoolYear: schoolYear,
    );
    double average(String area) {
      final matching = records
          .where(
            (record) => record.learningArea.toLowerCase() == area.toLowerCase(),
          )
          .toList();
      return matching.isEmpty
          ? 0
          : matching.fold<double>(0, (total, item) => total + item.score) /
                matching.length;
    }

    final overall = records.isEmpty
        ? 0.0
        : records.fold<double>(0, (total, item) => total + item.score) /
              records.length;
    return StudentPerformanceModel(
      studentId: studentId,
      schoolYear: schoolYear,
      englishAverage: average('English'),
      mathematicsAverage: average('Mathematics'),
      scienceAverage: average('Science'),
      overallAverage: overall,
      activitiesCompleted: records
          .map((item) => item.activityName)
          .toSet()
          .length,
      totalActivities: records.map((item) => item.activityName).toSet().length,
      totalAttempts: records.fold<int>(
        0,
        (total, item) => total + item.attempts,
      ),
      lastUpdated: records.isEmpty ? DateTime.now() : records.first.completedAt,
    );
  }

  @override
  Future<List<StudentPerformanceModel>> getPerformances({
    required String schoolYear,
  }) async {
    final users = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();
    return Future.wait(users.docs.map((doc) => _calculate(doc.id, schoolYear)));
  }

  @override
  Future<StudentPerformanceModel?> getStudentPerformance({
    required String studentId,
    required String schoolYear,
  }) => _calculate(studentId, schoolYear);

  @override
  Future<void> savePerformance(StudentPerformanceModel performance) =>
      _saved.doc('${performance.schoolYear}_${performance.studentId}').set({
        ...performance.toMap(),
        'lastUpdated': Timestamp.fromDate(performance.lastUpdated),
      }, SetOptions(merge: true));

  @override
  Future<void> deleteStudentPerformance({
    required String studentId,
    required String schoolYear,
  }) => _saved.doc('${schoolYear}_$studentId').delete();

  @override
  Future<void> clearSchoolYearPerformance(String schoolYear) async {
    final snapshot = await _saved
        .where('schoolYear', isEqualTo: schoolYear)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    if (snapshot.docs.isNotEmpty) await batch.commit();
  }
}
