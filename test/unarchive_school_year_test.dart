import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnable_admin/models/activity_record_model.dart';
import 'package:learnable_admin/models/archived_student_summary.dart';
import 'package:learnable_admin/models/student_performance_model.dart';
import 'package:learnable_admin/screens/dashboard_screen.dart';
import 'package:learnable_admin/services/activity_service.dart';
import 'package:learnable_admin/services/archive_service.dart';
import 'package:learnable_admin/services/mock_account_service.dart';
import 'package:learnable_admin/services/mock_archive_service.dart';
import 'package:learnable_admin/services/performance_service.dart';
import 'package:learnable_admin/widgets/archived_students_section.dart';

class TestArchive extends ArchiveService {
  final List<String> archived = ['2000-2001'];
  final List<String> reopened = [];
  String current = '';
  bool fail = false;
  int calls = 0;
  Completer<void>? pending;

  @override
  Future<List<String>> getArchivedSchoolYears() async => List.of(archived);
  @override
  Future<List<String>> getUnarchivedSchoolYears() async => List.of(reopened);
  @override
  Future<List<ArchivedStudentSummary>> getArchivedStudents() async => [];
  @override
  Future<String> getCurrentSchoolYear() async => current;
  @override
  Future<void> setCurrentSchoolYear(String schoolYear) async {
    current = schoolYear;
  }

  @override
  Future<void> unarchiveSchoolYear(String schoolYear) async {
    calls++;
    if (pending != null) await pending!.future;
    if (fail) throw Exception('Unable to save. Try again.');
    archived.remove(schoolYear);
    reopened.add(schoolYear);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EmptyPerformance extends PerformanceService {
  @override
  Future<List<StudentPerformanceModel>> getPerformances({
    required String schoolYear,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EmptyActivity extends ActivityService {
  @override
  Future<List<ActivityRecordModel>> getRecentActivities({
    required String schoolYear,
    int limit = 10,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> showArchive(WidgetTester tester, ArchiveService service) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ArchivedStudentsSection(archiveService: service),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> confirmUnarchive(WidgetTester tester) async {
  await tester.tap(find.text('Unarchive Year'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Unarchive Year').last);
  await tester.pump();
}

void main() {
  test(
    'reopening preserves summaries and requires explicit activation',
    () async {
      final service = MockArchiveService.instance;
      const year = '1999-2000';
      final summary = ArchivedStudentSummary(
        studentId: 'test-student',
        studentName: 'Test Student',
        schoolYear: year,
        grade: 'Grade 1',
        condition: 'Test',
        englishAverage: 80,
        mathematicsAverage: 90,
        scienceAverage: 85,
        overallAverage: 85,
        activitiesCompleted: 3,
        totalActivities: 3,
        totalAttempts: 3,
        completionStatus: 'Completed',
        archivedAt: DateTime(2000),
      );
      await service.setCurrentSchoolYear(year);
      await service.archiveSchoolYear(schoolYear: year, students: [summary]);
      await service.unarchiveSchoolYear(year);
      expect(await service.getArchivedSchoolYears(), isNot(contains(year)));
      expect(await service.getUnarchivedSchoolYears(), contains(year));
      expect(await service.getCurrentSchoolYear(), '');
      expect(await service.getArchivedStudentsBySchoolYear(year), [summary]);
      await expectLater(service.unarchiveSchoolYear(year), throwsException);
      await service.setCurrentSchoolYear('2026-2027');
      await service.archiveSchoolYear(schoolYear: year, students: [summary]);
      expect(await service.getUnarchivedSchoolYears(), isNot(contains(year)));
      expect(await service.getArchivedStudentsBySchoolYear(year), hasLength(1));
      await service.unarchiveSchoolYear(year);
      expect(await service.getCurrentSchoolYear(), '2026-2027');
    },
  );

  testWidgets('cancel keeps the year archived', (tester) async {
    final service = TestArchive();
    await showArchive(tester, service);
    await tester.tap(find.text('Unarchive Year'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.calls, 0);
    expect(find.text('2000-2001'), findsOneWidget);
  });

  testWidgets('pending save disables repeats; failure permits retry', (
    tester,
  ) async {
    final service = TestArchive()
      ..pending = Completer<void>()
      ..fail = true;
    await showArchive(tester, service);
    await confirmUnarchive(tester);
    await tester.pump(const Duration(milliseconds: 300));
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Unarchiving...'),
    );
    expect(button.onPressed, isNull);
    expect(service.calls, 1);
    service.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Unable to save. Try again.'), findsOneWidget);
    expect(find.text('2000-2001'), findsOneWidget);
    service.fail = false;
    service.pending = null;
    await confirmUnarchive(tester);
    await tester.pumpAndSettle();
    expect(find.text('No archived school years'), findsOneWidget);
    expect(service.reopened, ['2000-2001']);
  });

  testWidgets('restored old year appears on dashboard and can be activated', (
    tester,
  ) async {
    final service = TestArchive();
    await showArchive(tester, service);
    await confirmUnarchive(tester);
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          accountService: MockAccountService.instance,
          archiveService: service,
          performanceService: EmptyPerformance(),
          activityService: EmptyActivity(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not Selected'), findsOneWidget);
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2000-2001').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Set School Year'));
    await tester.tap(find.text('Set School Year'));
    await tester.pumpAndSettle();
    expect(service.current, '2000-2001');
    expect(tester.takeException(), isNull);
  });

  testWidgets('unarchive control fits a narrow phone', (tester) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showArchive(tester, TestArchive());
    expect(find.text('Unarchive Year'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
