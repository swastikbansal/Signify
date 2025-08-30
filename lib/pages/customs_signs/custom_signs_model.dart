import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/supabase_storage_service.dart';
import '/services/uploaded_files_service.dart';
import 'custom_signs_widget.dart' show CustomSignsPage;

class CustomSignsModel extends FlutterFlowModel<CustomSignsPage> {
  FilePickerResult? selectedFiles;
  bool isUploading = false;
  bool isTraining = false;
  String? trainingError;
  Map<String, String> customFileNames = {};
  String? customBatchName;
  Map<String, String> perFileLabels = {};

  List<Map<String, dynamic>> uploadedFiles = [];

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  final String _apiUrl = 'http://10.29.46.248:5000';
  // String _apiUrl = 'https://philosia-codecult-signify.hf.space/process_frame';

  String get _customSignsEndpoint => '$_apiUrl/customTrain';
  String get _switchModelEndpoint => '$_apiUrl/switchModel';

  @override
  void initState(BuildContext context) {
    debugLogWidgetClass(this);
    _loadUploadedFiles();
  }

  /// Load uploaded files from persistent storage for the current user
  Future<void> _loadUploadedFiles() async {
    try {
      uploadedFiles = await UploadedFilesService.instance.getUploadedFiles();
      debugPrint(
        'Loaded ${uploadedFiles.length} uploaded files from storage for current user',
      );
    } catch (e) {
      debugPrint('Error loading uploaded files: $e');
      uploadedFiles = [];
    }
  }

  /// Public method to refresh uploaded files data (useful for manual refresh)
  Future<void> refreshUploadedFiles() async {
    await _loadUploadedFiles();
  }

  @override
  void dispose() {}

  Future<void> selectFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: true,
        allowCompression: true,
        // Always include bytes; upload service will prefer bytes when available.
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        selectedFiles = result;
        customFileNames.clear();
        perFileLabels.clear();
        debugPrint('Files selected: ${result.files.length} files');
        for (var file in result.files) {
          debugPrint('File: ${file.name}');
        }
      } else {
        debugPrint('No files selected or picker was cancelled');
      }
    } catch (e) {
      debugPrint('Error selecting files: $e');
    }
  }

  String _safeString(String? s) => (s ?? '').trim();

  // Add safer wrapper methods for UI callbacks
  void safeSetCustomFileName(String? originalName, String? newName) {
    try {
      setCustomFileName(originalName, newName);
    } catch (e) {
      debugPrint('Error setting custom file name: $e');
    }
  }

  void safeSetCustomBatchName(String? batchName) {
    try {
      setCustomBatchName(batchName);
    } catch (e) {
      debugPrint('Error setting custom batch name: $e');
    }
  }

  void safeSetFileLabel(String? originalName, String? label) {
    try {
      setFileLabel(originalName, label);
    } catch (e) {
      debugPrint('Error setting file label: $e');
    }
  }

  void setCustomFileName(String? originalName, String? newName) {
    if (originalName == null || newName == null) return;

    final key = _safeString(originalName);
    final value = _safeString(newName);

    if (key.isEmpty) return;

    try {
      if (value.isEmpty) {
        customFileNames.remove(key);
      } else {
        customFileNames[key] = value;
      }
    } catch (e) {
      debugPrint('Error in setCustomFileName: $e');
    }
  }

  void setCustomBatchName(String? batchName) {
    if (batchName == null) {
      customBatchName = null;
      return;
    }

    try {
      final value = _safeString(batchName);
      customBatchName = value.isEmpty ? null : value;
    } catch (e) {
      debugPrint('Error in setCustomBatchName: $e');
      customBatchName = null;
    }
  }

  void setFileLabel(String? originalName, String? label) {
    if (originalName == null || label == null) return;

    final key = _safeString(originalName);
    final value = _safeString(label);

    if (key.isEmpty) return;

    try {
      if (value.isEmpty) {
        perFileLabels.remove(key);
      } else {
        perFileLabels[key] = value;
      }
    } catch (e) {
      debugPrint('Error in setFileLabel: $e');
    }
  }

  /// Get the final file name for a specific file (null-safe)
  String getFinalFileName(String originalName, String? extension) {
    final orig = _safeString(originalName);
    if (orig.isEmpty) {
      // Fallback name to avoid passing nulls elsewhere
      return 'unnamed${extension != null ? '.$extension' : '.jpg'}';
    }

    if (customFileNames.containsKey(orig) &&
        _safeString(customFileNames[orig]).isNotEmpty) {
      final customName = _safeString(customFileNames[orig]);
      final ext = _safeString(extension).isEmpty
          ? 'jpg'
          : _safeString(extension);

      // Add extension if not present (case-insensitive)
      final lower = customName.toLowerCase();
      if (!lower.endsWith('.jpg') &&
          !lower.endsWith('.jpeg') &&
          !lower.endsWith('.png') &&
          !lower.endsWith('.webp')) {
        return '$customName.$ext';
      }
      return customName;
    }

    return orig;
  }

  /// Call the custom training endpoint with uploaded file paths
  Future<bool> trainCustomModel(
    List<String> filePaths,
    List<String> labels,
  ) async {
    bool trainingSuccess = false;

    try {
      isTraining = true;
      trainingError = null;

      debugPrint("Calling custom training API");
      debugPrint("Calling $_customSignsEndpoint");
      final response = await http.post(
        Uri.parse(_customSignsEndpoint),
        headers: {'Content-Type': 'application/json'},
        // body: jsonEncode({'file_paths': filePaths, 'labels': labels}),
      );

      if (response.statusCode == 200) {
        trainingSuccess = true;
        debugPrint('Training completed successfully - HTTP 200');

        // Log response for debugging purposes
        try {
          final responseData = jsonDecode(response.body);
          debugPrint('Training response: $responseData');
        } catch (e) {
          debugPrint(
            'Could not parse response body, but training successful based on HTTP 200',
          );
        }
      } else {
        trainingError = 'Server error: ${response.statusCode}';
        debugPrint('Training failed with status: ${response.statusCode}');
      }
    } catch (e) {
      trainingError = 'Network error: $e';
      debugPrint('Error during training: $e');
    } finally {
      isTraining = false;
    }

    return trainingSuccess;
  }

  /// Switch to the newly trained custom model
  Future<bool> switchToCustomModel() async {
    try {
      final response = await http.post(
        Uri.parse(_switchModelEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'modelType': 'custom'}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Model switch response: $responseData');
        return responseData['status'] == 'success' ||
            responseData['success'] == true;
      } else {
        debugPrint('Model switch failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error switching model: $e');
      return false;
    }
  }

  /// Upload files to Supabase Storage organized by labels
  Future<bool> uploadFiles() async {
    if (selectedFiles == null || selectedFiles!.files.isEmpty) return false;

    try {
      isUploading = true;

      // Perform upload to Supabase Storage
      final results = await SupabaseStorageService.uploadUserCustomPhotos(
        files: selectedFiles!.files,
        customNames: customFileNames,
        labels: perFileLabels,
      );

      // Summarize upload outcome
      final successes = results.where((r) => r.success).toList();
      final failures = results.where((r) => !r.success).toList();

      // Calculate total size of successful uploads
      double totalSize = successes.fold(
        0.0,
        (sum, r) => sum + r.sizeBytes / (1024 * 1024),
      );

      // Batch label shown in UI
      final fileCount = results.length;
      final batchLabel = fileCount == 1
          ? (successes.isNotEmpty
                ? _safeString(successes.first.finalName)
                : getFinalFileName(
                    selectedFiles!.files.first.name,
                    selectedFiles!.files.first.extension,
                  ))
          : (customBatchName?.isNotEmpty == true
                ? customBatchName!
                : 'Custom Signs Upload - $fileCount files');

      // Create file list for details (defensive access)
      final fileList = results.map((r) {
        try {
          if (r.success == true) {
            final label = _safeString(r.label);
            final finalName = _safeString(r.finalName);
            return label.isNotEmpty ? '$label/$finalName' : finalName;
          } else {
            return 'FAILED: ${_safeString(r.originalName)}';
          }
        } catch (_) {
          return 'FAILED: unknown';
        }
      }).toList();

      final newFileEntry = {
        'fileName': batchLabel,
        'uploadDate': dateTimeFormat("MMM d, y", getCurrentTimestamp),
        'fileSize': '${totalSize.toStringAsFixed(1)} MB',
        'status': failures.isEmpty
            ? 'processing'
            : (successes.isNotEmpty ? 'partial' : 'failed'),
        'fileCount': fileCount,
        'fileList': fileList,
        'isBatch': fileCount > 1,
        'publicUrls': successes
            .map((r) => _safeString(r.publicUrl))
            .where((s) => s.isNotEmpty)
            .toList(),
        'paths': successes
            .map((r) => _safeString(r.path))
            .where((s) => s.isNotEmpty)
            .toList(),
      };

      // Add to local list and persist to storage
      uploadedFiles.insert(0, newFileEntry);
      await UploadedFilesService.instance.addUploadedFile(newFileEntry);

      isUploading = false;

      // Start training if uploads were successful DO NOT TOUCH FOR NOW
      if (successes.isNotEmpty) {
        final filePaths = successes
            .map((r) => _safeString(r.path))
            .where((s) => s.isNotEmpty)
            .toList();
        final labels = successes
            .map((r) => _safeString(r.label))
            .where((s) => s.isNotEmpty)
            .toList();

        debugPrint("Calling custom training API");
        final trainingSuccess = await trainCustomModel(filePaths, labels);

        // Update the status based on training result
        uploadedFiles[0]['status'] = trainingSuccess ? 'trained' : 'failed';
        if (!trainingSuccess && trainingError != null) {
          uploadedFiles[0]['error'] = trainingError;
        }

        // Persist the status update
        await UploadedFilesService.instance.updateUploadedFile(
          0,
          uploadedFiles[0],
        );
      }

      selectedFiles = null;
      customFileNames.clear();
      customBatchName = null;

      return true;
    } catch (e) {
      isUploading = false;
      debugPrint('Error uploading files: $e');
      return false;
    }
  }

  /// Method to delete a file
  Future<void> deleteFile(int index) async {
    if (index >= 0 && index < uploadedFiles.length) {
      uploadedFiles.removeAt(index);
      await UploadedFilesService.instance.removeUploadedFile(index);
      // Note: UI state updates will be handled in the widget using safeSetState()
    }
  }

  /// Method to get file status color
  Color getStatusColor(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'trained':
        return Colors.green;
      case 'processed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return FlutterFlowTheme.of(context).secondaryText;
    }
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
    generatorVariables: debugGeneratorVariables,
    backendQueries: debugBackendQueries,
    componentStates: {
      ...widgetBuilderComponents.map(
        (key, value) => MapEntry(key, value.toWidgetClassDebugData()),
      ),
    }.withoutNulls,
    link:
        'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=customSigns',
    searchReference: 'reference=OghjdXN0b21TaWducw==',
    widgetClassName: 'customSigns',
  );
}
