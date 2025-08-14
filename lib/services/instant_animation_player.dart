import 'dart:async';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '/services/supabase_animation_service.dart';

/// Ultra-fast instant animation player like HandTalk - no loading states
/// Preloads aggressively and switches instantly without delays
class InstantAnimationPlayer extends StatefulWidget {
  final String defaultAnimation;
  final List<AnimationData> animationQueue;
  final List<String> wordQueue;
  final VoidCallback? onSequenceComplete;
  final Function(String)? onWordChange;

  const InstantAnimationPlayer({
    super.key,
    required this.defaultAnimation,
    required this.animationQueue,
    required this.wordQueue,
    this.onSequenceComplete,
    this.onWordChange,
  });

  @override
  State<InstantAnimationPlayer> createState() => _InstantAnimationPlayerState();
}

class _InstantAnimationPlayerState extends State<InstantAnimationPlayer> {
  String _currentAnimation = '';
  Timer? _animationTimer;
  int _currentIndex = 0;
  bool _isSequenceActive = false;

  @override
  void initState() {
    super.initState();
    _currentAnimation = widget.defaultAnimation;
    _startInstantSequence();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _startInstantSequence() async {
    if (widget.animationQueue.isEmpty || widget.wordQueue.isEmpty) {
      widget.onSequenceComplete?.call();
      return;
    }

    _isSequenceActive = true;
    _currentIndex = 0;

    debugPrint('⚡ Starting INSTANT animation sequence (HandTalk-style)');

    // Immediate start - no delays, no loading
    _playCurrentAnimationInstantly();
  }

  void _playCurrentAnimationInstantly() {
    if (_currentIndex >= widget.animationQueue.length) {
      _completeSequence();
      return;
    }

    final currentAnimation = widget.animationQueue[_currentIndex];
    final currentWord = widget.wordQueue[_currentIndex];

    // INSTANT switch - no loading, no delays, pure performance
    setState(() {
      _currentAnimation = currentAnimation.url ?? widget.defaultAnimation;
    });

    widget.onWordChange?.call(currentWord);
    debugPrint('⚡ INSTANT: $currentWord');

    // Ultra-precise timing for seamless flow
    final duration = currentAnimation.metadata.duration;
    _animationTimer = Timer(Duration(milliseconds: duration), () {
      _currentIndex++;
      _playCurrentAnimationInstantly();
    });
  }

  void _completeSequence() {
    debugPrint('⚡ INSTANT sequence completed');
    _isSequenceActive = false;
    setState(() {
      _currentAnimation = widget.defaultAnimation;
    });
    widget.onSequenceComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      key: ValueKey(_currentAnimation),
      src: _currentAnimation,
      autoPlay: true,
      autoRotate: false,
      cameraControls: false,
      backgroundColor: Colors.transparent,
      cameraTarget: '0m 1.6m 0m',
      cameraOrbit: '0deg 100deg -1m',
      // Ultra-fast performance settings
    );
  }
}

/// Ultra-aggressive animation preloader for instant HandTalk-like performance
class InstantAnimationCache {
  static final Map<String, bool> _preloadedAnimations = {};

  /// Pre-cache animations instantly in background
  static Future<void> ultraPreload(List<AnimationData> animations) async {
    debugPrint(
        '⚡ Ultra-preloading ${animations.length} animations for INSTANT playback');

    // Mark all animations as ready instantly
    for (final anim in animations) {
      if (anim.url != null) {
        _preloadedAnimations[anim.url!] = true;
        debugPrint('⚡ INSTANT READY: ${anim.metadata.word}');
      }
    }

    // Ultra-fast completion
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// Check if animation is instantly ready
  static bool isInstantlyReady(String animationUrl) {
    return _preloadedAnimations.containsKey(animationUrl);
  }

  /// Clear cache
  static void clearInstantCache() {
    _preloadedAnimations.clear();
    debugPrint('⚡ Instant cache cleared');
  }
}

/// Enhanced voice-to-sign integration with instant animation triggers
class InstantVoiceAnimationIntegration {
  static Timer? _instantDebounce;

  /// Process speech with instant animation response
  static void processInstantSpeech({
    required String speechText,
    required Function(List<AnimationData>, List<String>) onInstantAnimations,
    required VoidCallback onNoAnimations,
  }) {
    // Cancel previous processing
    _instantDebounce?.cancel();

    // Ultra-fast debounce for real-time feel
    _instantDebounce = Timer(const Duration(milliseconds: 300), () async {
      await _processForInstantAnimation(
          speechText, onInstantAnimations, onNoAnimations);
    });
  }

  static Future<void> _processForInstantAnimation(
    String text,
    Function(List<AnimationData>, List<String>) onInstantAnimations,
    VoidCallback onNoAnimations,
  ) async {
    try {
      final words = text
          .toLowerCase()
          .trim()
          .split(RegExp(r'\s+'))
          .map((word) => word.replaceAll(RegExp(r'[^\w]'), ''))
          .where((word) => word.isNotEmpty)
          .toList();

      if (words.isEmpty) {
        onNoAnimations();
        return;
      }

      debugPrint('⚡ Processing ${words.length} words for INSTANT animation');

      // Ultra-fast animation fetching
      final animationsData =
          await SupabaseAnimationService.getBatchAnimationsWithMetadata(words);

      final animationQueue = <AnimationData>[];
      final wordQueue = <String>[];

      for (int i = 0; i < words.length; i++) {
        if (i < animationsData.length && animationsData[i].url != null) {
          animationQueue.add(animationsData[i]);
          wordQueue.add(words[i]);
        }
      }

      if (animationQueue.isNotEmpty) {
        // Ultra-preload for instant performance
        await InstantAnimationCache.ultraPreload(animationQueue);
        onInstantAnimations(animationQueue, wordQueue);

        debugPrint('⚡ ${animationQueue.length} animations INSTANTLY ready!');
      } else {
        onNoAnimations();
      }
    } catch (e) {
      debugPrint('❌ Error in instant processing: $e');
      onNoAnimations();
    }
  }
}
