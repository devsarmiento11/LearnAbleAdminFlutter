import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_record_model.dart';
import 'activity_service.dart';
import 'activity_school_year.dart';

class FirebaseActivityService implements ActivityService {
  FirebaseActivityService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  static final FirebaseActivityService instance = FirebaseActivityService();
  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _scores =>
      _firestore.collection('activityScores');

  String _learningArea(Map<String, dynamic> data) {
    final explicit =
        (data['learningArea'] ?? data['subject'])?.toString().trim() ?? '';
    if (explicit.isNotEmpty) {
      switch (explicit.toLowerCase()) {
        case 'math':
        case 'mathematics':
          return 'Mathematics';
        case 'english':
          return 'English';
        case 'science':
          return 'Science';
      }
      return explicit;
    }
    final name = (data['activityName'] ?? '').toString().toLowerCase();
    if (name.contains('math') ||
        name.contains('number') ||
        name.contains('count')) {
      return 'Mathematics';
    }
    if (name.contains('sci') ||
        name.contains('living') ||
        name.contains('animal')) {
      return 'Science';
    }
    if (name.contains('english') ||
        name.contains('trac') ||
        name.contains('read') ||
        name.contains('letter')) {
      return 'English';
    }
    return 'Other';
  }

  Future<Map<String, String>> _studentNames() async {
    final users = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();
    return {
      for (final doc in users.docs) doc.id: _displayName(doc.id, doc.data()),
    };
  }

  String _displayName(String id, Map<String, dynamic> data) {
    final fullName = ['firstName', 'middleName', 'lastName']
        .map((key) => data[key]?.toString().trim() ?? '')
        .where((part) => part.isNotEmpty)
        .join(' ');
    if (fullName.isNotEmpty) return fullName;
    for (final key in ['name', 'username']) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return id;
  }

  Future<List<ActivityRecordModel>> _load({
    String? studentId,
    required String schoolYear,
  }) async {
    // Both Unity userId and admin studentId records are supported.
    final snapshot = await _scores.get();
    final names = await _studentNames();
    final values = snapshot.docs
        .where((doc) {
          final data = doc.data();
          final id = (data['userId'] ?? data['studentId'])?.toString() ?? '';
          if (studentId != null && id != studentId) return false;
          final year = data['schoolYear']?.toString().trim() ?? '';
          if (year.isNotEmpty) return year == schoolYear;
          return legacyActivitySchoolYear(data['completedAt']) == schoolYear;
        })
        .map((doc) {
          final data = doc.data();
          final id = (data['userId'] ?? data['studentId'])?.toString() ?? '';
          return ActivityRecordModel.fromMap({
            ...data,
            'id': doc.id,
            'studentId': id,
            'studentName': (data['studentName'] ?? names[id] ?? id).toString(),
            'learningArea': _learningArea(data),
            'schoolYear': schoolYear,
          });
        })
        .toList();
    values.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return values;
  }

  @override
  Future<List<ActivityRecordModel>> getRecentActivities({
    required String schoolYear,
    int limit = 10,
  }) async {
    final values = await _load(schoolYear: schoolYear);
    return values.take(limit).toList();
  }

  @override
  Future<List<ActivityRecordModel>> getStudentActivities({
    required String studentId,
    required String schoolYear,
  }) => _load(studentId: studentId, schoolYear: schoolYear);

  @override
  Future<void> saveActivity(ActivityRecordModel activity) async {
    final ref = activity.id.isEmpty ? _scores.doc() : _scores.doc(activity.id);
    await ref.set({
      ...activity.toMap(),
      'userId': activity.studentId,
      'completedAt': Timestamp.fromDate(activity.completedAt),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteActivity(String activityId) =>
      _scores.doc(activityId).delete();

  @override
  Future<void> clearSchoolYearActivities(String schoolYear) async {
    final snapshot = await _scores
        .where('schoolYear', isEqualTo: schoolYear)
        .get();
    WriteBatch batch = _firestore.batch();
    int count = 0;
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      if (++count == 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }
}
