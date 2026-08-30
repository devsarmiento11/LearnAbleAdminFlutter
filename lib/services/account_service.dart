import '../models/student_model.dart';
import '../models/teacher_model.dart';

abstract class AccountService {
  Future<String> generateStudentId();

  Future<String> generateTeacherId();

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

  Future<void> updateStudent(StudentModel student);

  Future<void> updateTeacher(TeacherModel teacher);

  Future<void> deleteStudent(String studentId);

  Future<void> deleteTeacher(String teacherId);
}
