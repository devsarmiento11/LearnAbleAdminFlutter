import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnable_admin/models/parent_model.dart';
import 'package:learnable_admin/services/account_service.dart';
import 'package:learnable_admin/widgets/registered_parents_section.dart';

class ParentsFixture extends AccountService {
  bool fail = false;
  final deleted = <String>[];
  @override
  Future<void> deleteParent(String id) async { deleted.add(id); }
  @override
  Future<List<ParentModel>> getParents() async {
    if (fail) throw Exception('offline');
    return List.generate(6, (i) => ParentModel.fromMap({
      'id': 'P000$i', 'firstName': 'Parent $i', 'lastName': 'Test',
      'childrenId': 'S000$i', 'email': 'parent$i@example.com',
    }));
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() {
  testWidgets('parent deletion requires confirmation', (tester) async {
    final service = ParentsFixture();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: RegisteredParentsSection(accountService: service)))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete parent account').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.deleted, isEmpty);
    await tester.tap(find.byTooltip('Delete parent account').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(service.deleted, ['P0000']);
  });
  testWidgets('parents paginate, search by linked child and open details', (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: RegisteredParentsSection(accountService: ParentsFixture())))));
    await tester.pumpAndSettle();
    expect(find.text('P0000'), findsOneWidget);
    expect(find.text('P0005'), findsNothing);
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('P0005'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 's0002');
    await tester.pumpAndSettle();
    expect(find.text('P0002'), findsOneWidget);
    expect(find.text('P0005'), findsNothing);
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.text('parent2@example.com'), findsOneWidget);
    expect(find.text('S0002'), findsOneWidget);
  });
  testWidgets('failed load offers working retry', (tester) async {
    final service = ParentsFixture()..fail = true;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: RegisteredParentsSection(accountService: service)))));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    service.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('P0000'), findsOneWidget);
  });
}
