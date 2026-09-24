import 'package:flutter/material.dart';

import '../models/archived_student_summary.dart';
import '../services/archive_service.dart';
import '../services/promotion_service.dart';

const Color archiveBackground = Color(0xFFF8F5F0);
const Color archiveBrown = Color(0xFF4D2F18);
const Color archiveAccent = Color(0xFF8C5A2D);
const Color archiveMuted = Color(0xFF918274);
const Color archiveBorder = Color(0xFFE8E1D8);
const Color archiveLightBrown = Color(0xFFF7F1E9);

class ArchivedStudentsSection extends StatefulWidget {
  final ArchiveService archiveService;
  final PromotionService? promotionService;
  final VoidCallback? onPromoted;

  const ArchivedStudentsSection({
    super.key,
    required this.archiveService,
    this.promotionService,
    this.onPromoted,
  });

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
  bool unarchiving = false;
  bool selecting = false;
  bool loadingPromotion = false;
  bool promoting = false;
  bool reviewing = false;
  int promotionRequest = 0;
  final selectedIds = <String>{};
  PromotionState promotionState = const PromotionState();
  String? promotionError;

  bool get promotionBusy => loadingPromotion || reviewing || promoting;

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
      await _loadPromotion();
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

  Future<bool> _loadPromotion() async {
    final service = widget.promotionService;
    final year = selectedSchoolYear;
    if (service == null || year == null) return false;
    final request = ++promotionRequest;
    setState(() {
      loadingPromotion = true;
      promotionError = null;
    });
    try {
      final result = await service.load(year);
      if (!mounted || request != promotionRequest) return false;
      setState(() {
        promotionState = result;
        selectedIds.removeWhere(
          (id) => result.candidates[id]?.eligible != true,
        );
      });
      return true;
    } catch (error) {
      if (mounted && request == promotionRequest) {
        setState(
          () => promotionError =
              'Unable to load promotion details. Please retry.',
        );
      }
      return false;
    } finally {
      if (mounted && request == promotionRequest) {
        setState(() => loadingPromotion = false);
      }
    }
  }

  void _toggleStudent(String id) {
    if (promotionBusy ||
        promotionError != null ||
        promotionState.candidates[id]?.eligible != true) {
      return;
    }
    setState(() {
      if (!selectedIds.add(id)) selectedIds.remove(id);
    });
  }

  void _promotionMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _promoteSelected() async {
    if (promotionBusy || selectedIds.isEmpty || selectedIds.length > 200) {
      return;
    }
    final originalIds = Set<String>.of(selectedIds);
    setState(() => reviewing = true);
    try {
      if (!await _loadPromotion() || !mounted) return;
      if (selectedIds.length != originalIds.length ||
          promotionState.activeYear == null ||
          promotionState.issue.isNotEmpty) {
        _promotionMessage(
          'Promotion details changed. Review the available students and school year.',
        );
        return;
      }
      final year = promotionState.activeYear!;
      final sourceYear = selectedSchoolYear!;
      final candidates = selectedIds
          .map((id) => promotionState.candidates[id]!)
          .toList();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Promote ${candidates.length} student${candidates.length == 1 ? '' : 's'}?',
            style: const TextStyle(
              color: archiveBrown,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enroll in $year and advance each student by one grade.',
                    style: const TextStyle(color: archiveBrown),
                  ),
                  const SizedBox(height: 14),
                  for (final candidate in candidates)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            archivedStudents
                                .firstWhere(
                                  (student) =>
                                      student.studentId == candidate.id,
                                )
                                .studentName,
                            style: const TextStyle(
                              color: archiveBrown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${candidate.grade} → ${candidate.nextGrade}',
                            style: const TextStyle(color: archiveAccent),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    'Archived summaries stay in $sourceYear. Students already enrolled in $year cannot be promoted again.',
                    style: const TextStyle(color: archiveMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: TextButton.styleFrom(foregroundColor: archiveAccent),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: _unarchiveButtonStyle(),
              child: const Text('Confirm Promotion'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => promoting = true);
      try {
        await widget.promotionService!.promote(
          sourceYear: sourceYear,
          targetYear: year,
          students: candidates,
        );
        if (!mounted) return;
        setState(() {
          final updated = Map<String, PromotionCandidate>.of(
            promotionState.candidates,
          );
          for (final candidate in candidates) {
            updated[candidate.id] = PromotionCandidate(
              id: candidate.id,
              grade: candidate.nextGrade!,
              nextGrade: null,
              enrolled: true,
              reason: 'Already enrolled in $year',
            );
          }
          promotionState = PromotionState(
            activeYear: year,
            candidates: updated,
          );
          selectedIds.clear();
          selecting = false;
        });
        _promotionMessage(
          '${candidates.length} student${candidates.length == 1 ? '' : 's'} enrolled in $year. Each grade advanced by one.',
        );
        widget.onPromoted?.call();
      } catch (error) {
        if (!mounted) return;
        _promotionMessage(
          'Promotion could not be confirmed. ${error.toString().replaceFirst('Exception: ', '')}',
        );
        await _loadPromotion();
      }
    } finally {
      if (mounted) {
        setState(() {
          reviewing = false;
          promoting = false;
        });
      }
    }
  }

  Widget _promotionControls() {
    final available = filteredStudents
        .where(
          (student) =>
              promotionState.candidates[student.studentId]?.eligible == true,
        )
        .toList();
    final selectedVisible = available
        .where((student) => selectedIds.contains(student.studentId))
        .length;
    final ready =
        !promotionBusy &&
        promotionError == null &&
        promotionState.activeYear != null &&
        promotionState.issue.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: archiveLightBrown,
            borderRadius: BorderRadius.circular(12),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Promote to active school year',
                    style: TextStyle(color: archiveMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    loadingPromotion
                        ? 'Loading...'
                        : promotionState.activeYear ?? 'Not Selected',
                    style: const TextStyle(
                      color: archiveBrown,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
              final button = OutlinedButton.icon(
                onPressed:
                    !promotionBusy &&
                        (selecting || (ready && available.isNotEmpty))
                    ? () => setState(() {
                        selecting = !selecting;
                        selectedIds.clear();
                      })
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: archiveAccent,
                  side: const BorderSide(color: archiveAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                icon: Icon(
                  selecting ? Icons.close_rounded : Icons.checklist_rounded,
                  size: 18,
                ),
                label: Text(
                  selecting ? 'Cancel Selection' : 'Select Accounts',
                  style: const TextStyle(fontSize: 12),
                ),
              );
              if (constraints.maxWidth < 400) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 8), button],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 8),
                  button,
                ],
              );
            },
          ),
        ),
        if (promotionError != null || promotionState.issue.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            promotionError ?? promotionState.issue,
            style: const TextStyle(color: archiveAccent, fontSize: 12),
          ),
          TextButton(
            onPressed: promotionBusy ? null : _loadPromotion,
            child: const Text('Retry'),
          ),
        ],
        if (selecting)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      tristate: true,
                      activeColor: archiveAccent,
                      value: selectedVisible == 0
                          ? false
                          : selectedVisible == available.length
                          ? true
                          : null,
                      onChanged: !ready || available.isEmpty
                          ? null
                          : (_) => setState(() {
                              if (selectedVisible == available.length) {
                                selectedIds.removeAll(
                                  available.map((student) => student.studentId),
                                );
                              } else {
                                selectedIds.addAll(
                                  available.map((student) => student.studentId),
                                );
                              }
                            }),
                    ),
                    const Text(
                      'Select all shown',
                      style: TextStyle(color: archiveBrown, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  '${selectedIds.length} selected',
                  style: const TextStyle(color: archiveMuted, fontSize: 12),
                ),
                ElevatedButton.icon(
                  onPressed:
                      ready &&
                          selectedIds.isNotEmpty &&
                          selectedIds.length <= 200
                      ? _promoteSelected
                      : null,
                  style: _unarchiveButtonStyle(),
                  icon: const Icon(Icons.school_rounded, size: 18),
                  label: Text(
                    promoting
                        ? 'Promoting...'
                        : reviewing
                        ? 'Preparing...'
                        : 'Promote (${selectedIds.length})',
                  ),
                ),
                if (selectedIds.length > 200)
                  const Text(
                    'Select up to 200 students per promotion.',
                    style: TextStyle(color: archiveAccent, fontSize: 12),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
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

  Future<void> _unarchiveSelectedYear() async {
    final year = selectedSchoolYear;
    if (year == null || unarchiving || selecting || promotionBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Unarchive School Year $year?',
          style: const TextStyle(
            color: archiveBrown,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'This year will appear again in the Dashboard’s school year list. '
          'Choose it and press Set School Year to make it current.',
          style: TextStyle(color: archiveMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: archiveAccent),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: _unarchiveButtonStyle(),
            child: const Text('Unarchive Year'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || unarchiving) return;

    setState(() => unarchiving = true);
    try {
      await widget.archiveService.unarchiveSchoolYear(year);
      if (!mounted) return;
      setState(() {
        schoolYears.remove(year);
        selectedSchoolYear = schoolYears.isEmpty ? null : schoolYears.first;
      });
      searchController.clear();
      await _loadPromotion();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'School Year $year unarchived. It is now available in the Dashboard.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
    } finally {
      if (mounted) setState(() => unarchiving = false);
    }
  }

  ButtonStyle _unarchiveButtonStyle() => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFA56B2F),
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
  );

  Widget _schoolYearControls() {
    final dropdown = DropdownButtonFormField<String>(
      key: ValueKey(selectedSchoolYear),
      initialValue: selectedSchoolYear,
      isExpanded: true,
      decoration: _inputDecoration(),
      items: schoolYears
          .map(
            (year) => DropdownMenuItem<String>(value: year, child: Text(year)),
          )
          .toList(),
      onChanged: unarchiving || promotionBusy
          ? null
          : (value) {
              if (value != null) {
                setState(() {
                  selectedSchoolYear = value;
                  selectedIds.clear();
                  selecting = false;
                  promotionState = const PromotionState();
                });
                _loadPromotion();
              }
            },
    );
    final button = ElevatedButton.icon(
      onPressed: unarchiving || selecting || promotionBusy
          ? null
          : _unarchiveSelectedYear,
      style: _unarchiveButtonStyle(),
      icon: unarchiving
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: archiveAccent,
              ),
            )
          : const Icon(Icons.unarchive_rounded, size: 18),
      label: Text(
        unarchiving ? 'Unarchiving...' : 'Unarchive Year',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [dropdown, const SizedBox(height: 10), button],
          );
        }
        return Row(
          children: [
            Expanded(child: dropdown),
            const SizedBox(width: 10),
            button,
          ],
        );
      },
    );
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

            _schoolYearControls(),

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
            if (widget.promotionService != null) _promotionControls(),
          ],

          if (schoolYears.isEmpty)
            _emptyState(
              icon: Icons.archive_outlined,
              title: 'No archived school years',
              message: 'Unarchived years are available on the Dashboard.',
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
    final candidate = promotionState.candidates[student.studentId];
    final selected = selectedIds.contains(student.studentId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFBF4EB) : const Color(0xFFFCFAF7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: selected ? archiveAccent : archiveBorder),
      ),
      child: InkWell(
        onTap: () {
          if (selecting) {
            _toggleStudent(student.studentId);
          } else {
            _showStudentSummary(student);
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (selecting)
                    Checkbox(
                      value: selected,
                      activeColor: archiveAccent,
                      semanticLabel: 'Select ${student.studentName}',
                      onChanged:
                          promotionBusy ||
                              promotionError != null ||
                              candidate?.eligible != true
                          ? null
                          : (_) => _toggleStudent(student.studentId),
                    )
                  else
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

                  IconButton(
                    onPressed: () => _showStudentSummary(student),
                    tooltip: 'View ${student.studentName} summary',
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: archiveMuted,
                    ),
                  ),
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
              if (candidate?.enrolled == true) ...[
                const Divider(color: archiveBorder),
                Text(
                  '✓ Enrolled in ${promotionState.activeYear} · ${candidate!.grade}',
                  style: const TextStyle(
                    color: Color(0xFF527044),
                    fontSize: 12,
                  ),
                ),
              ] else if (candidate != null && candidate.reason.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  candidate.reason,
                  style: const TextStyle(color: archiveMuted, fontSize: 12),
                ),
              ],
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
