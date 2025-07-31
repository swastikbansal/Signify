import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'custom_signs_widget.dart' show CustomSignsPage;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class CustomSignsModel extends FlutterFlowModel<CustomSignsPage> {
  ///  State fields for stateful widgets in this page.

  // File picker state
  FilePickerResult? selectedFiles;
  bool isUploading = false;
  Map<String, String> customFileNames = {}; // Store custom file names by original file name
  String? customBatchName; // Store custom batch name

  // List of uploaded files (you can replace this with actual backend data)
  List<Map<String, dynamic>> uploadedFiles = [
    {
      'fileName': 'custom_data_1.jpg',
      'uploadDate': 'Apr 20, 2024',
      'fileSize': '2.3 MB',
      'status': 'processed',
      'fileCount': 1,
      'fileList': ['custom_data_1.jpg'],
      'isBatch': false,
    },
    {
      'fileName': 'Traffic Signs Collection',
      'uploadDate': 'Apr 10, 2024',
      'fileSize': '5.2 MB',
      'status': 'processed',
      'fileCount': 3,
      'fileList': ['custom_signs_1.jpeg', 'custom_signs_2.jpeg', 'custom_signs_3.jpeg'],
      'isBatch': true,
    },
  ];

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};

  @override
  void initState(BuildContext context) {
    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    // Clean up any resources if needed
  }

  /// Method to handle file selection
  Future<void> selectFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg'],
        allowMultiple: true, // Enable multiple file selection
        allowCompression: true,
      );

      if (result != null && result.files.isNotEmpty) {
        selectedFiles = result;
        customFileNames.clear(); // Reset custom names
        debugPrint('Files selected: ${result.files.length} files');
        for (var file in result.files) {
          debugPrint('File: ${file.name}');
        }
        // Note: State updates will be handled in the widget using safeSetState()
      } else {
        debugPrint('No files selected or picker was cancelled');
      }
    } catch (e) {
      debugPrint('Error selecting files: $e');
    }
  }

  /// Method to set custom file name for a specific file
  void setCustomFileName(String originalName, String newName) {
    customFileNames[originalName] = newName;
  }

  /// Method to set custom batch name
  void setCustomBatchName(String batchName) {
    customBatchName = batchName;
  }

  /// Get the final file name for a specific file (custom or original)
  String getFinalFileName(String originalName, String? extension) {
    if (customFileNames.containsKey(originalName) && 
        customFileNames[originalName]!.isNotEmpty) {
      final customName = customFileNames[originalName]!;
      final ext = extension ?? 'jpg';
      
      // Add extension if not present
      if (!customName.toLowerCase().endsWith('.jpg') &&
          !customName.toLowerCase().endsWith('.jpeg')) {
        return '$customName.$ext';
      }
      return customName;
    }

    return originalName;
  }

  /// Method to upload files (replace with actual backend implementation)
  Future<bool> uploadFiles() async {
    if (selectedFiles == null || selectedFiles!.files.isEmpty) return false;

    try {
      isUploading = true;
      // Note: UI state updates will be handled in the widget using safeSetState()

      // Simulate upload delay
      await Future.delayed(const Duration(seconds: 3));

      // Calculate total size of all files
      double totalSize = 0;
      for (var file in selectedFiles!.files) {
        totalSize += file.size / (1024 * 1024); // Convert to MB
      }

      // Create a single batch entry for all uploaded files
      final fileCount = selectedFiles!.files.length;
      final batchLabel = fileCount == 1 
          ? getFinalFileName(selectedFiles!.files.first.name, selectedFiles!.files.first.extension)
          : (customBatchName?.isNotEmpty == true ? customBatchName! : 'Custom Signs Upload - $fileCount files');

      // Create file list for details
      final fileList = selectedFiles!.files.map((file) => 
          getFinalFileName(file.name, file.extension)).toList();

      uploadedFiles.insert(0, {
        'fileName': batchLabel,
        'uploadDate': dateTimeFormat("MMM d, y", getCurrentTimestamp),
        'fileSize': '${totalSize.toStringAsFixed(1)} MB',
        'status': 'processing',
        'fileCount': fileCount,
        'fileList': fileList, // Store individual file names for details
        'isBatch': fileCount > 1, // Flag to identify batch uploads
      });

      selectedFiles = null;
      customFileNames.clear(); // Reset custom names
      customBatchName = null; // Reset custom batch name
      isUploading = false;
      // Note: UI state updates will be handled in the widget using safeSetState()

      return true;
    } catch (e) {
      isUploading = false;
      // Note: UI state updates will be handled in the widget using safeSetState()
      debugPrint('Error uploading files: $e');
      return false;
    }
  }

  /// Method to delete a file
  Future<void> deleteFile(int index) async {
    if (index >= 0 && index < uploadedFiles.length) {
      uploadedFiles.removeAt(index);
      // Note: UI state updates will be handled in the widget using safeSetState()
    }
  }

  /// Method to get file status color
  Color getStatusColor(String status, BuildContext context) {
    switch (status.toLowerCase()) {
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
            (key, value) => MapEntry(
          key,
          value.toWidgetClassDebugData(),
        ),
      ),
    }.withoutNulls,
    link:
    'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=customSigns',
    searchReference: 'reference=OghjdXN0b21TaWducw==',
    widgetClassName: 'customSigns',
  );
}
