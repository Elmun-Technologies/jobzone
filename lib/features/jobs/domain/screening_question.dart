/// A screening question authored on a job posting (stored in
/// `jobs.screening_questions`). Candidate answers are keyed by [id] in
/// `applications.answers`.
class ScreeningQuestion {
  const ScreeningQuestion({
    required this.id,
    required this.label,
    this.type = 'text', // 'text' | 'yesno' | 'number'
    this.required = false,
  });

  final String id;
  final String label;
  final String type;
  final bool required;

  ScreeningQuestion copyWith({String? label, String? type, bool? required}) =>
      ScreeningQuestion(
        id: id,
        label: label ?? this.label,
        type: type ?? this.type,
        required: required ?? this.required,
      );

  factory ScreeningQuestion.fromMap(Map<String, dynamic> m) =>
      ScreeningQuestion(
        id: (m['id'] ?? '') as String,
        label: (m['label'] ?? '') as String,
        type: (m['type'] ?? 'text') as String,
        required: (m['required'] ?? false) as bool,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'type': type,
    'required': required,
  };
}
