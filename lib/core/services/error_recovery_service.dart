// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/models/word.dart';

/// Types of recoverable errors
enum ErrorType {
  vocabularyLoadFailure,
  storageFailure,
  configurationCorruption,
  assetMissing,
  networkUnavailable,
}

/// Error recovery strategy
enum RecoveryStrategy {
  retry,
  fallback,
  ignore,
  resetToDefault,
}

/// Detailed error information for recovery
class RecoverableError {
  const RecoverableError({
    required this.type,
    required this.message,
    required this.originalError,
    this.context,
    this.suggestedStrategy = RecoveryStrategy.retry,
  });

  final ErrorType type;
  final String message;
  final Object originalError;
  final Map<String, dynamic>? context;
  final RecoveryStrategy suggestedStrategy;

  @override
  String toString() => 'RecoverableError($type): $message';
}

/// Service for handling errors gracefully with recovery strategies
class ErrorRecoveryService {
  ErrorRecoveryService._();
  static final ErrorRecoveryService _instance = ErrorRecoveryService._();
  static ErrorRecoveryService get instance => _instance;

  final Map<ErrorType, int> _errorCounts = {};
  final List<RecoverableError> _recentErrors = [];
  static const int _maxRecentErrors = 10;
  static const int _maxRetryAttempts = 3;

  /// Handle an error with automatic recovery
  Future<T?> handleError<T>(
    ErrorType errorType,
    String message,
    Object error, {
    Map<String, dynamic>? context,
    Future<T> Function()? retryFunction,
    T Function()? fallbackFunction,
  }) async {
    final recoverableError = RecoverableError(
      type: errorType,
      message: message,
      originalError: error,
      context: context,
      suggestedStrategy: _getRecoveryStrategy(errorType),
    );

    _recordError(recoverableError);

    switch (recoverableError.suggestedStrategy) {
      case RecoveryStrategy.retry:
        return _attemptRetry(recoverableError, retryFunction);
      
      case RecoveryStrategy.fallback:
        return _attemptFallback(recoverableError, fallbackFunction);
      
      case RecoveryStrategy.ignore:
        _logError(recoverableError, 'Ignoring error as per strategy');
        return null;
      
      case RecoveryStrategy.resetToDefault:
        return _resetToDefault<T>(recoverableError);
    }
  }

  /// Attempt to recover vocabulary loading errors
  Future<List<Word>> recoverVocabularyLoad({
    required AppLanguage language,
    required VocabularyLevel level,
    required String setName,
    required Object originalError,
  }) async {
    return await handleError<List<Word>>(
      ErrorType.vocabularyLoadFailure,
      'Failed to load vocabulary for ${language.name} ${level.code} $setName',
      originalError,
      context: {
        'language': language.name,
        'level': level.code,
        'setName': setName,
      },
      retryFunction: null, // Will be handled by the cache service
      fallbackFunction: () => _getFallbackVocabulary(language),
    ) ?? [];
  }

  /// Attempt retry with exponential backoff
  Future<T?> _attemptRetry<T>(
    RecoverableError error,
    Future<T> Function()? retryFunction,
  ) async {
    if (retryFunction == null) return null;

    final errorCount = _errorCounts[error.type] ?? 0;
    if (errorCount >= _maxRetryAttempts) {
      _logError(error, 'Max retry attempts reached, giving up');
      return null;
    }

    // Exponential backoff: 100ms, 200ms, 400ms
    final delayMs = 100 * (1 << errorCount);
    await Future.delayed(Duration(milliseconds: delayMs));

    try {
      _logError(error, 'Retrying (attempt ${errorCount + 1})');
      final result = await retryFunction();
      _resetErrorCount(error.type);
      return result;
    } catch (e) {
      _incrementErrorCount(error.type);
      return _attemptRetry(error, retryFunction);
    }
  }

  /// Attempt fallback solution
  T? _attemptFallback<T>(
    RecoverableError error,
    T Function()? fallbackFunction,
  ) {
    if (fallbackFunction == null) return null;

    try {
      _logError(error, 'Using fallback strategy');
      return fallbackFunction();
    } catch (e) {
      _logError(error, 'Fallback also failed: $e');
      return null;
    }
  }

  /// Reset to default configuration
  T? _resetToDefault<T>(RecoverableError error) {
    _logError(error, 'Resetting to default configuration');
    // This would need to be implemented based on the specific type T
    return null;
  }

  /// Get appropriate recovery strategy for error type
  RecoveryStrategy _getRecoveryStrategy(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.vocabularyLoadFailure:
        return RecoveryStrategy.fallback;
      
      case ErrorType.storageFailure:
        return RecoveryStrategy.retry;
      
      case ErrorType.configurationCorruption:
        return RecoveryStrategy.resetToDefault;
      
      case ErrorType.assetMissing:
        return RecoveryStrategy.fallback;
      
      case ErrorType.networkUnavailable:
        return RecoveryStrategy.ignore; // App is offline-first
    }
  }

  /// Get fallback vocabulary for a language
  List<Word> _getFallbackVocabulary(AppLanguage language) {
    // Return minimal vocabulary set as emergency fallback
    switch (language) {
      case AppLanguage.latin:
        return [
          Word(
            id: 'emergency_latin_1',
            latin: 'sum',
            english: 'I am',
            pos: 'verb',
            exampleLatin: 'Sum discipulus.',
            exampleEnglish: 'I am a student.',
            tags: const ['emergency', 'fallback'],
          ),
        ];
      
      case AppLanguage.spanish:
        return [
          Word(
            id: 'emergency_spanish_1',
            latin: 'soy', // Reusing latin field for simplicity
            english: 'I am',
            pos: 'verb',
            exampleLatin: 'Soy estudiante.',
            exampleEnglish: 'I am a student.',
            tags: const ['emergency', 'fallback'],
          ),
        ];
    }
  }

  /// Record error for tracking
  void _recordError(RecoverableError error) {
    _recentErrors.add(error);
    
    // Keep only recent errors
    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeAt(0);
    }
  }

  /// Increment error count for an error type
  void _incrementErrorCount(ErrorType errorType) {
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
  }

  /// Reset error count for an error type
  void _resetErrorCount(ErrorType errorType) {
    _errorCounts[errorType] = 0;
  }

  /// Log error with context
  void _logError(RecoverableError error, String action) {
    if (!kDebugMode) return;
    
    debugPrint('🚨 Error Recovery: $action');
    debugPrint('   Type: ${error.type}');
    debugPrint('   Message: ${error.message}');
    if (error.context != null) {
      debugPrint('   Context: ${error.context}');
    }
  }

  /// Get error statistics for monitoring
  Map<String, dynamic> getErrorStats() {
    return {
      'error_counts': _errorCounts.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'recent_errors': _recentErrors.map((e) => e.toString()).toList(),
      'total_errors': _recentErrors.length,
    };
  }

  /// Reset all error tracking
  void resetErrorTracking() {
    _errorCounts.clear();
    _recentErrors.clear();
  }
}

/// Provider for error recovery service
final errorRecoveryServiceProvider = Provider<ErrorRecoveryService>((ref) {
  return ErrorRecoveryService.instance;
});

/// Mixin for adding error recovery to widgets and services
mixin ErrorRecoveryMixin {
  ErrorRecoveryService get errorRecovery => ErrorRecoveryService.instance;

  /// Safely execute an operation with error recovery
  Future<T?> safeExecute<T>(
    String operation,
    Future<T> Function() function, {
    ErrorType errorType = ErrorType.vocabularyLoadFailure,
    T Function()? fallback,
  }) async {
    try {
      return await function();
    } catch (error) {
      return await errorRecovery.handleError<T>(
        errorType,
        'Failed to execute $operation',
        error,
        fallbackFunction: fallback,
      );
    }
  }
}