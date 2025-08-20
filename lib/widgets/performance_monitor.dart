import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '/services/memory_optimizer.dart';
import '/services/performance_cache_manager.dart';

/// Performance monitoring widget that tracks frame drops and memory usage
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool showDebugInfo;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.showDebugInfo = kDebugMode,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  final List<Duration> _frameTimes = [];
  int _droppedFrames = 0;
  String _memoryInfo = '';

  @override
  void initState() {
    super.initState();

    // Disable performance monitoring in debug mode to prevent conflicts
    if (widget.showDebugInfo && kReleaseMode) {
      // Monitor frame performance only in release mode
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);

      // Update memory info periodically
      _updateMemoryInfo();
    }
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frameTimes.add(timing.totalSpan);

      // Consider frame dropped if it takes longer than 16.67ms (60fps)
      if (timing.totalSpan.inMilliseconds > 16) {
        _droppedFrames++;
        print('🚨 Frame drop detected: ${timing.totalSpan.inMilliseconds}ms');

        // Reduce aggressive cleanup in debug mode to prevent conflicts
        if (_droppedFrames % 10 == 0 && kReleaseMode) {
          _triggerCleanup();
        }
      }
    }

    // Keep only recent frame times
    if (_frameTimes.length > 100) {
      _frameTimes.removeRange(0, _frameTimes.length - 100);
    }

    if (mounted && widget.showDebugInfo) {
      setState(() {});
    }
  }

  void _updateMemoryInfo() {
    if (!mounted) return;

    final cacheStats = PerformanceCacheManager.instance.getStats();
    final totalCacheSize = cacheStats.values
        .map((stats) => stats['size'] as int)
        .fold(0, (a, b) => a + b);

    _memoryInfo =
        'Caches: $totalCacheSize items, Dropped frames: $_droppedFrames';

    if (mounted && widget.showDebugInfo) {
      setState(() {});
    }

    // Schedule next update
    Future.delayed(const Duration(seconds: 2), _updateMemoryInfo);
  }

  void _triggerCleanup() {
    print('🧹 Triggering performance cleanup due to frame drops');
    MemoryOptimizer.instance.forceCleanup();
  }

  double get _averageFrameTime {
    if (_frameTimes.isEmpty) return 0;
    final total =
        _frameTimes.fold<int>(0, (sum, time) => sum + time.inMicroseconds);
    return total / _frameTimes.length / 1000; // Convert to milliseconds
  }

  @override
  void dispose() {
    if (widget.showDebugInfo && kReleaseMode) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // In debug mode, return child directly without performance monitoring
    if (kDebugMode) {
      return widget.child;
    }
    
    return Stack(
      children: [
        widget.child,
        if (widget.showDebugInfo && kDebugMode)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Performance Monitor',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Avg Frame: ${_averageFrameTime.toStringAsFixed(1)}ms',
                    style: TextStyle(
                      color: _averageFrameTime > 16 ? Colors.red : Colors.green,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _memoryInfo,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'FPS: ${(1000 / (_averageFrameTime > 0 ? _averageFrameTime : 16.67)).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: _averageFrameTime > 16 ? Colors.red : Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Performance-optimized wrapper for MaterialApp
class OptimizedMaterialApp extends StatelessWidget {
  final Widget home;
  final String title;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode? themeMode;
  final List<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final List<Locale> supportedLocales;
  final Locale? locale;
  final RouteInformationProvider? routeInformationProvider;
  final RouteInformationParser<Object>? routeInformationParser;
  final RouterDelegate<Object>? routerDelegate;
  final bool showPerformanceOverlay;

  const OptimizedMaterialApp({
    super.key,
    required this.home,
    required this.title,
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.localizationsDelegates,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.locale,
    this.routeInformationProvider,
    this.routeInformationParser,
    this.routerDelegate,
    this.showPerformanceOverlay = kDebugMode,
  });

  @override
  Widget build(BuildContext context) {
    Widget app = MaterialApp.router(
      title: title,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: locale,
      routeInformationProvider: routeInformationProvider,
      routeInformationParser: routeInformationParser,
      routerDelegate: routerDelegate,
      // Disable debug banner for better performance
      debugShowCheckedModeBanner: false,
    );

    // Wrap with performance monitor
    if (showPerformanceOverlay) {
      app = PerformanceMonitor(child: app);
    }

    return app;
  }
}

/// Performance-optimized scaffold wrapper
class OptimizedScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Color? backgroundColor;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const OptimizedScaffold({
    super.key,
    this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    this.backgroundColor,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: appBar,
      body: body != null
          ? RepaintBoundary(child: body!) // Isolate repaints
          : null,
      bottomNavigationBar: bottomNavigationBar != null
          ? RepaintBoundary(child: bottomNavigationBar!)
          : null,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      backgroundColor: backgroundColor,
      // Reduce overdraw
      extendBody: true,
    );
  }
}
