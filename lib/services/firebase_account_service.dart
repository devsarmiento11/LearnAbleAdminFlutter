import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/parent_model.dart';
import 'account_service.dart';
import 'firebase_archive_service.dart';

class FirebaseAccountService implements AccountService {
  FirebaseAccountService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;
  static final FirebaseAccountService instance = FirebaseAccountService();
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final Random _random = Random.secure();
  final Set<String> _reservedIds = <String>{};
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<String> _generate(String prefix) async {
    for (int attempt = 0; attempt < 100; attempt++) {
      final id =
          '$prefix${(_random.nextInt(9999) + 1).toString().padLeft(4, '0')}';
      if (!_reservedIds.contains(id) && !(await _users.doc(id).get()).exists) {
        _reservedIds.add(id);
        return id;
      }
    }
    throw Exception(
      'Unable to generate a unique account ID. Please try again.',
    );
  }

  @override
  Future<String> generateStudentId() => _generate('S');
  @override
  Future<String> generateTeacherId() => _generate('T');

  @override
  Future<String> generateParentId() => _generate('P');

  @override
  Future<void> createParent({
    required ParentModel parent,
    required String password,
  }) async {
    if (password.length < 6) {
      throw Exception('Password must contain at least 6 characters.');
    }
    await _createAccount(
      id: parent.id,
      username: parent.id,
      password: password,
      role: 'parent',
      profile: parent.toMap(),
    );
    _reservedIds.remove(parent.id);
  }

  @override
  Future<void> createStudent({
    required StudentModel student,
    required String password,
  }) async {
    if (password.length < 6) {
      throw Exception('Password must contain at least 6 characters.');
    }
    final schoolYear = (await FirebaseArchiveService(
      firestore: _firestore,
    ).getCurrentSchoolYear()).trim();
    if (schoolYear.isEmpty) {
      throw Exception('Set the active school year on the dashboard first.');
    }
    await _createAccount(
      id: student.id,
      username: student.username,
      password: password,
      role: 'student',
      profile: {...student.toMap(), 'schoolYear': schoolYear},
    );
    _reservedIds.remove(student.id);
  }

  @override
  Future<void> createTeacher({
    required TeacherModel teacher,
    required String password,
  }) async {
    if (password.length < 6) {
      throw Exception('Password must contain at least 6 characters.');
    }
    await _createAccount(
      id: teacher.id,
      username: teacher.username,
      password: password,
      role: 'teacher',
      profile: teacher.toMap(),
    );
    _reservedIds.remove(teacher.id);
  }

  Future<void> _createAccount({
    required String id,
    required String username,
    required String password,
    required String role,
    required Map<String, dynamic> profile,
  }) async {
    await _functions.httpsCallable('createManagedAccount').call<void>({
      'id': id,
      'username': username.trim(),
      'password': password,
      'role': role,
      'profile': profile,
    });
  }

  @override
  Future<List<StudentModel>> getStudents() async {
    final snapshot = await _users.where('role', isEqualTo: 'student').get();
    final values = snapshot.docs
        .map((doc) => StudentModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
    values.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return values;
  }

  @override
  Future<List<TeacherModel>> getTeachers() async {
    final snapshot = await _users.where('role', isEqualTo: 'teacher').get();
    final values = snapshot.docs
        .map((doc) => TeacherModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
    values.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return values;
  }

  @override
  Future<List<ParentModel>> getParents() async {
    final snapshot = await _users.where('role', isEqualTo: 'parent').get();
    final values = snapshot.docs
        .map((doc) => ParentModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
    values.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return values;
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    await _updateAccount(student.id, student.username, student.toMap());
  }

  @override
  Future<void> updateTeacher(TeacherModel teacher) async {
    await _updateAccount(teacher.id, teacher.username, teacher.toMap());
  }

  Future<void> _updateAccount(
    String id,
    String username,
    Map<String, dynamic> profile,
  ) async {
    await _functions.httpsCallable('updateManagedAccount').call<void>({
      'id': id,
      'username': username.trim(),
      'profile': profile,
    });
  }

  @override
  Future<void> deleteStudent(String studentId) => _deleteAccount(studentId);
  @override
  Future<void> deleteTeacher(String teacherId) => _deleteAccount(teacherId);

  @override
  Future<void> deleteParent(String parentId) => _deleteAccount(parentId);

  Future<void> _deleteAccount(String id) =>
      _functions.httpsCallable(
        'deleteManagedAccount',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
      ).call<void>({'id': id});
}
