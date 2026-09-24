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

  List<String> _years(Map<String, dynamic>? data, String field) =>
      (data?[field] as List<dynamic>? ?? const []).whereType<String>().toList();

  @override
  Future<List<String>> getUnarchivedSchoolYears() async =>
      _years((await _settings.get()).data(), 'unarchivedSchoolYears')..sort();

  @override
  Future<void> unarchiveSchoolYear(String schoolYear) async {
    final year = schoolYear.trim();
    if (year.isEmpty) throw Exception('School year cannot be empty.');
    if (!(await getArchivedSchoolYears()).contains(year)) {
      throw Exception('School Year $year is no longer archived.');
    }
    await _firestore.runTransaction((transaction) async {
      final data = (await transaction.get(_settings)).data();
      if (_years(data, 'unarchivedSchoolYears').contains(year)) {
        throw Exception('School Year $year is no longer archived.');
      }
      transaction.set(_settings, {
        'unarchivedSchoolYears': FieldValue.arrayUnion([year]),
        'archivedSchoolYears': FieldValue.arrayRemove([year]),
        // An old saved value must not silently reactivate the reopened year.
        if (data?['currentSchoolYear'] == year) 'currentSchoolYear': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> archiveSchoolYear({
    required String schoolYear,
    required List<ArchivedStudentSummary> students,
  }) async {
    final year = schoolYear.trim();
    if (year.isEmpty) throw Exception('School year cannot be empty.');
    if ((await getArchivedSchoolYears()).contains(year)) {
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
    await _settings.set({
      'archivedSchoolYears': FieldValue.arrayUnion([year]),
      'unarchivedSchoolYears': FieldValue.arrayRemove([year]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    final data = (await _settings.get()).data();
    final reopened = _years(data, 'unarchivedSchoolYears').toSet();
    final values =
        (await _archives.get()).docs
            .map((doc) => doc.data()['schoolYear']?.toString() ?? '')
            .where((year) => year.isNotEmpty)
            .toSet()
          ..addAll(_years(data, 'archivedSchoolYears'))
          ..removeAll(reopened);
    return values.toList()..sort((a, b) => b.compareTo(a));
  }
}
