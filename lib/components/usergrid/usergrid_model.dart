import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'usergrid_widget.dart' show UsergridWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class UsergridModel extends FlutterFlowModel<UsergridWidget> {
  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetParameters: {
          'img': debugSerializeParam(
            widget?.img,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=usergrid',
            searchReference:
                'reference=ShMKDQoDaW1nEgZyNGFranpyAggEUABaA2ltZw==',
            name: 'String',
            nullable: true,
          ),
          'title': debugSerializeParam(
            widget?.title,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=usergrid',
            searchReference:
                'reference=ShUKDwoFdGl0bGUSBnZzbzJicnICCANQAFoFdGl0bGU=',
            name: 'String',
            nullable: true,
          ),
          'description': debugSerializeParam(
            widget?.description,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=usergrid',
            searchReference:
                'reference=ShsKFQoLZGVzY3JpcHRpb24SBnhwenlrM3ICCANQAFoLZGVzY3JpcHRpb24=',
            name: 'String',
            nullable: true,
          )
        }.withoutNulls,
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
            'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=usergrid',
        searchReference: 'reference=Ogh1c2VyZ3JpZFAAWgh1c2VyZ3JpZA==',
        widgetClassName: 'usergrid',
      );
}
