import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/profile_report.dart';
import '../services/report_service.dart';
import '../services/profile_pdf.dart';
import '../widgets/report_navigation_item.dart';
import 'dashboard_screen.dart';
import 'create_account_screen.dart';
import 'registered_accounts_screen.dart';
import 'login_screen.dart';
import '../services/firebase_auth_service.dart';

const _brown = Color(0xFF4D2F18);
const _muted = Color(0xFF918274);
const _cream = Color(0xFFF8F5F0);

class ReportGenerationScreen extends StatefulWidget {
  const ReportGenerationScreen({super.key, this.service, this.preview = false});
  final ReportService? service;
  final bool preview;
  @override
  State<ReportGenerationScreen> createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen> {
  late final ReportService _service = widget.service ?? FirebaseReportService();
  List<ReportStudent> _students = [];
  String? _year;
  String _query = '';
  String? _error;
  String? _printing;
  bool _loading = true;
  int _page = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final students = await _service.students();
      if (!mounted) return;
      setState(() {
        _students = students;
        final years = _years;
        if (!years.contains(_year)) _year = years.firstOrNull;
        _page = 0;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Unable to load students. Check your connection and try again.';
          _loading = false;
        });
      }
    }
  }

  List<String> get _years =>
      _students.expand((s) => s.enrollments.keys).toSet().toList()
        ..sort((a, b) => b.compareTo(a));
  String _yearLabel(String year) =>
      year.isEmpty ? 'School year not assigned' : year;
  Future<void> _print(ReportStudent student) async {
    final year = _year;
    if (year == null || _printing != null) return;
    setState(() => _printing = student.id);
    try {
      final report = await _service.profile(student, year);
      final bytes = await buildProfilePdf(report);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => _PdfScreen(
            bytes: bytes,
            name: student.name,
            filename:
                'LearnAble_${student.id.replaceAll(RegExp(r"[^a-zA-Z0-9_-]"), "_")}_${year.isEmpty ? "unassigned" : year}.pdf',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to prepare the profile PDF. Check your connection and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _printing = null);
    }
  }

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE8E1D8)),
    ),
    child: child,
  );
  @override
  Widget build(BuildContext context) {
    final filtered = _students
        .where(
          (s) =>
              s.enrollments.containsKey(_year) &&
              '${s.name} ${s.id}'.toLowerCase().contains(
                _query.toLowerCase().trim(),
              ),
        )
        .toList();
    final visible = filtered.skip(_page * 8).take(8).toList();
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _brown,
        title: const Text('LearnAble Admin'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh students',
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: _drawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1060),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0DFC8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Image.asset(
                      'assets/images/report_generation.png',
                      width: 35,
                      height: 35,
                      color: _brown,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Generation',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: _brown,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Student profiles, ready to review and print.',
                          style: TextStyle(color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (widget.preview) ...[
                const Text(
                  'LOCAL DESIGN PREVIEW • Sample students and grades',
                  style: TextStyle(color: _muted),
                ),
                const SizedBox(height: 12),
              ],
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose a school-year batch',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _brown,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select a saved batch to see its existing student accounts.',
                      style: TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 18),
                    if (_loading)
                      const LinearProgressIndicator()
                    else if (_error != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_error!),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Try again'),
                          ),
                        ],
                      )
                    else if (_years.isEmpty)
                      const Text('No student batches available yet.')
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey(_year),
                        initialValue: _year,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'School year',
                          prefixIcon: const Icon(
                            Icons.calendar_month_outlined,
                            color: _brown,
                          ),
                          filled: true,
                          fillColor: _cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: _years
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text(_yearLabel(year)),
                              ),
                            )
                            .toList(),
                        onChanged: _printing != null
                            ? null
                            : (year) => setState(() {
                                _year = year;
                                _page = 0;
                              }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!_loading && _error == null)
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.school_rounded, color: _brown),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Student profiles',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _brown,
                              ),
                            ),
                          ),
                          Text(
                            '${filtered.length} ${filtered.length == 1 ? 'student' : 'students'}',
                            style: const TextStyle(color: _muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        onChanged: (value) => setState(() {
                          _query = value;
                          _page = 0;
                        }),
                        decoration: InputDecoration(
                          hintText: 'Search student name or ID...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: _cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No students found for this selection.',
                            ),
                          ),
                        ),
                      ...visible.map((student) => _studentRow(student)),
                      if (filtered.length > 8)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: _page > 0
                                  ? () => setState(() => _page--)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text(
                              'Page ${_page + 1} of ${(filtered.length / 8).ceil()}',
                            ),
                            IconButton(
                              onPressed: (_page + 1) * 8 < filtered.length
                                  ? () => setState(() => _page++)
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              const Text(
                'Each PDF includes Profile, Recent Activity, and Grades. Preview the pages, then print or save as PDF.',
                style: TextStyle(color: _muted, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _studentRow(ReportStudent student) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _cream,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8E1D8)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final details = Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFEEDCC4),
              child: Icon(Icons.person_outline, color: _brown),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _brown,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      student.id,
                      student.enrollments[_year] ?? '',
                    ].where((s) => s.isNotEmpty).join('  •  '),
                    style: const TextStyle(color: _muted),
                  ),
                ],
              ),
            ),
          ],
        );
        final button = FilledButton.icon(
          onPressed: _printing == null ? () => _print(student) : null,
          style: FilledButton.styleFrom(
            backgroundColor: _brown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          ),
          icon: _printing == student.id
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print_outlined, size: 18),
          label: Text(
            _printing == student.id ? 'Preparing...' : 'Print Profile',
          ),
        );
        return constraints.maxWidth < 550
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [details, const SizedBox(height: 16), button],
              )
            : Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 16),
                  button,
                ],
              );
      },
    ),
  );
  Widget _drawer() => Drawer(
    width: 280,
    backgroundColor: const Color(0xFFDDB98D),
    child: SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Image.asset('assets/images/logo.png', width: 100, height: 80),
          const SizedBox(height: 8),
          const Text(
            'ADMIN PANEL',
            style: TextStyle(
              letterSpacing: 3,
              color: _brown,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Padding(padding: EdgeInsets.all(24), child: Divider()),
          _destination(
            Icons.home_rounded,
            'Dashboard',
            () => const DashboardScreen(),
          ),
          _destination(
            Icons.person_add_alt_1_rounded,
            'Create Account',
            () => const CreateAccountScreen(),
          ),
          _destination(
            Icons.people_alt_rounded,
            'Registered Accounts',
            () => const RegisteredAccountsScreen(),
          ),
          ReportNavigationItem(
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text(
            'Version 1.0',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: _brown),
            title: const Text('Logout', style: TextStyle(color: _brown)),
            onTap: () async {
              Navigator.pop(context);
              if (widget.preview) return;
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !mounted) return;
              final auth = FirebaseAdminAuthService();
              try {
                await auth.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(authService: auth),
                  ),
                  (_) => false,
                );
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to sign out. Please try again.'),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
  Widget _destination(IconData icon, String name, Widget Function() screen) =>
      ListTile(
        leading: Icon(icon, color: _brown),
        title: Text(name, style: const TextStyle(color: _brown, fontSize: 14)),
        onTap: () {
          Navigator.pop(context);
          if (!widget.preview) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => screen()),
            );
          }
        },
      );
}

class _PdfScreen extends StatelessWidget {
  const _PdfScreen({
    required this.bytes,
    required this.name,
    required this.filename,
  });
  final Uint8List bytes;
  final String name;
  final String filename;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('$name • Profile PDF'),
      backgroundColor: _cream,
      foregroundColor: _brown,
    ),
    body: PdfPreview(
      build: (_) async => bytes,
      pdfFileName: filename,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      allowSharing: false,
      loadingWidget: const Center(child: CircularProgressIndicator()),
      onError: (_, error) => const Center(
        child: Text(
          'PDF preview could not load. Please reopen the profile and try again.',
        ),
      ),
      actions: [
        PdfPreviewAction(
          icon: const Icon(Icons.download),
          onPressed: (context, build, format) async {
            await Printing.sharePdf(bytes: bytes, filename: filename);
          },
        ),
      ],
    ),
  );
}
