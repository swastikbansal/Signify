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
                
                // Step 1: Select file from local storage
                await _model.selectFile();
                
                if (_model.selectedFile != null) {
                  // Step 2: Show rename dialog
                  final shouldProceed = await _showRenameDialog();
                  
                  if (shouldProceed) {
                    // Step 3: Upload the selected file
                    safeSetState(() {}); // Update UI to show loading state
                    
                    final success = await _model.uploadFile();
                    
                    if (mounted) {
                      safeSetState(() {}); // Update UI after upload
                      
                      // Step 4: Show result to user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success 
                            ? 'File uploaded successfully!' 
                            : 'File upload failed. Please try again.'),
                          backgroundColor: success ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 3),
                          action: success ? SnackBarAction(
                            label: 'View',
                            textColor: Colors.white,
                            onPressed: () {
                              // Scroll to show the newly uploaded file
                            },
                          ) : null,
                        ),
                      );
                    }
                  }
                } else {
                  // User cancelled file selection or no file was selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No file selected'),
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
                        ? "Please wait while your file is being processed"
                        : "Supported formats: .jpg, .jpeg",
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
                          child: Icon(
                            file['status'] == 'processing' 
                              ? Icons.hourglass_empty 
                              : Icons.image,
                            color: _model.getStatusColor(file['status'], context),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          file['fileName'] ?? 'Unknown file',
                          style: TextStyle(
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontWeight: FontWeight.w500,
                          ),
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

  Future<bool> _showRenameDialog() async {
    final TextEditingController nameController = TextEditingController();
    final originalName = _model.selectedFile?.files.single.name ?? '';
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
                _model.setCustomFileName('');
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
                  _model.setCustomFileName(newName);
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
}
