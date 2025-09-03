// ignore_for_file: public_member_api_docs
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/language_study_config.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';

/// Provider for the complete study configuration set
final studyConfigurationProvider =
    StateNotifierProvider<
      StudyConfigurationNotifier,
      AsyncValue<StudyConfigurationSet>
    >((ref) {
      return StudyConfigurationNotifier(ref);
    });

/// State notifier for managing study configuration
class StudyConfigurationNotifier
    extends StateNotifier<AsyncValue<StudyConfigurationSet>> {
  StudyConfigurationNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  final Ref _ref;

  Future<void> _initialize() async {
    try {
      final dataService = await _ref.read(localDataServiceProvider.future);

      // Run migration if needed
      await dataService.migrateToNewConfigSystem();

      // Load current configuration
      final config = dataService.getStudyConfiguration();
      state = AsyncValue.data(config);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update configuration for a specific language
  Future<void> updateLanguageConfig(
    AppLanguage language,
    LanguageStudyConfig config,
  ) async {
    final currentState = state;
    if (currentState is! AsyncData<StudyConfigurationSet>) return;

    try {
      final dataService = await _ref.read(localDataServiceProvider.future);
      await dataService.updateLanguageConfig(language, config);

      // Update local state
      final updatedConfigSet = currentState.value.updateLanguageConfig(
        language,
        config,
      );
      state = AsyncValue.data(updatedConfigSet);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Set the current active language
  Future<void> setCurrentLanguage(AppLanguage language) async {
    final currentState = state;
    if (currentState is! AsyncData<StudyConfigurationSet>) return;

    try {
      final dataService = await _ref.read(localDataServiceProvider.future);
      await dataService.setCurrentLanguage(language);

      // Update local state
      final updatedConfigSet = currentState.value.withCurrentLanguage(language);
      state = AsyncValue.data(updatedConfigSet);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh configuration from storage
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _initialize();
  }
}

/// Provider for the current active language configuration (cached)
final currentLanguageConfigProvider = Provider<LanguageStudyConfig?>((ref) {
  final configAsync = ref.watch(studyConfigurationProvider);
  return configAsync.whenOrNull(data: (config) => config.currentConfiguration);
}, dependencies: [studyConfigurationProvider]);

/// Provider for all enabled language configurations (cached)
final enabledLanguageConfigsProvider = Provider<List<LanguageStudyConfig>>((
  ref,
) {
  final configAsync = ref.watch(studyConfigurationProvider);
  final result =
      configAsync.whenOrNull(data: (config) => config.enabledConfigurations) ??
      [];

  // Cache the result to avoid recomputation
  return result;
}, dependencies: [studyConfigurationProvider]);

/// Provider for the current active language (cached, backwards compatibility)
final currentLanguageProvider = Provider<AppLanguage>((ref) {
  final configAsync = ref.watch(studyConfigurationProvider);
  return configAsync.whenOrNull(data: (config) => config.currentLanguage) ??
      AppLanguage.latin;
}, dependencies: [studyConfigurationProvider]);

/// Provider for the current active level (cached, backwards compatibility)
final currentLevelProvider = Provider<VocabularyLevel>((ref) {
  final currentConfig = ref.watch(currentLanguageConfigProvider);
  return currentConfig?.level ?? VocabularyLevel.beginner;
}, dependencies: [currentLanguageConfigProvider]);

/// Optimized provider for checking if a language is enabled for study
final isLanguageEnabledProvider = Provider.family<bool, AppLanguage>((
  ref,
  language,
) {
  final configAsync = ref.watch(studyConfigurationProvider);
  return configAsync.whenOrNull(
        data: (config) {
          final langConfig = config.getConfigForLanguage(language);
          return langConfig?.isEnabled ?? false;
        },
      ) ??
      false;
});

/// Optimized provider for getting configuration for a specific language
final languageConfigProvider =
    Provider.family<LanguageStudyConfig?, AppLanguage>((ref, language) {
      final configAsync = ref.watch(studyConfigurationProvider);
      return configAsync.whenOrNull(
        data: (config) => config.getConfigForLanguage(language),
      );
    });
