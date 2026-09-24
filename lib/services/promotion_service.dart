class PromotionCandidate {
  final String id;
  final String grade;
  final String? nextGrade;
  final bool enrolled;
  final String reason;

  const PromotionCandidate({
    required this.id,
    required this.grade,
    required this.nextGrade,
    this.enrolled = false,
    this.reason = '',
  });

  bool get eligible => reason.isEmpty && !enrolled && nextGrade != null;
}

class PromotionState {
  final String? activeYear;
  final String issue;
  final Map<String, PromotionCandidate> candidates;

  const PromotionState({
    this.activeYear,
    this.issue = '',
    this.candidates = const {},
  });
}

abstract class PromotionService {
  Future<PromotionState> load(String sourceYear);
  Future<void> promote({
    required String sourceYear,
    required String targetYear,
    required List<PromotionCandidate> students,
  });
}
