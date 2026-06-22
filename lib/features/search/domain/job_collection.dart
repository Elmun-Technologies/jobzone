import 'package:flutter/material.dart';

import 'search_filters.dart';

/// Apna-style "quick find" presets surfaced as cards on Home. Each maps to a
/// [SearchFilters] preset so tapping a card opens a results list that is
/// already filtered — no manual filtering needed. The set is intentionally
/// fixed (no backend table): semantic shortcuts over the existing facets.
enum JobCollection {
  freshers(
    'freshers',
    Icons.school_outlined,
    Color(0xFF3A36DB),
    SearchFilters(experienceLevels: {'entry'}),
  ),
  remote(
    'remote',
    Icons.laptop_mac_rounded,
    Color(0xFF0D80F2),
    SearchFilters(workingModels: {'remote'}),
  ),
  partTime(
    'part_time',
    Icons.schedule_rounded,
    Color(0xFF00A37A),
    SearchFilters(jobTypes: {'part_time'}),
  ),
  fullTime(
    'full_time',
    Icons.work_outline_rounded,
    Color(0xFFEA7317),
    SearchFilters(jobTypes: {'full_time'}),
  ),
  rotational(
    'rotational',
    Icons.directions_bus_filled_outlined,
    Color(0xFF8E44AD),
    SearchFilters(jobTypes: {'rotational'}),
  ),
  women(
    'women',
    Icons.diversity_1_rounded,
    Color(0xFFD6336C),
    SearchFilters(womenFriendly: true),
  ),
  nightShift(
    'night_shift',
    Icons.nightlight_round,
    Color(0xFF334E68),
    SearchFilters(nightShift: true),
  );

  const JobCollection(this.key, this.icon, this.accent, this.preset);

  /// Stable identifier used in the `/collection/:key` route.
  final String key;
  final IconData icon;
  final Color accent;
  final SearchFilters preset;

  static JobCollection? fromKey(String? k) {
    for (final c in values) {
      if (c.key == k) return c;
    }
    return null;
  }
}
