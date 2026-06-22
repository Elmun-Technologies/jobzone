/// A language requirement on a job: a language [code] (`en`/`ru`/`uz`/…) and a
/// CEFR [level] (`a1`…`c2`) or `native`. Stored in `jobs.languages` jsonb.
class JobLanguage {
  const JobLanguage({required this.code, required this.level});

  final String code;
  final String level;

  factory JobLanguage.fromMap(Map<String, dynamic> m) => JobLanguage(
    code: (m['code'] ?? '') as String,
    level: (m['level'] ?? '') as String,
  );

  Map<String, dynamic> toMap() => {'code': code, 'level': level};

  JobLanguage copyWith({String? code, String? level}) =>
      JobLanguage(code: code ?? this.code, level: level ?? this.level);
}
