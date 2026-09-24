import '../widgets/report_navigation_item.dart';
import '../widgets/registered_parents_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../services/account_service.dart';
import '../services/archive_service.dart';
import '../services/firebase_account_service.dart';
import '../services/firebase_archive_service.dart';
import '../services/firebase_promotion_service.dart';
import '../services/promotion_service.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/archived_students_section.dart';

import 'create_account_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

// ============================================================
// COLORS
// ============================================================

const Color registeredBackground = Color(0xFFF8F5F0);
const Color registeredSidebar = Color(0xFFDDB98D);
const Color registeredBrown = Color(0xFF4D2F18);
const Color registeredAccent = Color(0xFF8C5A2D);
const Color registeredMuted = Color(0xFF918274);
const Color registeredBorder = Color(0xFFE8E1D8);
const Color registeredLightBrown = Color(0xFFF7F1E9);

class RegisteredAccountsScreen extends StatefulWidget {
  final AccountService? accountService;
  final ArchiveService? archiveService;
  final PromotionService? promotionService;

  const RegisteredAccountsScreen({
    super.key,
    this.accountService,
    this.archiveService,
    this.promotionService,
  });

  @override
  State<RegisteredAccountsScreen> createState() =>
      _RegisteredAccountsScreenState();
}

class _RegisteredAccountsScreenState extends State<RegisteredAccountsScreen> {
  late final AccountService accountService;
  late final ArchiveService archiveService;

  final TextEditingController studentSearchController = TextEditingController();

  final TextEditingController teacherSearchController = TextEditingController();

  List<StudentModel> students = [];
  List<TeacherModel> teachers = [];

  String accountType = 'student';

  String studentViewMode = 'active';

  bool loading = true;

  int studentPage = 0;
  int teacherPage = 0;

  static const int pageSize = 5;

  // ============================================================
  // INITIALIZE
  // ============================================================

  @override
  void initState() {
    super.initState();

    accountService = widget.accountService ?? FirebaseAccountService.instance;

    archiveService = widget.archiveService ?? FirebaseArchiveService.instance;

    studentSearchController.addListener(_studentSearchChanged);

    teacherSearchController.addListener(_teacherSearchChanged);

    _loadAccounts();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    studentSearchController.removeListener(_studentSearchChanged);

    teacherSearchController.removeListener(_teacherSearchChanged);

    studentSearchController.dispose();
    teacherSearchController.dispose();

    super.dispose();
  }

  // ============================================================
  // SHOW PHONE KEYBOARD
  // ============================================================

  void _showKeyboard() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _studentSearchChanged() {
    if (!mounted) return;

    setState(() {
      studentPage = 0;
    });
  }

  void _teacherSearchChanged() {
    if (!mounted) return;

    setState(() {
      teacherPage = 0;
    });
  }

  // ============================================================
  // LOAD ACCOUNTS
  // ============================================================

  Future<void> _loadAccounts() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final List<StudentModel> loadedStudents = await accountService
          .getStudents();

      final List<TeacherModel> loadedTeachers = await accountService
          .getTeachers();

      if (!mounted) return;

      setState(() {
        students = loadedStudents;
        teachers = loadedTeachers;

        loading = false;

        _fixStudentPage();
        _fixTeacherPage();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showError(_cleanError(error));
    }
  }

  // ============================================================
  // FILTER STUDENTS
  // ============================================================

  List<StudentModel> get filteredStudents {
    final String search = studentSearchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return students;
    }

    return students.where((StudentModel student) {
      return student.fullName.toLowerCase().contains(search) ||
          student.id.toLowerCase().contains(search) ||
          student.grade.toLowerCase().contains(search) ||
          student.condition.toLowerCase().contains(search) ||
          student.status.toLowerCase().contains(search);
    }).toList();
  }

  // ============================================================
  // FILTER TEACHERS
  // ============================================================

  List<TeacherModel> get filteredTeachers {
    final String search = teacherSearchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return teachers;
    }

    return teachers.where((TeacherModel teacher) {
      return teacher.fullName.toLowerCase().contains(search) ||
          teacher.id.toLowerCase().contains(search) ||
          teacher.email.toLowerCase().contains(search) ||
          teacher.gender.toLowerCase().contains(search) ||
          teacher.status.toLowerCase().contains(search);
    }).toList();
  }

  // ============================================================
  // PAGE COUNT
  // ============================================================

  int get studentPageCount {
    final int count = (filteredStudents.length / pageSize).ceil();

    return count < 1 ? 1 : count;
  }

  int get teacherPageCount {
    final int count = (filteredTeachers.length / pageSize).ceil();

    return count < 1 ? 1 : count;
  }

  // ============================================================
  // PAGED STUDENTS
  // ============================================================

  List<StudentModel> get pagedStudents {
    final List<StudentModel> filtered = filteredStudents;

    if (filtered.isEmpty) {
      return [];
    }

    final int start = studentPage * pageSize;

    if (start >= filtered.length) {
      return [];
    }

    return filtered.skip(start).take(pageSize).toList();
  }

  // ============================================================
  // PAGED TEACHERS
  // ============================================================

  List<TeacherModel> get pagedTeachers {
    final List<TeacherModel> filtered = filteredTeachers;

    if (filtered.isEmpty) {
      return [];
    }

    final int start = teacherPage * pageSize;

    if (start >= filtered.length) {
      return [];
    }

    return filtered.skip(start).take(pageSize).toList();
  }

  void _fixStudentPage() {
    if (studentPage >= studentPageCount) {
      studentPage = studentPageCount - 1;
    }

    if (studentPage < 0) {
      studentPage = 0;
    }
  }

  void _fixTeacherPage() {
    if (teacherPage >= teacherPageCount) {
      teacherPage = teacherPageCount - 1;
    }

    if (teacherPage < 0) {
      teacherPage = 0;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,

      onTap: () {
        FocusScope.of(context).unfocus();
      },

      child: Scaffold(
        backgroundColor: registeredBackground,

        drawer: _buildDrawer(),

        appBar: AppBar(
          backgroundColor: Colors.white,

          foregroundColor: registeredBrown,

          surfaceTintColor: Colors.white,

          elevation: 0,

          title: const Text(
            'Registered Accounts',

            style: TextStyle(
              color: registeredBrown,

              fontSize: 19,

              fontWeight: FontWeight.w700,
            ),
          ),

          actions: [
            IconButton(
              tooltip: 'Refresh',

              onPressed: loading ? null : _loadAccounts,

              icon: const Icon(Icons.refresh_rounded, color: registeredAccent),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 14),

              child: Container(
                width: 38,

                height: 38,

                decoration: const BoxDecoration(
                  color: registeredLightBrown,

                  shape: BoxShape.circle,
                ),

                clipBehavior: Clip.antiAlias,

                child: Image.asset(
                  'assets/images/admin.png',

                  fit: BoxFit.cover,

                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person_rounded,

                      color: registeredAccent,
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        body: SafeArea(
          child: RefreshIndicator(
            color: registeredAccent,

            onRefresh: _loadAccounts,

            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),

              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

              padding: const EdgeInsets.fromLTRB(16, 18, 16, 35),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Registered Accounts',

                        style: TextStyle(
                          color: registeredBrown,

                          fontSize: 24,

                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Manage all registered student, teacher, and parent accounts.',

                        style: TextStyle(color: registeredMuted, fontSize: 13),
                      ),

                      const SizedBox(height: 20),

                      _buildAccountTypeCard(),

                      const SizedBox(height: 16),

                      if (loading)
                        _buildLoading()
                      else if (accountType == 'student')
                        _buildStudentSection()
                      else if (accountType == 'parent')
                        RegisteredParentsSection(accountService: accountService)
                      else
                        _buildTeacherSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACCOUNT TYPE
  // ============================================================

  Widget _buildAccountTypeCard() {
    return _RegisteredCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const _RegisteredSectionTitle(
            icon: Icons.people_rounded,

            title: 'Account Type',

            subtitle: 'Choose which type of registered account to manage.',
          ),

          const SizedBox(height: 18),

          _AccountTypeOption(
            selected: accountType == 'student',

            icon: Icons.school_rounded,

            title: 'Student Accounts',

            subtitle: 'Manage registered learners.',

            onTap: () {
              FocusScope.of(context).unfocus();

              setState(() {
                accountType = 'student';
              });
            },
          ),

          const SizedBox(height: 10),

          _AccountTypeOption(
            selected: accountType == 'teacher',

            icon: Icons.co_present_rounded,

            title: 'Teacher Accounts',

            subtitle: 'Manage registered teachers.',

            onTap: () {
              FocusScope.of(context).unfocus();

              setState(() {
                accountType = 'teacher';
              });
            },
          ),
          const SizedBox(height: 10),
          _AccountTypeOption(
            selected: accountType == 'parent',
            icon: Icons.family_restroom,
            title: 'Parent Account',
            subtitle: 'View registered parents and their linked children.',
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => accountType = 'parent');
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return const _RegisteredCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 45),

        child: Center(
          child: CircularProgressIndicator(color: registeredAccent),
        ),
      ),
    );
  }

  // ============================================================
  // STUDENT SECTION
  // ============================================================

  // ============================================================
  // STUDENT ACTIVE / ARCHIVED
  // ============================================================

  Widget _buildStudentSection() {
    return Column(
      children: [
        _buildStudentModeSwitch(),

        const SizedBox(height: 14),

        if (studentViewMode == 'active')
          _buildActiveStudentSection()
        else
          ArchivedStudentsSection(
            archiveService: archiveService,
            promotionService:
                widget.promotionService ?? FirebasePromotionService.instance,
            onPromoted: _loadAccounts,
          ),
      ],
    );
  }

  Widget _buildStudentModeSwitch() {
    final bool active = studentViewMode == 'active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: registeredBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus();

                setState(() {
                  studentViewMode = 'active';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: active
                    ? registeredAccent
                    : registeredLightBrown,
                foregroundColor: active ? Colors.white : registeredBrown,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.people_alt_rounded, size: 17),
              label: const Text(
                'Active Students',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus();

                setState(() {
                  studentViewMode = 'archived';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: !active
                    ? registeredAccent
                    : registeredLightBrown,
                foregroundColor: !active ? Colors.white : registeredBrown,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.archive_rounded, size: 17),
              label: const Text(
                'Archived Students',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStudentSection() {
    final List<StudentModel> visibleStudents = pagedStudents;

    return _RegisteredCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const _RegisteredSectionTitle(
            icon: Icons.school_rounded,

            title: 'Student Accounts',

            subtitle: 'List of all registered student accounts.',
          ),

          const SizedBox(height: 18),

          _buildSearchField(
            controller: studentSearchController,

            hint: 'Search student accounts...',
          ),

          const SizedBox(height: 18),

          if (visibleStudents.isEmpty)
            _buildEmptyState(
              icon: Icons.person_off_rounded,

              title: 'No student accounts found',

              message: studentSearchController.text.trim().isNotEmpty
                  ? 'Try a different search.'
                  : 'Create a student account first.',
            )
          else
            ...visibleStudents.map((StudentModel student) {
              return _StudentAccountCard(
                student: student,

                onView: () {
                  _viewStudent(student);
                },

                onEdit: () {
                  _editStudent(student);
                },

                onDelete: () {
                  _deleteStudent(student);
                },
              );
            }),

          const SizedBox(height: 10),

          _buildPagination(
            label:
                'Showing ${filteredStudents.length} student${filteredStudents.length == 1 ? '' : 's'}',

            currentPage: studentPage,

            totalPages: studentPageCount,

            onPrevious: studentPage > 0
                ? () {
                    setState(() {
                      studentPage--;
                    });
                  }
                : null,

            onNext: studentPage < studentPageCount - 1
                ? () {
                    setState(() {
                      studentPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEACHER SECTION
  // ============================================================

  Widget _buildTeacherSection() {
    final List<TeacherModel> visibleTeachers = pagedTeachers;

    return _RegisteredCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const _RegisteredSectionTitle(
            icon: Icons.co_present_rounded,

            title: 'Teacher Accounts',

            subtitle: 'List of all registered teacher accounts.',
          ),

          const SizedBox(height: 18),

          _buildSearchField(
            controller: teacherSearchController,

            hint: 'Search teacher accounts...',
          ),

          const SizedBox(height: 18),

          if (visibleTeachers.isEmpty)
            _buildEmptyState(
              icon: Icons.person_off_rounded,

              title: 'No teacher accounts found',

              message: teacherSearchController.text.trim().isNotEmpty
                  ? 'Try a different search.'
                  : 'Create a teacher account first.',
            )
          else
            ...visibleTeachers.map((TeacherModel teacher) {
              return _TeacherAccountCard(
                teacher: teacher,

                onView: () {
                  _viewTeacher(teacher);
                },

                onEdit: () {
                  _editTeacher(teacher);
                },

                onDelete: () {
                  _deleteTeacher(teacher);
                },
              );
            }),

          const SizedBox(height: 10),

          _buildPagination(
            label:
                'Showing ${filteredTeachers.length} teacher${filteredTeachers.length == 1 ? '' : 's'}',

            currentPage: teacherPage,

            totalPages: teacherPageCount,

            onPrevious: teacherPage > 0
                ? () {
                    setState(() {
                      teacherPage--;
                    });
                  }
                : null,

            onNext: teacherPage < teacherPageCount - 1
                ? () {
                    setState(() {
                      teacherPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH FIELD
  // ============================================================

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,

      readOnly: false,

      keyboardType: TextInputType.text,

      textInputAction: TextInputAction.search,

      autocorrect: false,

      enableSuggestions: true,

      enableInteractiveSelection: true,

      onTap: () {
        _showKeyboard();
      },

      onSubmitted: (_) {
        FocusScope.of(context).unfocus();
      },

      decoration: InputDecoration(
        hintText: hint,

        hintStyle: const TextStyle(color: Color(0xFFB4ABA1), fontSize: 13),

        prefixIcon: const Icon(
          Icons.search_rounded,

          color: registeredAccent,

          size: 20,
        ),

        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear Search',

                onPressed: () {
                  controller.clear();

                  _showKeyboard();
                },

                icon: const Icon(Icons.close_rounded, size: 18),
              )
            : null,

        filled: true,

        fillColor: const Color(0xFFFCFAF7),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,

          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: const BorderSide(color: registeredBorder),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: const BorderSide(color: registeredBorder),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),

          borderSide: const BorderSide(color: registeredAccent, width: 1.4),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),

      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF7),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: registeredBorder),
      ),

      child: Column(
        children: [
          Container(
            width: 60,

            height: 60,

            decoration: BoxDecoration(
              color: registeredLightBrown,

              borderRadius: BorderRadius.circular(18),
            ),

            child: Icon(icon, color: registeredAccent, size: 29),
          ),

          const SizedBox(height: 15),

          Text(
            title,

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: registeredBrown,

              fontSize: 14,

              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            message,

            textAlign: TextAlign.center,

            style: const TextStyle(color: registeredMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination({
    required String label,
    required int currentPage,
    required int totalPages,
    required VoidCallback? onPrevious,
    required VoidCallback? onNext,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,

            style: const TextStyle(color: registeredMuted, fontSize: 10),
          ),
        ),

        _PaginationButton(
          icon: Icons.chevron_left_rounded,

          onPressed: onPrevious,
        ),

        const SizedBox(width: 7),

        Container(
          width: 34,

          height: 34,

          alignment: Alignment.center,

          decoration: BoxDecoration(
            color: registeredAccent,

            borderRadius: BorderRadius.circular(9),
          ),

          child: Text(
            '${currentPage + 1}',

            style: const TextStyle(
              color: Colors.white,

              fontSize: 11,

              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(width: 7),

        _PaginationButton(icon: Icons.chevron_right_rounded, onPressed: onNext),

        const SizedBox(width: 6),

        Text(
          '/ $totalPages',

          style: const TextStyle(color: registeredMuted, fontSize: 10),
        ),
      ],
    );
  }

  // ============================================================
  // VIEW STUDENT
  // ============================================================

  Future<void> _viewStudent(StudentModel student) async {
    FocusScope.of(context).unfocus();

    await showDialog<void>(
      context: context,

      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Student Account Details',

                  style: TextStyle(
                    color: registeredBrown,

                    fontSize: 18,

                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },

                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),

          content: SizedBox(
            width: 500,

            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  _detailTitle('Personal Information'),

                  _detailRow('Name', student.fullName),

                  _detailRow('Student ID', student.id),

                  _detailRow('Grade', student.grade),
                  if (student.schoolYear.isNotEmpty)
                    _detailRow('Enrolled School Year', student.schoolYear),

                  _detailRow('Learning Condition', student.condition),

                  _detailRow('Birthday', _formatDate(student.birthday)),

                  _detailRow('Age', student.age.toString()),

                  _detailRow('Address', student.address),

                  const SizedBox(height: 14),

                  _detailTitle('Family Information'),

                  _detailRow(
                    'Mother',
                    _joinName(student.motherFirstName, student.motherLastName),
                  ),

                  _detailRow(
                    'Father',
                    _joinName(student.fatherFirstName, student.fatherLastName),
                  ),

                  _detailRow(
                    'Guardian',
                    _joinName(
                      student.guardianFirstName,
                      student.guardianLastName,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _detailTitle('Account Information'),

                  _detailRow('Status', student.status),

                  _detailRow('Created', _formatDateTime(student.createdAt)),

                  _detailRow('Password', 'Managed by Authentication'),
                ],
              ),
            ),
          ),

          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: registeredAccent,

                foregroundColor: Colors.white,

                elevation: 0,
              ),

              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // VIEW TEACHER
  // ============================================================

  Future<void> _viewTeacher(TeacherModel teacher) async {
    FocusScope.of(context).unfocus();

    await showDialog<void>(
      context: context,

      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Teacher Account Details',

                  style: TextStyle(
                    color: registeredBrown,

                    fontSize: 18,

                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },

                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),

          content: SizedBox(
            width: 500,

            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  _detailTitle('Personal Information'),

                  _detailRow('Name', teacher.fullName),

                  _detailRow('Teacher ID', teacher.id),

                  _detailRow('Email', teacher.email),

                  _detailRow(
                    'Gender',
                    teacher.gender.isEmpty ? 'Not specified' : teacher.gender,
                  ),

                  const SizedBox(height: 14),

                  _detailTitle('Account Information'),

                  _detailRow('Status', teacher.status),

                  _detailRow('Created', _formatDateTime(teacher.createdAt)),

                  _detailRow('Password', 'Managed by Authentication'),
                ],
              ),
            ),
          ),

          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: registeredAccent,

                foregroundColor: Colors.white,

                elevation: 0,
              ),

              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EDIT STUDENT
  // ============================================================

  Future<void> _editStudent(StudentModel student) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final TextEditingController first = TextEditingController(
      text: student.firstName,
    );

    final TextEditingController middle = TextEditingController(
      text: student.middleName,
    );

    final TextEditingController last = TextEditingController(
      text: student.lastName,
    );

    final TextEditingController address = TextEditingController(
      text: student.address,
    );

    final TextEditingController motherFirst = TextEditingController(
      text: student.motherFirstName,
    );

    final TextEditingController motherLast = TextEditingController(
      text: student.motherLastName,
    );

    final TextEditingController fatherFirst = TextEditingController(
      text: student.fatherFirstName,
    );

    final TextEditingController fatherLast = TextEditingController(
      text: student.fatherLastName,
    );

    final TextEditingController guardianFirst = TextEditingController(
      text: student.guardianFirstName,
    );

    final TextEditingController guardianLast = TextEditingController(
      text: student.guardianLastName,
    );

    String grade = student.grade;

    String condition = student.condition;

    DateTime birthday = student.birthday;

    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,

              onTap: () {
                FocusScope.of(context).unfocus();
              },

              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.93,
                ),

                decoration: const BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),

                child: SafeArea(
                  top: false,

                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,

                    padding: EdgeInsets.fromLTRB(
                      18,
                      12,
                      18,
                      24 + MediaQuery.viewInsetsOf(context).bottom,
                    ),

                    child: Form(
                      key: formKey,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Center(
                            child: Container(
                              width: 44,

                              height: 4,

                              decoration: BoxDecoration(
                                color: const Color(0xFFD8CEC4),

                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Edit Student Account',

                                  style: TextStyle(
                                    color: registeredBrown,

                                    fontSize: 20,

                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                              IconButton(
                                onPressed: saving
                                    ? null
                                    : () {
                                        Navigator.pop(sheetContext);
                                      },

                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          _editSectionTitle('Personal Information'),

                          const SizedBox(height: 14),

                          _editField(
                            label: 'First Name',

                            controller: first,

                            required: true,
                          ),

                          _editField(label: 'Middle Name', controller: middle),

                          _editField(
                            label: 'Last Name',

                            controller: last,

                            required: true,
                          ),

                          _editDropdown(
                            label: 'Grade',

                            value: grade,

                            items: <String>{
                              'Grade 1',
                              'Grade 2',
                              'Grade 3',
                              'Grade 4',
                              'Grade 5',
                              'Grade 6',
                              grade,
                            }.toList(),

                            onChanged: (String? value) {
                              if (value == null) return;

                              setSheetState(() {
                                grade = value;
                              });
                            },
                          ),

                          _editDropdown(
                            label: 'Learning Condition',

                            value: condition,

                            items: const ['ASD', 'Down Syndrome'],

                            onChanged: (String? value) {
                              if (value == null) return;

                              setSheetState(() {
                                condition = value;
                              });
                            },
                          ),

                          _editDateField(
                            label: 'Birthday',

                            value: _formatDate(birthday),

                            onTap: () async {
                              FocusScope.of(context).unfocus();

                              final DateTime? picked = await showDatePicker(
                                context: context,

                                initialDate: birthday,

                                firstDate: DateTime(1950),

                                lastDate: DateTime.now(),
                              );

                              if (picked == null) {
                                return;
                              }

                              setSheetState(() {
                                birthday = picked;
                              });
                            },
                          ),

                          _editField(
                            label: 'Address',

                            controller: address,

                            required: true,

                            maxLines: 2,

                            keyboardType: TextInputType.streetAddress,

                            textInputAction: TextInputAction.newline,
                          ),

                          const SizedBox(height: 8),

                          _editSectionTitle('Family Information'),

                          const SizedBox(height: 14),

                          _editField(
                            label: "Mother's First Name",

                            controller: motherFirst,

                            required: true,
                          ),

                          _editField(
                            label: "Mother's Last Name",

                            controller: motherLast,

                            required: true,
                          ),

                          _editField(
                            label: "Father's First Name",

                            controller: fatherFirst,

                            required: true,
                          ),

                          _editField(
                            label: "Father's Last Name",

                            controller: fatherLast,

                            required: true,
                          ),

                          _editField(
                            label: "Guardian's First Name",

                            controller: guardianFirst,

                            required: true,
                          ),

                          _editField(
                            label: "Guardian's Last Name",

                            controller: guardianLast,

                            required: true,

                            textInputAction: TextInputAction.done,
                          ),

                          const SizedBox(height: 8),

                          _editSectionTitle('Account Information'),

                          const SizedBox(height: 14),

                          _readOnlyEditField(
                            label: 'Student ID',

                            value: student.id,
                          ),

                          _authenticationPasswordNotice(),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: saving
                                      ? null
                                      : () {
                                          Navigator.pop(sheetContext);
                                        },

                                  child: const Text('Cancel'),
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: ElevatedButton(
                                  onPressed: saving
                                      ? null
                                      : () async {
                                          if (!(formKey.currentState
                                                  ?.validate() ??
                                              false)) {
                                            return;
                                          }

                                          setSheetState(() {
                                            saving = true;
                                          });

                                          try {
                                            final StudentModel updated =
                                                StudentModel(
                                                  id: student.id,
                                                  username: student.username,

                                                  firstName: first.text.trim(),

                                                  middleName: middle.text
                                                      .trim(),

                                                  lastName: last.text.trim(),

                                                  grade: grade,

                                                  condition: condition,

                                                  birthday: birthday,

                                                  age: _calculateAge(birthday),

                                                  address: address.text.trim(),

                                                  motherFirstName: motherFirst
                                                      .text
                                                      .trim(),

                                                  motherLastName: motherLast
                                                      .text
                                                      .trim(),

                                                  fatherFirstName: fatherFirst
                                                      .text
                                                      .trim(),

                                                  fatherLastName: fatherLast
                                                      .text
                                                      .trim(),

                                                  guardianFirstName:
                                                      guardianFirst.text.trim(),

                                                  guardianLastName: guardianLast
                                                      .text
                                                      .trim(),

                                                  status: student.status,

                                                  createdAt: student.createdAt,
                                                );

                                            await accountService.updateStudent(
                                              updated,
                                            );

                                            if (!sheetContext.mounted) return;

                                            Navigator.pop(sheetContext);

                                            await _loadAccounts();

                                            if (!mounted) return;

                                            _showSuccess(
                                              'Student account updated successfully.',
                                            );
                                          } catch (error) {
                                            if (!mounted) return;

                                            setSheetState(() {
                                              saving = false;
                                            });

                                            _showError(_cleanError(error));
                                          }
                                        },

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: registeredAccent,

                                    foregroundColor: Colors.white,

                                    elevation: 0,
                                  ),

                                  child: saving
                                      ? const SizedBox(
                                          width: 18,

                                          height: 18,

                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,

                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Save Changes'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    first.dispose();
    middle.dispose();
    last.dispose();
    address.dispose();

    motherFirst.dispose();
    motherLast.dispose();

    fatherFirst.dispose();
    fatherLast.dispose();

    guardianFirst.dispose();
    guardianLast.dispose();
  }

  // ============================================================
  // EDIT TEACHER
  // ============================================================

  Future<void> _editTeacher(TeacherModel teacher) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final TextEditingController first = TextEditingController(
      text: teacher.firstName,
    );

    final TextEditingController middle = TextEditingController(
      text: teacher.middleName,
    );

    final TextEditingController last = TextEditingController(
      text: teacher.lastName,
    );

    final TextEditingController email = TextEditingController(
      text: teacher.email,
    );

    String gender = teacher.gender;

    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,

              onTap: () {
                FocusScope.of(context).unfocus();
              },

              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.93,
                ),

                decoration: const BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),

                child: SafeArea(
                  top: false,

                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,

                    padding: EdgeInsets.fromLTRB(
                      18,
                      12,
                      18,
                      24 + MediaQuery.viewInsetsOf(context).bottom,
                    ),

                    child: Form(
                      key: formKey,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Center(
                            child: Container(
                              width: 44,

                              height: 4,

                              decoration: BoxDecoration(
                                color: const Color(0xFFD8CEC4),

                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Edit Teacher Account',

                                  style: TextStyle(
                                    color: registeredBrown,

                                    fontSize: 20,

                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                              IconButton(
                                onPressed: saving
                                    ? null
                                    : () {
                                        Navigator.pop(sheetContext);
                                      },

                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          _editSectionTitle('Personal Information'),

                          const SizedBox(height: 14),

                          _editField(
                            label: 'First Name',

                            controller: first,

                            required: true,
                          ),

                          _editField(label: 'Middle Name', controller: middle),

                          _editField(
                            label: 'Last Name',

                            controller: last,

                            required: true,
                          ),

                          _editField(
                            label: 'Email',

                            controller: email,

                            required: true,

                            keyboardType: TextInputType.emailAddress,

                            validator: _emailValidator,

                            textInputAction: TextInputAction.done,
                          ),

                          _editDropdown(
                            label: 'Gender',

                            value: gender.isEmpty ? 'Not specified' : gender,

                            items: const ['Not specified', 'Male', 'Female'],

                            onChanged: (String? value) {
                              if (value == null) return;

                              setSheetState(() {
                                gender = value == 'Not specified' ? '' : value;
                              });
                            },
                          ),

                          const SizedBox(height: 8),

                          _editSectionTitle('Account Information'),

                          const SizedBox(height: 14),

                          _readOnlyEditField(
                            label: 'Teacher ID',

                            value: teacher.id,
                          ),

                          _authenticationPasswordNotice(),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: saving
                                      ? null
                                      : () {
                                          Navigator.pop(sheetContext);
                                        },

                                  child: const Text('Cancel'),
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: ElevatedButton(
                                  onPressed: saving
                                      ? null
                                      : () async {
                                          if (!(formKey.currentState
                                                  ?.validate() ??
                                              false)) {
                                            return;
                                          }

                                          setSheetState(() {
                                            saving = true;
                                          });

                                          try {
                                            final TeacherModel updated =
                                                TeacherModel(
                                                  id: teacher.id,
                                                  username: teacher.username,

                                                  firstName: first.text.trim(),

                                                  middleName: middle.text
                                                      .trim(),

                                                  lastName: last.text.trim(),

                                                  email: email.text.trim(),

                                                  gender: gender,

                                                  status: teacher.status,

                                                  createdAt: teacher.createdAt,
                                                );

                                            await accountService.updateTeacher(
                                              updated,
                                            );

                                            if (!sheetContext.mounted) return;

                                            Navigator.pop(sheetContext);

                                            await _loadAccounts();

                                            if (!mounted) return;

                                            _showSuccess(
                                              'Teacher account updated successfully.',
                                            );
                                          } catch (error) {
                                            if (!mounted) return;

                                            setSheetState(() {
                                              saving = false;
                                            });

                                            _showError(_cleanError(error));
                                          }
                                        },

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: registeredAccent,

                                    foregroundColor: Colors.white,

                                    elevation: 0,
                                  ),

                                  child: saving
                                      ? const SizedBox(
                                          width: 18,

                                          height: 18,

                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,

                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Save Changes'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    first.dispose();
    middle.dispose();
    last.dispose();
    email.dispose();
  }

  // ============================================================
  // EDIT FIELD
  // ============================================================

  Widget _editField({
    required String label,
    required TextEditingController controller,

    bool required = false,

    int maxLines = 1,

    TextInputType? keyboardType,

    TextInputAction? textInputAction,

    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _editLabel(label, required),

          const SizedBox(height: 7),

          TextFormField(
            controller: controller,

            readOnly: false,

            maxLines: maxLines,

            keyboardType: keyboardType ?? TextInputType.text,

            textInputAction:
                textInputAction ??
                (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),

            autocorrect: true,

            enableSuggestions: true,

            enableInteractiveSelection: true,

            validator: validator ?? (required ? _requiredValidator : null),

            onTap: () {
              _showKeyboard();
            },

            style: const TextStyle(color: registeredBrown, fontSize: 13),

            decoration: _editInputDecoration(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EDIT DROPDOWN
  // ============================================================

  Widget _editDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _editLabel(label, false),

          const SizedBox(height: 7),

          DropdownButtonFormField<String>(
            key: ValueKey('$label-$value'),

            initialValue: value,

            isExpanded: true,

            items: items
                .map(
                  (String item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),

            onChanged: (String? value) {
              FocusScope.of(context).unfocus();

              onChanged(value);
            },

            decoration: _editInputDecoration(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _editDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _editLabel(label, true),

          const SizedBox(height: 7),

          InkWell(
            onTap: onTap,

            borderRadius: BorderRadius.circular(12),

            child: InputDecorator(
              decoration: _editInputDecoration(),

              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,

                      style: const TextStyle(
                        color: registeredBrown,

                        fontSize: 13,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.calendar_month_rounded,

                    color: registeredAccent,

                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyEditField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _editLabel(label, false),

          const SizedBox(height: 7),

          Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),

            decoration: BoxDecoration(
              color: const Color(0xFFF4F1ED),

              borderRadius: BorderRadius.circular(12),

              border: Border.all(color: registeredBorder),
            ),

            child: Text(
              value,

              style: const TextStyle(color: registeredMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _authenticationPasswordNotice() {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: registeredLightBrown,

        borderRadius: BorderRadius.circular(12),
      ),

      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(Icons.lock_outline_rounded, size: 19, color: registeredAccent),

          SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Password',

                  style: TextStyle(
                    color: registeredBrown,

                    fontSize: 12,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Managed by Authentication',

                  style: TextStyle(color: registeredMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE STUDENT
  // ============================================================

  Future<void> _deleteStudent(StudentModel student) async {
    final bool? confirmed = await _showDeleteConfirmation(
      title: 'Delete Student Account',

      id: student.id,

      name: student.fullName,
    );

    if (confirmed != true) {
      return;
    }

    try {
      await accountService.deleteStudent(student.id);

      await _loadAccounts();

      if (!mounted) return;

      _showSuccess('Student account deleted.');
    } catch (error) {
      if (!mounted) return;

      _showError(_cleanError(error));
    }
  }

  // ============================================================
  // DELETE TEACHER
  // ============================================================

  Future<void> _deleteTeacher(TeacherModel teacher) async {
    final bool? confirmed = await _showDeleteConfirmation(
      title: 'Delete Teacher Account',

      id: teacher.id,

      name: teacher.fullName,
    );

    if (confirmed != true) {
      return;
    }

    try {
      await accountService.deleteTeacher(teacher.id);

      await _loadAccounts();

      if (!mounted) return;

      _showSuccess('Teacher account deleted.');
    } catch (error) {
      if (!mounted) return;

      _showError(_cleanError(error));
    }
  }

  Future<bool?> _showDeleteConfirmation({
    required String title,
    required String id,
    required String name,
  }) {
    FocusScope.of(context).unfocus();

    return showDialog<bool>(
      context: context,

      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Container(
                width: 65,

                height: 65,

                decoration: const BoxDecoration(
                  color: Color(0xFFFCE6E2),

                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.delete_outline_rounded,

                  size: 31,

                  color: Color(0xFFC65345),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                title,

                textAlign: TextAlign.center,

                style: const TextStyle(
                  color: registeredBrown,

                  fontSize: 18,

                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Are you sure you want to delete this account? This action cannot be undone.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: registeredMuted,

                  fontSize: 12,

                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(13),

                decoration: BoxDecoration(
                  color: registeredLightBrown,

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'ID: $id',

                      style: const TextStyle(
                        color: registeredBrown,

                        fontSize: 12,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Name: $name',

                      style: const TextStyle(
                        color: registeredMuted,

                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },

              child: const Text('Cancel'),
            ),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC65345),

                foregroundColor: Colors.white,

                elevation: 0,
              ),

              icon: const Icon(Icons.delete_rounded, size: 17),

              label: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }

    final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  int _calculateAge(DateTime birthday) {
    final DateTime today = DateTime.now();

    int age = today.year - birthday.year;

    if (today.month < birthday.month ||
        (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }

    return age;
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');

    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _formatDateTime(DateTime date) {
    return _formatDate(date);
  }

  String _joinName(String first, String last) {
    return '$first $last'.trim();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),

          backgroundColor: const Color(0xFFB34735),

          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),

          backgroundColor: const Color(0xFF3D8E59),

          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _detailTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Text(
        title,

        style: const TextStyle(
          color: registeredBrown,

          fontSize: 14,

          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 125,

            child: Text(
              label,

              style: const TextStyle(color: registeredMuted, fontSize: 11),
            ),
          ),

          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,

              style: const TextStyle(
                color: registeredBrown,

                fontSize: 12,

                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editSectionTitle(String title) {
    return Text(
      title,

      style: const TextStyle(
        color: registeredBrown,

        fontSize: 14,

        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _editLabel(String label, bool required) {
    return Row(
      children: [
        Text(
          label,

          style: const TextStyle(
            color: registeredBrown,

            fontSize: 12,

            fontWeight: FontWeight.w600,
          ),
        ),

        if (required)
          const Text(' *', style: TextStyle(color: Color(0xFFB84A3A))),
      ],
    );
  }

  InputDecoration _editInputDecoration() {
    return InputDecoration(
      filled: true,

      fillColor: const Color(0xFFFCFAF7),

      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),

        borderSide: const BorderSide(color: registeredBorder),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),

        borderSide: const BorderSide(color: registeredBorder),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),

        borderSide: const BorderSide(color: registeredAccent, width: 1.4),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),

        borderSide: const BorderSide(color: Color(0xFFB34735)),
      ),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _buildDrawer() {
    return Drawer(
      width: 280,

      backgroundColor: registeredSidebar,

      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            Image.asset(
              'assets/images/logo.png',

              width: 100,

              height: 80,

              fit: BoxFit.contain,

              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.school_rounded,

                  size: 60,

                  color: registeredBrown,
                );
              },
            ),

            const SizedBox(height: 8),

            const Text(
              'ADMIN PANEL',

              style: TextStyle(
                color: Color(0xFF6A4320),

                fontSize: 14,

                fontWeight: FontWeight.w600,

                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 20),

            Container(width: 170, height: 1, color: const Color(0x18000000)),

            const SizedBox(height: 24),

            _RegisteredDrawerItem(
              icon: Icons.home_rounded,

              label: 'Dashboard',

              onTap: () {
                Navigator.pop(context);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DashboardScreen(
                      accountService: accountService,
                      archiveService: archiveService,
                    ),
                  ),
                );
              },
            ),

            _RegisteredDrawerItem(
              icon: Icons.person_add_alt_1_rounded,

              label: 'Create Account',

              onTap: () {
                Navigator.pop(context);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateAccountScreen(accountService: accountService),
                  ),
                );
              },
            ),

            _RegisteredDrawerItem(
              icon: Icons.people_alt_rounded,

              label: 'Registered Accounts',

              selected: true,

              onTap: () {
                Navigator.pop(context);
              },
            ),

            const ReportNavigationItem(),

            const Spacer(),

            const Text(
              'Version 1.0',

              style: TextStyle(color: Color(0xFF87684C), fontSize: 11),
            ),

            const SizedBox(height: 10),

            _RegisteredDrawerItem(
              icon: Icons.logout_rounded,

              label: 'Logout',

              onTap: () {
                Navigator.pop(context);

                _showLogoutDialog();
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    FocusScope.of(context).unfocus();

    showDialog<void>(
      context: context,

      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text(
            'Logout',

            style: TextStyle(
              color: registeredBrown,

              fontWeight: FontWeight.w700,
            ),
          ),

          content: const Text(
            'Are you sure you want to logout?',

            style: TextStyle(color: registeredMuted),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) =>
                        LoginScreen(authService: FirebaseAdminAuthService()),
                  ),

                  (Route<dynamic> route) => false,
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: registeredAccent,

                foregroundColor: Colors.white,

                elevation: 0,
              ),

              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// REGISTERED CARD
// ============================================================

class _RegisteredCard extends StatelessWidget {
  final Widget child;

  const _RegisteredCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: registeredBorder),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),

            blurRadius: 15,

            offset: Offset(0, 5),
          ),
        ],
      ),

      child: child,
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _RegisteredSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RegisteredSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          width: 42,

          height: 42,

          decoration: BoxDecoration(
            color: registeredLightBrown,

            borderRadius: BorderRadius.circular(12),
          ),

          child: Icon(icon, size: 20, color: registeredAccent),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: const TextStyle(
                  color: registeredBrown,

                  fontSize: 15,

                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,

                style: const TextStyle(
                  color: registeredMuted,

                  fontSize: 10,

                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ACCOUNT TYPE OPTION
// ============================================================

class _AccountTypeOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountTypeOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFFAF3) : Colors.white,

      borderRadius: BorderRadius.circular(15),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(15),

        child: Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),

            border: Border.all(
              color: selected ? registeredAccent : registeredBorder,

              width: selected ? 1.4 : 1,
            ),
          ),

          child: Row(
            children: [
              if (title == 'Parent Account')
                Image.asset(
                  'assets/images/parents_icon.png',
                  width: 22,
                  height: 22,
                  color: registeredAccent,
                )
              else
                Icon(icon, color: registeredAccent, size: 22),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: const TextStyle(
                        color: registeredBrown,

                        fontSize: 13,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,

                      style: const TextStyle(
                        color: registeredMuted,

                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,

                color: selected ? registeredAccent : registeredMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STUDENT CARD
// ============================================================

class _StudentAccountCard extends StatelessWidget {
  final StudentModel student;

  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentAccountCard({
    required this.student,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF7),

        borderRadius: BorderRadius.circular(15),

        border: Border.all(color: registeredBorder),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 44,

                height: 44,

                decoration: BoxDecoration(
                  color: registeredLightBrown,

                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.school_rounded,

                  color: registeredAccent,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      student.fullName,

                      style: const TextStyle(
                        color: registeredBrown,

                        fontSize: 14,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      student.id,

                      style: const TextStyle(
                        color: registeredMuted,

                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              _StatusBadge(status: student.status),
            ],
          ),

          const SizedBox(height: 13),

          Wrap(
            spacing: 7,

            runSpacing: 7,

            children: [
              _InfoChip(label: student.grade),
              if (student.schoolYear.isNotEmpty)
                _InfoChip(label: student.schoolYear),

              _InfoChip(label: student.condition),

              _InfoChip(label: 'Age ${student.age}'),
            ],
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onView,

                  child: const Text('View'),
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,

                  child: const Text('Edit'),
                ),
              ),

              const SizedBox(width: 7),

              IconButton(
                tooltip: 'Delete',

                onPressed: onDelete,

                icon: const Icon(
                  Icons.delete_outline_rounded,

                  color: Color(0xFFC65345),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TEACHER CARD
// ============================================================

class _TeacherAccountCard extends StatelessWidget {
  final TeacherModel teacher;

  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeacherAccountCard({
    required this.teacher,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF7),

        borderRadius: BorderRadius.circular(15),

        border: Border.all(color: registeredBorder),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 44,

                height: 44,

                decoration: BoxDecoration(
                  color: registeredLightBrown,

                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.co_present_rounded,

                  color: registeredAccent,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      teacher.fullName,

                      style: const TextStyle(
                        color: registeredBrown,

                        fontSize: 14,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      teacher.id,

                      style: const TextStyle(
                        color: registeredMuted,

                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              _StatusBadge(status: teacher.status),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            teacher.email,

            style: const TextStyle(color: registeredMuted, fontSize: 11),
          ),

          const SizedBox(height: 8),

          _InfoChip(
            label: teacher.gender.isEmpty
                ? 'Gender not specified'
                : teacher.gender,
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onView,

                  child: const Text('View'),
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,

                  child: const Text('Edit'),
                ),
              ),

              const SizedBox(width: 7),

              IconButton(
                tooltip: 'Delete',

                onPressed: onDelete,

                icon: const Icon(
                  Icons.delete_outline_rounded,

                  color: Color(0xFFC65345),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STATUS BADGE
// ============================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool active = status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

      decoration: BoxDecoration(
        color: active ? const Color(0xFFE1F3E6) : const Color(0xFFF3E7E1),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status,

        style: TextStyle(
          color: active ? const Color(0xFF397C4D) : const Color(0xFF9A5B4D),

          fontSize: 9,

          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// INFO CHIP
// ============================================================

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),

      decoration: BoxDecoration(
        color: registeredLightBrown,

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        label,

        style: const TextStyle(
          color: registeredBrown,

          fontSize: 9,

          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================================
// PAGINATION BUTTON
// ============================================================

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _PaginationButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,

      height: 34,

      child: IconButton(
        padding: EdgeInsets.zero,

        onPressed: onPressed,

        icon: Icon(icon, size: 19),
      ),
    );
  }
}

// ============================================================
// DRAWER ITEM
// ============================================================

class _RegisteredDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RegisteredDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),

      child: Material(
        color: selected ? Colors.white : Colors.transparent,

        borderRadius: BorderRadius.circular(16),

        child: InkWell(
          onTap: onTap,

          borderRadius: BorderRadius.circular(16),

          child: SizedBox(
            height: 50,

            child: Row(
              children: [
                const SizedBox(width: 15),

                Icon(icon, color: const Color(0xFF55341B), size: 20),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    label,

                    style: TextStyle(
                      color: const Color(0xFF55341B),

                      fontSize: 14,

                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
