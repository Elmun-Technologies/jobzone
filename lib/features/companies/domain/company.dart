/// A company profile (`public.companies`) shown on the Company Details screen.
class Company {
  const Company({
    required this.id,
    required this.name,
    this.logoUrl,
    this.coverUrl,
    this.about,
    this.industry,
    this.size,
    this.foundedYear,
    this.website,
    this.headquarters,
    this.introVideoUrl,
    this.isVerified = false,
    this.verifiedAt,
    this.verificationMethod,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? coverUrl;
  final String? about;
  final String? industry;
  final String? size;
  final int? foundedYear;
  final String? website;
  final String? headquarters;
  final String? introVideoUrl;
  final bool isVerified;

  /// Verification audit: when granted and how (`legal_entity`/`licensed_agency`).
  final DateTime? verifiedAt;
  final String? verificationMethod;

  bool get hasIntroVideo => introVideoUrl != null && introVideoUrl!.isNotEmpty;

  Company copyWith({
    String? name,
    String? logoUrl,
    String? coverUrl,
    String? about,
    String? industry,
    String? size,
    int? foundedYear,
    String? website,
    String? headquarters,
    String? introVideoUrl,
    bool? isVerified,
    DateTime? verifiedAt,
    String? verificationMethod,
  }) => Company(
    id: id,
    name: name ?? this.name,
    logoUrl: logoUrl ?? this.logoUrl,
    coverUrl: coverUrl ?? this.coverUrl,
    about: about ?? this.about,
    industry: industry ?? this.industry,
    size: size ?? this.size,
    foundedYear: foundedYear ?? this.foundedYear,
    website: website ?? this.website,
    headquarters: headquarters ?? this.headquarters,
    introVideoUrl: introVideoUrl ?? this.introVideoUrl,
    isVerified: isVerified ?? this.isVerified,
    verifiedAt: verifiedAt ?? this.verifiedAt,
    verificationMethod: verificationMethod ?? this.verificationMethod,
  );

  factory Company.fromMap(Map<String, dynamic> m) => Company(
    id: (m['id'] ?? '') as String,
    name: (m['name'] ?? '') as String,
    logoUrl: m['logo_url'] as String?,
    coverUrl: m['cover_url'] as String?,
    about: m['about'] as String?,
    industry: m['industry'] as String?,
    size: m['size'] as String?,
    foundedYear: (m['founded_year'] as num?)?.toInt(),
    website: m['website'] as String?,
    headquarters: m['headquarters'] as String?,
    introVideoUrl: m['intro_video_url'] as String?,
    isVerified: (m['is_verified'] ?? false) as bool,
    verifiedAt: m['verified_at'] != null
        ? DateTime.tryParse('${m['verified_at']}')
        : null,
    verificationMethod: m['verification_method'] as String?,
  );
}

/// A team member / recruiter (`public.company_people`).
class CompanyPerson {
  const CompanyPerson({
    required this.id,
    required this.name,
    this.title,
    this.avatarUrl,
    this.isRecruiter = false,
  });

  final String id;
  final String name;
  final String? title;
  final String? avatarUrl;
  final bool isRecruiter;

  factory CompanyPerson.fromMap(Map<String, dynamic> m) => CompanyPerson(
    id: (m['id'] ?? '') as String,
    name: (m['name'] ?? '') as String,
    title: m['title'] as String?,
    avatarUrl: m['avatar_url'] as String?,
    isRecruiter: (m['is_recruiter'] ?? false) as bool,
  );
}

/// A gallery item (`public.company_gallery`): image or video with a caption.
class GalleryItem {
  const GalleryItem({
    required this.id,
    required this.mediaUrl,
    this.mediaType = 'image',
    this.caption,
  });

  final String id;
  final String mediaUrl;
  final String mediaType;
  final String? caption;

  bool get isVideo => mediaType == 'video';

  factory GalleryItem.fromMap(Map<String, dynamic> m) => GalleryItem(
    id: (m['id'] ?? '') as String,
    mediaUrl: (m['media_url'] ?? '') as String,
    mediaType: (m['media_type'] ?? 'image') as String,
    caption: m['caption'] as String?,
  );
}
