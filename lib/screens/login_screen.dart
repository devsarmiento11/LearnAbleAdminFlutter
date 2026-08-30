import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool obscurePassword = true;
  bool rememberMe = false;
  bool isLoading = false;

  String? loginMessage;

  static const Color backgroundColor = Color(0xFFF8F5F0);

  static const Color brown = Color(0xFF4D2F18);

  static const Color accent = Color(0xFFA56B2F);

  static const Color muted = Color(0xFF9A8A79);

  static const Color inputBackground = Color(0xFFFAF8F5);

  static const Color inputBorder = Color(0xFFE5DDD3);

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();

    usernameFocusNode.dispose();
    passwordFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // SHOW PHONE KEYBOARD
  // ============================================================

  void _showKeyboard(FocusNode focusNode) {
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    final String username = usernameController.text.trim();

    final String password = passwordController.text;

    setState(() {
      loginMessage = null;
    });

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        loginMessage = 'Please enter your username and password.';
      });

      return;
    }

    setState(() {
      isLoading = true;
    });

    final bool success = await widget.authService.login(
      username: username,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      passwordController.clear();

      setState(() {
        loginMessage = 'Invalid username or password.';
      });

      passwordFocusNode.requestFocus();

      _showKeyboard(passwordFocusNode);
    }
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  void forgotPassword() {
    FocusScope.of(context).unfocus();

    setState(() {
      loginMessage =
          'Please contact the system administrator to reset the password.';
    });
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
        backgroundColor: backgroundColor,

        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool verySmallPhone = constraints.maxWidth <= 360;

              return Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,

                  padding: EdgeInsets.all(verySmallPhone ? 18 : 20),

                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),

                    child: Container(
                      width: double.infinity,

                      padding: EdgeInsets.symmetric(
                        horizontal: verySmallPhone ? 18 : 24,

                        vertical: verySmallPhone ? 25 : 30,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(
                          verySmallPhone ? 18 : 20,
                        ),

                        border: Border.all(color: const Color(0xFFEEE8DF)),

                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x174D2F18),
                            blurRadius: 40,
                            offset: Offset(0, 15),
                          ),
                        ],
                      ),

                      child: Column(
                        children: [
                          // ========================================
                          // LOGO
                          // ========================================
                          Image.asset(
                            'assets/images/logo.png',

                            width: verySmallPhone ? 90 : 100,

                            height: 80,

                            fit: BoxFit.contain,

                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  return const Icon(
                                    Icons.school_rounded,
                                    size: 65,
                                    color: accent,
                                  );
                                },
                          ),

                          const SizedBox(height: 14),

                          // ========================================
                          // TITLE
                          // ========================================
                          Text(
                            'Admin Login',

                            style: TextStyle(
                              color: brown,

                              fontSize: verySmallPhone ? 23 : 24,

                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Sign in to continue',

                            style: TextStyle(color: muted, fontSize: 13),
                          ),

                          const SizedBox(height: 28),

                          // ========================================
                          // USERNAME
                          // ========================================
                          _fieldLabel('Username'),

                          const SizedBox(height: 7),

                          TextField(
                            controller: usernameController,

                            focusNode: usernameFocusNode,

                            enabled: !isLoading,

                            readOnly: false,

                            enableInteractiveSelection: true,

                            keyboardType: TextInputType.text,

                            textInputAction: TextInputAction.next,

                            autocorrect: false,

                            enableSuggestions: false,

                            onTap: () {
                              _showKeyboard(usernameFocusNode);
                            },

                            onSubmitted: (_) {
                              passwordFocusNode.requestFocus();

                              _showKeyboard(passwordFocusNode);
                            },

                            decoration: _inputDecoration(
                              hint: 'Enter username',

                              icon: Icons.person,
                            ),
                          ),

                          const SizedBox(height: 19),

                          // ========================================
                          // PASSWORD
                          // ========================================
                          _fieldLabel('Password'),

                          const SizedBox(height: 7),

                          TextField(
                            controller: passwordController,

                            focusNode: passwordFocusNode,

                            enabled: !isLoading,

                            readOnly: false,

                            obscureText: obscurePassword,

                            enableInteractiveSelection: true,

                            keyboardType: TextInputType.visiblePassword,

                            textInputAction: TextInputAction.done,

                            autocorrect: false,

                            enableSuggestions: false,

                            onTap: () {
                              _showKeyboard(passwordFocusNode);
                            },

                            onSubmitted: (_) {
                              login();
                            },

                            decoration: _inputDecoration(
                              hint: 'Enter password',

                              icon: Icons.lock,

                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });

                                  passwordFocusNode.requestFocus();

                                  _showKeyboard(passwordFocusNode);
                                },

                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,

                                  size: 20,

                                  color: muted,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ========================================
                          // REMEMBER + FORGOT PASSWORD
                          // ========================================
                          if (verySmallPhone)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                _rememberMe(),

                                const SizedBox(height: 10),

                                _forgotPasswordButton(),
                              ],
                            )
                          else
                            Row(
                              children: [
                                _rememberMe(),

                                const Spacer(),

                                _forgotPasswordButton(),
                              ],
                            ),

                          // ========================================
                          // LOGIN MESSAGE
                          // ========================================
                          if (loginMessage != null) ...[
                            const SizedBox(height: 12),

                            Text(
                              loginMessage!,

                              textAlign: TextAlign.center,

                              style: const TextStyle(
                                color: Color(0xFFB94A48),

                                fontSize: 12,
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // ========================================
                          // LOGIN BUTTON
                          // ========================================
                          SizedBox(
                            width: double.infinity,

                            height: 50,

                            child: ElevatedButton(
                              onPressed: isLoading ? null : login,

                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,

                                foregroundColor: Colors.white,

                                elevation: 0,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),

                              child: isLoading
                                  ? const SizedBox(
                                      width: 21,

                                      height: 21,

                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,

                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'LOGIN',

                                      style: TextStyle(
                                        fontSize: 14,

                                        fontWeight: FontWeight.w700,

                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ========================================
                          // ADMIN ACCESS
                          // ========================================
                          Container(
                            width: double.infinity,

                            padding: const EdgeInsets.all(11),

                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFAF3),

                              borderRadius: BorderRadius.circular(10),

                              border: Border.all(
                                color: const Color(0xFFF0E3D2),
                              ),
                            ),

                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                Icon(Icons.shield, size: 17, color: accent),

                                SizedBox(width: 7),

                                Text(
                                  'Administrator Access',

                                  style: TextStyle(color: muted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FIELD LABEL
  // ============================================================

  Widget _fieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,

      child: Text(
        text,

        style: const TextStyle(
          color: brown,

          fontSize: 13,

          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // REMEMBER ME
  // ============================================================

  Widget _rememberMe() {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        SizedBox(
          width: 20,
          height: 20,

          child: Checkbox(
            value: rememberMe,

            activeColor: accent,

            side: const BorderSide(color: Color(0xFFB5A99D)),

            onChanged: isLoading
                ? null
                : (bool? value) {
                    setState(() {
                      rememberMe = value ?? false;
                    });
                  },
          ),
        ),

        const SizedBox(width: 7),

        const Text(
          'Remember me',

          style: TextStyle(color: Color(0xFF7F7062), fontSize: 12),
        ),
      ],
    );
  }

  // ============================================================
  // FORGOT PASSWORD BUTTON
  // ============================================================

  Widget _forgotPasswordButton() {
    return TextButton(
      onPressed: isLoading ? null : forgotPassword,

      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,

        minimumSize: const Size(0, 30),

        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),

      child: const Text(
        'Forgot Password?',

        style: TextStyle(
          color: accent,

          fontSize: 12,

          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(color: Color(0xFFB5A99D), fontSize: 14),

      prefixIcon: Icon(icon, size: 19, color: accent),

      suffixIcon: suffix,

      filled: true,

      fillColor: inputBackground,

      contentPadding: const EdgeInsets.symmetric(vertical: 15),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),

        borderSide: const BorderSide(color: inputBorder),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),

        borderSide: const BorderSide(color: inputBorder),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),

        borderSide: const BorderSide(color: accent, width: 1.3),
      ),
    );
  }
}
