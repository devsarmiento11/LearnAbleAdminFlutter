import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnable_admin/models/profile_report.dart';
import 'package:learnable_admin/screens/report_generation_screen.dart';
import 'package:learnable_admin/services/report_service.dart';
import '../tool/report_preview.dart';

class FailingReports extends ReportService {
  @override
  Future<List<ReportStudent>> students() async => throw Exception('Offline');
  @override
  Future<ProfileReport> profile(ReportStudent student, String year) =>
      throw UnimplementedError();
}

void main() {
  testWidgets(
    'Search, batch selection, and empty results work on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ReportGenerationScreen(
            service: PreviewReportService(),
            preview: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3 students'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Jamie');
      await tester.pumpAndSettle();
      expect(find.text('Jamie Reyes'), findsOneWidget);
      expect(find.text('Alex Santos'), findsNothing);
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pumpAndSettle();
      expect(
        find.text('No students found for this selection.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('School year not assigned').last);
      await tester.pumpAndSettle();
      expect(find.text('Taylor Garcia'), findsOneWidget);
      expect(find.text('1 student'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Report navigation appears below Registered Accounts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportGenerationScreen(
          service: PreviewReportService(),
          preview: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    final drawer = find.byType(Drawer);
    final registered = find.descendant(
      of: drawer,
      matching: find.text('Registered Accounts'),
    );
    final report = find.descendant(
      of: drawer,
      matching: find.text('Report Generation'),
    );
    expect(
      tester.getCenter(report).dy,
      greaterThan(tester.getCenter(registered).dy),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Load errors offer a retry instead of an empty roster', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportGenerationScreen(service: FailingReports(), preview: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Student profiles'), findsNothing);
  });
}
