
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/model/alert.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widget_builders/actions.dart';

class Alerts {
  static const String notifyAlert = "edu.illinois.rokwire.alert";

  static void handleNotification(BuildContext context, Alert alert) {
    List<ButtonAction> buttonActions = [];
    for (ActionData action in alert.actions ?? []) {
      ButtonAction? buttonAction = ActionBuilder.actionTypeButtonAction(context, action, dismissContext: context);
      if (buttonAction != null) {
        buttonActions.add(buttonAction);
      }
    }

    if (alert.params?['immediate'] == true) {
      ActionsMessage.show(context: context, title: alert.title, message: alert.text, buttons: ActionBuilder.actionButtons(buttonActions), buttonAxis: Axis.vertical);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          ActionsMessage.show(context: context, title: alert.title, message: alert.text,
              buttons: ActionBuilder.actionButtons(buttonActions), buttonAxis: Axis.vertical));
    }
  }

  static Widget buildDividerLine({double height = 1, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin,
      height: height,
      color: Styles().colors?.dividerLine,
    );
  }
}