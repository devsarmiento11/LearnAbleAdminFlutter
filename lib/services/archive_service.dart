import '../models/archived_student_summary.dart';

abstract class ArchiveService {
  // =========================================================
  // CURRENT SCHOOL YEAR
  // =========================================================

  Future<String> getCurrentSchoolYear();

  Future<void> setCurrentSchoolYear(String schoolYear);

  /// Reopens a year without deleting its saved student summaries.
  Future<void> unarchiveSchoolYear(String schoolYear);

  /// Includes reopened years outside the dashboard's generated date range.
  Future<List<String>> getUnarchivedSchoolYears();

  // =========================================================
  // ARCHIVE SCHOOL YEAR
  // =========================================================

  Future<void> archiveSchoolYear({
    required String schoolYear,
    required List<ArchivedStudentSummary> students,
  });

  // =========================================================
  // GET ALL ARCHIVED STUDENTS
  // =========================================================

  Future<List<ArchivedStudentSummary>> getArchivedStudents();

  // =========================================================
  // GET ARCHIVED STUDENTS BY SCHOOL YEAR
  // =========================================================

  Future<List<ArchivedStudentSummary>> getArchivedStudentsBySchoolYear(
    String schoolYear,
  );

  // =========================================================
  // GET AVAILABLE SCHOOL YEARS
  // =========================================================

  Future<List<String>> getArchivedSchoolYears();
}
