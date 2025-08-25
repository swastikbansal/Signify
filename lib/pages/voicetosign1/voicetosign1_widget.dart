import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/supabase_animation_service.dart';
import 'voicetosign1_model.dart';

export 'voicetosign1_model.dart';

/// Ultra-aggressive animation preloader for instant HandTalk-like performance
class InstantAnimationCache {
  static final Map<String, bool> _preloadedAnimations = {};
  static final Map<String, AnimationData> _animationDataCache = {};

  /// Pre-cache animations instantly in background for seamless playback
  static Future<void> ultraPreload(List<AnimationData> animations) async {
    debugPrint(
      '⚡ Ultra-preloading ${animations.length} animations for INSTANT playback',
    );

    // Cache animation data and mark as ready instantly
    for (final anim in animations) {
      if (anim.url != null) {
        _preloadedAnimations[anim.url!] = true;
        _animationDataCache[anim.url!] = anim;
        debugPrint(
          '⚡ INSTANT READY: ${anim.metadata.word} (${anim.metadata.duration}ms)',
        );
      }
    }

    // Ultra-fast completion for immediate availability
    await Future.delayed(const Duration(milliseconds: 50));
    debugPrint('⚡ All animations cached and ready for seamless playback');
  }

  /// Check if animation is instantly ready for playback
  static bool isInstantlyReady(String animationUrl) {
    return _preloadedAnimations.containsKey(animationUrl);
  }

  /// Get cached animation data for instant access
  static AnimationData? getCachedAnimation(String animationUrl) {
    return _animationDataCache[animationUrl];
  }

  /// Clear cache for memory management
  static void clearInstantCache() {
    _preloadedAnimations.clear();
    _animationDataCache.clear();
    debugPrint('⚡ Instant cache cleared');
  }

  /// Get cache statistics for debugging
  static Map<String, int> getCacheStats() {
    return {
      'preloaded_count': _preloadedAnimations.length,
      'cached_data_count': _animationDataCache.length,
    };
  }
}

class Voicetosign1Widget extends StatefulWidget {
  const Voicetosign1Widget({super.key});

  @override
  State<Voicetosign1Widget> createState() => _Voicetosign1WidgetState();
}

class _Voicetosign1WidgetState extends State<Voicetosign1Widget>
    with RouteAware, TickerProviderStateMixin {
  late Voicetosign1Model _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // API-based seamless animation system
  final List<AnimationData> _animationQueue = [];
  final List<String> _wordQueue = [];

  final String defaultAnimation = 'assets/models/model.glb';
  String? currentAnimation;
  String? currentWord;
  String inputSentence = '';
  bool isPlayingSequence = false;
  bool voiceTrigger = false; // Local state for microphone toggle

  // Animation controllers for moving line animation (Claude AI style)
  late AnimationController _movingLineController;
  late Animation<double> _movingLineAnimation;

  // Direct animation sequence state (moved from InstantAnimationPlayer)
  Timer? _animationTimer;
  int _currentAnimationIndex = 0;
  bool _isSequenceActive = false;
  String? _currentAnimationUrl;

  // Image handling variables - use paths instead of File objects for safety
  List<String> uploadedImagePaths = [];
  bool isProcessingImage = false;
  bool isMovingLineActive = false; // For the moving line animation

  // OCR variables - using direct Google ML Kit TextRecognizer
  final ImagePicker _imagePicker = ImagePicker();
  late TextRecognizer _textRecognizer;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Voicetosign1Model());
    // Logging minimized – verbose helper removed

    _model.textController ??= TextEditingController()
      ..addListener(() {
        debugLogWidgetClass(_model);
      });
    _model.textFieldFocusNode ??= FocusNode();

    // Animation initialization
    currentAnimation = defaultAnimation;
    isPlayingSequence = false;

    // Initialize OCR TextRecognizer
    _textRecognizer = TextRecognizer();

    // Preload core vocabulary in background for instant access
    SupabaseAnimationService.preloadCoreVocabulary();

    // Optionally log dynamic vocabulary info for debugging
    _logVocabularyInfo(); // Will internally respect minimal logging

    // Moving line animation controller (Claude AI style)
    _movingLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Fast like Google/Claude
    );
    _movingLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _movingLineController,
        curve: Curves.easeInOutQuart, // Smooth curve like Claude
      ),
    );
  }

  @override
  void dispose() {
    _model.dispose();
    _movingLineController.dispose();
    _animationTimer?.cancel(); // Cancel animation timer
    _textRecognizer.close(); // Dispose text recognizer
    super.dispose();
  }

  // Dynamic vocabulary info logging - showcases API capabilities
  Future<void> _logVocabularyInfo() async {
    try {
      // Keep this silent unless needed for diagnostics
      await SupabaseAnimationService.getTotalWordCount();
    } catch (_) {}
  }

  // Minimal similar word suggestion (silent)
  Future<void> _suggestSimilarWords(String unknownWord) async {
    try {
      final suggestions = await SupabaseAnimationService.searchWords(
        unknownWord,
        limit: 3,
      );
      if (suggestions.isEmpty) {
        await SupabaseAnimationService.getPopularWords(limit: 3);
      }
    } catch (_) {}
  }

  // Animation sequence methods (moved from InstantAnimationPlayer)
  void _startInstantSequence() {
    if (_animationQueue.isEmpty) {
      _completeSequence();
      return;
    }

    setState(() {
      _currentAnimationIndex = 0;
      _isSequenceActive = true;
    });

    _playCurrentAnimationInstantly();
  }

  void _playCurrentAnimationInstantly() {
    if (_currentAnimationIndex >= _animationQueue.length) {
      _completeSequence();
      return;
    }

    final currentAnimationData = _animationQueue[_currentAnimationIndex];
    final currentWordData =
        _wordQueue.isNotEmpty && _currentAnimationIndex < _wordQueue.length
        ? _wordQueue[_currentAnimationIndex]
        : null;

    setState(() {
      _currentAnimationUrl = currentAnimationData.url;
      currentAnimation = currentAnimationData.url;
      currentWord = currentWordData;
    });

    // Notify parent about current word change
    if (currentWordData != null) {
      _onCurrentWordChange(currentWordData);
    }

    // Use actual animation duration from metadata for precise timing
    final animationDuration = currentAnimationData.metadata.duration;

    // Debug info for performance monitoring
    debugPrint(
      '⚡ INSTANT: ${currentWordData ?? 'Unknown'} (${animationDuration}ms)',
    );

    // Pre-cache next animation for seamless transition (if exists)
    if (_currentAnimationIndex + 1 < _animationQueue.length) {
      final nextAnimation = _animationQueue[_currentAnimationIndex + 1];
      InstantAnimationCache.ultraPreload([nextAnimation]);
    }

    _animationTimer?.cancel();
    _animationTimer = Timer(Duration(milliseconds: animationDuration), () {
      _currentAnimationIndex++;
      _playCurrentAnimationInstantly();
    });
  }

  void _completeSequence() {
    debugPrint('⚡ INSTANT sequence completed');

    // Cancel any remaining timer
    _animationTimer?.cancel();
    _animationTimer = null;

    setState(() {
      _isSequenceActive = false;
      _currentAnimationIndex = 0;
      _currentAnimationUrl = null;
      // Return to default animation smoothly
      currentAnimation = defaultAnimation;
    });

    _onAnimationSequenceComplete();
  }

  // Image handling methods
  Future<void> _pickImage() async {
    try {
      setState(() {
        isProcessingImage = true;
      });

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        setState(() {
          isProcessingImage = false;
        });
        return;
      }

      await _processImageSafely(pickedFile, isFromCamera: false);
    } catch (e) {
      debugPrint('Gallery image picker error: $e');
      setState(() {
        isProcessingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: Please try again'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    setState(() {
      isProcessingImage = true;
    });

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        // Increased back for better OCR quality
        maxHeight: 1200,
        // Increased back for better OCR quality
        imageQuality: 80,
        // Increased for better OCR accuracy
        preferredCameraDevice:
            CameraDevice.rear, // Specify rear camera for better quality
      );

      if (pickedFile == null) {
        setState(() {
          isProcessingImage = false;
        });
        return;
      }

      await _processImageSafely(pickedFile, isFromCamera: true);
    } catch (e) {
      debugPrint('Camera capture error: $e');
      setState(() {
        isProcessingImage = false;
      });

      // Show user-friendly error based on the error type
      String errorMessage = 'Camera error: Please try again';
      if (e.toString().contains('permission')) {
        errorMessage =
            'Camera permission required. Please grant permission in settings.';
      } else if (e.toString().contains('not available')) {
        errorMessage = 'Camera not available on this device.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _processImageSafely(
    XFile pickedFile, {
    bool isFromCamera = false,
  }) async {
    try {
      // Ensure file exists and is readable before processing
      final file = File(pickedFile.path);
      if (!await file.exists()) {
        throw Exception('Image file not found');
      }

      // Add a small delay for camera captures to ensure file is fully written
      if (isFromCamera) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Process image for OCR
      String extractedText = '';
      try {
        final inputImage = InputImage.fromFile(file);
        final recognizedText = await _textRecognizer.processImage(inputImage);
        extractedText = recognizedText.text.trim();
      } catch (ocrError) {
        debugPrint('OCR processing failed: $ocrError');
        // Continue without OCR - don't let OCR failure break the app
      }

      setState(() {
        // Add extracted text to the text field if any
        if (extractedText.isNotEmpty) {
          if (_model.textController!.text.isNotEmpty) {
            _model.textController!.text += ' $extractedText';
          } else {
            _model.textController!.text = extractedText;
          }
          inputSentence = _model.textController!.text;
          // Use enhanced voice-to-sign integration for OCR text
          _model.updateInputSentence(inputSentence);
        }

        // Add image path for preview (safer than File objects)
        uploadedImagePaths.add(pickedFile.path);
        isProcessingImage = false;
      });

      debugPrint(
        'Image processed successfully. OCR text length: ${extractedText.length}',
      );
    } catch (e) {
      debugPrint('Image processing error: $e');

      setState(() {
        isProcessingImage = false;
      });

      // Show user-friendly error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).alternate,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Add Image',
                        style: FlutterFlowTheme.of(context).headlineSmall
                            .override(
                              fontFamily: FlutterFlowTheme.of(
                                context,
                              ).headlineSmallFamily,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.0,
                              useGoogleFonts: GoogleFonts.asMap().containsKey(
                                FlutterFlowTheme.of(
                                  context,
                                ).headlineSmallFamily,
                              ),
                            ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _takePhoto();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(
                                    context,
                                  ).primaryBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 32,
                                      color: FlutterFlowTheme.of(
                                        context,
                                      ).primaryText,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Camera',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: FlutterFlowTheme.of(
                                              context,
                                            ).bodyMediumFamily,
                                            letterSpacing: 0.0,
                                            useGoogleFonts: GoogleFonts.asMap()
                                                .containsKey(
                                                  FlutterFlowTheme.of(
                                                    context,
                                                  ).bodyMediumFamily,
                                                ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(
                                    context,
                                  ).primaryBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.photo_library,
                                      size: 32,
                                      color: FlutterFlowTheme.of(
                                        context,
                                      ).primaryText,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Gallery',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: FlutterFlowTheme.of(
                                              context,
                                            ).bodyMediumFamily,
                                            letterSpacing: 0.0,
                                            useGoogleFonts: GoogleFonts.asMap()
                                                .containsKey(
                                                  FlutterFlowTheme.of(
                                                    context,
                                                  ).bodyMediumFamily,
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSendAction() async {
    if (inputSentence.isEmpty) {
      // Play the default animation if no input - NO loading states
      setState(() {
        _animationQueue.clear();
        _wordQueue.clear();
        currentAnimation = defaultAnimation;
        currentWord = null;
        isPlayingSequence = false;
      });
      return;
    }

    // Start Claude-style moving line animation first
    setState(() {
      isMovingLineActive = true;
    });

    _movingLineController.forward().then((_) {
      // Reset moving line for next time
      _movingLineController.reset();
      setState(() {
        isMovingLineActive = false;
      });
    });

    // Suppressed noisy send diagnostics

    try {
      // Parse sentence word by word for INSTANT API processing
      List<String> words = inputSentence
          .toLowerCase()
          .trim()
          .split(RegExp(r'\s+'))
          .map((word) => word.replaceAll(RegExp(r'[^\w]'), ''))
          .where((word) => word.isNotEmpty)
          .toList();

      // Silent list of words

      // Ultra-fast animations from Supabase API
      final animationsData =
          await SupabaseAnimationService.getBatchAnimationsWithMetadata(words);

      // Filter successful animations and prepare queue INSTANTLY
      _animationQueue.clear();
      _wordQueue.clear();

      for (int i = 0; i < words.length; i++) {
        if (i < animationsData.length && animationsData[i].url != null) {
          _animationQueue.add(animationsData[i]);
          _wordQueue.add(words[i]);
        } else {
          // Dynamic word suggestions for missing words
          _suggestSimilarWords(words[i]);
        }
      }

      setState(() {
        isPlayingSequence = true; // NO loading states
      });

      if (_animationQueue.isNotEmpty) {
        // Ultra-fast preloading for seamless HandTalk-style performance
        await InstantAnimationCache.ultraPreload(_animationQueue);

        // Also ultra-preload in SupabaseAnimationService for double caching
        final wordList = _wordQueue.isNotEmpty
            ? _wordQueue
            : _animationQueue.map((a) => a.metadata.word).toList();
        await SupabaseAnimationService.ultraPreloadAnimations(wordList);

        // Start predictive loading for better performance
        SupabaseAnimationService.preloadRelatedWords(
          _animationQueue.first.metadata.word,
        );

        _startInstantSequence();
      } else {
        setState(() {
          currentAnimation = defaultAnimation;
          currentWord = null;
          isPlayingSequence = false;
        });
      }
    } catch (e) {
      setState(() {
        currentAnimation = defaultAnimation;
        isPlayingSequence = false;
      });
    }

    // Clear text and images INSTANTLY with no delays
    setState(() {
      _model.textController!.clear();
      inputSentence = '';
      uploadedImagePaths.clear();
      // Clear animation state when clearing input
      _model.clearAnimations();
    });
  }

  void _onAnimationSequenceComplete() {
    setState(() {
      currentAnimation = defaultAnimation;
      currentWord = null;
      isPlayingSequence = false;
      _animationQueue.clear();
      _wordQueue.clear();
    });
  }

  void _onCurrentWordChange(String word) {
    setState(() {
      currentWord = word;
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
    DebugFlutterFlowModelContext.maybeOf(
      context,
    )?.parentModelCallback?.call(_model);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Signify',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: FlutterFlowTheme.of(context).primaryText,
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              // Full screen animation container
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                ),
                child: Stack(
                  children: [
                    // Direct ModelViewer for ultra-seamless animations (HandTalk-style)
                    ModelViewer(
                      key: ValueKey(
                        _currentAnimationUrl ??
                            currentAnimation ??
                            defaultAnimation,
                      ),
                      src:
                          _currentAnimationUrl ??
                          currentAnimation ??
                          defaultAnimation,
                      autoPlay: true,
                      // Auto-play default animation for its resting position
                      autoRotate: false,
                      cameraControls: !_isSequenceActive,
                      // Disable controls during sequence for focus
                      backgroundColor: Colors.transparent,
                      cameraTarget: '0m 1.2m 0.1m',
                      cameraOrbit: '0deg 90deg 1.6m',
                      minCameraOrbit: 'auto 45deg 1.0m',
                      maxCameraOrbit: 'auto 110deg 6m',
                      minFieldOfView: '20deg',
                      maxFieldOfView: '65deg',
                      fieldOfView: '35deg',
                      disablePan: true,
                      // Enable panning: drag with 2 fingers (mobile) or Ctrl+drag (desktop)
                      disableTap: true,
                      // Enable tap to focus: tap on model parts to center camera there
                      disableZoom: true,
                      // Enable zoom: pinch gesture (mobile) or scroll wheel (desktop)
                    ),

                    // NO loading overlays for instant HandTalk-like performance

                    // Word tag overlay removed as requested by user
                  ],
                ),
              ),

              // Floating input container positioned at bottom
              Positioned(
                left: 8.0,
                right: 8.0,
                bottom: 12.0,
                child:
                    // Modern unified input container with Claude-like design and acrylic transparency
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        16.0,
                      ), // Match container border radius
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                        child: Container(
                          decoration: BoxDecoration(
                            // GROK app-style glassmorphism with theme-adaptive colors for dark/light mode
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                // Perfect transparency levels using theme colors for dark/light mode
                                FlutterFlowTheme.of(
                                  context,
                                ).secondaryBackground.withOpacity(0.85),
                                // Top-left highlight
                                FlutterFlowTheme.of(
                                  context,
                                ).secondaryBackground.withOpacity(0.75),
                                // Center
                                FlutterFlowTheme.of(
                                  context,
                                ).secondaryBackground.withOpacity(0.65),
                                // Bottom-right shadow
                                FlutterFlowTheme.of(
                                  context,
                                ).secondaryBackground.withOpacity(0.55),
                                // Bottom edge fade
                              ],
                              stops: const [0.0, 0.3, 0.7, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(
                              20.0,
                            ), // More modern rounded corners
                            border: Border.all(
                              // Theme-adaptive border for dark/light mode compatibility
                              color: FlutterFlowTheme.of(
                                context,
                              ).alternate.withOpacity(0.6),
                              width:
                                  1.5, // Slightly thicker for better definition
                            ),
                            boxShadow: [
                              // Multi-layered shadows for realistic depth like GROK app
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 32,
                                offset: const Offset(0, 10),
                                spreadRadius: -4,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                                spreadRadius: -2,
                              ),
                              // Inner glow for glass edge effect
                              BoxShadow(
                                color: Colors.white.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                                spreadRadius: -1,
                              ),
                              // Subtle ambient shadow
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 64,
                                offset: const Offset(0, 20),
                                spreadRadius: -8,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Moving line animation overlay (Claude AI style)
                              if (isMovingLineActive)
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _movingLineAnimation,
                                    builder: (context, child) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16.0,
                                          ), // Match container border radius
                                          border: Border.all(
                                            color: Colors.transparent,
                                            width: 2.0,
                                          ),
                                        ),
                                        child: CustomPaint(
                                          painter: MovingLinePainter(
                                            progress:
                                                _movingLineAnimation.value,
                                            color: const Color(
                                              0xFFFAB317,
                                            ), // Yellow like Claude
                                            strokeWidth: 3.0,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              // Main content
                              Column(
                                children: [
                                  // Image preview section
                                  if (uploadedImagePaths.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.only(
                                        left: 16.0,
                                        right: 16.0,
                                        top: 8.0,
                                        bottom: 2.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8.0),
                                          SizedBox(
                                            height: 60.0,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  uploadedImagePaths.length,
                                              itemBuilder: (context, index) {
                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                    right: 8.0,
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8.0,
                                                            ),
                                                        child: Container(
                                                          width: 60.0,
                                                          height: 60.0,
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .grey[300]!,
                                                            ),
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            child: Image.file(
                                                              File(
                                                                uploadedImagePaths[index],
                                                              ),
                                                              width: 60.0,
                                                              height: 60.0,
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (
                                                                    context,
                                                                    error,
                                                                    stackTrace,
                                                                  ) {
                                                                    return Container(
                                                                      width:
                                                                          60.0,
                                                                      height:
                                                                          60.0,
                                                                      color: Colors
                                                                          .grey[300],
                                                                      child: const Icon(
                                                                        Icons
                                                                            .error,
                                                                      ),
                                                                    );
                                                                  },
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: -4,
                                                        right: -4,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              uploadedImagePaths
                                                                  .removeAt(
                                                                    index,
                                                                  );
                                                            });
                                                          },
                                                          child: Container(
                                                            width: 20,
                                                            height: 20,
                                                            decoration:
                                                                const BoxDecoration(
                                                                  color: Colors
                                                                      .red,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                            child: const Icon(
                                                              Icons.close,
                                                              size: 12,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Container(
                                            height: 1.0,
                                            color: FlutterFlowTheme.of(
                                              context,
                                            ).alternate.withOpacity(0.5),
                                          ),
                                        ],
                                      ),
                                    ),

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
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        hintText: 'Type message',
                                        hintStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: FlutterFlowTheme.of(
                                                context,
                                              ).bodyMediumFamily,
                                              color: FlutterFlowTheme.of(
                                                context,
                                              ).secondaryText,
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  GoogleFonts.asMap()
                                                      .containsKey(
                                                        FlutterFlowTheme.of(
                                                          context,
                                                        ).bodyMediumFamily,
                                                      ),
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
                                            fontFamily: FlutterFlowTheme.of(
                                              context,
                                            ).bodyMediumFamily,
                                            fontSize: 16.0,
                                            letterSpacing: 0.0,
                                            useGoogleFonts: GoogleFonts.asMap()
                                                .containsKey(
                                                  FlutterFlowTheme.of(
                                                    context,
                                                  ).bodyMediumFamily,
                                                ),
                                            lineHeight: 1.4,
                                          ),
                                      textAlign: TextAlign.start,
                                      maxLines: 4,
                                      minLines: 1,
                                      keyboardType: TextInputType.multiline,
                                      cursorColor: FlutterFlowTheme.of(
                                        context,
                                      ).primary,
                                      onChanged: (text) {
                                        setState(() {
                                          inputSentence = text;
                                          // Use enhanced voice-to-sign integration for typed text
                                          _model.updateInputSentence(text);
                                        });
                                      },
                                      validator: _model.textControllerValidator
                                          .asValidator(context),
                                    ),
                                  ),
                                  // Button row below text field (Claude AI style)
                                  Container(
                                    padding: const EdgeInsets.only(
                                      top: 6.0,
                                      left: 16.0,
                                      right: 16.0,
                                      bottom: 12.0,
                                    ),
                                    child: Row(
                                      children: [
                                        // Add image/attachment button (Claude AI style)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isProcessingImage
                                                ? const Color(
                                                    0xFFFAB317,
                                                  ) // Yellow when active
                                                : FlutterFlowTheme.of(context)
                                                      .secondaryText
                                                      .withOpacity(0.1),
                                            // Match send button inactive color
                                            borderRadius: BorderRadius.circular(
                                              16.0,
                                            ), // More rounded for modern look
                                            // Removed border to match send button
                                          ),
                                          child: Tooltip(
                                            message: 'Attach image or document',
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(
                                                context,
                                              ).alternate,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 4.0,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            textStyle: TextStyle(
                                              color: FlutterFlowTheme.of(
                                                context,
                                              ).primaryText,
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            preferBelow: false,
                                            showDuration: const Duration(
                                              seconds: 2,
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(
                                                  16.0,
                                                ), // Match container border radius
                                                onTap: isProcessingImage
                                                    ? null
                                                    : _showImagePickerBottomSheet,
                                                child: SizedBox(
                                                  width: 32.0,
                                                  height: 32.0,
                                                  child: Icon(
                                                    Icons.attach_file,
                                                    color: isProcessingImage
                                                        ? Colors.black
                                                        : FlutterFlowTheme.of(
                                                            context,
                                                          ).secondaryText,
                                                    size: 18.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),

                                        // Microphone button (Claude AI style) - moved next to send button
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 4.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: voiceTrigger
                                                ? const Color(
                                                    0xFFFAB317,
                                                  ) // Yellow when active
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              16.0,
                                            ), // More rounded for modern look
                                            border: voiceTrigger
                                                ? null
                                                : Border.all(
                                                    color:
                                                        FlutterFlowTheme.of(
                                                              context,
                                                            ).primaryBackground
                                                            .withOpacity(0.2),
                                                    width: 1.0,
                                                  ),
                                          ),
                                          child: Tooltip(
                                            message: voiceTrigger
                                                ? 'Stop voice recognition'
                                                : 'Start voice recognition',
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(
                                                context,
                                              ).alternate,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 4.0,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            textStyle: TextStyle(
                                              color: FlutterFlowTheme.of(
                                                context,
                                              ).primaryText,
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            preferBelow: false,
                                            showDuration: const Duration(
                                              seconds: 2,
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(
                                                  16.0,
                                                ), // Match container border radius
                                                onTap: () async {
                                                  setState(() {
                                                    voiceTrigger =
                                                        !voiceTrigger;
                                                  });
                                                  if (voiceTrigger) {
                                                    _model.startListening((
                                                      recognizedText,
                                                    ) {
                                                      setState(() {
                                                        _model
                                                                .textController!
                                                                .text =
                                                            recognizedText;
                                                        inputSentence =
                                                            recognizedText;
                                                        // Use enhanced voice-to-sign integration
                                                        _model
                                                            .updateInputSentence(
                                                              recognizedText,
                                                            );
                                                      });
                                                    });
                                                  } else {
                                                    _model.stopListening();
                                                    // Process final text when user stops speaking
                                                    if (inputSentence
                                                        .isNotEmpty) {
                                                      _model
                                                          .processFinalSpeechForAnimation(
                                                            inputSentence,
                                                          );
                                                    }
                                                  }
                                                },
                                                child: SizedBox(
                                                  width: 32.0,
                                                  height: 32.0,
                                                  child: Icon(
                                                    voiceTrigger
                                                        ? Icons.mic
                                                        : Icons.mic_none,
                                                    color: voiceTrigger
                                                        ? Colors.black
                                                        : FlutterFlowTheme.of(
                                                            context,
                                                          ).secondaryText,
                                                    size: 18.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Send button (Claude AI style with arrow up)
                                        Container(
                                          decoration: BoxDecoration(
                                            color:
                                                (inputSentence
                                                        .trim()
                                                        .isNotEmpty ||
                                                    uploadedImagePaths
                                                        .isNotEmpty)
                                                ? const Color(
                                                    0xFFFAB317,
                                                  ) // Yellow when active
                                                : FlutterFlowTheme.of(context)
                                                      .secondaryText
                                                      .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              16.0,
                                            ), // More rounded for modern look
                                          ),
                                          child: Tooltip(
                                            message:
                                                'Send message for sign animation',
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(
                                                context,
                                              ).alternate,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 4.0,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            textStyle: TextStyle(
                                              color: FlutterFlowTheme.of(
                                                context,
                                              ).primaryText,
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            preferBelow: false,
                                            showDuration: const Duration(
                                              seconds: 2,
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(
                                                  16.0,
                                                ), // Match container border radius
                                                onTap:
                                                    (inputSentence
                                                            .trim()
                                                            .isNotEmpty ||
                                                        uploadedImagePaths
                                                            .isNotEmpty)
                                                    ? () {
                                                        _handleSendAction();
                                                      }
                                                    : null,
                                                child: SizedBox(
                                                  width: 32.0,
                                                  height: 32.0,
                                                  child: Icon(
                                                    Icons.arrow_upward_rounded,
                                                    color:
                                                        (inputSentence
                                                                .trim()
                                                                .isNotEmpty ||
                                                            uploadedImagePaths
                                                                .isNotEmpty)
                                                        ? Colors
                                                              .black // Black icon when active
                                                        : FlutterFlowTheme.of(
                                                            context,
                                                          ).secondaryText,
                                                    size: 18.0,
                                                  ),
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
                    ),
              ), // Close Positioned widget
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for the moving line animation (like Google's)
class MovingLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  MovingLinePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const borderRadius = 20.0; // Match voice to sign page border radius
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(borderRadius),
    );

    // Calculate the total perimeter path
    final path = Path()..addRRect(rrect);
    final totalLength = _calculatePathLength(path);

    // Create path metrics to get position along the path
    final pathMetrics = path.computeMetrics().first;

    // Single line animation that travels around the complete perimeter with completion effect
    if (progress < 0.85) {
      // Moving phase: single solid line travels around the perimeter
      final lineLength =
          totalLength *
          0.2; // Line covers 20% of perimeter for better visibility
      final currentPosition =
          (progress / 0.85) *
          totalLength; // Travel full perimeter in first 85% of animation
      final startPosition = currentPosition - lineLength * 0.5;
      final endPosition = currentPosition + lineLength * 0.5;

      // Simple solid yellow paint - no gradients
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (startPosition >= 0 && endPosition <= totalLength) {
        // Draw simple line segment
        final segmentPath = pathMetrics.extractPath(
          startPosition.clamp(0.0, totalLength),
          endPosition.clamp(0.0, totalLength),
        );
        canvas.drawPath(segmentPath, paint);
      } else {
        // Handle wrapping around the path (simplified)
        if (startPosition < 0) {
          final segmentPath1 = pathMetrics.extractPath(
            (startPosition + totalLength).clamp(0.0, totalLength),
            totalLength,
          );
          final segmentPath2 = pathMetrics.extractPath(
            0.0,
            endPosition.clamp(0.0, totalLength),
          );

          // Draw simple segments
          canvas.drawPath(segmentPath1, paint);
          canvas.drawPath(segmentPath2, paint);
        } else if (endPosition > totalLength) {
          final segmentPath1 = pathMetrics.extractPath(
            startPosition.clamp(0.0, totalLength),
            totalLength,
          );
          final segmentPath2 = pathMetrics.extractPath(
            0.0,
            (endPosition - totalLength).clamp(0.0, totalLength),
          );

          // Draw simple segments
          canvas.drawPath(segmentPath1, paint);
          canvas.drawPath(segmentPath2, paint);
        }
      }
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

  double _calculatePathLength(Path path) {
    final pathMetrics = path.computeMetrics();
    double totalLength = 0.0;
    for (final metric in pathMetrics) {
      totalLength += metric.length;
    }
    return totalLength;
  }

  @override
  bool shouldRepaint(covariant MovingLinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
