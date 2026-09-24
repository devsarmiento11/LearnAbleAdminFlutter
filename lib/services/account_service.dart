import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/parent_model.dart';

abstract class AccountService {
  Future<String> generateStudentId();

  Future<String> generateTeacherId();

  Future<String> generateParentId();

  Future<void> createParent({
    required ParentModel parent,
    required String password,
  });

  Future<void> createStudent({
    required StudentModel student,
    required String password,
  });

  Future<void> createTeacher({
    required TeacherModel teacher,
    required String password,
  });

  Future<List<StudentModel>> getStudents();

  Future<List<TeacherModel>> getTeachers();

  Future<List<ParentModel>> getParents();

  Future<void> updateStudent(StudentModel student);

  Future<void> updateTeacher(TeacherModel teacher);

  Future<void> deleteStudent(String studentId);

  Future<void> deleteTeacher(String teacherId);

  Future<void> deleteParent(String parentId);
}
