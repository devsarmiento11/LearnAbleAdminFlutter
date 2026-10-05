import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnable_admin/models/activity_record_model.dart';
import 'package:learnable_admin/models/archived_student_summary.dart';
import 'package:learnable_admin/models/student_performance_model.dart';
import 'package:learnable_admin/screens/dashboard_screen.dart';
import 'package:learnable_admin/services/mock_account_service.dart';
import 'unarchive_school_year_test.dart'
    show TestArchive, EmptyActivity, EmptyPerformance;

class DashboardActivities extends EmptyActivity {
  bool fail = false;
  int requestedLimit = 0;
  @override
  Future<void> clearSchoolYearActivities(String schoolYear) async {
    throw StateError('Archiving must preserve source activities');
  }

  @override
  Future<List<ActivityRecordModel>> getRecentActivities({
    required String schoolYear,
    int limit = 10,
  }) async {
    requestedLimit = limit;
    if (fail) throw Exception('Offline');
    return [
      for (var i = 0; i < 12; i++)
        ActivityRecordModel(
          id: '$i',
          studentId: 'a',
          studentName: 'Learner',
          activityName: 'EnglishGame$i',
          learningArea: 'English',
          score: 0,
          attempts: 1,
          schoolYear: schoolYear,
          completedAt: DateTime(2026, 9, i + 1),
        ),
    ];
  }
}

class DashboardArchive extends TestArchive {
  int archiveCalls = 0;
  @override
  Future<void> archiveSchoolYear({
    required String schoolYear,
    required List<ArchivedStudentSummary> students,
  }) async {
    archiveCalls++;
    archived.add(schoolYear);
    current = '';
  }

  @override
  Future<void> addSchoolYear(String schoolYear) async {
    reopened.add(schoolYear);
  }
}

class DashboardPerformance extends EmptyPerformance {
  @override
  Future<StudentPerformanceModel?> getStudentPerformance({
    required String studentId,
    required String schoolYear,
  }) async => null;
  @override
  Future<void> clearSchoolYearPerformance(String schoolYear) async {
    throw StateError('Archiving must preserve source performance');
  }
}

Future<void> openDashboard(
  WidgetTester tester,
  DashboardArchive archive,
  DashboardActivities activities,
) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: DashboardScreen(
        accountService: MockAccountService.instance,
        archiveService: archive,
        activityService: activities,
        performanceService: DashboardPerformance(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'archive requires confirmation and retains source activity history',
    (tester) async {
      final archive = DashboardArchive()..current = '2026-2027';
      await openDashboard(tester, archive, DashboardActivities());
      await tester.tap(find.text('Archive School Year'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(archive.archiveCalls, 0);
      await tester.tap(find.text('Archive School Year'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Archive'));
      await tester.pumpAndSettle();
      expect(archive.archiveCalls, 1);
      expect(find.text('Not Selected'), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'zero scores render real charts and statistics; View All contains full history',
    (tester) async {
      final activities = DashboardActivities();
      await openDashboard(
        tester,
        DashboardArchive()..current = '2026-2027',
        activities,
      );
      expect(activities.requestedLimit, greaterThan(10));
      expect(find.text('No Data'), findsNothing);
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      await tester.tap(find.text('View Statistics'));
      await tester.pumpAndSettle();
      expect(find.text('Overall Average Score'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('View All'));
      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();
      expect(find.text('EnglishGame11'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'refresh reloads active year and clears charts when no year selected',
    (tester) async {
      final archive = DashboardArchive()..current = '2026-2027';
      await openDashboard(tester, archive, DashboardActivities());
      archive.current = '';
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();
      expect(find.text('Not Selected'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(PieChart), findsNothing);
    },
  );

  testWidgets('failed refresh clears stale charts and reports the failure', (
    tester,
  ) async {
    final activities = DashboardActivities();
    await openDashboard(
      tester,
      DashboardArchive()..current = '2026-2027',
      activities,
    );
    activities.fail = true;
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Offline'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
  });

  testWidgets('Add School Year persists a year outside the generated range', (
    tester,
  ) async {
    final archive = DashboardArchive()..current = '2026-2027';
    await openDashboard(tester, archive, DashboardActivities());
    await tester.tap(find.text('Add School Year'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2045');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();
    expect(archive.reopened, contains('2045-2046'));
    expect(archive.current, '2026-2027');
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('2045-2046'), findsOneWidget);
  });
}
