import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '/auth/firebase_auth/auth_util.dart';

class UploadedFilesService {
  static const String _baseUploadedFilesKey = 'uploaded_files_data';
  static UploadedFilesService? _instance;
  static SharedPreferences? _prefs;

  UploadedFilesService._();

  static UploadedFilesService get instance {
    _instance ??= UploadedFilesService._();
    return _instance!;
  }

  /// Get user-specific storage key
  String _getUserSpecificKey() {
    final userId = currentUserUid;
    if (userId.isEmpty) {
      debugPrint('Warning: No user logged in, using default key');
      return _baseUploadedFilesKey;
    }
    return '${_baseUploadedFilesKey}_$userId';
  }

  /// Initialize the service (call this in app startup)
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get all uploaded files data for the current user
  Future<List<Map<String, dynamic>>> getUploadedFiles() async {
    await _ensureInitialized();

    try {
      final String storageKey = _getUserSpecificKey();
      final String? jsonData = _prefs!.getString(storageKey);
      if (jsonData == null || jsonData.isEmpty) {
        return [];
      }

      final List<dynamic> decodedList = jsonDecode(jsonData);
      return decodedList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading uploaded files: $e');
      return [];
    }
  }

  /// Save uploaded files data for the current user
  Future<void> saveUploadedFiles(List<Map<String, dynamic>> files) async {
    await _ensureInitialized();

    try {
      final String storageKey = _getUserSpecificKey();
      final String jsonData = jsonEncode(files);
      await _prefs!.setString(storageKey, jsonData);
      debugPrint('Uploaded files saved for user: ${files.length} items');
    } catch (e) {
      debugPrint('Error saving uploaded files: $e');
    }
  }

  /// Add a new uploaded file (insert at beginning for latest-first order)
  Future<void> addUploadedFile(Map<String, dynamic> file) async {
    final List<Map<String, dynamic>> currentFiles = await getUploadedFiles();
    currentFiles.insert(0, file);
    await saveUploadedFiles(currentFiles);
  }

  /// Remove a file at specific index
  Future<void> removeUploadedFile(int index) async {
    final List<Map<String, dynamic>> currentFiles = await getUploadedFiles();
    if (index >= 0 && index < currentFiles.length) {
      currentFiles.removeAt(index);
      await saveUploadedFiles(currentFiles);
    }
  }

  /// Update a file at specific index
  Future<void> updateUploadedFile(
    int index,
    Map<String, dynamic> updatedFile,
  ) async {
    final List<Map<String, dynamic>> currentFiles = await getUploadedFiles();
    if (index >= 0 && index < currentFiles.length) {
      currentFiles[index] = updatedFile;
      await saveUploadedFiles(currentFiles);
    }
  }

  /// Clear all uploaded files data for the current user (call this on user data reset)
  Future<void> clearUploadedFiles() async {
    await _ensureInitialized();

    try {
      final String storageKey = _getUserSpecificKey();
      await _prefs!.remove(storageKey);
      debugPrint('Uploaded files data cleared for current user');
    } catch (e) {
      debugPrint('Error clearing uploaded files: $e');
    }
  }

  /// Ensure SharedPreferences is initialized
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }
}
