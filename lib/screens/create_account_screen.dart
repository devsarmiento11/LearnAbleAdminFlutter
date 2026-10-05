import '../widgets/report_navigation_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/parent_model.dart';
import '../services/account_service.dart';
import '../services/firebase_account_service.dart';
import '../services/firebase_auth_service.dart';

import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'registered_accounts_screen.dart';

// ============================================================
// COLORS
// ============================================================

const Color appBackground = Color(0xFFF8F5F0);
const Color appSidebar = Color(0xFFDDB98D);
const Color appBrown = Color(0xFF4D2F18);
const Color appAccent = Color(0xFF8C5A2D);
const Color appMuted = Color(0xFF918274);
const Color appBorder = Color(0xFFE8E1D8);
const Color appLightBrown = Color(0xFFF7F1E9);

class CreateAccountScreen extends StatefulWidget {
  final AccountService? accountService;

  const CreateAccountScreen({super.key, this.accountService});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  late final AccountService accountService;

  final GlobalKey<FormState> studentFormKey = GlobalKey<FormState>();

  final GlobalKey<FormState> teacherFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> parentFormKey = GlobalKey<FormState>();

  // ============================================================
  // ACCOUNT TYPE
  // ============================================================

  String accountType = 'student';
  bool isSubmitting = false;

  // ============================================================
  // STUDENT CONTROLLERS
  // ============================================================

  final TextEditingController studentFirstName = TextEditingController();

  final TextEditingController studentMiddleName = TextEditingController();

  final TextEditingController studentLastName = TextEditingController();

  final TextEditingController studentBirthday = TextEditingController();

  final TextEditingController studentAge = TextEditingController();

  final TextEditingController studentAddress = TextEditingController();

  final TextEditingController motherFirstName = TextEditingController();

  final TextEditingController motherLastName = TextEditingController();

  final TextEditingController fatherFirstName = TextEditingController();

  final TextEditingController fatherLastName = TextEditingController();

  final TextEditingController guardianFirstName = TextEditingController();

  final TextEditingController guardianLastName = TextEditingController();

  final TextEditingController studentId = TextEditingController();

  final TextEditingController studentPassword = TextEditingController();

  final TextEditingController studentConfirmPassword = TextEditingController();

  String? selectedGrade;
  String? selectedSet;
  String? selectedCondition;
  String? selectedStudentGender;
  DateTime? selectedBirthday;

  bool showStudentPassword = false;
  bool showStudentConfirmPassword = false;

  // ============================================================
  // TEACHER CONTROLLERS
  // ============================================================

  final TextEditingController teacherFirstName = TextEditingController();

  final TextEditingController teacherMiddleName = TextEditingController();

  final TextEditingController teacherLastName = TextEditingController();

  final TextEditingController teacherEmail = TextEditingController();

  final TextEditingController teacherId = TextEditingController();

  final TextEditingController teacherPassword = TextEditingController();

  final TextEditingController teacherConfirmPassword = TextEditingController();

  String? selectedGender;

  bool showTeacherPassword = false;
  bool showTeacherConfirmPassword = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  final TextEditingController parentFirstName = TextEditingController();

  final TextEditingController parentMiddleName = TextEditingController();

  final TextEditingController parentLastName = TextEditingController();

  final TextEditingController parentEmail = TextEditingController();

  final TextEditingController parentId = TextEditingController();

  final TextEditingController parentPassword = TextEditingController();

  final TextEditingController parentConfirmPassword = TextEditingController();

  String? selectedParentGender;

  bool showParentPassword = false;
  bool showParentConfirmPassword = false;

  final TextEditingController childrenId = TextEditingController();

  @override
  void initState() {
    super.initState();

    accountService = widget.accountService ?? FirebaseAccountService.instance;

  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    studentFirstName.dispose();
    studentMiddleName.dispose();
    studentLastName.dispose();
    studentBirthday.dispose();
    studentAge.dispose();
    studentAddress.dispose();

    motherFirstName.dispose();
    motherLastName.dispose();

    fatherFirstName.dispose();
    fatherLastName.dispose();

    guardianFirstName.dispose();
    guardianLastName.dispose();

    studentId.dispose();
    studentPassword.dispose();
    studentConfirmPassword.dispose();

    teacherFirstName.dispose();
    teacherMiddleName.dispose();
    teacherLastName.dispose();
    teacherEmail.dispose();

    teacherId.dispose();
    teacherPassword.dispose();
    teacherConfirmPassword.dispose();

    parentFirstName.dispose();
    parentMiddleName.dispose();
    parentLastName.dispose();
    parentEmail.dispose();
    parentId.dispose();
    parentPassword.dispose();
    parentConfirmPassword.dispose();
    childrenId.dispose();
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
  // AGE
  // ============================================================

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

  // ============================================================
  // BIRTHDAY
  // ============================================================

  Future<void> _selectBirthday() async {
    FocusScope.of(context).unfocus();

    final DateTime today = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          selectedBirthday ?? DateTime(today.year - 8, today.month, today.day),
      firstDate: DateTime(1950),
      lastDate: today,
      helpText: 'Select Birthday',
    );

    if (picked == null) return;

    setState(() {
      selectedBirthday = picked;

      studentBirthday.text = _formatDate(picked);

      studentAge.text = _calculateAge(picked).toString();
    });
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  String? _accountIdValidator(String? value, String prefix) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) return requiredError;
    final id = value!.trim();
    if (!RegExp('^' + prefix + r'[0-9]{4}$').hasMatch(id) || id == prefix + '0000') {
      return 'Enter $prefix followed by 4 digits (e.g. ${prefix}1234).';
    }
    return null;
  }

  String? _studentIdValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) return requiredError;
    final id = value!.trim();
    if (RegExp(r'^[0-9]{1,12}$').hasMatch(id)) return null;
    if (RegExp(r'^S[0-9]{4}$').hasMatch(id) && id != 'S0000') {
      return null;
    }
    return 'Enter a Student ID (e.g. S1234) or an LRN with 1–12 digits.';
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

  // ============================================================
  // CREATE STUDENT
  // ============================================================

  Future<void> _createStudent() async {
    FocusScope.of(context).unfocus();

    if (!(studentFormKey.currentState?.validate() ?? false)) {
      return;
    }

    if (selectedGrade == null) {
      _showError('Please select a grade.');
      return;
    }

    if (selectedCondition == null) {
      _showError('Please select a learning condition.');
      return;
    }

    if (selectedBirthday == null) {
      _showError('Please select the student birthday.');
      return;
    }

    if (studentPassword.text != studentConfirmPassword.text) {
      _showError('Passwords do not match.');
      return;
    }

    if (studentPassword.text.length < 6) {
      _showError('Password must contain at least 6 characters.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final StudentModel student = StudentModel(
        id: studentId.text.trim(),
        username: studentId.text.trim(),

        firstName: studentFirstName.text.trim(),

        middleName: studentMiddleName.text.trim(),

        lastName: studentLastName.text.trim(),

        grade: selectedGrade!,
        studentSet: selectedSet!,

        condition: selectedCondition!,

        birthday: selectedBirthday!,

        age: _calculateAge(selectedBirthday!),

        gender: selectedStudentGender ?? '',

        address: studentAddress.text.trim(),

        motherFirstName: motherFirstName.text.trim(),

        motherLastName: motherLastName.text.trim(),

        fatherFirstName: fatherFirstName.text.trim(),

        fatherLastName: fatherLastName.text.trim(),

        guardianFirstName: guardianFirstName.text.trim(),

        guardianLastName: guardianLastName.text.trim(),

        status: 'Active',

        createdAt: DateTime.now(),
      );

      await accountService.createStudent(
        student: student,
        password: studentPassword.text,
      );

      if (!mounted) return;

      await _showSuccessDialog(
        title: 'Account Created',
        message: 'Student account ${student.id} has been created successfully.',
      );

      if (!mounted) return;

      _openRegisteredAccounts();
    } catch (error) {
      if (!mounted) return;

      _showError(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // CREATE TEACHER
  // ============================================================

  Future<void> _createParent() async {
    if (isSubmitting) return;
    FocusScope.of(context).unfocus();

    if (!(parentFormKey.currentState?.validate() ?? false)) {
      return;
    }

    if (parentPassword.text != parentConfirmPassword.text) {
      _showError('Passwords do not match.');
      return;
    }

    if (parentPassword.text.length < 6) {
      _showError('Password must contain at least 6 characters.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final child = childrenId.text.trim().toUpperCase();
      final students = await accountService.getStudents();
      if (!students.any((student) => student.id == child)) {
        throw Exception('Children ID must belong to an existing student.');
      }
      final ParentModel parent = ParentModel(
        childrenId: child,
        id: parentId.text.trim(),
        username: parentId.text.trim(),

        firstName: parentFirstName.text.trim(),

        middleName: parentMiddleName.text.trim(),

        lastName: parentLastName.text.trim(),

        email: parentEmail.text.trim(),

        gender: selectedParentGender ?? '',

        status: 'Active',

        createdAt: DateTime.now(),
      );

      await accountService.createParent(
        parent: parent,
        password: parentPassword.text,
      );

      if (!mounted) return;

      await _showSuccessDialog(
        title: 'Account Created',
        message: 'Parent account ${parent.id} has been created successfully.',
      );

      if (!mounted) return;

      parentFirstName.clear();
      parentMiddleName.clear();
      parentLastName.clear();
      parentEmail.clear();
      parentPassword.clear();
      parentConfirmPassword.clear();
      childrenId.clear();
      setState(() => selectedParentGender = null);
      parentFormKey.currentState?.reset();
      parentId.clear();
    } catch (error) {
      if (!mounted) return;

      _showError(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> _createTeacher() async {
    FocusScope.of(context).unfocus();

    if (!(teacherFormKey.currentState?.validate() ?? false)) {
      return;
    }

    if (teacherPassword.text != teacherConfirmPassword.text) {
      _showError('Passwords do not match.');
      return;
    }

    if (teacherPassword.text.length < 6) {
      _showError('Password must contain at least 6 characters.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final TeacherModel teacher = TeacherModel(
        id: teacherId.text.trim(),
        username: teacherId.text.trim(),

        firstName: teacherFirstName.text.trim(),

        middleName: teacherMiddleName.text.trim(),

        lastName: teacherLastName.text.trim(),

        email: teacherEmail.text.trim(),

        gender: selectedGender ?? '',

        status: 'Active',

        createdAt: DateTime.now(),
      );

      await accountService.createTeacher(
        teacher: teacher,
        password: teacherPassword.text,
      );

      if (!mounted) return;

      await _showSuccessDialog(
        title: 'Account Created',
        message: 'Teacher account ${teacher.id} has been created successfully.',
      );

      if (!mounted) return;

      _openRegisteredAccounts();
    } catch (error) {
      if (!mounted) return;

      _showError(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // REGISTERED ACCOUNTS
  // ============================================================

  void _openRegisteredAccounts() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RegisteredAccountsScreen(accountService: accountService),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB34735),
        ),
      );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),

          contentPadding: const EdgeInsets.all(26),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,

                decoration: BoxDecoration(
                  color: const Color(0xFFDEF4E5),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: const Icon(
                  Icons.check_rounded,
                  size: 35,
                  color: Color(0xFF319252),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                title,

                textAlign: TextAlign.center,

                style: const TextStyle(
                  color: appBrown,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                message,

                textAlign: TextAlign.center,

                style: const TextStyle(
                  color: appMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                accountType == 'parent'
                    ? 'The Children ID has been saved for the parent–student connection.'
                    : 'You can now view and manage this account from Registered Accounts.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Color(0xFFA09284),
                  fontSize: 10,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,

                height: 48,

                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },

                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),

                  label: const Text('Continue'),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: appAccent,

                    foregroundColor: Colors.white,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,

      onTap: () {
        FocusScope.of(context).unfocus();
      },

      child: Scaffold(
        backgroundColor: appBackground,

        drawer: _buildDrawer(),

        appBar: AppBar(
          backgroundColor: Colors.white,

          foregroundColor: appBrown,

          surfaceTintColor: Colors.white,

          elevation: 0,

          title: const Text(
            'Create Account',

            style: TextStyle(
              color: appBrown,

              fontSize: 20,

              fontWeight: FontWeight.w700,
            ),
          ),

          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),

              child: Container(
                width: 38,

                height: 38,

                decoration: const BoxDecoration(
                  color: appLightBrown,

                  shape: BoxShape.circle,
                ),

                clipBehavior: Clip.antiAlias,

                child: Image.asset(
                  'assets/images/admin.png',

                  fit: BoxFit.cover,

                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person, color: appAccent);
                  },
                ),
              ),
            ),
          ],
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

            padding: const EdgeInsets.fromLTRB(16, 18, 16, 35),

            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Create Account',

                      style: TextStyle(
                        color: appBrown,

                        fontSize: 24,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Create a new student, teacher or parents account.',

                      style: TextStyle(color: appMuted, fontSize: 13),
                    ),

                    const SizedBox(height: 20),

                    _buildAccountTypeCard(),

                    const SizedBox(height: 16),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),

                      child: accountType == 'student'
                          ? _buildStudentForm()
                          : accountType == 'parent'
                          ? AbsorbPointer(
                              absorbing: isSubmitting,
                              child: _buildParentForm(),
                            )
                          : _buildTeacherForm(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACCOUNT TYPE CARD
  // ============================================================

  Widget _buildAccountTypeCard() {
    return _FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const _SectionTitle(
            icon: Icons.person_add_rounded,

            title: 'Account Type',

            subtitle: 'Choose which type of account you want to create.',
          ),

          const SizedBox(height: 18),

          _AccountOption(
            selected: accountType == 'student',

            icon: Icons.school_rounded,

            title: 'Student Account',

            subtitle: 'Create an account for a learner.',

            onTap: () {
              if (isSubmitting) return;

              FocusScope.of(context).unfocus();

              setState(() {
                accountType = 'student';
              });
            },
          ),

          const SizedBox(height: 10),

          _AccountOption(
            selected: accountType == 'teacher',

            icon: Icons.co_present_rounded,

            title: 'Teacher Account',

            subtitle: 'Create an account for a teacher.',

            onTap: () {
              if (isSubmitting) return;

              FocusScope.of(context).unfocus();

              setState(() {
                accountType = 'teacher';
              });
            },
          ),
          const SizedBox(height: 10),
          _AccountOption(
            selected: accountType == 'parent',
            icon: Icons.family_restroom_rounded,
            assetIcon: 'assets/images/parents_icon.png',
            title: 'Parents Account',
            subtitle: 'Create a separate account for a parent.',
            onTap: () {
              if (isSubmitting) return;
              FocusScope.of(context).unfocus();
              setState(() => accountType = 'parent');
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENT FORM
  // ============================================================

  Widget _buildStudentForm() {
    return Form(
      key: studentFormKey,

      child: Column(
        key: const ValueKey('studentForm'),

        children: [
          // PERSONAL INFORMATION
          _FormCard(
            child: Column(
              children: [
                const _SectionTitle(
                  icon: Icons.person_outline,

                  title: 'Personal Information',

                  subtitle: "Enter the student's personal information.",
                ),

                const SizedBox(height: 22),

                _buildTextField(
                  label: 'First Name',

                  required: true,

                  controller: studentFirstName,

                  hint: 'Enter First Name',

                  validator: _requiredValidator,
                ),

                _buildTextField(
                  label: 'Middle Name',

                  controller: studentMiddleName,

                  hint: 'Enter Middle Name',
                ),

                _buildTextField(
                  label: 'Last Name',

                  required: true,

                  controller: studentLastName,

                  hint: 'Enter Last Name',

                  validator: _requiredValidator,
                ),

                _buildDropdown(
                  label: 'Grade',

                  required: true,

                  value: selectedGrade,

                  hint: 'Select Grade',

                  items: const [
                    'Grade 1',
                    'Grade 2',
                    'Grade 3',
                    'Grade 4',
                    'Grade 5',
                    'Grade 6',
                  ],

                  onChanged: (String? value) {
                    setState(() {
                      selectedGrade = value;
                    });
                  },
                ),

                _buildDropdown(
                  label: 'Set',
                  required: true,
                  value: selectedSet,
                  hint: 'Select Set',
                  items: const ['A - Morning', 'B - Afternoon'],
                  onChanged: (String? value) {
                    setState(() => selectedSet = value);
                  },
                ),

                _buildDropdown(
                  label: 'Learning Condition',

                  required: true,

                  value: selectedCondition,

                  hint: 'Select Condition',

                  items: const ['ASD', 'Down Syndrome'],

                  onChanged: (String? value) {
                    setState(() {
                      selectedCondition = value;
                    });
                  },
                ),

                _buildTextField(
                  label: 'Birthday',

                  required: true,

                  controller: studentBirthday,

                  hint: 'Select Birthday',

                  readOnly: true,

                  validator: _requiredValidator,

                  onTap: _selectBirthday,

                  suffixIcon: const Icon(
                    Icons.calendar_month_rounded,
                    color: appAccent,
                    size: 20,
                  ),
                ),

                _buildTextField(
                  label: 'Age',

                  controller: studentAge,

                  hint: 'Age',

                  readOnly: true,
                ),

                _buildDropdown(
                  label: 'Gender',

                  value: selectedStudentGender,

                  hint: 'Select Gender',

                  items: const ['Male', 'Female'],

                  onChanged: (String? value) {
                    setState(() {
                      selectedStudentGender = value;
                    });
                  },
                ),

                _buildTextField(
                  label: 'Address',

                  required: true,

                  controller: studentAddress,

                  hint: 'Enter complete address',

                  validator: _requiredValidator,

                  keyboardType: TextInputType.streetAddress,

                  maxLines: 2,

                  textInputAction: TextInputAction.newline,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // FAMILY INFORMATION
          _FormCard(
            child: Column(
              children: [
                const _SectionTitle(
                  icon: Icons.family_restroom_rounded,

                  title: 'Family Information',

                  subtitle:
                      "Enter the student's parent and guardian information.",
                ),

                const SizedBox(height: 22),

                _buildTextField(
                  label: "Mother's First Name",

                  required: true,

                  controller: motherFirstName,

                  hint: "Enter Mother's First Name",

                  validator: _requiredValidator,
                ),

                _buildTextField(
                  label: "Mother's Last Name",

                  required: true,

                  controller: motherLastName,

                  hint: "Enter Mother's Last Name",

                  validator: _requiredValidator,
                ),

                _buildTextField(
                  label: "Father's First Name",

                  required: true,

                  controller: fatherFirstName,

                  hint: "Enter Father's First Name",

                  validator: _requiredValidator,
                ),

                _buildTextField(
                  label: "Father's Last Name",

                  required: true,

                  controller: fatherLastName,

                  hint: "Enter Father's Last Name",

                  validator: _requiredValidator,
                ),

                _buildTextField(
                  label: "Guardian's First Name",

                  required: true,

                  controller: guardianFirstName,

                  hint: "Enter Guardian's First Name",

                  validator: _requiredValidator,
                ),

                _buildTextField(
                  label: "Guardian's Last Name",

                  required: true,

                  controller: guardianLastName,

                  hint: "Enter Guardian's Last Name",

                  validator: _requiredValidator,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ACCOUNT INFORMATION
          _FormCard(
            child: Column(
              children: [
                const _SectionTitle(
                  icon: Icons.lock_outline_rounded,

                  title: 'Account Information',

                  subtitle: "Create the student's login credentials.",
                ),

                const SizedBox(height: 22),

                _buildTextField(
                  label: 'Student ID or LRN',

                  required: true,

                  controller: studentId,
                  hint: 'Enter Student ID or LRN (e.g. S1234 or 123456789999)',
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: _studentIdValidator,
                ),

                _buildTextField(
                  label: 'Password',

                  required: true,

                  controller: studentPassword,

                  hint: 'Enter password',

                  obscureText: !showStudentPassword,

                  keyboardType: TextInputType.visiblePassword,

                  autocorrect: false,

                  enableSuggestions: false,

                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required.';
                    }

                    if (value.length < 6) {
                      return 'Password must contain at least 6 characters.';
                    }

                    return null;
                  },

                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showStudentPassword = !showStudentPassword;
                      });

                      _showKeyboard();
                    },

                    icon: Icon(
                      showStudentPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,

                      color: appMuted,

                      size: 20,
                    ),
                  ),
                ),

                _buildTextField(
                  label: 'Confirm Password',

                  required: true,

                  controller: studentConfirmPassword,

                  hint: 'Confirm password',

                  obscureText: !showStudentConfirmPassword,

                  keyboardType: TextInputType.visiblePassword,

                  textInputAction: TextInputAction.done,

                  autocorrect: false,

                  enableSuggestions: false,

                  onSubmitted: (_) {
                    _createStudent();
                  },

                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm the password.';
                    }

                    if (value != studentPassword.text) {
                      return 'Passwords do not match.';
                    }

                    return null;
                  },

                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showStudentConfirmPassword =
                            !showStudentConfirmPassword;
                      });

                      _showKeyboard();
                    },

                    icon: Icon(
                      showStudentConfirmPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,

                      color: appMuted,

                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildSubmitButton(
            icon: Icons.person_add_alt_1_rounded,

            label: 'Create Student Account',

            onPressed: _createStudent,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEACHER FORM
  // ============================================================

  Widget _buildParentForm() {
    return Form(
      key: parentFormKey,

      child: Column(
        key: const ValueKey('parentForm'),

        children: [
          _FormCard(
            child: Column(
              children: [
                const _SectionTitle(
                  icon: Icons.person_outline,

                  title: 'Personal Information',

                  subtitle: "Enter the parent's personal information.",
                ),

                const SizedBox(height: 22),

                _buildTextField(
                  label: 'First Name',

                  required: true,

                  controller: parentFirstName,

                  hint: 'Enter First Name',

                  validator: _requiredValidator,
                ),

                _buildTextField(
                  label: 'Middle Name',

                  controller: parentMiddleName,

                  hint: 'Enter Middle Name',
                ),

                _buildTextField(
                  label: 'Last Name',

                  required: true,

                  controller: parentLastName,

                  hint: 'Enter Last Name',

                  validator: _requiredValidator,
                ),

                _buildTextField(
                  label: 'Email',

                  required: true,

                  controller: parentEmail,

                  hint: 'Enter Email Address',

                  validator: _emailValidator,

                  keyboardType: TextInputType.emailAddress,
                ),

                _buildDropdown(
                  label: 'Gender',

                  value: selectedParentGender,

                  hint: 'Select Gender',

                  items: const ['Male', 'Female'],

                  onChanged: (String? value) {
                    setState(() {
                      selectedParentGender = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _FormCard(
            child: Column(
              children: [
                const _SectionTitle(
                  icon: Icons.lock_outline_rounded,

                  title: 'Account Information',

                  subtitle: "Create the parent's login credentials.",
                ),

                const SizedBox(height: 22),

                _buildTextField(
                  label: 'Parents ID',

                  required: true,

                  controller: parentId,
                  hint: 'Enter Parents ID (e.g. P1234)',
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: (value) => _accountIdValidator(value, 'P'),
                ),

                _buildTextField(
                  label: 'Children ID or LRN',
                  required: true,
                  controller: childrenId,
                  hint: 'Enter existing Student ID or LRN (e.g. S2144 or 123456789999)',
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Children ID or LRN is required.';
                    }
                    if (!RegExp(
                      r'^(S[0-9]{4}|[0-9]{1,12})$',
                    ).hasMatch(value.trim().toUpperCase())) {
                      return 'Enter a Student ID (e.g. S2144) or an LRN with 1–12 digits.';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Password',

                  required: true,

                  controller: parentPassword,

                  hint: 'Enter password',

                  obscureText: !showParentPassword,

                  keyboardType: TextInputType.visiblePassword,

                  autocorrect: false,

                  enableSuggestions: false,

                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required.';
                    }

                    if (value.length < 6) {
                      return 'Password must contain at least 6 characters.';
                    }

                    return null;
                  },

                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showParentPassword = !showParentPassword;
                      });

                      _showKeyboard();
                    },

                    icon: Icon(
                      showParentPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,

                      color: appMuted,

                      size: 20,
                    ),
                  ),
                ),

                _buildTextField(
                  label: 'Confirm Password',

                  required: true,

                  controller: parentConfirmPassword,

                  hint: 'Confirm password',

                  obscureText: !showParentConfirmPassword,

                  keyboardType: TextInputType.visiblePassword,

                  textInputAction: TextInputAction.done,

                  autocorrect: false,

                  enableSuggestions: false,

                  onSubmitted: (_) {
                    _createParent();
                  },

                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm the password.';
                    }

                    if (value != parentPassword.text) {
                      return 'Passwords do not match.';
                    }

                    return null;
                  },

                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showParentConfirmPassword = !showParentConfirmPassword;
                      });

                      _showKeyboard();
                    },

                    icon: Icon(
                      showParentConfirmPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,

                      color: appMuted,

                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildSubmitButton(
            icon: Icons.person_add_alt_1_rounded,

            label: 'Create Parents Account',

            onPressed: _createParent,
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherForm() {
    return Form(
      key: teacherFormKey,

      child: Column(
        key: const ValueKey('teacherForm'),

        children: [
          _FormCard(
            child: Column(
              children: [
                const _SectionTitle(
                  icon: Icons.person_outline,

                  title: 'Personal Information',

                  subtitle: "Enter the teacher's personal information.",
                ),

                const SizedBox(height: 22),

                _buildTextField(
                  label: 'First Name',

                  required: true,

                  controller: teacherFirstName,

                  hint: 'Enter First Name',

                  validator: _requiredValidator,
                ),

                _buildTextField(
                  label: 'Middle Name',

                  controller: teacherMiddleName,

                  hint: 'Enter Middle Name',
                ),

                _buildTextField(
                  label: 'Last Name',

                  required: true,

                  controller: teacherLastName,

                  hint: 'Enter Last Name',

                  validator: _requiredValidator,
                ),

                _buildTextField(
                  label: 'Email',

                  required: true,

                  controller: teacherEmail,

                  hint: 'Enter Email Address',

                  validator: _emailValidator,

                  keyboardType: TextInputType.emailAddress,
                ),

                _buildDropdown(
                  label: 'Gender',

                  value: selectedGender,

                  hint: 'Select Gender',

                  items: const ['Male', 'Female'],

                  onChanged: (String? value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _FormCard(
            child: Column(
              children: [
                const _SectionTitle(
                  icon: Icons.lock_outline_rounded,

                  title: 'Account Information',

                  subtitle: "Create the teacher's login credentials.",
                ),

                const SizedBox(height: 22),

                _buildTextField(
                  label: 'Teacher ID',

                  required: true,

                  controller: teacherId,
                  hint: 'Enter Teacher ID (e.g. T1234)',
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: (value) => _accountIdValidator(value, 'T'),
                ),

                _buildTextField(
                  label: 'Password',

                  required: true,

                  controller: teacherPassword,

                  hint: 'Enter password',

                  obscureText: !showTeacherPassword,

                  keyboardType: TextInputType.visiblePassword,

                  autocorrect: false,

                  enableSuggestions: false,

                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required.';
                    }

                    if (value.length < 6) {
                      return 'Password must contain at least 6 characters.';
                    }

                    return null;
                  },

                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showTeacherPassword = !showTeacherPassword;
                      });

                      _showKeyboard();
                    },

                    icon: Icon(
                      showTeacherPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,

                      color: appMuted,

                      size: 20,
                    ),
                  ),
                ),

                _buildTextField(
                  label: 'Confirm Password',

                  required: true,

                  controller: teacherConfirmPassword,

                  hint: 'Confirm password',

                  obscureText: !showTeacherConfirmPassword,

                  keyboardType: TextInputType.visiblePassword,

                  textInputAction: TextInputAction.done,

                  autocorrect: false,

                  enableSuggestions: false,

                  onSubmitted: (_) {
                    _createTeacher();
                  },

                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm the password.';
                    }

                    if (value != teacherPassword.text) {
                      return 'Passwords do not match.';
                    }

                    return null;
                  },

                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showTeacherConfirmPassword =
                            !showTeacherConfirmPassword;
                      });

                      _showKeyboard();
                    },

                    icon: Icon(
                      showTeacherConfirmPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,

                      color: appMuted,

                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildSubmitButton(
            icon: Icons.person_add_alt_1_rounded,

            label: 'Create Teacher Account',

            onPressed: _createTeacher,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,

    bool required = false,
    bool readOnly = false,
    bool obscureText = false,

    int maxLines = 1,

    TextInputType? keyboardType,

    TextInputAction? textInputAction,

    bool autocorrect = true,
    bool enableSuggestions = true,

    String? Function(String?)? validator,

    VoidCallback? onTap,

    ValueChanged<String>? onSubmitted,

    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _fieldLabel(label, required),

          const SizedBox(height: 8),

          TextFormField(
            controller: controller,

            readOnly: readOnly,

            obscureText: obscureText,

            maxLines: obscureText ? 1 : maxLines,

            keyboardType:
                keyboardType ??
                (obscureText
                    ? TextInputType.visiblePassword
                    : TextInputType.text),

            textInputAction:
                textInputAction ??
                (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),

            autocorrect: autocorrect,

            enableSuggestions: enableSuggestions,

            enableInteractiveSelection: true,

            validator: validator,

            onTap: () {
              if (!readOnly) {
                _showKeyboard();
              }

              onTap?.call();
            },

            onFieldSubmitted: onSubmitted,

            style: const TextStyle(color: appBrown, fontSize: 14),

            decoration: _inputDecoration(
              hint: hint,

              suffixIcon: suffixIcon,

              readOnly: readOnly,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildDropdown({
    required String label,
    required String hint,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,

    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _fieldLabel(label, required),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            key: ValueKey('$label-$value'),

            initialValue: value,

            isExpanded: true,

            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,

              color: appAccent,
            ),

            hint: Text(
              hint,

              style: const TextStyle(color: Color(0xFFB4AAA0), fontSize: 13),
            ),

            items: items
                .map(
                  (String item) => DropdownMenuItem<String>(
                    value: item,

                    child: Text(
                      item,

                      style: const TextStyle(color: appBrown, fontSize: 13),
                    ),
                  ),
                )
                .toList(),

            onChanged: isSubmitting
                ? null
                : (String? newValue) {
                    FocusScope.of(context).unfocus();

                    onChanged(newValue);
                  },

            validator: required
                ? (String? selected) {
                    if (selected == null || selected.isEmpty) {
                      return 'This field is required.';
                    }

                    return null;
                  }
                : null,

            decoration: _inputDecoration(hint: hint),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _fieldLabel(String label, bool required) {
    return Row(
      children: [
        Text(
          label,

          style: const TextStyle(
            color: appBrown,

            fontSize: 12,

            fontWeight: FontWeight.w600,
          ),
        ),

        if (required)
          const Text(
            ' *',

            style: TextStyle(
              color: Color(0xFFB84A3A),

              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
    bool readOnly = false,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(color: Color(0xFFB4AAA0), fontSize: 13),

      suffixIcon: suffixIcon,

      filled: true,

      fillColor: readOnly ? const Color(0xFFF4F1ED) : const Color(0xFFFCFAF7),

      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),

        borderSide: const BorderSide(color: appBorder),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),

        borderSide: const BorderSide(color: appBorder),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),

        borderSide: const BorderSide(color: appAccent, width: 1.4),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),

        borderSide: const BorderSide(color: Color(0xFFB34735)),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),

        borderSide: const BorderSide(color: Color(0xFFB34735), width: 1.4),
      ),
    );
  }

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget _buildSubmitButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,

      height: 52,

      child: ElevatedButton.icon(
        onPressed: isSubmitting ? null : onPressed,

        icon: isSubmitting
            ? const SizedBox(
                width: 18,

                height: 18,

                child: CircularProgressIndicator(
                  strokeWidth: 2,

                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 19),

        label: Text(
          isSubmitting ? 'Creating Account...' : label,

          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: appAccent,

          foregroundColor: Colors.white,

          disabledBackgroundColor: const Color(0xFFC5A98B),

          disabledForegroundColor: Colors.white,

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _buildDrawer() {
    return Drawer(
      width: 280,

      backgroundColor: appSidebar,

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
                  color: appBrown,
                  size: 60,
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

            _DrawerItem(
              icon: Icons.home_rounded,

              label: 'Dashboard',

              onTap: () {
                Navigator.pop(context);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DashboardScreen(accountService: accountService),
                  ),
                );
              },
            ),

            _DrawerItem(
              icon: Icons.person_add_alt_1_rounded,

              label: 'Create Account',

              selected: true,

              onTap: () {
                Navigator.pop(context);
              },
            ),

            _DrawerItem(
              icon: Icons.people_alt_rounded,

              label: 'Registered Accounts',

              onTap: () {
                Navigator.pop(context);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisteredAccountsScreen(
                      accountService: accountService,
                    ),
                  ),
                );
              },
            ),

            const ReportNavigationItem(),

            const Spacer(),

            const Text(
              'Version 1.0',

              style: TextStyle(color: Color(0xFF87684C), fontSize: 11),
            ),

            const SizedBox(height: 10),

            _DrawerItem(
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

  // ============================================================
  // LOGOUT
  // ============================================================

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

            style: TextStyle(color: appBrown, fontWeight: FontWeight.w700),
          ),

          content: const Text(
            'Are you sure you want to logout?',

            style: TextStyle(color: appMuted),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              child: const Text('Cancel', style: TextStyle(color: appMuted)),
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
                backgroundColor: appAccent,

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
// FORM CARD
// ============================================================

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: appBorder),

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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
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
            color: appLightBrown,

            borderRadius: BorderRadius.circular(12),
          ),

          child: Icon(icon, size: 20, color: appAccent),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: const TextStyle(
                  color: appBrown,

                  fontSize: 15,

                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,

                style: const TextStyle(
                  color: appMuted,

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
// ACCOUNT OPTION
// ============================================================

class _AccountOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String? assetIcon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountOption({
    required this.selected,
    required this.icon,
    this.assetIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFFAF3) : Colors.white,

      borderRadius: BorderRadius.circular(16),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(16),

        child: Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: selected
                  ? const Color(0xFFB57A3D)
                  : const Color(0xFFE5DFD6),

              width: selected ? 1.5 : 1,
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 19,

                height: 19,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  border: Border.all(
                    color: selected ? appAccent : const Color(0xFFB7AFA5),

                    width: 2,
                  ),
                ),

                child: selected
                    ? Center(
                        child: Container(
                          width: 9,

                          height: 9,

                          decoration: const BoxDecoration(
                            color: appAccent,

                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              Container(
                width: 40,

                height: 40,

                decoration: BoxDecoration(
                  color: appLightBrown,

                  borderRadius: BorderRadius.circular(11),
                ),

                child: assetIcon == null
                    ? Icon(icon, color: appAccent, size: 20)
                    : Padding(
                        padding: const EdgeInsets.all(7),
                        child: Image.asset(
                          assetIcon!,
                          color: appAccent,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: const TextStyle(
                        color: appBrown,

                        fontSize: 13,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,

                      style: const TextStyle(color: appMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DRAWER ITEM
// ============================================================

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
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
