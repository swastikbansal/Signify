import '/flutter_flow/flutter_flow_util.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'voicetosign1_widget.dart' show Voicetosign1Widget;
import 'package:flutter/material.dart';

class Voicetosign1Model extends FlutterFlowModel<Voicetosign1Widget> {
  ///  Local state fields for this page.

  String imgpath =
      'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8Nnx8c2hvZXN8ZW58MHx8MHx8&auto=format&fit=crop&w=800&q=60';

  String title = 'Element Title';

  String description = 'Element Description';

  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? signifyScreen1Controller;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    signifyScreen1Controller?.finish();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
