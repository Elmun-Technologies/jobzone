/// Sort options offered on Explore / Search (mapped to Meilisearch
/// `sortableAttributes`).
enum SearchSort { newest, salaryHigh, salaryLow }

/// The user's current search criteria. Drives both the live Meilisearch query
/// and the offline mock filtering.
class SearchFilters {
  const SearchFilters({
    this.query = '',
    this.jobTypes = const {},
    this.experienceLevels = const {},
    this.workingModels = const {},
    this.schedulePatterns = const {},
    this.formalizations = const {},
    this.titles = const {},
    this.salaryMin,
    this.salaryMax,
    this.city,
    this.womenFriendly = false,
    this.nightShift = false,
    this.disabilityFriendly = false,
    this.sort = SearchSort.newest,
  });

  final String query;
  final Set<String> jobTypes;
  final Set<String> experienceLevels;
  final Set<String> workingModels;
  final Set<String> schedulePatterns;
  final Set<String> formalizations;
  final Set<String> titles;
  final num? salaryMin;
  final num? salaryMax;
  final String? city;

  /// Quick-find facets (set by the Home "collection" presets): women-friendly
  /// roles and night-shift work.
  final bool womenFriendly;
  final bool nightShift;
  final bool disabilityFriendly;
  final SearchSort sort;

  /// Number of active facet filters (excludes the free-text query & sort).
  int get activeCount =>
      jobTypes.length +
      experienceLevels.length +
      workingModels.length +
      schedulePatterns.length +
      formalizations.length +
      titles.length +
      ((salaryMin != null || salaryMax != null) ? 1 : 0) +
      (city != null && city!.isNotEmpty ? 1 : 0) +
      (womenFriendly ? 1 : 0) +
      (nightShift ? 1 : 0) +
      (disabilityFriendly ? 1 : 0);

  SearchFilters copyWith({
    String? query,
    Set<String>? jobTypes,
    Set<String>? experienceLevels,
    Set<String>? workingModels,
    Set<String>? schedulePatterns,
    Set<String>? formalizations,
    Set<String>? titles,
    num? salaryMin,
    num? salaryMax,
    bool clearSalary = false,
    String? city,
    bool clearCity = false,
    bool? womenFriendly,
    bool? nightShift,
    bool? disabilityFriendly,
    SearchSort? sort,
  }) => SearchFilters(
    query: query ?? this.query,
    jobTypes: jobTypes ?? this.jobTypes,
    experienceLevels: experienceLevels ?? this.experienceLevels,
    workingModels: workingModels ?? this.workingModels,
    schedulePatterns: schedulePatterns ?? this.schedulePatterns,
    formalizations: formalizations ?? this.formalizations,
    titles: titles ?? this.titles,
    salaryMin: clearSalary ? null : (salaryMin ?? this.salaryMin),
    salaryMax: clearSalary ? null : (salaryMax ?? this.salaryMax),
    city: clearCity ? null : (city ?? this.city),
    womenFriendly: womenFriendly ?? this.womenFriendly,
    nightShift: nightShift ?? this.nightShift,
    disabilityFriendly: disabilityFriendly ?? this.disabilityFriendly,
    sort: sort ?? this.sort,
  );
}

/// Serializable payload sent to the `search-jobs` Edge Function.
class SearchQuery {
  const SearchQuery({
    required this.q,
    required this.filters,
    required this.sort,
    this.limit = 30,
    this.offset = 0,
  });

  final String q;
  final List<String> filters;
  final List<String> sort;
  final int limit;
  final int offset;

  Map<String, dynamic> toJson() => {
    'q': q,
    'filters': filters,
    'sort': sort,
    'limit': limit,
    'offset': offset,
  };

  factory SearchQuery.from(SearchFilters f) {
    String inList(String attr, Set<String> values) =>
        '$attr IN [${values.map((e) => '"$e"').join(',')}]';

    final filters = <String>[
      if (f.jobTypes.isNotEmpty) inList('job_type', f.jobTypes),
      if (f.experienceLevels.isNotEmpty)
        inList('experience_level', f.experienceLevels),
      if (f.workingModels.isNotEmpty) inList('working_model', f.workingModels),
      if (f.schedulePatterns.isNotEmpty)
        inList('schedule_pattern', f.schedulePatterns),
      if (f.formalizations.isNotEmpty)
        inList('formalization', f.formalizations),
      if (f.salaryMin != null) 'salary_max >= ${f.salaryMin}',
      if (f.salaryMax != null) 'salary_min <= ${f.salaryMax}',
      if (f.city != null && f.city!.isNotEmpty) 'city = "${f.city}"',
      if (f.womenFriendly) 'women_friendly = true',
      if (f.nightShift) 'night_shift = true',
      if (f.disabilityFriendly) 'disability_friendly = true',
    ];

    final sort = switch (f.sort) {
      SearchSort.newest => ['posted_at:desc'],
      SearchSort.salaryHigh => ['salary_max:desc'],
      SearchSort.salaryLow => ['salary_min:asc'],
    };

    return SearchQuery(q: f.query, filters: filters, sort: sort);
  }
}
