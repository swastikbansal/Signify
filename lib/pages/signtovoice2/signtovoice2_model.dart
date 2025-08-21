import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:translator/translator.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/services/performance_cache_manager.dart';
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

  bool get isFrontCamera {
    return _cameraController?.description.lensDirection ==
        CameraLensDirection.front;
  }

  double? get cameraAspectRatio {
    return _cameraController?.value.aspectRatio;
  }

  // Cache manager for improved performance
  final PerformanceCacheManager _cacheManager =
      PerformanceCacheManager.instance;

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
  String _apiUrl = 'http://192.168.29.42:5000/process_frame';

  // String _apiUrl = 'https://swastikbansal-signify.hf.space/process_frame';
  bool _isApiEnabled = true;
  int _lastApiCallTime = 0;
  static const int _apiCallInterval = 100; //ms

  static const int _jpegQuality = 80;

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
        print("TTS: Speech started");
      });

      _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
        // Don't change the toggle state - keep TTS enabled if it was enabled
        _notifyStateChange();
        print(
            "TTS: Speech completed - TTS remains ${_ttsToggleState ? 'ON' : 'OFF'}");
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

  // Toggle TTS on/off with new behavior
  Future<void> toggleTts() async {
    if (_ttsToggleState) {
      // Currently ON - turn OFF
      _ttsToggleState = false;
      await stopSpeaking();
      print("TTS toggled OFF");
    } else {
      // Currently OFF - turn ON and speak entire sentence
      _ttsToggleState = true;
      await speakCurrentSentence();
      print("TTS toggled ON - speaking entire sentence");
    }
    _notifyStateChange();
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

  // Set TTS toggle state directly
  void setTtsToggleState(bool enabled) {
    _ttsToggleState = enabled;
    if (!enabled) {
      stopSpeaking(); // Stop any ongoing speech when turning off
    }
    print("TTS toggle set to: ${_ttsToggleState ? 'ON' : 'OFF'}");
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
    // Always append word (duplicate suppression removed for simplicity)
    _currentSentence.add(word.trim());

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
          print('Translation error for new word: $e');
          wordToSpeak = word.trim(); // Fall back to original word
        }
      }

      // Speak only the new word
      await speakText(wordToSpeak);
      print("Speaking new word: '$wordToSpeak' (TTS is ON)");
    }
  }

  void clearSentence() {
    _currentSentence.clear();
    if (textController != null) {
      textController!.text = '';
    }
    // Reset TTS toggle state when sentence is cleared
    _ttsToggleState = false;
    print('Sentence cleared - TTS toggle reset to OFF');
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

    // Initialize HTTP client with connection pooling
    _initializeHttpClient();

    // Initialize TTS
    initializeTts();
  }

  // Convert CameraImage to JPEG bytes for API transmission
  Future<Uint8List?> _convertCameraImageToJpeg(CameraImage image) async {
    try {
      late img.Image convertedImage;

      if (image.format.group == ImageFormatGroup.yuv420) {
        // Handle YUV420 format (most common on Android)
        convertedImage = _convertYUV420toImage(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        // Handle BGRA8888 format (common on iOS and our preferred format)
        convertedImage = img.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: image.planes[0].bytes.buffer,
        );
      } else if (image.format.group == ImageFormatGroup.jpeg) {
        // Handle native JPEG - use directly but with quality control
        print('Using native JPEG: ${image.planes[0].bytes.length} bytes');
        return image.planes[0].bytes;
      } else {
        print('Unsupported image format: ${image.format.group}');
        return null;
      }

      // Encode to JPEG with consistent quality
      final jpegBytes = img.encodeJpg(convertedImage, quality: _jpegQuality);
      print(
          'JPEG encoded: ${jpegBytes.length} bytes (${convertedImage.width}x${convertedImage.height}) q=$_jpegQuality');
      return Uint8List.fromList(jpegBytes);
    } catch (e) {
      print('Error converting camera image to JPEG: $e');
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
  // Add connection pooling and retry logic
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
        print('Failed to convert camera image to JPEG');
        _apiInFlight = false;
        return;
      }

      // Create multipart request with enhanced connection pooling
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.headers['Connection'] = 'keep-alive';
      request.headers['Keep-Alive'] = 'timeout=30, max=100';

      // Add the image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'frame',
          jpegBytes,
          filename: 'frame_$currentTime.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Add additional metadata (wall clock + monotonic frame index)
      request.fields['timestamp'] = currentTime.toString();
      request.fields['camera_type'] = isFrontCamera ? 'front' : 'back';
      request.fields['width'] = image.width.toString();
      request.fields['height'] = image.height.toString();

      print('Sending frame to API: ${jpegBytes.length} bytes');

      // Send the request with timeout using persistent client
      http.StreamedResponse response;
      final sendStart = DateTime.now();
      try {
        response =
            await _httpClient.send(request).timeout(const Duration(seconds: 2));
      } on TimeoutException catch (_) {
        print('Frame API call timed out after 2s');
        _errorMessage = 'API timeout';
        _notifyStateChange();
        return;
      }

      final elapsed = DateTime.now().difference(sendStart).inMilliseconds;
      final responseString = await response.stream.bytesToString();
      print(
          'API responded in ${elapsed}ms status=${response.statusCode} len=${responseString.length}');

      if (response.statusCode == 200) {
        print('Frame API call successful: $responseString');
        // (Adaptive encoding removed – fixed size/quality used)

        // Parse the JSON response
        try {
          final responseData =
              json.decode(responseString) as Map<String, dynamic>;
          final status = responseData['status'] as String?;

          if (status == 'success') {
            // Extract prediction from successful response
            final prediction = responseData['prediction'] as String?;
            if (prediction != null &&
                prediction.isNotEmpty &&
                prediction != 'rest') {
              print('Received prediction from frame API: $prediction');

              // Update prediction history
              _predictionHistory.add(prediction);

              // Add word to sentence
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
          print('Error parsing frame API response: $parseError');
          print('Raw response: $responseString');
        }
      } else {
        print('Frame API call failed with status: ${response.statusCode}');
        print('Response: $responseString');

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
    } catch (e) {
      print('Error sending frame to API: $e');

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

  // Method to update API URL
  void setApiUrl(String url) {
    _apiUrl = url;
  }

  // Method to toggle API calls
  void setApiEnabled(bool enabled) {
    _isApiEnabled = enabled;
    print(
        'API prediction ${enabled ? 'enabled' : 'disabled'} - using ${enabled ? 'remote' : 'local'} prediction');
  }

  // Method to toggle between API-based and local prediction
  void togglePredictionMode() {
    _isApiEnabled = !_isApiEnabled;
    print(
        'Switched to ${_isApiEnabled ? 'API-based' : 'local'} prediction mode');
    _notifyStateChange();
  }

  // Method to toggle skeleton overlay
  // (Removed skeleton overlay & coordinate transformation methods)

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
          print('Advanced camera settings not available: $e');
        }

        // Start image stream for camera processing
        if (_isDetecting) {
          await _cameraController!.startImageStream((CameraImage image) {
            _processCameraImage(image);
          });
        }

        _isCameraInitialized = true;
        _notifyStateChange();
        print(
            'Medium-quality camera initialized successfully: ${_cameraController!.description.name}');
        print('Camera is front: $isFrontCamera');
        print('Camera resolution: ${_cameraController!.value.previewSize}');
        print(
            'Camera aspect ratio: ${cameraAspectRatio?.toStringAsFixed(3) ?? "Unknown"}');
        print('Image format: ${ImageFormatGroup.bgra8888}');
        print('Resolution preset: Medium');
      }
    } catch (e) {
      print('Error initializing camera: $e');
      _errorMessage = 'Camera initialization failed: $e';
      _isCameraInitialized = false;
      _notifyStateChange();
    }
  }

  // Add frame throttling variables
  // Simplified frame processing: drop frames while API request converting/sending
  bool _isProcessingFrame = false; // retained for watchdog safety

  void _processCameraImage(CameraImage image) {
    if (_isDetecting && _isInitialized && !_isProcessingFrame) {
      try {
        // Only process if no request in flight
        if (_apiInFlight) return; // Drop frame silently
        _isProcessingFrame = true; // Mark for watchdog
        Timer(const Duration(seconds: 5), () {
          if (_isProcessingFrame) {
            _isProcessingFrame = false;
            debugPrint('Processing watchdog reset flag after 5s');
          }
        });

        // Debug logging (only occasionally to avoid spam)
        if (DateTime.now().millisecondsSinceEpoch % 1000 < 100) {
          print(
              'Processing camera image: ${image.width}x${image.height}, format: ${image.format.group.name}, planes: ${image.planes.length}');
        }

        // Send frame to API for prediction instead of local processing
        if (_isApiEnabled) {
          _sendFrameToApi(image)
              .timeout(const Duration(seconds: 5))
              .catchError((e) => print('Frame send error: $e'))
              .whenComplete(() => _isProcessingFrame = false);
        } else {
          _isProcessingFrame = false;
        }
      } catch (e) {
        print('Error in image processing: $e');
        _isProcessingFrame = false;
      }
    } else {
      // Debug why processing is not happening
      if (DateTime.now().millisecondsSinceEpoch % 2000 < 100) {
        print(
            'Not processing image - isDetecting: $_isDetecting, isInitialized: $_isInitialized, isProcessing: $_isProcessingFrame');
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
      print('Camera disposed');
    } catch (e) {
      print('Error disposing camera: $e');
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
          print('Detection started - API-based processing');
          print(
              'Detection initialized: $_isInitialized, detecting: $_isDetecting');
        } catch (e) {
          _errorMessage = 'Start detection error: $e';
          _isDetecting = false;
          _isInitialized = false; // Add this line
          await _disposeActiveCamera();
          print('Error starting detection: $e');
        }
      }
      _notifyStateChange();
    } catch (e) {
      print('Error toggling detection: $e');
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

      // Dispose cache manager - use the performance cache manager
      _cacheManager.clearAll();

      // Dispose camera
      _disposeActiveCamera();

      textFieldFocusNode?.dispose();
      textController?.dispose();

      // Clear state callback to prevent memory leaks
      _stateChangeCallback = null;

      print('SignToVoice2Model disposed successfully with memory cleanup');
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
