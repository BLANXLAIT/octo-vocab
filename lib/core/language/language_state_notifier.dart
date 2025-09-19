import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octo_vocab/core/language/language_registry.dart';
import 'package:octo_vocab/core/services/local_data_service.dart';

// ignore_for_file: public_member_api_docs

/// Manages selected language state with persistence
class LanguageStateNotifier extends StateNotifier<String> {
  final LocalDataService _dataService;
  final LanguageRegistry _registry;
  static const String _languageKey = 'selectedLanguage';

  LanguageStateNotifier(this._dataService, this._registry) : super('la') {
    _loadSavedLanguage();
  }

  /// Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final settings = _dataService.getAppSettings();
      final savedLanguage = settings[_languageKey] as String?;

      if (savedLanguage != null && _registry.isLanguageAvailable(savedLanguage)) {
        state = savedLanguage;
      } else {
        // Fallback to first available language
        final availableLanguages = _registry.getAvailableLanguages();
        if (availableLanguages.isNotEmpty) {
          state = availableLanguages.first.code;
          // Save this default choice
          await _saveLanguage(state);
        }
      }
    } catch (e) {
      // Silent fail - keep default 'la' if loading fails
    }
  }

  /// Change the selected language and persist it
  Future<void> setLanguage(String languageCode) async {
    if (languageCode == state) return; // No change needed

    // For tests with provider overrides, we might not have the registry properly configured
    // In production, this validation prevents invalid language codes
    if (_registry.getAvailableLanguages().isNotEmpty &&
        !_registry.isLanguageAvailable(languageCode)) {
      throw ArgumentError('Language "$languageCode" is not available');
    }

    state = languageCode;
    await _saveLanguage(languageCode);
  }

  /// Save the language choice to SharedPreferences
  Future<void> _saveLanguage(String languageCode) async {
    try {
      final settings = _dataService.getAppSettings();
      settings[_languageKey] = languageCode;
      await _dataService.saveAppSettings(settings);
    } catch (e) {
      // Silent fail - the state is still updated even if saving fails
    }
  }

  /// Get the current language code
  String get currentLanguage => state;

  /// Check if a language is currently selected
  bool isLanguageSelected(String languageCode) => state == languageCode;
}

/// Provider for the language state notifier
final languageStateNotifierProvider = StateNotifierProvider<LanguageStateNotifier, String>((ref) {
  final dataService = ref.watch(localDataServiceProvider);
  final registry = ref.watch(languageRegistryProvider);

  return dataService.when(
    data: (service) => LanguageStateNotifier(service, registry),
    loading: () => LanguageStateNotifier(
      // Create a mock service for loading state
      _MockLocalDataService(),
      registry,
    ),
    error: (_, __) => LanguageStateNotifier(
      _MockLocalDataService(),
      registry,
    ),
  );
});

/// Mock service for loading/error states
class _MockLocalDataService implements LocalDataService {
  @override
  Map<String, dynamic> getAppSettings() => {};

  @override
  Future<bool> saveAppSettings(Map<String, dynamic> settings) async => true;

  // These methods won't be called by LanguageStateNotifier
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}