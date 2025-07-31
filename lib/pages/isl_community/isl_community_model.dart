import '/flutter_flow/flutter_flow_util.dart';
import 'isl_community_widget.dart' show IslCommunityWidget;
import 'package:flutter/material.dart';

class IslCommunityModel extends FlutterFlowModel<IslCommunityWidget> {
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
            'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=islCommunity',
        searchReference: 'reference=Ogxpc2xDb21tdW5pdHlQAVoMaXNsQ29tbXVuaXR5',
        widgetClassName: 'islCommunity',
      );
}
