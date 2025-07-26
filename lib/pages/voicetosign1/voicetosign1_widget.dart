import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/walkthroughs/signify_screen_1.dart';
import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'dart:async';
import 'voicetosign1_model.dart';
export 'voicetosign1_model.dart';

class Voicetosign1Widget extends StatefulWidget {
  const Voicetosign1Widget({super.key});

  @override
  State<Voicetosign1Widget> createState() => _Voicetosign1WidgetState();
}

class _Voicetosign1WidgetState extends State<Voicetosign1Widget>
    with RouteAware, SingleTickerProviderStateMixin {
  late Voicetosign1Model _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final Map<String, String> wordToAnimationMap = {
    "baby": "assets/models/baby.glb",
    "cold": "assets/models/cold.glb",
    "book": "assets/models/book.glb",
    "drink": "assets/models/drink.glb",
    "teacher": "assets/models/teacher.glb",
    "work": "assets/models/work.glb",
    "boy": "assets/models/boy.glb",
    "happy": "assets/models/happy.glb",
  };

  final Map<String, int> animationDurations = {
    'assets/models/baby.glb': 3200,
    'assets/models/cold.glb': 4000,
    'assets/models/book.glb': 3800,
    'assets/models/drink.glb': 3200,
    'assets/models/teacher.glb': 4600,
    'assets/models/work.glb': 4000,
    'assets/models/boy.glb': 4800,
    'assets/models/happy.glb': 3600,
  };

  final String defaultAnimation = 'assets/models/model.glb';
  final int defaultDuration =
      3500; // Duration for default animation in milliseconds
  List<String> animationQueue = [];
  List<String> wordQueue = [];
  String? currentAnimation;
  Timer? animationTimer;
  String inputSentence = '';
  late AnimationController _fadeController;
  String? currentWord;
  bool isPlayingSequence = false;
  bool voiceTrigger = false; // Local state for microphone toggle

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
    animationQueue = [];
    wordQueue = [];
    currentAnimation = defaultAnimation;
    isPlayingSequence = false;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 200), // Faster fade duration for seamless transitions
    )..forward();
  }

  @override
  void dispose() {
    _model.dispose();
    animationTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleSendAction() {
    animationTimer?.cancel(); // Cancel any ongoing animation sequence

    if (inputSentence.isEmpty) {
      // Play the default animation if no input
      setState(() {
        animationQueue = [];
        wordQueue = [];
        currentAnimation = defaultAnimation;
        currentWord = null;
        isPlayingSequence = false;
      });
      debugPrint('No sentence provided. Playing default animation.');
      return;
    }

    // Parse sentence word by word and create animation queue
    List<String> words =
        inputSentence.toLowerCase().trim().split(RegExp(r'\s+'));
    List<String> animations = [];
    List<String> wordsToShow = [];

    for (String word in words) {
      // Remove punctuation from word
      String cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');

      if (wordToAnimationMap.containsKey(cleanWord)) {
        animations.add(wordToAnimationMap[cleanWord]!);
        wordsToShow.add(cleanWord);
        debugPrint('Added animation for word: $cleanWord');
      } else {
        debugPrint('No animation found for word: $cleanWord, skipping...');
      }
    }

    setState(() {
      animationQueue = animations;
      wordQueue = wordsToShow;
      isPlayingSequence = true;
    });

    if (animations.isNotEmpty) {
      debugPrint('Playing animations for words in order: $wordsToShow');
      // Start immediately without any delay
      _playNextAnimation();
    } else {
      debugPrint(
          'No animations found for any words. Playing default animation.');
      setState(() {
        currentAnimation = defaultAnimation;
        currentWord = null;
        isPlayingSequence = false;
      });
    }
  }

  void _playNextAnimation() {
    if (animationQueue.isEmpty || wordQueue.isEmpty) {
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

    // Get the next animation and word
    String nextAnimation = animationQueue.removeAt(0);
    String nextWord = wordQueue.removeAt(0);

    setState(() {
      currentAnimation = nextAnimation;
      currentWord = nextWord;
    });

    // Get the duration for the current animation (in milliseconds)
    int duration = animationDurations[nextAnimation] ?? defaultDuration;

    debugPrint('Now playing: $nextWord ($nextAnimation) for ${duration}ms');

    // Set a timer to play the next animation with minimal delay for seamless transition
    animationTimer = Timer(Duration(milliseconds: duration - 20), () {
      if (animationQueue.isNotEmpty) {
        _playNextAnimation();
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
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        width: 2.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: currentAnimation != null
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
                                        fontSize: 16, color: Color(0xFFFAB317)),
                                  ),
                                ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AlignedTooltip(
                      content: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          FFLocalizations.of(context).getText(
                            '2ymxzvnb' /* Enter your words or sentences ... */,
                          ),
                          style: FlutterFlowTheme.of(context)
                              .labelMedium
                              .override(
                                fontFamily: FlutterFlowTheme.of(context)
                                    .labelMediumFamily,
                                letterSpacing: 0.0,
                                useGoogleFonts: GoogleFonts.asMap().containsKey(
                                    FlutterFlowTheme.of(context)
                                        .labelMediumFamily),
                              ),
                        ),
                      ),
                      offset: 4.0,
                      preferredDirection: AxisDirection.up,
                      borderRadius: BorderRadius.circular(12.0),
                      backgroundColor: FlutterFlowTheme.of(context).alternate,
                      elevation: 4.0,
                      tailBaseWidth: 24.0,
                      tailLength: 24.0,
                      waitDuration: Duration(milliseconds: 10),
                      showDuration: Duration(milliseconds: 2000),
                      triggerMode: TooltipTriggerMode.tap,
                      child: Container(
                        width: 100.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primaryBackground,
                        ),
                        child: TextFormField(
                          controller: _model.textController,
                          focusNode: _model.textFieldFocusNode,
                          autofocus: false,
                          textCapitalization: TextCapitalization.sentences,
                          obscureText: false,
                          decoration: InputDecoration(
                            isDense: false,
                            labelText: FFLocalizations.of(context).getText(
                              'wz6eakba' /* Your Message */,
                            ),
                            labelStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .labelMediumFamily,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: GoogleFonts.asMap()
                                      .containsKey(FlutterFlowTheme.of(context)
                                          .labelMediumFamily),
                                  lineHeight: 1.0,
                                ),
                            alignLabelWithHint: false,
                            hintText: FFLocalizations.of(context).getText(
                              'v4uk70of' /* Type to translate... */,
                            ),
                            hintStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .labelMediumFamily,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: GoogleFonts.asMap()
                                      .containsKey(FlutterFlowTheme.of(context)
                                          .labelMediumFamily),
                                  lineHeight: 1.0,
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
                            fillColor:
                                FlutterFlowTheme.of(context).primaryBackground,
                            hoverColor:
                                FlutterFlowTheme.of(context).primaryBackground,
                          ),
                          style: FlutterFlowTheme.of(context)
                              .titleSmall
                              .override(
                                fontFamily: FlutterFlowTheme.of(context)
                                    .titleSmallFamily,
                                letterSpacing: 0.0,
                                useGoogleFonts: GoogleFonts.asMap().containsKey(
                                    FlutterFlowTheme.of(context)
                                        .titleSmallFamily),
                                lineHeight: 2.0,
                              ),
                          textAlign: TextAlign.start,
                          maxLines: 6,
                          minLines: 1,
                          cursorColor: FlutterFlowTheme.of(context).primary,
                          onChanged: (text) {
                            setState(() {
                              inputSentence = text; // Update input sentence
                            });
                          },
                          validator: _model.textControllerValidator
                              .asValidator(context),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: voiceTrigger
                          ? FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.1)
                          : FlutterFlowTheme.of(context).primaryBackground,
                      borderRadius: BorderRadius.circular(28.0),
                      border: voiceTrigger
                          ? Border.all(
                              color: FlutterFlowTheme.of(context).primary,
                              width: 2.0,
                            )
                          : null,
                      // Add a subtle shadow when active
                      boxShadow: voiceTrigger
                          ? [
                              BoxShadow(
                                color: FlutterFlowTheme.of(context)
                                    .primary
                                    .withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: FlutterFlowIconButton(
                      borderRadius: 28.0,
                      buttonSize: 56.0,
                      fillColor: Colors.transparent,
                      icon: Icon(
                        voiceTrigger ? Icons.mic : Icons.mic_off,
                        color: voiceTrigger
                            ? FlutterFlowTheme.of(context).primary
                            : FlutterFlowTheme.of(context).secondaryText,
                        size: 24.0,
                      ),
                      onPressed: () async {
                        // Toggle voice recognition state
                        setState(() {
                          voiceTrigger = !voiceTrigger;
                        });

                        if (voiceTrigger) {
                          // Clear previous text when starting fresh (optional)
                          // Uncomment the next line if you want to clear previous text when starting
                          // _model.clearSpeechText();

                          // Start speech recognition
                          _model.startListening((recognizedText) {
                            // Update the text field with accumulated recognized text
                            setState(() {
                              _model.textController!.text = recognizedText;
                              inputSentence = recognizedText;

                              // Move cursor to the end of text
                              _model.textController!.selection =
                                  TextSelection.fromPosition(
                                TextPosition(
                                    offset: _model.textController!.text.length),
                              );
                            });
                          });
                        } else {
                          // Stop speech recognition
                          _model.stopListening();
                        }
                      },
                    ),
                  ),
                  AlignedTooltip(
                    content: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        FFLocalizations.of(context).getText(
                          'tizyil5m' /* Press the send button to see t... */,
                        ),
                        style:
                            FlutterFlowTheme.of(context).labelMedium.override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .labelMediumFamily,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: GoogleFonts.asMap()
                                      .containsKey(FlutterFlowTheme.of(context)
                                          .labelMediumFamily),
                                ),
                      ),
                    ),
                    offset: 4.0,
                    preferredDirection: AxisDirection.up,
                    borderRadius: BorderRadius.circular(12.0),
                    backgroundColor: FlutterFlowTheme.of(context).alternate,
                    elevation: 4.0,
                    tailBaseWidth: 24.0,
                    tailLength: 24.0,
                    waitDuration: Duration(milliseconds: 10),
                    showDuration: Duration(milliseconds: 2000),
                    triggerMode: TooltipTriggerMode.longPress,
                    child: Align(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: FlutterFlowIconButton(
                        borderRadius: 100.0,
                        buttonSize: 56.0,
                        fillColor:
                            FlutterFlowTheme.of(context).secondaryBackground,
                        hoverColor:
                            FlutterFlowTheme.of(context).primaryBackground,
                        hoverIconColor: FlutterFlowTheme.of(context).primary,
                        icon: Icon(
                          Icons.send_rounded,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 30.0,
                        ),
                        showLoadingIndicator: false,
                        onPressed: () {
                          _handleSendAction(); // Trigger animation logic
                        },
                      ).addWalkthrough(
                        iconButtonO625l09g,
                        _model.signifyScreen1Controller,
                      ),
                    ),
                  ),
                ]
                    .divide(SizedBox(width: 8.0))
                    .addToStart(SizedBox(width: 16.0))
                    .addToEnd(SizedBox(width: 16.0)),
              ).addWalkthrough(
                row3qnw9877,
                _model.signifyScreen1Controller,
              ),
            ].addToEnd(SizedBox(height: 24.0)),
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
