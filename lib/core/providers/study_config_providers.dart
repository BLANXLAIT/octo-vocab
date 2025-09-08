// ignore_for_file: public_member_api_docs
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';

/// Provider for vocabulary level selection
final vocabularyLevelProvider = StateProvider<VocabularyLevel>((ref) {
  return VocabularyLevel.beginner;
});

/// Provider for local data service
final localDataServiceProvider = FutureProvider<LocalDataService>((ref) {
  return LocalDataService.create();
});