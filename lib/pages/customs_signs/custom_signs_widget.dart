import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';

class CustomSignsPage extends StatelessWidget {
  const CustomSignsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
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
        title: const Text(
          'Custom Signs',
          style: TextStyle(
            color: Colors.white,
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
            const Text(
              "Upload your own custom signs to improve sign recognition and personalize results.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                try {
                  bool uploadSuccess = true; // Replace with actual upload logic
                  if (uploadSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File uploaded successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File upload failed. Please try again.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('An error occurred during file upload.'),
                      backgroundColor: Colors.red,
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
                  color: Colors.grey[900],
                ),
                child: Column(
                  children: const [
                    Icon(Icons.upload_rounded, color: Colors.yellow, size: 40),
                    SizedBox(height: 8),
                    Text(
                      "Upload Custom Signs",
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Supported formats: .jpg, .jpeg",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    title: Text("custom_data_1.jpg",
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text("Uploaded on Apr 20, 2024",
                        style: TextStyle(color: Colors.white54)),
                    trailing: Icon(Icons.chevron_right, color: Colors.white54),
                  ),
                  Divider(color: Colors.white24),
                  ListTile(
                    title: Text("custom_signs.jpeg",
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text("Uploaded on Apr 10, 2024",
                        style: TextStyle(color: Colors.white54)),
                    trailing: Icon(Icons.chevron_right, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
