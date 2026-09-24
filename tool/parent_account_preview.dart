import 'package:flutter/material.dart';
import 'package:learnable_admin/models/student_model.dart';
import 'package:learnable_admin/screens/create_account_screen.dart';
import 'package:learnable_admin/services/mock_account_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final service = MockAccountService.instance;
  await service.createStudent(
    student: StudentModel.fromMap({
      'id': 'S2144',
      'username': 'S2144',
      'firstName': 'Demo',
      'lastName': 'Student',
      'grade': 'Grade 3',
      'birthday': '2017-01-01',
    }),
    password: 'local-demo-only',
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFA56B2F)),
      ),
      builder: (context, child) => Column(
        children: [
          Material(
            color: const Color(0xFFF7F1E9),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Local demo • Children ID: S2144 • No live accounts are created',
                  style: const TextStyle(
                    color: Color(0xFF4D2F18),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: child!),
        ],
      ),
      home: CreateAccountScreen(accountService: service),
    ),
  );
}
