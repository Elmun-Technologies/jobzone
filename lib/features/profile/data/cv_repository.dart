import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/enums/enums.dart';
import '../domain/cv_models.dart';
import 'offline_profile.dart';

/// CRUD for every editable CV section. Backed by Supabase when configured;
/// otherwise an in-memory store seeded with sample data so the edit flows are
/// fully demoable offline (mirrors the pattern in `ApplicationsRepository`).
///
/// All write paths are owner-scoped server-side by RLS (`auth.uid()`); the
/// repository only stamps `profile_id` onto inserts.
class CvRepository {
  CvRepository(this._ref);

  final Ref _ref;

  bool get _online => Env.hasSupabase;
  String? get _uid => _ref.read(supabaseClientProvider).auth.currentUser?.id;

  // --- Experiences ---------------------------------------------------------
  Future<List<Experience>> experiences() async {
    if (!_online) return List.unmodifiable(_offline.experiences);
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('experiences')
        .select()
        .order('start_date', ascending: false);
    return (rows as List)
        .map((e) => Experience.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExperience(Experience e) =>
      _save('experiences', e.id, e.toMap(), () => _offline.upsertExperience(e));

  Future<void> deleteExperience(String id) => _delete(
    'experiences',
    id,
    () => _offline.experiences.removeWhere((e) => e.id == id),
  );

  // --- Educations ----------------------------------------------------------
  Future<List<Education>> educations() async {
    if (!_online) return List.unmodifiable(_offline.educations);
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('educations')
        .select()
        .order('start_date', ascending: false);
    return (rows as List)
        .map((e) => Education.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveEducation(Education e) =>
      _save('educations', e.id, e.toMap(), () => _offline.upsertEducation(e));

  Future<void> deleteEducation(String id) => _delete(
    'educations',
    id,
    () => _offline.educations.removeWhere((e) => e.id == id),
  );

  // --- Projects ------------------------------------------------------------
  Future<List<Project>> projects() async {
    if (!_online) return List.unmodifiable(_offline.projects);
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('projects')
        .select()
        .order('start_date', ascending: false);
    return (rows as List)
        .map((e) => Project.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveProject(Project e) =>
      _save('projects', e.id, e.toMap(), () => _offline.upsertProject(e));

  Future<void> deleteProject(String id) => _delete(
    'projects',
    id,
    () => _offline.projects.removeWhere((e) => e.id == id),
  );

  // --- Certifications ------------------------------------------------------
  Future<List<Certification>> certifications() async {
    if (!_online) return List.unmodifiable(_offline.certifications);
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('certifications')
        .select()
        .order('issued_date', ascending: false);
    return (rows as List)
        .map((e) => Certification.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCertification(Certification e) => _save(
    'certifications',
    e.id,
    e.toMap(),
    () => _offline.upsertCertification(e),
  );

  Future<void> deleteCertification(String id) => _delete(
    'certifications',
    id,
    () => _offline.certifications.removeWhere((e) => e.id == id),
  );

  // --- Volunteer -----------------------------------------------------------
  Future<List<Volunteer>> volunteer() async {
    if (!_online) return List.unmodifiable(_offline.volunteer);
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('volunteer_experiences')
        .select()
        .order('start_date', ascending: false);
    return (rows as List)
        .map((e) => Volunteer.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveVolunteer(Volunteer e) => _save(
    'volunteer_experiences',
    e.id,
    e.toMap(),
    () => _offline.upsertVolunteer(e),
  );

  Future<void> deleteVolunteer(String id) => _delete(
    'volunteer_experiences',
    id,
    () => _offline.volunteer.removeWhere((e) => e.id == id),
  );

  // --- Awards --------------------------------------------------------------
  Future<List<Award>> awards() async {
    if (!_online) return List.unmodifiable(_offline.awards);
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('awards')
        .select()
        .order('date', ascending: false);
    return (rows as List)
        .map((e) => Award.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAward(Award e) =>
      _save('awards', e.id, e.toMap(), () => _offline.upsertAward(e));

  Future<void> deleteAward(String id) => _delete(
    'awards',
    id,
    () => _offline.awards.removeWhere((e) => e.id == id),
  );

  // --- About (profiles row) ------------------------------------------------
  Future<void> saveAbout({
    String? fullName,
    String? headline,
    String? bio,
  }) async {
    if (!_online) {
      offlineProfile
        ..fullName = fullName
        ..headline = headline
        ..bio = bio;
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    await _ref
        .read(supabaseClientProvider)
        .from('profiles')
        .update({'full_name': fullName, 'headline': headline, 'bio': bio})
        .eq('id', uid);
  }

  /// Personal Information screen — name + contact basics on the profile row.
  /// [avatarBytes], when set, is uploaded to the `avatars` bucket first and
  /// `avatar_url` is updated alongside the other fields in the same write.
  Future<void> savePersonalInfo({
    String? fullName,
    String? phone,
    String? city,
    String? country,
    Uint8List? avatarBytes,
  }) async {
    if (!_online) {
      offlineProfile
        ..fullName = fullName
        ..phone = phone
        ..city = city
        ..country = country;
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    final client = _ref.read(supabaseClientProvider);
    String? avatarUrl;
    if (avatarBytes != null) {
      final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client.storage
          .from('avatars')
          .uploadBinary(
            path,
            avatarBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      avatarUrl = client.storage.from('avatars').getPublicUrl(path);
    }
    await client
        .from('profiles')
        .update({
          'full_name': fullName,
          'phone': phone,
          'city': city,
          'country': country,
          'avatar_url': ?avatarUrl,
        })
        .eq('id', uid);
  }

  Future<void> setOpenToWork(bool value) async {
    if (!_online) {
      offlineProfile.isOpenToWork = value;
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    await _ref
        .read(supabaseClientProvider)
        .from('profiles')
        .update({'is_open_to_work': value})
        .eq('id', uid);
  }

  /// Job Seeking Status screen — status + open-to-work flag.
  Future<void> setSeekingStatus(
    SeekingStatus status, {
    required bool openToWork,
  }) async {
    if (!_online) {
      offlineProfile
        ..seekingStatus = status
        ..isOpenToWork = openToWork;
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    await _ref
        .read(supabaseClientProvider)
        .from('profiles')
        .update({
          'seeking_status_id': _seekingStatusId(status),
          'is_open_to_work': openToWork,
        })
        .eq('id', uid);
  }

  // Maps to the smallint ids seeded in `seeking_statuses` (migration 0001).
  int _seekingStatusId(SeekingStatus s) => switch (s) {
    SeekingStatus.activelyLooking => 1,
    SeekingStatus.openToOffers => 2,
    SeekingStatus.notLooking => 3,
  };

  // --- Contact info --------------------------------------------------------
  Future<ContactInfo> contactInfo() async {
    if (!_online) return _offline.contact;
    final uid = _uid;
    if (uid == null) return const ContactInfo();
    final row = await _ref
        .read(supabaseClientProvider)
        .from('contact_info')
        .select()
        .eq('profile_id', uid)
        .maybeSingle();
    return row == null ? const ContactInfo() : ContactInfo.fromMap(row);
  }

  Future<void> saveContactInfo(ContactInfo info) async {
    if (!_online) {
      _offline.contact = info;
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    await _ref.read(supabaseClientProvider).from('contact_info').upsert({
      'profile_id': uid,
      ...info.toMap(),
    });
  }

  // --- Skills --------------------------------------------------------------
  Future<List<String>> skills() async {
    if (!_online) return List.unmodifiable(_offline.skills);
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('profile_skills')
        .select('skills(name)')
        .eq('profile_id', uid);
    return (rows as List)
        .map((e) {
          final s = (e as Map)['skills'];
          return s is Map ? (s['name'] as String? ?? '') : '';
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Replaces the user's skill set: ensures each name exists in `skills`,
  /// then rewrites the `profile_skills` join.
  Future<void> setSkills(List<String> names) async {
    final cleaned = names
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    if (!_online) {
      _offline.skills
        ..clear()
        ..addAll(cleaned);
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    final client = _ref.read(supabaseClientProvider);
    final ids = <String>[];
    for (final name in cleaned) {
      final row = await client
          .from('skills')
          .upsert({'name': name}, onConflict: 'name')
          .select('id')
          .single();
      ids.add(row['id'] as String);
    }
    await client.from('profile_skills').delete().eq('profile_id', uid);
    if (ids.isNotEmpty) {
      await client.from('profile_skills').insert([
        for (final id in ids) {'profile_id': uid, 'skill_id': id},
      ]);
    }
  }

  // --- Resumes -------------------------------------------------------------
  Future<List<Resume>> resumes() async {
    if (!_online) return List.unmodifiable(_offline.resumes);
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('resumes')
        .select()
        .eq('profile_id', uid)
        .order('uploaded_at', ascending: false);
    return (rows as List)
        .map((e) => Resume.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Uploads [bytes] to the private `resumes` bucket, records a row, and returns
  /// the new resume id (used e.g. to attach a CV to a job application).
  Future<String?> addResume({
    required String title,
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/pdf',
  }) async {
    if (!_online) {
      final resume = Resume(
        id: 'r${_offline.seq++}',
        title: title,
        filePath: fileName,
        fileSize: bytes.length,
        mimeType: mimeType,
        isDefault: _offline.resumes.isEmpty,
        uploadedAt: DateTime.now(),
      );
      _offline.resumes.insert(0, resume);
      return resume.id;
    }
    final uid = _uid;
    if (uid == null) return null;
    final client = _ref.read(supabaseClientProvider);
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await client.storage
        .from('resumes')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
        );
    final existing = await client
        .from('resumes')
        .select('id')
        .eq('profile_id', uid)
        .limit(1);
    final inserted = await client
        .from('resumes')
        .insert({
          'profile_id': uid,
          'title': title,
          'file_path': path,
          'file_size': bytes.length,
          'mime_type': mimeType,
          'is_default': (existing as List).isEmpty,
        })
        .select('id')
        .single();
    return inserted['id'] as String?;
  }

  /// Deletes a resume row, its uploaded file, and — if it was the default —
  /// promotes the next most recent remaining resume so the profile always
  /// has a default when one exists (the applications flow attaches CVs by
  /// looking up the default).
  Future<void> deleteResume(String id) async {
    if (!_online) {
      final wasDefault = _offline.resumes.any((r) => r.id == id && r.isDefault);
      _offline.resumes.removeWhere((e) => e.id == id);
      if (wasDefault && _offline.resumes.isNotEmpty) {
        final first = _offline.resumes.first;
        _offline.resumes[0] = Resume(
          id: first.id,
          title: first.title,
          filePath: first.filePath,
          fileSize: first.fileSize,
          mimeType: first.mimeType,
          isDefault: true,
          uploadedAt: first.uploadedAt,
        );
      }
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    final client = _ref.read(supabaseClientProvider);
    final row = await client
        .from('resumes')
        .select('file_path, is_default')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return;
    final path = row['file_path'] as String?;
    if (path != null && path.isNotEmpty) {
      await client.storage.from('resumes').remove([path]);
    }
    await client.from('resumes').delete().eq('id', id);
    if (row['is_default'] == true) {
      final remaining = await client
          .from('resumes')
          .select('id')
          .eq('profile_id', uid)
          .order('uploaded_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final nextId = remaining?['id'] as String?;
      if (nextId != null) {
        await client
            .from('resumes')
            .update({'is_default': true})
            .eq('id', nextId);
      }
    }
  }

  Future<void> setDefaultResume(String id) async {
    if (!_online) {
      _offline.resumes.setAll(0, [
        for (final r in _offline.resumes)
          Resume(
            id: r.id,
            title: r.title,
            filePath: r.filePath,
            fileSize: r.fileSize,
            mimeType: r.mimeType,
            isDefault: r.id == id,
            uploadedAt: r.uploadedAt,
          ),
      ]);
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    final client = _ref.read(supabaseClientProvider);
    await client
        .from('resumes')
        .update({'is_default': false})
        .eq('profile_id', uid);
    await client.from('resumes').update({'is_default': true}).eq('id', id);
  }

  // --- Shared write helpers ------------------------------------------------
  Future<void> _save(
    String table,
    String? id,
    Map<String, dynamic> values,
    void Function() offline,
  ) async {
    if (!_online) {
      offline();
      return;
    }
    final uid = _uid;
    if (uid == null) return;
    final client = _ref.read(supabaseClientProvider);
    if (id == null) {
      await client.from(table).insert({'profile_id': uid, ...values});
    } else {
      await client.from(table).update(values).eq('id', id);
    }
  }

  Future<void> _delete(String table, String id, void Function() offline) async {
    if (!_online) {
      offline();
      return;
    }
    await _ref.read(supabaseClientProvider).from(table).delete().eq('id', id);
  }
}

final cvRepositoryProvider = Provider<CvRepository>((ref) => CvRepository(ref));

/// In-memory store backing offline mode. Seeded once with sample data so the
/// edit screens render meaningfully without a backend.
class _OfflineCvStore {
  int seq = 100;

  final experiences = <Experience>[
    Experience(
      id: 'e1',
      title: 'Senior Flutter Engineer',
      companyName: 'Acme',
      employmentType: 'full_time',
      location: 'Tashkent',
      workingModel: 'hybrid',
      startDate: DateTime(2022),
      isCurrent: true,
      description: 'Lead the mobile team building cross-platform apps.',
    ),
    Experience(
      id: 'e2',
      title: 'Mobile Developer',
      companyName: 'Nimbus',
      startDate: DateTime(2019),
      endDate: DateTime(2022),
    ),
  ];

  final educations = <Education>[
    Education(
      id: 'd1',
      school: 'TUIT',
      degree: 'BSc Computer Science',
      field: 'Software Engineering',
      startDate: DateTime(2015),
      endDate: DateTime(2019),
    ),
  ];

  final projects = <Project>[
    Project(
      id: 'p1',
      name: 'Yolla',
      role: 'Lead Developer',
      url: 'https://github.com/example/jobzone',
      startDate: DateTime(2024),
      description: 'Cross-platform job finder built with Flutter and Supabase.',
    ),
  ];

  final certifications = <Certification>[
    Certification(
      id: 'c1',
      name: 'Google Associate Android Developer',
      issuer: 'Google',
      issuedDate: DateTime(2021, 6),
    ),
  ];

  final volunteer = <Volunteer>[
    Volunteer(
      id: 'v1',
      organization: 'Code for Tashkent',
      role: 'Mentor',
      cause: 'Education',
      startDate: DateTime(2020),
    ),
  ];

  final awards = <Award>[
    Award(
      id: 'a1',
      title: 'Hackathon Winner',
      issuer: 'TechWeek',
      date: DateTime(2023, 9),
    ),
  ];

  final skills = <String>['Dart', 'Flutter', 'Riverpod', 'Supabase', 'Git'];
  ContactInfo contact = const ContactInfo(
    website: 'https://aziz.dev',
    linkedin: 'aziz-karimov',
    github: 'azizk',
    telegram: '@azizk',
  );
  final resumes = <Resume>[
    Resume(
      id: 'res1',
      title: 'Aziz Karimov — Resume',
      filePath: 'resume.pdf',
      fileSize: 248000,
      mimeType: 'application/pdf',
      isDefault: true,
      uploadedAt: DateTime(2024, 3, 12),
    ),
  ];

  void upsertExperience(Experience e) => _upsert(
    experiences,
    e,
    e.id,
    (id) => Experience(
      id: id,
      title: e.title,
      companyName: e.companyName,
      employmentType: e.employmentType,
      location: e.location,
      workingModel: e.workingModel,
      startDate: e.startDate,
      endDate: e.endDate,
      isCurrent: e.isCurrent,
      description: e.description,
    ),
  );

  void upsertEducation(Education e) => _upsert(
    educations,
    e,
    e.id,
    (id) => Education(
      id: id,
      school: e.school,
      degree: e.degree,
      field: e.field,
      startDate: e.startDate,
      endDate: e.endDate,
      grade: e.grade,
      description: e.description,
    ),
  );

  void upsertProject(Project e) => _upsert(
    projects,
    e,
    e.id,
    (id) => Project(
      id: id,
      name: e.name,
      role: e.role,
      url: e.url,
      startDate: e.startDate,
      endDate: e.endDate,
      description: e.description,
    ),
  );

  void upsertCertification(Certification e) => _upsert(
    certifications,
    e,
    e.id,
    (id) => Certification(
      id: id,
      name: e.name,
      issuer: e.issuer,
      credentialId: e.credentialId,
      credentialUrl: e.credentialUrl,
      issuedDate: e.issuedDate,
      expiryDate: e.expiryDate,
    ),
  );

  void upsertVolunteer(Volunteer e) => _upsert(
    volunteer,
    e,
    e.id,
    (id) => Volunteer(
      id: id,
      organization: e.organization,
      role: e.role,
      cause: e.cause,
      startDate: e.startDate,
      endDate: e.endDate,
      description: e.description,
    ),
  );

  void upsertAward(Award e) => _upsert(
    awards,
    e,
    e.id,
    (id) => Award(
      id: id,
      title: e.title,
      issuer: e.issuer,
      date: e.date,
      description: e.description,
    ),
  );

  void _upsert<T>(
    List<T> list,
    T value,
    String? id,
    T Function(String id) withId,
  ) {
    if (id == null) {
      list.insert(0, withId('mem${seq++}'));
    } else {
      final i = list.indexWhere((e) => (e as dynamic).id == id);
      if (i != -1) list[i] = value;
    }
  }
}

final _offline = _OfflineCvStore();
