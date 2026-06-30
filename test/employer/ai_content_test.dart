import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/employer/data/ai_content_repository.dart';

void main() {
  // No Supabase env in tests → the repository serves its local stub.
  group('AiContentRepository (offline stub)', () {
    AiContentRepository repo() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c.read(aiContentRepositoryProvider);
    }

    test('draftJob fills every section from title + skills', () async {
      final d = await repo().draftJob(
        title: 'Barista',
        skills: const ['Coffee', 'POS'],
      );
      expect(d.description, contains('Barista'));
      expect(d.requirements, contains('Coffee'));
      expect(d.responsibilities, isNotEmpty);
      expect(d.benefits, isNotEmpty);
    });

    test('matchJob scores skill overlap offline (case-insensitive)', () async {
      final m = await repo().matchJob(
        title: 'Barista',
        jobSkills: const ['Coffee', 'POS', 'Teamwork'],
        mySkills: const ['coffee', 'teamwork'],
      );
      expect(m.score, 67); // 2 of 3 required skills
      expect(m.strengths, containsAll(<String>['Coffee', 'Teamwork']));
      expect(m.gaps, contains('POS'));
    });

    test('rankBySkills orders applicants by skill overlap', () {
      final ranked = repo().rankBySkills(
        jobSkills: const ['flutter', 'dart'],
        applicants: const [
          (id: 'a', skills: ['flutter', 'dart']),
          (id: 'b', skills: ['java']),
          (id: 'c', skills: ['flutter']),
        ],
      );
      expect(ranked.first.id, 'a');
      expect(ranked.last.id, 'b');
    });
  });
}
