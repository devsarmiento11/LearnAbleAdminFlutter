import 'package:flutter/material.dart';
import 'package:learnable_admin/models/profile_report.dart';
import 'package:learnable_admin/screens/report_generation_screen.dart';
import 'package:learnable_admin/services/report_service.dart';

// Local design review only. No Firebase initialization or account changes.
class PreviewReportService implements ReportService {
  @override
  Future<List<ReportStudent>> students() async => [
    for (final (id, first, last, grade) in [
      ('DEMO001', 'Alex', 'Santos', 'Grade 2'),
      ('DEMO002', 'Jamie', 'Reyes', 'Grade 3'),
      ('DEMO003', 'Sam', 'Cruz', 'Grade 2'),
    ])
      ReportStudent(
        id,
        {
          'firstName': first,
          'lastName': last,
          'schoolYear': '2026-2027',
          'grade': grade,
          'section': 'A - morning',
          'academicGrades': {
            'ENGLISH_1ST': 88,
            'ENGLISH_2ND': 90,
            'MATH_1ST': 84,
            'MATH_2ND': 87,
            'SCIENCE_1ST': 92,
            'SCIENCE_2ND': 94,
          },
          'teacherRemark':
              'Shows steady progress and participates enthusiastically in learning activities.',
        },
        {'2026-2027': grade, '2025-2026': 'Grade 1'},
      ),
    const ReportStudent('DEMO004', {'name': 'Taylor Garcia'}, {'': 'Grade 1'}),
  ];
  @override
  Future<ProfileReport> profile(ReportStudent student, String year) async =>
      ProfileReport(
        student: student,
        year: year,
        activities: student.id == 'DEMO003'
            ? []
            : [
                for (var i = 0; i < 15; i++)
                  ReportActivity(
                    name: [
                      'MathGame1Level1',
                      'ScienceGame2Level2',
                      'LetsTraceLevel1',
                    ][i % 3],
                    score: 70 + (i % 4) * 10,
                    seconds: 18 + i,
                    completedAt: DateTime(
                      2026,
                      9,
                      24,
                    ).subtract(Duration(hours: i)),
                  ),
              ],
      );
}

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'LearnAble • Report Design Preview',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFA56B2F)),
    ),
    home: ReportGenerationScreen(
      service: PreviewReportService(),
      preview: true,
    ),
  ),
);
