import '../models/activity_record_model.dart';

abstract class ActivityService {
  /// Returns the newest activity records for one school year.
  Future<List<ActivityRecordModel>> getRecentActivities({
    required String schoolYear,
    int limit = 10,
  });

  /// Returns activity history for one student.
  Future<List<ActivityRecordModel>> getStudentActivities({
    required String studentId,
    required String schoolYear,
  });

  /// Saves a completed activity.
  ///
  /// Firebase will implement this later when Unity sends
  /// real student activity results.
  Future<void> saveActivity(ActivityRecordModel activity);

  /// Deletes one activity record when necessary.
  Future<void> deleteActivity(String activityId);

  /// Clears live activity records belonging to an archived year.
  Future<void> clearSchoolYearActivities(String schoolYear);
}
