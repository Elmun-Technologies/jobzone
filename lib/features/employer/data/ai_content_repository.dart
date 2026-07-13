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

/// How well a seeker fits a job — shown by the "Am I a good match?" action.
class JobMatch {
  const JobMatch({
    required this.score,
    this.summary = '',
    this.strengths = const [],
    this.gaps = const [],
  });

  /// 0–100 fit score.
  final int score;
  final String summary;
  final List<String> strengths; // job skills the seeker has
  final List<String> gaps; // job skills the seeker is missing
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
    String locale = 'uz',
  }) async {
    if (_live) {
      // Mirror matchJob: never let a missing/failed edge function (not deployed,
      // rate-limited, 500…) leave the "AI генерация" button dead. Fall back to
      // the same local templates so the employer always gets usable draft text.
      try {
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
                'locale': locale,
              },
            );
        final m = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
        final draft = JobDraft(
          description: (m['description'] ?? '') as String,
          responsibilities: (m['responsibilities'] ?? '') as String,
          requirements: (m['requirements'] ?? '') as String,
          benefits: (m['benefits'] ?? '') as String,
        );
        // An empty payload (misconfigured function) is as useless as a throw —
        // treat it the same and use the local templates instead.
        if (draft.description.trim().isEmpty &&
            draft.responsibilities.trim().isEmpty &&
            draft.requirements.trim().isEmpty &&
            draft.benefits.trim().isEmpty) {
          return _localDraft(title, skills, locale);
        }
        return draft;
      } catch (_) {
        return _localDraft(title, skills, locale);
      }
    }
    return _localDraft(title, skills, locale);
  }

  /// Offline draft templates. The live path localizes via the edge function;
  /// offline we branch on [locale] (uz default) so an employer never sees an
  /// English draft baked into a published, uz-first vacancy.
  JobDraft _localDraft(String title, List<String> skills, String locale) {
    final t = title.trim();
    switch (locale) {
      case 'ru':
        final role = t.isEmpty ? 'эта должность' : t;
        final sk = skills.isEmpty ? 'необходимые навыки' : skills.join(', ');
        return JobDraft(
          description:
              'Мы ищем сотрудника на позицию «$role». Вы присоединитесь к '
              'растущей команде и сразу начнёте приносить пользу — отличная '
              'возможность для карьерного роста.',
          responsibilities:
              'Качественно выполнять работу ($role). Взаимодействовать с '
              'командой. Использовать $sk в ежедневной работе.',
          requirements:
              'Опыт, соответствующий позиции «$role». Навыки: $sk. '
              'Ответственный, с хорошими коммуникативными навыками.',
          benefits:
              'Достойная оплата. Поддерживающая команда. Возможности для роста.',
        );
      case 'en':
        final role = t.isEmpty ? 'this role' : t;
        final sk = skills.isEmpty ? 'the required skills' : skills.join(', ');
        return JobDraft(
          description:
              "We're hiring a $role. You'll join a growing team and make an "
              'immediate impact — a great opportunity to grow your career.',
          responsibilities:
              'Deliver high-quality work as a $role. Collaborate with the '
              'team. Use $sk day to day.',
          requirements:
              'Proven experience relevant to a $role. Skills: $sk. Reliable '
              'and a good communicator.',
          benefits: 'Competitive pay. Supportive team. Room to grow.',
        );
      default: // uz — the product's first language
        final role = t.isEmpty ? 'bu lavozim' : t;
        final sk = skills.isEmpty ? 'kerakli koʻnikmalar' : skills.join(', ');
        return JobDraft(
          description:
              '$role lavozimiga xodim qidiryapmiz. Jamoamizga qoʻshilib, oʻz '
              'ishingizda darhol natija koʻrsatasiz — martabangizni oʻstirish '
              'uchun ajoyib imkoniyat.',
          responsibilities:
              '$role sifatida sifatli ish bajarish. Jamoa bilan hamkorlik '
              'qilish. Kundalik ishda $sk dan foydalanish.',
          requirements:
              '$role lavozimiga mos tajriba. Koʻnikmalar: $sk. Ishonchli va '
              'yaxshi muloqot qila oladigan.',
          benefits:
              'Munosib maosh. Qoʻllab-quvvatlovchi jamoa. Oʻsish imkoniyati.',
        );
    }
  }

  /// Scores how well a seeker fits a job. Live: the `match` action of the
  /// `generate-job-content` function (real Claude when ANTHROPIC_API_KEY is set,
  /// else a skill-overlap score). Offline: the same skill-overlap locally.
  Future<JobMatch> matchJob({
    required String title,
    List<String> jobSkills = const [],
    String? description,
    List<String> mySkills = const [],
    String? myHeadline,
    String locale = 'uz',
  }) async {
    if (_live) {
      try {
        final res = await _ref
            .read(supabaseClientProvider)
            .functions
            .invoke(
              'generate-job-content',
              body: {
                'action': 'match',
                'title': title,
                'jobSkills': jobSkills,
                'description': description,
                'mySkills': mySkills,
                'myHeadline': myHeadline,
                'locale': locale,
              },
            );
        final m = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
        return JobMatch(
          score:
              (m['score'] as num?)?.round() ??
              _localMatch(jobSkills, mySkills).score,
          summary: (m['summary'] ?? '') as String,
          strengths: ((m['strengths'] as List?) ?? const [])
              .map((e) => '$e')
              .toList(),
          gaps: ((m['gaps'] as List?) ?? const []).map((e) => '$e').toList(),
        );
      } catch (_) {
        return _localMatch(jobSkills, mySkills);
      }
    }
    return _localMatch(jobSkills, mySkills);
  }

  JobMatch _localMatch(List<String> jobSkills, List<String> mySkills) {
    final js = jobSkills
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    if (js.isEmpty) return const JobMatch(score: 0);
    final ms = mySkills.map((s) => s.toLowerCase().trim()).toSet();
    final strengths = [
      for (final s in jobSkills)
        if (ms.contains(s.toLowerCase().trim())) s,
    ];
    final gaps = [
      for (final s in jobSkills)
        if (!ms.contains(s.toLowerCase().trim())) s,
    ];
    final score = (strengths.length / js.length * 100).round();
    return JobMatch(score: score, strengths: strengths, gaps: gaps);
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
