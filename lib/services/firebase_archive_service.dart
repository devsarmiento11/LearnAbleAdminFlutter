import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/archived_student_summary.dart';
import 'archive_service.dart';

class FirebaseArchiveService implements ArchiveService {
  FirebaseArchiveService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  static final FirebaseArchiveService instance = FirebaseArchiveService();
  final FirebaseFirestore _firestore;
  DocumentReference<Map<String, dynamic>> get _settings =>
      _firestore.collection('adminSettings').doc('schoolYear');
  CollectionReference<Map<String, dynamic>> get _archives =>
      _firestore.collection('archivedStudents');

  @override
  Future<String> getCurrentSchoolYear() async =>
      (await _settings.get()).data()?['currentSchoolYear']?.toString() ??
      '2026-2027';

  @override
  Future<void> setCurrentSchoolYear(String schoolYear) async {
    if (schoolYear.trim().isEmpty) {
      throw Exception('School year cannot be empty.');
    }
    await _settings.set({
      'currentSchoolYear': schoolYear.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> archiveSchoolYear({
    required String schoolYear,
    required List<ArchivedStudentSummary> students,
  }) async {
    final year = schoolYear.trim();
    if (year.isEmpty) throw Exception('School year cannot be empty.');
    if ((await _archives.where('schoolYear', isEqualTo: year).limit(1).get())
        .docs
        .isNotEmpty) {
      throw Exception('School Year $year has already been archived.');
    }
    WriteBatch batch = _firestore.batch();
    int count = 0;
    for (final student in students) {
      batch.set(_archives.doc('${year}_${student.studentId}'), {
        ...student.toMap(),
        'archivedAt': Timestamp.fromDate(student.archivedAt),
      });
      if (++count == 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }

  List<ArchivedStudentSummary> _map(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final values = snapshot.docs
        .map((doc) => ArchivedStudentSummary.fromMap(doc.data()))
        .toList();
    values.sort((a, b) {
      final year = b.schoolYear.compareTo(a.schoolYear);
      return year != 0
          ? year
          : a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase());
    });
    return values;
  }

  @override
  Future<List<ArchivedStudentSummary>> getArchivedStudents() async =>
      _map(await _archives.get());
  @override
  Future<List<ArchivedStudentSummary>> getArchivedStudentsBySchoolYear(
    String schoolYear,
  ) async =>
      _map(await _archives.where('schoolYear', isEqualTo: schoolYear).get());
  @override
  Future<List<String>> getArchivedSchoolYears() async {
    final values = (await _archives.get()).docs
        .map((doc) => doc.data()['schoolYear']?.toString() ?? '')
        .where((year) => year.isNotEmpty)
        .toSet()
        .toList();
    values.sort((a, b) => b.compareTo(a));
    return values;
  }
}
