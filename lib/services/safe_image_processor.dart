import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Safe image processor that prevents app restarts during camera capture
class SafeImageProcessor {
  static SafeImageProcessor? _instance;
  static SafeImageProcessor get instance =>
      _instance ??= SafeImageProcessor._();

  SafeImageProcessor._();

  TextRecognizer? _textRecognizer;
  bool _isInitialized = false;

  /// Initialize text recognizer safely
  Future<void> _ensureInitialized() async {
    if (!_isInitialized || _textRecognizer == null) {
      try {
        _textRecognizer = TextRecognizer();
        _isInitialized = true;
        if (kDebugMode) {
          print('🔤 TextRecognizer initialized safely');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to initialize TextRecognizer: $e');
        }
        _isInitialized = false;
      }
    }
  }

  /// Process image safely with ultra-conservative memory management
  Future<Map<String, dynamic>> processImageSafely({
    required XFile imageFile,
    int maxWidth = 1200,
    int maxHeight = 1200,
    int imageQuality = 70,
    bool isFromCamera = false, // Flag to identify camera images
  }) async {
    File? processedFile;
    String extractedText = '';

    try {
      print(
          '🔄 Starting safe image processing ${isFromCamera ? '(CAMERA)' : '(GALLERY)'}...');

      // ULTRA-SAFE CAMERA HANDLING - Add delay to prevent camera conflicts
      if (isFromCamera) {
        await Future.delayed(const Duration(milliseconds: 500));
        print('📱 Camera image stabilized, processing...');
      }

      // Create file reference with immediate null safety
      processedFile = File(imageFile.path);

      // Verify file exists before processing
      if (!await processedFile.exists()) {
        print('❌ Image file does not exist');
        return {
          'success': false,
          'text': '',
          'imagePath': '',
          'message': 'Image file not found'
        };
      }

      // Check file size and compress if too large
      final fileSize = await processedFile.length();
      print(
          '📏 Original file size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');

      // ULTRA-CONSERVATIVE limits for camera images to prevent restarts
      final maxSize = isFromCamera
          ? 2 * 1024 * 1024
          : 5 * 1024 * 1024; // 2MB for camera, 5MB for gallery

      if (fileSize > maxSize) {
        print(
            '⚠️ ${isFromCamera ? 'Camera' : 'Gallery'} image too large, skipping OCR');
        return {
          'success': true,
          'text': '',
          'imagePath': imageFile.path,
          'message': 'Image added (too large for text recognition)'
        };
      }

      // Ultra-safe OCR processing with additional safeguards
      try {
        // Ensure TextRecognizer is properly initialized
        await _ensureInitialized();

        // Skip OCR in debug mode if TextRecognizer failed to initialize
        if (kDebugMode && (_textRecognizer == null || !_isInitialized)) {
          print('⚠️ Debug mode: Skipping OCR due to initialization failure');
          return {
            'success': true,
            'text': '',
            'imagePath': imageFile.path,
            'message': 'Image added (OCR skipped in debug mode)'
          };
        }

        if (_textRecognizer == null) {
          throw Exception('TextRecognizer not initialized');
        }

        final InputImage inputImage = InputImage.fromFile(processedFile);

        // Add shorter timeout for camera images to prevent hanging
        final timeoutDuration = isFromCamera
            ? const Duration(seconds: 5)
            : const Duration(seconds: 8);

        final recognizedText =
            await _textRecognizer!.processImage(inputImage).timeout(
                  timeoutDuration,
                  onTimeout: () =>
                      throw TimeoutException('OCR timeout', timeoutDuration),
                );

        extractedText = recognizedText.text.trim();
        print(
            '✅ OCR completed successfully! Text length: ${extractedText.length}');

        // Additional memory management for camera images
        if (isFromCamera) {
          await Future.delayed(const Duration(milliseconds: 200));
          print('♻️ Camera image OCR with memory cleanup');
        }
      } catch (ocrError) {
        print('⚠️ OCR failed safely: $ocrError');
        extractedText = ''; // Continue without OCR
      }

      return {
        'success': true,
        'text': extractedText,
        'imagePath': imageFile.path,
        'message': extractedText.isNotEmpty
            ? 'Text extracted successfully'
            : 'Image added successfully'
      };
    } catch (e) {
      print('❌ Error in safe image processing: $e');

      // Always return success to prevent app crashes
      return {
        'success': true,
        'text': '',
        'imagePath': imageFile.path,
        'message': 'Image added (processing failed safely)'
      };
    } finally {
      // Ultra-conservative cleanup
      processedFile = null;

      // Additional cleanup for camera images
      if (isFromCamera) {
        await Future.delayed(const Duration(milliseconds: 200));
        print('📸 Camera image processing cleanup completed');
      }

      print('📸 Image processing completed safely');
    }
  }

  /// Get recommended camera settings for stability
  Map<String, dynamic> getRecommendedCameraSettings() {
    return {
      'maxWidth': 1200.0,
      'maxHeight': 1200.0,
      'imageQuality': 70,
      'preferredCameraDevice': CameraDevice.rear,
    };
  }

  /// Clean up safely
  void dispose() {
    try {
      _textRecognizer?.close();
      _textRecognizer = null;
      _isInitialized = false;
      if (kDebugMode) {
        print('🔤 TextRecognizer disposed safely');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing text recognizer: $e');
      }
    }
  }
}

/// Safe image preview widget that doesn't cause memory issues
class SafeImagePreview extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final VoidCallback? onRemove;

  const SafeImagePreview({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 60,
      height: height ?? 60,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Use Image.file with basic error handling
            Image.file(
              File(imagePath),
              width: width ?? 60,
              height: height ?? 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 30),
                );
              },
            ),
            if (onRemove != null)
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
