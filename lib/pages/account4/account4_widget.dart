import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/customs_signs/custom_signs_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:google_fonts/google_fonts.dart';
import 'account4_model.dart';
export 'account4_model.dart';

// Performance optimization imports
import '/services/memory_optimizer.dart';

/// Disposable wrapper for account widget
class _AccountDisposable implements Disposable {
  final _Account4WidgetState state;
  _AccountDisposable(this.state);

  @override
  void dispose() {
    // Additional cleanup if needed
  }
}

class Account4Widget extends StatefulWidget {
  const Account4Widget({super.key});

  @override
  State<Account4Widget> createState() => _Account4WidgetState();
}

class _Account4WidgetState extends State<Account4Widget>
    with RouteAware, MemoryOptimizedWidget {
  late Account4Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Account4Model());

    // Tutorial walkthrough removed for performance optimization
    // Performance optimization: register for memory cleanup
    MemoryOptimizer.instance.registerDisposable(_AccountDisposable(this));
  }

  @override
  void dispose() {
    _model.dispose();
    // Clean up memory-tracked resources
    disposeMemoryResources();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, DebugModalRoute.of(context)!);
    debugLogGlobalProperty(context);
  }

  @override
  void didPopNext() {
    safeSetState(() => _model.isRouteVisible = true);
    debugLogWidgetClass(_model);
  }

  @override
  void didPush() {
    safeSetState(() => _model.isRouteVisible = true);
    debugLogWidgetClass(_model);
  }

  @override
  void didPop() {
    _model.isRouteVisible = false;
  }

  @override
  void didPushNext() {
    _model.isRouteVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    DebugFlutterFlowModelContext.maybeOf(
      context,
    )?.parentModelCallback?.call(_model);

    // Debug mode: Simple safety check for currentUserReference
    if (kDebugMode && currentUserReference == null) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            'Account (Debug Mode)',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
              fontFamily: 'Space Grotesk',
              letterSpacing: 0.0,
              useGoogleFonts: GoogleFonts.asMap().containsKey('Space Grotesk'),
            ),
          ),
          centerTitle: false,
          elevation: 0.0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 80,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
              const SizedBox(height: 16),
              Text(
                'Debug Mode: Please sign in',
                style: FlutterFlowTheme.of(context).titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FFButtonWidget(
                onPressed: () async {
                  context.pushNamed('authPage');
                },
                text: 'Sign In',
                options: FFButtonOptions(
                  width: 160,
                  height: 44,
                  padding: EdgeInsets.zero,
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(
                    context,
                  ).titleSmall.override(color: Colors.white),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(currentUserReference!),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 60.0,
                height: 60.0,
                child: SpinKitRipple(
                  color: FlutterFlowTheme.of(context).primary,
                  size: 60.0,
                ),
              ),
            ),
          );
        }

        final account4UsersRecord = snapshot.data!;
        _model.debugBackendQueries['account4UsersRecord_Scaffold_1o3oa7a6'] =
            debugSerializeParam(
              account4UsersRecord,
              ParamType.Document,
              link:
                  'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=account4',
              name: 'users',
              nullable: false,
            );
        debugLogWidgetClass(_model);

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
              automaticallyImplyLeading: false,
              title: Text(
                FFLocalizations.of(context).getText('vi568dp4' /* Account */),
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Space Grotesk',
                  letterSpacing: 0.0,
                  useGoogleFonts: GoogleFonts.asMap().containsKey(
                    'Space Grotesk',
                  ),
                ),
              ),
              actions: const [],
              centerTitle: false,
              elevation: 0.0,
            ),
            body: SafeArea(
              top: true,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  16.0,
                  0.0,
                  16.0,
                  0.0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clickable Profile Section
                      InkWell(
                        onTap: () async {
                          context.pushNamed(
                            'editProfile',
                            extra: <String, dynamic>{
                              kTransitionInfoKey: const TransitionInfo(
                                hasTransition: true,
                                transitionType: PageTransitionType.bottomToTop,
                                duration: Duration(milliseconds: 300),
                              ),
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(
                              context,
                            ).primaryBackground,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 120.0,
                                      height: 120.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(
                                          context,
                                        ).primaryBackground,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: FlutterFlowTheme.of(
                                            context,
                                          ).primary,
                                          width: 2.0,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          100.0,
                                        ),
                                        child: Image.network(
                                          account4UsersRecord.photoUrl,
                                          width: 120.0,
                                          height: 120.0,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Image.asset(
                                                'assets/images/error_image.png',
                                                width: 120.0,
                                                height: 120.0,
                                                fit: BoxFit.cover,
                                              ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            account4UsersRecord.displayName,
                                            style: FlutterFlowTheme.of(context)
                                                .titleMedium
                                                .override(
                                                  fontFamily:
                                                      FlutterFlowTheme.of(
                                                        context,
                                                      ).titleMediumFamily,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts:
                                                      GoogleFonts.asMap()
                                                          .containsKey(
                                                            FlutterFlowTheme.of(
                                                              context,
                                                            ).titleMediumFamily,
                                                          ),
                                                ),
                                          ),
                                          Text(
                                            account4UsersRecord.email,
                                            style: FlutterFlowTheme.of(context)
                                                .labelMedium
                                                .override(
                                                  fontFamily:
                                                      FlutterFlowTheme.of(
                                                        context,
                                                      ).labelMediumFamily,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts:
                                                      GoogleFonts.asMap()
                                                          .containsKey(
                                                            FlutterFlowTheme.of(
                                                              context,
                                                            ).labelMediumFamily,
                                                          ),
                                                ),
                                          ),
                                        ].divide(const SizedBox(height: 4.0)),
                                      ),
                                    ),
                                  ].divide(const SizedBox(width: 16.0)),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: FlutterFlowTheme.of(
                                  context,
                                ).secondaryText,
                                size: 24.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Modern, clean menu list without borders - Uber style
                      Column(
                        children: [
                          // Custom Signs - First
                          ListTile(
                            leading: Icon(
                              Icons.sign_language_outlined,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 24.0,
                            ),
                            title: Text(
                              FFLocalizations.of(
                                context,
                              ).getText('ushyb1bc' /*Add Custom Signs*/),
                              /*Add Custom Signs*/
                              style: FlutterFlowTheme.of(context).bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(
                                      context,
                                    ).bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts: GoogleFonts.asMap()
                                        .containsKey(
                                          FlutterFlowTheme.of(
                                            context,
                                          ).bodyLargeFamily,
                                        ),
                                  ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 20.0,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0.0,
                              vertical: 4.0,
                            ),
                            onTap: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CustomSignsPage(),
                                ),
                              );
                            },
                          ),
                          Divider(
                            height: 1.0,
                            thickness: 0.5,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          // Change Password - Second
                          ListTile(
                            leading: Icon(
                              Icons.lock_outline,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 24.0,
                            ),
                            title: Text(
                              'Change Password',
                              style: FlutterFlowTheme.of(context).bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(
                                      context,
                                    ).bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts: GoogleFonts.asMap()
                                        .containsKey(
                                          FlutterFlowTheme.of(
                                            context,
                                          ).bodyLargeFamily,
                                        ),
                                  ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 20.0,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0.0,
                              vertical: 4.0,
                            ),
                            onTap: () async {
                              context.pushNamed('forgotPassword');
                            },
                          ),
                          Divider(
                            height: 1.0,
                            thickness: 0.5,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          // App Settings - Third
                          ListTile(
                            leading: Icon(
                              Icons.settings_outlined,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 24.0,
                            ),
                            title: Text(
                              FFLocalizations.of(
                                context,
                              ).getText('8emomfy5' /* Settings */),
                              style: FlutterFlowTheme.of(context).bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(
                                      context,
                                    ).bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts: GoogleFonts.asMap()
                                        .containsKey(
                                          FlutterFlowTheme.of(
                                            context,
                                          ).bodyLargeFamily,
                                        ),
                                  ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 20.0,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0.0,
                              vertical: 4.0,
                            ),
                            onTap: () async {
                              context.pushNamed('appSettings');
                            },
                          ),
                          Divider(
                            height: 1.0,
                            thickness: 0.5,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          // Tutorial - Fourth
                          ListTile(
                            leading: Icon(
                              Icons.help_outline,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 24.0,
                            ),
                            title: Text(
                              FFLocalizations.of(
                                context,
                              ).getText('w49luoi2' /* Tutorial */),
                              style: FlutterFlowTheme.of(context).bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(
                                      context,
                                    ).bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts: GoogleFonts.asMap()
                                        .containsKey(
                                          FlutterFlowTheme.of(
                                            context,
                                          ).bodyLargeFamily,
                                        ),
                                  ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 20.0,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0.0,
                              vertical: 4.0,
                            ),
                            onTap: () async {
                              context.pushNamed(
                                'tutorialPage',
                                extra: <String, dynamic>{
                                  kTransitionInfoKey: const TransitionInfo(
                                    hasTransition: true,
                                    transitionType:
                                        PageTransitionType.rightToLeft,
                                    duration: Duration(milliseconds: 300),
                                  ),
                                },
                              );
                            },
                          ),
                          Divider(
                            height: 1.0,
                            thickness: 0.5,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          // Support & Feedback - Fifth
                          ListTile(
                            leading: Icon(
                              Icons.support_agent,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 24.0,
                            ),
                            title: Text(
                              FFLocalizations.of(
                                context,
                              ).getText('r94u6d0h' /* Support & Feedback */),
                              style: FlutterFlowTheme.of(context).bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(
                                      context,
                                    ).bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts: GoogleFonts.asMap()
                                        .containsKey(
                                          FlutterFlowTheme.of(
                                            context,
                                          ).bodyLargeFamily,
                                        ),
                                  ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 20.0,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0.0,
                              vertical: 4.0,
                            ),
                            onTap: () async {
                              context.pushNamed('supportPage');
                            },
                          ),
                          Divider(
                            height: 1.0,
                            thickness: 0.5,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          // Report Bug - Sixth
                          ListTile(
                            leading: Icon(
                              Icons.bug_report,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 24.0,
                            ),
                            title: Text(
                              FFLocalizations.of(
                                context,
                              ).getText('4oce2tuu' /* Report a Bug */),
                              style: FlutterFlowTheme.of(context).bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(
                                      context,
                                    ).bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts: GoogleFonts.asMap()
                                        .containsKey(
                                          FlutterFlowTheme.of(
                                            context,
                                          ).bodyLargeFamily,
                                        ),
                                  ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 20.0,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0.0,
                              vertical: 4.0,
                            ),
                            onTap: () async {
                              context.pushNamed('reportBug');
                            },
                          ),
                          Divider(
                            height: 1.0,
                            thickness: 0.5,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          // Feature Request - Seventh
                          ListTile(
                            leading: Icon(
                              Icons.lightbulb_outline,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 24.0,
                            ),
                            title: Text(
                              FFLocalizations.of(
                                context,
                              ).getText('ddu5ylfz' /* Feature Request */),
                              style: FlutterFlowTheme.of(context).bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(
                                      context,
                                    ).bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts: GoogleFonts.asMap()
                                        .containsKey(
                                          FlutterFlowTheme.of(
                                            context,
                                          ).bodyLargeFamily,
                                        ),
                                  ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 20.0,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0.0,
                              vertical: 4.0,
                            ),
                            onTap: () async {
                              context.pushNamed('requestFeature');
                            },
                          ),
                          Divider(
                            height: 1.0,
                            thickness: 0.5,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          // Log Out - Last (Only text is clickable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0.0,
                              vertical: 24.0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.logout,
                                  color: FlutterFlowTheme.of(context).error,
                                  size: 24.0,
                                ),
                                const SizedBox(width: 16.0),
                                GestureDetector(
                                  onTap: () async {
                                    GoRouter.of(context).prepareAuthEvent();
                                    await authManager.signOut();
                                    GoRouter.of(
                                      context,
                                    ).clearRedirectLocation();

                                    context.goNamedAuth(
                                      'selectlanguage',
                                      context.mounted,
                                    );
                                  },
                                  child: Text(
                                    FFLocalizations.of(
                                      context,
                                    ).getText('31up9p14' /* Log Out */),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily: FlutterFlowTheme.of(
                                            context,
                                          ).bodyLargeFamily,
                                          color: FlutterFlowTheme.of(
                                            context,
                                          ).error,
                                          letterSpacing: 0.0,
                                          useGoogleFonts: GoogleFonts.asMap()
                                              .containsKey(
                                                FlutterFlowTheme.of(
                                                  context,
                                                ).bodyLargeFamily,
                                              ),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ].divide(const SizedBox(height: 24.0)).addToStart(const SizedBox(height: 16.0)).addToEnd(const SizedBox(height: 24.0)),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
