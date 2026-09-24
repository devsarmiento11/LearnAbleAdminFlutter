import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnable_admin/models/profile_report.dart';
import 'package:learnable_admin/services/profile_pdf.dart';
import '../tool/report_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Missing quarters stay blank and averages match the Unity grade rules',
    () async {
      final service = PreviewReportService();
      final student = (await service.students()).first;
      final report = await service.profile(student, '2026-2027');
      expect(report.grade('English', '3RD'), isNull);
      expect(report.subjectAverage('English'), 89);
      expect(report.generalAverage, closeTo(89.166666, .00001));
      expect(ProfileReport.remark(74), 'Failed');
      expect(ProfileReport.remark(75), 'Good');
      expect(ProfileReport.remark(85), 'Very Good');
      expect(ProfileReport.remark(90), 'Excellent');
      expect(ProfileReport.number(100), '100');
      expect(ProfileReport.number(0), '0');
      final historical = await service.profile(student, '2025-2026');
      expect(historical.generalAverage, isNull);
      expect(historical.teacherRemark, isEmpty);
    },
  );
  test(
    'Activity summaries use actual attempts, extrema, and cumulative duration',
    () {
      const report = ProfileReport(
        student: ReportStudent('test', {}, {}),
        year: '',
        activities: [
          ReportActivity(name: 'MathGame1Level2', score: 100, seconds: 42),
          ReportActivity(name: 'MathGame1Level2', score: 60, seconds: 32),
        ],
      );
      expect(report.summaryRows.single, [
        'Math Game1Level2',
        '2',
        '2',
        '1m 14s',
        '100',
        '60',
      ]);
    },
  );
  test(
    'PDF renders all three sections and paginates long activity history',
    () async {
      final service = PreviewReportService();
      final student = (await service.students()).first;
      final report = await service.profile(student, '2026-2027');
      final bytes = await buildProfilePdf(report);
      expect(bytes.take(4), [37, 80, 68, 70]);
      await Directory('tmp/pdfs').create(recursive: true);
      await File('tmp/pdfs/profile-preview.pdf').writeAsBytes(bytes);
      final long = ProfileReport(
        student: student,
        year: report.year,
        activities: List.generate(
          150,
          (i) => ReportActivity(
            name: 'MathGame${i}Level1',
            score: i % 101,
            seconds: i,
          ),
        ),
      );
      final longBytes = await buildProfilePdf(long);
      expect(longBytes.length, greaterThan(bytes.length));
      await File('tmp/pdfs/profile-long.pdf').writeAsBytes(longBytes);
    },
  );
}
