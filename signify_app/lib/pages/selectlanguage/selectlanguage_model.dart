import '/auth/base_auth_user_provider.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_language_selector.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'selectlanguage_widget.dart' show SelectlanguageWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SelectlanguageModel extends FlutterFlowModel<SelectlanguageWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for DropDown widget.
  int? _dropDownValue;
  set dropDownValue(int? value) {
    _dropDownValue = value;
    debugLogWidgetClass(this);
  }

  int? get dropDownValue => _dropDownValue;

  FormFieldController<int>? dropDownValueController;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    debugLogWidgetClass(this);
  }

  @override
  void dispose() {}

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetStates: {
          'dropDownValue': debugSerializeParam(
            dropDownValue,
            ParamType.int,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=selectlanguage',
            name: 'int',
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
            'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=selectlanguage',
        searchReference:
            'reference=Og5zZWxlY3RsYW5ndWFnZVABWg5zZWxlY3RsYW5ndWFnZQ==',
        widgetClassName: 'selectlanguage',
      );
}
