import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '/components/walkelement_cardsmall/walkelement_cardsmall_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

// Focus widget keys for this walkthrough
final row3qnw9877 = GlobalKey();
final iconButtonIwoicpe5 = GlobalKey();
final iconButtonO625l09g = GlobalKey();

/// Signify Screen 1
///
/// Signify walkthrough for screen 1 Voice to Sign.
List<TargetFocus> createWalkthroughTargets(BuildContext context) => [
      /// Step 1
      TargetFocus(
        keyTarget: row3qnw9877,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.Circle,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                'whrx7nqi' /* Welcome to Signify. */,
              ),
              description: FFLocalizations.of(context).getText(
                'zoeeea3e' /* Discover how Signify enables s... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1640550444366-b94e5752c479?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHw3fHxzaWduJTIwbGFuZ3VhZ2V8ZW58MHx8fHwxNzMzNjgxNDAwfDA&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),

      /// Step 2
      TargetFocus(
        keyTarget: iconButtonIwoicpe5,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.Circle,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                'igv8chfo' /* Speech Recognition */,
              ),
              description: FFLocalizations.of(context).getText(
                'nicwmjfz' /* Press the microphone button, s... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1541592553160-82008b127ccb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHwxOHx8bWljfGVufDB8fHx8MTczMzY4NDcxN3ww&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),

      /// Step 3
      TargetFocus(
        keyTarget: iconButtonO625l09g,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.Circle,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                'go06z7dv' /* Send Button */,
              ),
              description: FFLocalizations.of(context).getText(
                'pqr6f1i4' /* Press the button to see the 3D... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1601597111158-2fceff292cdc?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHwxfHxzZW5kJTIwaWNvbnxlbnwwfHx8fDE3MzM2ODYxNzl8MA&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),
    ];
