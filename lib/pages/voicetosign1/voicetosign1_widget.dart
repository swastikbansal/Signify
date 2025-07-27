import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/walkthroughs/signify_screen_1.dart';
import '/services/supabase_animation_service.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:async';
import 'dart:io';
import 'voicetosign1_model.dart';
export 'voicetosign1_model.dart';

class Voicetosign1Widget extends StatefulWidget {
  const Voicetosign1Widget({super.key});

  @override
  State<Voicetosign1Widget> createState() => _Voicetosign1WidgetState();
}

class _Voicetosign1WidgetState extends State<Voicetosign1Widget>
    with RouteAware, TickerProviderStateMixin {
  late Voicetosign1Model _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // API-based animation system
  final List<AnimationData> _animationQueue = [];
  final List<String> _wordQueue = [];

  final String defaultAnimation = 'assets/models/model.glb';
  String? currentAnimation;
  Timer? animationTimer;
  String inputSentence = '';
  late AnimationController _fadeController;
  late AnimationController _loadingController;
  late AnimationController _movingLineController;
  late Animation<double> _movingLineAnimation;
  String? currentWord;
  bool isPlayingSequence = false;
  bool voiceTrigger = false; // Local state for microphone toggle
  bool isLoadingAnimations = false; // New loading state for API calls

  // Image handling variables
  List<String> uploadedImagePaths = [];
  List<File> uploadedImages = [];
  bool isProcessingImage = false;
  bool isLoadingAnimation = false;
  bool isMovingLineActive = false; // For the moving line animation

  // OCR variables
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Voicetosign1Model());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
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
            _model.signifyScreen1Controller = createPageWalkthrough(context));
        _model.signifyScreen1Controller?.show(context: context);
        return;
      } else {
        return;
      }
    });

    _model.textController ??= TextEditingController()
      ..addListener(() {
        debugLogWidgetClass(_model);
      });
    _model.textFieldFocusNode ??= FocusNode();

    // Animation initialization
    currentAnimation = defaultAnimation;
    isPlayingSequence = false;

    // Preload core vocabulary in background for instant access
    SupabaseAnimationService.preloadCoreVocabulary();

    // Optionally log dynamic vocabulary info for debugging
    _logVocabularyInfo();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 200), // Faster fade duration for seamless transitions
    )..forward();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Moving line animation controller (Google-like faster)
    _movingLineController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 1200), // Faster - reduced from 2000ms to 1200ms
    );
    _movingLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _movingLineController,
      curve: Curves.easeInOutQuart, // More Google-like smooth curve
    ));
  }

  @override
  void dispose() {
    _model.dispose();
    animationTimer?.cancel();
    _fadeController.dispose();
    _loadingController.dispose();
    _movingLineController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  // Dynamic vocabulary info logging - showcases API capabilities
  Future<void> _logVocabularyInfo() async {
    try {
      final totalWords = await SupabaseAnimationService.getTotalWordCount();
      final categories =
          await SupabaseAnimationService.getAvailableCategories();
      final popularWords =
          await SupabaseAnimationService.getPopularWords(limit: 5);

      debugPrint('📊 Dynamic Vocabulary Info:');
      debugPrint('  Total words available: $totalWords');
      debugPrint('  Categories: ${categories.join(", ")}');
      debugPrint('  Popular words: ${popularWords.join(", ")}');
      debugPrint(
          '🚀 Fully scalable - add words via Supabase without code changes!');
    } catch (e) {
      debugPrint('⚠️ Could not fetch vocabulary info: $e');
    }
  }

  // Dynamic word suggestions for unknown words - showcases search capabilities
  Future<void> _suggestSimilarWords(String unknownWord) async {
    try {
      // Search for partial matches
      final suggestions =
          await SupabaseAnimationService.searchWords(unknownWord, limit: 3);

      if (suggestions.isNotEmpty) {
        debugPrint(
            '💡 Suggestions for "$unknownWord": ${suggestions.join(", ")}');
      } else {
        // If no partial matches, suggest popular words
        final popular =
            await SupabaseAnimationService.getPopularWords(limit: 3);
        debugPrint('💡 Try these popular words instead: ${popular.join(", ")}');
      }
    } catch (e) {
      debugPrint('⚠️ Could not fetch suggestions for $unknownWord: $e');
    }
  }

  // Image handling methods
  Future<void> _pickImage() async {
    try {
      debugPrint('📸 Starting image picker...');

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        debugPrint('❌ No image selected');
        return;
      }

      await _processImage(pickedFile);
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      setState(() {
        isProcessingImage = false;
        isLoadingAnimation = false;
      });
      _loadingController.stop();
      _loadingController.reset();
    }
  }

  Future<void> _takePhoto() async {
    try {
      debugPrint('📷 Starting camera...');

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        debugPrint('❌ No photo taken');
        return;
      }

      await _processImage(pickedFile);
    } catch (e) {
      debugPrint('❌ Error taking photo: $e');
      setState(() {
        isProcessingImage = false;
        isLoadingAnimation = false;
      });
      _loadingController.stop();
      _loadingController.reset();
    }
  }

  Future<void> _processImage(XFile pickedFile) async {
    setState(() {
      isProcessingImage = true;
      isLoadingAnimation = true;
    });

    // Start loading animation
    _loadingController.repeat();

    debugPrint('🔄 Processing image with OCR...');

    // Create File from XFile
    final File imageFile = File(pickedFile.path);

    // Perform OCR
    final InputImage inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    String extractedText = recognizedText.text.trim();
    debugPrint('✅ OCR completed! Extracted text: $extractedText');

    if (extractedText.isNotEmpty) {
      setState(() {
        // Add extracted text to the text field
        if (_model.textController!.text.isNotEmpty) {
          _model.textController!.text += ' $extractedText';
        } else {
          _model.textController!.text = extractedText;
        }
        inputSentence = _model.textController!.text;

        // Add the actual image for preview
        uploadedImages.add(imageFile);
        uploadedImagePaths.add(pickedFile.path);

        isProcessingImage = false;
        isLoadingAnimation = false;
      });

      // Don't trigger animation immediately, wait for send button
      debugPrint('✅ Text extracted and added to text field: $extractedText');
    } else {
      debugPrint('⚠️ No text detected in image');
      setState(() {
        // Still add image even if no text detected
        uploadedImages.add(imageFile);
        uploadedImagePaths.add(pickedFile.path);
        isProcessingImage = false;
        isLoadingAnimation = false;
      });
    }

    // Stop loading animation
    _loadingController.stop();
    _loadingController.reset();

    debugPrint(
        '🖼️ Image added to preview. Total images: ${uploadedImagePaths.length}');
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
                        style: FlutterFlowTheme.of(context)
                            .headlineSmall
                            .override(
                              fontFamily: FlutterFlowTheme.of(context)
                                  .headlineSmallFamily,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.0,
                              useGoogleFonts: GoogleFonts.asMap().containsKey(
                                FlutterFlowTheme.of(context)
                                    .headlineSmallFamily,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 32,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Camera',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMediumFamily,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                GoogleFonts.asMap().containsKey(
                                              FlutterFlowTheme.of(context)
                                                  .bodyMediumFamily,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.photo_library,
                                      size: 32,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Gallery',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMediumFamily,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                GoogleFonts.asMap().containsKey(
                                              FlutterFlowTheme.of(context)
                                                  .bodyMediumFamily,
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

  void _startLoadingAnimation() {
    setState(() {
      isLoadingAnimation = true;
    });
    _loadingController.repeat();
  }

  void _stopLoadingAnimation() {
    setState(() {
      isLoadingAnimation = false;
    });
    _loadingController.stop();
    _loadingController.reset();
  }

  void _handleSendAction() async {
    if (inputSentence.isEmpty) {
      // Stop loading animation
      _stopLoadingAnimation();

      // Play the default animation if no input
      setState(() {
        _animationQueue.clear();
        _wordQueue.clear();
        currentAnimation = defaultAnimation;
        currentWord = null;
        isPlayingSequence = false;
      });
      debugPrint('No sentence provided. Playing default animation.');
      return;
    }

    animationTimer?.cancel(); // Cancel any ongoing animation sequence

    // Start moving line animation first (like Google's)
    setState(() {
      isMovingLineActive = true;
      isLoadingAnimations = true; // Show API loading state
    });

    _movingLineController.forward().then((_) {
      // After moving line animation, start loading animation
      _startLoadingAnimation();

      // Reset moving line for next time
      _movingLineController.reset();
      setState(() {
        isMovingLineActive = false;
      });
    });

    debugPrint('📤 Send button pressed!');
    debugPrint('📝 Current text: ${inputSentence.trim()}');
    debugPrint('🖼️ Images to clear: ${uploadedImagePaths.length}');

    try {
      // Parse sentence word by word for API processing
      List<String> words = inputSentence
          .toLowerCase()
          .trim()
          .split(RegExp(r'\s+'))
          .map((word) => word.replaceAll(RegExp(r'[^\w]'), ''))
          .where((word) => word.isNotEmpty)
          .toList();

      debugPrint('🔍 Processing words: $words');

      // Fetch animations from Supabase API with metadata
      final animationsData =
          await SupabaseAnimationService.getBatchAnimationsWithMetadata(words);

      // Filter successful animations and prepare queue
      _animationQueue.clear();
      _wordQueue.clear();

      for (int i = 0; i < words.length; i++) {
        if (i < animationsData.length && animationsData[i].url != null) {
          _animationQueue.add(animationsData[i]);
          _wordQueue.add(words[i]);
          debugPrint(
              '✅ Found animation for: ${words[i]} (${animationsData[i].metadata.duration}ms)');
        } else {
          debugPrint('❌ No animation for: ${words[i]}');
          // Dynamic word suggestions for missing words
          _suggestSimilarWords(words[i]);
        }
      }

      setState(() {
        isPlayingSequence = true;
        isLoadingAnimations = false;
      });

      if (_animationQueue.isNotEmpty) {
        // Start predictive loading for better performance
        if (_animationQueue.isNotEmpty) {
          SupabaseAnimationService.preloadRelatedWords(
              _animationQueue.first.metadata.word);
        }

        debugPrint('Playing animations for words in order: $_wordQueue');
        _playNextAnimationFromAPI();
      } else {
        debugPrint(
            'No animations found for any words. Playing default animation.');
        setState(() {
          currentAnimation = defaultAnimation;
          currentWord = null;
          isPlayingSequence = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading animations from API: $e');
      setState(() {
        isLoadingAnimations = false;
        currentAnimation = defaultAnimation;
        isPlayingSequence = false;
      });
    }

    // Clear text and images after sending with a small delay for smooth UX
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _model.textController!.clear();
        inputSentence = '';
        uploadedImagePaths.clear();
        uploadedImages.clear(); // Also clear the actual image files
      });
      debugPrint('🧹 Cleared text field and images after sending');

      // Stop loading animation after clearing
      _stopLoadingAnimation();
    });
  }

  void _playNextAnimationFromAPI() {
    if (_animationQueue.isEmpty || _wordQueue.isEmpty) {
      // Sequence finished, return to default animation
      setState(() {
        currentAnimation = defaultAnimation;
        currentWord = null;
        isPlayingSequence = false;
      });
      debugPrint(
          'Animation sequence completed. Returning to default animation.');
      return;
    }

    // Get the next animation data and word
    AnimationData nextAnimationData = _animationQueue.removeAt(0);
    String nextWord = _wordQueue.removeAt(0);

    setState(() {
      currentAnimation = nextAnimationData.url; // Use URL from API
      currentWord = nextWord;
    });

    // Use precise duration from API metadata for HandTalk-level timing
    int duration = nextAnimationData.metadata.duration;

    debugPrint(
        'Now playing: $nextWord (${nextAnimationData.url}) for ${duration}ms');

    // Preload next animation for seamless transition
    if (_animationQueue.isNotEmpty) {
      // The next animation URL is already cached, so ModelViewer will load it instantly
      debugPrint('🚀 Next animation preloaded for seamless transition');
    }

    // Set a timer to play the next animation with optimized timing for smooth transitions
    animationTimer = Timer(Duration(milliseconds: duration - 10), () {
      // Reduced overlap for smoother transition
      if (_animationQueue.isNotEmpty) {
        _playNextAnimationFromAPI();
      } else {
        // Sequence finished, return to default immediately
        setState(() {
          currentAnimation = defaultAnimation;
          currentWord = null;
          isPlayingSequence = false;
        });
        debugPrint(
            'Animation sequence completed. Returned to default animation.');
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
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            FFLocalizations.of(context).getText(
              'iriw5ix1' /* Voice to Sign */,
            ),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Space Grotesk',
                  letterSpacing: 0.0,
                  useGoogleFonts:
                      GoogleFonts.asMap().containsKey('Space Grotesk'),
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity, // Full width
                  height: double.infinity, // Full height
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            // Main animation viewer
                            currentAnimation != null
                                ? ModelViewer(
                                    key: ValueKey(currentAnimation),
                                    src: currentAnimation!,
                                    autoPlay: true,
                                    autoRotate: false,
                                    cameraControls: false,
                                    backgroundColor: Colors.transparent,
                                    cameraTarget: '0m 1.5m 0m',
                                    cameraOrbit: '0deg 75deg 2.5m',
                                  )
                                : const Center(
                                    child: Text(
                                      'No animation playing',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFFFAB317)),
                                    ),
                                  ),

                            // API Loading overlay (HandTalk-style)
                            if (isLoadingAnimations)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Color(0xFFFAB317),
                                          ),
                                          strokeWidth: 3.0,
                                        ),
                                        SizedBox(height: 12.0),
                                        Text(
                                          'Loading animations...',
                                          style: TextStyle(
                                            color: Color(0xFFFAB317),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Word tag overlay removed as requested by user
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // Modern unified input container with Claude-like design
              Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0), // Reduced horizontal margin for more space
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context)
                      .secondaryBackground, // Changed to secondary background
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: FlutterFlowTheme.of(context)
                        .alternate, // Alternate border color
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
                    // Moving line animation overlay
                    if (isMovingLineActive)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _movingLineAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24.0),
                                border: Border.all(
                                  color: Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                              child: CustomPaint(
                                painter: MovingLinePainter(
                                  progress: _movingLineAnimation.value,
                                  color: const Color(0xFFFAB317),
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
                              top: 12.0,
                              bottom: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Images (${uploadedImagePaths.length}):',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .bodySmallFamily,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        fontSize: 12.0,
                                        letterSpacing: 0.0,
                                        useGoogleFonts: GoogleFonts.asMap()
                                            .containsKey(
                                                FlutterFlowTheme.of(context)
                                                    .bodySmallFamily),
                                      ),
                                ),
                                const SizedBox(height: 8.0),
                                SizedBox(
                                  height: 60.0,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: uploadedImages.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              child: Image.file(
                                                uploadedImages[index],
                                                width: 60.0,
                                                height: 60.0,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: -4.0,
                                              right: -4.0,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                ),
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      uploadedImages
                                                          .removeAt(index);
                                                      uploadedImagePaths
                                                          .removeAt(index);
                                                    });
                                                  },
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16.0,
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
                                  color: FlutterFlowTheme.of(context)
                                      .alternate
                                      .withOpacity(0.5),
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
                            textCapitalization: TextCapitalization.sentences,
                            obscureText: false,
                            decoration: InputDecoration(
                              hintText: 'Type message',
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
                            maxLines: null,
                            minLines: 1,
                            keyboardType: TextInputType.multiline,
                            cursorColor: FlutterFlowTheme.of(context).primary,
                            onChanged: (text) {
                              setState(() {
                                inputSentence = text;
                              });
                            },
                            validator: _model.textControllerValidator
                                .asValidator(context),
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
                              // Add image/attachment button (Claude AI style)
                              Container(
                                margin: const EdgeInsets.only(right: 8.0),
                                decoration: BoxDecoration(
                                  color: isProcessingImage
                                      ? const Color(
                                          0xFFFAB317) // Yellow when active
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: isProcessingImage
                                      ? null
                                      : Border.all(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText
                                              .withOpacity(0.2),
                                          width: 1.0,
                                        ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8.0),
                                    onTap: isProcessingImage
                                        ? null
                                        : _showImagePickerBottomSheet,
                                    child: Container(
                                      width: 32.0,
                                      height: 32.0,
                                      child: Icon(
                                        Icons.attach_file,
                                        color: isProcessingImage
                                            ? Colors.black
                                            : FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        size: 18.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Microphone button (Claude AI style) - moved next to send button
                              Container(
                                margin: const EdgeInsets.only(right: 4.0),
                                decoration: BoxDecoration(
                                  color: voiceTrigger
                                      ? const Color(
                                          0xFFFAB317) // Yellow when active
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: voiceTrigger
                                      ? null
                                      : Border.all(
                                          color: FlutterFlowTheme.of(context)
                                              .primaryBackground
                                              .withOpacity(0.2),
                                          width: 1.0,
                                        ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8.0),
                                    onTap: () async {
                                      setState(() {
                                        voiceTrigger = !voiceTrigger;
                                      });
                                      if (voiceTrigger) {
                                        _model.startListening((recognizedText) {
                                          setState(() {
                                            _model.textController!.text =
                                                recognizedText;
                                            inputSentence = recognizedText;
                                          });
                                        });
                                      } else {
                                        _model.stopListening();
                                      }
                                    },
                                    child: Container(
                                      width: 32.0,
                                      height: 32.0,
                                      child: Icon(
                                        voiceTrigger
                                            ? Icons.mic
                                            : Icons.mic_none,
                                        color: voiceTrigger
                                            ? Colors.black
                                            : FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        size: 18.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Send button (Claude AI style with arrow up)
                              Container(
                                decoration: BoxDecoration(
                                  color: (inputSentence.trim().isNotEmpty ||
                                          uploadedImagePaths.isNotEmpty)
                                      ? const Color(
                                          0xFFFAB317) // Yellow when active
                                      : FlutterFlowTheme.of(context)
                                          .secondaryText
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8.0),
                                    onTap: (inputSentence.trim().isNotEmpty ||
                                            uploadedImagePaths.isNotEmpty)
                                        ? () {
                                            _handleSendAction();
                                          }
                                        : null,
                                    child: Container(
                                      width: 32.0,
                                      height: 32.0,
                                      child: Icon(
                                        Icons.arrow_upward_rounded,
                                        color: (inputSentence
                                                    .trim()
                                                    .isNotEmpty ||
                                                uploadedImagePaths.isNotEmpty)
                                            ? Colors
                                                .black // Black icon when active
                                            : FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        size: 18.0,
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
            ].addToEnd(SizedBox(height: 12.0)), // Reduced from 24.0 to 12.0
          ),
        ),
      ),
    );
  }

  TutorialCoachMark createPageWalkthrough(BuildContext context) =>
      TutorialCoachMark(
        targets: createWalkthroughTargets(context),
        onFinish: () async {
          safeSetState(() => _model.signifyScreen1Controller = null);
        },
        onSkip: () {
          return true;
        },
      );
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
    final borderRadius = 24.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Calculate the total perimeter path
    final path = Path()..addRRect(rrect);
    final totalLength = _calculatePathLength(path);
    final lineLength =
        totalLength * 0.3; // Increased line length for more visibility

    // Calculate current position based on progress
    final currentPosition = totalLength * progress;
    final startPosition = currentPosition - lineLength * 0.5;
    final endPosition = currentPosition + lineLength * 0.5;

    // Create path metrics to get position along the path
    final pathMetrics = path.computeMetrics().first;

    // Simple solid yellow paint - no gradients
    final paint = Paint()
      ..color = const Color(0xFFFAB317) // Simple solid yellow
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
