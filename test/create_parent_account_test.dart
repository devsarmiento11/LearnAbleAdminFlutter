import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnable_admin/models/parent_model.dart';
import 'package:learnable_admin/models/student_model.dart';
import 'package:learnable_admin/screens/create_account_screen.dart';
import 'package:learnable_admin/services/account_service.dart';

class ParentAccounts extends AccountService {
  ParentModel? saved;
  int count = 0;
  @override
  Future<String> generateParentId() async =>
      'P${(++count).toString().padLeft(4, '0')}';
  @override
  Future<String> generateTeacherId() async => 'T0001';
  @override
  Future<String> generateStudentId() async => 'S0001';
  @override
  Future<List<StudentModel>> getStudents() async => [
    StudentModel.fromMap({'id': 'S2144'}),
  ];
  @override
  Future<void> createParent({
    required ParentModel parent,
    required String password,
  }) async {
    saved = parent;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Finder field(String hint) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == hint,
);
Future<void> openParent(WidgetTester tester, ParentAccounts service) async {
  await tester.pumpWidget(
    MaterialApp(home: CreateAccountScreen(accountService: service)),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Parents Account'));
  await tester.tap(find.text('Parents Account'));
  await tester.pumpAndSettle();
}

Future<void> fillParent(
  WidgetTester tester, {
  String child = 's2144',
  String confirmation = 'secret12',
}) async {
  for (final entry in {
    'Enter First Name': 'Jane',
    'Enter Last Name': 'Doe',
    'Enter Email Address': 'jane@example.com',
    'Enter Parents ID (e.g. P1234)': 'P4321',
    'Enter existing Student ID (e.g. S2144)': child,
    'Enter password': 'secret12',
    'Confirm password': confirmation,
  }.entries) {
    await tester.ensureVisible(field(entry.key));
    await tester.enterText(field(entry.key), entry.value);
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.text('Create Parents Account'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Create Parents Account'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  test('student set survives profile serialization without replacing enrollment year', () {
    final student = StudentModel.fromMap({
      'id': 'S1234',
      'set': 'B - Afternoon',
      'schoolYear': '2025-2026',
    });
    expect(student.studentSet, 'B - Afternoon');
    expect(student.schoolYear, '2025-2026');
    expect(student.toMap()['set'], 'B - Afternoon');
    expect(student.toMap().containsKey('schoolYear'), isFalse);
    expect(StudentModel.fromMap({'id': 'S1234'}).toMap().containsKey('set'), isFalse);
  });

  testWidgets('student set is required and offers morning and afternoon below grade', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CreateAccountScreen(accountService: ParentAccounts())));
    await tester.pumpAndSettle();
    final grade = find.byKey(const ValueKey('Grade-null'));
    final set = find.byKey(const ValueKey('Set-null'));
    await tester.ensureVisible(set);
    expect(tester.getTopLeft(set).dy, greaterThan(tester.getTopLeft(grade).dy));
    final dropdown = tester.widget<DropdownButtonFormField<String>>(set);
    expect(dropdown.validator!(null), isNotNull);
    await tester.tap(set);
    await tester.pumpAndSettle();
    expect(find.text('A - Morning'), findsOneWidget);
    expect(find.text('B - Afternoon'), findsOneWidget);
    await tester.tap(find.text('B - Afternoon'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('Set-B - Afternoon')), findsOneWidget);
  });

  testWidgets('all account IDs start empty, accept typing, and have no generator', (tester) async {
    final service = ParentAccounts();
    await tester.pumpWidget(MaterialApp(home: CreateAccountScreen(accountService: service)));
    await tester.pumpAndSettle();
    for (final entry in {
      'Student Account': 'Student',
      'Teacher Account': 'Teacher',
      'Parents Account': 'Parents',
    }.entries) {
      await tester.ensureVisible(find.text(entry.key));
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      final prefix = entry.value.substring(0, 1);
      final input = field('Enter '+entry.value+' ID (e.g. '+prefix+'1234)');
      expect(tester.widget<TextField>(input).controller!.text, isEmpty);
      expect(tester.widget<TextField>(input).readOnly, isFalse);
      expect(find.byTooltip('Generate ID'), findsNothing);
      await tester.ensureVisible(input);
      await tester.enterText(input, prefix+'4321');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(input).controller!.text, prefix+'4321');
    }
    expect(service.count, 0);
  });

  testWidgets(
    'parent form uses supplied icon and creates separate parent with child ID',
    (tester) async {
      final service = ParentAccounts();
      await openParent(tester, service);
      expect(find.text('Parents Account'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/parents_icon.png',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(field('Enter Parents ID (e.g. P1234)')).controller!.text,
        '',
      );
      await fillParent(tester);
      expect(service.saved!.childrenId, 'S2144');
      expect(service.saved!.id, 'P4321');
      expect(service.count, 0);
      expect(service.saved!.firstName, 'Jane');
      expect(service.saved!.toMap().containsKey('password'), false);
      expect(find.text('Account Created'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field('Enter Parents ID (e.g. P1234)')).controller!.text,
        '',
      );
    },
  );
  testWidgets('missing student and mismatched passwords do not save', (
    tester,
  ) async {
    final service = ParentAccounts();
    await openParent(tester, service);
    await fillParent(tester, child: 'S9999');
    expect(service.saved, isNull);
    expect(
      find.text('Children ID must belong to an existing student.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await fillParent(tester, confirmation: 'different');
    expect(service.saved, isNull);
    expect(find.text('Passwords do not match.'), findsOneWidget);
  });
  testWidgets('parent and teacher inputs stay separate and fit a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openParent(tester, ParentAccounts());
    await tester.enterText(field('Enter First Name'), 'Jane');
    await tester.ensureVisible(find.text('Teacher Account'));
    await tester.tap(find.text('Teacher Account'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field('Enter First Name')).controller!.text,
      '',
    );
    await tester.tap(find.text('Parents Account'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field('Enter First Name')).controller!.text,
      'Jane',
    );
    expect(tester.takeException(), isNull);
  });
}
