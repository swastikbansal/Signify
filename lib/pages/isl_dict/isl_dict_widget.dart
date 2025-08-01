import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '/services/google_drive_service.dart';
import 'isl_dict_model.dart';
export 'isl_dict_model.dart';

class IslDictWidget extends StatefulWidget {
  const IslDictWidget({super.key});

  @override
  State<IslDictWidget> createState() => _IslDictWidgetState();
}

class _IslDictWidgetState extends State<IslDictWidget> with RouteAware {
  late IslDictModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => IslDictModel());

    _model.textController ??= TextEditingController()
      ..addListener(() {
        debugLogWidgetClass(_model);
        // Trigger search when text changes with debouncing
        EasyDebounce.debounce(
          'searchDebouncer',
          Duration(milliseconds: 500),
          () async {
            await _model.searchSigns(_model.textController?.text ?? '');
            // Update UI after async search completes
            safeSetState(() {});
          },
        );
      });
    _model.textFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
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

  // Helper function for safe state updates
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    DebugFlutterFlowModelContext.maybeOf(context)
        ?.parentModelCallback
        ?.call(_model);

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

        final islDictUsersRecord = snapshot.data!;
        _model.debugBackendQueries['islDictUsersRecord_Scaffold_fsndxmtc'] =
            debugSerializeParam(
          islDictUsersRecord,
          ParamType.Document,
          link:
              'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=islDict',
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
                FFLocalizations.of(context).getText(
                  '5fzg2vtr' /* ISL Dictionary */,
                ),
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      fontFamily: 'Space Grotesk',
                      letterSpacing: 0.0,
                      useGoogleFonts:
                          GoogleFonts.asMap().containsKey('Space Grotesk'),
                    ),
              ),
              actions: const [],
              centerTitle: false,
              elevation: 0.0,
            ),
            body: SafeArea(
              top: true,
              child: Stack(
                children: [
                  Align(
                    alignment: const AlignmentDirectional(0.0, -1.0),
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting Section
                            RichText(
                              textScaler: MediaQuery.of(context).textScaler,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: FFLocalizations.of(context).getText(
                                      '0pwzyzhy' /* Hello  */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          fontFamily: FlutterFlowTheme.of(context).headlineSmallFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts: GoogleFonts.asMap()
                                              .containsKey(FlutterFlowTheme.of(context).headlineSmallFamily),
                                        ),
                                  ),
                                  TextSpan(
                                    text: islDictUsersRecord.displayName.isNotEmpty 
                                        ? islDictUsersRecord.displayName 
                                        : currentUserDisplayName ?? 'User',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          fontFamily: FlutterFlowTheme.of(context).headlineSmallFamily,
                                          color: FlutterFlowTheme.of(context).primary,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          useGoogleFonts: GoogleFonts.asMap()
                                              .containsKey(FlutterFlowTheme.of(context).headlineSmallFamily),
                                        ),
                                  ),
                                  TextSpan(
                                    text: FFLocalizations.of(context).getText(
                                      'leryyacw' /* ! */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          fontFamily: FlutterFlowTheme.of(context).headlineSmallFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts: GoogleFonts.asMap()
                                              .containsKey(FlutterFlowTheme.of(context).headlineSmallFamily),
                                        ),
                                  )
                                ],
                              ),
                            ),
                            
                            // Description
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 8.0, 0.0, 24.0),
                              child: Text(
                                FFLocalizations.of(context).getText(
                                  'tai0ovmf' /* Explore the Indian Sign Language dictionary */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                      letterSpacing: 0.0,
                                      useGoogleFonts: GoogleFonts.asMap()
                                          .containsKey(FlutterFlowTheme.of(context).bodyMediumFamily),
                                    ),
                              ),
                            ),
                            
                            // Search Bar
                            Container(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _model.textController,
                                focusNode: _model.textFieldFocusNode,
                                onChanged: (_) => EasyDebounce.debounce(
                                  'textController',
                                  Duration(milliseconds: 500),
                                  () => safeSetState(() {}),
                                ),
                                autofocus: false,
                                obscureText: false,
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
                                    fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts: GoogleFonts.asMap()
                                        .containsKey(FlutterFlowTheme.of(context).labelMediumFamily),
                                  ),
                                  hintText: 'Search here',
                                  hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                                    fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts: GoogleFonts.asMap()
                                        .containsKey(FlutterFlowTheme.of(context).labelMediumFamily),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).alternate,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).primary,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  filled: true,
                                  fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                                  contentPadding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                    size: 20.0,
                                  ),
                                ),
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: GoogleFonts.asMap()
                                      .containsKey(FlutterFlowTheme.of(context).bodyMediumFamily),
                                ),
                                cursorColor: FlutterFlowTheme.of(context).primary,
                                validator: _model.textControllerValidator.asValidator(context),
                              ),
                            ),
                            SizedBox(height: 24.0),
                            
                            /* // Daily Task Section - Commented out for now
                            GestureDetector(
                              onTap: () => _model.startDailyTask(),
                              child: Container(
                                width: double.infinity,
                                height: 160.0,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF8B5CF6).withOpacity(0.3),
                                      offset: Offset(0, 8),
                                      blurRadius: 16.0,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Background decorative elements
                                    Positioned(
                                      right: -20,
                                      bottom: -20,
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 40,
                                      top: 20,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    // Content
                                    Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${_model.dailyTask?.streakDays ?? 10}-day streak',
                                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                                  fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                  color: Colors.white.withOpacity(0.9),
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts: GoogleFonts.asMap()
                                                      .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                                ),
                                              ),
                                              SizedBox(width: 8.0),
                                              Icon(
                                                Icons.local_fire_department,
                                                color: Colors.orange,
                                                size: 16.0,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.0),
                                          Text(
                                            'Daily task',
                                            style: FlutterFlowTheme.of(context).headlineSmall.override(
                                              fontFamily: FlutterFlowTheme.of(context).headlineSmallFamily,
                                              color: Colors.white,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              useGoogleFonts: GoogleFonts.asMap()
                                                  .containsKey(FlutterFlowTheme.of(context).headlineSmallFamily),
                                            ),
                                          ),
                                          Spacer(),
                                          Container(
                                            height: 45.0,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _model.startDailyTask(),
                                              icon: Icon(Icons.play_arrow, color: Colors.black),
                                              label: Text(
                                                'Start',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFFFACC15),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(25.0),
                                                ),
                                                padding: EdgeInsets.symmetric(horizontal: 24.0),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 32.0),
                            */
                            
                            // Search Results Section
                            if (_model.textController?.text.isNotEmpty == true) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Search Results',
                                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                                      fontFamily: FlutterFlowTheme.of(context).headlineSmallFamily,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      useGoogleFonts: GoogleFonts.asMap()
                                          .containsKey(FlutterFlowTheme.of(context).headlineSmallFamily),
                                    ),
                                  ),
                                  if (_model.isLoadingDriveVideos)
                                    SizedBox(
                                      width: 20.0,
                                      height: 20.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        color: FlutterFlowTheme.of(context).primary,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                _model.getSearchStatusMessage(),
                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                  fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: GoogleFonts.asMap()
                                      .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                ),
                              ),
                              SizedBox(height: 16.0),
                              
                              // Local ISL Signs Results
                              if (_model.filteredSigns.isNotEmpty) ...[
                                Text(
                                  'ISL Dictionary (${_model.filteredSigns.length})',
                                  style: FlutterFlowTheme.of(context).titleMedium.override(
                                    fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
                                    color: FlutterFlowTheme.of(context).primary,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: GoogleFonts.asMap()
                                        .containsKey(FlutterFlowTheme.of(context).titleMediumFamily),
                                  ),
                                ),
                                SizedBox(height: 12.0),
                                ...(_model.filteredSigns.take(5).map((sign) => 
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 12.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        _model.addToRecentlyViewed(sign);
                                        _showSignDetailsBottomSheet(sign);
                                        safeSetState(() {});
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context).secondaryBackground,
                                          borderRadius: BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context).alternate,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40.0,
                                              height: 40.0,
                                              decoration: BoxDecoration(
                                                color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8.0),
                                              ),
                                              child: Icon(
                                                Icons.waving_hand,
                                                color: FlutterFlowTheme.of(context).primary,
                                                size: 20.0,
                                              ),
                                            ),
                                            SizedBox(width: 12.0),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    sign.word,
                                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                      fontFamily: FlutterFlowTheme.of(context).bodyLargeFamily,
                                                      fontWeight: FontWeight.w500,
                                                      letterSpacing: 0.0,
                                                      useGoogleFonts: GoogleFonts.asMap()
                                                          .containsKey(FlutterFlowTheme.of(context).bodyLargeFamily),
                                                    ),
                                                  ),
                                                  Text(
                                                    sign.category,
                                                    style: FlutterFlowTheme.of(context).bodySmall.override(
                                                      fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                      color: FlutterFlowTheme.of(context).secondaryText,
                                                      letterSpacing: 0.0,
                                                      useGoogleFonts: GoogleFonts.asMap()
                                                          .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color: FlutterFlowTheme.of(context).secondaryText,
                                              size: 16.0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ).toList()),
                                SizedBox(height: 16.0),
                              ],
                              
                              // Additional video results
                              if (_model.driveVideos.isNotEmpty) ...[
                                SizedBox(height: 12.0),
                                ...(_model.driveVideos.take(5).map((video) => 
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 12.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        _model.addDriveVideoToRecentlyViewed(video);
                                        _showDriveVideoBottomSheet(video);
                                        safeSetState(() {});
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context).secondaryBackground,
                                          borderRadius: BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: Color(0xFF4285F4).withOpacity(0.3),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40.0,
                                              height: 40.0,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(8.0),
                                              ),
                                              child: Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                                size: 20.0,
                                              ),
                                            ),
                                            SizedBox(width: 12.0),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _model.extractWordFromVideoName(video.name),
                                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                      fontFamily: FlutterFlowTheme.of(context).bodyLargeFamily,
                                                      fontWeight: FontWeight.w500,
                                                      letterSpacing: 0.0,
                                                      useGoogleFonts: GoogleFonts.asMap()
                                                          .containsKey(FlutterFlowTheme.of(context).bodyLargeFamily),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF4285F4).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12.0),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.play_circle_fill,
                                                    color: Color(0xFF4285F4),
                                                    size: 14.0,
                                                  ),
                                                  SizedBox(width: 4.0),
                                                  Text(
                                                    'Watch',
                                                    style: FlutterFlowTheme.of(context).bodySmall.override(
                                                      fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                      color: Color(0xFF4285F4),
                                                      letterSpacing: 0.0,
                                                      fontWeight: FontWeight.w500,
                                                      useGoogleFonts: GoogleFonts.asMap()
                                                          .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ).toList()),
                                SizedBox(height: 16.0),
                              ],
                              
                              // No results message
                              if (_model.filteredSigns.isEmpty && 
                                  _model.driveVideos.isEmpty && 
                                  !_model.isLoadingDriveVideos) ...[
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(24.0),
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(
                                      color: FlutterFlowTheme.of(context).alternate,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        color: FlutterFlowTheme.of(context).secondaryText,
                                        size: 48.0,
                                      ),
                                      SizedBox(height: 12.0),
                                      Text(
                                        'No results found',
                                        style: FlutterFlowTheme.of(context).titleMedium.override(
                                          fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts: GoogleFonts.asMap()
                                              .containsKey(FlutterFlowTheme.of(context).titleMediumFamily),
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        'Try a different search term or check your Google Drive configuration',
                                        textAlign: TextAlign.center,
                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                          fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                                          color: FlutterFlowTheme.of(context).secondaryText,
                                          letterSpacing: 0.0,
                                          useGoogleFonts: GoogleFonts.asMap()
                                              .containsKey(FlutterFlowTheme.of(context).bodyMediumFamily),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16.0),
                              ],
                              
                              SizedBox(height: 16.0),
                            ],
                            
                            // Recently Viewed Section
                            if (_model.recentlyViewedSigns.isNotEmpty) ...[
                              Text(
                                'Recently Viewed',
                                style: FlutterFlowTheme.of(context).headlineSmall.override(
                                  fontFamily: FlutterFlowTheme.of(context).headlineSmallFamily,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  useGoogleFonts: GoogleFonts.asMap()
                                      .containsKey(FlutterFlowTheme.of(context).headlineSmallFamily),
                                ),
                              ),
                              SizedBox(height: 16.0),
                              ...(_model.recentlyViewedSigns.take(3).map((sign) => 
                                Padding(
                                  padding: EdgeInsets.only(bottom: 12.0),
                                  child: GestureDetector(
                                    onTap: () => _showSignDetailsBottomSheet(sign),
                                    child: Container(
                                      padding: EdgeInsets.all(16.0),
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context).secondaryBackground,
                                        borderRadius: BorderRadius.circular(12.0),
                                        border: Border.all(
                                          color: FlutterFlowTheme.of(context).alternate,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40.0,
                                            height: 40.0,
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                            child: Icon(
                                              Icons.waving_hand,
                                              color: FlutterFlowTheme.of(context).primary,
                                              size: 20.0,
                                            ),
                                          ),
                                          SizedBox(width: 12.0),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  sign.word,
                                                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                    fontFamily: FlutterFlowTheme.of(context).bodyLargeFamily,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: 0.0,
                                                    useGoogleFonts: GoogleFonts.asMap()
                                                        .containsKey(FlutterFlowTheme.of(context).bodyLargeFamily),
                                                  ),
                                                ),
                                                Text(
                                                  sign.category,
                                                  style: FlutterFlowTheme.of(context).bodySmall.override(
                                                    fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                    color: FlutterFlowTheme.of(context).secondaryText,
                                                    letterSpacing: 0.0,
                                                    useGoogleFonts: GoogleFonts.asMap()
                                                        .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: FlutterFlowTheme.of(context).secondaryText,
                                            size: 16.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ).toList()),
                              SizedBox(height: 32.0),
                            ],
                            
                            /* 
                            // Categories Grid
                            StaggeredGrid.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16.0,
                              crossAxisSpacing: 16.0,
                              children: [
                                // Alphabets
                                _buildCategoryCard(
                                  title: 'Alphabets',
                                  progress: '12 / 100',
                                  icon: Icons.sort_by_alpha,
                                  backgroundColor: Color(0xFFE879F9),
                                  onTap: () async {
                                    await _model.filterByCategory('alphabets');
                                    safeSetState(() {});
                                  },
                                ),
                                // Numbers
                                _buildCategoryCard(
                                  title: 'Numbers',
                                  progress: '12 / 100',
                                  icon: Icons.format_list_numbered,
                                  backgroundColor: Color(0xFFFACC15),
                                  onTap: () async {
                                    await _model.filterByCategory('numbers');
                                    safeSetState(() {});
                                  },
                                ),
                                // Family
                                _buildCategoryCard(
                                  title: 'Family',
                                  progress: '12 / 100',
                                  icon: Icons.family_restroom,
                                  backgroundColor: Color(0xFF7DD3FC),
                                  onTap: () async {
                                    await _model.filterByCategory('family');
                                    safeSetState(() {});
                                  },
                                ),
                                // Food
                                _buildCategoryCard(
                                  title: 'Food',
                                  progress: '12 / 100',
                                  icon: Icons.restaurant,
                                  backgroundColor: Color(0xFF86EFAC),
                                  onTap: () async {
                                    await _model.filterByCategory('food');
                                    safeSetState(() {});
                                  },
                                ),
                                // Education
                                _buildCategoryCard(
                                  title: 'Education',
                                  progress: '12 / 100',
                                  icon: Icons.school,
                                  backgroundColor: Color(0xFFFFB347),
                                  onTap: () async {
                                    await _model.filterByCategory('education');
                                    safeSetState(() {});
                                  },
                                ),
                                // Health
                                _buildCategoryCard(
                                  title: 'Health',
                                  progress: '12 / 100',
                                  icon: Icons.favorite,
                                  backgroundColor: Color(0xFFE879F9),
                                  onTap: () async {
                                    await _model.filterByCategory('health');
                                    safeSetState(() {});
                                  },
                                ),
                                // Basic Phrases
                                _buildCategoryCard(
                                  title: 'Basic Phrases',
                                  progress: '12 / 100',
                                  icon: Icons.chat_bubble,
                                  backgroundColor: Color(0xFF7DD3FC),
                                  onTap: () async {
                                    await _model.filterByCategory('basic_phrases');
                                    safeSetState(() {});
                                  },
                                ),
                                // Explore More
                                _buildCategoryCard(
                                  title: 'Explore More',
                                  progress: '12 / 100',
                                  icon: Icons.explore,
                                  backgroundColor: Color(0xFFFACC15),
                                  onTap: () => _showWordOfTheDayBottomSheet(),
                                ),
                              ],
                            ),
                            SizedBox(height: 32.0),
                            */
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSignDetailsBottomSheet(dynamic sign) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sign?.word ?? 'Sign',
                    style: FlutterFlowTheme.of(context).headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                height: 200.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).accent1,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_fill,
                        size: 64.0,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      const SizedBox(height: 8.0),
                      const Text('Video Preview'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                sign?.description ?? 'Sign description',
                style: FlutterFlowTheme.of(context).bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _model.markSignAsLearned(sign?.id ?? '');
                        safeSetState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlutterFlowTheme.of(context).primary,
                      ),
                      child: const Text(
                        'Practice Sign',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  IconButton(
                    onPressed: () {
                      _model.toggleFavorite(sign?.id ?? '');
                      safeSetState(() {});
                    },
                    icon: Icon(
                      (sign?.isFavorite ?? false) ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month];
  }

  // Method to show word of the day bottom sheet
  void _showWordOfTheDayBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28.0),
            topRight: Radius.circular(28.0),
          ),
        ),
        child: Column(
          children: [
            // Handle bar and header
            Container(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    width: 40.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryText.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Text(
                          'Word of the Day',
                          style: FlutterFlowTheme.of(context).labelMedium.override(
                            fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                            color: Colors.white,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                            useGoogleFonts: GoogleFonts.asMap()
                                .containsKey(FlutterFlowTheme.of(context).labelMediumFamily),
                          ),
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Main word display with animation container
                    Center(
                      child: Container(
                        width: 200.0,
                        height: 200.0,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24.0),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF667eea).withOpacity(0.4),
                              offset: Offset(0, 12),
                              blurRadius: 24.0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.waving_hand,
                                color: Colors.white,
                                size: 64.0,
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                'ISL',
                                style: FlutterFlowTheme.of(context).titleMedium.override(
                                  fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  useGoogleFonts: GoogleFonts.asMap()
                                      .containsKey(FlutterFlowTheme.of(context).titleMediumFamily),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 32.0),
                    
                    // Word details
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _model.wordOfTheDay?.word ?? 'Hello',
                            style: FlutterFlowTheme.of(context).displayMedium.override(
                              fontFamily: FlutterFlowTheme.of(context).displayMediumFamily,
                              fontSize: 48.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.0,
                              useGoogleFonts: GoogleFonts.asMap()
                                  .containsKey(FlutterFlowTheme.of(context).displayMediumFamily),
                            ),
                          ),
                          SizedBox(height: 12.0),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.category,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 16.0,
                                ),
                                SizedBox(width: 6.0),
                                Text(
                                  _model.wordOfTheDay?.category ?? 'Greetings',
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                                    color: FlutterFlowTheme.of(context).primary,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: GoogleFonts.asMap()
                                        .containsKey(FlutterFlowTheme.of(context).bodyMediumFamily),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 32.0),
                    
                    // Meaning section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.0),
                      margin: EdgeInsets.symmetric(horizontal: 20.0),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).alternate,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: FlutterFlowTheme.of(context).primary,
                                size: 20.0,
                              ),
                              SizedBox(width: 8.0),
                              Text(
                                'Meaning',
                                style: FlutterFlowTheme.of(context).titleMedium.override(
                                  fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: GoogleFonts.asMap()
                                      .containsKey(FlutterFlowTheme.of(context).titleMediumFamily),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.0),
                          Text(
                            _model.wordOfTheDay?.description ?? 'A greeting sign used to acknowledge someone',
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                              letterSpacing: 0.0,
                              lineHeight: 1.5,
                              useGoogleFonts: GoogleFonts.asMap()
                                  .containsKey(FlutterFlowTheme.of(context).bodyMediumFamily),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24.0),
                    
                    // Action buttons
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _model.markSignAsLearned(_model.wordOfTheDay?.id ?? '');
                                safeSetState(() {});
                              },
                              icon: Icon(Icons.play_arrow),
                              label: Text('Practice Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FlutterFlowTheme.of(context).primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.0),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: IconButton(
                              onPressed: () {
                                _model.toggleFavorite(_model.wordOfTheDay?.id ?? '');
                                safeSetState(() {});
                              },
                              icon: Icon(
                                _model.wordOfTheDay?.isFavorite ?? false
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDriveVideoBottomSheet(dynamic video) {
    // Initialize video when modal opens
    if (video?.name != null) {
      final wordName = _model.extractWordFromVideoName(video.name);
      
      // Use improved initialization with fallback
      _model.initializeVideoWithFallback(wordName);
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _model.extractWordFromVideoName(video?.name ?? 'Video'),
                      style: FlutterFlowTheme.of(context).headlineSmall,
                    ),
                    IconButton(
                      onPressed: () {
                        _model.disposeVideo();
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Stack(
                        children: [
                          // Video player or placeholder
                          if (_model.isVideoInitialized && _model.videoController != null)
                            Center(
                              child: AspectRatio(
                                aspectRatio: _model.videoController!.value.aspectRatio,
                                child: VideoPlayer(_model.videoController!),
                              ),
                            )
                          else if (_model.isVideoLoading())
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 16.0),
                                  Text(
                                    'Loading video...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  if (kDebugMode)
                                    Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Using demo video for testing',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12.0,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          else
                            // Fallback UI when video fails to load
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(20.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.play_arrow,
                                      size: 60.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 16.0),
                                  Text(
                                    'Video not available locally',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8.0),
                                  Text(
                                    'Tap to simulate playback',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Play/Pause overlay button
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () {
                                if (_model.isVideoInitialized) {
                                  _model.toggleVideoPlayback();
                                  setModalState(() {});
                                } else {
                                  // Fallback: show snackbar for demo
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Playing ${_model.extractWordFromVideoName(video?.name ?? '')} sign video...'),
                                      backgroundColor: FlutterFlowTheme.of(context).primary,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: _model.isVideoInitialized && !_model.isVideoPlaying
                                    ? Center(
                                        child: Container(
                                          padding: EdgeInsets.all(16.0),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.play_arrow,
                                            size: 40.0,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : SizedBox.shrink(),
                              ),
                            ),
                          ),
                          
                          // Video controls overlay
                          if (_model.isVideoInitialized)
                            Positioned(
                              bottom: 16.0,
                              left: 16.0,
                              right: 16.0,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.videocam,
                                      color: Colors.white,
                                      size: 20.0,
                                    ),
                                    SizedBox(width: 8.0),
                                    Expanded(
                                      child: Text(
                                        'ISL Sign Video',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${_model.getVideoPosition()} / ${_model.getVideoDuration()}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            // Default controls for non-video content
                            Positioned(
                              bottom: 16.0,
                              left: 16.0,
                              right: 16.0,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.videocam,
                                      color: Colors.white,
                                      size: 20.0,
                                    ),
                                    SizedBox(width: 8.0),
                                    Expanded(
                                      child: Text(
                                        'ISL Sign Video',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '0:30',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  _model.extractWordFromVideoName(video?.name ?? ''),
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                    fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    useGoogleFonts: GoogleFonts.asMap()
                        .containsKey(FlutterFlowTheme.of(context).titleMediumFamily),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.0),
                SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _model.markDriveVideoAsLearned(video);
                          _model.disposeVideo();
                          safeSetState(() {});
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to learned signs! Daily task progress updated.'),
                              backgroundColor: FlutterFlowTheme.of(context).primary,
                            ),
                          );
                        },
                        icon: Icon(Icons.check_circle, color: Colors.white),
                        label: Text(
                          'Mark as Learned',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF34A853),
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatFileSize(int? size) {
    if (size == null) return 'Unknown size';
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper method to build category cards
  Widget _buildCategoryCard({
    required String title,
    required String progress,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120.0,
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              offset: Offset(0, 4),
              blurRadius: 8.0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.black.withOpacity(0.8),
              size: 28.0,
            ),
            Spacer(),
            Text(
              title,
              style: FlutterFlowTheme.of(context).titleSmall.override(
                fontFamily: FlutterFlowTheme.of(context).titleSmallFamily,
                color: Colors.black,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
                useGoogleFonts: GoogleFonts.asMap()
                    .containsKey(FlutterFlowTheme.of(context).titleSmallFamily),
              ),
            ),
            SizedBox(height: 4.0),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                progress,
                style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                  color: Colors.black.withOpacity(0.8),
                  letterSpacing: 0.0,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w500,
                  useGoogleFonts: GoogleFonts.asMap()
                      .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
