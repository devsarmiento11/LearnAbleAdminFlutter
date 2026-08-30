import 'dart:math';

import '../models/student_model.dart';
import '../models/teacher_model.dart';
import 'account_service.dart';

class MockAccountService implements AccountService {
  MockAccountService._();

  static final MockAccountService instance = MockAccountService._();

  final List<StudentModel> _students = [];
  final List<TeacherModel> _teachers = [];

  final Random _random = Random();

  // IDs that have already been generated during this app session.
  // This prevents the Generate button from showing the same ID again
  // even before the account has been created.
  final Set<String> _generatedStudentIds = {};
  final Set<String> _generatedTeacherIds = {};

  // =========================================================
  // GENERATE STUDENT ID
  //
  // Example:
  // S4827
  // S1934
  // S7502
  // =========================================================

  @override
  Future<String> generateStudentId() async {
    String id;

    do {
      final int number = _random.nextInt(9999) + 1;

      id = 'S${number.toString().padLeft(4, '0')}';
    } while (_students.any((StudentModel student) => student.id == id) ||
        _generatedStudentIds.contains(id));

    _generatedStudentIds.add(id);

    return id;
  }

  // =========================================================
  // GENERATE TEACHER ID
  //
  // Example:
  // T3841
  // T8260
  // T1573
  // =========================================================

  @override
  Future<String> generateTeacherId() async {
    String id;

    do {
      final int number = _random.nextInt(9999) + 1;

      id = 'T${number.toString().padLeft(4, '0')}';
    } while (_teachers.any((TeacherModel teacher) => teacher.id == id) ||
        _generatedTeacherIds.contains(id));

    _generatedTeacherIds.add(id);

    return id;
  }

  // =========================================================
  // CREATE STUDENT
  // =========================================================

  @override
  Future<void> createStudent({
    required StudentModel student,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (password.length < 6) {
      throw Exception('Password must contain at least 6 characters.');
    }

    final bool duplicate = _students.any(
      (StudentModel existing) => existing.id == student.id,
    );

    if (duplicate) {
      throw Exception('This Student ID already exists.');
    }

    // Password is intentionally NOT stored here.
    //
    // Later Firebase Authentication will handle it.

    _students.add(student);

    // Once the ID belongs to a real account,
    // we no longer need to keep it reserved here.
    _generatedStudentIds.remove(student.id);
  }

  // =========================================================
  // CREATE TEACHER
  // =========================================================

  @override
  Future<void> createTeacher({
    required TeacherModel teacher,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (password.length < 6) {
      throw Exception('Password must contain at least 6 characters.');
    }

    final bool duplicate = _teachers.any(
      (TeacherModel existing) => existing.id == teacher.id,
    );

    if (duplicate) {
      throw Exception('This Teacher ID already exists.');
    }

    // Password is intentionally NOT stored here.
    //
    // Later Firebase Authentication will handle it.

    _teachers.add(teacher);

    // Once the ID belongs to a real account,
    // we no longer need to keep it reserved here.
    _generatedTeacherIds.remove(teacher.id);
  }

  // =========================================================
  // GET STUDENTS
  // =========================================================

  @override
  Future<List<StudentModel>> getStudents() async {
    await Future.delayed(const Duration(milliseconds: 200));

    return List.unmodifiable(_students);
  }

  // =========================================================
  // GET TEACHERS
  // =========================================================

  @override
  Future<List<TeacherModel>> getTeachers() async {
    await Future.delayed(const Duration(milliseconds: 200));

    return List.unmodifiable(_teachers);
  }

  // =========================================================
  // UPDATE STUDENT
  // =========================================================

  @override
  Future<void> updateStudent(StudentModel student) async {
    final int index = _students.indexWhere(
      (StudentModel existing) => existing.id == student.id,
    );

    if (index == -1) {
      throw Exception('Student account not found.');
    }

    _students[index] = student;
  }

  // =========================================================
  // UPDATE TEACHER
  // =========================================================

  @override
  Future<void> updateTeacher(TeacherModel teacher) async {
    final int index = _teachers.indexWhere(
      (TeacherModel existing) => existing.id == teacher.id,
    );

    if (index == -1) {
      throw Exception('Teacher account not found.');
    }

    _teachers[index] = teacher;
  }

  // =========================================================
  // DELETE STUDENT
  // =========================================================

  @override
  Future<void> deleteStudent(String studentId) async {
    _students.removeWhere((StudentModel student) => student.id == studentId);
  }

  // =========================================================
  // DELETE TEACHER
  // =========================================================

  @override
  Future<void> deleteTeacher(String teacherId) async {
    _teachers.removeWhere((TeacherModel teacher) => teacher.id == teacherId);
  }
}
