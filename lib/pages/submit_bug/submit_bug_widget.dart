import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'submit_bug_model.dart';
export 'submit_bug_model.dart';

class SubmitBugWidget extends StatefulWidget {
  const SubmitBugWidget({super.key});

  @override
  State<SubmitBugWidget> createState() => _SubmitBugWidgetState();
}

class _SubmitBugWidgetState extends State<SubmitBugWidget> {
  late SubmitBugModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubmitBugModel());

    _model.bugSubmitTextController ??= TextEditingController();
    _model.bugSubmitFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        automaticallyImplyLeading: false,
        leading: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FlutterFlowIconButton(
              borderColor: Colors.transparent,
              borderRadius: 100.0,
              buttonSize: 50.0,
              hoverColor: FlutterFlowTheme.of(context).secondaryBackground,
              hoverIconColor: FlutterFlowTheme.of(context).primaryText,
              icon: Icon(
                Icons.arrow_back_ios,
                color: FlutterFlowTheme.of(context).primaryText,
                size: 24.0,
              ),
              onPressed: () async {
                context.pushNamed(
                  'account4',
                  extra: <String, dynamic>{
                    kTransitionInfoKey: const TransitionInfo(
                      hasTransition: true,
                      transitionType: PageTransitionType.leftToRight,
                      duration: Duration(milliseconds: 200),
                    ),
                  },
                );
              },
            ),
            Text(
              FFLocalizations.of(context).getText(
                '4w6sqkk0' /* Submit a Bug */,
              ),
              textAlign: TextAlign.start,
              style: FlutterFlowTheme.of(context).headlineSmall.override(
                    fontFamily: 'Space Grotesk',
                    letterSpacing: 0.0,
                    useGoogleFonts:
                        GoogleFonts.asMap().containsKey('Space Grotesk'),
                  ),
            ),
          ],
        ),
        actions: const [],
        centerTitle: false,
        elevation: 0.0,
      ),
      body: Align(
        alignment: const AlignmentDirectional(0.0, -1.0),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxWidth: 570.0,
          ),
          decoration: const BoxDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // This row exists for when the "app bar" is hidden on desktop, having a way back for the user can work well.
              if (responsiveVisibility(
                context: context,
                phone: false,
                tablet: false,
              ))
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 8.0),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      context.safePop();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 12.0, 0.0, 12.0),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              12.0, 0.0, 0.0, 0.0),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              'mlua77zx' /* Back */,
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .bodyMediumFamily,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: GoogleFonts.asMap()
                                      .containsKey(FlutterFlowTheme.of(context)
                                          .bodyMediumFamily),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16.0, 20.0, 16.0, 4.0),
                child: Text(
                  FFLocalizations.of(context).getText(
                    'pq65pza0' /* Oops! Found something that’s n... */,
                  ),
                  style: FlutterFlowTheme.of(context).labelLarge.override(
                        fontFamily:
                            FlutterFlowTheme.of(context).labelLargeFamily,
                        letterSpacing: 0.0,
                        useGoogleFonts: GoogleFonts.asMap().containsKey(
                            FlutterFlowTheme.of(context).labelLargeFamily),
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16.0, 30.0, 16.0, 30.0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextFormField(
                    controller: _model.bugSubmitTextController,
                    focusNode: _model.bugSubmitFocusNode,
                    onChanged: (_) => EasyDebounce.debounce(
                      '_model.bugSubmitTextController',
                      const Duration(milliseconds: 2000),
                      () => safeSetState(() {}),
                    ),
                    onFieldSubmitted: (_) async {
                      await BugReportRecord.createDoc(currentUserReference!)
                          .set(createBugReportRecordData(
                        description: _model.bugSubmitTextController.text,
                      ));
                    },
                    textInputAction: TextInputAction.done,
                    obscureText: false,
                    decoration: InputDecoration(
                      isDense: false,
                      labelText: FFLocalizations.of(context).getText(
                        'a5563aii' /* Bug Description.... */,
                      ),
                      labelStyle: FlutterFlowTheme.of(context)
                          .labelMedium
                          .override(
                            fontFamily:
                                FlutterFlowTheme.of(context).labelMediumFamily,
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            useGoogleFonts: GoogleFonts.asMap().containsKey(
                                FlutterFlowTheme.of(context).labelMediumFamily),
                            lineHeight: 0.0,
                          ),
                      hintText: FFLocalizations.of(context).getText(
                        'vki7snxy' /* Describe the issue in detail..... */,
                      ),
                      hintStyle: FlutterFlowTheme.of(context)
                          .labelMedium
                          .override(
                            fontFamily:
                                FlutterFlowTheme.of(context).labelMediumFamily,
                            letterSpacing: 0.0,
                            useGoogleFonts: GoogleFonts.asMap().containsKey(
                                FlutterFlowTheme.of(context).labelMediumFamily),
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
                      fillColor: FlutterFlowTheme.of(context).primaryBackground,
                      contentPadding: const EdgeInsets.all(24.0),
                      hoverColor:
                          FlutterFlowTheme.of(context).primaryBackground,
                      prefixIcon: Icon(
                        Icons.bug_report,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 24.0,
                      ),
                      suffixIcon:
                          _model.bugSubmitTextController!.text.isNotEmpty
                              ? InkWell(
                                  onTap: () async {
                                    _model.bugSubmitTextController?.clear();
                                    safeSetState(() {});
                                  },
                                  child: const Icon(
                                    Icons.clear,
                                    color: Color(0xFF757575),
                                    size: 24.0,
                                  ),
                                )
                              : null,
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily:
                              FlutterFlowTheme.of(context).bodyMediumFamily,
                          letterSpacing: 0.0,
                          useGoogleFonts: GoogleFonts.asMap().containsKey(
                              FlutterFlowTheme.of(context).bodyMediumFamily),
                          lineHeight: 2.0,
                        ),
                    maxLines: 16,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    cursorColor: FlutterFlowTheme.of(context).primary,
                    validator: _model.bugSubmitTextControllerValidator
                        .asValidator(context),
                  ),
                ),
              ),
              Align(
                alignment: const AlignmentDirectional(0.0, 0.0),
                child: FFButtonWidget(
                  onPressed: () async {
                    await BugReportRecord.createDoc(currentUserReference!)
                        .set(createBugReportRecordData(
                      description: _model.bugSubmitTextController.text,
                    ));
                  },
                  text: FFLocalizations.of(context).getText(
                    'wf02ugj6' /* Submit Bug */,
                  ),
                  options: FFButtonOptions(
                    width: 260.0,
                    height: 50.0,
                    padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    iconPadding:
                        const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context)
                        .titleMedium
                        .override(
                          fontFamily:
                              FlutterFlowTheme.of(context).titleMediumFamily,
                          color: FlutterFlowTheme.of(context).customColor5,
                          letterSpacing: 0.0,
                          useGoogleFonts: GoogleFonts.asMap().containsKey(
                              FlutterFlowTheme.of(context).titleMediumFamily),
                        ),
                    elevation: 2.0,
                    borderRadius: BorderRadius.circular(12.0),
                    hoverColor: FlutterFlowTheme.of(context).secondary,
                    hoverBorderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                    hoverTextColor: FlutterFlowTheme.of(context).primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
