import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '/components/walkelement_cardsmall/walkelement_cardsmall_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

// Focus widget keys for this walkthrough
final columnOfubeq9b = GlobalKey();
final containerXdqk8aw2 = GlobalKey();

/// Signify Screen 4
///
/// Signify walkthrough for Screen 4 Account.
List<TargetFocus> createWalkthroughTargets(BuildContext context) => [
      /// Step 1
      TargetFocus(
        keyTarget: columnOfubeq9b,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.Circle,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                'kjfv53gp' /* Your Personal Account */,
              ),
              description: FFLocalizations.of(context).getText(
                '9neu6n5i' /* Manage your profile, settings,... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1610270197941-925ce9015c40?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHw1fHxhY2NvdW50fGVufDB8fHx8MTczMzY2OTcxOXww&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),

      /// Step 2
      TargetFocus(
        keyTarget: columnOfubeq9b,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.RRect,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                '2wbsdw1z' /* Profile Details */,
              ),
              description: FFLocalizations.of(context).getText(
                'uhxx03z1' /* Keep your profile up-to-date t... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1528109966604-5a6a4a964e8d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHw0fHxlZGl0fGVufDB8fHx8MTczMzY5MDEzN3ww&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),

      /// Step 3
      TargetFocus(
        keyTarget: containerXdqk8aw2,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.RRect,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                '7shyb1bb' /* App Preferences */,
              ),
              description: FFLocalizations.of(context).getText(
                'h3mkejsw' /* Tailor the app to your needs b... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1585282263861-f55e341878f8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHw0fHxhcHB8ZW58MHx8fHwxNzMzNjY5MzEzfDA&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),
    ];
