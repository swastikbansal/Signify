import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'signtovoice2_widget.dart' show Signtovoice2Widget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'package:camera/camera.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';

class Signtovoice2Model extends FlutterFlowModel<Signtovoice2Widget> {
  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? signifyScreen2Controller;

  // MediaPipe related state
  static const platform = MethodChannel('mediapipe_plugin');
  bool _isDetecting = false;
  bool _isInitialized = false;
  bool _isCameraReady = false;
  String _errorMessage = '';

  // Camera preview state
  CameraController? _cameraController;
  bool _isCameraOn = false;
  bool _isCameraInitialized = false;

  // Add state change callback
  void Function()? _stateChangeCallback;

  void setStateChangeCallback(void Function() callback) {
    _stateChangeCallback = callback;
  }

  void _notifyStateChange() {
    if (_stateChangeCallback != null) {
      try {
        _stateChangeCallback!();
      } catch (e) {
        print('Error in state change callback: $e');
      }
    }
  }

  bool get isDetecting => _isDetecting;

  bool get isInitialized => _isInitialized;

  bool get isCameraReady => _isCameraReady;

  bool get isCameraOn => _isCameraOn;

  bool get isCameraInitialized => _isCameraInitialized;

  CameraController? get cameraController => _cameraController;

  String get errorMessage => _errorMessage;

  // Camera information getters for skeleton overlay
  bool get isFrontCamera {
    return _cameraController?.description.lensDirection ==
        CameraLensDirection.front;
  }

  double? get cameraAspectRatio {
    return _cameraController?.value.aspectRatio;
  }

  // Store coordinate data
  List<List<Map<String, dynamic>>> _handLandmarks = [];
  List<List<Map<String, dynamic>>> _poseLandmarks = [];
  String _lastUpdateTime = '';

  // Enhanced coordinate storage for API
  List<double>? _leftHandCoords;
  List<double>? _rightHandCoords;
  List<double>? _poseCoords;
  List<String>? _handLabels; // To store hand labels (Left/Right)

  // Prediction history for debug
  List<String> _predictionHistory = [];

  // Sentence building state
  List<String> _currentSentence = [];
  String _lastPrediction = "";
  int _lastPredictionTime = 0;
  static const int _wordCooldownMs =
      2000; // 2 seconds cooldown between same words

  List<String> get predictionHistory => _predictionHistory;

  String get latestPrediction =>
      _predictionHistory.isNotEmpty ? _predictionHistory.last : "";

  String get currentSentence => _currentSentence.join(' ');

  List<String> get sentenceWords => List.from(_currentSentence);

  // API related state
  String _apiUrl =
      'http://192.168.137.235:5000/predict'; // Replace with your actual API endpoint
  bool _isApiEnabled = true;
  int _lastApiCallTime = 0;
  static const int _apiCallInterval =
      100; // Minimum interval between API calls (ms)

  // Skeleton overlay state
  bool _isSkeletonOverlayEnabled = true;
  bool _useCoordinateTransformation = true;

  // Text-to-Speech state
  FlutterTts? _flutterTts;
  bool _isTtsInitialized = false;
  bool _isSpeaking = false;
  String _selectedLanguage = 'en-US'; // Default language
  double _speechRate = 0.5;
  double _speechVolume = 0.8;
  double _speechPitch = 1.0;
  bool _autoSpeakEnabled = false; // Auto-speak new words when added

  // Translation state
  final GoogleTranslator _translator = GoogleTranslator();
  bool _translationEnabled = true; // Enable translation by default
  bool _isTranslating = false;

  // Available languages for TTS
  final Map<String, String> _availableLanguages = {
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
    'hi-IN': 'Hindi',
    'bn-IN': 'Bengali',
    'mr-IN': 'Marathi',
    'te-IN': 'Telugu',
    'gu-IN': 'Gujarati',
    'pa-IN': 'Punjabi',
    'kn-IN': 'Kannada',
    'ta-IN': 'Tamil',
    'ml-IN': 'Malayalam',
    'or-IN': 'Odia',
    'as-IN': 'Assamese',
    'ur-IN': 'Urdu',
  };

  // Mapping from TTS language codes to Google Translate language codes
  final Map<String, String> _languageCodeMapping = {
    'en-US': 'en',
    'en-GB': 'en',
    'hi-IN': 'hi',
    'bn-IN': 'bn',
    'mr-IN': 'mr',
    'te-IN': 'te',
    'gu-IN': 'gu',
    'pa-IN': 'pa',
    'kn-IN': 'kn',
    'ta-IN': 'ta',
    'ml-IN': 'ml',
    'or-IN': 'or',
    'as-IN': 'as',
    'ur-IN': 'ur',
  };

  List<List<Map<String, dynamic>>> get handLandmarks => _handLandmarks;

  List<List<Map<String, dynamic>>> get poseLandmarks => _poseLandmarks;

  String get lastUpdateTime => _lastUpdateTime;

  List<double>? get leftHandCoords => _leftHandCoords;

  List<double>? get rightHandCoords => _rightHandCoords;

  List<double>? get poseCoords => _poseCoords;

  List<String>? get handLabels => _handLabels;

  bool get isSkeletonOverlayEnabled => _isSkeletonOverlayEnabled;

  bool get useCoordinateTransformation => _useCoordinateTransformation;

  // TTS getters
  bool get isTtsInitialized => _isTtsInitialized;
  bool get isSpeaking => _isSpeaking;
  String get selectedLanguage => _selectedLanguage;
  Map<String, String> get availableLanguages => Map.from(_availableLanguages);
  double get speechRate => _speechRate;
  double get speechVolume => _speechVolume;
  double get speechPitch => _speechPitch;
  bool get autoSpeakEnabled => _autoSpeakEnabled;

  // Translation getters
  bool get translationEnabled => _translationEnabled;
  bool get isTranslating => _isTranslating;

  void resetState() {
    _errorMessage = '';
    _isInitialized = false;
    _isDetecting = false;
    _isCameraReady = false;
    _notifyStateChange();
  }

  // Text-to-Speech functionality
  Future<void> initializeTts() async {
    try {
      _flutterTts = FlutterTts();

      // Set up TTS handlers
      _flutterTts!.setStartHandler(() {
        _isSpeaking = true;
        _notifyStateChange();
        print("TTS: Speech started");
      });

      _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
        _notifyStateChange();
        print("TTS: Speech completed");
      });

      _flutterTts!.setErrorHandler((msg) {
        _isSpeaking = false;
        _notifyStateChange();
        print("TTS Error: $msg");
      });

      _flutterTts!.setCancelHandler(() {
        _isSpeaking = false;
        _notifyStateChange();
        print("TTS: Speech cancelled");
      });

      // Set default TTS settings
      await _flutterTts!.setSpeechRate(_speechRate);
      await _flutterTts!.setVolume(_speechVolume);
      await _flutterTts!.setPitch(_speechPitch);
      await _flutterTts!.setLanguage(_selectedLanguage);

      _isTtsInitialized = true;
      print("TTS initialized successfully with language: $_selectedLanguage");
    } catch (e) {
      print("Error initializing TTS: $e");
      _isTtsInitialized = false;
    }
  }

  Future<void> speakText(String text) async {
    if (!_isTtsInitialized) {
      await initializeTts();
    }

    if (text.trim().isEmpty) {
      print("No text to speak");
      return;
    }

    try {
      // Stop any ongoing speech
      await stopSpeaking();

      // Set the language before speaking
      await _flutterTts!.setLanguage(_selectedLanguage);

      print("Speaking text: '$text' in language: $_selectedLanguage");
      await _flutterTts!.speak(text);
    } catch (e) {
      print("Error speaking text: $e");
      _isSpeaking = false;
      _notifyStateChange();
    }
  }

  Future<void> stopSpeaking() async {
    if (_flutterTts != null && _isSpeaking) {
      try {
        await _flutterTts!.stop();
        _isSpeaking = false;
        _notifyStateChange();
        print("TTS: Speech stopped");
      } catch (e) {
        print("Error stopping TTS: $e");
      }
    }
  }

  Future<void> setTtsLanguage(String languageCode) async {
    _selectedLanguage = languageCode;

    if (_flutterTts != null) {
      try {
        await _flutterTts!.setLanguage(_selectedLanguage);
        print("TTS language changed to: $_selectedLanguage");
        _notifyStateChange();

        // Retranslate current sentence when language changes
        if (_translationEnabled && _currentSentence.isNotEmpty) {
          await translateCurrentSentence();
        }
      } catch (e) {
        print("Error setting TTS language: $e");
      }
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);

    if (_flutterTts != null) {
      try {
        await _flutterTts!.setSpeechRate(_speechRate);
        print("TTS speech rate changed to: $_speechRate");
      } catch (e) {
        print("Error setting speech rate: $e");
      }
    }
  }

  Future<void> setSpeechVolume(double volume) async {
    _speechVolume = volume.clamp(0.0, 1.0);

    if (_flutterTts != null) {
      try {
        await _flutterTts!.setVolume(_speechVolume);
        print("TTS volume changed to: $_speechVolume");
      } catch (e) {
        print("Error setting speech volume: $e");
      }
    }
  }

  Future<void> setSpeechPitch(double pitch) async {
    _speechPitch = pitch.clamp(0.5, 2.0);

    if (_flutterTts != null) {
      try {
        await _flutterTts!.setPitch(_speechPitch);
        print("TTS pitch changed to: $_speechPitch");
      } catch (e) {
        print("Error setting speech pitch: $e");
      }
    }
  }

  // Method to speak current sentence
  Future<void> speakCurrentSentence() async {
    final text = textController?.text ?? '';
    if (text.isNotEmpty) {
      await speakText(text);
    } else {
      print("No text in the text field to speak");
    }
  }

  // Toggle TTS on/off
  Future<void> toggleTts() async {
    if (_isSpeaking) {
      await stopSpeaking();
    } else {
      await speakCurrentSentence();
    }
  }

  // Toggle auto-speak mode
  void toggleAutoSpeak() {
    _autoSpeakEnabled = !_autoSpeakEnabled;
    print("Auto-speak ${_autoSpeakEnabled ? 'enabled' : 'disabled'}");
    _notifyStateChange();
  }

  // Set auto-speak mode
  void setAutoSpeak(bool enabled) {
    _autoSpeakEnabled = enabled;
    print("Auto-speak ${_autoSpeakEnabled ? 'enabled' : 'disabled'}");
    _notifyStateChange();
  }

  // Translation functionality
  Future<String> translateText(String text, String targetLanguage) async {
    if (!_translationEnabled || text.trim().isEmpty) {
      return text;
    }

    // If already in the target language (English), no need to translate
    if (targetLanguage == 'en' || targetLanguage == 'en-US') {
      return text;
    }

    try {
      _isTranslating = true;
      _notifyStateChange();

      // Get the Google Translate language code
      String translateLangCode =
          _languageCodeMapping[targetLanguage] ?? targetLanguage;
      if (translateLangCode.contains('-')) {
        translateLangCode =
            translateLangCode.split('-')[0]; // Extract base language code
      }

      print("Translating '$text' to language: $translateLangCode");

      var translation =
          await _translator.translate(text, from: 'en', to: translateLangCode);

      String translatedText = translation.text;
      print("Translation result: '$translatedText'");

      _isTranslating = false;
      _notifyStateChange();

      return translatedText;
    } catch (e) {
      print("Translation error: $e");
      _isTranslating = false;
      _notifyStateChange();
      return text; // Return original text on error
    }
  }

  // Method to enable/disable translation
  void setTranslationEnabled(bool enabled) {
    _translationEnabled = enabled;
    print("Translation ${_translationEnabled ? 'enabled' : 'disabled'}");
    _notifyStateChange();
  }

  // Method to translate and update current sentence
  Future<void> translateCurrentSentence() async {
    if (!_translationEnabled || _currentSentence.isEmpty) {
      return;
    }

    try {
      String currentText = _currentSentence.join(' ');
      String translatedText =
          await translateText(currentText, _selectedLanguage);

      if (translatedText != currentText && textController != null) {
        textController!.text = translatedText;
        print("Updated text field with translated text: '$translatedText'");
      }
    } catch (e) {
      print("Error translating current sentence: $e");
    }
  }

  // Sentence management methods
  void _addWordToSentence(String word) async {
    if (word.trim().isEmpty) return;

    String cleanWord = word.trim().toLowerCase();
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    // Avoid duplicate words within cooldown period
    if (_lastPrediction == cleanWord &&
        currentTime - _lastPredictionTime < _wordCooldownMs) {
      return;
    }

    _currentSentence.add(word.trim());
    _lastPrediction = cleanWord;
    _lastPredictionTime = currentTime;

    print('Added word to sentence: "$word" -> "${_currentSentence.join(' ')}"');

    // Translate the complete sentence to the selected language
    String currentSentenceText = _currentSentence.join(' ');
    String translatedText = currentSentenceText;

    if (_translationEnabled &&
        _selectedLanguage != 'en-US' &&
        _selectedLanguage != 'en-GB') {
      try {
        translatedText =
            await translateText(currentSentenceText, _selectedLanguage);
      } catch (e) {
        print('Translation error: $e');
        translatedText = currentSentenceText; // Fall back to original text
      }
    }

    // Update text field with translated sentence
    if (textController != null) {
      textController!.text = translatedText;
    }

    // Auto-speak the translated text if enabled
    if (_autoSpeakEnabled && _isTtsInitialized) {
      speakText(translatedText);
    }
  }

  void clearSentence() {
    _currentSentence.clear();
    if (textController != null) {
      textController!.text = '';
    }
    print('Sentence cleared');
    _notifyStateChange();
  }

  void removeLastWord() async {
    if (_currentSentence.isNotEmpty) {
      String removedWord = _currentSentence.removeLast();

      // Retranslate the remaining sentence
      String currentSentenceText = _currentSentence.join(' ');
      String translatedText = currentSentenceText;

      if (_translationEnabled &&
          _selectedLanguage != 'en-US' &&
          _selectedLanguage != 'en-GB' &&
          currentSentenceText.isNotEmpty) {
        try {
          translatedText =
              await translateText(currentSentenceText, _selectedLanguage);
        } catch (e) {
          print('Translation error: $e');
          translatedText = currentSentenceText; // Fall back to original text
        }
      }

      if (textController != null) {
        textController!.text = translatedText;
      }
      print('Removed word: "$removedWord" -> "${_currentSentence.join(' ')}"');
      _notifyStateChange();
    }
  }

  // State field(s) for DropDown widget.
  String? _dropDownValue;

  set dropDownValue(String? value) {
    _dropDownValue = value;
    debugLogWidgetClass(this);
  }

  String? get dropDownValue => _dropDownValue;

  FormFieldController<String>? dropDownValueController;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};

  @override
  void initState(BuildContext context) {
    debugLogWidgetClass(this);
    _setupMethodChannelListener();

    // Initialize TTS
    initializeTts();
  }

  void _setupMethodChannelListener() {
    try {
      platform.setMethodCallHandler((call) async {
        try {
          switch (call.method) {
            case 'onHandLandmarks':
              if (call.arguments != null && call.arguments['hands'] != null) {
                final handsRaw = call.arguments['hands'] as List<dynamic>;
                _handLandmarks =
                    handsRaw.map<List<Map<String, dynamic>>>((hand) {
                  final handRaw = hand as List<dynamic>;
                  return handRaw.map<Map<String, dynamic>>((landmark) {
                    return Map<String, dynamic>.from(
                        landmark as Map<dynamic, dynamic>);
                  }).toList();
                }).toList();
                _lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(
                        call.arguments['timestamp'] ?? 0)
                    .toString();

                // Extract coordinates and send to API
                _extractAndProcessCoordinates();

                // Print all hand landmarks to console for debugging
                // _handLandmarks.asMap().forEach((handIndex, hand) {
                //   String handLabel =
                //       _handLabels != null && handIndex < _handLabels!.length
                //           ? _handLabels![handIndex]
                //           : 'Unknown';
                //   print(
                //       '=== Hand $handIndex ($handLabel) - ${hand.length} landmarks ===');
                //   hand.asMap().forEach((landmarkIndex, landmark) {
                //     print(
                //         'Landmark $landmarkIndex: x=${landmark['x']}, y=${landmark['y']}, z=${landmark['z']}');
                //   });
                // });

                _notifyStateChange();
                print(
                    'Received hand landmarks: ${_handLandmarks.length} hands detected');

                // Log coordinate extraction results
                if (_leftHandCoords != null) {
                  print(
                      'Left hand coordinates extracted: ${_leftHandCoords!.length} values');
                }
                if (_rightHandCoords != null) {
                  print(
                      'Right hand coordinates extracted: ${_rightHandCoords!.length} values');
                }
              }
              break;

            case 'onPoseLandmarks':
              if (call.arguments != null && call.arguments['poses'] != null) {
                final posesRaw = call.arguments['poses'] as List<dynamic>;
                _poseLandmarks =
                    posesRaw.map<List<Map<String, dynamic>>>((pose) {
                  final poseRaw = pose as List<dynamic>;
                  return poseRaw.map<Map<String, dynamic>>((landmark) {
                    return Map<String, dynamic>.from(
                        landmark as Map<dynamic, dynamic>);
                  }).toList();
                }).toList();
                _lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(
                        call.arguments['timestamp'] ?? 0)
                    .toString();

                // Extract coordinates and send to API
                _extractAndProcessCoordinates();

                // Print all pose landmarks to console for debugging
                // _poseLandmarks.asMap().forEach((poseIndex, pose) {
                //   print('=== Pose $poseIndex (${pose.length} landmarks) ===');
                //   pose.asMap().forEach((landmarkIndex, landmark) {
                //     print(
                //         'Landmark $landmarkIndex: x=${landmark['x']}, y=${landmark['y']}, z=${landmark['z']}');
                //   });
                // });

                _notifyStateChange();
                print(
                    'Received pose landmarks: ${_poseLandmarks.length} poses detected');

                // Log pose coordinate extraction results
                if (_poseCoords != null) {
                  print(
                      'Pose coordinates extracted: ${_poseCoords!.length} values');
                }
              }
              break;

            case 'onPrediction':
              // Receive prediction from native side
              final prediction =
                  call.arguments?['prediction']?.toString() ?? "";

              print('Received prediction: $prediction');

              if (prediction.isNotEmpty) {
                _predictionHistory.add(prediction);
                print('Prediction history: $_predictionHistory');

                // Add word to sentence instead of replacing
                _addWordToSentence(prediction);

                _notifyStateChange();
              }
              break;

            case 'onError':
              _errorMessage = call.arguments?['error'] ?? 'Unknown error';
              _isDetecting = false;
              _isInitialized = false;
              _notifyStateChange();
              print('MediaPipe error: $_errorMessage');
              break;

            case 'onInitialized':
              _isInitialized = call.arguments?['success'] ?? false;
              _errorMessage = _isInitialized ? '' : 'Initialization failed';
              _notifyStateChange();
              print('MediaPipe initialized: $_isInitialized');
              break;

            case 'onCameraReady':
              _isCameraReady = call.arguments?['success'] ?? false;
              _notifyStateChange();
              print('Camera ready: $_isCameraReady');
              break;
          }
        } catch (e) {
          print('Error handling method channel call: $e');
          _errorMessage = 'Method channel error: $e';
          _notifyStateChange();
        }
      });
    } catch (e) {
      print('Error setting up method channel listener: $e');
      _errorMessage = 'Setup error: $e';
    }
  }

  // Deprecated: replaced by prediction from native
  // String _analyzeGesture(List<List<Map<String, dynamic>>> hands) {
  //   try {
  //     if (hands.isNotEmpty) {
  //       return "Gesture detected - ${hands.length} hand(s)";
  //     }
  //   } catch (e) {
  //     print('Error analyzing gesture: $e');
  //   }
  //   return "";
  // }

  // Enhanced coordinate extraction method similar to Python implementation
  void _extractAndProcessCoordinates() {
    try {
      // Reset coordinate data
      _leftHandCoords = null;
      _rightHandCoords = null;
      _poseCoords = null;
      _handLabels = null;

      // Extract hand coordinates more efficiently
      if (_handLandmarks.isNotEmpty) {
        List<String> labels = [];

        for (int i = 0; i < _handLandmarks.length; i++) {
          List<Map<String, dynamic>> hand = _handLandmarks[i];

          // Extract coordinates as flat list [x1, y1, z1, x2, y2, z2, ...]
          List<double> coords = [];
          for (var landmark in hand) {
            coords.add((landmark['x'] as num).toDouble());
            coords.add((landmark['y'] as num).toDouble());
            coords.add((landmark['z'] as num).toDouble());
          }

          // Determine hand label based on position or use index-based labeling
          // For better hand detection, we can use landmark positions to determine left/right
          String handLabel = _determineHandLabel(hand, i);
          labels.add(handLabel);

          if (handLabel == "Left") {
            _leftHandCoords = coords;
          } else {
            _rightHandCoords = coords;
          }
        }
        _handLabels = labels;
      }

      // Extract pose coordinates
      if (_poseLandmarks.isNotEmpty && _poseLandmarks[0].isNotEmpty) {
        List<double> coords = [];
        for (var landmark in _poseLandmarks[0]) {
          coords.add((landmark['x'] as num).toDouble());
          coords.add((landmark['y'] as num).toDouble());
          coords.add((landmark['z'] as num).toDouble());
        }
        _poseCoords = coords;
      }

      // Send to API if enabled and coordinates are available
      if (_isApiEnabled &&
          (_leftHandCoords != null ||
              _rightHandCoords != null ||
              _poseCoords != null)) {
        _sendCoordinatesToApi();
      }
    } catch (e) {
      print('Error extracting coordinates: $e');
    }
  }

  // Improved hand label determination
  String _determineHandLabel(List<Map<String, dynamic>> hand, int handIndex) {
    try {
      // Use landmark positions to determine left/right hand
      // Landmark 0 is wrist, landmark 9 is middle finger MCP
      if (hand.length > 9) {
        double wristX = (hand[0]['x'] as num).toDouble();
        double middleFingerX = (hand[9]['x'] as num).toDouble();

        // If middle finger is to the right of wrist, it's likely a right hand
        // This is a simplified heuristic and may need adjustment based on camera orientation
        if (middleFingerX > wristX) {
          return "Right";
        } else {
          return "Left";
        }
      }
    } catch (e) {
      print('Error determining hand label: $e');
    }

    // Fallback to index-based labeling
    return handIndex == 0 ? "Left" : "Right";
  }

  // Send coordinates to API
  Future<void> _sendCoordinatesToApi() async {
    try {
      // Throttle API calls to prevent overwhelming the server
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - _lastApiCallTime < _apiCallInterval) {
        return;
      }
      _lastApiCallTime = currentTime;

      // Prepare API data
      Map<String, dynamic> apiData = {
        'timestamp': currentTime,
        'left_hand': _leftHandCoords,
        'right_hand': _rightHandCoords,
        'pose': _poseCoords,
      };

      // Remove null values
      apiData.removeWhere((key, value) => value == null);

      // Only send if we have actual data
      if (apiData.length > 1) {
        // More than just timestamp
        await _makeApiCall(apiData);
      }
    } catch (e) {
      print('Error sending coordinates to API: $e');
    }
  }

  // Make the actual API call
  Future<void> _makeApiCall(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        print('API call successful: ${response.body}');

        // Parse the JSON response
        try {
          final responseData =
              json.decode(response.body) as Map<String, dynamic>;
          final status = responseData['status'] as String?;

          if (status == 'success') {
            // Extract prediction from successful response
            final prediction = responseData['prediction'] as String?;
            if (prediction != null && prediction.isNotEmpty) {
              print('Received prediction from API: $prediction');

              // Update prediction history
              _predictionHistory.add(prediction);

              // Add word to sentence instead of replacing
              _addWordToSentence(prediction);

              // Notify UI to update
              _notifyStateChange();
            }
          } else if (status == 'collecting') {
            // Still collecting frames, log progress
            final message = responseData['message'] as String?;
            final frameCount = responseData['frame_count'] as int?;
            print('API collecting frames: $message (frames: $frameCount)');
          }
        } catch (parseError) {
          print('Error parsing API response: $parseError');
          print('Raw response: ${response.body}');
        }
      } else {
        print('API call failed with status: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error making API call: $e');
      // Don't disable API on network errors, just log them
    }
  }

  // Method to update API URL
  void setApiUrl(String url) {
    _apiUrl = url;
  }

  // Method to toggle API calls
  void setApiEnabled(bool enabled) {
    _isApiEnabled = enabled;
  }

  // Method to toggle skeleton overlay
  void setSkeletonOverlayEnabled(bool enabled) {
    _isSkeletonOverlayEnabled = enabled;
    _notifyStateChange();
  }

  // Method to toggle coordinate transformation
  void setUseCoordinateTransformation(bool enabled) {
    _useCoordinateTransformation = enabled;
    _notifyStateChange();
  }

  // Method to get API status
  bool get isApiEnabled => _isApiEnabled;

  // Method to get current API URL
  String get apiUrl => _apiUrl;

  // Method to reset API call timer (useful for immediate API calls)
  void resetApiTimer() {
    _lastApiCallTime = 0;
  }

  // Sentence management public methods
  void clearCurrentSentence() {
    clearSentence();
  }

  void undoLastWord() {
    removeLastWord();
  }

  void setSentenceCooldown(int milliseconds) {
    // Allow dynamic adjustment of cooldown if needed
    // _wordCooldownMs = milliseconds; // Would need to make it non-const
  }

  int get sentenceWordCount => _currentSentence.length;

  bool get hasSentence => _currentSentence.isNotEmpty;

  // Enhanced method for better hand detection configuration
  Future<void> configureHandDetection({
    double minDetectionConfidence = 0.7, // Increase for better detection
    double minTrackingConfidence = 0.5,
    int maxNumHands = 2,
  }) async {
    try {
      await platform.invokeMethod('configureHandDetection', {
        'minDetectionConfidence': minDetectionConfidence,
        'minTrackingConfidence': minTrackingConfidence,
        'maxNumHands': maxNumHands,
      });
      print('Hand detection configured with improved settings');
    } catch (e) {
      print('Error configuring hand detection: $e');
    }
  }

  // Method to force coordinate extraction (useful for testing)
  void forceCoordinateExtraction() {
    _extractAndProcessCoordinates();
  }

  // Method to get coordinate extraction status
  Map<String, dynamic> getCoordinateStatus() {
    return {
      'hasLeftHand': _leftHandCoords != null,
      'hasRightHand': _rightHandCoords != null,
      'hasPose': _poseCoords != null,
      'leftHandPoints': _leftHandCoords?.length ?? 0,
      'rightHandPoints': _rightHandCoords?.length ?? 0,
      'posePoints': _poseCoords?.length ?? 0,
      'handLabels': _handLabels,
      'lastUpdate': _lastUpdateTime,
    };
  }

  // Debug method to print coordinate alignment information
  void debugCoordinateAlignment() {
    print('=== Coordinate Alignment Debug ===');
    print('Camera Type: ${isFrontCamera ? "Front" : "Back"}');
    print(
        'Camera Aspect Ratio: ${cameraAspectRatio?.toStringAsFixed(3) ?? "Unknown"}');
    print('Use Coordinate Transformation: $_useCoordinateTransformation');
    print('Skeleton Overlay Enabled: $_isSkeletonOverlayEnabled');

    if (_handLandmarks.isNotEmpty) {
      final firstHand = _handLandmarks[0];
      if (firstHand.isNotEmpty) {
        final wrist = firstHand[0];
        print(
            'Sample Wrist Coordinate: x=${wrist['x']}, y=${wrist['y']}, z=${wrist['z']}');
      }
    }

    if (_cameraController != null) {
      print('Camera Resolution: ${_cameraController!.value.previewSize}');
      print('Camera Description: ${_cameraController!.description}');
    }
    print('================================');
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Use back camera if available, otherwise use first camera
        final camera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420, // Explicitly set format
        );

        await _cameraController!.initialize();

        // Start image stream for MediaPipe processing
        if (_isDetecting) {
          await _cameraController!.startImageStream((CameraImage image) {
            _processCameraImage(image);
          });
        }

        _isCameraInitialized = true;
        _notifyStateChange();
        print(
            'Back camera initialized successfully with format: ${_cameraController!.description.name}');
      }
    } catch (e) {
      print('Error initializing camera: $e');
      _errorMessage = 'Camera initialization failed: $e';
      _isCameraInitialized = false;
      _notifyStateChange();
    }
  }

  void _processCameraImage(CameraImage image) {
    if (_isDetecting && _isInitialized) {
      try {
        // Only process every 3rd frame to avoid overwhelming the system
        if (DateTime.now().millisecondsSinceEpoch % 3 != 0) return;

        // Convert CameraImage to format suitable for MediaPipe
        final imageData = {
          'width': image.width,
          'height': image.height,
          'format': image.format.group.name,
          'planes': image.planes
              .map((plane) => {
                    'bytes': plane.bytes,
                    'bytesPerPixel': plane.bytesPerPixel ?? 1,
                    'bytesPerRow': plane.bytesPerRow,
                  })
              .toList(),
        };

        // Send image data to native MediaPipe (non-blocking)
        platform.invokeMethod('processImage', imageData).catchError((e) {
          print('Error processing image: $e');
        });
      } catch (e) {
        print('Error in image processing: $e');
      }
    }
  }

  Future<void> _disposeCamera() async {
    try {
      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await _cameraController!.dispose();
        _cameraController = null;
      }
      _isCameraInitialized = false;
      _isCameraOn = false;
      _notifyStateChange();
      print('Camera disposed');
    } catch (e) {
      print('Error disposing camera: $e');
    }
  }

  Future<void> toggleDetection() async {
    try {
      if (_isDetecting) {
        // Stop detection
        try {
          await platform.invokeMethod('stopDetection');
        } catch (e) {
          print('Error stopping detection: $e');
        }
        _isDetecting = false;
        _handLandmarks.clear();
        _poseLandmarks.clear();
        _lastUpdateTime = '';
        _errorMessage = '';

        // Clear coordinate data
        _leftHandCoords = null;
        _rightHandCoords = null;
        _poseCoords = null;
        _handLabels = null;

        // Optionally clear current sentence when stopping detection
        // clearSentence(); // Uncomment if you want to clear sentence on stop

        // Dispose camera
        await _disposeCamera();

        print('MediaPipe detection stopped');
      } else {
        // Check if initialized first
        if (!_isInitialized) {
          try {
            // Try to initialize MediaPipe first
            final result = await platform.invokeMethod('initialize');
            _isInitialized = result == true;
            if (!_isInitialized) {
              _errorMessage = 'Failed to initialize MediaPipe';
              _notifyStateChange();
              return;
            }

            // Configure hand detection for better second hand recognition
            await configureHandDetection(
              minDetectionConfidence:
                  0.6, // Lower threshold for better detection
              minTrackingConfidence: 0.4,
              maxNumHands: 2,
            );
          } catch (e) {
            _errorMessage = 'Initialization error: $e';
            _isInitialized = false;
            _notifyStateChange();
            print('MediaPipe initialization error: $e');
            return;
          }
        }

        // Set detection flag first
        _isDetecting = true;
        _isCameraOn = true;
        _notifyStateChange();

        // Initialize camera with image stream
        await _initializeCamera();

        // Start MediaPipe detection
        try {
          await platform.invokeMethod('startDetection');
          _errorMessage = '';
          print(
              'MediaPipe detection started - landmarks will be printed to console');
        } catch (e) {
          _errorMessage = 'Start detection error: $e';
          _isDetecting = false;
          await _disposeCamera();
          print('Error starting detection: $e');
        }
      }
      _notifyStateChange();
    } catch (e) {
      print('Error toggling detection: $e');
      _isDetecting = false;
      _errorMessage = 'Toggle error: $e';
      _handLandmarks.clear();
      _poseLandmarks.clear();
      _lastUpdateTime = '';

      // Clear coordinate data
      _leftHandCoords = null;
      _rightHandCoords = null;
      _poseCoords = null;
      _handLabels = null;
      await _disposeCamera();
      _notifyStateChange();
    }
  }

  @override
  void dispose() {
    try {
      // Stop MediaPipe detection
      if (_isDetecting) {
        platform.invokeMethod('stopDetection').catchError((e) {
          print('Error stopping detection during dispose: $e');
        });
      }

      // Stop and dispose TTS
      if (_flutterTts != null) {
        _flutterTts!.stop();
        _flutterTts = null;
      }

      // Dispose camera
      _disposeCamera();

      signifyScreen2Controller?.finish();
      textFieldFocusNode?.dispose();
      textController?.dispose();
    } catch (e) {
      print('Error during dispose: $e');
    }
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetStates: {
          'dropDownValue': debugSerializeParam(
            dropDownValue,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=signtovoice2',
            name: 'String',
            nullable: true,
          ),
          'textFieldText': debugSerializeParam(
            textController?.text,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=signtovoice2',
            name: 'String',
            nullable: true,
          )
        },
        generatorVariables: debugGeneratorVariables,
        backendQueries: debugBackendQueries,
        componentStates: {
          ...widgetBuilderComponents.map(
            (key, value) => MapEntry(
              key,
              value.toWidgetClassDebugData(),
            ),
          ),
        }.withoutNulls,
        link:
            'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=signtovoice2',
        searchReference: 'reference=OgxzaWdudG92b2ljZTJQAVoMc2lnbnRvdm9pY2Uy',
        widgetClassName: 'signtovoice2',
      );
}
