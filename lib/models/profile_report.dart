class ReportStudent {
  const ReportStudent(this.id, this.data, this.enrollments);
  final String id;
  final Map<String, dynamic> data;

  /// School year -> grade recorded for that enrollment.
  final Map<String, String> enrollments;
  String get name {
    final parts = [
      'firstName',
      'middleName',
      'lastName',
    ].map((key) => '${data[key] ?? ''}'.trim()).where((s) => s.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : '${data['name'] ?? id}';
  }

  String get currentYear => '${data['schoolYear'] ?? ''}'.trim();
}

class ReportActivity {
  const ReportActivity({
    required this.name,
    required this.score,
    required this.seconds,
    this.completedAt,
  });
  final String name;
  final int score;
  final int seconds;
  final DateTime? completedAt;
  String get level => RegExp(r'\d+$').stringMatch(name) ?? '-';
  String get displayName => name.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );
  String get activityName => displayName
      .replaceFirst(RegExp(r'\s*Level.*$', caseSensitive: false), '')
      .trim();
}

class ProfileReport {
  const ProfileReport({
    required this.student,
    required this.year,
    required this.activities,
    this.unassignedActivities = const [],
  });
  final ReportStudent student;
  final String year;
  final List<ReportActivity> activities;
  final List<ReportActivity> unassignedActivities;
  List<List<String>> get unassignedSummaryRows => ProfileReport(
    student: student,
    year: '',
    activities: unassignedActivities,
  ).summaryRows;
  static const subjects = ['English', 'Math', 'Science'];
  static const quarters = ['1ST', '2ND', '3RD', '4TH'];
  // The game stores one current grade sheet, not historical grade snapshots.
  bool get hasCurrentGrades => year == student.currentYear;
  double? grade(String subject, String quarter) {
    if (!hasCurrentGrades) return null;
    final grades = student.data['academicGrades'];
    if (grades is! Map) return null;
    final value = double.tryParse(
      '${grades['${subject.toUpperCase()}_$quarter']}',
    );
    return value != null && value.isFinite && value >= 0 && value <= 100
        ? value
        : null;
  }

  static double? average(Iterable<double?> values) {
    final saved = values.whereType<double>().toList();
    return saved.isEmpty ? null : saved.reduce((a, b) => a + b) / saved.length;
  }

  double? subjectAverage(String subject) =>
      average(quarters.map((q) => grade(subject, q)));
  double? get generalAverage => average(subjects.map(subjectAverage));
  static String number(double? value) => value == null
      ? '-'
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  static String remark(double? value) => value == null
      ? '-'
      : value < 75
      ? 'Failed'
      : value < 85
      ? 'Good'
      : value < 90
      ? 'Very Good'
      : 'Excellent';
  String get teacherRemark =>
      hasCurrentGrades ? '${student.data['teacherRemark'] ?? ''}' : '';
  List<List<String>> get summaryRows {
    final grouped = <String, List<ReportActivity>>{};
    for (final a in activities) {
      grouped.putIfAbsent(a.name, () => []).add(a);
    }
    final names = grouped.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names.map((name) {
      final rows = grouped[name]!;
      final seconds = rows.fold<int>(0, (sum, a) => sum + a.seconds);
      final scores = rows.map((a) => a.score).toList()..sort();
      return [
        rows.first.displayName,
        rows.first.level,
        '${rows.length}',
        seconds >= 60 ? '${seconds ~/ 60}m ${seconds % 60}s' : '${seconds}s',
        '${scores.last}',
        '${scores.first}',
      ];
    }).toList();
  }

  List<List<String>> get gradeRows => subjects
      .map(
        (s) => [
          s,
          ...quarters.map((q) => number(grade(s, q))),
          number(subjectAverage(s)),
          remark(subjectAverage(s)),
        ],
      )
      .toList();
}
