import 'package:cloud_functions/cloud_functions.dart';
import 'promotion_service.dart';

class FirebasePromotionService implements PromotionService {
  FirebasePromotionService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;
  static final instance = FirebasePromotionService();
  final FirebaseFunctions _functions;

  @override
  Future<PromotionState> load(String sourceYear) async {
    final response = await _functions
        .httpsCallable('promoteArchivedStudents')
        .call({'operation': 'preview', 'sourceYear': sourceYear});
    final data = Map<String, dynamic>.from(response.data as Map);
    final candidates = <String, PromotionCandidate>{};
    for (final entry in data['candidates'] as List? ?? []) {
      final item = Map<String, dynamic>.from(entry as Map);
      final candidate = PromotionCandidate(
        id: item['id'] as String,
        grade: item['grade'] as String,
        nextGrade: item['nextGrade'] as String?,
        enrolled: item['enrolled'] == true,
        reason: item['reason'] as String? ?? '',
      );
      candidates[candidate.id] = candidate;
    }
    return PromotionState(
      activeYear: data['activeYear'] as String?,
      issue: data['issue'] as String? ?? '',
      candidates: candidates,
    );
  }

  @override
  Future<void> promote({
    required String sourceYear,
    required String targetYear,
    required List<PromotionCandidate> students,
  }) async {
    await _functions.httpsCallable('promoteArchivedStudents').call({
      'operation': 'promote',
      'sourceYear': sourceYear,
      'targetYear': targetYear,
      'students': students
          .map((student) => {'id': student.id, 'grade': student.grade})
          .toList(),
    });
  }
}
