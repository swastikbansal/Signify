import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'walkelement_cardsmall_widget.dart' show WalkelementCardsmallWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class WalkelementCardsmallModel
    extends FlutterFlowModel<WalkelementCardsmallWidget> {
  ///  Local state fields for this component.

  String _img =
      'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8Nnx8c2hvZXN8ZW58MHx8MHx8&auto=format&fit=crop&w=800&q=60';
  set img(String value) {
    _img = value;
    debugLogWidgetClass(this);
  }

  String get img => _img;

  String? _title = 'Element Title';
  set title(String? value) {
    _title = value;
    debugLogWidgetClass(this);
  }

  String? get title => _title;

  String _description = 'Element Description';
  set description(String value) {
    _description = value;
    debugLogWidgetClass(this);
  }

  String get description => _description;

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
          'title': debugSerializeParam(
            widget?.title,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=walkelementCardsmall',
            searchReference:
                'reference=ShUKDwoFdGl0bGUSBnQwY2o1Y3ICCANQAFoFdGl0bGU=',
            name: 'String',
            nullable: true,
          ),
          'description': debugSerializeParam(
            widget?.description,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=walkelementCardsmall',
            searchReference:
                'reference=ShsKFQoLZGVzY3JpcHRpb24SBjY2a29hdXICCANQAFoLZGVzY3JpcHRpb24=',
            name: 'String',
            nullable: true,
          ),
          'img': debugSerializeParam(
            widget?.img,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=walkelementCardsmall',
            searchReference:
                'reference=ShMKDQoDaW1nEgZsbHdtc3ZyAggEUABaA2ltZw==',
            name: 'String',
            nullable: true,
          )
        }.withoutNulls,
        localStates: {
          'img': debugSerializeParam(
            img,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=walkelementCardsmall',
            searchReference:
                'reference=Qh0KDAoDaW1nEgV2NWh4YSoHEgVmYWxzZXIECAQgAVAAWgNpbWdiFHdhbGtlbGVtZW50Q2FyZHNtYWxs',
            name: 'String',
            nullable: false,
          ),
          'title': debugSerializeParam(
            title,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=walkelementCardsmall',
            searchReference:
                'reference=QhQKDgoFdGl0bGUSBTZsYzh5cgIIA1AAWgV0aXRsZWIUd2Fsa2VsZW1lbnRDYXJkc21hbGw=',
            name: 'String',
            nullable: true,
          ),
          'description': debugSerializeParam(
            description,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=walkelementCardsmall',
            searchReference:
                'reference=QiAKFAoLZGVzY3JpcHRpb24SBWUwam5jKgISAHIECAMgAVAAWgtkZXNjcmlwdGlvbmIUd2Fsa2VsZW1lbnRDYXJkc21hbGw=',
            name: 'String',
            nullable: false,
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
            'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=walkelementCardsmall',
        searchReference:
            'reference=OhR3YWxrZWxlbWVudENhcmRzbWFsbFAAWhR3YWxrZWxlbWVudENhcmRzbWFsbA==',
        widgetClassName: 'walkelementCardsmall',
      );
}
