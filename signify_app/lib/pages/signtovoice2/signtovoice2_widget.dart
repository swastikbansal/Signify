import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class Signtovoice2Widget extends StatefulWidget {
  const Signtovoice2Widget({super.key});

  @override
  State<Signtovoice2Widget> createState() => _Signtovoice2WidgetState();
}

class _Signtovoice2WidgetState extends State<Signtovoice2Widget> {
  late TextEditingController textController;
  late FocusNode textFieldFocusNode;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();

    textController = TextEditingController();
    textFieldFocusNode = FocusNode();

    // Initialize Supabase
    _initializeSupabase();
    _initCamera();
  }

  void _initializeSupabase() async {
    await Supabase.initialize(
      url: 'https://hmyiaobxmiqjabtdfjwi.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhteWlhb2J4bWlxamFidGRmandpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM1NjIxODcsImV4cCI6MjA0OTEzODE4N30.6G5UAfS6cLTQ6CPzZVUM9qw9eKVVmSlnqZ4WesQXRtw',
    );
  }


  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.high,
      );

      _initializeControllerFuture = _cameraController.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_cameraController.value.isInitialized) {
      if (isRecording) {
        try {
          XFile videoFile = await _cameraController.stopVideoRecording();
          setState(() {
            isRecording = false;
          });

          debugPrint('Video temporarily stored at: ${videoFile.path}');
          await _uploadVideoToSupabase(videoFile.path);

          if (File(videoFile.path).existsSync()) {
            await File(videoFile.path).delete();
            debugPrint('Temporary video file deleted.');
          }
        } catch (e) {
          debugPrint('Error stopping video recording: $e');
        }
      } else {
        try {
          await _cameraController.startVideoRecording();
          setState(() {
            isRecording = true;
          });
        } catch (e) {
          debugPrint('Error starting video recording: $e');
        }
      }
    }
  }

  Future<void> _uploadVideoToSupabase(String filePath) async {
    try {
      final supabase = Supabase.instance.client;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'video_$timestamp.mp4';
      final file = File(filePath);

      final response = await supabase.storage.from('Video').upload(
        'Videos/$fileName',
        file,
      );

      final publicURL = supabase.storage
          .from('Video')
          .getPublicUrl('Videos/$fileName');

      debugPrint('Public URL: $publicURL');
    } catch (e) {
      debugPrint('Failed to upload video: $e');
    }
  }

  @override
  void dispose() {
    textController.dispose();
    textFieldFocusNode.dispose();
    if (_cameraController.value.isInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.black54,
        appBar: AppBar(
          backgroundColor: Colors.black54,
          automaticallyImplyLeading: false,
          title: Text(
            'Sign to Voice',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(5.0, 0.0, 5.0, 0.0),
                child: Container(
                  child: FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return AspectRatio(
                          aspectRatio: 3 / 4, // Custom aspect ratio
                          child: CameraPreview(_cameraController),
                        );
                      } else {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DropdownButton<String>(
                      items: [
                        'English',
                        'Hindi',
                        'Bengali',
                        'Marathi',
                        'Telugu',
                        'Tamil',
                        'Gujarati',
                        'Punjabi'
                      ]
                          .map((language) => DropdownMenuItem<String>(
                        value: language,
                        child: Text(language),
                      ))
                          .toList(),
                      onChanged: (value) {
                        // Handle language selection
                      },
                      hint: Text('Select Language'),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isRecording ? Colors.white70 : Colors.transparent,
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: Colors.grey[700], // Adjust this color as needed for the icon.
                        ),
                        onPressed: _toggleVideoRecording,
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50.0),
                      child: IconButton(
                        icon: Icon(Icons.volume_up),
                        onPressed: () {
                          // Additional audio actions can be implemented here
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 111.9697,
                child: Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border(
                        top: BorderSide(
                          color: Colors.black26,
                          width: 2.0,
                        ),
                        left: BorderSide(
                          color: Colors.black26,
                          width: 2.0,
                        ),
                        right: BorderSide(
                          color: Colors.black26,
                          width: 2.0,
                        ),
                        bottom: BorderSide.none, // No border at the bottom
                      ),
                    ),
                    child: Center(
                      child: TextField(
                        controller: textController,
                        focusNode: textFieldFocusNode,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Translated Text',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12.0,
                          ),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 10,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}