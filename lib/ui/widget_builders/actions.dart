import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/widget_builders/buttons.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ActionBuilder {
  static List<Widget> actionButtons(List<ButtonAction>? actions) {
    List<Widget> buttons = [];
    for (ButtonAction action in actions ?? []) {
      if (buttons.isNotEmpty) {
        buttons.add(Container(height: 8));
      }
      buttons.add(ButtonBuilder.standardRoundedButton(label: action.title, onTap: action.action));
    }
    return buttons;
  }

  //TODO: Reimplement as service that allows registration of action types
  static ButtonAction? actionTypeButtonAction(BuildContext context, ActionData? action, {BuildContext? dismissContext}) {
    Function()? actionFunc = getAction(action, context: context, dismissContext: dismissContext);
    switch (action?.type) {
      case ActionType.showSurvey:
        return ButtonAction(action?.label ?? Localization().getStringEx("widget.button.action.show_survey.title", "Show Survey"), actionFunc);
      case ActionType.launchUri:
        return ButtonAction(action?.label ?? Localization().getStringEx("widget.button.action.launchUri.title", "Open Link"), actionFunc);
      case ActionType.dismiss:
        return ButtonAction(action?.label ?? Localization().getStringEx("widget.button.action.dismiss.title", "Dismiss"), actionFunc);
      default:
        return null;
    }
  }

  static Function()? getAction(ActionData? action, {BuildContext? context, BuildContext? dismissContext}) {
    switch (action?.type) {
      case ActionType.showSurvey:
        return (action?.data is String) ? () => onTapShowSurvey(action!.data) : null;
      case ActionType.launchUri:
        if (action?.data is String) {
          dynamic internal = action?.params['internal'];
          return (internal is bool?) ? () => onTapLaunchUri(action!.data, internal: internal, context: context, dismissContext: dismissContext) : null;
        }
        return null;
      case ActionType.dismiss:
        return () => onTapDismiss(dismissContext: dismissContext);
      default:
        return null;
    }
  }

  static List<ButtonAction> actionTypeButtonActions(BuildContext context, List<ActionData>? actions, {BuildContext? dismissContext}) {
    List<ButtonAction> buttonActions = [];
    for (ActionData action in actions ?? []) {
      ButtonAction? buttonAction = ActionBuilder.actionTypeButtonAction(context, action);
      if (buttonAction != null) {
        buttonActions.add(buttonAction);
      }
    }
    return buttonActions;
  }

  static void onTapShowSurvey(dynamic survey, {BuildContext? context, BuildContext? dismissContext}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      onTapDismiss(dismissContext: dismissContext);
      if (survey is String || survey is Survey) {
        //TODO: will change depending on whether survey should be embedded or not
        // setState(() {
        //   _survey = surveyObject;
        //   _mainSurveyData = _survey?.firstQuestion;
        // });
        Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: survey)));
      }
    });
  }

  static void onTapLaunchUri(String? uri, {bool? internal, BuildContext? context, BuildContext? dismissContext}) {
    // onTapDismiss(dismissContext: dismissContext);
    UrlUtils.launch(context, uri, internal: internal);
  }

  static void onTapDismiss({BuildContext? dismissContext}) {
    if (dismissContext != null) {
      Navigator.pop(dismissContext);
    }
  }
}