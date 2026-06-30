/// A screening question authored on a job posting (stored in
/// `jobs.screening_questions`). Candidate answers are keyed by [id] in
/// `applications.answers`.
class ScreeningQuestion {
  const ScreeningQuestion({
    required this.id,
    required this.label,
    this.type = 'text', // 'text' | 'yesno' | 'number' | 'multiple_choice'
    this.required = false,
    this.options = const [],
  });

  final String id;
  final String label;
  final String type;
  final bool required;

  /// Answer options for [type] == `'multiple_choice'`. Ignored for other types.
  final List<String> options;

  ScreeningQuestion copyWith({
    String? label,
    String? type,
    bool? required,
    List<String>? options,
  }) => ScreeningQuestion(
    id: id,
    label: label ?? this.label,
    type: type ?? this.type,
    required: required ?? this.required,
    options: options ?? this.options,
  );

  factory ScreeningQuestion.fromMap(Map<String, dynamic> m) =>
      ScreeningQuestion(
        id: (m['id'] ?? '') as String,
        label: (m['label'] ?? '') as String,
        type: (m['type'] ?? 'text') as String,
        required: (m['required'] ?? false) as bool,
        options: (m['options'] as List?)?.map((e) => '$e').toList() ?? const [],
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'type': type,
    'required': required,
    'options': options,
  };
}
