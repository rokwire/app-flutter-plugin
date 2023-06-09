import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/panels/web_panel.dart';
import 'package:rokwire_plugin/ui/widget_builders/buttons.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ActionBuilder {
  static const String notifyShowPanel = "edu.illinois.rokwire.action.show_panel";

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
    Function()? actionFunc = getAction(context, action, dismissContext: dismissContext);
    switch (action?.type) {
      case ActionType.showSurvey:
        return ButtonAction(action?.label ?? Localization().getStringEx("widget.button.action.show_survey.title", "Show Survey"), actionFunc);
      case ActionType.showPanel:
        return ButtonAction(action?.label ?? Localization().getStringEx("widget.button.action.show_panel.title", "Show Panel"), actionFunc);
      case ActionType.launchUri:
        return ButtonAction(action?.label ?? Localization().getStringEx("widget.button.action.launchUri.title", "Open Link"), actionFunc);
      case ActionType.dismiss:
        return ButtonAction(action?.label ?? Localization().getStringEx("widget.button.action.dismiss.title", "Dismiss"), actionFunc);
      default:
        return null;
    }
  }

  static Function()? getAction(BuildContext context, ActionData? action, {BuildContext? dismissContext}) {
    switch (action?.type) {
      case ActionType.showSurvey:
        return (action?.data is String) ? () => onTapShowSurvey(context, action!.data, params: action.params, dismissContext: dismissContext) : null;
      case ActionType.showPanel:
        return (action?.data is String) ? () => onTapShowPanel(context, action!.data, params: action.params, dismissContext: dismissContext) : null;
      case ActionType.launchUri:
        return (action?.data is String) ? () => onTapLaunchUri(context, action!.data, internal: action.isInternalUri, dismissContext: dismissContext) : null;
      case ActionType.dismiss:
        return () => onTapDismiss(dismissContext: dismissContext);
      default:
        return null;
    }
  }

  static List<ButtonAction> actionTypeButtonActions(BuildContext context, List<ActionData>? actions, {BuildContext? dismissContext}) {
    List<ButtonAction> buttonActions = [];
    for (ActionData action in actions ?? []) {
      ButtonAction? buttonAction = ActionBuilder.actionTypeButtonAction(context, action, dismissContext: dismissContext);
      if (buttonAction != null) {
        buttonActions.add(buttonAction);
      }
    }
    return buttonActions;
  }

  static void onTapShowSurvey(BuildContext context, dynamic survey, {Map<String, dynamic>? params, BuildContext? dismissContext}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      onTapDismiss(dismissContext: dismissContext);
      if (survey is String || survey is Survey) {
        //TODO: will change depending on whether survey should be embedded or not
        // setState(() {
        //   _survey = surveyObject;
        //   _mainSurveyData = _survey?.firstQuestion;
        // });
        Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: survey, defaultResponses: JsonUtils.mapValue(params?['default_responses']))));
      }
    });
  }

  static void onTapShowPanel(BuildContext context, dynamic panel, {Map<String, dynamic>? params, BuildContext? dismissContext}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // onTapDismiss(dismissContext: dismissContext);
      switch (panel) {
        case "SurveyPanel":
          if (params?['id'] is String) {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: params!['id'], defaultResponses: JsonUtils.mapValue(params['default_responses']))));
          }
          break;
        case "GuideDetailPanel":
          if (params?['guide_id'] is String) {
            params!["panel"] = "GuideDetailPanel";
            NotificationService().notify(notifyShowPanel, params);
          }
          break;
      }
    });
  }

  static void onTapLaunchUri(BuildContext context, String? uri, {bool? internal, BuildContext? dismissContext}) {
    // onTapDismiss(dismissContext: dismissContext);
    if (StringUtils.isNotEmpty(uri)) {
      if (internal == true || (internal != false && UrlUtils.launchInternal(uri))) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: uri)));
      } else {
        Uri? parsedUri = Uri.tryParse(uri!);
        if (parsedUri != null) {
          launchUrl(parsedUri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }

  static void onTapDismiss({BuildContext? dismissContext}) {
    if (dismissContext != null) {
      Navigator.pop(dismissContext);
    }
  }
}