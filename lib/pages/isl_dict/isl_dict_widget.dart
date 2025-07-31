import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
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
        // Trigger search when text changes
        _model.searchSigns(_model.textController?.text ?? '');
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
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmallFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts: GoogleFonts.asMap()
                                              .containsKey(
                                                  FlutterFlowTheme.of(context)
                                                      .headlineSmallFamily),
                                        ),
                                  ),
                                  TextSpan(
                                    text: islDictUsersRecord.displayName,
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmallFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts: GoogleFonts.asMap()
                                              .containsKey(
                                                  FlutterFlowTheme.of(context)
                                                      .headlineSmallFamily),
                                        ),
                                  ),
                                  TextSpan(
                                    text: FFLocalizations.of(context).getText(
                                      'leryyacw' /* ! */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmallFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts: GoogleFonts.asMap()
                                              .containsKey(
                                                  FlutterFlowTheme.of(context)
                                                      .headlineSmallFamily),
                                        ),
                                  )
                                ],
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .headlineSmallFamily,
                                      letterSpacing: 1.0,
                                      useGoogleFonts: GoogleFonts.asMap()
                                          .containsKey(
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmallFamily),
                                      lineHeight: 1.0,
                                    ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            // Description
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 8.0),
                                    child: Text(
                                      FFLocalizations.of(context).getText(
                                        'tai0ovmf' /* Explore the Indian Sign Language dictionary */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMediumFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            useGoogleFonts: GoogleFonts.asMap()
                                                .containsKey(
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMediumFamily),
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Search Field
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _model.textController,
                                focusNode: _model.textFieldFocusNode,
                                onChanged: (_) => EasyDebounce.debounce(
                                  '_model.textController',
                                  const Duration(milliseconds: 500),
                                  () {
                                    _model.searchSigns(_model.textController?.text ?? '');
                                    safeSetState(() {});
                                  },
                                ),
                                autofocus: false,
                                autofillHints: const [AutofillHints.jobTitle],
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                obscureText: false,
                                decoration: InputDecoration(
                                  isDense: false,
                                  labelText:
                                      FFLocalizations.of(context).getText(
                                    '6ldvvr2l' /* Search */,
                                  ),
                                  labelStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .labelMediumFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts: GoogleFonts.asMap()
                                            .containsKey(
                                                FlutterFlowTheme.of(context)
                                                    .labelMediumFamily),
                                      ),
                                  hintText: FFLocalizations.of(context).getText(
                                    'rkagcocl' /* Search to learn more */,
                                  ),
                                  hintStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .labelMediumFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts: GoogleFonts.asMap()
                                            .containsKey(
                                                FlutterFlowTheme.of(context)
                                                    .labelMediumFamily),
                                      ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
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
                                  fillColor: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  contentPadding: const EdgeInsets.all(12.0),
                                  hoverColor: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  prefixIcon: Icon(
                                    Icons.menu_book_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 24.0,
                                  ),
                                  suffixIcon: _model
                                          .textController!.text.isNotEmpty
                                      ? InkWell(
                                          onTap: () async {
                                            _model.textController?.clear();
                                            _model.searchSigns('');
                                            safeSetState(() {});
                                          },
                                          child: Icon(
                                            Icons.clear,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            size: 24.0,
                                          ),
                                        )
                                      : null,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts: GoogleFonts.asMap()
                                          .containsKey(
                                              FlutterFlowTheme.of(context)
                                                  .bodyMediumFamily),
                                    ),
                                maxLines: 2,
                                minLines: 1,
                                cursorColor:
                                    FlutterFlowTheme.of(context).primary,
                                validator: _model.textControllerValidator
                                    .asValidator(context),
                              ),
                            ),

                            const SizedBox(height: 24.0),

                            // Daily Task Banner
                            GestureDetector(
                              onTap: () {
                                _model.startDailyTask();
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Daily Practice'),
                                    content: Text('Start your daily learning session?\n\nGoal: Learn ${_model.dailyTask?.targetSigns ?? 5} signs today\nProgress: ${_model.dailyTask?.learnedToday ?? 0}/${_model.dailyTask?.targetSigns ?? 5} completed'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Later'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          // Navigate to practice mode
                                        },
                                        child: const Text('Start Practice'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                height: 140.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).primary,
                                  borderRadius: BorderRadius.circular(16.0),
                                  image: const DecorationImage(
                                    fit: BoxFit.cover,
                                    image: AssetImage('assets/images/dailyTask.png'),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${_model.dailyTask?.streakDays ?? 0}-day streak',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: FlutterFlowTheme.of(context)
                                                  .bodyMediumFamily,
                                              color: Colors.white,
                                              letterSpacing: 0.0,
                                              useGoogleFonts: GoogleFonts.asMap()
                                                  .containsKey(FlutterFlowTheme.of(context)
                                                      .bodyMediumFamily),
                                            ),
                                      ),
                                      Text(
                                        _model.dailyTask?.title ?? 'Daily Practice',
                                        style: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .override(
                                              fontFamily: FlutterFlowTheme.of(context)
                                                  .headlineSmallFamily,
                                              color: Colors.white,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              useGoogleFonts: GoogleFonts.asMap()
                                                  .containsKey(FlutterFlowTheme.of(context)
                                                      .headlineSmallFamily),
                                            ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Container(
                                        width: 200.0,
                                        height: 6.0,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(3.0),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _model.getDailyTaskProgress(),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(3.0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32.0),

                            // Categories Grid
                            Text(
                              'Categories',
                              style: FlutterFlowTheme.of(context).titleLarge.override(
                                fontFamily: FlutterFlowTheme.of(context).titleLargeFamily,
                                letterSpacing: 0.0,
                                useGoogleFonts: GoogleFonts.asMap()
                                    .containsKey(FlutterFlowTheme.of(context).titleLargeFamily),
                              ),
                            ),

                            const SizedBox(height: 16.0),

                            GridView.count(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              crossAxisCount: 2,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                              childAspectRatio: 1.1,
                              children: [
                                // Alphabets Category
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to alphabets
                                    _model.filterByCategory('alphabets');
                                    safeSetState(() {});
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFE1BEE7),
                                          Color(0xFFCE93D8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFCE93D8).withOpacity(0.3),
                                          offset: const Offset(0, 8),
                                          blurRadius: 16.0,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AZ',
                                            style: FlutterFlowTheme.of(context)
                                                .displaySmall
                                                .override(
                                                  fontFamily: FlutterFlowTheme.of(context).displaySmallFamily,
                                                  color: const Color(0xFF7B1FA2),
                                                  fontSize: 36.0,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts: GoogleFonts.asMap()
                                                      .containsKey(FlutterFlowTheme.of(context).displaySmallFamily),
                                                ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Alphabets',
                                            style: FlutterFlowTheme.of(context)
                                                .titleMedium
                                                .override(
                                                  fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
                                                  color: const Color(0xFF4A148C),
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts: GoogleFonts.asMap()
                                                      .containsKey(FlutterFlowTheme.of(context).titleMediumFamily),
                                                ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF7B1FA2),
                                              borderRadius: BorderRadius.circular(16.0),
                                            ),
                                            child: Text(
                                              '12 / 100',
                                              style: FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                    color: Colors.white,
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.0,
                                                    useGoogleFonts: GoogleFonts.asMap()
                                                        .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Numbers Category
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to numbers
                                    _model.filterByCategory('numbers');
                                    safeSetState(() {});
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFF9C4),
                                          Color(0xFFFFF176),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFF176).withOpacity(0.3),
                                          offset: const Offset(0, 8),
                                          blurRadius: 16.0,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 20.0,
                                                height: 4.0,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE65100),
                                                  borderRadius: BorderRadius.circular(2.0),
                                                ),
                                              ),
                                              const SizedBox(height: 4.0),
                                              Container(
                                                width: 30.0,
                                                height: 4.0,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE65100),
                                                  borderRadius: BorderRadius.circular(2.0),
                                                ),
                                              ),
                                              const SizedBox(height: 4.0),
                                              Container(
                                                width: 25.0,
                                                height: 4.0,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE65100),
                                                  borderRadius: BorderRadius.circular(2.0),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Numbers',
                                            style: FlutterFlowTheme.of(context)
                                                .titleMedium
                                                .override(
                                                  fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
                                                  color: const Color(0xFFBF360C),
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts: GoogleFonts.asMap()
                                                      .containsKey(FlutterFlowTheme.of(context).titleMediumFamily),
                                                ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE65100),
                                              borderRadius: BorderRadius.circular(16.0),
                                            ),
                                            child: Text(
                                              '12 / 100',
                                              style: FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                    color: Colors.white,
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.0,
                                                    useGoogleFonts: GoogleFonts.asMap()
                                                        .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Family Category
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to family
                                    _model.filterByCategory('family');
                                    safeSetState(() {});
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFE0F7FA),
                                          Color(0xFF80DEEA),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF80DEEA).withOpacity(0.3),
                                          offset: const Offset(0, 8),
                                          blurRadius: 16.0,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.person,
                                                color: Color(0xFF00695C),
                                                size: 20.0,
                                              ),
                                              SizedBox(width: 4.0),
                                              Icon(
                                                Icons.person,
                                                color: Color(0xFF00695C),
                                                size: 20.0,
                                              ),
                                              SizedBox(width: 4.0),
                                              Icon(
                                                Icons.person,
                                                color: Color(0xFF00695C),
                                                size: 16.0,
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Family',
                                            style: FlutterFlowTheme.of(context)
                                                .titleMedium
                                                .override(
                                                  fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
                                                  color: const Color(0xFF004D40),
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts: GoogleFonts.asMap()
                                                      .containsKey(FlutterFlowTheme.of(context).titleMediumFamily),
                                                ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00695C),
                                              borderRadius: BorderRadius.circular(16.0),
                                            ),
                                            child: Text(
                                              '8 / 50',
                                              style: FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                    color: Colors.white,
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.0,
                                                    useGoogleFonts: GoogleFonts.asMap()
                                                        .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Books Category
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to books
                                    _model.filterByCategory('books');
                                    safeSetState(() {});
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFE8F5E8),
                                          Color(0xFFA5D6A7),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFA5D6A7).withOpacity(0.3),
                                          offset: const Offset(0, 8),
                                          blurRadius: 16.0,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            children: [
                                              Container(
                                                width: 30.0,
                                                height: 24.0,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2E7D32),
                                                  borderRadius: BorderRadius.circular(4.0),
                                                ),
                                              ),
                                              Positioned(
                                                left: 4.0,
                                                child: Container(
                                                  width: 30.0,
                                                  height: 24.0,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF43A047),
                                                    borderRadius: BorderRadius.circular(4.0),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                left: 8.0,
                                                child: Container(
                                                  width: 30.0,
                                                  height: 24.0,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF66BB6A),
                                                    borderRadius: BorderRadius.circular(4.0),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Books',
                                            style: FlutterFlowTheme.of(context)
                                                .titleMedium
                                                .override(
                                                  fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
                                                  color: const Color(0xFF1B5E20),
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts: GoogleFonts.asMap()
                                                      .containsKey(FlutterFlowTheme.of(context).titleMediumFamily),
                                                ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2E7D32),
                                              borderRadius: BorderRadius.circular(16.0),
                                            ),
                                            child: Text(
                                              '15 / 75',
                                              style: FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                    color: Colors.white,
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.0,
                                                    useGoogleFonts: GoogleFonts.asMap()
                                                        .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32.0),

                            // Word of the Day Section
                            Text(
                              'Word of the Day',
                              style: FlutterFlowTheme.of(context).titleLarge.override(
                                fontFamily: FlutterFlowTheme.of(context).titleLargeFamily,
                                letterSpacing: 0.0,
                                useGoogleFonts: GoogleFonts.asMap()
                                    .containsKey(FlutterFlowTheme.of(context).titleLargeFamily),
                              ),
                            ),

                            const SizedBox(height: 16.0),

                            GestureDetector(
                              onTap: () {
                                // Navigate to word details or show detailed view
                                _model.viewWordOfTheDay();
                                _showWordOfTheDayBottomSheet();
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF667eea).withOpacity(0.3),
                                      offset: const Offset(0, 8),
                                      blurRadius: 20.0,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(20.0),
                                            ),
                                            child: Text(
                                              '${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
                                              style: FlutterFlowTheme.of(context).bodySmall.override(
                                                fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                color: Colors.white,
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.0,
                                                useGoogleFonts: GoogleFonts.asMap()
                                                    .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12.0),
                                          Text(
                                            _model.wordOfTheDay?.word ?? 'Hello',
                                            style: FlutterFlowTheme.of(context).headlineMedium.override(
                                              fontFamily: FlutterFlowTheme.of(context).headlineMediumFamily,
                                              color: Colors.white,
                                              fontSize: 28.0,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.0,
                                              useGoogleFonts: GoogleFonts.asMap()
                                                  .containsKey(FlutterFlowTheme.of(context).headlineMediumFamily),
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            _model.wordOfTheDay?.meaning ?? 'A greeting used when meeting someone',
                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                              fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 14.0,
                                              letterSpacing: 0.0,
                                              useGoogleFonts: GoogleFonts.asMap()
                                                  .containsKey(FlutterFlowTheme.of(context).bodyMediumFamily),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 12.0),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(16.0),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.play_arrow,
                                                      color: Colors.white,
                                                      size: 16.0,
                                                    ),
                                                    const SizedBox(width: 4.0),
                                                    Text(
                                                      'Watch Sign',
                                                      style: FlutterFlowTheme.of(context).bodySmall.override(
                                                        fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                        color: Colors.white,
                                                        fontSize: 12.0,
                                                        fontWeight: FontWeight.w500,
                                                        letterSpacing: 0.0,
                                                        useGoogleFonts: GoogleFonts.asMap()
                                                            .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(16.0),
                                                ),
                                                child: Text(
                                                  _model.wordOfTheDay?.category ?? 'Greetings',
                                                  style: FlutterFlowTheme.of(context).bodySmall.override(
                                                    fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                    color: Colors.white,
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: 0.0,
                                                    useGoogleFonts: GoogleFonts.asMap()
                                                        .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16.0),
                                    Container(
                                      width: 80.0,
                                      height: 80.0,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16.0),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2.0,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.sign_language,
                                        color: Colors.white,
                                        size: 40.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Recently Viewed Section
                            if (_model.recentlyViewedSigns.isNotEmpty) ...[
                              const SizedBox(height: 32.0),
                              Text(
                                'Recently Viewed',
                                style: FlutterFlowTheme.of(context).titleLarge.override(
                                  fontFamily: FlutterFlowTheme.of(context).titleLargeFamily,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: GoogleFonts.asMap()
                                      .containsKey(FlutterFlowTheme.of(context).titleLargeFamily),
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              SizedBox(
                                height: 120.0,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _model.recentlyViewedSigns.length,
                                  itemBuilder: (context, index) {
                                    final sign = _model.recentlyViewedSigns[index];
                                    return GestureDetector(
                                      onTap: () {
                                        _model.viewSignDetails(sign);
                                        _showSignDetailsBottomSheet(sign);
                                      },
                                      child: Container(
                                        width: 100.0,
                                        margin: const EdgeInsets.only(right: 12.0),
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context).secondaryBackground,
                                          borderRadius: BorderRadius.circular(12.0),
                                          boxShadow: [
                                            BoxShadow(
                                              blurRadius: 4.0,
                                              color: Colors.black.withOpacity(0.1),
                                              offset: const Offset(0.0, 2.0),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.sign_language,
                                                size: 32.0,
                                                color: FlutterFlowTheme.of(context).primary,
                                              ),
                                              const SizedBox(height: 8.0),
                                              Text(
                                                sign.word,
                                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                                  fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts: GoogleFonts.asMap()
                                                      .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],

                            // Search Results Section
                            if (_model.textController!.text.isNotEmpty) ...[
                              const SizedBox(height: 32.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Search Results',
                                    style: FlutterFlowTheme.of(context).titleLarge.override(
                                      fontFamily: FlutterFlowTheme.of(context).titleLargeFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts: GoogleFonts.asMap()
                                          .containsKey(FlutterFlowTheme.of(context).titleLargeFamily),
                                    ),
                                  ),
                                  Text(
                                    '${_model.filteredSigns.length} found',
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
                              const SizedBox(height: 16.0),
                              if (_model.filteredSigns.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64.0,
                                        color: FlutterFlowTheme.of(context).secondaryText,
                                      ),
                                      const SizedBox(height: 16.0),
                                      Text(
                                        'No signs found',
                                        style: FlutterFlowTheme.of(context).titleMedium.override(
                                          fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
                                          color: FlutterFlowTheme.of(context).secondaryText,
                                          letterSpacing: 0.0,
                                          useGoogleFonts: GoogleFonts.asMap()
                                              .containsKey(FlutterFlowTheme.of(context).titleMediumFamily),
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        'Try searching with different keywords',
                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                          fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                                          color: FlutterFlowTheme.of(context).secondaryText,
                                          letterSpacing: 0.0,
                                          useGoogleFonts: GoogleFonts.asMap()
                                              .containsKey(FlutterFlowTheme.of(context).bodyMediumFamily),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: _model.filteredSigns.length,
                                  itemBuilder: (context, index) {
                                    final sign = _model.filteredSigns[index];
                                    return GestureDetector(
                                      onTap: () {
                                        _model.viewSignDetails(sign);
                                        _showSignDetailsBottomSheet(sign);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12.0),
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context).secondaryBackground,
                                          borderRadius: BorderRadius.circular(12.0),
                                          boxShadow: [
                                            BoxShadow(
                                              blurRadius: 4.0,
                                              color: Colors.black.withOpacity(0.1),
                                              offset: const Offset(0.0, 2.0),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 60.0,
                                              height: 60.0,
                                              decoration: BoxDecoration(
                                                color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8.0),
                                              ),
                                              child: Icon(
                                                Icons.sign_language,
                                                color: FlutterFlowTheme.of(context).primary,
                                                size: 32.0,
                                              ),
                                            ),
                                            const SizedBox(width: 16.0),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    sign.word,
                                                    style: FlutterFlowTheme.of(context).titleMedium.override(
                                                      fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0.0,
                                                      useGoogleFonts: GoogleFonts.asMap()
                                                          .containsKey(FlutterFlowTheme.of(context).titleMediumFamily),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4.0),
                                                  Text(
                                                    sign.description,
                                                    style: FlutterFlowTheme.of(context).bodySmall.override(
                                                      fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                      color: FlutterFlowTheme.of(context).secondaryText,
                                                      letterSpacing: 0.0,
                                                      useGoogleFonts: GoogleFonts.asMap()
                                                          .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8.0),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                                        decoration: BoxDecoration(
                                                          color: FlutterFlowTheme.of(context).accent1,
                                                          borderRadius: BorderRadius.circular(12.0),
                                                        ),
                                                        child: Text(
                                                          sign.category.toUpperCase(),
                                                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                                            fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                            color: FlutterFlowTheme.of(context).primary,
                                                            fontSize: 10.0,
                                                            fontWeight: FontWeight.w600,
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts: GoogleFonts.asMap()
                                                                .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8.0),
                                                      Row(
                                                        children: List.generate(3, (diffIndex) {
                                                          return Icon(
                                                            Icons.star,
                                                            size: 12.0,
                                                            color: diffIndex < sign.difficulty
                                                                ? FlutterFlowTheme.of(context).warning
                                                                : FlutterFlowTheme.of(context).secondaryText,
                                                          );
                                                        }),
                                                      ),
                                                    ],
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
                                    );
                                  },
                                ),
                            ],
                          ]
                              .divide(const SizedBox(height: 16.0))
                              .addToStart(const SizedBox(height: 16.0))
                              .addToEnd(const SizedBox(height: 36.0)),
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
                    sign.word,
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
                sign.description,
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
                        _model.markSignAsLearned(sign.id);
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
                      _model.toggleFavorite(sign.id);
                      safeSetState(() {});
                    },
                    icon: Icon(
                      sign.isFavorite ? Icons.favorite : Icons.favorite_border,
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
        height: MediaQuery.of(context).size.height * 0.6,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryText,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      'Word of the Day',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.0,
                        useGoogleFonts: GoogleFonts.asMap()
                            .containsKey(FlutterFlowTheme.of(context).bodySmallFamily),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
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
              
              const SizedBox(height: 24.0),
              
              // Word display
              Center(
                child: Container(
                  width: 150.0,
                  height: 150.0,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                        offset: const Offset(0, 8),
                        blurRadius: 20.0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sign_language,
                    color: Colors.white,
                    size: 80.0,
                  ),
                ),
              ),
              
              const SizedBox(height: 24.0),
              
              // Word details
              Center(
                child: Text(
                  _model.wordOfTheDay?.word ?? 'Hello',
                  style: FlutterFlowTheme.of(context).displaySmall.override(
                    fontFamily: FlutterFlowTheme.of(context).displaySmallFamily,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.0,
                    useGoogleFonts: GoogleFonts.asMap()
                        .containsKey(FlutterFlowTheme.of(context).displaySmallFamily),
                  ),
                ),
              ),
              
              const SizedBox(height: 12.0),
              
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    _model.wordOfTheDay?.category ?? 'Greetings',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                      color: FlutterFlowTheme.of(context).primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.0,
                      useGoogleFonts: GoogleFonts.asMap()
                          .containsKey(FlutterFlowTheme.of(context).bodyMediumFamily),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20.0),
              
              // Meaning
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
              
              const SizedBox(height: 8.0),
              
              Text(
                _model.wordOfTheDay?.meaning ?? 'A greeting used when meeting someone for the first time or when acknowledging their presence.',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  letterSpacing: 0.0,
                  useGoogleFonts: GoogleFonts.asMap()
                      .containsKey(FlutterFlowTheme.of(context).bodyMediumFamily),
                ),
              ),
              
              const Spacer(),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Play sign video
                      },
                      icon: const Icon(Icons.play_arrow, size: 20.0),
                      label: const Text('Watch Sign'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlutterFlowTheme.of(context).primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Add to favorites
                        _model.toggleFavoriteWordOfTheDay();
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        _model.wordOfTheDay?.isFavorite == true 
                          ? Icons.favorite 
                          : Icons.favorite_border,
                        size: 20.0,
                      ),
                      label: const Text('Favorite'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FlutterFlowTheme.of(context).primary,
                        side: BorderSide(color: FlutterFlowTheme.of(context).primary),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
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
    );
  }
}
