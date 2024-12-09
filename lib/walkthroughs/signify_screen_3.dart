import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '/components/walkelement_cardsmall/walkelement_cardsmall_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

// Focus widget keys for this walkthrough
final listView86zm3y4x = GlobalKey();
final container3o25fvbt = GlobalKey();
final containerB46jpjgu = GlobalKey();
final containerIld7clv3 = GlobalKey();

/// Signify Screen 3
///
/// Signify walkthrough for screen 3 Education.
List<TargetFocus> createWalkthroughTargets(BuildContext context) => [
      /// Step 1
      TargetFocus(
        keyTarget: listView86zm3y4x,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.Circle,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                'luetmi3v' /* Learn Indian Sign Language (IS... */,
              ),
              description: FFLocalizations.of(context).getText(
                'lqneq5ry' /* Empower yourself with the abil... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHw1fHxlZHVjYXRpb258ZW58MHx8fHwxNzMzNTk5NTMyfDA&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),

      /// Step 2
      TargetFocus(
        keyTarget: container3o25fvbt,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.RRect,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                '6ui6jaoo' /* Expand Your Knowledge by Visua... */,
              ),
              description: FFLocalizations.of(context).getText(
                'lzptqvcq' /* Explore a rich library of ISL ... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1598618589929-b1433d05cfc6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHwyMXx8Ym9va3N8ZW58MHx8fHwxNzMzNjM0NjM2fDA&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),

      /// Step 3
      TargetFocus(
        keyTarget: containerB46jpjgu,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.RRect,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                'zv6mqs46' /* Become a Part of the Community */,
              ),
              description: FFLocalizations.of(context).getText(
                'qd5roanu' /* Connect with others learning I... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1527525443983-6e60c75fff46?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHw4fHxjb21tdW5pdHl8ZW58MHx8fHwxNzMzNjg5NDYzfDA&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),

      /// Step 4
      TargetFocus(
        keyTarget: containerIld7clv3,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomCenter,
        shape: ShapeLightFocus.RRect,
        color: FlutterFlowTheme.of(context).info,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, __) => WalkelementCardsmallWidget(
              title: FFLocalizations.of(context).getText(
                '75vo9xwb' /* Stay Updated */,
              ),
              description: FFLocalizations.of(context).getText(
                'yp7ruikj' /* Stay up to date with latest ad... */,
              ),
              img:
                  'https://images.unsplash.com/photo-1728577740843-5f29c7586afe?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHwxOXx8YXZhdGFyc3xlbnwwfHx8fDE3MzM2ODk2ODF8MA&ixlib=rb-4.0.3&q=80&w=1080',
            ),
          ),
        ],
      ),
    ];
