import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/walkthroughs/signify_screen_2.dart';
import 'signtovoice2_model.dart';
export 'signtovoice2_model.dart';
import 'skeleton_overlay.dart'; // Import our skeleton overlay
import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

class Signtovoice2Widget extends StatefulWidget {
  const Signtovoice2Widget({super.key});

  @override
  State<Signtovoice2Widget> createState() => _Signtovoice2WidgetState();
}

class _Signtovoice2WidgetState extends State<Signtovoice2Widget>
    with RouteAware {
  late Signtovoice2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Signtovoice2Model());

    // Set up state change callback for MediaPipe updates with error handling
    _model.setStateChangeCallback(() {
      try {
        if (mounted) {
          safeSetState(() {});
        }
      } catch (e) {
        print('Error updating UI state: $e');
      }
    });

    // On page load action with error handling
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        if (dateTimeFormat(
              "relative",
              currentUserDocument?.loggedinTime,
              locale: FFLocalizations.of(context).languageCode,
            ) ==
            dateTimeFormat(
              "relative",
              getCurrentTimestamp,
              locale: FFLocalizations.of(context).languageCode,
            )) {
          safeSetState(() =>
              _model.signifyScreen2Controller = createPageWalkthrough(context));
          _model.signifyScreen2Controller?.show(context: context);
          return;
        } else {
          return;
        }
      } catch (e) {
        print('Error in page load action: $e');
      }
    });

    try {
      _model.textController ??= TextEditingController()
        ..addListener(() {
          debugLogWidgetClass(_model);
        });
      _model.textFieldFocusNode ??= FocusNode();
    } catch (e) {
      print('Error initializing text controller: $e');
    }
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        width: 2.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: _model.isDetecting
                          ? _buildMediaPipeDisplay()
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 80.0,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                  ),
                                  SizedBox(height: 16.0),
                                  Text(
                                    'Press camera button to start MediaPipe detection',
                                    textAlign: TextAlign.center,
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
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AlignedTooltip(
                          content: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'yf3qurjr' /* Select your Regional Language ... */,
                              ),
                              style: FlutterFlowTheme.of(context)
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
                            ),
                          ),
                          offset: 4.0,
                          preferredDirection: AxisDirection.up,
                          borderRadius: BorderRadius.circular(12.0),
                          backgroundColor:
                              FlutterFlowTheme.of(context).alternate,
                          elevation: 4.0,
                          tailBaseWidth: 24.0,
                          tailLength: 24.0,
                          waitDuration: Duration(milliseconds: 10),
                          showDuration: Duration(milliseconds: 2000),
                          triggerMode: TooltipTriggerMode.longPress,
                          child: FlutterFlowDropDown<String>(
                            controller: _model.dropDownValueController ??=
                                FormFieldController<String>(null),
                            options: [
                              FFLocalizations.of(context).getText(
                                'rpno13ax' /* English */,
                              ),
                              FFLocalizations.of(context).getText(
                                'poexbjj4' /* Hindi */,
                              ),
                              FFLocalizations.of(context).getText(
                                'qtkvhy1f' /* Bengali */,
                              ),
                              FFLocalizations.of(context).getText(
                                'u9ln63gu' /* Marathi */,
                              ),
                              FFLocalizations.of(context).getText(
                                'b33de32b' /* Telugu */,
                              ),
                              FFLocalizations.of(context).getText(
                                'fpa9yid6' /* Tamil */,
                              ),
                              FFLocalizations.of(context).getText(
                                'hann7xcl' /* Gujarati */,
                              ),
                              FFLocalizations.of(context).getText(
                                'qshr5rcb' /* Punjabi */,
                              ),
                              FFLocalizations.of(context).getText(
                                'zw3yahpp' /* Urdu */,
                              ),
                              FFLocalizations.of(context).getText(
                                'f1lmzpqr' /* Kannada */,
                              ),
                              FFLocalizations.of(context).getText(
                                'o714o7gt' /* Malayalam */,
                              )
                            ],
                            onChanged: (val) =>
                                safeSetState(() => _model.dropDownValue = val),
                            width: 180.0,
                            height: 50.0,
                            textStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .labelMediumFamily,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: GoogleFonts.asMap()
                                      .containsKey(FlutterFlowTheme.of(context)
                                          .labelMediumFamily),
                                ),
                            hintText: FFLocalizations.of(context).getText(
                              'drx645ue' /* Select Language */,
                            ),
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 24.0,
                            ),
                            fillColor: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            elevation: 4.0,
                            borderColor: FlutterFlowTheme.of(context).alternate,
                            borderWidth: 1.0,
                            borderRadius: 12.0,
                            margin: EdgeInsets.all(12.0),
                            hidesUnderline: true,
                            isOverButton: false,
                            isSearchable: false,
                            isMultiSelect: false,
                          ).addWalkthrough(
                            dropDownB9wm9jo8,
                            _model.signifyScreen2Controller,
                          ),
                        ),
                        AlignedTooltip(
                          content: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Press to toggle MediaPipe detection',
                              style: FlutterFlowTheme.of(context)
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
                            ),
                          ),
                          offset: 4.0,
                          preferredDirection: AxisDirection.up,
                          borderRadius: BorderRadius.circular(12.0),
                          backgroundColor:
                              FlutterFlowTheme.of(context).alternate,
                          elevation: 4.0,
                          tailBaseWidth: 24.0,
                          tailLength: 24.0,
                          waitDuration: Duration(milliseconds: 10),
                          showDuration: Duration(milliseconds: 2000),
                          triggerMode: TooltipTriggerMode.longPress,
                          child: FlutterFlowIconButton(
                            borderRadius: 50.0,
                            buttonSize: 50.0,
                            fillColor: _model.isDetecting
                                ? FlutterFlowTheme.of(context).primary
                                : FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                            hoverColor:
                                FlutterFlowTheme.of(context).primaryBackground,
                            hoverIconColor:
                                FlutterFlowTheme.of(context).primary,
                            icon: Icon(
                              _model.isDetecting
                                  ? Icons.stop
                                  : Icons.camera_alt,
                              color: _model.isDetecting
                                  ? FlutterFlowTheme.of(context)
                                      .primaryBackground
                                  : FlutterFlowTheme.of(context).primaryText,
                              size: 24.0,
                            ),
                            onPressed: () async {
                              await _model.toggleDetection();
                              safeSetState(() {});
                            },
                          ).addWalkthrough(
                            iconButtonPl161kuq,
                            _model.signifyScreen2Controller,
                          ),
                        ),
                        AlignedTooltip(
                          content: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'w8aykljz' /* Press the speaker button, to g... */,
                              ),
                              style: FlutterFlowTheme.of(context)
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
                            ),
                          ),
                          offset: 4.0,
                          preferredDirection: AxisDirection.up,
                          borderRadius: BorderRadius.circular(12.0),
                          backgroundColor:
                              FlutterFlowTheme.of(context).alternate,
                          elevation: 4.0,
                          tailBaseWidth: 24.0,
                          tailLength: 24.0,
                          waitDuration: Duration(milliseconds: 10),
                          showDuration: Duration(milliseconds: 2000),
                          triggerMode: TooltipTriggerMode.longPress,
                          child: FlutterFlowIconButton(
                            borderRadius: 50.0,
                            buttonSize: 50.0,
                            fillColor: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            hoverColor:
                                FlutterFlowTheme.of(context).primaryBackground,
                            hoverIconColor:
                                FlutterFlowTheme.of(context).primary,
                            icon: Icon(
                              Icons.volume_up,
                              color: FlutterFlowTheme.of(context).primaryText,
                              size: 24.0,
                            ),
                            onPressed: () {
                              print('IconButton pressed ...');
                            },
                          ).addWalkthrough(
                            iconButton9jd3gtk2,
                            _model.signifyScreen2Controller,
                          ),
                        ),
                        // Skeleton overlay toggle button
                        AlignedTooltip(
                          content: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Toggle skeleton overlay visualization',
                              style: FlutterFlowTheme.of(context)
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
                            ),
                          ),
                          offset: 4.0,
                          preferredDirection: AxisDirection.up,
                          borderRadius: BorderRadius.circular(12.0),
                          backgroundColor:
                              FlutterFlowTheme.of(context).alternate,
                          elevation: 4.0,
                          tailBaseWidth: 24.0,
                          tailLength: 24.0,
                          waitDuration: Duration(milliseconds: 10),
                          showDuration: Duration(milliseconds: 2000),
                          triggerMode: TooltipTriggerMode.longPress,
                          child: FlutterFlowIconButton(
                            borderRadius: 50.0,
                            buttonSize: 50.0,
                            fillColor: _model.isSkeletonOverlayEnabled
                                ? FlutterFlowTheme.of(context).primary
                                : FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                            hoverColor:
                                FlutterFlowTheme.of(context).primaryBackground,
                            hoverIconColor:
                                FlutterFlowTheme.of(context).primary,
                            icon: Icon(
                              _model.isSkeletonOverlayEnabled
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: _model.isSkeletonOverlayEnabled
                                  ? FlutterFlowTheme.of(context)
                                      .primaryBackground
                                  : FlutterFlowTheme.of(context).primaryText,
                              size: 24.0,
                            ),
                            onPressed: () {
                              _model.setSkeletonOverlayEnabled(
                                  !_model.isSkeletonOverlayEnabled);
                              safeSetState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              elevation: 4.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(0.0),
                                  bottomRight: Radius.circular(0.0),
                                  topLeft: Radius.circular(36.0),
                                  topRight: Radius.circular(36.0),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 0.0,
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                      offset: Offset(
                                        0.0,
                                        0.0,
                                      ),
                                      spreadRadius: 2.0,
                                    )
                                  ],
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(0.0),
                                    bottomRight: Radius.circular(0.0),
                                    topLeft: Radius.circular(36.0),
                                    topRight: Radius.circular(36.0),
                                  ),
                                  shape: BoxShape.rectangle,
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    width: 1.0,
                                  ),
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: TextFormField(
                                      controller: _model.textController,
                                      focusNode: _model.textFieldFocusNode,
                                      autofocus: false,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      readOnly: true,
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        isDense: false,
                                        alignLabelWithHint: false,
                                        hintText:
                                            FFLocalizations.of(context).getText(
                                          'nt3iz8g2' /* Translated Text */,
                                        ),
                                        hintStyle: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .titleLargeFamily,
                                              letterSpacing: 0.0,
                                              useGoogleFonts: GoogleFonts
                                                      .asMap()
                                                  .containsKey(
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleLargeFamily),
                                              lineHeight: 1.0,
                                            ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0x00000000),
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0x00000000),
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0x00000000),
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0x00000000),
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                        ),
                                        hoverColor: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .titleLargeFamily,
                                            letterSpacing: 0.0,
                                            useGoogleFonts: GoogleFonts.asMap()
                                                .containsKey(
                                                    FlutterFlowTheme.of(context)
                                                        .titleLargeFamily),
                                            lineHeight: 1.0,
                                          ),
                                      textAlign: TextAlign.center,
                                      maxLines: 10,
                                      minLines: 2,
                                      cursorColor:
                                          FlutterFlowTheme.of(context).primary,
                                      validator: _model.textControllerValidator
                                          .asValidator(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ].divide(SizedBox(height: 24.0)),
                ).addWalkthrough(
                  column7du8ugv9,
                  _model.signifyScreen2Controller,
                ),
              ),
            ].divide(SizedBox(height: 16.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPipeDisplay() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Minimal status indicator
          Container(
            padding: EdgeInsets.all(4.0),
            color: _model.isDetecting
                ? Colors.green.withOpacity(0.8)
                : Colors.orange.withOpacity(0.8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _model.isDetecting
                      ? Icons.fiber_manual_record
                      : Icons.pause_circle_outline,
                  color: Colors.white,
                  size: 12,
                ),
                SizedBox(width: 4),
                Text(
                  _model.isDetecting ? 'LIVE' : 'PAUSED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Live camera feed area with Flutter CameraPreview
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0.0),
                child: _model.isCameraOn && _model.isCameraInitialized
                    ? Stack(
                        children: [
                          // Flutter Camera Preview
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            child: CameraPreview(_model.cameraController!),
                          ),
                          // MediaPipe Skeleton Overlay
                          if (_model.isDetecting &&
                              _model.isSkeletonOverlayEnabled &&
                              (_model.handLandmarks.isNotEmpty ||
                                  _model.poseLandmarks.isNotEmpty))
                            Positioned.fill(
                              child: SkeletonOverlay(
                                handLandmarks: _model.handLandmarks,
                                poseLandmarks: _model.poseLandmarks,
                                handLabels: _model.handLabels,
                                cameraAspectRatio: _model.cameraAspectRatio,
                                isFrontCamera: _model.isFrontCamera,
                                useCoordinateTransformation:
                                    _model.useCoordinateTransformation,
                                onDebugTap: () {
                                  _model.debugCoordinateAlignment();
                                  _model.setUseCoordinateTransformation(
                                      !_model.useCoordinateTransformation);
                                  print(
                                      'Coordinate transformation toggled: ${_model.useCoordinateTransformation}');
                                },
                              ),
                            ),
                          // MediaPipe landmarks overlay (minimal)
                          if (_model.isDetecting)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'H:${_model.handLandmarks.length} P:${_model.poseLandmarks.length}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          // Landmarks printing indicator
                          if (_model.isDetecting)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _model.isSkeletonOverlayEnabled
                                      ? 'Skeleton Overlay Active'
                                      : 'Tracking Active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 80.0,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              _model.isCameraOn
                                  ? 'Initializing camera...'
                                  : 'Press camera button to start',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_model.errorMessage.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(
                                'Error: ${_model.errorMessage}',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TutorialCoachMark createPageWalkthrough(BuildContext context) =>
      TutorialCoachMark(
        targets: createWalkthroughTargets(context),
        onFinish: () async {
          safeSetState(() => _model.signifyScreen2Controller = null);
        },
        onSkip: () {
          return true;
        },
      );
}
