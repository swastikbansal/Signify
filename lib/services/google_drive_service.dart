import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'google_drive_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleDriveVideo {
  final String id;
  final String name;
  final String webViewLink;
  final String thumbnailLink;
  final DateTime createdTime;
  final String size;
  final String mimeType;

  GoogleDriveVideo({
    required this.id,
    required this.name,
    required this.webViewLink,
    required this.thumbnailLink,
    required this.createdTime,
    required this.size,
    required this.mimeType,
  });

  factory GoogleDriveVideo.fromJson(Map<String, dynamic> json) {
    return GoogleDriveVideo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      webViewLink: json['webViewLink'] ?? '',
      thumbnailLink: json['thumbnailLink'] ?? '',
      createdTime: DateTime.parse(json['createdTime'] ?? DateTime.now().toIso8601String()),
      size: json['size'] ?? '0',
      mimeType: json['mimeType'] ?? '',
    );
  }
}

class GoogleDriveService {
  static const String _baseUrl = 'https://www.googleapis.com/drive/v3';
  
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  // Get access token using service account
  static Future<String> _getAccessToken() async {
    if (_accessToken != null && 
        _tokenExpiry != null && 
        DateTime.now().isBefore(_tokenExpiry!)) {
      if (kDebugMode) {
        print('🔄 Using cached access token');
      }
      return _accessToken!;
    }

    try {
      if (kDebugMode) {
        print('🔐 Getting new access token...');
      }
      
      final serviceAccount = jsonDecode(GoogleDriveConfig.serviceAccountKey);
      
      // Create JWT for service account authentication
      final jwt = _createJWT(serviceAccount);
      
      if (kDebugMode) {
        print('📝 JWT created successfully');
      }
      
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': jwt,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in'] - 60));
        if (kDebugMode) {
          print('✅ Access token obtained successfully');
        }
        return _accessToken!;
      } else {
        if (kDebugMode) {
          print('❌ Failed to get access token: ${response.statusCode}');
          print('📄 Response: ${response.body}');
        }
        throw Exception('Failed to get access token: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error getting access token: $e');
      }
      throw Exception('Authentication failed: $e');
    }
  }

  // Get user's Google OAuth token from Firebase Auth
  static Future<String?> _getUserGoogleToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the user's ID token which might contain Google OAuth info
        final idToken = await user.getIdToken();
        
        // For Google Sign-In users, we need to get the Google OAuth token
        // This requires additional setup with Google Sign-In package
        if (kDebugMode) {
          print('🔐 User is authenticated with Firebase');
          print('👤 User email: ${user.email}');
        }
        
        // If the user signed in with Google, we can access their Google token
        // For now, return the Firebase ID token - you may need to modify this
        // based on your Google Sign-In implementation
        return idToken;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user Google token: $e');
      }
    }
    return null;
  }

  // Enhanced get access token - try user token first, then service account
  static Future<String> _getAccessTokenWithUserAuth() async {
    // First try to use the user's Google OAuth token
    final userToken = await _getUserGoogleToken();
    if (userToken != null) {
      if (kDebugMode) {
        print('✅ Using user\'s authenticated token');
      }
      return userToken;
    }
    
    // Fallback to service account
    if (kDebugMode) {
      print('⚠️ User token not available, using service account');
    }
    return await _getAccessToken();
  }

  // Create JWT for service account
  static String _createJWT(Map<String, dynamic> serviceAccount) {
    try {
      // Create the JWT payload
      final jwt = JWT({
        'iss': serviceAccount['client_email'],
        'scope': 'https://www.googleapis.com/auth/drive.readonly',
        'aud': 'https://oauth2.googleapis.com/token',
        'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });

      // Sign the JWT with the private key
      final privateKey = serviceAccount['private_key'].toString().replaceAll('\\n', '\n');
      
      if (kDebugMode) {
        print('🔐 Creating RSA private key for JWT signing...');
        print('🔑 Private key length: ${privateKey.length}');
      }
      
      // Create RSA private key using the constructor that takes PEM string
      final rsaPrivateKey = RSAPrivateKey(privateKey);
      
      if (kDebugMode) {
        print('🔐 RSA private key created successfully, signing JWT...');
      }
      
      return jwt.sign(rsaPrivateKey, algorithm: JWTAlgorithm.RS256);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating JWT: $e');
        print('🔍 Private key format check...');
        final privateKey = serviceAccount['private_key'].toString().replaceAll('\\n', '\n');
        print('🔑 Key starts with: ${privateKey.substring(0, 50)}...');
        print('🔑 Key ends with: ...${privateKey.substring(privateKey.length - 50)}');
      }
      throw Exception('Failed to create JWT: $e');
    }
  }

  // Search for videos in Google Drive
  static Future<List<GoogleDriveVideo>> searchVideos(String query) async {
    try {
      if (kDebugMode) {
        print('🔎 Searching Google Drive for: "$query"');
        print('📂 Configured target folder: ${GoogleDriveConfig.targetFolderId}');
        validateConfiguration();
      }
      
      final accessToken = await _getAccessToken();  // Use service account directly for now
      
      if (kDebugMode) {
        print('🔑 Got access token successfully');
      }
      
      // If we have a target folder, search in it and its subfolders
      if (GoogleDriveConfig.targetFolderId != null && GoogleDriveConfig.targetFolderId!.isNotEmpty) {
        if (kDebugMode) {
          print('🎯 Target folder configured: ${GoogleDriveConfig.targetFolderId}');
        }
        
        // First, verify the folder exists and is accessible
        if (await _verifyFolderAccess(GoogleDriveConfig.targetFolderId!, accessToken)) {
          if (kDebugMode) {
            print('✅ Target folder verified, searching within it...');
          }
          // Search directly in the folder first (since user mentioned no subfolders)
          return await _searchInFolderDirectly(query, GoogleDriveConfig.targetFolderId!, accessToken);
        } else {
          if (kDebugMode) {
            print('⚠️ Target folder not accessible, falling back to global search');
            print('🌍 Attempting global search as fallback...');
          }
          return await _searchGlobally(query, accessToken);
        }
      }
      
      // Otherwise search globally
      return await _searchGlobally(query, accessToken);
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error in searchVideos: $e');
      }
      return [];
    }
  }

  // Verify that a folder exists and is accessible
  static Future<bool> _verifyFolderAccess(String folderId, String accessToken) async {
    try {
      if (kDebugMode) {
        print('🔍 Verifying access to folder: $folderId');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/files/$folderId').replace(queryParameters: {
          'fields': 'id,name,mimeType,parents,capabilities',
          'supportsAllDrives': 'true',
        }),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isFolder = data['mimeType'] == 'application/vnd.google-apps.folder';
        if (kDebugMode) {
          print('✅ Folder verified: "${data['name']}" (${data['id']})');
          print('   🗂️ Is folder: $isFolder');
          print('   👀 Can list children: ${data['capabilities']?['canListChildren'] ?? 'unknown'}');
          print('   📂 Parent folders: ${data['parents']?.join(', ') ?? 'none'}');
        }
        return isFolder;
      } else {
        if (kDebugMode) {
          print('❌ Folder verification failed: ${response.statusCode} - ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error verifying folder access: $e');
      }
      return false;
    }
  }

  // Search globally across all accessible files
  static Future<List<GoogleDriveVideo>> _searchGlobally(String query, String accessToken) async {
    // Create search query for video files
    String searchQuery = "name contains '$query' and mimeType contains 'video/' and trashed=false";
    
    if (kDebugMode) {
      print('🌍 Searching globally with query: $searchQuery');
    }
    
    return await _performSearch(searchQuery, accessToken, query);
  }

  // Search recursively in a folder and its subfolders
  static Future<List<GoogleDriveVideo>> _searchInFolderRecursively(String query, String folderId, String accessToken) async {
    List<GoogleDriveVideo> allVideos = [];
    
    if (kDebugMode) {
      print('📁 Searching recursively in folder: $folderId');
    }
    
    // First, search for videos directly in this folder
    String directQuery = "name contains '$query' and mimeType contains 'video/' and trashed=false and '$folderId' in parents";
    List<GoogleDriveVideo> directVideos = await _performSearch(directQuery, accessToken, query);
    allVideos.addAll(directVideos);
    
    if (kDebugMode) {
      print('📹 Found ${directVideos.length} videos directly in folder $folderId');
    }
    
    // Only proceed with subfolder search if we can access the parent folder
    try {
      String folderQuery = "mimeType='application/vnd.google-apps.folder' and trashed=false and '$folderId' in parents";
      if (kDebugMode) {
        print('🔍 Subfolder search query: $folderQuery');
      }
      final response = await http.get(
        Uri.parse('$_baseUrl/files').replace(queryParameters: {
          'q': folderQuery,
          'fields': 'files(id,name)',
          'pageSize': '100',
          'supportsAllDrives': 'true',
          'includeItemsFromAllDrives': 'true',
        }),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      
      if (kDebugMode) {
        print('🔍 Subfolder list response status: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final folders = data['files'] as List<dynamic>;
        if (kDebugMode) {
          print('📁 Found ${folders.length} subfolders in $folderId');
          for (var folder in folders) {
            print('  📂 ${folder['name']} (${folder['id']})');
          }
        }
        // Recursively search in each subfolder
        for (var folder in folders) {
          List<GoogleDriveVideo> subfolderVideos = await _searchInFolderRecursively(query, folder['id'], accessToken);
          allVideos.addAll(subfolderVideos);
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print('❌ Folder $folderId not found (404). Folder may have been deleted or access denied.');
        }
        // Don't throw an error, just return what we found so far
      } else {
        if (kDebugMode) {
          print('❌ Failed to list subfolders in $folderId: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error searching subfolders: $e');
      }
    }
    
    return allVideos;
  }

  // Search directly in a folder (no recursion) - optimized for folders without subfolders
  static Future<List<GoogleDriveVideo>> _searchInFolderDirectly(String query, String folderId, String accessToken) async {
    if (kDebugMode) {
      print('📁 Searching directly in folder: $folderId (no subfolder recursion)');
    }
    
    // Search for videos directly in this folder
    String directQuery = "name contains '$query' and mimeType contains 'video/' and trashed=false and '$folderId' in parents";
    List<GoogleDriveVideo> videos = await _performSearch(directQuery, accessToken, query);
    
    if (kDebugMode) {
      print('📹 Found ${videos.length} videos directly in folder $folderId');
      if (videos.isEmpty) {
        print('🔍 Let me also check what files exist in this folder...');
        await _listFolderContents(folderId, accessToken);
      }
    }
    
    return videos;
  }

  // Helper method to list all contents of a folder for debugging
  static Future<void> _listFolderContents(String folderId, String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/files').replace(queryParameters: {
          'q': "'$folderId' in parents and trashed=false",
          'fields': 'files(id,name,mimeType,size)',
          'pageSize': '20',
          'supportsAllDrives': 'true',
          'includeItemsFromAllDrives': 'true',
        }),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List<dynamic>;
        
        if (kDebugMode) {
          print('📋 Total files in folder: ${files.length}');
          for (var file in files) {
            final isVideo = file['mimeType'].toString().contains('video/');
            final icon = isVideo ? '📹' : (file['mimeType'] == 'application/vnd.google-apps.folder' ? '📂' : '📄');
            print('  $icon ${file['name']} (${file['mimeType']}) - Size: ${file['size'] ?? 'N/A'}');
          }
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to list folder contents: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error listing folder contents: $e');
      }
    }
  }

  // Perform the actual search with a given query
  static Future<List<GoogleDriveVideo>> _performSearch(String searchQuery, String accessToken, String originalQuery) async {
    try {
      if (kDebugMode) {
        print('📝 Executing search query: $searchQuery');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/files').replace(queryParameters: {
          'q': searchQuery,
          'fields': 'files(id,name,webViewLink,thumbnailLink,createdTime,size,mimeType)',
          'orderBy': 'name',
          'pageSize': GoogleDriveConfig.maxResults.toString(),
          'supportsAllDrives': 'true',
          'includeItemsFromAllDrives': 'true',
        }),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List<dynamic>;
        
        if (kDebugMode) {
          print('✅ Found ${files.length} videos from this query');
          for (var file in files) {
            print('  📹 ${file['name']} (${file['id']})');
          }
        }
        
        return files.map((file) => GoogleDriveVideo.fromJson(file)).toList();
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print('❌ Search target not found (404). This might be a folder access issue.');
        }
        return [];
      } else {
        if (kDebugMode) {
          print('❌ Error executing search: ${response.statusCode} - ${response.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error in _performSearch: $e');
      }
      return [];
    }
  }

  // Get direct download link for video streaming
  static Future<String?> getVideoStreamUrl(String fileId) async {
    try {
      final accessToken = await _getAccessToken();  // Use service account directly for now
      
      final response = await http.get(
        Uri.parse('$_baseUrl/files/$fileId').replace(queryParameters: {
          'fields': 'webContentLink,webViewLink',
        }),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['webContentLink'] ?? data['webViewLink'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting video stream URL: $e');
      }
      return null;
    }
  }

  // Get video metadata
  static Future<Map<String, dynamic>?> getVideoMetadata(String fileId) async {
    try {
      final accessToken = await _getAccessToken();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/files/$fileId').replace(queryParameters: {
          'fields': 'id,name,description,size,createdTime,modifiedTime,owners,parents,webViewLink,thumbnailLink',
        }),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting video metadata: $e');
      }
      return null;
    }
  }

  // Check if service is properly configured
  static bool isConfigured() {
    try {
      final serviceAccount = jsonDecode(GoogleDriveConfig.serviceAccountKey);
      
      if (kDebugMode) {
        print('🔍 Checking Google Drive configuration...');
        print('📄 Project ID: ${serviceAccount['project_id']}');
        print('📧 Client Email: ${serviceAccount['client_email']}');
        print('🔑 Private Key exists: ${serviceAccount['private_key'] != null}');
        print('🏷️ Type: ${serviceAccount['type']}');
      }
      
      // Check if all required fields are present and not empty
      final isConfigured = serviceAccount['project_id'] != null &&
             serviceAccount['project_id'].toString().isNotEmpty &&
             serviceAccount['client_email'] != null &&
             serviceAccount['client_email'].toString().isNotEmpty &&
             serviceAccount['private_key'] != null &&
             serviceAccount['private_key'].toString().isNotEmpty &&
             serviceAccount['type'] == 'service_account';
             
      if (kDebugMode) {
        print('✅ Google Drive configured: $isConfigured');
      }
      
      return isConfigured;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking configuration: $e');
      }
      return false;
    }
  }

  // Test configuration method - temporary debug function
  static void testConfiguration() {
    if (kDebugMode) {
      print('🧪 Testing Google Drive configuration...');
      try {
        final serviceAccount = jsonDecode(GoogleDriveConfig.serviceAccountKey);
        print('🔍 JSON parsing: SUCCESS');
        print('📋 Keys found: ${serviceAccount.keys.join(', ')}');
        
        // Test each field individually
        final projectId = serviceAccount['project_id'];
        final clientEmail = serviceAccount['client_email'];
        final privateKey = serviceAccount['private_key'];
        final type = serviceAccount['type'];
        
        print('📄 project_id: "$projectId" (${projectId?.runtimeType}) - null: ${projectId == null}, empty: ${projectId?.toString().isEmpty}');
        print('📧 client_email: "$clientEmail" (${clientEmail?.runtimeType}) - null: ${clientEmail == null}, empty: ${clientEmail?.toString().isEmpty}');
        print('🔑 private_key: exists=${privateKey != null}, length=${privateKey?.toString().length ?? 0}');
        print('🏷️ type: "$type" (${type?.runtimeType}) - equals service_account: ${type == 'service_account'}');
        
        final configResult = GoogleDriveService.isConfigured();
        print('✅ Final result: $configResult');
      } catch (e) {
        print('❌ JSON parsing error: $e');
      }
    }
  }

  // Debug method to validate current configuration
  static void validateConfiguration() {
    if (kDebugMode) {
      print('🔍 === Configuration Validation ===');
      print('📂 Target Folder ID: "${GoogleDriveConfig.targetFolderId}"');
      print('📧 Service Account Email: "${_extractEmailFromServiceAccount()}"');
      print('🔑 Access Token Cached: ${_accessToken != null}');
      print('⏰ Token Expiry: ${_tokenExpiry?.toIso8601String() ?? "Not set"}');
      print('================================');
    }
  }

  // Helper method to extract email from service account
  static String _extractEmailFromServiceAccount() {
    try {
      final serviceAccount = jsonDecode(GoogleDriveConfig.serviceAccountKey);
      return serviceAccount['client_email'] ?? 'Unknown';
    } catch (e) {
      return 'Error parsing config';
    }
  }

  // Force refresh access token (useful for debugging)
  static void clearTokenCache() {
    if (kDebugMode) {
      print('🗑️ Clearing token cache...');
    }
    _accessToken = null;
    _tokenExpiry = null;
  }
}
