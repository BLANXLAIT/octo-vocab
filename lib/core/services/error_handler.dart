import 'package:flutter/foundation.dart';

// ignore_for_file: public_member_api_docs

/// Centralized error handling service for the application
class ErrorHandler {
  /// Log an error with context
  static void logError(
    String context,
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    if (kDebugMode) {
      print('❌ ERROR in $context: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Get a user-friendly error message
  static String getUserMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('SocketException') ||
          message.contains('HandshakeException') ||
          message.contains('NetworkException')) {
        return 'Network connection error. Please check your internet.';
      }
      if (message.contains('TimeoutException')) {
        return 'Request timed out. Please try again.';
      }
      if (message.contains('FormatException')) {
        return 'Data format error. Please try again.';
      }
    }

    // For this offline app, most errors are data-related
    return 'Something went wrong. Please try again.';
  }

  /// Check if an error is recoverable
  static bool isRecoverable(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      // These errors are typically recoverable
      return message.contains('Timeout') ||
          message.contains('Network') ||
          message.contains('Socket');
    }
    return true; // Assume recoverable by default
  }
}

/// Custom exception for vocabulary loading errors
class VocabularyLoadException implements Exception {
  final String message;
  final String? languageCode;

  const VocabularyLoadException(this.message, [this.languageCode]);

  @override
  String toString() =>
      'VocabularyLoadException: $message${languageCode != null ? ' (language: $languageCode)' : ''}';
}

/// Custom exception for storage errors
class StorageException implements Exception {
  final String message;
  final String operation;

  const StorageException(this.message, this.operation);

  @override
  String toString() => 'StorageException: $message (operation: $operation)';
}

/// Custom exception for language plugin errors
class LanguagePluginException implements Exception {
  final String message;
  final String languageCode;

  const LanguagePluginException(this.message, this.languageCode);

  @override
  String toString() =>
      'LanguagePluginException: $message (language: $languageCode)';
}