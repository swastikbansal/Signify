import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_drive_config.dart';

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
      createdTime: DateTime.parse(
        json['createdTime'] ?? DateTime.now().toIso8601String(),
      ),
      size: json['size'] ?? '0',
      mimeType: json['mimeType'] ?? '',
    );
  }
}

// Optimized stream source descriptor for Drive videos (URL + required headers)
class GoogleDriveStreamSource {
  final Uri uri;
  final Map<String, String> headers;
  const GoogleDriveStreamSource({required this.uri, required this.headers});
}

class GoogleDriveService {
  static const String _baseUrl = 'https://www.googleapis.com/drive/v3';

  static String? _accessToken;
  static DateTime? _tokenExpiry;

  // Scopes used for Drive user OAuth
  static const List<String> _driveScopes = <String>[
    'https://www.googleapis.com/auth/drive.readonly',
  ];

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
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: data['expires_in'] - 60),
        );
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

  // Initialize Google Sign-In and try lightweight auth (no UI)
  static Future<void> _initGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
      // Fire and forget; returns nullable future per API
      unawaited(GoogleSignIn.instance.attemptLightweightAuthentication());
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ GoogleSignIn initialize/attemptLightweightAuthentication error: $e',
        );
      }
    }
  }

  // Get user's Google OAuth access token via Google Sign-In (v7.x API)
  static Future<String?> _getUserGoogleToken() async {
    try {
      await _initGoogleSignIn();

      // Request headers silently (no prompt)
      final headers = await GoogleSignIn.instance.authorizationClient
          .authorizationHeaders(_driveScopes, promptIfNecessary: false);

      if (headers != null) {
        final authHeader = headers['Authorization'] ?? headers['authorization'];
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          final token = authHeader.substring('Bearer '.length);
          if (kDebugMode) {
            print('🔐 Retrieved user access token (length=${token.length})');
          }
          return token;
        }
      }
      if (kDebugMode) {
        print(
          'ℹ️ No user authorization headers returned; likely not signed in or scopes not granted.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user Google token (silent): $e');
      }
    }
    return null;
  }

  // Enhanced get access token - try user token first, then service account
  static Future<String> _getAccessTokenWithUserAuth() async {
    final userToken = await _getUserGoogleToken();
    if (userToken != null && userToken.isNotEmpty) {
      if (kDebugMode) {
        print('✅ Using user\'s Google OAuth token');
      }
      return userToken;
    }

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
        'exp':
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });

      // Sign the JWT with the private key
      final privateKey = serviceAccount['private_key'].toString().replaceAll(
        '\\n',
        '\n',
      );

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
        final privateKey = serviceAccount['private_key'].toString().replaceAll(
          '\\n',
          '\n',
        );
        print('🔑 Key starts with: ${privateKey.substring(0, 50)}...');
        print(
          '🔑 Key ends with: ...${privateKey.substring(privateKey.length - 50)}',
        );
      }
      throw Exception('Failed to create JWT: $e');
    }
  }

  // Search for videos in Google Drive
  static Future<List<GoogleDriveVideo>> searchVideos(String query) async {
    try {
      if (kDebugMode) {
        print('🔎 Searching Google Drive for: "$query"');
        print(
          '📂 Configured target folder: ${GoogleDriveConfig.targetFolderId}',
        );
        validateConfiguration();
      }

      // Prefer user OAuth token; fallback to service account
      final accessToken = await _getAccessTokenWithUserAuth();

      if (kDebugMode) {
        print('🔑 Got access token successfully');
      }

      // If we have a target folder, search in it and its subfolders
      if (GoogleDriveConfig.targetFolderId.isNotEmpty) {
        if (kDebugMode) {
          print(
            '🎯 Target folder configured: ${GoogleDriveConfig.targetFolderId}',
          );
        }

        // First, verify the folder exists and is accessible
        if (await _verifyFolderAccess(
          GoogleDriveConfig.targetFolderId,
          accessToken,
        )) {
          if (kDebugMode) {
            print('✅ Target folder verified, searching within it...');
          }
          // Search directly in the folder first (since user mentioned no subfolders)
          return await _searchInFolderDirectly(
            query,
            GoogleDriveConfig.targetFolderId,
            accessToken,
          );
        } else {
          if (kDebugMode) {
            print(
              '⚠️ Target folder not accessible, falling back to global search',
            );
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
  static Future<bool> _verifyFolderAccess(
    String folderId,
    String accessToken,
  ) async {
    try {
      if (kDebugMode) {
        print('🔍 Verifying access to folder: $folderId');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/files/$folderId').replace(
          queryParameters: {
            'fields': 'id,name,mimeType,parents,capabilities',
            'supportsAllDrives': 'true',
          },
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isFolder =
            data['mimeType'] == 'application/vnd.google-apps.folder';
        if (kDebugMode) {
          print('✅ Folder verified: "${data['name']}" (${data['id']})');
          print('   🗂️ Is folder: $isFolder');
          print(
            '   👀 Can list children: ${data['capabilities']?['canListChildren'] ?? 'unknown'}',
          );
          print(
            '   📂 Parent folders: ${data['parents']?.join(', ') ?? 'none'}',
          );
        }
        return isFolder;
      } else {
        if (kDebugMode) {
          print(
            '❌ Folder verification failed: ${response.statusCode} - ${response.body}',
          );
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
  static Future<List<GoogleDriveVideo>> _searchGlobally(
    String query,
    String accessToken,
  ) async {
    // Create search query for video files
    String searchQuery =
        "name contains '$query' and mimeType contains 'video/' and trashed=false";

    if (kDebugMode) {
      print('🌍 Searching globally with query: $searchQuery');
    }

    return await _performSearch(searchQuery, accessToken, query);
  }

  // Search recursively in a folder and its subfolders
  // ignore: unused_element
  static Future<List<GoogleDriveVideo>> _searchInFolderRecursively(
    String query,
    String folderId,
    String accessToken,
  ) async {
    List<GoogleDriveVideo> allVideos = [];

    if (kDebugMode) {
      print('📁 Searching recursively in folder: $folderId');
    }

    // First, search for videos directly in this folder
    String directQuery =
        "name contains '$query' and mimeType contains 'video/' and trashed=false and '$folderId' in parents";
    List<GoogleDriveVideo> directVideos = await _performSearch(
      directQuery,
      accessToken,
      query,
    );
    allVideos.addAll(directVideos);

    if (kDebugMode) {
      print(
        '📹 Found ${directVideos.length} videos directly in folder $folderId',
      );
    }

    // Only proceed with subfolder search if we can access the parent folder
    try {
      String folderQuery =
          "mimeType='application/vnd.google-apps.folder' and trashed=false and '$folderId' in parents";
      if (kDebugMode) {
        print('🔍 Subfolder search query: $folderQuery');
      }
      final response = await http.get(
        Uri.parse('$_baseUrl/files').replace(
          queryParameters: {
            'q': folderQuery,
            'fields': 'files(id,name)',
            'pageSize': '100',
            'supportsAllDrives': 'true',
            'includeItemsFromAllDrives': 'true',
          },
        ),
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
          List<GoogleDriveVideo> subfolderVideos =
              await _searchInFolderRecursively(
                query,
                folder['id'],
                accessToken,
              );
          allVideos.addAll(subfolderVideos);
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print(
            '❌ Folder $folderId not found (404). Folder may have been deleted or access denied.',
          );
        }
        // Don't throw an error, just return what we found so far
      } else {
        if (kDebugMode) {
          print(
            '❌ Failed to list subfolders in $folderId: ${response.statusCode} - ${response.body}',
          );
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
  static Future<List<GoogleDriveVideo>> _searchInFolderDirectly(
    String query,
    String folderId,
    String accessToken,
  ) async {
    if (kDebugMode) {
      print(
        '📁 Searching directly in folder: $folderId (no subfolder recursion)',
      );
    }

    // Search for videos directly in this folder
    String directQuery =
        "name contains '$query' and mimeType contains 'video/' and trashed=false and '$folderId' in parents";
    List<GoogleDriveVideo> videos = await _performSearch(
      directQuery,
      accessToken,
      query,
    );

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
  static Future<void> _listFolderContents(
    String folderId,
    String accessToken,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/files').replace(
          queryParameters: {
            'q': "'$folderId' in parents and trashed=false",
            'fields': 'files(id,name,mimeType,size)',
            'pageSize': '20',
            'supportsAllDrives': 'true',
            'includeItemsFromAllDrives': 'true',
          },
        ),
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
            final icon = isVideo
                ? '📹'
                : (file['mimeType'] == 'application/vnd.google-apps.folder'
                      ? '📂'
                      : '📄');
            print(
              '  $icon ${file['name']} (${file['mimeType']}) - Size: ${file['size'] ?? 'N/A'}',
            );
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
  static Future<List<GoogleDriveVideo>> _performSearch(
    String searchQuery,
    String accessToken,
    String originalQuery,
  ) async {
    try {
      if (kDebugMode) {
        print('📝 Executing search query: $searchQuery');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/files').replace(
          queryParameters: {
            'q': searchQuery,
            'fields':
                'files(id,name,webViewLink,thumbnailLink,createdTime,size,mimeType)',
            'orderBy': 'name',
            'pageSize': GoogleDriveConfig.maxResults.toString(),
            'supportsAllDrives': 'true',
            'includeItemsFromAllDrives': 'true',
          },
        ),
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
          print(
            '❌ Search target not found (404). This might be a folder access issue.',
          );
        }
        return [];
      } else {
        if (kDebugMode) {
          print(
            '❌ Error executing search: ${response.statusCode} - ${response.body}',
          );
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

  // Build a direct media URI that supports HTTP range requests (best for streaming)
  static Uri _buildMediaUri(String fileId) {
    return Uri.parse('$_baseUrl/files/$fileId').replace(
      queryParameters: {
        'alt': 'media',
        'supportsAllDrives': 'true',
        // Helps bypass some warning flows for large files
        'acknowledgeAbuse': 'true',
      },
    );
  }

  // Internal: auth header map for media requests
  static Map<String, String> _authHeaders(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  // Optionally warm up the media endpoint to reduce first-frame latency
  static Future<void> _warmupMediaUri(
    String fileId,
    String accessToken, {
    int prefetchBytes = 512 * 1024,
  }) async {
    try {
      final mediaUri = _buildMediaUri(fileId);

      // 1) HEAD to establish connection and get headers (like Accept-Ranges, Content-Length)
      final headResp = await http.head(
        mediaUri,
        headers: _authHeaders(accessToken),
      );
      if (kDebugMode) {
        final ar = headResp.headers['accept-ranges'];
        final cl = headResp.headers['content-length'];
        print(
          '🚀 Warmup HEAD: status=${headResp.statusCode}, accept-ranges=$ar, content-length=$cl',
        );
      }

      // 2) Small ranged GET to prime caches and reduce initial buffering
      final end = (prefetchBytes - 1).clamp(0, prefetchBytes - 1);
      final headers = {..._authHeaders(accessToken), 'Range': 'bytes=0-$end'};
      final rangeResp = await http.get(mediaUri, headers: headers);
      if (kDebugMode) {
        print(
          '📦 Warmup range GET: status=${rangeResp.statusCode}, received=${rangeResp.bodyBytes.length} bytes',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Warmup failed (non-fatal): $e');
      }
    }
  }

  // Preferred API: returns a direct media URL + headers for fast streaming
  // Pass these to VideoPlayerController.networkUrl(uri, httpHeaders: headers)
  static Future<GoogleDriveStreamSource?> getOptimizedVideoStreamSource(
    String fileId, {
    bool warmup = true,
  }) async {
    try {
      // Prefer user token when available
      final accessToken = await _getAccessTokenWithUserAuth();
      final mediaUri = _buildMediaUri(fileId);

      if (warmup) {
        // Fire and forget; don't block UI too long
        unawaited(_warmupMediaUri(fileId, accessToken));
      }

      return GoogleDriveStreamSource(
        uri: mediaUri,
        headers: _authHeaders(accessToken),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ getOptimizedVideoStreamSource error: $e');
      }
      return null;
    }
  }

  // Get direct download/stream link (legacy). Prefer getOptimizedVideoStreamSource for lower latency.
  static Future<String?> getVideoStreamUrl(String fileId) async {
    try {
      // Build alt=media URL and embed token as query param for compatibility with players that can't set headers
      final token = await _getAccessTokenWithUserAuth();
      final mediaUri = _buildMediaUri(fileId).replace(
        queryParameters: {
          ..._buildMediaUri(fileId).queryParameters,
          'access_token': token,
        },
      );
      if (kDebugMode) {
        print('🔗 Media URL (alt=media) with token param: $mediaUri');
      }
      return mediaUri.toString();
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
      final accessToken = await _getAccessTokenWithUserAuth();

      final response = await http.get(
        Uri.parse('$_baseUrl/files/$fileId').replace(
          queryParameters: {
            'fields':
                'id,name,description,size,createdTime,modifiedTime,owners,parents,webViewLink,thumbnailLink',
          },
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
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
        print(
          '🔑 Private Key exists: ${serviceAccount['private_key'] != null}',
        );
        print('🏷️ Type: ${serviceAccount['type']}');
      }

      // Check if all required fields are present and not empty
      final isConfigured =
          serviceAccount['project_id'] != null &&
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

        print(
          '📄 project_id: "$projectId" (${projectId?.runtimeType}) - null: ${projectId == null}, empty: ${projectId?.toString().isEmpty}',
        );
        print(
          '📧 client_email: "$clientEmail" (${clientEmail?.runtimeType}) - null: ${clientEmail == null}, empty: ${clientEmail?.toString().isEmpty}',
        );
        print(
          '🔑 private_key: exists=${privateKey != null}, length=${privateKey?.toString().length ?? 0}',
        );
        print(
          '🏷️ type: "$type" (${type?.runtimeType}) - equals service_account: ${type == 'service_account'}',
        );

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
