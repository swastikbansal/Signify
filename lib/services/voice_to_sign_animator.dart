import 'dart:async';
import 'package:flutter/material.dart';
import '/services/supabase_animation_service.dart';

/// Enhanced voice-to-sign integration for seamless real-time animation
class VoiceToSignAnimator {
  static final VoiceToSignAnimator _instance = VoiceToSignAnimator._();
  static VoiceToSignAnimator get instance => _instance;

  VoiceToSignAnimator._();

  Timer? _debounceTimer;
  String _lastProcessedText = '';
  bool _isProcessing = false;

  /// Process speech input and trigger animations in real-time
  Future<Map<String, dynamic>> processSpeechForAnimation({
    required String speechText,
    required Function(List<AnimationData>, List<String>) onAnimationsReady,
    required VoidCallback onNoAnimations,
    Duration debounceDelay =
        const Duration(milliseconds: 800), // Quick response
  }) async {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Don't process if text hasn't changed significantly
    if (_isSimilarText(speechText, _lastProcessedText) || _isProcessing) {
      return {'status': 'skipped', 'reason': 'similar_text_or_processing'};
    }

    // Start debounce timer for real-time feel
    _debounceTimer = Timer(debounceDelay, () async {
      await _processTextForAnimation(
          speechText, onAnimationsReady, onNoAnimations);
    });

    return {'status': 'queued'};
  }

  /// Process final speech text immediately (when user stops speaking)
  Future<Map<String, dynamic>> processFinalSpeech({
    required String finalText,
    required Function(List<AnimationData>, List<String>) onAnimationsReady,
    required VoidCallback onNoAnimations,
  }) async {
    _debounceTimer?.cancel(); // Cancel any pending processing
    return await _processTextForAnimation(
        finalText, onAnimationsReady, onNoAnimations);
  }

  Future<Map<String, dynamic>> _processTextForAnimation(
    String text,
    Function(List<AnimationData>, List<String>) onAnimationsReady,
    VoidCallback onNoAnimations,
  ) async {
    if (_isProcessing || text.trim().isEmpty) {
      return {'status': 'busy_or_empty'};
    }

    _isProcessing = true;
    _lastProcessedText = text;

    debugPrint('🎤 Processing speech for animation: "$text"');

    try {
      // Parse words efficiently
      final words = text
          .toLowerCase()
          .trim()
          .split(RegExp(r'\s+'))
          .map((word) => word.replaceAll(RegExp(r'[^\w]'), ''))
          .where((word) => word.isNotEmpty)
          .toList();

      if (words.isEmpty) {
        onNoAnimations();
        return {'status': 'no_words'};
      }

      debugPrint('🔍 Processing ${words.length} words: $words');

      // Fetch animations efficiently
      final animationsData =
          await SupabaseAnimationService.getBatchAnimationsWithMetadata(words);

      final animationQueue = <AnimationData>[];
      final wordQueue = <String>[];

      for (int i = 0; i < words.length; i++) {
        if (i < animationsData.length && animationsData[i].url != null) {
          animationQueue.add(animationsData[i]);
          wordQueue.add(words[i]);
          debugPrint('✅ Animation ready: ${words[i]}');
        } else {
          debugPrint('❌ No animation for: ${words[i]}');
        }
      }

      if (animationQueue.isNotEmpty) {
        // Animations ready for instant playback
        onAnimationsReady(animationQueue, wordQueue);

        debugPrint(
            '🚀 ${animationQueue.length} animations ready for instant playback');
        return {
          'status': 'success',
          'animations': animationQueue.length,
          'words': wordQueue.length
        };
      } else {
        onNoAnimations();
        return {'status': 'no_animations'};
      }
    } catch (e) {
      debugPrint('❌ Error processing speech for animation: $e');
      onNoAnimations();
      return {'status': 'error', 'error': e.toString()};
    } finally {
      _isProcessing = false;
    }
  }

  /// Check if two text strings are similar enough to skip processing
  bool _isSimilarText(String newText, String oldText) {
    if (newText == oldText) return true;
    if (newText.isEmpty || oldText.isEmpty) return false;

    // Simple similarity check - if new text just extends old text
    return newText.contains(oldText) &&
        (newText.length - oldText.length) <
            3; // Only a few characters difference
  }

  /// Clear processing state
  void reset() {
    _debounceTimer?.cancel();
    _lastProcessedText = '';
    _isProcessing = false;
    debugPrint('🔄 VoiceToSignAnimator reset');
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    debugPrint('🗑️ VoiceToSignAnimator disposed');
  }
}

/// Enhanced voice integration widget for real-time sign language
class EnhancedVoiceToSignWidget extends StatefulWidget {
  final Widget child;
  final String defaultAnimation;
  final Function(List<AnimationData>, List<String>) onAnimationsReady;
  final VoidCallback onNoAnimations;
  final bool isVoiceActive;

  const EnhancedVoiceToSignWidget({
    super.key,
    required this.child,
    required this.defaultAnimation,
    required this.onAnimationsReady,
    required this.onNoAnimations,
    required this.isVoiceActive,
  });

  @override
  State<EnhancedVoiceToSignWidget> createState() =>
      _EnhancedVoiceToSignWidgetState();
}

class _EnhancedVoiceToSignWidgetState extends State<EnhancedVoiceToSignWidget> {
  @override
  void dispose() {
    VoiceToSignAnimator.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
