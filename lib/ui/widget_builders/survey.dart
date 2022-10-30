import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widget_builders/actions.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyBuilder {
  static Widget? surveyDataResult(BuildContext context, SurveyDataResult? survey) {
    if (survey == null) return null;

    List<Widget> buttonActions = resultSurveyButtons(context, survey);
    return Column(
      children: <Widget>[
        Text(survey.moreInfo ?? '', style: Styles().textStyles?.getTextStyle('widget.detail.regular')),
        CollectionUtils.isNotEmpty(buttonActions) ? Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: buttonActions),
        ) : Container(),
      ],
    );
  }

  static List<Widget> resultSurveyButtons(BuildContext context, SurveyDataResult? survey, {EdgeInsets padding = const EdgeInsets.all(0)}) {
    return ActionBuilder.actionButtons(ActionBuilder.actionTypeButtonActions(context, survey?.actions, dismissContext: context));
  }

  static Widget surveyResponseCard(BuildContext context, SurveyResponse response, {bool showTimeOnly = false}) {
    List<Widget> widgets = [];

    String? date;
    if (showTimeOnly) {
      date = DateTimeUtils.getDisplayTime(dateTimeUtc: response.dateCreated);
    } else {
      date = DateTimeUtils.getDisplayDateTime(response.dateCreated);
    }

    widgets.addAll([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(response.survey.title.toUpperCase(), style: Styles().textStyles?.getTextStyle('widget.title.small.fat')),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(date ?? '', style: Styles().textStyles?.getTextStyle('widget.detail.small')),
              Container(width: 8.0),
              Image.asset('images/chevron-right.png')
              // UIIcon(IconAssets.chevronRight, size: 14.0, color: Styles().colors.headlineText),
            ],
          ),
        ],
      ),
      Container(height: 8),
    ]);

    Map<String, dynamic>? responses = response.survey.stats?.responseData;
    if (responses?.length == 1) {
      widgets.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Localization().getStringEx("widget.survey.response_card.response.title", "Response:"),
              style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat')),
          SizedBox(width: 8.0),
          Flexible(child: Text(responses?.values.join(", ") ?? '', style: Styles().textStyles?.getTextStyle('widget.detail.regular'))),
        ],
      ));
    }

    dynamic result = response.survey.resultData;
    if (result is Map<String, dynamic>) {
      if (result['type'] == 'survey_data.result') {
        SurveyDataResult dataResult = SurveyDataResult.fromJson('result', result);
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Localization().getStringEx("widget.survey.response_card.result.title", "Results:"),
                  style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat')),
              SizedBox(height: 4.0),
              SurveyBuilder.surveyDataResult(context, dataResult) ?? Container(),
            ],
          ),
        ));
      }
    }

    return Material(
      borderRadius: BorderRadius.circular(30),
      color: Styles().colors?.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        // onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyResponseSummaryPanel(response: response))),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgets,
            )
        ),
      ),
    );
  }
}