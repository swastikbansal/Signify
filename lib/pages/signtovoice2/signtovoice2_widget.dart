import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/walkthroughs/signify_screen_2.dart';
import 'signtovoice2_model.dart';
export 'signtovoice2_model.dart';
import 'skeleton_overlay.dart'; // Import our skeleton overlay
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
    with RouteAware, TickerProviderStateMixin {
  late Signtovoice2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation controllers for Google Assistant-like glow animation
  late AnimationController _glowController;
  late AnimationController _movingLineController;
  late Animation<double> _movingLineAnimation;
  bool isGlowActive = false;
  bool isSpeakerOn = false; // Add speaker toggle state
  int _lastLandmarkCount = 0; // Track landmark changes

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Signtovoice2Model());

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

    // Initialize animation controllers for glow effect
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _movingLineController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _movingLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _movingLineController,
      curve: Curves.easeInOutQuart,
    ));

    // Listen to text changes to trigger glow animation
    _model.textController?.addListener(() {
      final currentText = _model.textController?.text ?? '';
      if (currentText.isNotEmpty && !isGlowActive) {
        _triggerGlowAnimation();
      }
    });

    // Listen to model state changes to trigger animation on pose detection
    _model.setStateChangeCallback(() {
      try {
        if (mounted) {
          // Calculate current landmark count
          int currentLandmarkCount =
              _model.handLandmarks.length + _model.poseLandmarks.length;

          // Trigger animation when new poses/hands are detected (landmark count changes)
          if (currentLandmarkCount > 0 &&
              currentLandmarkCount != _lastLandmarkCount &&
              _model.isDetecting &&
              !isGlowActive) {
            _triggerGlowAnimation();
            _lastLandmarkCount = currentLandmarkCount;
          }

          // Also trigger when text changes
          final currentText = _model.textController?.text ?? '';
          if (currentText.isNotEmpty && !isGlowActive) {
            _triggerGlowAnimation();
          }

          safeSetState(() {});
        }
      } catch (e) {
        print('Error updating UI state: $e');
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _glowController.dispose();
    _movingLineController.dispose();
    super.dispose();
  }

  // Method to trigger the Google Assistant-like glow animation
  void _triggerGlowAnimation() {
    if (!mounted) return;

    setState(() {
      isGlowActive = true;
    });

    _movingLineController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          isGlowActive = false;
        });
        _movingLineController.reset();
      }
    });
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
        body: Stack(
          children: [
            // Full screen camera view without borders or padding
            Container(
              width: double.infinity,
              height: double.infinity,
              color: FlutterFlowTheme.of(context).primaryBackground,
              child: _model.isCameraOn || _model.isDetecting
                  ? _buildMediaPipeDisplay()
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 80.0,
                            color: FlutterFlowTheme.of(context).info,
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            'Press camera button to start MediaPipe detection',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .bodyMediumFamily,
                                  color: FlutterFlowTheme.of(context).info,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: GoogleFonts.asMap()
                                      .containsKey(FlutterFlowTheme.of(context)
                                          .bodyMediumFamily),
                                ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Floating control panel positioned above bottom nav - Claude AI style
            Positioned(
              bottom:
                  12.0, // Position just above bottom nav bar (optimal spacing)
              left: 8.0,
              right: 8.0,
              child: Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).alternate,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Moving line animation overlay (Google Assistant-like)
                    if (isGlowActive)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _movingLineAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                              child: CustomPaint(
                                painter: MovingLinePainter(
                                  progress: _movingLineAnimation.value,
                                  color: const Color(
                                      0xFFFAB317), // App yellow color
                                  strokeWidth: 3.0,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    // Main content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Text field area (full width like Claude AI)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 16.0,
                          ),
                          child: TextFormField(
                            controller: _model.textController,
                            focusNode: _model.textFieldFocusNode,
                            autofocus: false,
                            readOnly: true,
                            textCapitalization: TextCapitalization.sentences,
                            obscureText: false,
                            decoration: InputDecoration(
                              hintText: 'Translated Text Appear Here',
                              hintStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodyMediumFamily,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    useGoogleFonts: GoogleFonts.asMap()
                                        .containsKey(
                                            FlutterFlowTheme.of(context)
                                                .bodyMediumFamily),
                                  ),
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .bodyMediumFamily,
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: GoogleFonts.asMap()
                                      .containsKey(FlutterFlowTheme.of(context)
                                          .bodyMediumFamily),
                                  lineHeight: 1.4,
                                ),
                            textAlign: TextAlign.start,
                            maxLines: 6, // Allow expansion up to 10 lines
                            minLines: 1,
                            keyboardType: TextInputType.multiline,
                            cursorColor: FlutterFlowTheme.of(context).primary,
                          ),
                        ),

                        // Button row below text field (Claude AI style)
                        Container(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            bottom: 16.0,
                          ),
                          child: Row(
                            children: [
                              // Modern Android-style scrollable language dropdown
                              Container(
                                margin: const EdgeInsets.only(right: 12.0),
                                child: ModernDropDown(
                                  value: _model.dropDownValue ?? 'English',
                                  options: [
                                    FFLocalizations.of(context)
                                        .getText('rpno13ax' /* English */),
                                    FFLocalizations.of(context)
                                        .getText('poexbjj4' /* Hindi */),
                                    FFLocalizations.of(context)
                                        .getText('qtkvhy1f' /* Bengali */),
                                    FFLocalizations.of(context)
                                        .getText('u9ln63gu' /* Marathi */),
                                    FFLocalizations.of(context)
                                        .getText('b33de32b' /* Telugu */),
                                    FFLocalizations.of(context)
                                        .getText('fpa9yid6' /* Tamil */),
                                    FFLocalizations.of(context)
                                        .getText('hann7xcl' /* Gujarati */),
                                    FFLocalizations.of(context)
                                        .getText('qshr5rcb' /* Punjabi */),
                                    FFLocalizations.of(context)
                                        .getText('zw3yahpp' /* Urdu */),
                                    FFLocalizations.of(context)
                                        .getText('f1lmzpqr' /* Kannada */),
                                    FFLocalizations.of(context)
                                        .getText('o714o7gt' /* Malayalam */),
                                  ],
                                  onChanged: (val) => safeSetState(
                                      () => _model.dropDownValue = val),
                                  width: 90.0,
                                  height: 36.0,
                                ).addWalkthrough(
                                  dropDownB9wm9jo8,
                                  _model.signifyScreen2Controller,
                                ),
                              ),

                              // Speaker toggle button with state
                              Container(
                                margin: const EdgeInsets.only(right: 8.0),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8.0),
                                    onTap: () {
                                      setState(() {
                                        isSpeakerOn = !isSpeakerOn;
                                      });
                                      print(
                                          'Speaker toggle: ${isSpeakerOn ? "ON" : "OFF"}');
                                    },
                                    child: Container(
                                      width: 42.0,
                                      height: 42.0,
                                      child: Icon(
                                        isSpeakerOn
                                            ? Icons.volume_up_rounded
                                            : Icons.volume_off_rounded,
                                        color: isSpeakerOn
                                            ? const Color(0xFFFAB317)
                                            : FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        size: 24.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Camera toggle button (no border)
                              Container(
                                margin: const EdgeInsets.only(right: 8.0),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8.0),
                                    onTap: () async {
                                      await _model.toggleDetection();
                                      safeSetState(() {});
                                    },
                                    child: Container(
                                      width: 42.0,
                                      height: 42.0,
                                      child: Icon(
                                        _model.isDetecting
                                            ? Icons.stop_rounded
                                            : Icons.camera_alt_rounded,
                                        color: _model.isDetecting
                                            ? const Color(0xFFFAB317)
                                            : FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        size: 24.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ).addWalkthrough(
                                iconButtonPl161kuq,
                                _model.signifyScreen2Controller,
                              ),

                              // Pose overlay toggle button (no border)
                              Container(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8.0),
                                    onTap: () {
                                      _model.setSkeletonOverlayEnabled(
                                          !_model.isSkeletonOverlayEnabled);
                                      safeSetState(() {});
                                    },
                                    child: Container(
                                      width: 42.0,
                                      height: 42.0,
                                      child: Icon(
                                        _model.isSkeletonOverlayEnabled
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                        color: _model.isSkeletonOverlayEnabled
                                            ? const Color(0xFFFAB317)
                                            : FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        size: 24.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                          // Flutter Camera Preview with mirroring for front camera
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: _model.isFrontCamera
                                  ? Matrix4.rotationY(
                                      3.14159) // Mirror horizontally for front camera
                                  : Matrix4.identity(),
                              child: CameraPreview(_model.cameraController!),
                            ),
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

// Custom painter for moving line animation (Google Assistant/Gemini style)
class MovingLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  MovingLinePainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0) return;

    final path = Path();

    // Create a moving line animation around the container
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16.0),
    );

    // Calculate the perimeter path
    path.addRRect(rect);

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      final length = pathMetric.length;

      // Single line animation that travels around the complete perimeter
      if (progress < 0.85) {
        // Moving phase: single solid line travels around the perimeter
        final lineLength =
            length * 0.2; // Line covers 20% of perimeter for better visibility
        final startDistance = (progress / 0.85) *
            length; // Travel full perimeter in first 85% of animation

        final extractedPath = pathMetric.extractPath(
          startDistance % length,
          (startDistance + lineLength) % length,
        );

        // Simple solid yellow paint - no glow effects (like voice to sign)
        final paint = Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawPath(extractedPath, paint);
      } else {
        // Completion glow phase: full perimeter glows out with solid color
        final glowProgress = (progress - 0.85) / 0.15; // Last 15% of animation
        final glowIntensity = 1.0 - glowProgress; // Fade out the glow

        // Draw the complete path with solid color fading
        final completionPaint = Paint()
          ..color = color.withOpacity(glowIntensity)
          ..strokeWidth = strokeWidth * 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawPath(path, completionPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MovingLinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// Modern Android-style scrollable dropdown widget
class ModernDropDown extends StatefulWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final double width;
  final double height;

  const ModernDropDown({
    Key? key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  State<ModernDropDown> createState() => _ModernDropDownState();
}

class _ModernDropDownState extends State<ModernDropDown>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (_isExpanded) {
      _collapseDropdown();
    } else {
      _expandDropdown();
    }
  }

  void _expandDropdown() {
    setState(() {
      _isExpanded = true;
    });

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    // Calculate dropdown height to position it above
    const double maxDropdownHeight = 200.0;
    final double dropdownHeight =
        (widget.options.length * 40.0).clamp(0.0, maxDropdownHeight);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy - dropdownHeight - 4, // Position above with 4px gap
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: FlutterFlowTheme.of(context).secondaryBackground,
          shadowColor: Colors.black26,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: 200, // Scrollable if more than 5 items (40 each)
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: FlutterFlowTheme.of(context).alternate,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Scrollbar(
                thumbVisibility: widget.options.length > 5,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: widget.options.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: FlutterFlowTheme.of(context).alternate,
                  ),
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final isSelected = option == widget.value;

                    return InkWell(
                      onTap: () {
                        widget.onChanged(option);
                        _collapseDropdown();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        color: isSelected
                            ? FlutterFlowTheme.of(context)
                                .accent1
                                .withOpacity(0.1)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodySmallFamily,
                                      color: isSelected
                                          ? FlutterFlowTheme.of(context).primary
                                          : FlutterFlowTheme.of(context)
                                              .primaryText,
                                      fontSize: 12.0,
                                      letterSpacing: 0.0,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      useGoogleFonts: GoogleFonts.asMap()
                                          .containsKey(
                                              FlutterFlowTheme.of(context)
                                                  .bodySmallFamily),
                                    ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: FlutterFlowTheme.of(context).primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _collapseDropdown() {
    setState(() {
      _isExpanded = false;
    });
    _animationController.reverse().then((_) {
      _removeOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleDropdown,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: _isExpanded
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).alternate,
            width: _isExpanded ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (_isExpanded)
              BoxShadow(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.value,
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontSize: 12.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                      useGoogleFonts: GoogleFonts.asMap().containsKey(
                          FlutterFlowTheme.of(context).bodySmallFamily),
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _isExpanded
                    ? FlutterFlowTheme.of(context).primary
                    : FlutterFlowTheme.of(context).secondaryText,
                size: 16.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
