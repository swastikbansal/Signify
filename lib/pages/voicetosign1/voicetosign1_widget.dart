import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/walkthroughs/signify_screen_1.dart';
import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
    'iit': 'assets/models/iit.glb',
    'bcom': 'assets/models/bcom.glb',
    'homicide': 'assets/models/homicide.glb',
    "baby": "assets/models/baby_default.glb",
    "cold": "assets/models/cold_default.glb",
    "book": "assets/models/book_default.glb",
    "teacher": "assets/models/teacher_default.glb",
    "work": "assets/models/work_default.glb",
    "boy": "assets/models/boy_default.glb",
    "happy": "assets/models/happy_default.glb",
  };

  final Map<String, int> animationDurations = {
    'assets/models/iit.glb': 10,
    'assets/models/homicide.glb': 15,
    'assets/models/bcom.glb': 16,
    'assets/models/baby_default.glb': 3,
    'assets/models/book_default.glb': 3,
    'assets/models/happy_default.glb': 2,
    'assets/models/teacher_default.glb': 5,
    'assets/models/work_default.glb': 4,
    'assets/models/boy_default.glb': 5,
    'assets/models/cold_default.glb': 4,
  };

  final String defaultAnimation = 'assets/models/model.glb';
  final int defaultDuration = 5; // Duration for default animation
  List<String> animationQueue = [];
  String? currentAnimation;
  Timer? animationTimer;
  String inputSentence = '';
  late AnimationController _fadeController;
  String? currentWord;

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
    animationQueue = [defaultAnimation];
    currentAnimation = defaultAnimation;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Smooth fade duration
    )..forward();
    _playNextAnimation();
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
        animationQueue = [defaultAnimation];
        currentWord = null;
      });
      debugPrint('No sentence provided. Playing default animation.');
    } else {
      // Parse sentence and add matching animations to the queue
      List<String> matches = wordToAnimationMap.entries
          .where((entry) =>
              inputSentence.toLowerCase().contains(entry.key.toLowerCase()))
          .map((entry) => entry.value)
          .toList();

      setState(() {
        animationQueue = matches.isEmpty ? [defaultAnimation] : matches;
        if (matches.isEmpty) {
          currentWord = null;
        } else {
          currentWord = wordToAnimationMap.entries
              .firstWhere((entry) => entry.value == matches[0])
              .key;
        }
      });

      debugPrint('Playing animations for matched words: $animationQueue');
    }

    _playNextAnimation();
  }

  void _playNextAnimation() {
    if (animationQueue.isEmpty) {
      return; // No animations to play
    }

    // Start fade-out animation
    _fadeController.reverse().then((_) {
      setState(() {
        currentAnimation =
            animationQueue.removeAt(0); // Get and remove the first animation
        currentWord = wordToAnimationMap.entries
            .firstWhere((entry) => entry.value == currentAnimation,
                orElse: () => MapEntry('', defaultAnimation))
            .key;
      });

      // Get the duration for the current animation
      int duration = animationDurations[currentAnimation!] ?? defaultDuration;

      // Start fade-in animation
      _fadeController.forward();

      // Set a timer to play the next animation
      animationTimer = Timer(Duration(seconds: duration), () {
        if (animationQueue.isNotEmpty) {
          _playNextAnimation();
        } else {
          setState(() {
            currentAnimation =
                defaultAnimation; // Show default animation when done
            currentWord = null;
          });
        }
      });

      debugPrint('Currently playing: $currentAnimation for $duration seconds');
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
                        if (currentWord != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              currentWord!,
                              style: TextStyle(
                                color: FlutterFlowTheme.of(context).primaryText,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _fadeController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _fadeController.value,
                                child: currentAnimation != null
                                    ? ModelViewer(
                                        key: ValueKey(currentAnimation),
                                        src: currentAnimation!,
                                        autoPlay: true,
                                        autoRotate: true,
                                        cameraControls: true,
                                        backgroundColor: Colors.transparent,
                                        cameraTarget: '0m 1.5m 0m',
                                        // Keeps the avatar centered
                                        cameraOrbit:
                                            '0deg 75deg 2.5m', // Adjust camera orbit for positioning
                                      )
                                    : const Center(
                                        child: Text(
                                          'No animation playing',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFFFAB317)),
                                        ),
                                      ),
                              );
                            },
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
                  AlignedTooltip(
                    content: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        FFLocalizations.of(context).getText(
                          'z013a10e' /* Press the microphone button, s... */,
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
                    child: FlutterFlowIconButton(
                      borderRadius: 100.0,
                      buttonSize: 50.0,
                      hoverColor: FlutterFlowTheme.of(context).alternate,
                      hoverIconColor: FlutterFlowTheme.of(context).primary,
                      icon: FaIcon(
                        FontAwesomeIcons.microphone,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 24.0,
                      ),
                      onPressed: () {
                        print('IconButton pressed ...');
                      },
                    ).addWalkthrough(
                      iconButtonIwoicpe5,
                      _model.signifyScreen1Controller,
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
                        showLoadingIndicator: true,
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
