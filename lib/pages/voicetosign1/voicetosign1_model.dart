import '/flutter_flow/flutter_flow_util.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'voicetosign1_widget.dart' show Voicetosign1Widget;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class Voicetosign1Model extends FlutterFlowModel<Voicetosign1Widget> {
  ///  Local state fields for this page.

  String _imgpath =
      'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8Nnx8c2hvZXN8ZW58MHx8MHx8&auto=format&fit=crop&w=800&q=60';

  set imgpath(String value) {
    _imgpath = value;
    debugLogWidgetClass(this);
  }

  String get imgpath => _imgpath;

  String _title = 'Element Title';

  set title(String value) {
    _title = value;
    debugLogWidgetClass(this);
  }

  String get title => _title;

  String _description = 'Element Description';

  set description(String value) {
    _description = value;
    debugLogWidgetClass(this);
  }

  String get description => _description;

  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? signifyScreen1Controller;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  // Speech to text variables
  stt.SpeechToText? speechToText;
  bool isListening = false;
  String recognizedText = '';
  String finalizedText = ''; // Store the finalized/confirmed text
  String currentPartialText =
      ''; // Store the current partial text being processed

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};

  @override
  void initState(BuildContext context) {
    debugLogWidgetClass(this);
    speechToText = stt.SpeechToText();
  }

  @override
  void dispose() {
    signifyScreen1Controller?.finish();
    textFieldFocusNode?.dispose();
    textController?.dispose();
    if (isListening) {
      speechToText?.stop();
    }
    // Clear speech variables
    clearSpeechText();
  }

  // Initialize speech recognition
  Future<bool> initSpeech() async {
    try {
      bool available = await speechToText?.initialize(
            onError: (error) {
              debugPrint("Speech initialization error: $error");
            },
            onStatus: (status) {
              debugPrint("Speech initialization status: $status");
            },
          ) ??
          false;
      return available;
    } catch (e) {
      debugPrint("Failed to initialize speech: $e");
      return false;
    }
  }

  // Start listening to speech
  void startListening(Function(String) onResult) async {
    if (!isListening) {
      bool available = await initSpeech();
      if (available) {
        isListening = true;

        // Start continuous listening
        _startContinuousListening(onResult);
      }
    }
  }

  // Continuous listening implementation
  void _startContinuousListening(Function(String) onResult) async {
    if (!isListening) return;

    try {
      await speechToText?.listen(
        onResult: (result) {
          if (result.finalResult) {
            // This is a final result - add it to our finalized text
            if (result.recognizedWords.trim().isNotEmpty) {
              // Add space before new sentence if there's existing text
              String newText = result.recognizedWords.trim();
              if (finalizedText.isNotEmpty && !finalizedText.endsWith(' ')) {
                finalizedText += ' ';
              }
              finalizedText += newText;
              currentPartialText = ''; // Clear partial text

              // Update the full text
              recognizedText = finalizedText;
              onResult(recognizedText);
            }

            // Don't restart immediately after final result - let the session continue
            // The speech recognition will naturally keep listening for more input
            // This eliminates the restart sounds
          } else {
            // This is a partial result - update without finalizing
            currentPartialText = result.recognizedWords;

            // Combine finalized text with current partial text
            String fullText = finalizedText;
            if (currentPartialText.isNotEmpty) {
              if (fullText.isNotEmpty && !fullText.endsWith(' ')) {
                fullText += ' ';
              }
              fullText += currentPartialText;
            }

            recognizedText = fullText;
            onResult(recognizedText);
          }
        },
        listenFor: const Duration(hours: 1),
        // Very long duration to avoid timeouts
        pauseFor: const Duration(seconds: 8),
        // Much longer pause before stopping - allows natural conversation pace
        localeId: null,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );

      // Set up status listener to handle only when session truly ends
      speechToText?.statusListener = (status) {
        debugPrint("Speech status: $status");
        if (status == 'done' && isListening) {
          // Only restart if the session has truly ended and we still want to listen
          // Use a longer delay to minimize restart frequency
          Future.delayed(const Duration(seconds: 2), () {
            if (isListening) {
              debugPrint("Session ended naturally, restarting quietly...");
              _startContinuousListening(onResult);
            }
          });
        }
      };
    } catch (e) {
      debugPrint("Speech recognition error: $e");
      // Only retry after significant errors, with a longer delay to minimize sound interruptions
      if (isListening) {
        Future.delayed(const Duration(seconds: 3), () {
          if (isListening) {
            debugPrint("Retrying after error...");
            _startContinuousListening(onResult);
          }
        });
      }
    }
  }

  // Stop listening to speech
  void stopListening() {
    if (isListening) {
      speechToText?.stop();
      isListening = false;
      // Don't reset the text when stopping - keep what was recognized
      // finalizedText and recognizedText will keep the accumulated text
      currentPartialText = ''; // Clear only the partial text
    }
  }

  // Method to clear all speech text (useful for starting fresh)
  void clearSpeechText() {
    finalizedText = '';
    currentPartialText = '';
    recognizedText = '';
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        localStates: {
          'imgpath': debugSerializeParam(
            imgpath,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=voicetosign1',
            searchReference:
                'reference=QiEKEAoHaW1ncGF0aBIFcGs1NDQqBxIFZmFsc2VyBAgEIAFQAVoHaW1ncGF0aGIMdm9pY2V0b3NpZ24x',
            name: 'String',
            nullable: false,
          ),
          'title': debugSerializeParam(
            title,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=voicetosign1',
            searchReference:
                'reference=QhoKDgoFdGl0bGUSBWJoM2Z0KgISAHIECAMgAVABWgV0aXRsZWIMdm9pY2V0b3NpZ24x',
            name: 'String',
            nullable: false,
          ),
          'description': debugSerializeParam(
            description,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=voicetosign1',
            searchReference:
                'reference=QiAKFAoLZGVzY3JpcHRpb24SBXdnbmJmKgISAHIECAMgAVABWgtkZXNjcmlwdGlvbmIMdm9pY2V0b3NpZ24x',
            name: 'String',
            nullable: false,
          )
        },
        widgetStates: {
          'textFieldText': debugSerializeParam(
            textController?.text,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=voicetosign1',
            name: 'String',
            nullable: true,
          )
        },
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
            'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=voicetosign1',
        searchReference: 'reference=Ogx2b2ljZXRvc2lnbjFQAVoMdm9pY2V0b3NpZ24x',
        widgetClassName: 'voicetosign1',
      );
}
