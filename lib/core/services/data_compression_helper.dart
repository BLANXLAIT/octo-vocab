// ignore_for_file: public_member_api_docs
import 'dart:convert';
import 'dart:io';

/// Helper class for optimizing SharedPreferences storage
class DataCompressionHelper {
  /// Compress JSON string for storage (reduces size by ~30-60%)
  static String compressJson(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final compressed = gzip.encode(bytes);
    return base64Encode(compressed);
  }

  /// Decompress JSON string from storage
  static Map<String, dynamic> decompressJson(String compressedData) {
    try {
      final compressed = base64Decode(compressedData);
      final bytes = gzip.decode(compressed);
      final jsonString = utf8.decode(bytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Fallback to uncompressed data (backwards compatibility)
      return jsonDecode(compressedData) as Map<String, dynamic>;
    }
  }

  /// Clean old data to prevent storage bloat
  static Map<String, dynamic> cleanOldQuizResults(
    Map<String, dynamic> quizResults, {
    int maxResults = 100,
    int maxAgeDays = 90,
  }) {
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: maxAgeDays))
        .millisecondsSinceEpoch;

    final cleaned = <String, dynamic>{};
    final sortedEntries = quizResults.entries.toList()
      ..sort((a, b) {
        final aTime = (a.value as Map<String, dynamic>)['timestamp'] as int? ?? 0;
        final bTime = (b.value as Map<String, dynamic>)['timestamp'] as int? ?? 0;
        return bTime.compareTo(aTime); // Most recent first
      });

    // Keep most recent results within time limit
    var count = 0;
    for (final entry in sortedEntries) {
      if (count >= maxResults) break;

      final result = entry.value as Map<String, dynamic>;
      final timestamp = result['timestamp'] as int? ?? 0;

      if (timestamp >= cutoffTime) {
        cleaned[entry.key] = entry.value;
        count++;
      }
    }

    return cleaned;
  }

  /// Clean old study sessions (keep daily aggregates only)
  static List<DateTime> cleanOldStudySessions(
    List<DateTime> sessions, {
    int maxDays = 365,
  }) {
    final cutoffDate = DateTime.now().subtract(Duration(days: maxDays));

    return sessions
        .where((session) => session.isAfter(cutoffDate))
        .toList();
  }

  /// Estimate storage size in bytes
  static int estimateStorageSize(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return utf8.encode(jsonString).length;
  }

  /// Get storage statistics
  static Map<String, dynamic> getStorageStats(Map<String, dynamic> data) {
    final originalSize = estimateStorageSize(data);
    final compressedSize = base64Decode(compressJson(data)).length;

    return {
      'originalSizeBytes': originalSize,
      'compressedSizeBytes': compressedSize,
      'compressionRatio': originalSize > 0 ? compressedSize / originalSize : 1.0,
      'spaceSavedBytes': originalSize - compressedSize,
      'entriesCount': data.length,
    };
  }
}