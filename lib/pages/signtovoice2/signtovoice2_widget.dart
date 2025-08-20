import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'signtovoice2_model.dart';
export 'signtovoice2_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;

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

  // ScrollController for auto-scroll functionality
  late ScrollController _textFieldScrollController;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Signtovoice2Model());

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

    // Initialize scroll controller for auto-scroll functionality
    _textFieldScrollController = ScrollController();

    // Listen to text changes to trigger glow animation and auto-scroll
    _model.textController?.addListener(() {
      final currentText = _model.textController?.text ?? '';
      if (currentText.isNotEmpty && !isGlowActive) {
        _triggerGlowAnimation();
      }
      // Auto-scroll to bottom when text changes
      _autoScrollToBottom();
    });

    // Listen to model state changes to trigger animation on pose detection
    _model.setStateChangeCallback(() {
      try {
        if (mounted) {
          // Trigger glow animation when detection state changes
          if (_model.isDetecting && !_glowController.isAnimating) {
            _startGlowAnimation();
          } else if (!_model.isDetecting && _glowController.isAnimating) {
            _stopGlowAnimation();
          }

          // Also trigger when text changes
          final currentText = _model.textController?.text ?? '';
          if (currentText.isNotEmpty && !isGlowActive) {
            _triggerGlowAnimation();
          }

          // Auto-scroll when state changes (new words added programmatically)
          _autoScrollToBottom();

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
    _textFieldScrollController.dispose();
    super.dispose();
  }

  // Method to auto-scroll to bottom like ChatGPT
  void _autoScrollToBottom() {
    if (!_textFieldScrollController.hasClients) {
      return;
    }

    // Use a small delay to ensure the text field has been updated and rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _textFieldScrollController.hasClients) {
        // Check if we need to scroll (if there's content beyond the current view)
        final currentScrollPosition =
            _textFieldScrollController.position.pixels;
        final maxScrollExtent =
            _textFieldScrollController.position.maxScrollExtent;

        // Only scroll if we're not already at the bottom or if there's new content
        if (maxScrollExtent > 0 &&
            (maxScrollExtent - currentScrollPosition) > 10) {
          _textFieldScrollController.animateTo(
            maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  // Method to start continuous glow animation for API processing
  void _startGlowAnimation() {
    if (!mounted) return;
    _glowController.repeat();
  }

  // Method to stop glow animation
  void _stopGlowAnimation() {
    if (!mounted) return;
    _glowController.stop();
    _glowController.reset();
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
                  ? _buildCameraDisplay()
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 80.0,
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'Press camera button to start detection',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .bodyMediumFamily,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
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

            // Floating control panel positioned above bottom nav - Claude AI style with acrylic transparency
            Positioned(
              bottom:
                  12.0, // Position just above bottom nav bar (optimal spacing)
              left: 8.0,
              right: 8.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    decoration: BoxDecoration(
                      // Acrylic glass effect with transparency like Windows/Grok AI
                      color: FlutterFlowTheme.of(context)
                          .secondaryBackground
                          .withOpacity(0.90),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        // Subtle glass-like border with opacity
                        color: FlutterFlowTheme.of(context)
                            .alternate
                            .withOpacity(0.6),
                        width: 1.0,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          // Modern glassmorphism gradient
                          FlutterFlowTheme.of(context)
                              .secondaryBackground
                              .withOpacity(0.9),
                          FlutterFlowTheme.of(context)
                              .secondaryBackground
                              .withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, -1),
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
                              child: Scrollbar(
                                controller: _textFieldScrollController,
                                thumbVisibility: false,
                                // Only show when scrolling
                                trackVisibility: false,
                                thickness: 4.0,
                                radius: const Radius.circular(2.0),
                                child: TextFormField(
                                  controller: _model.textController,
                                  focusNode: _model.textFieldFocusNode,
                                  scrollController: _textFieldScrollController,
                                  autofocus: false,
                                  readOnly: true,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    hintText: _model.isTranslating
                                        ? 'Translating...'
                                        : 'Translated Text Appear Here',
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMediumFamily,
                                          color: _model.isTranslating
                                              ? const Color(0xFFFAB317)
                                              : FlutterFlowTheme.of(context)
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
                                            .containsKey(
                                                FlutterFlowTheme.of(context)
                                                    .bodyMediumFamily),
                                        lineHeight: 1.4,
                                      ),
                                  textAlign: TextAlign.start,
                                  maxLines: 6,
                                  // Allow expansion up to 6 lines
                                  minLines: 1,
                                  keyboardType: TextInputType.multiline,
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primary,
                                ),
                              ),
                            ),

                            // Button row below text field (Claude AI style)
                            Container(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                                bottom: 12.0,
                              ),
                              child: Row(
                                children: [
                                  // Modern Android-style scrollable language dropdown
                                  Container(
                                    margin: const EdgeInsets.only(right: 12.0),
                                    child: Tooltip(
                                      message:
                                          'Select language for text-to-speech output',
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4.0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      textStyle: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      preferBelow: false,
                                      showDuration: const Duration(seconds: 2),
                                      child: ModernDropDown(
                                        value: _model.availableLanguages[
                                                _model.selectedLanguage] ??
                                            'English (US)',
                                        options: _model
                                            .availableLanguages.values
                                            .toList(),
                                        onChanged: (val) async {
                                          // Find the language code for the selected language name
                                          String? selectedCode;
                                          _model.availableLanguages
                                              .forEach((code, name) {
                                            if (name == val) {
                                              selectedCode = code;
                                            }
                                          });

                                          if (selectedCode != null) {
                                            await _model
                                                .setTtsLanguage(selectedCode!);
                                            safeSetState(() {});
                                            print(
                                                'TTS Language changed to: $selectedCode ($val)');
                                          }
                                        },
                                        width: 110.0,
                                        height: 36.0,
                                      ),
                                    ), // Removed walkthrough functionality
                                    // .addWalkthrough(
                                    //   dropDownB9wm9jo8,
                                    //   _model.signifyScreen2Controller,
                                    // ),
                                  ),

                                  // Speaker toggle button with TTS state
                                  Container(
                                    margin: const EdgeInsets.only(right: 8.0),
                                    child: Tooltip(
                                      message: _model.ttsToggleState
                                          ? 'Turn off text-to-speech'
                                          : 'Turn on text-to-speech',
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4.0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      textStyle: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      preferBelow: false,
                                      showDuration: const Duration(seconds: 2),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          onTap: () async {
                                            await _model.toggleTts();
                                            safeSetState(() {});
                                          },
                                          child: SizedBox(
                                            width: 42.0,
                                            height: 42.0,
                                            child: Icon(
                                              _model.ttsToggleState
                                                  ? Icons.volume_up_rounded
                                                  : Icons.volume_off_rounded,
                                              color: _model.ttsToggleState
                                                  ? const Color(0xFFFAB317)
                                                  : FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              size: 24.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const Spacer(),

                                  // Camera toggle button (no border)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8.0),
                                    child: Tooltip(
                                      message: _model.isDetecting
                                          ? 'Stop sign detection'
                                          : 'Start sign detection',
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4.0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      textStyle: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      preferBelow: false,
                                      showDuration: const Duration(seconds: 2),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          onTap: () async {
                                            await _model.toggleDetection();
                                            safeSetState(() {});
                                          },
                                          child: SizedBox(
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
                                    ),
                                  ),
                                  // Removed walkthrough functionality
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraDisplay() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Live camera feed area with Flutter CameraPreview (clean, no overlays)
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0.0),
                child: _model.isCameraOn && _model.isCameraInitialized
                    ? SizedBox(
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
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.camera_alt,
                              size: 80.0,
                              color: Colors.grey, // Use a const color instead
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              _model.isCameraOn
                                  ? 'Initializing camera...'
                                  : 'Press camera button to start',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_model.errorMessage.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Error: ${_model.errorMessage}',
                                style: const TextStyle(
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
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.width,
    required this.height,
  });

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Material(
                  elevation: 0, // Remove elevation since we have acrylic effect
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxHeight:
                          200, // Scrollable if more than 5 items (40 each)
                    ),
                    decoration: BoxDecoration(
                      // Acrylic glass effect matching the main container
                      color: FlutterFlowTheme.of(context)
                          .secondaryBackground
                          .withOpacity(0.88),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context)
                            .alternate
                            .withOpacity(0.4),
                        width: 1,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          // Glassmorphism gradient for dropdown
                          FlutterFlowTheme.of(context)
                              .secondaryBackground
                              .withOpacity(0.92),
                          FlutterFlowTheme.of(context)
                              .secondaryBackground
                              .withOpacity(0.82),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, -1),
                        ),
                      ],
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  // Subtle acrylic highlight for selected item
                                  color: isSelected
                                      ? FlutterFlowTheme.of(context)
                                          .primary
                                          .withOpacity(0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: isSelected
                                      ? Border.all(
                                          color: FlutterFlowTheme.of(context)
                                              .primary
                                              .withOpacity(0.2),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmallFamily,
                                              color: isSelected
                                                  ? FlutterFlowTheme.of(context)
                                                      .primary
                                                  : FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              fontSize: 12.0,
                                              letterSpacing: 0.0,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              useGoogleFonts:
                                                  GoogleFonts.asMap()
                                                      .containsKey(
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmallFamily),
                                            ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
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
            )));

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              // Acrylic glass effect matching the main container
              color:
                  FlutterFlowTheme.of(context).secondaryBackground.withOpacity(
                        _isExpanded ? 0.85 : 0.75,
                      ),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: _isExpanded
                    ? FlutterFlowTheme.of(context).primary
                    : FlutterFlowTheme.of(context).alternate.withOpacity(0.4),
                width: _isExpanded ? 2.0 : 1.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  // Glassmorphism gradient matching main container
                  FlutterFlowTheme.of(context)
                      .secondaryBackground
                      .withOpacity(_isExpanded ? 0.9 : 0.8),
                  FlutterFlowTheme.of(context)
                      .secondaryBackground
                      .withOpacity(_isExpanded ? 0.7 : 0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isExpanded ? 0.15 : 0.08),
                  blurRadius: _isExpanded ? 12 : 8,
                  offset: const Offset(0, 2),
                  spreadRadius: _isExpanded ? -1 : -2,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(_isExpanded ? 0.08 : 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily:
                              FlutterFlowTheme.of(context).bodySmallFamily,
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
        ),
      ),
    );
  }
}
