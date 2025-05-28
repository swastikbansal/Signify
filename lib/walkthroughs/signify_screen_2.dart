import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '/components/walkelement_cardsmall/walkelement_cardsmall_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

// Focus widget keys for this walkthrough
final column7du8ugv9 = GlobalKey();
final dropDownB9wm9jo8 = GlobalKey();
final iconButtonPl161kuq = GlobalKey();
final iconButton9jd3gtk2 = GlobalKey();

/// Signify Screen 2
///
/// Signify walkthrough for screen 2 Sign to Voice.
List<TargetFocus> createWalkthroughTargets(BuildContext context) => [
      /// Step 1
      TargetFocus(
        keyTarget: column7du8ugv9,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.Circle,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                'ljd521u0' /* Effortless Communication */,
              ),
              description: FFLocalizations.of(context).getText(
                '0j48fmb6' /* Use the camera to capture ISL ... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1512221684154-3a1f36dac982?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHwxMXx8Y2FwdHVyZXxlbnwwfHx8fDE3MzM2ODc0Njd8MA&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),

      /// Step 2
      TargetFocus(
        keyTarget: dropDownB9wm9jo8,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.RRect,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                '4anfae5c' /* Regional Language  */,
              ),
              description: FFLocalizations.of(context).getText(
                '63plts8t' /* Choose your preferred language... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1536690179483-7a0f1d0efc05?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHwyNHx8bGFuZ3VhZ2V8ZW58MHx8fHwxNzMzNTczNjUwfDA&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),

      /// Step 3
      TargetFocus(
        keyTarget: iconButtonPl161kuq,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.Circle,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                'llp29yvv' /* Capture Button */,
              ),
              description: FFLocalizations.of(context).getText(
                'wyphd06u' /* Press the button, to record th... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1524135220673-c731600a1a50?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHwyM3x8Y2FtZXJhfGVufDB8fHx8MTczMzY4NzQ0M3ww&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),

      /// Step 4
      TargetFocus(
        keyTarget: iconButton9jd3gtk2,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.Circle,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                'alqhp33p' /* Speaker Button */,
              ),
              description: FFLocalizations.of(context).getText(
                'es4nakb5' /* Press the speaker button, to l... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1511842745775-b366af36db2a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHwxNHx8c3BlYWtlcnxlbnwwfHx8fDE3MzM2ODgzMjZ8MA&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),
    ];
