import '../models/archived_student_summary.dart';
import 'archive_service.dart';

class MockArchiveService implements ArchiveService {
  MockArchiveService._();

  static final MockArchiveService instance = MockArchiveService._();

  String _currentSchoolYear = '2026-2027';

  final List<ArchivedStudentSummary> _archivedStudents = [];

  final Set<String> _archivedSchoolYears = <String>{};

  @override
  Future<String> getCurrentSchoolYear() async {
    return _currentSchoolYear;
  }

  @override
  Future<void> setCurrentSchoolYear(String schoolYear) async {
    final String value = schoolYear.trim();

    if (value.isEmpty) {
      throw Exception('School year cannot be empty.');
    }

    _currentSchoolYear = value;
  }

  @override
  Future<void> archiveSchoolYear({
    required String schoolYear,
    required List<ArchivedStudentSummary> students,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final String year = schoolYear.trim();

    if (year.isEmpty) {
      throw Exception('School year cannot be empty.');
    }

    if (_archivedSchoolYears.contains(year)) {
      throw Exception('School Year $year has already been archived.');
    }

    _archivedStudents.addAll(students);

    _archivedSchoolYears.add(year);
  }

  @override
  Future<List<ArchivedStudentSummary>> getArchivedStudents() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final List<ArchivedStudentSummary> results =
        List<ArchivedStudentSummary>.from(_archivedStudents);

    results.sort((ArchivedStudentSummary a, ArchivedStudentSummary b) {
      final int yearCompare = b.schoolYear.compareTo(a.schoolYear);

      if (yearCompare != 0) {
        return yearCompare;
      }

      return a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase());
    });

    return List.unmodifiable(results);
  }

  @override
  Future<List<ArchivedStudentSummary>> getArchivedStudentsBySchoolYear(
    String schoolYear,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final List<ArchivedStudentSummary> results = _archivedStudents.where((
      ArchivedStudentSummary student,
    ) {
      return student.schoolYear == schoolYear;
    }).toList();

    results.sort((ArchivedStudentSummary a, ArchivedStudentSummary b) {
      return a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase());
    });

    return List.unmodifiable(results);
  }

  @override
  Future<List<String>> getArchivedSchoolYears() async {
    final List<String> results = _archivedSchoolYears.toList();

    results.sort((String a, String b) {
      return b.compareTo(a);
    });

    return List.unmodifiable(results);
  }
}
