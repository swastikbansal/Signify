import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'isl_dict_widget.dart' show IslDictWidget;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '/services/google_drive_service.dart';
import '/services/google_drive_config.dart';

// Data Models for ISL Dictionary
class ISLSign {
  final String id;
  final String word;
  final String category;
  final String videoUrl;
  final String? imageUrl;
  final String description;
  final List<String> tags;
  final int difficulty; // 1-3 (Easy, Medium, Hard)
  final DateTime dateAdded;
  final int viewCount;
  final bool isFavorite;

  ISLSign({
    required this.id,
    required this.word,
    required this.category,
    required this.videoUrl,
    this.imageUrl,
    required this.description,
    required this.tags,
    required this.difficulty,
    required this.dateAdded,
    this.viewCount = 0,
    this.isFavorite = false,
  });
}

class WordOfTheDay {
  final String id;
  final String word;
  final String description;
  final String category;
  final String videoUrl;
  final String? imageUrl;
  final DateTime date;
  final bool isFavorite;

  WordOfTheDay({
    required this.id,
    required this.word,
    required this.description,
    required this.category,
    required this.videoUrl,
    this.imageUrl,
    required this.date,
    this.isFavorite = false,
  });
}

class ISLCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color backgroundColor;
  final Color shadowColor;
  final Color iconColor;
  final int signCount;
  final int learnedCount;

  ISLCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.backgroundColor,
    required this.shadowColor,
    required this.iconColor,
    required this.signCount,
    this.learnedCount = 0,
  });
}

class DailyTask {
  final String title;
  final String description;
  final int streakDays;
  final bool isCompleted;
  final int targetSigns;
  final int learnedToday;

  DailyTask({
    required this.title,
    required this.description,
    required this.streakDays,
    this.isCompleted = false,
    this.targetSigns = 5,
    this.learnedToday = 0,
  });
}

class IslDictModel extends FlutterFlowModel<IslDictWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  // Dictionary data
  List<ISLSign> allSigns = [];
  List<ISLSign> filteredSigns = [];
  List<ISLSign> recentlyViewedSigns = [];
  List<ISLCategory> categories = [];
  DailyTask? dailyTask;
  WordOfTheDay? wordOfTheDay;
  String selectedCategory = 'all';
  bool isLoading = false;

  // Google Drive integration
  List<GoogleDriveVideo> driveVideos = [];
  bool isLoadingDriveVideos = false;
  String? driveSearchError;

  // Video player for modal
  VideoPlayerController? videoController;
  bool isVideoInitialized = false;
  bool isVideoPlaying = false;
  String? currentVideoId;

  @override
  void initState(BuildContext context) {
    debugLogWidgetClass(this);
    _initializeData();

    // Test Google Drive configuration
    if (kDebugMode) {
      GoogleDriveService.testConfiguration();
    }
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
    videoController?.dispose();
  }

  // Required override methods for FlutterFlowModel
  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
    widgetParameters: debugGeneratorVariables,
    backendQueries: debugBackendQueries,
    componentStates: widgetBuilderComponents.map(
      (key, value) => MapEntry(key, value.toWidgetClassDebugData()),
    ),
  );

  Map<String, FlutterFlowModel> get widgetBuilderComponents =>
      <String, FlutterFlowModel>{};

  Map<String, DebugDataField> get debugGeneratorVariables =>
      <String, DebugDataField>{};

  Map<String, DebugDataField> get debugBackendQueries =>
      <String, DebugDataField>{};

  // Initialize mock data (replace with actual backend calls)
  void _initializeData() {
    _initializeCategories();
    _initializeSigns();
    _initializeDailyTask();
    _initializeRecentlyViewed();
    _initializeWordOfTheDay();
  }

  void _initializeCategories() {
    categories = [
      ISLCategory(
        id: 'alphabets',
        name: 'Alphabets',
        icon: Icons.sort_by_alpha,
        backgroundColor: const Color(0xFFFFE6CC),
        shadowColor: const Color(0xFF77630D),
        iconColor: const Color(0xFF77630D),
        signCount: 26,
        learnedCount: 12,
      ),
      ISLCategory(
        id: 'numbers',
        name: 'Numbers',
        icon: Icons.format_list_numbered,
        backgroundColor: const Color(0xFFE6F3FF),
        shadowColor: const Color(0xFF1565C0),
        iconColor: const Color(0xFF1565C0),
        signCount: 20,
        learnedCount: 8,
      ),
      ISLCategory(
        id: 'greetings',
        name: 'Greetings',
        icon: Icons.waving_hand,
        backgroundColor: const Color(0xFFE8F5E8),
        shadowColor: const Color(0xFF2E7D32),
        iconColor: const Color(0xFF2E7D32),
        signCount: 15,
        learnedCount: 5,
      ),
      ISLCategory(
        id: 'family',
        name: 'Family',
        icon: Icons.family_restroom,
        backgroundColor: const Color(0xFFFCE4EC),
        shadowColor: const Color(0xFFC2185B),
        iconColor: const Color(0xFFC2185B),
        signCount: 18,
        learnedCount: 3,
      ),
      ISLCategory(
        id: 'emotions',
        name: 'Emotions',
        icon: Icons.sentiment_satisfied,
        backgroundColor: const Color(0xFFF3E5F5),
        shadowColor: const Color(0xFF7B1FA2),
        iconColor: const Color(0xFF7B1FA2),
        signCount: 22,
        learnedCount: 7,
      ),
      ISLCategory(
        id: 'animals',
        name: 'Animals',
        icon: Icons.pets,
        backgroundColor: const Color(0xFFE0F2F1),
        shadowColor: const Color(0xFF00695C),
        iconColor: const Color(0xFF00695C),
        signCount: 25,
        learnedCount: 4,
      ),
      ISLCategory(
        id: 'colors',
        name: 'Colors',
        icon: Icons.palette,
        backgroundColor: const Color(0xFFFFF3E0),
        shadowColor: const Color(0xFFE65100),
        iconColor: const Color(0xFFE65100),
        signCount: 12,
        learnedCount: 9,
      ),
      ISLCategory(
        id: 'food',
        name: 'Food',
        icon: Icons.restaurant,
        backgroundColor: const Color(0xFFEDE7F6),
        shadowColor: const Color(0xFF512DA8),
        iconColor: const Color(0xFF512DA8),
        signCount: 30,
        learnedCount: 6,
      ),
    ];
  }

  void _initializeSigns() {
    // Sample ISL signs data
    allSigns = [
      // Alphabets
      ISLSign(
        id: 'sign_a',
        word: 'A',
        category: 'alphabets',
        videoUrl: 'assets/videos/alphabet_a.mp4',
        imageUrl: 'assets/images/alphabet_a.png',
        description: 'The letter A in Indian Sign Language',
        tags: ['alphabet', 'letter', 'basic'],
        difficulty: 1,
        dateAdded: DateTime.now().subtract(const Duration(days: 5)),
      ),
      ISLSign(
        id: 'sign_b',
        word: 'B',
        category: 'alphabets',
        videoUrl: 'assets/videos/alphabet_b.mp4',
        imageUrl: 'assets/images/alphabet_b.png',
        description: 'The letter B in Indian Sign Language',
        tags: ['alphabet', 'letter', 'basic'],
        difficulty: 1,
        dateAdded: DateTime.now().subtract(const Duration(days: 4)),
      ),
      // Numbers
      ISLSign(
        id: 'sign_1',
        word: '1',
        category: 'numbers',
        videoUrl: 'assets/videos/number_1.mp4',
        imageUrl: 'assets/images/number_1.png',
        description: 'Number one in Indian Sign Language',
        tags: ['number', 'counting', 'basic'],
        difficulty: 1,
        dateAdded: DateTime.now().subtract(const Duration(days: 3)),
      ),
      // Greetings
      ISLSign(
        id: 'sign_happy',
        word: 'Happy',
        category: 'greetings',
        videoUrl: 'assets/videos/happy.mp4',
        imageUrl: 'assets/images/happy.png',
        description: 'Emotion: Happy in Indian Sign Language',
        tags: ['emotion', 'happy', 'feeling', 'positive'],
        difficulty: 1,
        dateAdded: DateTime.now().subtract(const Duration(days: 2)),
        viewCount: 25,
      ),
      ISLSign(
        id: 'sign_child',
        word: 'Child',
        category: 'family',
        videoUrl: 'assets/videos/child.mp4',
        imageUrl: 'assets/images/child.png',
        description: 'Family member: Child in Indian Sign Language',
        tags: ['family', 'child', 'young', 'person'],
        difficulty: 2,
        dateAdded: DateTime.now().subtract(const Duration(days: 1)),
        viewCount: 18,
      ),
      // Family
      ISLSign(
        id: 'sign_good',
        word: 'Good',
        category: 'greetings',
        videoUrl: 'assets/videos/good.mp4',
        imageUrl: 'assets/images/good.png',
        description: 'Expression: Good in Indian Sign Language',
        tags: ['expression', 'good', 'positive', 'quality'],
        difficulty: 2,
        dateAdded: DateTime.now(),
        viewCount: 12,
      ),
      // Add more signs as needed...
    ];

    filteredSigns = List.from(allSigns);
  }

  void _initializeDailyTask() {
    dailyTask = DailyTask(
      title: 'Daily Practice',
      description: 'Learn 5 new signs today',
      streakDays: 10,
      isCompleted: false,
      targetSigns: 5,
      learnedToday: 2,
    );
  }

  void _initializeRecentlyViewed() {
    // Get recently viewed signs (from local storage or backend)
    recentlyViewedSigns = allSigns
        .where((sign) => sign.viewCount > 0)
        .take(4)
        .toList();
  }

  void _initializeWordOfTheDay() {
    // Initialize word of the day
    wordOfTheDay = WordOfTheDay(
      id: 'wotd_happy',
      word: 'Happy',
      description:
          'A feeling of joy, pleasure, or contentment. Used to express positive emotions.',
      category: 'Emotions',
      videoUrl: 'assets/videos/happy.mp4',
      imageUrl: 'assets/images/happy.png',
      date: DateTime.now(),
      isFavorite: false,
    );
  }

  // Enhanced search functionality with Google Drive integration
  Future<void> searchSigns(String query) async {
    if (query.isEmpty) {
      // Clear both local and drive results when no query
      filteredSigns.clear();
      driveVideos.clear();
      driveSearchError = null;
    } else {
      // Only search Google Drive videos - no local signs
      filteredSigns.clear(); // Don't show local signs in search results

      // Search Google Drive videos
      await searchDriveVideos(query);
    }
    // State will be updated automatically through setState in the widget
  }

  // Search Google Drive for videos
  Future<void> searchDriveVideos(String query) async {
    if (kDebugMode) {
      print('🚀 Starting Drive video search for: "$query"');
      print(' Google Drive configured: ${GoogleDriveService.isConfigured()}');
      GoogleDriveService.testConfiguration();
    }

    if (!GoogleDriveService.isConfigured()) {
      driveSearchError = 'Google Drive not configured';
      if (kDebugMode) {
        print('⚠️ Google Drive not configured, skipping search');
      }
      return;
    }

    isLoadingDriveVideos = true;
    driveSearchError = null;

    try {
      if (kDebugMode) {
        print('📡 Calling GoogleDriveService.searchVideos...');
        print('🎯 Target folder: ${GoogleDriveConfig.targetFolderId}');
      }
      driveVideos = await GoogleDriveService.searchVideos(query);
      driveSearchError = null;
      if (kDebugMode) {
        print('✅ Drive search completed. Found ${driveVideos.length} videos');
        for (var video in driveVideos) {
          print('📹 Found video: ${video.name} (ID: ${video.id})');
        }
      }
    } catch (e) {
      driveSearchError = 'Failed to search Drive: ${e.toString()}';
      driveVideos.clear();
      if (kDebugMode) {
        print('❌ Drive search failed: $e');
        print('🔍 Full error details: ${e.toString()}');
      }
    } finally {
      isLoadingDriveVideos = false;
    }
  }

  // Test method to check Google Drive access
  Future<void> testGoogleDriveAccess() async {
    if (kDebugMode) {
      print('🧪 Testing Google Drive access...');
    }

    if (!GoogleDriveService.isConfigured()) {
      if (kDebugMode) {
        print('❌ Google Drive not configured');
      }
      return;
    }

    try {
      // Test with a simple search for any video files
      final testResults = await GoogleDriveService.searchVideos('');
      if (kDebugMode) {
        print(
          '✅ Google Drive test successful. Found ${testResults.length} total videos',
        );
        for (var video in testResults.take(5)) {
          print('📹 Sample video: ${video.name}');
        }

        // Test specifically for 'happy'
        final happyResults = await GoogleDriveService.searchVideos('happy');
        print('🔍 Search for "happy": ${happyResults.length} results');
        for (var video in happyResults) {
          print('😊 Happy video: ${video.name}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google Drive test failed: $e');
      }
    }
  }

  // Manual test method - call this from the UI to test Drive access
  Future<void> manualTestDriveAccess() async {
    if (kDebugMode) {
      print('🧪 MANUAL TEST: Starting Google Drive access test...');
      print('📂 Target folder ID: ${GoogleDriveConfig.targetFolderId}');
    }

    try {
      // Test basic configuration
      GoogleDriveService.testConfiguration();

      // Test if service is configured
      final isConfigured = GoogleDriveService.isConfigured();
      if (kDebugMode) {
        print('🔧 Is configured: $isConfigured');
      }

      if (!isConfigured) {
        if (kDebugMode) {
          print('❌ Service not configured, aborting test');
        }
        return;
      }

      // Test search for any videos
      if (kDebugMode) {
        print('🔍 Testing search for any videos...');
      }

      final allVideos = await GoogleDriveService.searchVideos('');
      if (kDebugMode) {
        print('📹 Found ${allVideos.length} total videos');
        for (var video in allVideos.take(10)) {
          print('  - ${video.name} (${video.id})');
        }
      }

      // Test search for specific word
      if (kDebugMode) {
        print('🔍 Testing search for "happy"...');
      }

      final happyVideos = await GoogleDriveService.searchVideos('happy');
      if (kDebugMode) {
        print('😊 Found ${happyVideos.length} videos for "happy"');
        for (var video in happyVideos) {
          print('  - ${video.name} (${video.id})');
        }
      }

      // Update the UI with results
      driveVideos = happyVideos;
      driveSearchError = null;

      if (kDebugMode) {
        print('✅ Manual test completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Manual test failed: $e');
      }
      driveSearchError = e.toString();
    }
  }

  // Get total search results count (only Drive videos now)
  int getTotalSearchResults() {
    return driveVideos.length;
  }

  // Check if any results found (only Drive videos now)
  bool hasSearchResults() {
    return driveVideos.isNotEmpty;
  }

  // Get search status message (only for Drive videos now)
  String getSearchStatusMessage() {
    final driveCount = driveVideos.length;

    if (kDebugMode) {
      print('🔍 Search Status Debug:');
      print('  - Drive videos: $driveCount');
      print('  - Drive search error: $driveSearchError');
      print('  - Is loading Drive videos: $isLoadingDriveVideos');
    }

    if (driveCount == 0) {
      if (driveSearchError != null) {
        return 'No results found. Drive error: $driveSearchError';
      }
      return 'No sign language videos found. Try different keywords.';
    }

    String message =
        'Found $driveCount sign language video${driveCount == 1 ? '' : 's'}';

    // DEBUG: Force check what isConfigured returns
    final isConfigured = GoogleDriveService.isConfigured();
    if (kDebugMode) {
      print('🔍 DEBUG: isConfigured() returns: $isConfigured');
      print('🔍 DEBUG: driveCount: $driveCount');
      print('🔍 DEBUG: driveSearchError: $driveSearchError');
    }

    // Check if Google Drive is configured
    if (!isConfigured) {
      if (driveCount > 0) {
        message +=
            ' (Demo mode - configure real Google Drive API for actual results)';
      } else {
        message = 'Google Drive not configured for video search.';
      }
    }

    if (driveSearchError != null && driveSearchError!.isNotEmpty) {
      message += ' (Drive search error: $driveSearchError)';
    }

    return message;
  }

  // Category filtering
  Future<void> filterByCategory(String categoryId) async {
    selectedCategory = categoryId;
    await searchSigns(textController?.text ?? '');
  }

  // Alphabet filtering
  void filterByAlphabet(String letter) {
    selectedCategory = 'alphabets';
    // Filter signs that start with the specific letter
    filteredSigns = allSigns.where((sign) {
      return sign.word.toLowerCase().startsWith(letter.toLowerCase()) ||
          sign.category.toLowerCase() == 'alphabets';
    }).toList();
  }

  // Number filtering
  void filterByNumber(String number) {
    selectedCategory = 'numbers';
    // Filter signs related to the specific number
    filteredSigns = allSigns.where((sign) {
      return sign.word.contains(number) ||
          sign.category.toLowerCase() == 'numbers' ||
          sign.tags.any((tag) => tag.contains(number));
    }).toList();
  }

  // Add to recently viewed
  void addToRecentlyViewed(ISLSign sign) {
    recentlyViewedSigns.removeWhere((s) => s.id == sign.id);
    recentlyViewedSigns.insert(0, sign);
    if (recentlyViewedSigns.length > 6) {
      recentlyViewedSigns.removeLast();
    }
  }

  // Toggle favorite
  void toggleFavorite(String signId) {
    final signIndex = allSigns.indexWhere((sign) => sign.id == signId);
    if (signIndex != -1) {
      // Create a new ISLSign object with updated favorite status
      final currentSign = allSigns[signIndex];
      final updatedSign = ISLSign(
        id: currentSign.id,
        word: currentSign.word,
        category: currentSign.category,
        videoUrl: currentSign.videoUrl,
        imageUrl: currentSign.imageUrl,
        description: currentSign.description,
        tags: currentSign.tags,
        difficulty: currentSign.difficulty,
        dateAdded: currentSign.dateAdded,
        viewCount: currentSign.viewCount,
        isFavorite: !currentSign.isFavorite,
      );

      allSigns[signIndex] = updatedSign;

      // Update filtered signs if it contains this sign
      final filteredIndex = filteredSigns.indexWhere(
        (sign) => sign.id == signId,
      );
      if (filteredIndex != -1) {
        filteredSigns[filteredIndex] = updatedSign;
      }

      // Update recently viewed if it contains this sign
      final recentIndex = recentlyViewedSigns.indexWhere(
        (sign) => sign.id == signId,
      );
      if (recentIndex != -1) {
        recentlyViewedSigns[recentIndex] = updatedSign;
      }
    }
  }

  // Learning progress methods
  void markSignAsLearned(String signId) {
    // Update learning progress in backend
    // Update daily task progress
    if (dailyTask != null) {
      dailyTask = DailyTask(
        title: dailyTask!.title,
        description: dailyTask!.description,
        streakDays: dailyTask!.streakDays,
        isCompleted: dailyTask!.learnedToday + 1 >= dailyTask!.targetSigns,
        targetSigns: dailyTask!.targetSigns,
        learnedToday: (dailyTask!.learnedToday + 1).clamp(
          0,
          dailyTask!.targetSigns,
        ),
      );
    }

    // Mark the sign as learned (you could add a learned property to ISLSign in the future)
    // For now, we'll just increment the view count to show it's been interacted with
    final signIndex = allSigns.indexWhere((sign) => sign.id == signId);
    if (signIndex != -1) {
      final currentSign = allSigns[signIndex];
      final updatedSign = ISLSign(
        id: currentSign.id,
        word: currentSign.word,
        category: currentSign.category,
        videoUrl: currentSign.videoUrl,
        imageUrl: currentSign.imageUrl,
        description: currentSign.description,
        tags: currentSign.tags,
        difficulty: currentSign.difficulty,
        dateAdded: currentSign.dateAdded,
        viewCount: currentSign.viewCount + 1,
        isFavorite: currentSign.isFavorite,
      );

      allSigns[signIndex] = updatedSign;

      // Update filtered signs if it contains this sign
      final filteredIndex = filteredSigns.indexWhere(
        (sign) => sign.id == signId,
      );
      if (filteredIndex != -1) {
        filteredSigns[filteredIndex] = updatedSign;
      }

      // Update recently viewed if it contains this sign
      final recentIndex = recentlyViewedSigns.indexWhere(
        (sign) => sign.id == signId,
      );
      if (recentIndex != -1) {
        recentlyViewedSigns[recentIndex] = updatedSign;
      }
    }
  }

  // Filter methods
  List<ISLSign> getSignsByCategory(String categoryId) {
    return allSigns.where((sign) => sign.category == categoryId).toList();
  }

  // Get progress for category
  double getCategoryProgress(String categoryId) {
    final category = categories.firstWhere((cat) => cat.id == categoryId);
    return category.signCount > 0
        ? category.learnedCount / category.signCount
        : 0.0;
  }

  // Get daily task progress
  double getDailyTaskProgress() {
    return dailyTask != null && dailyTask!.targetSigns > 0
        ? (dailyTask!.learnedToday / dailyTask!.targetSigns).clamp(0.0, 1.0)
        : 0.0;
  }

  // Navigation and interaction methods
  void viewSignDetails(ISLSign sign) {
    addToRecentlyViewed(sign);
    // In a real app, navigate to sign details page
    // context.pushNamed('signDetails', extra: sign);
  }

  void startDailyTask() {
    // Navigate to daily task/practice mode
    // This would typically start a learning session
  }

  // Word of the Day methods
  void viewWordOfTheDay() {
    // Mark word of the day as viewed
    // This could update analytics or user progress
  }

  void toggleFavoriteWordOfTheDay() {
    if (wordOfTheDay != null) {
      wordOfTheDay = WordOfTheDay(
        id: wordOfTheDay!.id,
        word: wordOfTheDay!.word,
        description: wordOfTheDay!.description,
        category: wordOfTheDay!.category,
        videoUrl: wordOfTheDay!.videoUrl,
        imageUrl: wordOfTheDay!.imageUrl,
        date: wordOfTheDay!.date,
        isFavorite: !wordOfTheDay!.isFavorite,
      );
    }
  }

  // Enhanced Word of the Day methods
  void markWordOfTheDayAsLearned() {
    if (wordOfTheDay != null) {
      // Mark as learned and update daily task progress
      markSignAsLearned(wordOfTheDay!.id);

      // Update word of the day status
      wordOfTheDay = WordOfTheDay(
        id: wordOfTheDay!.id,
        word: wordOfTheDay!.word,
        description: wordOfTheDay!.description,
        category: wordOfTheDay!.category,
        videoUrl: wordOfTheDay!.videoUrl,
        imageUrl: wordOfTheDay!.imageUrl,
        date: wordOfTheDay!.date,
        isFavorite: wordOfTheDay!.isFavorite,
      );
    }
  }

  // Get learning streak for word of the day feature
  int getWordOfTheDayStreak() {
    // This would typically come from user's learning history
    // For now, return the daily task streak
    return dailyTask?.streakDays ?? 0;
  }

  // Check if word of the day has been learned today
  bool hasLearnedWordOfTheDayToday() {
    // This would check if user has completed today's word
    // For demo purposes, return false to encourage interaction
    return false;
  }

  // Get difficulty rating for current word
  int getWordOfTheDayDifficulty() {
    if (wordOfTheDay?.word == 'Hello') return 1;
    if (wordOfTheDay?.word == 'Thank You') return 2;
    return 2; // Default medium difficulty
  }

  // Get estimated learning time
  String getEstimatedLearningTime() {
    final difficulty = getWordOfTheDayDifficulty();
    switch (difficulty) {
      case 1:
        return '2-3 min';
      case 2:
        return '3-5 min';
      case 3:
        return '5-8 min';
      default:
        return '3-5 min';
    }
  }

  // Get word popularity level
  String getWordPopularity() {
    if (wordOfTheDay?.word == 'Hello' || wordOfTheDay?.word == 'Thank You') {
      return 'High';
    }
    return 'Medium';
  }

  // Add Drive video to recently viewed (placeholder for now)
  void addDriveVideoToRecentlyViewed(GoogleDriveVideo video) {
    if (kDebugMode) {
      print('📝 Adding Drive video to recently viewed: ${video.name}');
    }
    // This could be implemented to track recently viewed Drive videos
  }

  // Add placeholder method for marking Drive videos as learned
  void markDriveVideoAsLearned(GoogleDriveVideo? video) {
    if (video != null && kDebugMode) {
      print('✅ Marking Drive video as learned: ${video.name}');
    }
    // This could be implemented to track learned Drive videos
  }

  // Extract word from video name (helper method)
  String extractWordFromVideoName(String videoName) {
    // Remove file extension and clean up the name
    String cleanName = videoName.replaceAll(
      RegExp(r'\.(mp4|avi|mov|wmv)$'),
      '',
    );
    // Replace underscores/dashes with spaces and capitalize
    cleanName = cleanName.replaceAll(RegExp(r'[_\-]'), ' ');
    return cleanName
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  // Video player methods
  Future<void> initializeVideo(String videoUrl) async {
    // Dispose previous controller if exists
    if (videoController != null) {
      await videoController!.dispose();
    }

    try {
      if (kDebugMode) {
        print('🎬 Attempting to initialize video: $videoUrl');
      }

      // Check if it's a local asset or network URL
      if (videoUrl.startsWith('assets/')) {
        videoController = VideoPlayerController.asset(videoUrl);
      } else {
        videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }

      await videoController!.initialize();
      isVideoInitialized = true;
      isVideoPlaying = false;

      // Listen to video completion
      videoController!.addListener(() {
        if (videoController!.value.position >=
            videoController!.value.duration) {
          isVideoPlaying = false;
        }
      });

      if (kDebugMode) {
        print('✅ Video initialized successfully: $videoUrl');
        print('📱 Video duration: ${videoController!.value.duration}');
        print('📐 Video aspect ratio: ${videoController!.value.aspectRatio}');
      }
    } catch (e) {
      isVideoInitialized = false;
      isVideoPlaying = false;
      if (kDebugMode) {
        print('❌ Failed to initialize video: $e');
        print(
          '💡 This is normal if video assets are not yet added to the project',
        );
        print('💡 Video files should be placed in: assets/videos/');
      }

      // Clean up the controller since initialization failed
      if (videoController != null) {
        try {
          await videoController!.dispose();
        } catch (disposeError) {
          if (kDebugMode) {
            print('⚠️ Error disposing failed video controller: $disposeError');
          }
        }
        videoController = null;
      }
    }
  }

  // Check if video file exists (helper method)
  bool hasVideoAsset(String videoName) {
    // This is a simplified check - in reality you'd want to verify file existence
    // For now, we'll assume no local videos exist since the folder is empty
    return false;
  }

  // Get demo video URL for testing
  String getDemoVideoUrl() {
    // You can replace this with a public demo video URL for testing
    return 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4';
  }

  // Initialize video with fallback options - prioritize Google Drive videos
  Future<void> initializeVideoWithFallback(String videoName) async {
    if (kDebugMode) {
      print('🔍 Looking for video: $videoName');
    }

    // Step 1: Try to find the video in Google Drive first (since user is authenticated)
    if (GoogleDriveService.isConfigured()) {
      try {
        if (kDebugMode) {
          print('� Searching Google Drive for: $videoName');
        }

        // Search for the specific video in Google Drive
        final driveResults = await GoogleDriveService.searchVideos(videoName);

        if (driveResults.isNotEmpty) {
          // Find the best match (exact word match preferred)
          GoogleDriveVideo? bestMatch;

          // Look for exact match first
          for (final video in driveResults) {
            final videoWord = extractWordFromVideoName(
              video.name,
            ).toLowerCase();
            if (videoWord == videoName.toLowerCase()) {
              bestMatch = video;
              break;
            }
          }

          // If no exact match, use the first result
          bestMatch ??= driveResults.first;

          if (kDebugMode) {
            print('✅ Found Google Drive video: ${bestMatch.name}');
            print('🎬 Drive video URL: ${bestMatch.webViewLink}');
          }

          // Get the direct video URL for streaming
          final streamUrl = await GoogleDriveService.getVideoStreamUrl(
            bestMatch.id,
          );
          if (streamUrl != null) {
            await initializeVideo(streamUrl);
            if (isVideoInitialized) {
              if (kDebugMode) {
                print('✅ Successfully initialized Google Drive video');
              }
              return;
            }
          }
        }

        if (kDebugMode) {
          print('⚠️ No matching video found in Google Drive for: $videoName');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error searching Google Drive: $e');
        }
      }
    }

    // Step 2: Try local asset as fallback
    String localAssetPath = 'assets/videos/${videoName.toLowerCase()}.mp4';

    if (kDebugMode) {
      print('🔍 Checking for local video asset: $localAssetPath');
    }

    await initializeVideo(localAssetPath);

    // Step 3: If both failed, show appropriate message
    if (!isVideoInitialized) {
      if (kDebugMode) {
        print('💡 No video found for: $videoName');
        print('📝 Checked: Google Drive and local assets');
        print(
          '📝 To add videos: Upload to Google Drive or place in assets/videos/',
        );
      }
    }
  }

  void playVideo() {
    if (videoController != null && isVideoInitialized) {
      videoController!.play();
      isVideoPlaying = true;
    }
  }

  void pauseVideo() {
    if (videoController != null && isVideoInitialized) {
      videoController!.pause();
      isVideoPlaying = false;
    }
  }

  void toggleVideoPlayback() {
    if (isVideoPlaying) {
      pauseVideo();
    } else {
      playVideo();
    }
  }

  void resetVideo() {
    if (videoController != null && isVideoInitialized) {
      videoController!.seekTo(Duration.zero);
      isVideoPlaying = false;
    }
  }

  void disposeVideo() {
    if (videoController != null) {
      videoController!.dispose();
      videoController = null;
      isVideoInitialized = false;
      isVideoPlaying = false;
    }
  }

  // Get video duration formatted
  String getVideoDuration() {
    if (videoController != null && isVideoInitialized) {
      final duration = videoController!.value.duration;
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '0:30'; // Default fallback
  }

  // Get current video position formatted
  String getVideoPosition() {
    if (videoController != null && isVideoInitialized) {
      final position = videoController!.value.position;
      final minutes = position.inMinutes;
      final seconds = position.inSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '0:00';
  }

  // Check if video is loading
  bool isVideoLoading() {
    return videoController != null && !isVideoInitialized;
  }
}
