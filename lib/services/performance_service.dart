import '../models/student_performance_model.dart';

abstract class PerformanceService {
  Future<List<StudentPerformanceModel>> getPerformances({
    required String schoolYear,
  });

  Future<StudentPerformanceModel?> getStudentPerformance({
    required String studentId,
    required String schoolYear,
  });

  Future<void> savePerformance(StudentPerformanceModel performance);

  Future<void> deleteStudentPerformance({
    required String studentId,
    required String schoolYear,
  });

  Future<void> clearSchoolYearPerformance(String schoolYear);
}
