import 'package:flutter/material.dart';

import '../models/archived_student_summary.dart';
import '../services/archive_service.dart';

const Color archiveBackground = Color(0xFFF8F5F0);
const Color archiveBrown = Color(0xFF4D2F18);
const Color archiveAccent = Color(0xFF8C5A2D);
const Color archiveMuted = Color(0xFF918274);
const Color archiveBorder = Color(0xFFE8E1D8);
const Color archiveLightBrown = Color(0xFFF7F1E9);

class ArchivedStudentsSection extends StatefulWidget {
  final ArchiveService archiveService;

  const ArchivedStudentsSection({super.key, required this.archiveService});

  @override
  State<ArchivedStudentsSection> createState() =>
      _ArchivedStudentsSectionState();
}

class _ArchivedStudentsSectionState extends State<ArchivedStudentsSection> {
  final TextEditingController searchController = TextEditingController();

  List<ArchivedStudentSummary> archivedStudents = [];
  List<String> schoolYears = [];

  String? selectedSchoolYear;

  bool loading = true;

  @override
  void initState() {
    super.initState();

    searchController.addListener(_searchChanged);

    _loadArchive();
  }

  @override
  void dispose() {
    searchController.removeListener(_searchChanged);

    searchController.dispose();

    super.dispose();
  }

  void _searchChanged() {
    if (!mounted) return;

    setState(() {});
  }

  Future<void> _loadArchive() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final List<String> loadedYears = await widget.archiveService
          .getArchivedSchoolYears();

      final List<ArchivedStudentSummary> loadedStudents = await widget
          .archiveService
          .getArchivedStudents();

      if (!mounted) return;

      setState(() {
        schoolYears = loadedYears;
        archivedStudents = loadedStudents;

        if (schoolYears.isEmpty) {
          selectedSchoolYear = null;
        } else if (selectedSchoolYear == null ||
            !schoolYears.contains(selectedSchoolYear)) {
          selectedSchoolYear = schoolYears.first;
        }

        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
    }
  }

  List<ArchivedStudentSummary> get filteredStudents {
    final String search = searchController.text.trim().toLowerCase();

    return archivedStudents.where((ArchivedStudentSummary student) {
      if (selectedSchoolYear != null &&
          student.schoolYear != selectedSchoolYear) {
        return false;
      }

      if (search.isEmpty) {
        return true;
      }

      return student.studentName.toLowerCase().contains(search) ||
          student.studentId.toLowerCase().contains(search) ||
          student.grade.toLowerCase().contains(search) ||
          student.condition.toLowerCase().contains(search) ||
          student.completionStatus.toLowerCase().contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _panel(
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 45),
          child: Center(child: CircularProgressIndicator(color: archiveAccent)),
        ),
      );
    }

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.archive_rounded, color: archiveAccent, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Archived Students',
                      style: TextStyle(
                        color: archiveBrown,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Student performance summaries from previous school years.',
                      style: TextStyle(color: archiveMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (schoolYears.isNotEmpty) ...[
            const Text(
              'School Year',
              style: TextStyle(
                color: archiveBrown,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 7),

            DropdownButtonFormField<String>(
              key: ValueKey(selectedSchoolYear),
              initialValue: selectedSchoolYear,
              isExpanded: true,
              decoration: _inputDecoration(),
              items: schoolYears.map((String year) {
                return DropdownMenuItem<String>(value: year, child: Text(year));
              }).toList(),
              onChanged: (String? value) {
                if (value == null) return;

                setState(() {
                  selectedSchoolYear = value;
                });
              },
            ),

            const SizedBox(height: 13),

            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: _inputDecoration().copyWith(
                hintText: 'Search archived students...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: archiveAccent,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 18),
          ],

          if (schoolYears.isEmpty)
            _emptyState(
              icon: Icons.archive_outlined,
              title: 'No archived school years',
              message: 'Archive a school year from the Dashboard first.',
            )
          else if (filteredStudents.isEmpty)
            _emptyState(
              icon: Icons.person_search_rounded,
              title: 'No archived students found',
              message: searchController.text.trim().isNotEmpty
                  ? 'Try a different search.'
                  : 'There are no students for this school year.',
            )
          else
            ...filteredStudents.map(_studentCard),
        ],
      ),
    );
  }

  Widget _studentCard(ArchivedStudentSummary student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: archiveBorder),
      ),
      child: InkWell(
        onTap: () {
          _showStudentSummary(student);
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: archiveLightBrown,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.archive_rounded,
                      color: archiveAccent,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.studentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: archiveBrown,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${student.studentId} • ${student.schoolYear}',
                          style: const TextStyle(
                            color: archiveMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(Icons.chevron_right_rounded, color: archiveMuted),
                ],
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _chip(student.grade),
                  _chip(student.condition),
                  _chip(student.completionStatus),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Text(
                    'Overall Average',
                    style: TextStyle(color: archiveMuted, fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    '${student.overallAverage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: archiveAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: archiveLightBrown,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: archiveAccent,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _showStudentSummary(ArchivedStudentSummary student) async {
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
              const Icon(Icons.archive_rounded, color: archiveAccent),

              const SizedBox(width: 9),

              const Expanded(
                child: Text(
                  'Archived Summary',
                  style: TextStyle(
                    color: archiveBrown,
                    fontSize: 17,
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
                  Text(
                    student.studentName,
                    style: const TextStyle(
                      color: archiveBrown,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    student.studentId,
                    style: const TextStyle(color: archiveMuted, fontSize: 11),
                  ),

                  const SizedBox(height: 18),

                  _summaryRow('School Year', student.schoolYear),
                  _summaryRow('Grade', student.grade),
                  _summaryRow('Learning Condition', student.condition),

                  const Divider(height: 28, color: archiveBorder),

                  _summaryRow(
                    'English Average',
                    '${student.englishAverage.toStringAsFixed(0)}%',
                  ),
                  _summaryRow(
                    'Mathematics Average',
                    '${student.mathematicsAverage.toStringAsFixed(0)}%',
                  ),
                  _summaryRow(
                    'Science Average',
                    '${student.scienceAverage.toStringAsFixed(0)}%',
                  ),
                  _summaryRow(
                    'Overall Average',
                    '${student.overallAverage.toStringAsFixed(0)}%',
                    strong: true,
                  ),

                  const Divider(height: 28, color: archiveBorder),

                  _summaryRow(
                    'Activities Completed',
                    '${student.activitiesCompleted} / ${student.totalActivities}',
                  ),
                  _summaryRow('Total Attempts', '${student.totalAttempts}'),
                  _summaryRow('Status', student.completionStatus),
                  _summaryRow('Date Archived', _formatDate(student.archivedAt)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: archiveMuted, fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: strong ? archiveAccent : archiveBrown,
                fontSize: strong ? 14 : 11,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: archiveBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 35, color: archiveAccent),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: archiveBrown,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: archiveMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: archiveBorder),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFFCFAF7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: archiveBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: archiveBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: archiveAccent, width: 1.4),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');

    final String day = date.day.toString().padLeft(2, '0');

    return '$month/$day/${date.year}';
  }
}
