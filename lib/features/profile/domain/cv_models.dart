// Editable CV domain models. Unlike the read-only [UserProfile] aggregate,
// these carry primary keys and the full column set so they can round-trip
// through the edit forms and `CvRepository` (Supabase upsert / delete).
//
// Dates map to the Postgres `date` columns: parsed from ISO `yyyy-MM-dd`
// strings and serialized the same way via [isoDate].

String? isoDate(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

DateTime? parseDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse('$v');
}

/// Work experience entry (`public.experiences`).
class Experience {
  const Experience({
    this.id,
    required this.title,
    this.companyName,
    this.employmentType,
    this.location,
    this.workingModel,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description,
  });

  final String? id;
  final String title;
  final String? companyName;
  final String? employmentType;
  final String? location;
  final String? workingModel;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? description;

  factory Experience.fromMap(Map<String, dynamic> m) => Experience(
    id: m['id'] as String?,
    title: (m['title'] ?? '') as String,
    companyName: m['company_name'] as String?,
    employmentType: m['employment_type'] as String?,
    location: m['location'] as String?,
    workingModel: m['working_model'] as String?,
    startDate: parseDate(m['start_date']),
    endDate: parseDate(m['end_date']),
    isCurrent: (m['is_current'] ?? false) as bool,
    description: m['description'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'company_name': companyName,
    'employment_type': employmentType,
    'location': location,
    'working_model': workingModel,
    'start_date': isoDate(startDate),
    'end_date': isCurrent ? null : isoDate(endDate),
    'is_current': isCurrent,
    'description': description,
  };
}

/// Education entry (`public.educations`).
class Education {
  const Education({
    this.id,
    required this.school,
    this.degree,
    this.field,
    this.startDate,
    this.endDate,
    this.grade,
    this.description,
  });

  final String? id;
  final String school;
  final String? degree;
  final String? field;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? grade;
  final String? description;

  factory Education.fromMap(Map<String, dynamic> m) => Education(
    id: m['id'] as String?,
    school: (m['school'] ?? '') as String,
    degree: m['degree'] as String?,
    field: m['field'] as String?,
    startDate: parseDate(m['start_date']),
    endDate: parseDate(m['end_date']),
    grade: m['grade'] as String?,
    description: m['description'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'school': school,
    'degree': degree,
    'field': field,
    'start_date': isoDate(startDate),
    'end_date': isoDate(endDate),
    'grade': grade,
    'description': description,
  };
}

/// Project entry (`public.projects`).
class Project {
  const Project({
    this.id,
    required this.name,
    this.role,
    this.url,
    this.startDate,
    this.endDate,
    this.description,
  });

  final String? id;
  final String name;
  final String? role;
  final String? url;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;

  factory Project.fromMap(Map<String, dynamic> m) => Project(
    id: m['id'] as String?,
    name: (m['name'] ?? '') as String,
    role: m['role'] as String?,
    url: m['url'] as String?,
    startDate: parseDate(m['start_date']),
    endDate: parseDate(m['end_date']),
    description: m['description'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'role': role,
    'url': url,
    'start_date': isoDate(startDate),
    'end_date': isoDate(endDate),
    'description': description,
  };
}

/// Certification or license (`public.certifications`).
class Certification {
  const Certification({
    this.id,
    required this.name,
    this.issuer,
    this.credentialId,
    this.credentialUrl,
    this.issuedDate,
    this.expiryDate,
  });

  final String? id;
  final String name;
  final String? issuer;
  final String? credentialId;
  final String? credentialUrl;
  final DateTime? issuedDate;
  final DateTime? expiryDate;

  factory Certification.fromMap(Map<String, dynamic> m) => Certification(
    id: m['id'] as String?,
    name: (m['name'] ?? '') as String,
    issuer: m['issuer'] as String?,
    credentialId: m['credential_id'] as String?,
    credentialUrl: m['credential_url'] as String?,
    issuedDate: parseDate(m['issued_date']),
    expiryDate: parseDate(m['expiry_date']),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'issuer': issuer,
    'credential_id': credentialId,
    'credential_url': credentialUrl,
    'issued_date': isoDate(issuedDate),
    'expiry_date': isoDate(expiryDate),
  };
}

/// Volunteer experience (`public.volunteer_experiences`).
class Volunteer {
  const Volunteer({
    this.id,
    required this.organization,
    this.role,
    this.cause,
    this.startDate,
    this.endDate,
    this.description,
  });

  final String? id;
  final String organization;
  final String? role;
  final String? cause;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;

  factory Volunteer.fromMap(Map<String, dynamic> m) => Volunteer(
    id: m['id'] as String?,
    organization: (m['organization'] ?? '') as String,
    role: m['role'] as String?,
    cause: m['cause'] as String?,
    startDate: parseDate(m['start_date']),
    endDate: parseDate(m['end_date']),
    description: m['description'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'organization': organization,
    'role': role,
    'cause': cause,
    'start_date': isoDate(startDate),
    'end_date': isoDate(endDate),
    'description': description,
  };
}

/// Award or achievement (`public.awards`).
class Award {
  const Award({
    this.id,
    required this.title,
    this.issuer,
    this.date,
    this.description,
  });

  final String? id;
  final String title;
  final String? issuer;
  final DateTime? date;
  final String? description;

  factory Award.fromMap(Map<String, dynamic> m) => Award(
    id: m['id'] as String?,
    title: (m['title'] ?? '') as String,
    issuer: m['issuer'] as String?,
    date: parseDate(m['date']),
    description: m['description'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'issuer': issuer,
    'date': isoDate(date),
    'description': description,
  };
}

/// Social / contact links (`public.contact_info`).
class ContactInfo {
  const ContactInfo({
    this.website,
    this.linkedin,
    this.github,
    this.telegram,
    this.address,
  });

  final String? website;
  final String? linkedin;
  final String? github;
  final String? telegram;
  final String? address;

  factory ContactInfo.fromMap(Map<String, dynamic> m) => ContactInfo(
    website: m['website'] as String?,
    linkedin: m['linkedin'] as String?,
    github: m['github'] as String?,
    telegram: m['telegram'] as String?,
    address: m['address'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'website': website,
    'linkedin': linkedin,
    'github': github,
    'telegram': telegram,
    'address': address,
  };
}

/// Uploaded resume / CV file (`public.resumes`).
class Resume {
  const Resume({
    this.id,
    required this.title,
    required this.filePath,
    this.fileSize,
    this.mimeType,
    this.isDefault = false,
    this.uploadedAt,
  });

  final String? id;
  final String title;
  final String filePath;
  final int? fileSize;
  final String? mimeType;
  final bool isDefault;
  final DateTime? uploadedAt;

  factory Resume.fromMap(Map<String, dynamic> m) => Resume(
    id: m['id'] as String?,
    title: (m['title'] ?? '') as String,
    filePath: (m['file_path'] ?? '') as String,
    fileSize: (m['file_size'] as num?)?.toInt(),
    mimeType: m['mime_type'] as String?,
    isDefault: (m['is_default'] ?? false) as bool,
    uploadedAt: parseDate(m['uploaded_at']),
  );

  /// Human-readable size, e.g. `1.4 MB`.
  String? get sizeText {
    final s = fileSize;
    if (s == null) return null;
    if (s < 1024) return '$s B';
    if (s < 1024 * 1024) return '${(s / 1024).toStringAsFixed(0)} KB';
    return '${(s / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
