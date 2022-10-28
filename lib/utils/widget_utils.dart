// Copyright 2022 Board of Trustees of the University of Illinois.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class SurveyUtils {
  static List<Widget> buildResultSurveyButtons(BuildContext context, SurveyDataResult? survey) {
    List<Widget> buttonActions = [];
    for (ActionData action in survey?.actions ?? []) {
      ButtonAction? buttonAction = actionTypeButtonAction(context, action);
      if (buttonAction != null) {
        buttonActions.add(Padding(padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16), child: RoundedButton(label: buttonAction.title, borderColor: Styles().colors?.fillColorPrimary,
              backgroundColor: Styles().colors?.surface, textColor: Styles().colors?.headlineText, onTap: buttonAction.action as void Function())));
      }
    }
    return buttonActions;
  }

  static ButtonAction? actionTypeButtonAction(BuildContext context, ActionData? action, {BuildContext? dismissContext}) {
    switch (action?.type) {
      case ActionType.showSurvey:
        if (action?.data is Survey) {
          return ButtonAction(action?.label ?? Localization().getStringEx("panel.home.button.action.show_survey.title", "Show Survey"), () => onTapShowSurvey(context, action?.data, dismissContext: dismissContext));
        } else if (action?.data is Map<String, dynamic>) {
          dynamic survey = action?.data['survey'];
          return ButtonAction(action?.label ?? Localization().getStringEx("panel.home.button.action.show_survey.title", "Show Survey"), () => onTapShowSurvey(context, action?.data, dismissContext: dismissContext));
        }
        return null;
      case ActionType.contact:
        //TODO: handle phone, web URIs, etc.
        if (action?.data is Map<String, dynamic>) {
          dynamic uri = action?.data['uri'];
          return ButtonAction(action?.label ?? Localization().getStringEx("panel.home.button.action.show_survey.title", "Show Survey"), () => onTapContact(uri));
        }
        return null;
      case ActionType.dismiss:
        return ButtonAction(action?.label ?? Localization().getStringEx("panel.home.button.action.dismiss.title", "Dismiss"), () => onTapDismiss(dismissContext: dismissContext));
      default:
        return null;
    }
  }

  static void onTapContact(dynamic uri) {
    //TODO: handle URIs
  }

  static void onTapShowSurvey(BuildContext context, dynamic survey, {BuildContext? dismissContext}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Survey? surveyObject;
      if (survey is Survey) {
        surveyObject = survey;
      } else if (survey is String) {
        surveyObject = await Polls().loadSurvey(survey);
      }

      if (surveyObject != null) {
        //TODO: will change depending on whether survey should be embedded or not
        // setState(() {
        //   _survey = surveyObject;
        //   _mainSurveyData = _survey?.firstQuestion;
        // });
        Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: surveyObject!, surveyDataKey: surveyObject.defaultDataKey, onComplete: () {
          surveyObject!.evaluate();
        })));
      } else {
        onTapDismiss(dismissContext: context);
      }
    });
  }

  static void onTapDismiss({BuildContext? dismissContext}) {
    if (dismissContext != null) {
      Navigator.pop(dismissContext);
    }
  }
}