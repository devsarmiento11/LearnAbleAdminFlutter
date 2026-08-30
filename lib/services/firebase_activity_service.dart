import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_record_model.dart';
import 'activity_service.dart';

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
    if (explicit.isNotEmpty) return explicit;
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
    if (name.contains('trace') ||
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
      for (final doc in users.docs)
        doc.id: (doc.data()['name'] ?? doc.data()['username'] ?? doc.id)
            .toString(),
    };
  }

  Future<List<ActivityRecordModel>> _load({
    String? studentId,
    required String schoolYear,
  }) async {
    Query<Map<String, dynamic>> query = _scores;
    if (studentId != null) query = query.where('userId', isEqualTo: studentId);
    final snapshot = await query.get();
    final names = await _studentNames();
    final values = snapshot.docs
        .where((doc) {
          final year = doc.data()['schoolYear']?.toString() ?? '';
          return year.isEmpty || year == schoolYear;
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
            'schoolYear': data['schoolYear'] ?? schoolYear,
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
