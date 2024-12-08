import '/flutter_flow/flutter_flow_util.dart';
import 'isl_dict_widget.dart' show IslDictWidget;
import 'package:flutter/material.dart';

class IslDictModel extends FlutterFlowModel<IslDictWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
