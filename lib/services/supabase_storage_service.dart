import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadResult {
  final String originalName;
  final String finalName;
  final String label;
  final String path;
  final String? publicUrl;
  final int sizeBytes;
  final bool success;
  final String? error;

  UploadResult({
    required this.originalName,
    required this.finalName,
    required this.label,
    required this.path,
    required this.publicUrl,
    required this.sizeBytes,
    required this.success,
    this.error,
  });
}

class SupabaseStorageService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String defaultBucket = 'Custom_Dataset';

  static Future<List<UploadResult>> uploadUserCustomPhotos({
    required List<PlatformFile> files,
    Map<String, String>? customNames,
    Map<String, String>? labels,
    String bucket = defaultBucket,
    bool upsert = true,
  }) async {
    // Ensure Supabase authentication before uploading

    final List<UploadResult> results = [];

    for (final file in files) {
      final originalName = file.name;

      final extension =
          (file.extension ?? _inferExtensionFromName(originalName))
              .toLowerCase();

      final finalName = _sanitizeFileName(
        _ensureExtension(
          customNames?[originalName]?.trim().isNotEmpty == true
              ? customNames![originalName]!.trim()
              : originalName,
          extension,
        ),
      );

      final rawLabel = labels?[originalName]?.trim();
      final label = _sanitizePathSegment(
        rawLabel?.isNotEmpty == true ? rawLabel! : 'unlabeled',
      );

      final String storagePath = '$label/$finalName';
      final contentType = _contentTypeForExtension(extension);

      debugPrint(
        'Uploading file: $finalName to $storagePath with label $label',
      );

      try {
        if (kIsWeb) {
          // On web, upload bytes (file.path not available)
          final Uint8List bytes =
              file.bytes ??
              (throw StorageException(
                'File bytes are null on web. Enable withData in file picker.',
              ));
          await _client.storage
              .from(bucket)
              .upload(
                storagePath,
                bytes
                    as dynamic, // cast to dynamic to avoid Uint8List -> File type error
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              );
        } else {
          // On non-web, use local File constructed from the file path
          final String? filePath = file.path;
          if (filePath == null) {
            throw StorageException(
              'File path is null. Ensure the file is accessible.',
            );
          }
          final localFile = File(filePath);
          await _client.storage
              .from(bucket)
              .upload(
                storagePath,
                localFile,
                fileOptions: FileOptions(cacheControl: '3600', upsert: upsert),
              );
        }

        final publicUrl = _client.storage
            .from(bucket)
            .getPublicUrl(storagePath);

        results.add(
          UploadResult(
            originalName: originalName,
            finalName: finalName,
            label: label,
            path: storagePath,
            publicUrl: publicUrl,
            sizeBytes: file.size,
            success: true,
          ),
        );
      } on StorageException catch (e) {
        results.add(
          UploadResult(
            originalName: originalName,
            finalName: finalName,
            label: label,
            path: storagePath,
            publicUrl: null,
            sizeBytes: file.size,
            success: false,
            error:
                'StorageException(${e.statusCode ?? '400'}): ${e.message} | path=$storagePath | size=${file.size} | contentType=$contentType | bucket=$bucket',
          ),
        );
      } catch (e) {
        results.add(
          UploadResult(
            originalName: originalName,
            finalName: finalName,
            label: label,
            path: storagePath,
            publicUrl: null,
            sizeBytes: file.size,
            success: false,
            error:
                'UploadError: ${e.toString()} | path=$storagePath | bucket=$bucket',
          ),
        );
      }
    }

    return results;
  }

  static String _ensureExtension(String name, String ext) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.$ext')) return name;
    // allow common jpeg variants
    if (ext == 'jpg' || ext == 'jpeg') {
      if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return name;
      return '$name.$ext';
    }
    return '$name.$ext';
  }

  static String _sanitizePathSegment(String input) {
    // Replace spaces with underscores, remove slashes and illegal chars, lower-case it
    final sanitized = input
        .replaceAll(RegExp(r"[\\/]+"), '-')
        .replaceAll(RegExp(r"[^a-zA-Z0-9._-]+"), '_')
        .replaceAll(RegExp(r"_+"), '_')
        .trim()
        .toLowerCase();
    return sanitized.isEmpty ? 'unlabeled' : sanitized;
  }

  // New: sanitize the file name (excluding the path) to avoid 400 from invalid keys.
  static String _sanitizeFileName(String input) {
    // Keep dots for extensions, replace illegal path/separator characters.
    final sanitized = input
        .replaceAll(RegExp(r'[\\/]+'), '-') // no slashes
        .replaceAll(RegExp(r'[\u0000-\u001F]'), '') // control chars
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_') // safe charset
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    return sanitized.isEmpty
        ? 'file.${_inferExtensionFromName(input).toLowerCase()}'
        : sanitized;
  }

  static String _inferExtensionFromName(String name) {
    final idx = name.lastIndexOf('.');
    if (idx == -1 || idx == name.length - 1) return 'jpg';
    return name.substring(idx + 1);
  }

  static String _contentTypeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      // Common video types (if needed)
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }
}
