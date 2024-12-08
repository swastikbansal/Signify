import '/flutter_flow/flutter_flow_util.dart';
import 'account4_widget.dart' show Account4Widget;
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'package:flutter/material.dart';

class Account4Model extends FlutterFlowModel<Account4Widget> {
  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? signifyScreen4Controller;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    signifyScreen4Controller?.finish();
  }
}
