import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'auth/firebase_auth/auth_util.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'backend/firebase/firebase_config.dart';
// Security and state management
import 'config/app_config.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'index.dart';
import 'services/error_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  // Initialize modern error handling service
  ErrorService.instance.initialize();

  await initFirebase();
  await FlutterFlowTheme.initialize();
  await FFLocalizations.initialize();

  // Industry-standard error handling
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    return ErrorService.buildErrorWidget(
      'Something went wrong. Please restart the app.',
    );
  };

  // Initialize Supabase with simplified error handling
  await _initializeSupabase();

  runApp(const MyApp());
}

/// Initialize Supabase with proper error handling
Future<void> _initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize Supabase: $e');
    // Continue app initialization even if Supabase fails
  }
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

  List<String> getRouteStack() => _router
      .routerDelegate
      .currentConfiguration
      .matches
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
    // Remove custom splash screen delay - native splash is sufficient
    _appStateNotifier.stopShowingSplashImage();

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
    // Disable PerformanceMonitor in debug mode to prevent blank page issues
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: FlutterFlowTheme.of(
          context,
        ).secondaryBackground,
        systemNavigationBarIconBrightness:
            Theme.of(context).brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
      child: Scaffold(
        body: _currentPage ?? tabs[_currentPageName],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: FlutterFlowTheme.of(context).alternate,
                width: 0.0, // Adds border to the top of the NavBar
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (i) => safeSetState(() {
              _currentPage = null;
              _currentPageName = tabs.keys.toList()[i];
            }),
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            indicatorColor: FlutterFlowTheme.of(
              context,
            ).primary.withOpacity(0.16),
            surfaceTintColor: FlutterFlowTheme.of(context).secondaryBackground,
            elevation: 10.0,
            height: 65.0,
            // Reduced from 80.0 to 65.0
            animationDuration: const Duration(milliseconds: 300),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            // Custom label text styling for selected/unselected states
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  color: FlutterFlowTheme.of(context).primary,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                );
              }
              return TextStyle(
                color: FlutterFlowTheme.of(context).secondaryText,
                fontSize: 12.0,
                fontWeight: FontWeight.w400,
              );
            }),

            // Reduce padding between icon and label
            // labelPadding: const EdgeInsets.only(top: 4.0), // Padding between icon and label default 4.0
            destinations: [
              Tooltip(
                message: 'Convert speech to sign language',
                preferBelow: false,
                // Position tooltip above
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).alternate,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                textStyle: TextStyle(
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 14.0,
                ),
                child: NavigationDestination(
                  icon: Icon(
                    Icons.record_voice_over_outlined,
                    size: 24.0,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                  selectedIcon: Icon(
                    Icons.record_voice_over,
                    size: 24.0,
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                  label: FFLocalizations.of(
                    context,
                  ).getText('ktfggi18' /* Speak */),
                  tooltip: '', // Disable default tooltip
                ),
              ),
              Tooltip(
                message: 'Convert sign language to speech',
                preferBelow: false,
                // Position tooltip above
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).alternate,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                textStyle: TextStyle(
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 14.0,
                ),
                child: NavigationDestination(
                  icon: Icon(
                    Icons.sign_language_outlined,
                    size: 24.0,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                  selectedIcon: Icon(
                    Icons.sign_language,
                    size: 24.0,
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                  label: FFLocalizations.of(
                    context,
                  ).getText('helpdw8b' /* Sign */),
                  tooltip: '', // Disable default tooltip
                ),
              ),
              Tooltip(
                message: 'Sign language dictionary',
                preferBelow: false,
                // Position tooltip above
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).alternate,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                textStyle: TextStyle(
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 14.0,
                ),
                child: NavigationDestination(
                  icon: Icon(
                    Icons.book_outlined,
                    size: 24.0,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                  selectedIcon: Icon(
                    Icons.book,
                    size: 24.0,
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                  label: FFLocalizations.of(
                    context,
                  ).getText('5fzg2vtn' /* Dictionary */),
                  tooltip: '', // Disable default tooltip
                ),
              ),
              Tooltip(
                message: 'User account and settings',
                preferBelow: false,
                // Position tooltip above
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).alternate,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                textStyle: TextStyle(
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 14.0,
                ),
                child: NavigationDestination(
                  icon: Icon(
                    Icons.person_outline,
                    size: 24.0,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                  selectedIcon: Icon(
                    Icons.person,
                    size: 24.0,
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                  label: FFLocalizations.of(
                    context,
                  ).getText('k68wh7xs' /* Account */),
                  tooltip: '', // Disable default tooltip
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
