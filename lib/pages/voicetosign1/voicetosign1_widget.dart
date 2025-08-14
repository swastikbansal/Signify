import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
// import '/walkthroughs/signify_screen_1.dart'; // Commented out to disable walkthrough
import '/services/supabase_animation_service.dart';
import '/services/safe_image_processor.dart';
import '/services/instant_animation_player.dart'; // Use instant animation player
// import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
//     show TutorialCoachMark; // Commented out to disable walkthrough
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:async';
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

  // Seamless animation player key for rebuilding
  Key _animationPlayerKey = UniqueKey();

  // Image handling variables - use paths instead of File objects for safety
  List<String> uploadedImagePaths = [];
  bool isProcessingImage = false;
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
      // Commented out walkthrough trigger to disable tutorial
      /*
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
      */
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

    // Moving line animation controller (Claude AI style)
    _movingLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Fast like Google/Claude
    );
    _movingLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _movingLineController,
      curve: Curves.easeInOutQuart, // Smooth curve like Claude
    ));
  }

  @override
  void dispose() {
    _model.dispose();
    _movingLineController.dispose();
    _textRecognizer.close();
    SafeImageProcessor.instance.dispose();
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
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 70,
      );

      if (pickedFile == null) {
        debugPrint('❌ No image selected');
        return;
      }

      await _processImageSafely(pickedFile, isFromCamera: false);
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      setState(() {
        isProcessingImage = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      debugPrint('📷 Starting camera...');

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 70,
      );

      if (pickedFile == null) {
        debugPrint('❌ No photo taken');
        return;
      }

      await _processImageSafely(pickedFile, isFromCamera: true);
    } catch (e) {
      debugPrint('❌ Error taking photo: $e');
      setState(() {
        isProcessingImage = false;
      });
    }
  }

  Future<void> _processImageSafely(XFile pickedFile,
      {bool isFromCamera = false}) async {
    setState(() {
      isProcessingImage = true;
    });

    debugPrint(
        '🔄 Processing ${isFromCamera ? 'camera' : 'gallery'} image safely...');

    try {
      // Use safe image processor with camera flag
      final result = await SafeImageProcessor.instance.processImageSafely(
        imageFile: pickedFile,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 70,
        isFromCamera: isFromCamera, // Pass camera flag for special handling
      );

      if (result['success'] == true) {
        final String extractedText = result['text'] ?? '';
        final String imagePath = result['imagePath'];

        debugPrint(
            '✅ Safe processing completed! Text: ${extractedText.length} chars');

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
          uploadedImagePaths.add(imagePath);

          isProcessingImage = false;
        });

        debugPrint(
            '✅ Image safely processed and added. Total: ${uploadedImagePaths.length}');
      } else {
        debugPrint('⚠️ Image processing failed safely');
        setState(() {
          isProcessingImage = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error in safe image processing: $e');
      setState(() {
        isProcessingImage = false;
      });
    }

    debugPrint('📸 Image processing completed safely');
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
      debugPrint('No sentence provided. Playing default animation.');
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

    debugPrint('⚡ INSTANT Send button pressed!');
    debugPrint('⚡ INSTANT processing text: ${inputSentence.trim()}');
    debugPrint('🖼️ Images to clear: ${uploadedImagePaths.length}');

    try {
      // Parse sentence word by word for INSTANT API processing
      List<String> words = inputSentence
          .toLowerCase()
          .trim()
          .split(RegExp(r'\s+'))
          .map((word) => word.replaceAll(RegExp(r'[^\w]'), ''))
          .where((word) => word.isNotEmpty)
          .toList();

      debugPrint('⚡ Processing words INSTANTLY: $words');

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
          debugPrint(
              '⚡ INSTANT animation ready: ${words[i]} (${animationsData[i].metadata.duration}ms)');
        } else {
          debugPrint('❌ No animation for: ${words[i]}');
          // Dynamic word suggestions for missing words
          _suggestSimilarWords(words[i]);
        }
      }

      setState(() {
        isPlayingSequence = true; // NO loading states
      });

      if (_animationQueue.isNotEmpty) {
        // NO preloading delays - instant performance like HandTalk
        await InstantAnimationCache.ultraPreload(_animationQueue);

        // Start predictive loading for better performance
        SupabaseAnimationService.preloadRelatedWords(
            _animationQueue.first.metadata.word);

        debugPrint('⚡ Starting INSTANT animation sequence for: $_wordQueue');
        _startSeamlessAnimationSequence();
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
    debugPrint('⚡ INSTANTLY cleared text field and images');
  }

  void _startSeamlessAnimationSequence() {
    setState(() {
      isPlayingSequence = true; // NO loading states for instant performance
      // Create new player key to rebuild the instant player
      _animationPlayerKey = UniqueKey();
    });
  }

  void _onAnimationSequenceComplete() {
    debugPrint('✅ Seamless animation sequence completed');
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
    debugPrint('🎯 Now playing: $word');
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
                            // Instant animation player or default ModelViewer
                            isPlayingSequence && _animationQueue.isNotEmpty
                                ? InstantAnimationPlayer(
                                    key: _animationPlayerKey,
                                    defaultAnimation: defaultAnimation,
                                    animationQueue: List.from(
                                        _animationQueue), // Copy to avoid modification issues
                                    wordQueue: List.from(_wordQueue),
                                    onSequenceComplete:
                                        _onAnimationSequenceComplete,
                                    onWordChange: _onCurrentWordChange,
                                  )
                                : ModelViewer(
                                    key: ValueKey(
                                        currentAnimation ?? defaultAnimation),
                                    src: currentAnimation ?? defaultAnimation,
                                    autoPlay: true,
                                    autoRotate: false,
                                    cameraControls: false,
                                    backgroundColor: Colors.transparent,
                                    cameraTarget:
                                        '0m 1.6m 0m', // Focus on upper chest area
                                    cameraOrbit:
                                        '0deg 100deg -1m', // Much closer for bigger avatar
                                  ),

                            // NO loading overlays for instant HandTalk-like performance

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
                    // Moving line animation overlay (Claude AI style)
                    if (isMovingLineActive)
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
                                      0xFFFAB317), // Yellow like Claude
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
                                    itemCount: uploadedImagePaths.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              child: SafeImagePreview(
                                                imagePath:
                                                    uploadedImagePaths[index],
                                                width: 60.0,
                                                height: 60.0,
                                                onRemove: () {
                                                  setState(() {
                                                    uploadedImagePaths
                                                        .removeAt(index);
                                                  });
                                                },
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
                                child: Tooltip(
                                  message: 'Attach image or document',
                                  decoration: BoxDecoration(
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                    borderRadius: BorderRadius.circular(8.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
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
                                      borderRadius: BorderRadius.circular(8.0),
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
                                              : FlutterFlowTheme.of(context)
                                                  .secondaryText,
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
                                child: Tooltip(
                                  message: voiceTrigger
                                      ? 'Stop voice recognition'
                                      : 'Start voice recognition',
                                  decoration: BoxDecoration(
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                    borderRadius: BorderRadius.circular(8.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
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
                                      borderRadius: BorderRadius.circular(8.0),
                                      onTap: () async {
                                        setState(() {
                                          voiceTrigger = !voiceTrigger;
                                        });
                                        if (voiceTrigger) {
                                          _model
                                              .startListening((recognizedText) {
                                            setState(() {
                                              _model.textController!.text =
                                                  recognizedText;
                                              inputSentence = recognizedText;
                                              // Use enhanced voice-to-sign integration
                                              _model.updateInputSentence(
                                                  recognizedText);
                                            });
                                          });
                                        } else {
                                          _model.stopListening();
                                          // Process final text when user stops speaking
                                          if (inputSentence.isNotEmpty) {
                                            _model
                                                .processFinalSpeechForAnimation(
                                                    inputSentence);
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
                                              : FlutterFlowTheme.of(context)
                                                  .secondaryText,
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
                                  color: (inputSentence.trim().isNotEmpty ||
                                          uploadedImagePaths.isNotEmpty)
                                      ? const Color(
                                          0xFFFAB317) // Yellow when active
                                      : FlutterFlowTheme.of(context)
                                          .secondaryText
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Tooltip(
                                  message: 'Send message for sign animation',
                                  decoration: BoxDecoration(
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                    borderRadius: BorderRadius.circular(8.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
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
                                      borderRadius: BorderRadius.circular(8.0),
                                      onTap: (inputSentence.trim().isNotEmpty ||
                                              uploadedImagePaths.isNotEmpty)
                                          ? () {
                                              _handleSendAction();
                                            }
                                          : null,
                                      child: SizedBox(
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ].addToEnd(
                const SizedBox(height: 12.0)), // Reduced from 24.0 to 12.0
          ),
        ),
      ),
    );
  }

  // Commented out walkthrough functionality to disable tutorial
  /*
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
  */
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
    const borderRadius = 16.0; // Match sign to voice page border radius
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect =
        RRect.fromRectAndRadius(rect, const Radius.circular(borderRadius));

    // Calculate the total perimeter path
    final path = Path()..addRRect(rrect);
    final totalLength = _calculatePathLength(path);

    // Create path metrics to get position along the path
    final pathMetrics = path.computeMetrics().first;

    // Single line animation that travels around the complete perimeter with completion effect
    if (progress < 0.85) {
      // Moving phase: single solid line travels around the perimeter
      final lineLength = totalLength *
          0.2; // Line covers 20% of perimeter for better visibility
      final currentPosition = (progress / 0.85) *
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
