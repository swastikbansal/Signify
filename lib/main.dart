import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initFirebase();

  await FlutterFlowTheme.initialize();

  await FFLocalizations.initialize();

  runApp(const MyApp());
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

  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;

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
      });
    jwtTokenStream.listen((_) {});
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
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
    return MaterialApp.router(
      title: 'Signify',
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
      'education3': const Education3Widget(),
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
          BottomNavigationBarItem(
            icon: const Icon(
              Icons.menu_book_rounded,
              size: 30.0,
            ),
            activeIcon: const FaIcon(
              FontAwesomeIcons.bookReader,
              size: 30.0,
            ),
            label: FFLocalizations.of(context).getText(
              'rdorkg51' /* Education */,
            ),
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
