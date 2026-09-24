import 'package:flutter/material.dart';
import 'package:learnable_admin/models/archived_student_summary.dart';
import 'package:learnable_admin/services/mock_archive_service.dart';
import 'package:learnable_admin/services/promotion_service.dart';
import 'package:learnable_admin/widgets/archived_students_section.dart';

final samples = [
  ('S2144', 'Alexis John Sarmiento', 3),
  ('S2246', 'Big Star Show', 6),
  ('S0131', 'Eudora Flores Ramos', 5),
];

// Isolated local demonstration: no Firebase initialization or network writes.
class LocalPromotion extends PromotionService {
  final enrolled = <String, String>{};
  @override
  Future<PromotionState> load(String sourceYear) async => PromotionState(
    activeYear: '2026-2027',
    candidates: {
      for (final student in samples)
        student.$1: PromotionCandidate(
          id: student.$1,
          grade: enrolled[student.$1] ?? 'Grade ${student.$3}',
          nextGrade: 'Grade ${student.$3 + 1}',
          enrolled: enrolled.containsKey(student.$1),
          reason: enrolled.containsKey(student.$1)
              ? 'Already enrolled in 2026-2027'
              : '',
        ),
    },
  );
  @override
  Future<void> promote({
    required String sourceYear,
    required String targetYear,
    required List<PromotionCandidate> students,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (targetYear != '2026-2027' ||
        students.any((student) => enrolled.containsKey(student.id))) {
      throw Exception('Review the current enrollment before promoting.');
    }
    for (final student in students) {
      enrolled[student.id] = student.nextGrade!;
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MockArchiveService.instance.archiveSchoolYear(
    schoolYear: '2024-2025',
    students: [
      for (final student in samples)
        ArchivedStudentSummary(
          studentId: student.$1,
          studentName: student.$2,
          grade: 'Grade ${student.$3}',
          schoolYear: '2024-2025',
          condition: 'Down Syndrome',
          englishAverage: 100,
          mathematicsAverage: 100,
          scienceAverage: 100,
          overallAverage: 100,
          activitiesCompleted: 3,
          totalActivities: 3,
          totalAttempts: 3,
          completionStatus: 'Completed',
          archivedAt: DateTime(2025, 6, 1),
        ),
    ],
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFA56B2F)),
      ),
      home: const LocalPreview(),
    ),
  );
}

class LocalPreview extends StatefulWidget {
  const LocalPreview({super.key});
  @override
  State<LocalPreview> createState() => _LocalPreviewState();
}

class _LocalPreviewState extends State<LocalPreview> {
  final promotion = LocalPromotion();
  bool active = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: archiveBackground,
    appBar: AppBar(
      title: const Text('Registered Accounts'),
      backgroundColor: archiveBackground,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Local demo • Changes stay in this preview',
                style: TextStyle(color: archiveMuted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Active Students')),
                  ButtonSegment(value: false, label: Text('Archived Students')),
                ],
                selected: {active},
                onSelectionChanged: (value) =>
                    setState(() => active = value.single),
              ),
              const SizedBox(height: 14),
              Offstage(
                offstage: active,
                child: ArchivedStudentsSection(
                  archiveService: MockArchiveService.instance,
                  promotionService: promotion,
                  onPromoted: () => setState(() {}),
                ),
              ),
              if (active)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: archiveBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Enrolled in 2026-2027',
                        style: TextStyle(
                          color: archiveBrown,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (promotion.enrolled.isEmpty)
                        const Text(
                          'Promote students from Archived Students to enroll them here.',
                        ),
                      for (final student in samples.where(
                        (student) => promotion.enrolled.containsKey(student.$1),
                      ))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(student.$2),
                          subtitle: Text(
                            '${student.$1} · ${promotion.enrolled[student.$1]} · 2026-2027',
                          ),
                          trailing: const Text(
                            'Active',
                            style: TextStyle(color: Color(0xFF527044)),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
