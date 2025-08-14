import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'index.dart';

// Performance optimization services
import 'services/performance_cache_manager.dart';
import 'services/memory_optimizer.dart';
import 'services/network_optimizer.dart';
import 'services/database_optimizer.dart';
import 'services/background_task_optimizer.dart';

// Security and state management
import 'config/app_config.dart';
import 'services/app_state_manager.dart';
import 'services/error_recovery_service.dart';

import 'dart:async';
import 'package:easy_debounce/easy_debounce.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  // Initialize performance services first
  await _initializePerformanceServices();

  await initFirebase();

  await FlutterFlowTheme.initialize();

  await FFLocalizations.initialize();

  final originalErrorWidgetBuilder = ErrorWidget.builder;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    try {
      final match = RegExp(
              r'The relevant error-causing widget was:\s+([a-zA-Z0-9]+)(.|\n)*When the exception was thrown, this was the stack:((.|\n)*)')
          .firstMatch(details.toString());
      if (match == null) {
        return originalErrorWidgetBuilder(details);
      }
      final widgetName = match.group(1);
      final stackTrace = match.group(3)!;

      // The stack trace usually is very long, and most of it is entirely
      // irrelevant for troubleshooting, e.g.:
      //
      // dart-sdk/lib/_internal/js_dev_runtime/private/ddc_runtime/errors.dart 251:49  throw_
      // dart-sdk/lib/_internal/js_dev_runtime/private/ddc_runtime/errors.dart 29:3    assertFailed
      // packages/flutter/src/widgets/text.dart 378:14                                 new
      // packages/debug_screen_test/home_page/home_page_widget.dart 51:15              build
      // packages/flutter/src/widgets/framework.dart 4870:27                           build
      // packages/flutter/src/widgets/framework.dart 4754:15                           performRebuild
      // packages/flutter/src/widgets/framework.dart 4928:11                           performRebuild
      // packages/flutter/src/widgets/framework.dart 4477:5                            rebuild
      // <a long long list of internal libraries>
      //
      // We truncate everything after project-specific code.

      final filteredStackTrace = <String>[];
      var foundProjectTraces = false;
      for (final line in stackTrace.split('\n')) {
        if (line.startsWith('packages/signify/')) {
          foundProjectTraces = true;
        } else {
          if (foundProjectTraces) {
            filteredStackTrace.add('...');
            break;
          }
        }
        filteredStackTrace.add(line);
      }

      final result = '''${details.exceptionAsString()}
      
The relevant error-causing widget was: $widgetName

Stack trace: ${filteredStackTrace.join("\n")}''';

      return ErrorWidget.withDetails(message: result);
    } catch (_) {
      return originalErrorWidgetBuilder(details);
    }
  };

  /// Optimized debounce cleanup - reduced frequency to improve performance
  Timer.periodic(const Duration(seconds: 5), (timer) {
    EasyDebounce.cancel('508f3c74205c87928b71f49040062e732f9c20b0');
  });

  // Initialize Supabase for loading 3D ISL Animations with error recovery
  await _initializeSupabaseWithRetry();

  runApp(const MyApp());
}

/// Initialize performance optimization services - simplified
Future<void> _initializePerformanceServices() async {
  try {
    // Initialize memory optimizer
    await MemoryOptimizer.instance.initialize();

    // Initialize cache manager
    PerformanceCacheManager.instance.initialize();

    // Initialize remaining optimizers (instant performance achieved with new system)
    NetworkOptimizer.instance.initialize();
    DatabaseOptimizer.instance.initialize();
    BackgroundTaskOptimizer.instance.initialize();

    // Disable aggressive memory pressure handling that causes app restarts during image capture
    // MemoryOptimizer.instance.addMemoryPressureListener(() {
    //   PerformanceCacheManager.instance.clearAll();
    //   NetworkOptimizer.instance.clearCache();
    //   DatabaseOptimizer.instance.clearQueryCache();
    //   // Using safe image processor now - no cache clearing needed
    //   print('🧹 Basic caches cleared due to memory pressure');
    // });

    print('🚀 Basic performance services initialized successfully');
  } catch (e) {
    print('⚠️ Error initializing performance services: $e');
  }
}

/// Initialize Supabase with error recovery
Future<void> _initializeSupabaseWithRetry() async {
  return ErrorRecoveryService.instance.handleWithRetry(
    operationKey: 'supabase_init',
    operation: () async {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      print('✅ Supabase initialized successfully');
    },
    onError: (error) {
      print('❌ Failed to initialize Supabase: $error');
      AppStateManager.instance.setError('Failed to initialize services');
    },
    onMaxRetriesReached: () {
      print('🚨 Critical: Supabase initialization failed after all retries');
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale? _locale = FFLocalizations.getStoredLocale();

  Locale? get locale => _locale;
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;

  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();

  late Stream<BaseAuthUser> userStream;

  final authUserSub = authenticatedUserStream.listen((_) {});

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = signifyFirebaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
        debugLogAuthenticatedUser();
      });
    jwtTokenStream.listen((_) {});
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );

    _router.routerDelegate.addListener(() {
      if (mounted) {
        debugLogGlobalProperty(
          context,
          locale: locale.toString(),
          routePath: getRoute(),
          routeStack: getRouteStack(),
        );
      }
    });
  }

  @override
  void dispose() {
    authUserSub.cancel();

    // Dispose all performance services in correct order
    BackgroundTaskOptimizer.instance.dispose();
    DatabaseOptimizer.instance.dispose();
    NetworkOptimizer.instance.dispose();
    // Removed animation and image optimizers - using instant system now
    PerformanceCacheManager.instance.dispose();
    MemoryOptimizer.instance.dispose();

    // Dispose error recovery service
    ErrorRecoveryService.instance.dispose();

    super.dispose();
  }

  void setLocale(String language) {
    safeSetState(() => _locale = createLocale(language));
    FFLocalizations.storeLocale(language);
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    // Temporarily disable PerformanceMonitor to fix image/animation issues
    return MaterialApp.router(
      title: 'Signify',
      // Disable debug banner for better performance
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationDelegate(),
        FallbackCupertinoLocalizationDelegate(),
      ],
      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('bn'),
        Locale('mr'),
        Locale('te'),
        Locale('gu'),
        Locale('pa'),
        Locale('kn'),
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        // Optimized scrollbar theme
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: WidgetStateProperty.all(false),
          interactive: true,
          radius: const Radius.circular(50.0),
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.dragged)) {
              return const Color(0xff000000);
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xfff3f3f3);
            }
            return const Color(0xff000000);
          }),
        ),
        // Performance optimization: reduce animation durations
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: WidgetStateProperty.all(false),
          interactive: true,
          radius: const Radius.circular(50.0),
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.dragged)) {
              return const Color(0xffffffff);
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xff1c1c1c);
            }
            return const Color(0xffffffff);
          }),
        ),
        // Performance optimization: reduce animation durations
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}

class NavBarPage extends StatefulWidget {
  const NavBarPage({super.key, this.initialPage, this.page});

  final String? initialPage;
  final Widget? page;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

/// This is the private State class that goes with NavBarPage.
class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'voicetosign1';
  late Widget? _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = {
      'voicetosign1': const Voicetosign1Widget(),
      'signtovoice2': const Signtovoice2Widget(),
      'islDict': const IslDictWidget(),
      'account4': const Account4Widget(),
    };
    final currentIndex = tabs.keys.toList().indexOf(_currentPageName);

    return Scaffold(
      body: _currentPage ?? tabs[_currentPageName],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => safeSetState(() {
          _currentPage = null;
          _currentPageName = tabs.keys.toList()[i];
        }),
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        selectedItemColor: FlutterFlowTheme.of(context).primary,
        unselectedItemColor: FlutterFlowTheme.of(context).secondaryText,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(
              Icons.sign_language_outlined,
              size: 30.0,
            ),
            activeIcon: const Icon(
              Icons.sign_language,
              size: 30.0,
            ),
            label: FFLocalizations.of(context).getText(
              'ktfggi18' /* Voice to sign */,
            ),
            tooltip: '',
          ),
          BottomNavigationBarItem(
            icon: const Icon(
              Icons.spatial_audio_off_outlined,
              size: 30.0,
            ),
            activeIcon: const Icon(
              Icons.spatial_audio_off_rounded,
              size: 30.0,
            ),
            label: FFLocalizations.of(context).getText(
              'vgleqcd8' /* Sign to Voice */,
            ),
            tooltip: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(
              Icons.book_outlined,
              size: 30.0,
            ),
            activeIcon: Icon(
              Icons.book,
              size: 30.0,
            ),
            label: 'Dictionary',
            tooltip: '',
          ),
          BottomNavigationBarItem(
            icon: const Icon(
              Icons.account_circle_outlined,
              size: 30.0,
            ),
            activeIcon: const Icon(
              Icons.account_circle_rounded,
              size: 30.0,
            ),
            label: FFLocalizations.of(context).getText(
              'k68wh7xs' /* Account */,
            ),
            tooltip: '',
          )
        ],
      ),
    );
  }
}
