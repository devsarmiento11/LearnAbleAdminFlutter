import 'package:flutter_test/flutter_test.dart';
import 'package:learnable_admin/models/activity_record_model.dart';
import 'package:learnable_admin/models/dashboard_summary.dart';
import 'package:learnable_admin/services/activity_school_year.dart';

ActivityRecordModel record(
  String child,
  double score, {
  String area = 'English',
  int day = 1,
}) => ActivityRecordModel(
  id: '$child-$day-$score',
  studentId: child,
  studentName: child,
  activityName: 'Activity',
  learningArea: area,
  score: score,
  attempts: 1,
  schoolYear: '2026-2027',
  completedAt: DateTime(2026, 9, day),
);

void main() {
  test('children have equal weight; missing subjects are not zero scores', () {
    final summary = DashboardSummary.fromRecords([
      record('a', 100),
      record('a', 100),
      record('b', 0, area: 'Mathematics'),
    ]);
    expect(summary.average, 50);
    expect(summary.areaAverages, [100, 0, 0]);
    expect(summary.categories, [1, 0, 0, 1]);
  });

  test('zero is real data and invalid scores do not enter statistics', () {
    final summary = DashboardSummary.fromRecords([
      record('a', 0),
      record('b', double.nan),
      record('c', 101),
      record('', 75),
    ]);
    expect(summary.records, hasLength(1));
    expect(summary.categories, [0, 0, 0, 1]);
    expect(summary.trendScores, [0]);
  });

  test(
    'trend uses last seven recorded days, sorted, without truncating totals',
    () {
      final summary = DashboardSummary.fromRecords([
        for (var day = 10; day >= 1; day--) record('a', day * 10, day: day),
      ]);
      expect(summary.records, hasLength(10));
      expect(summary.average, 55);
      expect(summary.trendDates.first.day, 4);
      expect(summary.trendScores, [40, 50, 60, 70, 80, 90, 100]);
      expect(summary.records.first.completedAt.day, 10);
    },
  );

  test('category boundaries are based on unrounded student averages', () {
    final summary = DashboardSummary.fromRecords([
      record('a', 90),
      record('b', 75),
      record('c', 60),
      record('d', 59.9),
    ]);
    expect(summary.categories, [1, 1, 1, 1]);
  });

  test('legacy school-year boundary uses Philippine time', () {
    expect(legacyActivitySchoolYear('2026-05-31T15:59:59Z'), '2025-2026');
    expect(legacyActivitySchoolYear('2026-05-31T16:00:00Z'), '2026-2027');
    expect(legacyActivitySchoolYear(null), '');
    expect(legacyActivitySchoolYear('invalid'), '');
  });

  test('missing completion date never fabricates activity today', () {
    final value = ActivityRecordModel.fromMap({'studentId': 'a', 'score': 0});
    expect(value.completedAt.year, 1970);
    expect(DashboardSummary.fromRecords([value]).trendScores, isEmpty);
  });
}
