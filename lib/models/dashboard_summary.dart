import 'activity_record_model.dart';

/// Each child contributes one average; unattempted subjects are not zero scores.
class DashboardSummary {
  final List<ActivityRecordModel> records;
  final double average;
  final List<double> areaAverages;
  final List<int> categories;
  final List<DateTime> trendDates;
  final List<double> trendScores;

  DashboardSummary.fromRecords(List<ActivityRecordModel> source)
    : records =
          source
              .where(
                (r) =>
                    r.studentId.isNotEmpty &&
                    r.score.isFinite &&
                    r.score >= 0 &&
                    r.score <= 100,
              )
              .toList()
            ..sort((a, b) => b.completedAt.compareTo(a.completedAt)),
      average = _childAverage(source),
      areaAverages = ['English', 'Mathematics', 'Science']
          .map(
            (area) =>
                _childAverage(source.where((r) => r.learningArea == area)),
          )
          .toList(),
      categories = [0, 0, 0, 0],
      trendDates = [],
      trendScores = [] {
    for (final scores in _children(records).values) {
      final score = _average(scores);
      categories[score >= 90
          ? 0
          : score >= 75
          ? 1
          : score >= 60
          ? 2
          : 3]++;
    }
    final days = <DateTime, List<ActivityRecordModel>>{};
    for (final record in records) {
      final time = record.completedAt.toLocal();
      // An unknown timestamp must not appear as a completion today.
      if (time.year < 2000) continue;
      final day = DateTime(time.year, time.month, time.day);
      days.putIfAbsent(day, () => []).add(record);
    }
    final dates = days.keys.toList()..sort();
    for (final day in dates.skip(dates.length > 7 ? dates.length - 7 : 0)) {
      trendDates.add(day);
      trendScores.add(_childAverage(days[day]!));
    }
  }

  static Map<String, List<double>> _children(
    Iterable<ActivityRecordModel> records,
  ) {
    final children = <String, List<double>>{};
    for (final record in records) {
      if (record.studentId.isEmpty ||
          !record.score.isFinite ||
          record.score < 0 ||
          record.score > 100) {
        continue;
      }
      children.putIfAbsent(record.studentId, () => []).add(record.score);
    }
    return children;
  }

  static double _average(Iterable<double> values) => values.isEmpty
      ? 0
      : values.fold<double>(0, (sum, value) => sum + value) / values.length;

  static double _childAverage(Iterable<ActivityRecordModel> records) =>
      _average(_children(records).values.map(_average));
}
