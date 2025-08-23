import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'notificationtoast_widget.dart' show NotificationtoastWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class NotificationtoastModel extends FlutterFlowModel<NotificationtoastWidget> {
  ///  Local state fields for this component.

  String _title = 'Title';
  set title(String value) {
    _title = value;
    debugLogWidgetClass(this);
  }

  String get title => _title;

  String _description = 'Description';
  set description(String value) {
    _description = value;
    debugLogWidgetClass(this);
  }

  String get description => _description;

  String _icon =
      'https://images.unsplash.com/photo-1556696863-6c5eddae0f5f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHwxN3x8dGV4dHxlbnwwfHx8fDE3MzM2ODM4NDl8MA&ixlib=rb-4.0.3&q=80&w=1080';
  set icon(String value) {
    _icon = value;
    debugLogWidgetClass(this);
  }

  String get icon => _icon;

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
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=notificationtoast',
            searchReference:
                'reference=SiAKDwoFdGl0bGUSBmxhd3U4YyoHEgVUaXRsZXIECAMgAVAAWgV0aXRsZQ==',
            name: 'String',
            nullable: false,
          ),
          'description': debugSerializeParam(
            widget?.description,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=notificationtoast',
            searchReference:
                'reference=SiwKFQoLZGVzY3JpcHRpb24SBnY1ZmF0cioNEgtEZXNjcmlwdGlvbnIECAMgAVAAWgtkZXNjcmlwdGlvbg==',
            name: 'String',
            nullable: false,
          ),
          'icon': debugSerializeParam(
            widget?.icon,
            ParamType.Widget,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=notificationtoast',
            searchReference:
                'reference=ShoKDgoEaWNvbhIGdWNnbjdhcggICyABKgIwAlAAWgRpY29u',
            name: 'Widget',
            nullable: true,
          )
        }.withoutNulls,
        localStates: {
          'title': debugSerializeParam(
            title,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=notificationtoast',
            searchReference:
                'reference=QhoKDgoFdGl0bGUSBWptZTAyKgISAHIECAMgAVAAWgV0aXRsZWIRbm90aWZpY2F0aW9udG9hc3Q=',
            name: 'String',
            nullable: false,
          ),
          'description': debugSerializeParam(
            description,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=notificationtoast',
            searchReference:
                'reference=QiAKFAoLZGVzY3JpcHRpb24SBWdqb2xpKgISAHIECAMgAVAAWgtkZXNjcmlwdGlvbmIRbm90aWZpY2F0aW9udG9hc3Q=',
            name: 'String',
            nullable: false,
          ),
          'icon': debugSerializeParam(
            icon,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=notificationtoast',
            searchReference:
                'reference=Qh4KDQoEaWNvbhIFOHM0N2oqBxIFZmFsc2VyBAgEIAFQAFoEaWNvbmIRbm90aWZpY2F0aW9udG9hc3Q=',
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
            'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=notificationtoast',
        searchReference:
            'reference=OhFub3RpZmljYXRpb250b2FzdFAAWhFub3RpZmljYXRpb250b2FzdA==',
        widgetClassName: 'notificationtoast',
      );
}
