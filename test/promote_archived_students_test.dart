import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnable_admin/models/archived_student_summary.dart';
import 'package:learnable_admin/services/promotion_service.dart';
import 'package:learnable_admin/widgets/archived_students_section.dart';
import 'unarchive_school_year_test.dart' show TestArchive;

class PromotionArchive extends TestArchive {
  PromotionArchive() {
    archived
      ..clear()
      ..addAll(['2024-2025', '2023-2024']);
  }
  @override
  Future<List<ArchivedStudentSummary>> getArchivedStudents() async => [
    for (final year in archived)
      for (var i = 1; i <= 2; i++)
        ArchivedStudentSummary(
          studentId: 'S$i',
          studentName: i == 1 ? 'Alexis' : 'Big Star',
          schoolYear: year,
          grade: i == 1 ? 'Grade 3' : 'Grade 6',
          condition: 'Test',
          englishAverage: 100,
          mathematicsAverage: 100,
          scienceAverage: 100,
          overallAverage: 100,
          activitiesCompleted: 1,
          totalActivities: 1,
          totalAttempts: 1,
          completionStatus: 'Completed',
          archivedAt: DateTime(2025),
        ),
  ];
}

class TestPromotion implements PromotionService {
  String? year = '2026-2027';
  bool failLoad = false;
  bool failSave = false;
  bool alreadyEnrolled = false;
  int writes = 0;
  List<String> promoted = [];
  Completer<void>? pending;
  @override
  Future<PromotionState> load(String sourceYear) async {
    if (failLoad) throw Exception('Offline');
    return PromotionState(
      activeYear: year,
      issue: year == null
          ? 'Set an active school year on the Dashboard before promoting students.'
          : '',
      candidates: {
        'S1': PromotionCandidate(
          id: 'S1',
          grade: 'Grade 3',
          nextGrade: 'Grade 4',
          enrolled: alreadyEnrolled,
          reason: alreadyEnrolled ? 'Already enrolled in $year' : '',
        ),
        'S2': const PromotionCandidate(
          id: 'S2',
          grade: 'Grade 6',
          nextGrade: 'Grade 7',
        ),
      },
    );
  }

  @override
  Future<void> promote({
    required String sourceYear,
    required String targetYear,
    required List<PromotionCandidate> students,
  }) async {
    writes++;
    if (pending != null) await pending!.future;
    if (failSave) throw Exception('Could not save');
    promoted = students.map((s) => s.id).toList();
  }
}

Future<void> showSection(
  WidgetTester tester,
  TestPromotion service, {
  VoidCallback? onPromoted,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ArchivedStudentsSection(
            archiveService: PromotionArchive(),
            promotionService: service,
            onPromoted: onPromoted,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> selectAll(WidgetTester tester) async {
  await tester.tap(find.text('Select Accounts'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(Checkbox).first);
  await tester.pumpAndSettle();
}

Future<void> review(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Promote (2)'));
  await tester.tap(find.text('Promote (2)'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'select, filter, cancel and confirm preserves archive and shows enrollment',
    (tester) async {
      final service = TestPromotion();
      var refreshed = 0;
      await showSection(tester, service, onPromoted: () => refreshed++);
      await selectAll(tester);
      expect(find.text('2 selected'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Alexis');
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
      await review(tester);
      expect(find.text('Grade 3 → Grade 4'), findsOneWidget);
      expect(find.text('Grade 6 → Grade 7'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(service.writes, 0);
      await review(tester);
      await tester.tap(find.text('Confirm Promotion'));
      await tester.pumpAndSettle();
      expect(service.promoted, ['S1', 'S2']);
      expect(refreshed, 1);
      expect(find.text('✓ Enrolled in 2026-2027 · Grade 4'), findsOneWidget);
      expect(find.text('Grade 3'), findsOneWidget);
      expect(find.text('2024-2025'), findsOneWidget);
    },
  );

  testWidgets(
    'no active year and load failures disable selection; retry works',
    (tester) async {
      final service = TestPromotion()..year = null;
      await showSection(tester, service);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Select Accounts'),
            )
            .onPressed,
        isNull,
      );
      service.year = '2026-2027';
      service.failLoad = true;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to load promotion details. Please retry.'),
        findsOneWidget,
      );
      service.failLoad = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Select Accounts'),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('already enrolled students cannot be selected', (tester) async {
    await showSection(tester, TestPromotion()..alreadyEnrolled = true);
    await selectAll(tester);
    expect(find.text('1 selected'), findsOneWidget);
    expect(
      tester
          .widget<Checkbox>(
            find.byWidgetPredicate(
              (w) => w is Checkbox && w.semanticLabel == 'Select Alexis',
            ),
          )
          .onChanged,
      isNull,
    );
  });

  testWidgets(
    'pending save disables repeat submit and failure keeps retry available',
    (tester) async {
      final service = TestPromotion()
        ..pending = Completer<void>()
        ..failSave = true;
      await showSection(tester, service);
      await selectAll(tester);
      await review(tester);
      await tester.tap(find.text('Confirm Promotion'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Promoting...'),
            )
            .onPressed,
        isNull,
      );
      service.pending!.complete();
      await tester.pumpAndSettle();
      expect(service.writes, 1);
      expect(find.text('2 selected'), findsOneWidget);
      expect(
        find.textContaining('Promotion could not be confirmed.'),
        findsOneWidget,
      );
      expect(find.text('✓ Enrolled in 2026-2027 · Grade 4'), findsNothing);
    },
  );

  testWidgets('changing source year clears selection', (tester) async {
    await showSection(tester, TestPromotion());
    await selectAll(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2023-2024').last);
    await tester.pumpAndSettle();
    expect(find.text('Select Accounts'), findsOneWidget);
    expect(find.text('2 selected'), findsNothing);
  });

  testWidgets('selection and review fit a 360px phone', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showSection(tester, TestPromotion());
    await selectAll(tester);
    await review(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
