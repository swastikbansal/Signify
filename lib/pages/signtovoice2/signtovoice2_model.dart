import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:translator/translator.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/services/api_service.dart';
import '/services/api_config.dart';
import '/services/api_models.dart';
import 'signtovoice2_widget.dart' show Signtovoice2Widget;

class Signtovoice2Model extends FlutterFlowModel<Signtovoice2Widget> {
  ///  State fields for stateful widgets in this page.

  // API-based sign detection state
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
        debugPrint('Error in state change callback: $e');
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

  bool get isFrontCamera {
    return _cameraController?.description.lensDirection ==
        CameraLensDirection.front;
  }

  double? get cameraAspectRatio {
    return _cameraController?.value.aspectRatio;
  }

  // Store coordinate data
  String _lastUpdateTime = '';

  final List<String> _predictionHistory = [];

  final List<String> _currentSentence = [];

  List<String> get predictionHistory => _predictionHistory;

  String get latestPrediction =>
      _predictionHistory.isNotEmpty ? _predictionHistory.last : "";

  String get currentSentence => _currentSentence.join(' ');

  List<String> get sentenceWords => List.from(_currentSentence);

  // API related state
  // Use the unified API service instead of direct HTTP calls
  final ApiService _apiService = ApiService();

  bool _isApiEnabled = true;
  int _lastApiCallTime = 0;
  static const int _apiCallInterval = 200; // API call interval in milliseconds

  static const int _jpegQuality = 70; // Quality for JPEG encoding

  bool _apiInFlight = false;

  // Enhanced HTTP client with connection pooling
  late final http.Client _httpClient;

  void _initializeHttpClient() {
    _httpClient = http.Client();
  }

  // Text-to-Speech state
  FlutterTts? _flutterTts;
  bool _isTtsInitialized = false;
  bool _isSpeaking = false;
  String _selectedLanguage = 'en-US';
  double _speechRate = 0.5;
  double _speechVolume = 0.8;
  double _speechPitch = 1.0;
  bool _autoSpeakEnabled = false;
  bool _ttsToggleState = false;

  // Translation state
  final GoogleTranslator _translator = GoogleTranslator();
  bool _translationEnabled = true;
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

  // Removed landmark getters
  String get lastUpdateTime => _lastUpdateTime;

  // TTS getters
  bool get isTtsInitialized => _isTtsInitialized;

  bool get isSpeaking => _isSpeaking;

  String get selectedLanguage => _selectedLanguage;

  Map<String, String> get availableLanguages => Map.from(_availableLanguages);

  double get speechRate => _speechRate;

  double get speechVolume => _speechVolume;

  double get speechPitch => _speechPitch;

  bool get autoSpeakEnabled => _autoSpeakEnabled;

  bool get ttsToggleState => _ttsToggleState;

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
        debugPrint("TTS: Speech started");
      });

      _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
        // Don't change the toggle state - keep TTS enabled if it was enabled
        _notifyStateChange();
        debugPrint(
          "TTS: Speech completed - TTS remains ${_ttsToggleState ? 'ON' : 'OFF'}",
        );
      });

      _flutterTts!.setErrorHandler((msg) {
        _isSpeaking = false;
        _notifyStateChange();
        debugPrint("TTS Error: $msg");
      });

      _flutterTts!.setCancelHandler(() {
        _isSpeaking = false;
        _notifyStateChange();
        debugPrint("TTS: Speech cancelled");
      });

      // Set default TTS settings
      await _flutterTts!.setSpeechRate(_speechRate);
      await _flutterTts!.setVolume(_speechVolume);
      await _flutterTts!.setPitch(_speechPitch);
      await _flutterTts!.setLanguage(_selectedLanguage);

      _isTtsInitialized = true;
      debugPrint(
        "TTS initialized successfully with language: $_selectedLanguage",
      );
    } catch (e) {
      debugPrint("Error initializing TTS: $e");
      _isTtsInitialized = false;
    }
  }

  Future<void> speakText(String text) async {
    if (!_isTtsInitialized) {
      await initializeTts();
    }

    if (text.trim().isEmpty) {
      debugPrint("No text to speak");
      return;
    }

    try {
      // Stop any ongoing speech
      await stopSpeaking();

      // Set the language before speaking
      await _flutterTts!.setLanguage(_selectedLanguage);

      debugPrint("Speaking text: '$text' in language: $_selectedLanguage");
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint("Error speaking text: $e");
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
        debugPrint("TTS: Speech stopped");
      } catch (e) {
        debugPrint("Error stopping TTS: $e");
      }
    }
  }

  Future<void> setTtsLanguage(String languageCode) async {
    _selectedLanguage = languageCode;

    if (_flutterTts != null) {
      try {
        await _flutterTts!.setLanguage(_selectedLanguage);
        debugPrint("TTS language changed to: $_selectedLanguage");
        _notifyStateChange();

        // Retranslate current sentence when language changes
        if (_translationEnabled && _currentSentence.isNotEmpty) {
          await translateCurrentSentence();
        }
      } catch (e) {
        debugPrint("Error setting TTS language: $e");
      }
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);

    if (_flutterTts != null) {
      try {
        await _flutterTts!.setSpeechRate(_speechRate);
        debugPrint("TTS speech rate changed to: $_speechRate");
      } catch (e) {
        debugPrint("Error setting speech rate: $e");
      }
    }
  }

  Future<void> setSpeechVolume(double volume) async {
    _speechVolume = volume.clamp(0.0, 1.0);

    if (_flutterTts != null) {
      try {
        await _flutterTts!.setVolume(_speechVolume);
        debugPrint("TTS volume changed to: $_speechVolume");
      } catch (e) {
        debugPrint("Error setting speech volume: $e");
      }
    }
  }

  Future<void> setSpeechPitch(double pitch) async {
    _speechPitch = pitch.clamp(0.5, 2.0);

    if (_flutterTts != null) {
      try {
        await _flutterTts!.setPitch(_speechPitch);
        debugPrint("TTS pitch changed to: $_speechPitch");
      } catch (e) {
        debugPrint("Error setting speech pitch: $e");
      }
    }
  }

  // Method to speak current sentence
  Future<void> speakCurrentSentence() async {
    final text = textController?.text ?? '';
    if (text.isNotEmpty) {
      await speakText(text);
    } else {
      debugPrint("No text in the text field to speak");
    }
  }

  // Toggle TTS on/off with new behavior
  Future<void> toggleTts() async {
    if (_ttsToggleState) {
      // Currently ON - turn OFF
      _ttsToggleState = false;
      await stopSpeaking();
      debugPrint("TTS toggled OFF");
    } else {
      // Currently OFF - turn ON and speak entire sentence
      _ttsToggleState = true;
      await speakCurrentSentence();
      debugPrint("TTS toggled ON - speaking entire sentence");
    }
    _notifyStateChange();
  }

  // Toggle auto-speak mode
  void toggleAutoSpeak() {
    _autoSpeakEnabled = !_autoSpeakEnabled;
    debugPrint("Auto-speak ${_autoSpeakEnabled ? 'enabled' : 'disabled'}");
    _notifyStateChange();
  }

  // Set auto-speak mode
  void setAutoSpeak(bool enabled) {
    _autoSpeakEnabled = enabled;
    debugPrint("Auto-speak ${_autoSpeakEnabled ? 'enabled' : 'disabled'}");
    _notifyStateChange();
  }

  // Set TTS toggle state directly
  void setTtsToggleState(bool enabled) {
    _ttsToggleState = enabled;
    if (!enabled) {
      stopSpeaking(); // Stop any ongoing speech when turning off
    }
    debugPrint("TTS toggle set to: ${_ttsToggleState ? 'ON' : 'OFF'}");
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
        translateLangCode = translateLangCode.split(
          '-',
        )[0]; // Extract base language code
      }

      debugPrint("Translating '$text' to language: $translateLangCode");

      var translation = await _translator.translate(
        text,
        from: 'en',
        to: translateLangCode,
      );

      String translatedText = translation.text;
      debugPrint("Translation result: '$translatedText'");

      _isTranslating = false;
      _notifyStateChange();

      return translatedText;
    } catch (e) {
      debugPrint("Translation error: $e");
      _isTranslating = false;
      _notifyStateChange();
      return text; // Return original text on error
    }
  }

  // Method to enable/disable translation
  void setTranslationEnabled(bool enabled) {
    _translationEnabled = enabled;
    debugPrint("Translation ${_translationEnabled ? 'enabled' : 'disabled'}");
    _notifyStateChange();
  }

  // Method to translate and update current sentence
  Future<void> translateCurrentSentence() async {
    if (!_translationEnabled || _currentSentence.isEmpty) {
      return;
    }

    try {
      String currentText = _currentSentence.join(' ');
      String translatedText = await translateText(
        currentText,
        _selectedLanguage,
      );

      if (translatedText != currentText && textController != null) {
        textController!.text = translatedText;
        debugPrint(
          "Updated text field with translated text: '$translatedText'",
        );
      }
    } catch (e) {
      debugPrint("Error translating current sentence: $e");
    }
  }

  // Sentence management methods
  void _addWordToSentence(String word) async {
    if (word.trim().isEmpty) return;
    _currentSentence.add(word.trim());

    debugPrint(
      'Added word to sentence: "$word" -> "${_currentSentence.join(' ')}"',
    );

    // Translate the complete sentence to the selected language
    String currentSentenceText = _currentSentence.join(' ');
    String translatedText = currentSentenceText;

    if (_translationEnabled &&
        _selectedLanguage != 'en-US' &&
        _selectedLanguage != 'en-GB') {
      try {
        translatedText = await translateText(
          currentSentenceText,
          _selectedLanguage,
        );
      } catch (e) {
        debugPrint('Translation error: $e');
        translatedText = currentSentenceText;
      }
    }

    // Update text field with translated sentence
    if (textController != null) {
      textController!.text = translatedText;
    }

    // Auto-speak only the new word if TTS is toggled ON
    if (_ttsToggleState && _isTtsInitialized) {
      // Translate just the new word for speaking
      String wordToSpeak = word.trim();
      if (_translationEnabled &&
          _selectedLanguage != 'en-US' &&
          _selectedLanguage != 'en-GB') {
        try {
          wordToSpeak = await translateText(word.trim(), _selectedLanguage);
        } catch (e) {
          debugPrint('Translation error for new word: $e');
          wordToSpeak = word.trim(); // Fall back to original word
        }
      }

      // Speak only the new word
      await speakText(wordToSpeak);
      debugPrint("Speaking new word: '$wordToSpeak' (TTS is ON)");
    }
  }

  void clearSentence() {
    _currentSentence.clear();
    if (textController != null) {
      textController!.text = '';
    }
    // Reset TTS toggle state when sentence is cleared
    _ttsToggleState = false;
    debugPrint('Sentence cleared - TTS toggle reset to OFF');
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
          translatedText = await translateText(
            currentSentenceText,
            _selectedLanguage,
          );
        } catch (e) {
          debugPrint('Translation error: $e');
          translatedText = currentSentenceText; // Fall back to original text
        }
      }

      if (textController != null) {
        textController!.text = translatedText;
      }
      debugPrint(
        'Removed word: "$removedWord" -> "${_currentSentence.join(' ')}"',
      );
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

    _initializeHttpClient();

    initializeTts();
  }

  Future<Uint8List?> _convertCameraImageToJpeg(CameraImage image) async {
    try {
      late img.Image convertedImage;

      //Switching encoding on the bases of phone
      if (image.format.group == ImageFormatGroup.yuv420) {
        convertedImage = _convertYUV420toImage(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        convertedImage = img.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: image.planes[0].bytes.buffer,
        );
      } else if (image.format.group == ImageFormatGroup.jpeg) {
        debugPrint('Using native JPEG: ${image.planes[0].bytes.length} bytes');
        return image.planes[0].bytes;
      } else {
        debugPrint('Unsupported image format: ${image.format.group}');
        return null;
      }

      // Encode to JPEG with consistent quality
      final jpegBytes = img.encodeJpg(convertedImage, quality: _jpegQuality);
      debugPrint(
        'JPEG encoded: ${jpegBytes.length} bytes (${convertedImage.width}x${convertedImage.height}) q=$_jpegQuality',
      );
      return Uint8List.fromList(jpegBytes);
    } catch (e) {
      debugPrint('Error converting camera image to JPEG: $e');
      return null;
    }
  }

  // Convert YUV420 to RGB Image
  img.Image _convertYUV420toImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final convertedImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yPlane.bytesPerRow + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final int yValue = yPlane.bytes[yIndex];
        final int uValue = uPlane.bytes[uvIndex];
        final int vValue = vPlane.bytes[uvIndex];

        // Optimized YUV to RGB conversion
        final int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        final int g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .round()
                .clamp(0, 255);
        final int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        convertedImage.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }

    return convertedImage;
  }

  // Send camera frame to API for prediction
  Future<void> _sendFrameToApi(CameraImage image) async {
    try {
      if (_apiInFlight) {
        return; // Drop frame if a request is already in flight
      }
      // Throttle API calls to prevent overwhelming the server
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - _lastApiCallTime < _apiCallInterval) {
        return;
      }
      _lastApiCallTime = currentTime;

      _apiInFlight = true;

      // Convert camera image to JPEG
      final jpegBytes = await _convertCameraImageToJpeg(image);
      if (jpegBytes == null) {
        debugPrint('Failed to convert camera image to JPEG');
        _apiInFlight = false;
        return;
      }

      // Use the unified API service for frame processing
      try {
        final response = await _apiService.processFrame(
          frameBytes: jpegBytes,
          timestamp: currentTime.toString(),
          cameraType: isFrontCamera ? 'front' : 'back',
          width: image.width,
          height: image.height,
          filename: 'frame_$currentTime.jpg',
        );

        final elapsed = DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(currentTime))
            .inMilliseconds;
        debugPrint(
          'API responded in ${elapsed}ms status=${response.isSuccess}',
        );

        if (response.isSuccess && response.data != null) {
          final frameData = response.data!;
          debugPrint('Frame API call successful: ${frameData.status}');

          if (frameData.isSuccess) {
            // Extract prediction from successful response
            if (frameData.hasPrediction) {
              debugPrint(
                'Received prediction from frame API: ${frameData.prediction}',
              );

              _predictionHistory.add(frameData.prediction!);

              _addWordToSentence(frameData.prediction!);

              _notifyStateChange();
            }
          } else if (frameData.isCollecting) {
            // Still collecting frames, log progress
            debugPrint(
              'API collecting frames: ${frameData.message} (frames: ${frameData.frameCount})',
            );
          }
        } else {
          debugPrint('Frame API call failed: ${response.getErrorMessage()}');

          // Set error message to trigger red glow
          _errorMessage = 'API Error: ${response.statusCode}';
          _notifyStateChange();

          // Clear error after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (_errorMessage.startsWith('API Error:')) {
              _errorMessage = '';
              _notifyStateChange();
            }
          });
        }
      } catch (parseError) {
        // Handle JSON parsing errors specifically
        debugPrint('JSON parsing error in API response: $parseError');

        // Set a more specific error message for JSON issues
        _errorMessage = 'API Response Format Error';
        _notifyStateChange();

        // Clear error after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (_errorMessage == 'API Response Format Error') {
            _errorMessage = '';
            _notifyStateChange();
          }
        });
      }
    } on ApiException catch (e) {
      debugPrint('API exception sending frame: $e');

      // Set error message based on exception type
      if (e is TimeoutException) {
        _errorMessage = 'API timeout';
      } else if (e is NetworkException) {
        _errorMessage = 'Network Error: ${e.message.substring(0, 30)}...';
      } else {
        _errorMessage = 'API Error: ${e.message.substring(0, 30)}...';
      }
      _notifyStateChange();

      // Clear error after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (_errorMessage.startsWith('API') ||
            _errorMessage.startsWith('Network')) {
          _errorMessage = '';
          _notifyStateChange();
        }
      });
    } catch (e) {
      debugPrint('Error sending frame to API: $e');

      // Set error message to trigger red glow
      _errorMessage = 'Network Error: ${e.toString().substring(0, 30)}...';
      _notifyStateChange();

      // Clear error after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (_errorMessage.startsWith('Network Error:')) {
          _errorMessage = '';
          _notifyStateChange();
        }
      });
    } finally {
      _apiInFlight = false;
    }
  }

  // (Adaptive encoding removed – using fixed parameters)

  // Method to update API URL (now handled by ApiConfig)
  void setApiUrl(String url) {
    // Use the unified API configuration
    ApiConfig.setCustomBaseUrl(url);
    debugPrint('API URL updated via ApiConfig: $url');
  }

  // Method to toggle API calls
  void setApiEnabled(bool enabled) {
    _isApiEnabled = enabled;
    debugPrint(
      'API prediction ${enabled ? 'enabled' : 'disabled'} - using ${enabled ? 'remote' : 'local'} prediction',
    );
  }

  // Method to toggle between API-based and local prediction
  void togglePredictionMode() {
    _isApiEnabled = !_isApiEnabled;
    debugPrint(
      'Switched to ${_isApiEnabled ? 'API-based' : 'local'} prediction mode',
    );
    _notifyStateChange();
  }

  // Method to toggle skeleton overlay
  // (Removed skeleton overlay & coordinate transformation methods)

  // Method to get API status
  bool get isApiEnabled => _isApiEnabled;

  // Method to get current API URL (now from ApiConfig)
  String get apiUrl => ApiConfig.baseUrl;

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

  // Method to force coordinate extraction (useful for testing)
  // (Removed coordinate status & debug alignment utilities)

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Use FRONT camera for sign language (so user sees themselves like a mirror)
        final camera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          // (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          camera,
          ResolutionPreset.medium, // Sets the resolution of the camera
          enableAudio: false,
          imageFormatGroup:
              ImageFormatGroup.bgra8888, // Back to BGRA8888 for compatibility
        );

        await _cameraController!.initialize();

        // Set high quality camera settings after initialization
        try {
          await _cameraController!.setFlashMode(FlashMode.off);
          await _cameraController!.setFocusMode(FocusMode.auto);
          await _cameraController!.setExposureMode(ExposureMode.auto);

          // Additional quality settings for better image capture
          await _cameraController!.lockCaptureOrientation();

          // Set exposure compensation for better lighting (optional)
          // await _cameraController!.setExposureOffset(0.0);
        } catch (e) {
          debugPrint('Advanced camera settings not available: $e');
        }

        // Start image stream for camera processing
        if (_isDetecting) {
          await _cameraController!.startImageStream((CameraImage image) {
            _processCameraImage(image);
          });
        }

        _isCameraInitialized = true;
        _notifyStateChange();
        debugPrint(
          'Medium-quality camera initialized successfully: ${_cameraController!.description.name}',
        );
        debugPrint('Camera is front: $isFrontCamera');
        debugPrint(
          'Camera resolution: ${_cameraController!.value.previewSize}',
        );
        debugPrint(
          'Camera aspect ratio: ${cameraAspectRatio?.toStringAsFixed(3) ?? "Unknown"}',
        );
        debugPrint('Image format: ${ImageFormatGroup.bgra8888}');
        debugPrint('Resolution preset: Medium');
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _errorMessage = 'Camera initialization failed: $e';
      _isCameraInitialized = false;
      _notifyStateChange();
    }
  }

  // Add frame throttling variables
  bool _isProcessingFrame = false;

  void _processCameraImage(CameraImage image) {
    if (_isDetecting && _isInitialized && !_isProcessingFrame) {
      try {
        // Only process if no request in flight
        if (_apiInFlight) return;
        _isProcessingFrame = true;
        Timer(const Duration(seconds: 5), () {
          if (_isProcessingFrame) {
            _isProcessingFrame = false;
            debugPrint('Processing watchdog reset flag after 5s');
          }
        });

        // Debug logging (only occasionally to avoid spam)
        if (DateTime.now().millisecondsSinceEpoch % 1000 < 100) {
          debugPrint(
            'Processing camera image: ${image.width}x${image.height}, format: ${image.format.group.name}, planes: ${image.planes.length}',
          );
        }

        // Send frame to API for prediction instead of local processing
        if (_isApiEnabled) {
          _sendFrameToApi(image)
              .timeout(const Duration(seconds: 5))
              .catchError((e) => debugPrint('Frame send error: $e'))
              .whenComplete(() => _isProcessingFrame = false);
        } else {
          _isProcessingFrame = false;
        }
      } catch (e) {
        debugPrint('Error in image processing: $e');
        _isProcessingFrame = false;
      }
    } else {
      // Debug why processing is not happening
      if (DateTime.now().millisecondsSinceEpoch % 2000 < 100) {
        debugPrint(
          'Not processing image - isDetecting: $_isDetecting, isInitialized: $_isInitialized, isProcessing: $_isProcessingFrame',
        );
      }
    }
  }

  // Simplified camera dispose helper (replaces removed _disposeCamera)
  Future<void> _disposeActiveCamera() async {
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
      _isProcessingFrame = false;
      _notifyStateChange();
      debugPrint('Camera disposed');
    } catch (e) {
      debugPrint('Error disposing camera: $e');
    }
  }

  // (Simplified dispose cleanup)

  Future<void> toggleDetection() async {
    try {
      if (_isDetecting) {
        _isDetecting = false;
        _isInitialized = false; // Add this line
        _lastUpdateTime = '';
        _errorMessage = '';

        // Dispose camera
        await _disposeActiveCamera();
      } else {
        // Set detection flag first
        _isDetecting = true;
        _isCameraOn = true;
        _notifyStateChange();

        // Initialize camera with image stream
        await _initializeCamera();

        // Start detection
        try {
          _errorMessage = '';
          _isInitialized = true; // Add this line to set initialized to true
          debugPrint('Detection started - API-based processing');
          debugPrint(
            'Detection initialized: $_isInitialized, detecting: $_isDetecting',
          );
        } catch (e) {
          _errorMessage = 'Start detection error: $e';
          _isDetecting = false;
          _isInitialized = false; // Add this line
          await _disposeActiveCamera();
          debugPrint('Error starting detection: $e');
        }
      }
      _notifyStateChange();
    } catch (e) {
      debugPrint('Error toggling detection: $e');
      _isDetecting = false;
      _isInitialized = false; // Add this line
      _errorMessage = 'Toggle error: $e';
      _lastUpdateTime = '';

      await _disposeActiveCamera();
      _notifyStateChange();
    }
  }

  @override
  void dispose() {
    try {
      // Stop and dispose TTS
      if (_flutterTts != null) {
        _flutterTts!.stop();
        _flutterTts = null;
      }
      // Close persistent HTTP client
      _httpClient.close();

      // Clear all caches and coordinate data for memory optimization
      _predictionHistory.clear();
      _currentSentence.clear();
      // Landmark data already removed

      // Dispose camera
      _disposeActiveCamera();

      textFieldFocusNode?.dispose();
      textController?.dispose();

      // Clear state callback to prevent memory leaks
      _stateChangeCallback = null;

      debugPrint('SignToVoice2Model disposed successfully with memory cleanup');
    } catch (e) {
      debugPrint('Error during dispose: $e');
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
      ),
    },
    generatorVariables: debugGeneratorVariables,
    backendQueries: debugBackendQueries,
    componentStates: {
      ...widgetBuilderComponents.map(
        (key, value) => MapEntry(key, value.toWidgetClassDebugData()),
      ),
    }.withoutNulls,
    link:
        'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=signtovoice2',
    searchReference: 'reference=OgxzaWdudG92b2ljZTJQAVoMc2lnbnRvdm9pY2Uy',
    widgetClassName: 'signtovoice2',
  );
}
