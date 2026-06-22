import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';

/// Generated job-post text (the "AI Генерация" output).
class JobDraft {
  const JobDraft({
    this.description = '',
    this.responsibilities = '',
    this.requirements = '',
    this.benefits = '',
  });

  final String description;
  final String responsibilities;
  final String requirements;
  final String benefits;
}

/// AI assist for employers: drafts job-post text and ranks applicants by skill
/// match. Currently a rule-based **stub** behind an edge-function seam — live
/// calls the `generate-job-content` function; offline returns the same
/// templates. Swap in a real Claude call later without touching callers.
class AiContentRepository {
  AiContentRepository(this._ref);

  final Ref _ref;

  bool get _live => Env.hasSupabase;

  Future<JobDraft> draftJob({
    required String title,
    String? category,
    String? jobType,
    List<String> skills = const [],
  }) async {
    if (_live) {
      final res = await _ref
          .read(supabaseClientProvider)
          .functions
          .invoke(
            'generate-job-content',
            body: {
              'action': 'draft',
              'title': title,
              'category': category,
              'jobType': jobType,
              'skills': skills,
            },
          );
      final m = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
      return JobDraft(
        description: (m['description'] ?? '') as String,
        responsibilities: (m['responsibilities'] ?? '') as String,
        requirements: (m['requirements'] ?? '') as String,
        benefits: (m['benefits'] ?? '') as String,
      );
    }
    return _localDraft(title, skills);
  }

  JobDraft _localDraft(String title, List<String> skills) {
    final t = title.trim().isEmpty ? 'this role' : title.trim();
    final sk = skills.isEmpty ? 'the required skills' : skills.join(', ');
    return JobDraft(
      description:
          "We're hiring a $t. You'll join a growing team and make an "
          'immediate impact — a great opportunity to grow your career.',
      responsibilities:
          'Deliver high-quality work as a $t. Collaborate with the team. '
          'Use $sk day to day.',
      requirements:
          'Proven experience relevant to a $t. Skills: $sk. Reliable and a '
          'good communicator.',
      benefits: 'Competitive pay. Supportive team. Room to grow.',
    );
  }

  /// Skill-overlap (Jaccard) ranking, highest first. Rule-based stub.
  List<({String id, double score})> rankBySkills({
    required List<String> jobSkills,
    required List<({String id, List<String> skills})> applicants,
  }) {
    final js = jobSkills.map((s) => s.toLowerCase()).toSet();
    final ranked = [
      for (final a in applicants)
        (
          id: a.id,
          score: _overlap(js, a.skills.map((s) => s.toLowerCase()).toSet()),
        ),
    ]..sort((x, y) => y.score.compareTo(x.score));
    return ranked;
  }

  double _overlap(Set<String> a, Set<String> b) {
    final union = a.union(b).length;
    return union == 0 ? 0 : a.intersection(b).length / union;
  }
}

final aiContentRepositoryProvider = Provider<AiContentRepository>(
  (ref) => AiContentRepository(ref),
);
