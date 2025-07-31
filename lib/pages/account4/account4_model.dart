import '/flutter_flow/flutter_flow_util.dart';
import 'account4_widget.dart' show Account4Widget;
import 'package:flutter/material.dart';

class Account4Model extends FlutterFlowModel<Account4Widget> {
  ///  State fields for stateful widgets in this page.

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    // Optimized disposal - no tutorial controller to dispose
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
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
            'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=account4',
        searchReference: 'reference=OghhY2NvdW50NFABWghhY2NvdW50NA==',
        widgetClassName: 'account4',
      );
}
