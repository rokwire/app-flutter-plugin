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
  static ButtonAction? actionTypeButtonAction(BuildContext context, ActionData? action, {BuildContext? dismissContext, Map<String, dynamic>? params}) {
    switch (action?.type) {
      case ActionType.showSurvey:
        if (action?.data is Survey) {
          return ButtonAction(action?.label ?? Localization().getStringEx("widget.button.action.show_survey.title", "Show Survey"),
                  () => onTapShowSurvey(context, action!.data, dismissContext: dismissContext, params: params)
          );
        } else if (action?.data is Map<String, dynamic>) {
          dynamic survey = action?.data['survey'];
          return ButtonAction(action?.label ?? Localization().getStringEx("widget.button.action.show_survey.title", "Show Survey"),
                  () => onTapShowSurvey(context, survey, dismissContext: dismissContext, params: params)
          );
        }
        return null;
      case ActionType.launchUri:
        dynamic data = action?.data;
        if (data is String) {
          return ButtonAction(action?.label ?? Localization().getStringEx("widget.button.action.launchUri.title", "Open Link"),
                  () => onTapLaunchUri(context, data, dismissContext: dismissContext, params: params)
          );
        } else if (action?.data is Map<String, dynamic>) {
          dynamic uri = action?.data['uri'];
          dynamic internal = action?.data['internal'];
          if (uri is String && internal is bool?) {
            return ButtonAction(action?.label ?? Localization().getStringEx("widget.button.action.launchUri.title", "Open Link"),
                    () => onTapLaunchUri(context, uri, internal: internal, dismissContext: dismissContext, params: params)
            );
          }
        }
        return null;
      case ActionType.dismiss:
        return ButtonAction(action?.label ?? Localization().getStringEx("widget.button.action.dismiss.title", "Dismiss"),
                () => onTapDismiss(dismissContext: dismissContext)
        );
      default:
        return null;
    }
  }

  static List<ButtonAction> actionTypeButtonActions(BuildContext context, List<ActionData>? actions, {BuildContext? dismissContext, Map<String, dynamic>? params}) {
    List<ButtonAction> buttonActions = [];
    for (ActionData action in actions ?? []) {
      ButtonAction? buttonAction = ActionBuilder.actionTypeButtonAction(context, action);
      if (buttonAction != null) {
        buttonActions.add(buttonAction);
      }
    }
    return buttonActions;
  }

  static void onTapShowSurvey(BuildContext context, dynamic survey, {BuildContext? dismissContext, Map<String, dynamic>? params}) {
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

  static void onTapLaunchUri(BuildContext context, String? uri, {bool? internal, BuildContext? dismissContext, Map<String, dynamic>? params}) {
    // onTapDismiss(dismissContext: dismissContext);
    UrlUtils.launch(context, uri, internal: internal);
  }

  static void onTapDismiss({BuildContext? dismissContext}) {
    if (dismissContext != null) {
      Navigator.pop(dismissContext);
    }
  }
}