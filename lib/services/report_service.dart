import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_report.dart';

abstract class ReportService {
  Future<List<ReportStudent>> students();
  Future<ProfileReport> profile(ReportStudent student, String year);
}

class FirebaseReportService implements ReportService {
  FirebaseReportService({FirebaseFirestore? firestore})
    : db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore db;
  @override
  Future<List<ReportStudent>> students() async {
    final results = await Future.wait([
      db.collection('users').where('role', isEqualTo: 'student').get(),
      db.collection('archivedStudents').get(),
    ]);
    final archives = results[1].docs;
    final students =
        results[0].docs.map((doc) {
          final data = doc.data();
          final year = '${data['schoolYear'] ?? ''}'.trim();
          final enrollments = <String, String>{};
          for (final archive in archives.where(
            (a) => a.data()['studentId'] == doc.id,
          )) {
            final value = archive.data();
            final y = '${value['schoolYear'] ?? ''}'.trim();
            if (y.isNotEmpty) enrollments[y] = '${value['grade'] ?? ''}';
          }
          for (final y in (data['enrolledSchoolYears'] as List? ?? [])) {
            if ('$y'.trim().isNotEmpty) enrollments.putIfAbsent('$y', () => '');
          }
          if (year.isNotEmpty) enrollments[year] = '${data['grade'] ?? ''}';
          if (enrollments.isEmpty) enrollments[''] = '${data['grade'] ?? ''}';
          return ReportStudent(doc.id, data, enrollments);
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    return students;
  }

  @override
  Future<ProfileReport> profile(ReportStudent student, String year) async {
    final user = await db.collection('users').doc(student.id).get();
    if (!user.exists || user.data()?['role'] != 'student') {
      throw StateError(
        'This student account is no longer available. Refresh the list.',
      );
    }
    final snapshot = await db
        .collection('activityScores')
        .where('userId', isEqualTo: student.id)
        .get();
    final records = <ReportActivity>[];
    final unassigned = <ReportActivity>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final savedYear = '${data['schoolYear'] ?? ''}'.trim();
      if (savedYear.isNotEmpty && savedYear != year) continue;
      final date = data['completedAt'];
      final seconds = int.tryParse('${data['timeUsedSeconds']}') ?? 0;
      final target = savedYear.isEmpty && year.isNotEmpty
          ? unassigned
          : records;
      target.add(
        ReportActivity(
          name: '${data['activityName'] ?? 'Unknown Activity'}',
          score: int.tryParse('${data['score']}') ?? 0,
          seconds: seconds < 0 ? 0 : seconds,
          completedAt: date is Timestamp
              ? date.toDate()
              : DateTime.tryParse('$date'),
        ),
      );
    }
    records.sort(
      (a, b) => (b.completedAt ?? DateTime(1900)).compareTo(
        a.completedAt ?? DateTime(1900),
      ),
    );
    unassigned.sort(
      (a, b) => (b.completedAt ?? DateTime(1900)).compareTo(
        a.completedAt ?? DateTime(1900),
      ),
    );
    return ProfileReport(
      student: ReportStudent(student.id, user.data()!, student.enrollments),
      year: year,
      activities: records,
      unassignedActivities: unassigned,
    );
  }
}
