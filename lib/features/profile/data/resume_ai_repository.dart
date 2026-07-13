import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';

/// One work-history entry parsed from a résumé.
class ParsedExperience {
  const ParsedExperience({
    required this.title,
    this.companyName,
    this.startYear,
    this.endYear,
    this.isCurrent = false,
    this.description,
  });

  final String title;
  final String? companyName;
  final int? startYear;
  final int? endYear;
  final bool isCurrent;
  final String? description;

  factory ParsedExperience.fromMap(Map<String, dynamic> m) => ParsedExperience(
    title: (m['title'] ?? '') as String,
    companyName: m['companyName'] as String?,
    startYear: (m['startYear'] as num?)?.toInt(),
    endYear: (m['endYear'] as num?)?.toInt(),
    isCurrent: (m['isCurrent'] ?? false) as bool,
    description: m['description'] as String?,
  );
}

/// One education entry parsed from a résumé.
class ParsedEducation {
  const ParsedEducation({
    required this.school,
    this.degree,
    this.field,
    this.startYear,
    this.endYear,
  });

  final String school;
  final String? degree;
  final String? field;
  final int? startYear;
  final int? endYear;

  factory ParsedEducation.fromMap(Map<String, dynamic> m) => ParsedEducation(
    school: (m['school'] ?? '') as String,
    degree: m['degree'] as String?,
    field: m['field'] as String?,
    startYear: (m['startYear'] as num?)?.toInt(),
    endYear: (m['endYear'] as num?)?.toInt(),
  );
}

/// The structured profile parsed from an uploaded CV.
class ParsedResume {
  const ParsedResume({
    this.fullName,
    this.headline,
    this.bio,
    this.skills = const [],
    this.experiences = const [],
    this.educations = const [],
  });

  final String? fullName;
  final String? headline;
  final String? bio;
  final List<String> skills;
  final List<ParsedExperience> experiences;
  final List<ParsedEducation> educations;

  bool get isEmpty =>
      (fullName == null || fullName!.trim().isEmpty) &&
      (headline == null || headline!.trim().isEmpty) &&
      (bio == null || bio!.trim().isEmpty) &&
      skills.isEmpty &&
      experiences.isEmpty &&
      educations.isEmpty;

  factory ParsedResume.fromMap(Map<String, dynamic> m) => ParsedResume(
    fullName: m['fullName'] as String?,
    headline: m['headline'] as String?,
    bio: m['bio'] as String?,
    skills: ((m['skills'] as List?) ?? const [])
        .map((e) => '$e'.trim())
        .where((e) => e.isNotEmpty)
        .toList(),
    experiences: ((m['experiences'] as List?) ?? const [])
        .map(
          (e) => ParsedExperience.fromMap((e as Map).cast<String, dynamic>()),
        )
        .where((e) => e.title.trim().isNotEmpty)
        .toList(),
    educations: ((m['educations'] as List?) ?? const [])
        .map((e) => ParsedEducation.fromMap((e as Map).cast<String, dynamic>()))
        .where((e) => e.school.trim().isNotEmpty)
        .toList(),
  );
}

/// Sends an uploaded CV to the `parse-resume` edge function and returns the
/// structured profile. Returns null when parsing isn't available (no AI key,
/// unsupported file type, provider error) so the caller falls back to manual
/// entry. Offline, returns a small demo parse so the flow is still explorable.
class ResumeAiRepository {
  ResumeAiRepository(this._ref);

  final Ref _ref;

  bool get _live => Env.hasSupabase;

  Future<ParsedResume?> parseResume({
    required Uint8List bytes,
    required String mimeType,
    String locale = 'uz',
  }) async {
    if (!_live) return _demoParsed;
    try {
      final res = await _ref
          .read(supabaseClientProvider)
          .functions
          .invoke(
            'parse-resume',
            body: {
              'fileBase64': base64Encode(bytes),
              'mimeType': mimeType,
              'locale': locale,
            },
          );
      final data = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
      if (data['available'] != true) return null;
      final profile = (data['profile'] as Map?)?.cast<String, dynamic>();
      if (profile == null) return null;
      final parsed = ParsedResume.fromMap(profile);
      return parsed.isEmpty ? null : parsed;
    } catch (_) {
      return null;
    }
  }
}

/// Offline demo so the résumé→autofill flow is explorable with no backend.
const _demoParsed = ParsedResume(
  headline: 'Haydovchi',
  bio:
      'Toifali haydovchilik guvohnomasiga ega, 5 yillik tajribali haydovchi. '
      'Mas’uliyatli va vaqtga rioya qiladi.',
  skills: ['Haydovchilik B/C', 'Yuk tashish', 'Xaritada yo‘l topish'],
  experiences: [
    ParsedExperience(
      title: 'Haydovchi',
      companyName: 'Express Logistics',
      startYear: 2020,
      isCurrent: true,
    ),
  ],
  educations: [
    ParsedEducation(school: 'Toshkent avtomobil kolleji', startYear: 2014),
  ],
);

final resumeAiRepositoryProvider = Provider<ResumeAiRepository>(
  (ref) => ResumeAiRepository(ref),
);
