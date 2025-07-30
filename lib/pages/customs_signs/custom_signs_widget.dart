import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import 'custom_signs_model.dart';
export 'custom_signs_model.dart';

class CustomSignsPage extends StatefulWidget {
  const CustomSignsPage({super.key});

  @override
  State<CustomSignsPage> createState() => _CustomSignsPageState();
}

class _CustomSignsPageState extends State<CustomSignsPage> {
  late CustomSignsModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomSignsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        elevation: 0,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 100.0,
          buttonSize: 50.0,
          hoverColor: FlutterFlowTheme.of(context).secondaryBackground,
          hoverIconColor: FlutterFlowTheme.of(context).primaryText,
          icon: Icon(
            Icons.arrow_back_ios,
            color: FlutterFlowTheme.of(context).primaryText,
            size: 24.0,
          ),
          onPressed: () async {
            context.safePop();
          },
        ),
        title: Text(
          'Custom Signs',
          style: TextStyle(
            color: FlutterFlowTheme.of(context).primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Upload your own custom signs to improve sign recognition and personalize results.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FlutterFlowTheme.of(context).secondaryText,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                if (_model.isUploading) return; // Prevent multiple uploads

                // Step 1: Select files from local storage
                await _model.selectFiles();

                if (_model.selectedFiles != null && _model.selectedFiles!.files.isNotEmpty) {
                  // Step 2: Show rename dialog for multiple files
                  final shouldProceed = await _showMultipleFilesRenameDialog();

                  if (shouldProceed) {
                    // Step 3: Upload the selected files
                    safeSetState(() {}); // Update UI to show loading state

                    final success = await _model.uploadFiles();

                    if (mounted) {
                      safeSetState(() {}); // Update UI after upload

                      // Step 4: Show result to user
                      final fileCount = _model.selectedFiles?.files.length ?? 0;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? '$fileCount file${fileCount > 1 ? 's' : ''} uploaded successfully!'
                              : 'File upload failed. Please try again.'),
                          backgroundColor: success ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 3),
                          action: success ? SnackBarAction(
                            label: 'View',
                            textColor: Colors.white,
                            onPressed: () {
                              // Scroll to show the newly uploaded files
                            },
                          ) : null,
                        ),
                      );
                    }
                  }
                } else {
                  // User cancelled file selection or no files were selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No files selected'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  border: Border.all(
                    color: _model.isUploading
                        ? FlutterFlowTheme.of(context).primary
                        : FlutterFlowTheme.of(context).alternate,
                    width: _model.isUploading ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    // Show loading animation or upload icon
                    _model.isUploading
                        ? SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: FlutterFlowTheme.of(context).primary,
                        strokeWidth: 3.0,
                      ),
                    )
                        : Icon(
                      Icons.upload_rounded,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _model.isUploading
                          ? "Uploading..."
                          : "Upload Custom Signs",
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _model.isUploading
                          ? "Please wait while your files are being processed"
                          : "Supported formats: .jpg, .jpeg (Multiple files allowed)",
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _model.uploadedFiles.length,
                itemBuilder: (context, index) {
                  final file = _model.uploadedFiles[index];
                  return Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _model.getStatusColor(file['status'], context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: file['isBatch'] == true
                              ? Stack(
                                  children: [
                                    Icon(
                                      file['status'] == 'processing'
                                          ? Icons.hourglass_empty
                                          : Icons.folder,
                                      color: _model.getStatusColor(file['status'], context),
                                      size: 18,
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: _model.getStatusColor(file['status'], context),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${file['fileCount'] ?? 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Icon(
                                  file['status'] == 'processing'
                                      ? Icons.hourglass_empty
                                      : Icons.image,
                                  color: _model.getStatusColor(file['status'], context),
                                  size: 20,
                                ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file['fileName'] ?? 'Unknown file',
                              style: TextStyle(
                                color: FlutterFlowTheme.of(context).primaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (file['isBatch'] == true && file['fileCount'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  "${file['fileCount']} file${file['fileCount'] > 1 ? 's' : ''}",
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context).primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Uploaded on ${file['uploadDate'] ?? 'Unknown date'}",
                              style: TextStyle(
                                color: FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 12,
                              ),
                            ),
                            if (file['isBatch'] == true && file['fileList'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "Files: ${(file['fileList'] as List<String>).join(', ')}",
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Row(
                              children: [
                                Text(
                                  file['fileSize'] ?? 'Unknown size',
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _model.getStatusColor(file['status'], context).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    file['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                                    style: TextStyle(
                                      color: _model.getStatusColor(file['status'], context),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (file['status'] == 'processing')
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: FlutterFlowTheme.of(context).primary,
                                  strokeWidth: 2.0,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                          ],
                        ),
                        onTap: () {
                          // Handle file tap (view details, etc.)
                          if (file['isBatch'] == true) {
                            _showBatchDetailsDialog(file);
                          }
                        },
                      ),
                      if (index < _model.uploadedFiles.length - 1)
                        Divider(color: FlutterFlowTheme.of(context).alternate),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<bool> _showMultipleFilesRenameDialog() async {
    final files = _model.selectedFiles?.files ?? [];
    if (files.isEmpty) return false;

    final Map<String, TextEditingController> controllers = {};
    final TextEditingController batchNameController = TextEditingController();
    
    // Initialize controllers for each file
    for (var file in files) {
      final nameWithoutExtension = file.name.split('.').first;
      controllers[file.name] = TextEditingController(text: nameWithoutExtension);
    }

    // Set default batch name suggestion
    if (files.length > 1) {
      batchNameController.text = 'Custom Signs Collection';
    }

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          title: Text(
            files.length > 1 
                ? 'Name Your Collection (${files.length} files)'
                : 'Rename File',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (files.length > 1) ...[
                  Text(
                    'Give your collection of ${files.length} files a meaningful name',
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: batchNameController,
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Collection Name *',
                      labelStyle: TextStyle(
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                      hintText: 'e.g., Traffic Signs, Warning Signs, etc.',
                      hintStyle: TextStyle(
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: 12,
                      ),
                    ),
                    maxLength: 50,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Individual File Names (optional):',
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  Text(
                    'You can rename this file or keep the original name',
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              files.length > 1 
                                  ? 'File ${index + 1}: ${file.name}'
                                  : 'Original: ${file.name}',
                              style: TextStyle(
                                color: FlutterFlowTheme.of(context).primaryText,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: controllers[file.name],
                              style: TextStyle(
                                color: FlutterFlowTheme.of(context).primaryText,
                              ),
                              decoration: InputDecoration(
                                labelText: files.length > 1 ? 'Custom name (optional)' : 'New file name',
                                labelStyle: TextStyle(
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                ),
                                hintText: 'Enter custom name',
                                hintStyle: TextStyle(
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).alternate,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).primary,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, 
                                  vertical: 8,
                                ),
                              ),
                              maxLength: 50,
                              textInputAction: index < files.length - 1 
                                  ? TextInputAction.next 
                                  : TextInputAction.done,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Text(
                  'Extensions will be added automatically. Leave individual names blank to keep originals.',
                  style: TextStyle(
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Dispose controllers
                batchNameController.dispose();
                for (var controller in controllers.values) {
                  controller.dispose();
                }
                Navigator.of(context).pop(false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
              ),
            ),
            if (files.length > 1)
              TextButton(
                onPressed: () {
                  // Keep all original names with default batch name
                  _model.customFileNames.clear();
                  _model.setCustomBatchName('');
                  // Dispose controllers
                  batchNameController.dispose();
                  for (var controller in controllers.values) {
                    controller.dispose();
                  }
                  Navigator.of(context).pop(true);
                },
                child: Text(
                  'Use Defaults',
                  style: TextStyle(
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                // Validate batch name for multiple files
                if (files.length > 1) {
                  final batchName = batchNameController.text.trim();
                  if (batchName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a collection name'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  _model.setCustomBatchName(batchName);
                }

                // Set custom names for files that have been renamed
                for (var file in files) {
                  final newName = controllers[file.name]?.text.trim() ?? '';
                  if (newName.isNotEmpty) {
                    _model.setCustomFileName(file.name, newName);
                  }
                }
                
                // Dispose controllers
                batchNameController.dispose();
                for (var controller in controllers.values) {
                  controller.dispose();
                }
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                foregroundColor: Colors.white,
              ),
              child: Text(files.length > 1 ? 'Create Collection' : 'Rename & Upload'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _showRenameDialog() async {
    final TextEditingController nameController = TextEditingController();
    final originalName = _model.selectedFiles?.files.single.name ?? '';
    final nameWithoutExtension = originalName.split('.').first;

    nameController.text = nameWithoutExtension;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          title: Text(
            'Rename File',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Original name: $originalName',
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
                decoration: InputDecoration(
                  labelText: 'New file name',
                  labelStyle: TextStyle(
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                  hintText: 'Enter custom name (without extension)',
                  hintStyle: TextStyle(
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
                maxLength: 50,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 8),
              Text(
                'Extension (.jpg or .jpeg) will be added automatically',
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Use original name
                _model.setCustomFileName(originalName, '');
                Navigator.of(context).pop(true);
              },
              child: Text(
                'Keep Original',
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  _model.setCustomFileName(originalName, newName);
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid file name'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rename & Upload'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showBatchDetailsDialog(Map<String, dynamic> batchFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          title: Text(
            'Batch Upload Details',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Date: ${batchFile['uploadDate'] ?? 'Unknown'}',
                  style: TextStyle(
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Size: ${batchFile['fileSize'] ?? 'Unknown'}',
                  style: TextStyle(
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _model.getStatusColor(batchFile['status'], context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        batchFile['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                        style: TextStyle(
                          color: _model.getStatusColor(batchFile['status'], context),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Files in this batch (${batchFile['fileCount'] ?? 0}):',
                  style: TextStyle(
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (batchFile['fileList'] != null)
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: (batchFile['fileList'] as List<String>).length,
                      itemBuilder: (context, index) {
                        final fileName = (batchFile['fileList'] as List<String>)[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.image,
                                size: 16,
                                color: FlutterFlowTheme.of(context).secondaryText,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  fileName,
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context).primaryText,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
