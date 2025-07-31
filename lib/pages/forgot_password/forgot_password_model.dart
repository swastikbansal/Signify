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

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    resetemailAddressFocusNode?.dispose();
    resetemailAddressTextController?.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetStates: {
          'resetemailAddressText': debugSerializeParam(
            resetemailAddressTextController?.text,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=forgotPassword',
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
            'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=forgotPassword',
        searchReference:
            'reference=Og5mb3Jnb3RQYXNzd29yZFABWg5mb3Jnb3RQYXNzd29yZA==',
        widgetClassName: 'forgotPassword',
      );
}
