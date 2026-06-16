import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../data/preferences_repository.dart';

/// In-progress selections shared across the four preference-setup screens.
class PreferenceDraft {
  const PreferenceDraft({
    this.jobTypes = const {},
    this.experienceLevels = const {},
    this.workingModels = const {},
    this.titles = const [],
  });

  final Set<String> jobTypes;
  final Set<String> experienceLevels;
  final Set<String> workingModels;
  final List<String> titles;

  PreferenceDraft copyWith({
    Set<String>? jobTypes,
    Set<String>? experienceLevels,
    Set<String>? workingModels,
    List<String>? titles,
  }) => PreferenceDraft(
    jobTypes: jobTypes ?? this.jobTypes,
    experienceLevels: experienceLevels ?? this.experienceLevels,
    workingModels: workingModels ?? this.workingModels,
    titles: titles ?? this.titles,
  );
}

class PreferencesController extends Notifier<PreferenceDraft> {
  @override
  PreferenceDraft build() => const PreferenceDraft();

  Set<String> _toggled(Set<String> set, String value) {
    final next = {...set};
    next.contains(value) ? next.remove(value) : next.add(value);
    return next;
  }

  void toggleJobType(String wire) =>
      state = state.copyWith(jobTypes: _toggled(state.jobTypes, wire));
  void toggleExperience(String wire) => state = state.copyWith(
    experienceLevels: _toggled(state.experienceLevels, wire),
  );
  void toggleWorkingModel(String wire) => state = state.copyWith(
    workingModels: _toggled(state.workingModels, wire),
  );

  void addTitle(String title) {
    final t = title.trim();
    if (t.isEmpty || state.titles.contains(t)) return;
    state = state.copyWith(titles: [...state.titles, t]);
  }

  /// Toggles a predefined title in/out of the selection.
  void toggleTitle(String title) {
    final next = state.titles.contains(title)
        ? state.titles.where((t) => t != title).toList()
        : [...state.titles, title];
    state = state.copyWith(titles: next);
  }

  void removeTitle(String title) => state = state.copyWith(
    titles: state.titles.where((t) => t != title).toList(),
  );

  /// Saves the draft to Supabase (no-op in offline/no-backend mode).
  Future<void> persist() async {
    if (!Env.hasSupabase) return;
    await ref
        .read(preferencesRepositoryProvider)
        .save(
          jobTypes: state.jobTypes.toList(),
          experienceLevels: state.experienceLevels.toList(),
          workingModels: state.workingModels.toList(),
          titles: state.titles,
        );
  }
}

final preferencesControllerProvider =
    NotifierProvider<PreferencesController, PreferenceDraft>(
      PreferencesController.new,
    );
