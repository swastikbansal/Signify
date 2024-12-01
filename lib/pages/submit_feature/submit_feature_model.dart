import '/flutter_flow/flutter_flow_util.dart';
import 'submit_feature_widget.dart' show SubmitFeatureWidget;
import 'package:flutter/material.dart';

class SubmitFeatureModel extends FlutterFlowModel<SubmitFeatureWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for featureRequest widget.
  FocusNode? featureRequestFocusNode;
  TextEditingController? featureRequestTextController;
  String? Function(BuildContext, String?)?
      featureRequestTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    featureRequestFocusNode?.dispose();
    featureRequestTextController?.dispose();
  }
}
