import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

// Simple generic cache holder with TTL
class _Cached<T> {
  final T value;
  final DateTime expiresAt;
  const _Cached(this.value, this.expiresAt);
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

class GoogleDriveService {
  static const String _baseUrl = 'https://www.googleapis.com/drive/v3';

  static String? _accessToken;
  static DateTime? _tokenExpiry;

  // ===== Performance: In-memory caches with TTL =====
  // Tune TTLs as needed
  static const Duration _searchTTL = Duration(minutes: 10);
  static const Duration _streamTTL = Duration(minutes: 30);
  static const Duration _metadataTTL = Duration(minutes: 60);
  static const int _warmupPrefetchCount = 6; // prefetch top-N results
  static const int _warmupConcurrency = 3; // limit concurrent warmups

  // Disk cache key prefixes
  static const String _diskPrefixStream = 'gdrive_stream_';
  static const String _diskPrefixMetadata = 'gdrive_meta_';

  // Caches
  static final Map<String, _Cached<List<GoogleDriveVideo>>> _searchCache = {};
  static final Map<String, _Cached<String?>> _streamUrlCache = {};
  static final Map<String, _Cached<Map<String, dynamic>?>> _metadataCache = {};

  // In-flight de-duplication maps
  static final Map<String, Future<List<GoogleDriveVideo>>> _inFlightSearches =
      {};
  static final Map<String, Future<String?>> _inFlightStream = {};
  static final Map<String, Future<Map<String, dynamic>?>> _inFlightMetadata =
      {};

  static String _normalizeQuery(String q) => q.trim().toLowerCase();
  static String _searchKey(String q) {
    final norm = _normalizeQuery(q);
    final folder = GoogleDriveConfig.targetFolderId.isEmpty
        ? 'global'
        : 'folder:${GoogleDriveConfig.targetFolderId}';
    return 'q:$norm|$folder|max:${GoogleDriveConfig.maxResults}';
  }

  static void _cleanupExpiredCaches() {
    // Remove expired entries to prevent unbounded growth
    _searchCache.removeWhere((_, v) => !v.isValid);
    _streamUrlCache.removeWhere((_, v) => !v.isValid);
    _metadataCache.removeWhere((_, v) => !v.isValid);
  }

  // ---- Disk cache helpers ----
  static Future<_Cached<String?>?> _diskGetStreamUrl(String fileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_diskPrefixStream$fileId');
      if (raw == null) return null;
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAtMillis = obj['expiresAt'] as int?;
      if (expiresAtMillis == null) return null;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMillis);
      if (DateTime.now().isAfter(expiresAt)) return null;
      final val = obj.containsKey('value') ? obj['value'] as String? : null;
      return _Cached<String?>(val, expiresAt);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _diskSetStreamUrl(
    String fileId,
    String? url,
    Duration ttl,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'value': url,
        'expiresAt': DateTime.now().add(ttl).millisecondsSinceEpoch,
      });
      await prefs.setString('$_diskPrefixStream$fileId', payload);
    } catch (_) {}
  }

  static Future<_Cached<Map<String, dynamic>?>?> _diskGetMetadata(
    String fileId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_diskPrefixMetadata$fileId');
      if (raw == null) return null;
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAtMillis = obj['expiresAt'] as int?;
      if (expiresAtMillis == null) return null;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMillis);
      if (DateTime.now().isAfter(expiresAt)) return null;
      final val = obj['value'];
      return _Cached<Map<String, dynamic>?>(
        val == null ? null : (val as Map<String, dynamic>),
        expiresAt,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _diskSetMetadata(
    String fileId,
    Map<String, dynamic>? data,
    Duration ttl,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'value': data,
        'expiresAt': DateTime.now().add(ttl).millisecondsSinceEpoch,
      });
      await prefs.setString('$_diskPrefixMetadata$fileId', payload);
    } catch (_) {}
  }

  // Warm-up caches for top-N results in background
  static Future<void> _warmUpCachesForVideos(
    List<GoogleDriveVideo> videos,
  ) async {
    if (videos.isEmpty) return;
    final top = videos.take(_warmupPrefetchCount).toList();

    // Concurrency-limited prefetcher
    final semaphore = _Semaphore(_warmupConcurrency);
    final futures = <Future<void>>[];

    for (final v in top) {
      futures.add(
        semaphore.withPermit(() async {
          try {
            // Prefetch stream URL
            await getVideoStreamUrl(v.id);
          } catch (_) {}
          try {
            // Prefetch metadata
            await getVideoMetadata(v.id);
          } catch (_) {}
          try {
            // Prefetch thumbnail using DefaultCacheManager
            if (v.thumbnailLink.isNotEmpty) {
              await DefaultCacheManager().getSingleFile(v.thumbnailLink);
            }
          } catch (_) {}
        }),
      );
    }

    // Run without blocking caller
    // Intentionally not awaited where called; this method itself awaits children
    await Future.wait(futures);
  }

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
  // ignore: unused_element
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
        'exp':
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch /
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

      // Cache lookup / in-flight de-duplication
      final key = _searchKey(query);
      _cleanupExpiredCaches();
      final cached = _searchCache[key];
      if (cached != null && cached.isValid) {
        if (kDebugMode) print('⚡ Returning cached search results for "$query"');
        // Start warmup in background for better subsequent UX
        // No await to avoid blocking
        Future.microtask(() => _warmUpCachesForVideos(cached.value));
        return cached.value;
      }
      final existing = _inFlightSearches[key];
      if (existing != null) {
        if (kDebugMode) print('⏳ Awaiting in-flight search for "$query"');
        final results = await existing;
        // Also trigger warmup in background
        Future.microtask(() => _warmUpCachesForVideos(results));
        return results;
      }

      final Future<List<GoogleDriveVideo>> future = (() async {
        final accessToken = await _getAccessToken();
        if (kDebugMode) {
          print('🔑 Got access token successfully');
        }

        List<GoogleDriveVideo> results;
        if (GoogleDriveConfig.targetFolderId.isNotEmpty) {
          if (kDebugMode) {
            print(
              '🎯 Target folder configured: ${GoogleDriveConfig.targetFolderId}',
            );
          }

          if (await _verifyFolderAccess(
            GoogleDriveConfig.targetFolderId,
            accessToken,
          )) {
            if (kDebugMode) {
              print('✅ Target folder verified, searching within it...');
            }
            results = await _searchInFolderDirectly(
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
            results = await _searchGlobally(query, accessToken);
          }
        } else {
          results = await _searchGlobally(query, accessToken);
        }

        // Store in cache
        _searchCache[key] = _Cached(results, DateTime.now().add(_searchTTL));

        // Warm-up prefetch (thumbnails, URLs, metadata) non-blocking
        Future.microtask(() => _warmUpCachesForVideos(results));
        return results;
      })();

      _inFlightSearches[key] = future;
      try {
        final res = await future;
        return res;
      } finally {
        _inFlightSearches.remove(key);
      }
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

  // Get direct download link for video streaming
  static Future<String?> getVideoStreamUrl(String fileId) async {
    // Cache first
    _cleanupExpiredCaches();
    final cached = _streamUrlCache[fileId];
    if (cached != null && cached.isValid) {
      if (kDebugMode) print('⚡ Using cached stream URL for $fileId');
      return cached.value;
    }

    final inflight = _inFlightStream[fileId];
    if (inflight != null) {
      if (kDebugMode) print('⏳ Awaiting in-flight stream URL for $fileId');
      return await inflight;
    }

    // Try disk cache
    try {
      final disk = await _diskGetStreamUrl(fileId);
      if (disk != null && disk.isValid) {
        _streamUrlCache[fileId] = disk;
        if (kDebugMode) print('💾 Using disk-cached stream URL for $fileId');
        return disk.value;
      }
    } catch (_) {}

    final Future<String?> future = _fetchStreamUrlInternal(fileId);
    _inFlightStream[fileId] = future;
    try {
      return await future;
    } finally {
      _inFlightStream.remove(fileId);
    }
  }

  // Get video metadata
  static Future<Map<String, dynamic>?> getVideoMetadata(String fileId) async {
    // Cache first
    _cleanupExpiredCaches();
    final cached = _metadataCache[fileId];
    if (cached != null && cached.isValid) {
      if (kDebugMode) print('⚡ Using cached metadata for $fileId');
      return cached.value;
    }

    final inflight = _inFlightMetadata[fileId];
    if (inflight != null) {
      if (kDebugMode) print('⏳ Awaiting in-flight metadata for $fileId');
      return await inflight;
    }

    // Try disk cache
    try {
      final disk = await _diskGetMetadata(fileId);
      if (disk != null && disk.isValid) {
        _metadataCache[fileId] = disk;
        if (kDebugMode) print('💾 Using disk-cached metadata for $fileId');
        return disk.value;
      }
    } catch (_) {}

    final Future<Map<String, dynamic>?> future = _fetchMetadataInternal(fileId);
    _inFlightMetadata[fileId] = future;
    try {
      return await future;
    } finally {
      _inFlightMetadata.remove(fileId);
    }
  }

  // Internal helpers to fetch data with proper types (moved here)
  static Future<String?> _fetchStreamUrlInternal(String fileId) async {
    try {
      final accessToken = await _getAccessToken();
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/files/$fileId',
        ).replace(queryParameters: {'fields': 'webContentLink,webViewLink'}),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['webContentLink'] ?? data['webViewLink'];
        _streamUrlCache[fileId] = _Cached(url, DateTime.now().add(_streamTTL));
        // write-through to disk
        unawaited(_diskSetStreamUrl(fileId, url, _streamTTL));
        return url;
      } else {
        if (kDebugMode) {
          print('❌ Failed to get stream URL ($fileId): ${response.statusCode}');
        }
        // Negative cache briefly to avoid hammering
        final ttl = const Duration(minutes: 2);
        _streamUrlCache[fileId] = _Cached(null, DateTime.now().add(ttl));
        unawaited(_diskSetStreamUrl(fileId, null, ttl));
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting video stream URL: $e');
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _fetchMetadataInternal(
    String fileId,
  ) async {
    try {
      final accessToken = await _getAccessToken();
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _metadataCache[fileId] = _Cached(
          data,
          DateTime.now().add(_metadataTTL),
        );
        // write-through to disk
        unawaited(_diskSetMetadata(fileId, data, _metadataTTL));
        return data;
      } else {
        if (kDebugMode) {
          print('❌ Failed to get metadata ($fileId): ${response.statusCode}');
        }
        final ttl = const Duration(minutes: 5);
        _metadataCache[fileId] = _Cached(null, DateTime.now().add(ttl));
        unawaited(_diskSetMetadata(fileId, null, ttl));
        return null;
      }
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

  // Public method to clear all in-memory caches related to Drive fetches
  static void clearMemoryCaches() {
    if (kDebugMode) {
      print('🧹 Clearing GoogleDriveService in-memory caches');
    }
    _searchCache.clear();
    _streamUrlCache.clear();
    _metadataCache.clear();
  }

  // Public method to clear on-disk caches for stream URLs and metadata
  static Future<void> clearDiskCaches() async {
    if (kDebugMode) {
      print('🧹 Clearing GoogleDriveService disk caches');
    }
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList(growable: false);
    for (final k in keys) {
      if (k.startsWith(_diskPrefixStream) ||
          k.startsWith(_diskPrefixMetadata)) {
        await prefs.remove(k);
      }
    }
  }
}

// Lightweight semaphore for concurrency limiting
class _Semaphore {
  int _permits;
  final _waiters = <Completer<void>>[];
  _Semaphore(this._permits);

  Future<T> withPermit<T>(Future<T> Function() action) async {
    await _acquire();
    try {
      return await action();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_permits > 0) {
      _permits--;
      return;
    }
    final c = Completer<void>();
    _waiters.add(c);
    await c.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _permits++;
    }
  }
}
