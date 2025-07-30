import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'isl_dict_widget.dart' show IslDictWidget;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
  final String meaning;
  final String category;
  final String videoUrl;
  final String? imageUrl;
  final DateTime date;
  final bool isFavorite;

  WordOfTheDay({
    required this.id,
    required this.word,
    required this.meaning,
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

  @override
  void initState(BuildContext context) {
    debugLogWidgetClass(this);
    _initializeData();
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
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

  @override
  Map<String, FlutterFlowModel> get widgetBuilderComponents => 
      <String, FlutterFlowModel>{};

  @override
  Map<String, DebugDataField> get debugGeneratorVariables => 
      <String, DebugDataField>{};

  @override
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
        dateAdded: DateTime.now().subtract(Duration(days: 5)),
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
        dateAdded: DateTime.now().subtract(Duration(days: 4)),
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
        dateAdded: DateTime.now().subtract(Duration(days: 3)),
      ),
      // Greetings
      ISLSign(
        id: 'sign_hello',
        word: 'Hello',
        category: 'greetings',
        videoUrl: 'assets/videos/hello.mp4',
        imageUrl: 'assets/images/hello.png',
        description: 'Greeting: Hello in Indian Sign Language',
        tags: ['greeting', 'hello', 'basic', 'communication'],
        difficulty: 1,
        dateAdded: DateTime.now().subtract(Duration(days: 2)),
        viewCount: 25,
      ),
      ISLSign(
        id: 'sign_thank_you',
        word: 'Thank You',
        category: 'greetings',
        videoUrl: 'assets/videos/thank_you.mp4',
        imageUrl: 'assets/images/thank_you.png',
        description: 'Expression of gratitude in Indian Sign Language',
        tags: ['greeting', 'thanks', 'gratitude', 'polite'],
        difficulty: 2,
        dateAdded: DateTime.now().subtract(Duration(days: 1)),
        viewCount: 18,
      ),
      // Family
      ISLSign(
        id: 'sign_mother',
        word: 'Mother',
        category: 'family',
        videoUrl: 'assets/videos/mother.mp4',
        imageUrl: 'assets/images/mother.png',
        description: 'Family member: Mother in Indian Sign Language',
        tags: ['family', 'mother', 'parent', 'relationship'],
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
    recentlyViewedSigns = allSigns.where((sign) => sign.viewCount > 0).take(4).toList();
  }

  void _initializeWordOfTheDay() {
    // Initialize word of the day
    wordOfTheDay = WordOfTheDay(
      id: 'wotd_hello',
      word: 'Hello',
      meaning: 'A greeting used when meeting someone for the first time or when acknowledging their presence.',
      category: 'Greetings',
      videoUrl: 'assets/videos/hello.mp4',
      imageUrl: 'assets/images/hello.png',
      date: DateTime.now(),
      isFavorite: false,
    );
  }

  // Search functionality
  void searchSigns(String query) {
    if (query.isEmpty) {
      filteredSigns = selectedCategory == 'all' 
          ? List.from(allSigns) 
          : allSigns.where((sign) => sign.category == selectedCategory).toList();
    } else {
      filteredSigns = allSigns.where((sign) {
        final matchesQuery = sign.word.toLowerCase().contains(query.toLowerCase()) ||
                           sign.description.toLowerCase().contains(query.toLowerCase()) ||
                           sign.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        final matchesCategory = selectedCategory == 'all' || sign.category == selectedCategory;
        return matchesQuery && matchesCategory;
      }).toList();
    }
    // State will be updated automatically through setState in the widget
  }

  // Category filtering
  void filterByCategory(String categoryId) {
    selectedCategory = categoryId;
    searchSigns(textController?.text ?? '');
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
      final filteredIndex = filteredSigns.indexWhere((sign) => sign.id == signId);
      if (filteredIndex != -1) {
        filteredSigns[filteredIndex] = updatedSign;
      }
      
      // Update recently viewed if it contains this sign
      final recentIndex = recentlyViewedSigns.indexWhere((sign) => sign.id == signId);
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
        learnedToday: (dailyTask!.learnedToday + 1).clamp(0, dailyTask!.targetSigns),
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
      final filteredIndex = filteredSigns.indexWhere((sign) => sign.id == signId);
      if (filteredIndex != -1) {
        filteredSigns[filteredIndex] = updatedSign;
      }
      
      // Update recently viewed if it contains this sign
      final recentIndex = recentlyViewedSigns.indexWhere((sign) => sign.id == signId);
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
    return category.signCount > 0 ? category.learnedCount / category.signCount : 0.0;
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
        meaning: wordOfTheDay!.meaning,
        category: wordOfTheDay!.category,
        videoUrl: wordOfTheDay!.videoUrl,
        imageUrl: wordOfTheDay!.imageUrl,
        date: wordOfTheDay!.date,
        isFavorite: !wordOfTheDay!.isFavorite,
      );
    }
  }
}
