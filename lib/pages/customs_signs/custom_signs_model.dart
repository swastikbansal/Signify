import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import 'custom_signs_widget.dart' show CustomSignsPage;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class CustomSignsModel extends FlutterFlowModel<CustomSignsPage> {
  ///  State fields for stateful widgets in this page.

  // File picker state
  FilePickerResult? selectedFile;
  bool isUploading = false;
  String? customFileName; // Store custom file name
  
  // List of uploaded files (you can replace this with actual backend data)
  List<Map<String, dynamic>> uploadedFiles = [
    {
      'fileName': 'custom_data_1.jpg',
      'uploadDate': 'Apr 20, 2024',
      'fileSize': '2.3 MB',
      'status': 'processed'
    },
    {
      'fileName': 'custom_signs.jpeg',
      'uploadDate': 'Apr 10, 2024',
      'fileSize': '1.8 MB',
      'status': 'processed'
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
  Future<void> selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg'],
        allowMultiple: false,
        allowCompression: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        selectedFile = result;
        customFileName = null; // Reset custom name
        debugPrint('File selected: ${result.files.single.name}');
        // Note: State updates will be handled in the widget using safeSetState()
      } else {
        debugPrint('No file selected or picker was cancelled');
      }
    } catch (e) {
      debugPrint('Error selecting file: $e');
    }
  }

  /// Method to set custom file name
  void setCustomFileName(String newName) {
    customFileName = newName;
  }

  /// Get the final file name (custom or original)
  String getFinalFileName() {
    if (selectedFile == null) return '';
    
    if (customFileName != null && customFileName!.isNotEmpty) {
      // Add extension if not present
      final extension = selectedFile!.files.single.extension ?? 'jpg';
      if (!customFileName!.toLowerCase().endsWith('.jpg') && 
          !customFileName!.toLowerCase().endsWith('.jpeg')) {
        return '$customFileName.$extension';
      }
      return customFileName!;
    }
    
    return selectedFile!.files.single.name;
  }

  /// Method to upload file (replace with actual backend implementation)
  Future<bool> uploadFile() async {
    if (selectedFile == null) return false;

    try {
      isUploading = true;
      // Note: UI state updates will be handled in the widget using safeSetState()

      // Simulate upload delay
      await Future.delayed(const Duration(seconds: 2));

      // Add to uploaded files list (replace with actual backend call)
      uploadedFiles.insert(0, {
        'fileName': getFinalFileName(),
        'uploadDate': dateTimeFormat("MMM d, y", getCurrentTimestamp),
        'fileSize': '${(selectedFile!.files.single.size / (1024 * 1024)).toStringAsFixed(1)} MB',
        'status': 'processing'
      });

      selectedFile = null;
      customFileName = null; // Reset custom name
      isUploading = false;
      // Note: UI state updates will be handled in the widget using safeSetState()

      return true;
    } catch (e) {
      isUploading = false;
      // Note: UI state updates will be handled in the widget using safeSetState()
      debugPrint('Error uploading file: $e');
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
