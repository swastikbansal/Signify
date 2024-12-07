import '/flutter_flow/flutter_flow_util.dart';
import 'forgot_password_widget.dart' show ForgotPasswordWidget;
import 'package:flutter/material.dart';

class ForgotPasswordModel extends FlutterFlowModel<ForgotPasswordWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for resetemailAddress widget.
  FocusNode? resetemailAddressFocusNode;
  TextEditingController? resetemailAddressTextController;
  String? Function(BuildContext, String?)?
      resetemailAddressTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    resetemailAddressFocusNode?.dispose();
    resetemailAddressTextController?.dispose();
  }
}
