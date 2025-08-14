import 'package:flutter/foundation.dart';

/// Simple global state manager using ChangeNotifier
class AppStateManager extends ChangeNotifier {
  static AppStateManager? _instance;
  static AppStateManager get instance => _instance ??= AppStateManager._();

  AppStateManager._();

  // App-level states
  bool _isOnline = true;
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, dynamic> _appSettings = {};

  // Getters
  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get appSettings => Map.unmodifiable(_appSettings);

  // State updates with notifications
  void setOnlineStatus(bool status) {
    if (_isOnline != status) {
      _isOnline = status;
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      notifyListeners();
    }
  }

  void clearError() => setError(null);

  void updateSetting(String key, dynamic value) {
    _appSettings[key] = value;
    notifyListeners();
  }

  T? getSetting<T>(String key) => _appSettings[key] as T?;

  void resetState() {
    _isOnline = true;
    _isLoading = false;
    _errorMessage = null;
    _appSettings.clear();
    notifyListeners();
  }
}
