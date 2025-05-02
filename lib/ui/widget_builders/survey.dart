import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/widget_builders/actions.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyBuilder {
  static Widget? surveyDataResult(BuildContext context, SurveyDataResult? survey) {
    if (survey == null) return null;

    List<Widget> buttonActions = resultSurveyButtons(context, survey);
    List<Widget> content = [];
    if (StringUtils.isNotEmpty(survey.text)) {
      content.add(Text(survey.text, textAlign: TextAlign.start, style: Styles().textStyles.getTextStyle('widget.title.dark.large.fat')));
    }
    if (StringUtils.isNotEmpty(survey.moreInfo)) {
      content.add(Padding(padding: const EdgeInsets.only(top: 8), child: Text(survey.moreInfo!, style: Styles().textStyles.getTextStyle('widget.detail.regular'))));
    }
    if (CollectionUtils.isNotEmpty(buttonActions)) {
      content.add(Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buttonActions),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: content);
  }

  static List<Widget> resultSurveyButtons(BuildContext context, SurveyDataResult? survey, {EdgeInsets padding = const EdgeInsets.all(0)}) {
    return ActionBuilder.actionButtons(ActionBuilder.actionTypeButtonActions(context, survey?.actions, dismissContext: context));
  }

  static Widget surveyResponseCard(BuildContext context, SurveyResponse response, {String? title, bool showTimeOnly = false, void Function()? onTap}) {
    List<Widget> widgets = [];

    String? date;
    if (showTimeOnly) {
      date = AppDateTime().getDisplayTime(dateTimeUtc: response.dateTaken);
    } else {
      date = AppDateTime().getDisplayDateTime(response.dateTaken);
    }

    widgets.addAll([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: Text(title ?? response.survey.title.toUpperCase(), style: Styles().textStyles.getTextStyle('widget.title.dark.small.fat'))),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(date ?? '', style: Styles().textStyles.getTextStyle('widget.detail.dark.small')),
              Container(width: 8.0),
              Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true) ?? Container()
              // UIIcon(IconAssets.chevronRight, size: 14.0, color: Styles().colors.headlineText),
            ],
          ),
        ],
      ),
    ]);

    if (CollectionUtils.isNotEmpty(response.survey.responseKeys)) {
      Map<String, dynamic>? responses = response.survey.stats?.responseData;

      for (String key in response.survey.responseKeys!) {
        //TODO: Handle string localization
        dynamic responseData = responses?[key];
        if (responseData != null) {
          widgets.add(Container(height: 8));
          widgets.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(key.replaceAll('_', ' ').toUpperCase() + ':',
                  style: Styles().textStyles.getTextStyle('widget.description.regular.fat')),
              const SizedBox(width: 8.0),
              Flexible(child: Text(responseData ?? '', style: Styles().textStyles.getTextStyle('widget.detail.regular'))),
            ],
          ));
        }
      }
    }

    Widget? resultWidget = surveyResult(context, response.survey);
    if (resultWidget != null) {
      widgets.add(resultWidget);
    }

    return Material(
      borderRadius: BorderRadius.circular(30),
      color: Styles().colors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () => (onTap != null) ? onTap() : Navigator.push(context, CupertinoPageRoute(builder: (context) =>
          SurveyPanel(survey: response.survey, inputEnabled: false, dateTaken: response.dateTaken, showResult: true)
        )),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgets,
            )
        ),
      ),
    );
  }

  static Widget? surveyResult(BuildContext context, Survey? survey) {
    dynamic result = survey?.resultData;
    if (result is Map<String, dynamic>) {
      if (result['type'] == 'survey_data.result') {
        SurveyDataResult dataResult = SurveyDataResult.fromJson('result', result);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Localization().getStringEx("widget.survey.response_card.result.title", "Result:"),
                  style: Styles().textStyles.getTextStyle('widget.detail.dark.regular.fat')),
              const SizedBox(height: 8.0),
              SurveyBuilder.surveyDataResult(context, dataResult) ?? Container(),
            ],
          ),
        );
      }
    }
    return null;
  }
}