// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Performance metrics for monitoring app performance
class PerformanceMetrics {
  const PerformanceMetrics({
    required this.memoryUsage,
    required this.cacheHitRate,
    required this.averageLoadTime,
    required this.activeProviders,
  });

  final double memoryUsage; // MB
  final double cacheHitRate; // Percentage
  final Duration averageLoadTime;
  final int activeProviders;

  Map<String, dynamic> toJson() {
    return {
      'memory_usage_mb': memoryUsage,
      'cache_hit_rate': cacheHitRate,
      'average_load_time_ms': averageLoadTime.inMilliseconds,
      'active_providers': activeProviders,
    };
  }
}

/// Service for monitoring app performance and identifying bottlenecks
class PerformanceMonitor {
  PerformanceMonitor._();
  static final PerformanceMonitor _instance = PerformanceMonitor._();
  static PerformanceMonitor get instance => _instance;

  final List<Duration> _loadTimes = [];
  int _cacheHits = 0;
  int _cacheMisses = 0;
  Timer? _monitoringTimer;

  /// Start performance monitoring
  void startMonitoring() {
    if (_monitoringTimer != null) return;
    
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _logPerformanceMetrics();
    });
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Record a cache hit
  void recordCacheHit() {
    _cacheHits++;
  }

  /// Record a cache miss
  void recordCacheMiss() {
    _cacheMisses++;
  }

  /// Record loading time for an operation
  void recordLoadTime(Duration duration) {
    _loadTimes.add(duration);
    
    // Keep only recent measurements (last 100)
    if (_loadTimes.length > 100) {
      _loadTimes.removeAt(0);
    }
  }

  /// Get current performance metrics
  PerformanceMetrics getMetrics() {
    final totalCacheRequests = _cacheHits + _cacheMisses;
    final cacheHitRate = totalCacheRequests > 0 
        ? (_cacheHits / totalCacheRequests) * 100 
        : 0.0;
    
    final averageLoadTime = _loadTimes.isNotEmpty
        ? _loadTimes.reduce((a, b) => a + b) ~/ _loadTimes.length
        : Duration.zero;

    return PerformanceMetrics(
      memoryUsage: _getMemoryUsage(),
      cacheHitRate: cacheHitRate,
      averageLoadTime: averageLoadTime,
      activeProviders: _getActiveProvidersCount(),
    );
  }

  /// Log performance metrics (debug mode only)
  void _logPerformanceMetrics() {
    if (!kDebugMode) return;
    
    final metrics = getMetrics();
    debugPrint('🚀 Performance Metrics: ${metrics.toJson()}');
    
    // Alert on performance issues
    if (metrics.averageLoadTime.inMilliseconds > 1000) {
      debugPrint('⚠️ Slow loading times detected: ${metrics.averageLoadTime.inMilliseconds}ms');
    }
    
    if (metrics.cacheHitRate < 50) {
      debugPrint('⚠️ Low cache hit rate: ${metrics.cacheHitRate.toStringAsFixed(1)}%');
    }
  }

  /// Estimate memory usage (simplified)
  double _getMemoryUsage() {
    // This is a simplified estimation
    // In production, you might use more sophisticated memory tracking
    return 0.0; // Placeholder
  }

  /// Get active providers count (simplified)
  int _getActiveProvidersCount() {
    // This would need integration with Riverpod internals
    // For now, return a placeholder
    return 0; // Placeholder
  }

  /// Reset metrics
  void resetMetrics() {
    _loadTimes.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
  }
}

/// Provider for performance monitor
final performanceMonitorProvider = Provider<PerformanceMonitor>((ref) {
  return PerformanceMonitor.instance;
});

/// Provider for current performance metrics
final performanceMetricsProvider = Provider<PerformanceMetrics>((ref) {
  final monitor = ref.watch(performanceMonitorProvider);
  return monitor.getMetrics();
});

/// Mixin to add performance monitoring to widgets
mixin PerformanceTrackingMixin {
  Future<T> trackOperation<T>(String operationName, Future<T> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      return result;
    } finally {
      stopwatch.stop();
      PerformanceMonitor.instance.recordLoadTime(stopwatch.elapsed);
      
      if (kDebugMode) {
        debugPrint('⏱️ $operationName took ${stopwatch.elapsedMilliseconds}ms');
      }
    }
  }
}