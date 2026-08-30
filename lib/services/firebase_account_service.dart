import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import 'account_service.dart';

class FirebaseAccountService implements AccountService {
  FirebaseAccountService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  static final FirebaseAccountService instance = FirebaseAccountService();
  final FirebaseFirestore _firestore;
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

  Future<void> _ensureUniqueUsername(
    String username, {
    String? exceptId,
  }) async {
    final normalized = username.trim().toLowerCase();
    final direct = await _users
        .where('usernameLower', isEqualTo: normalized)
        .limit(2)
        .get();
    if (direct.docs.any((doc) => doc.id != exceptId)) {
      throw Exception('This username is already in use.');
    }
    // Also protects older records created before usernameLower was introduced.
    final legacy = await _users
        .where('username', isEqualTo: username.trim())
        .limit(2)
        .get();
    if (legacy.docs.any((doc) => doc.id != exceptId)) {
      throw Exception('This username is already in use.');
    }
  }

  Map<String, dynamic> _profile(
    Map<String, dynamic> data,
    String id,
    String username,
    String name,
    String role,
  ) => {
    ...data,
    'id': id,
    'userId': id,
    'schoolId': id,
    'username': username.trim(),
    'usernameLower': username.trim().toLowerCase(),
    'name': name,
    'role': role,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  Future<void> createStudent({
    required StudentModel student,
    required String password,
  }) async {
    if (password.length < 6) {
      throw Exception('Password must contain at least 6 characters.');
    }
    if ((await _users.doc(student.id).get()).exists) {
      throw Exception('This Student ID already exists.');
    }
    await _ensureUniqueUsername(student.username);
    await _users
        .doc(student.id)
        .set(
          _profile(
            student.toMap(),
            student.id,
            student.username,
            student.fullName,
            'student',
          ),
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
    if ((await _users.doc(teacher.id).get()).exists) {
      throw Exception('This Teacher ID already exists.');
    }
    await _ensureUniqueUsername(teacher.username);
    await _users
        .doc(teacher.id)
        .set(
          _profile(
            teacher.toMap(),
            teacher.id,
            teacher.username,
            teacher.fullName,
            'teacher',
          ),
        );
    _reservedIds.remove(teacher.id);
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
  Future<void> updateStudent(StudentModel student) async {
    await _ensureUniqueUsername(student.username, exceptId: student.id);
    await _users
        .doc(student.id)
        .set(
          _profile(
            student.toMap(),
            student.id,
            student.username,
            student.fullName,
            'student',
          ),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> updateTeacher(TeacherModel teacher) async {
    await _ensureUniqueUsername(teacher.username, exceptId: teacher.id);
    await _users
        .doc(teacher.id)
        .set(
          _profile(
            teacher.toMap(),
            teacher.id,
            teacher.username,
            teacher.fullName,
            'teacher',
          ),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteStudent(String studentId) =>
      _users.doc(studentId).delete();
  @override
  Future<void> deleteTeacher(String teacherId) =>
      _users.doc(teacherId).delete();
}
