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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/options.dart';
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/rules.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widget_builders/survey.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/radio_button.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyWidgetController {
  // Controllers
  void Function()? continueSurvey;
  Survey? Function()? getSurvey;

  // Callbacks
  Function(bool)? onChangeSurveyResponse;
  Function()? beforeComplete;
  Function(dynamic)? onComplete;
  Function(Survey?)? onLoad;
  bool saving;

  SurveyWidgetController({this.onChangeSurveyResponse, this.beforeComplete, this.onComplete, this.onLoad, this.saving = false});
}

class SurveyWidget extends StatefulWidget {
  final dynamic survey;
  final String? surveyDataKey;
  final SurveyData? mainSurveyData;
  final bool inputEnabled;
  final DateTime? dateTaken;
  final bool showResult;
  final bool internalContinueButton;
  final Map<String, dynamic>? defaultResponses;
  final Widget? offlineWidget;
  final bool summarizeResultRules;
  final Widget? summarizeResultRulesWidget;

  late final SurveyWidgetController controller;

  SurveyWidget({Key? key, required this.survey, this.inputEnabled = true, this.dateTaken, this.showResult = false, this.internalContinueButton = true,
    this.surveyDataKey, this.mainSurveyData, this.defaultResponses, this.offlineWidget, this.summarizeResultRules = false, this.summarizeResultRulesWidget,
    SurveyWidgetController? controller}) : super(key: key) {
    this.controller = controller ?? SurveyWidgetController();
  }

  @override
  State<SurveyWidget> createState() => _SurveyWidgetState();

  static Widget buildContinueButton(SurveyWidgetController controller) {
    Survey? survey = controller.getSurvey?.call();
    bool canContinue = survey != null ? Surveys().canContinue(survey) : false;

    int? totalQuestions = survey?.stats?.total;
    int? completedQuestions = survey?.stats?.complete;
    String questionProgress = "";
    if (totalQuestions != null && completedQuestions != null) {
      questionProgress = " ($completedQuestions/$totalQuestions)";
    }
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      RoundedButton(
          label: Localization().getStringEx("widget.survey.button.action.continue.title", "Continue") + questionProgress,
          textColor: canContinue ? null : Styles().colors?.disabledTextColor,
          borderColor: canContinue ? null : Styles().colors?.disabledTextColor,
          enabled: canContinue && !controller.saving,
          onTap: controller.continueSurvey,
          progress: controller.saving),
    ]);
  }
}

class _SurveyWidgetState extends State<SurveyWidget> {
  bool _loading = false;
  Survey? _survey;
  SurveyData? _mainSurveyData;
  Map<String, TextEditingController>? _dateTimeTextControllers;

  @override
  void initState() {
    super.initState();

    widget.controller.continueSurvey = _onTapContinue;
    widget.controller.getSurvey = () => _survey;

    initSurvey();
  }

  void initSurvey() {
    if (widget.survey is Survey) {
      _survey = widget.survey;
      _mainSurveyData = widget.mainSurveyData;
      _mainSurveyData ??= Surveys().getFirstQuestion(_survey!);
    } else if (widget.survey is String) {
      _setLoading(true);
      Surveys().loadSurvey(widget.survey).then((survey) {
        if (survey != null) {
          _setSurvey(survey);
          widget.controller.onLoad?.call(survey);
        }
        _setLoading(false);
      });
    }
  }

  @override
  void didUpdateWidget(SurveyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.survey != oldWidget.survey) {
      setState(() {
        initSurvey();
      });
    }
  }

  @override
  void dispose() {
    _dateTimeTextControllers?.forEach((key, value) { value.dispose(); });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors?.fillColorPrimary)),
        ),
      );
    }
    return _survey != null && _mainSurveyData != null ? Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Visibility(visible: widget.dateTaken != null, child: _buildDateTaken()),
            Visibility(visible: StringUtils.isNotEmpty(_survey?.moreInfo), child: _buildMoreInfo()),
            _buildContent(),
            Visibility(visible: widget.showResult, child: _buildResult() ?? Container()),
            Visibility(visible: widget.inputEnabled && widget.internalContinueButton,
                child: SurveyWidget.buildContinueButton(widget.controller)),
        ]),
      ) : (Connectivity().isOffline && widget.offlineWidget != null ? widget.offlineWidget! : Container());
  }

  Widget _buildDateTaken() {
    DateTime? dateTaken = widget.dateTaken;
    if (dateTaken == null) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(AppDateTime().getDisplayDateTime(dateTaken), style: Styles().textStyles?.getTextStyle('widget.detail.regular'),),
    );
  }

  Widget _buildMoreInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Text(_survey!.moreInfo ?? '', style: Styles().textStyles?.getTextStyle('widget.message.large.fat'),),
    );
  }

  Widget? _buildResult() {
    return SurveyBuilder.surveyResult(context, _survey);
  }

  Widget _buildContent() {
    if (_survey == null) {
      return Container();
    }

    List<Widget> contentList = [];
    for (SurveyData? data = _mainSurveyData; data != null; data = Surveys().getFollowUp(_survey!, data)) {
      Widget? surveyWidget = _buildInlineSurveyWidget(data);
      if (surveyWidget != null) {
        // GlobalKey? key;
        // if (data.response == null) {
        //   key = GlobalKey();
        //   dataKey = key;
        // }
        contentList.add(Padding(padding: contentList.isNotEmpty ? const EdgeInsets.only(top: 32) : EdgeInsets.zero, child: surveyWidget));
      }
      if (contentList.length > 1000) {
        break;
      }
    }

    return Column(children: contentList);
  }

  void _onChangeResponse(bool scrollEnd) {
    setState(() {
      if (_survey != null) {
        Surveys().evaluate(_survey!);
      }
    });
    widget.controller.onChangeSurveyResponse?.call(scrollEnd);
  }

  Widget? _buildInlineSurveyWidget(SurveyData survey, {TextStyle? textStyle, EdgeInsets textPadding = const EdgeInsets.only(bottom: 8),
    EdgeInsets moreInfoPadding = const EdgeInsets.only(bottom: 8)}) {
    SurveyDataWidget? surveyWidget;

    if (survey is SurveyQuestionMultipleChoice) {
      surveyWidget = _buildMultipleChoiceSurveySection(survey, enabled: widget.inputEnabled);
    } else if (survey is SurveyQuestionTrueFalse) {
      surveyWidget = _buildTrueFalseSurveySection(survey, enabled: widget.inputEnabled);
    } else if (survey is SurveyQuestionDateTime) {
      _dateTimeTextControllers ??= {survey.key: TextEditingController(text: survey.response?.toString())};
      surveyWidget = _buildDateEntrySurveySection(survey, defaultIconKey: 'calendar', enabled: widget.inputEnabled);
    } else if (survey is SurveyQuestionNumeric) {
      surveyWidget = _buildNumericSurveySection(survey, enabled: widget.inputEnabled);
    } else if (survey is SurveyDataResult) {
      surveyWidget = _buildResultSurveySection(survey);
    } else if (survey is SurveyQuestionText) {
      surveyWidget = _buildTextSurveySection(survey, readOnly: !widget.inputEnabled);
    }
    // else if (survey is SurveyDataPage) {
    //   surveyWidget = _buildPageWidget(survey);
    // }

    return surveyWidget?.widget != null ? Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: textPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Visibility(visible: surveyWidget!.orientation == WidgetOrientation.left, child: surveyWidget.widget!),
              Visibility(visible: !survey.allowSkip, child: Text("* ", semanticsLabel: Localization().getStringEx("widget.survey.label.required.hint", "Required"), style: textStyle ?? Styles().textStyles?.getTextStyle('widget.error.regular.fat'))),
              Visibility(
                visible: !surveyWidget.containsText,
                child: Flexible(
                  child: Text(
                    survey.text,
                    textAlign: TextAlign.start,
                    style: textStyle ?? Styles().textStyles?.getTextStyle('widget.message.medium'),
                  ),
                ),
              ),
              Visibility(visible: surveyWidget.orientation == WidgetOrientation.right, child: surveyWidget.widget!),
            ],
          ),
        ),
        Visibility(
          visible: !surveyWidget.containsMoreInfo && StringUtils.isNotEmpty(survey.moreInfo),
          child: Padding(
            padding: moreInfoPadding,
            child: Text(
              survey.moreInfo ?? '',
              textAlign: TextAlign.start,
              style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            ),
          ),
        ),
        // Container(height: 8),
        Visibility(visible: surveyWidget.orientation == WidgetOrientation.below, child: surveyWidget.widget!),
      ],
    ) : null;
  }

  SurveyDataWidget? _buildResultSurveySection(SurveyDataResult? survey) {
    return SurveyDataWidget(SurveyBuilder.surveyDataResult(context, survey),
        containsText: true, containsMoreInfo: true);
  }

  SurveyDataWidget? _buildTextSurveySection(SurveyQuestionText? survey, {bool readOnly = false}) {
    if (survey == null) return null;

    return SurveyDataWidget(_buildTextFormFieldWidget("Response", readOnly: readOnly, maxLength: survey.maxLength, multipleLines: true,
      initialValue: survey.response, inputType: TextInputType.multiline, textCapitalization: TextCapitalization.sentences, onChanged: (value) {
      survey.response = value;
      _onChangeResponse(false);
    }).widget);
  }

  SurveyDataWidget? _buildMultipleChoiceSurveySection(SurveyQuestionMultipleChoice? survey, {bool enabled = true}) {
    if (survey == null) return null;

    List<OptionData> optionList = survey.options;
    if (survey.allowMultiple) {
      return SurveyDataWidget(_buildMultipleAnswerWidget(optionList, survey, enabled: enabled));
    }
    if (survey.style == 'horizontal') {
      return SurveyDataWidget(_buildHorizontalMultipleChoiceSurveySection(survey, enabled: enabled));
    }

    OptionData? selected;
    for (OptionData data in optionList) {
      if (data.responseValue == survey.response) {
        selected = data;
        break;
      }
    }

    // if (enabled) {
    return SurveyDataWidget(SingleSelectionList(
        selectionList: optionList,
        onChanged: enabled ? (int index) {
          // if (survey.scored && survey.response != null) {
          //   return;
          // }
          survey.response = optionList[index].responseValue;
          _onChangeResponse(true);
        } : null,
        selectedValue: selected));
    // }
    // else {
    //   multipleChoice = CustomIconSelectionList(
    //     optionList: optionList,
    //     selectedValues: selected != null ? [selected.value] : [],
    //     correctAnswers: survey.correctAnswers,
    //     scored: survey.scored,
    //   );
    // }
  }

  Widget _buildMultipleAnswerWidget(List<OptionData> options, SurveyQuestionMultipleChoice survey, {bool enabled = true}) {
    List<dynamic> selectedOptions = [];
    List<bool> isCheckedList = List<bool>.filled(options.length, false);

    for (int i = 0; i < options.length; i++) {
      OptionData data = options[i];
      dynamic response = survey.response;
      if (response is List<dynamic>) {
        if (response.contains(data.responseValue)) {
          isCheckedList[i] = true;
          selectedOptions.add(data.responseValue);
        }
      }
    }

    Widget multipleChoice;
    // if (enabled) {
    multipleChoice = MultiSelectionList(
      selectionList: options,
      isChecked: isCheckedList,
      onChanged: enabled ? (int index) {
        //TODO: Prevent changing initial response when scored
        // if (survey.scored && survey.response != null) {
        //   return;
        // }

        if (!isCheckedList[index]) {
          selectedOptions.add(options[index].responseValue);
        } else {
          selectedOptions.remove(options[index].responseValue);
        }

        if (selectedOptions.isNotEmpty) {
          survey.response = selectedOptions;
        } else {
          survey.response = null;
        }
        _onChangeResponse(false);
      } : null,
    );
    // } else {
    //   multipleChoice = CustomIconSelectionList(
    //     optionList: options,
    //     selectedValues: selectedOptions,
    //     correctAnswers: survey.correctAnswers,
    //     scored: survey.scored,
    //   );
    // }

    return multipleChoice;
  }

  Widget? _buildHorizontalMultipleChoiceSurveySection(SurveyQuestionMultipleChoice? survey, {bool enabled = true}) {
    if (survey == null) return null;

    List<Widget> buttons = [];
    for (OptionData option in survey.options) {
      buttons.add(Flexible(fit: FlexFit.tight, child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: RadioButton<dynamic>(
          semanticsLabel: option.hint ?? option.title,
          value: option.responseValue,
          groupValue: survey.response,
          onChanged: (value) {
            survey.response = value;
            _onChangeResponse(false);
          },
          enabled: enabled,
          textWidget: Text(option.title, style: Styles().textStyles?.getTextStyle('widget.detail.small'), textAlign: TextAlign.center),
          backgroundDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.surface),
          borderDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorPrimaryVariant),
          selectedWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorSecondary)),
          disabledWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.mediumGray)),
        ),
      )));
    }

    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: buttons));
  }

  SurveyDataWidget? _buildTrueFalseSurveySection(SurveyQuestionTrueFalse? survey, {bool enabled = true}) {
    if (survey == null) return null;

    //Widget trueFalse;
    // if (enabled) {
    if (survey.style == 'checkbox') {
      if (survey.response is! bool) {
        survey.response = false;
      }
      return SurveyDataWidget(Checkbox(
        checkColor: Styles().colors?.surface,
        activeColor: Styles().colors?.fillColorPrimary,
        value: survey.response,
        onChanged: enabled ? (bool? value) {
          // if (survey.scored && survey.response != null) {
          //   return;
          // }
          survey.response = value;
          _onChangeResponse(true);
        } : null,
      ), orientation: WidgetOrientation.left);
    }

    if (survey.style == 'toggle') {
      if (survey.response is! bool) {
        survey.response = false;
      }
      return SurveyDataWidget(Switch(
        value: survey.response,
        activeColor: Styles().colors?.fillColorPrimary,
        onChanged: enabled ? (bool value) {
          // if (survey.scored && survey.response != null) {
          //   return;
          // }
          survey.response = value;
          _onChangeResponse(true);
        } : null,
      ), orientation: WidgetOrientation.right);
    }

    List<OptionData> optionList = survey.options;

    OptionData? selected;
    for (OptionData data in optionList) {
      if (data.responseValue == survey.response) {
        selected = data;
        break;
      }
    }

    return SurveyDataWidget(SingleSelectionList(
        selectionList: optionList,
        onChanged: enabled ? (int index) {
          // if (survey.scored && survey.response != null) {
          //   return;
          // }
          survey.response = optionList[index].responseValue;
          _onChangeResponse(true);
        } : null,
        selectedValue: selected
    ));

    // } else {
    //   trueFalse = CustomIconSelectionList(
    //     optionList: optionList,
    //     selectedValues: selected != null ? [selected.value] : [],
    //     correctAnswers: survey.correctAnswer != null ? [survey.correctAnswer] : null,
    //     scored: survey.scored,);
    // }
  }

  SurveyDataWidget? _buildDateEntrySurveySection(SurveyQuestionDateTime? survey, {Widget? calendarIcon, String? defaultIconKey, bool enabled = true}) {
    if (survey == null) return null;

    String format = "MM-dd-yyyy";
    return SurveyDataWidget(Row(
      children: <Widget>[
        Expanded(
          child: FormFieldText('Response', hint: format, readOnly: !enabled, controller: _dateTimeTextControllers![survey.key], inputType: TextInputType.datetime,
            validator: (value) => _validateDate(value, format: format), onChanged: (value) {
              survey.response = value.trim();
              _onChangeResponse(false);
            }
          ),
        ),
        Visibility(
          visible: enabled,
          child: IconButton(
            icon: calendarIcon ?? Styles().images?.getImage(defaultIconKey ?? '') ?? Container(),
            tooltip: "Date picker",
            alignment: Alignment.topCenter,
            splashRadius: 24,
            onPressed: () {
              DateTime initialDate = _getInitialDate(survey.response?.toString() ?? '', format);
              if (survey.startTime != null && initialDate.isBefore(survey.startTime!)) {
                initialDate = survey.startTime!;
              }
              if (survey.endTime != null && initialDate.isAfter(survey.endTime!)) {
                initialDate = survey.endTime!;
              }
              _selectDate(context: context, initialDate: initialDate, firstDate: survey.startTime,
                lastDate: survey.endTime, callback: (DateTime picked) {
                  String date = DateFormat(format).format(picked);
                  survey.response = date;
                  _dateTimeTextControllers![survey.key]!.text = date;
                  _onChangeResponse(false);
                }
              );
            },
          ),
        ),
      ],
    ));
  }

  DateTime _getInitialDate(String current, String format) {
    if (StringUtils.isEmpty(current)) {
      return DateTime.now();
    } else {
      try {
        return DateFormat(format).parse(current);
      } catch (e) {
        return DateTime.now();
      }
    }
  }

  void _selectDate({required BuildContext context, required Function(DateTime) callback, required DateTime initialDate, DateTime? firstDate, DateTime? lastDate}) async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate ?? DateTime(1900), //_dateTimeSurvey!.startTime ,
        lastDate: lastDate ?? DateTime(2025) //_dateTimeSurvey!.endTime );
    );

    if (picked != null) {
      callback(picked);
    }
  }

  String? _validateDate(String? dateStr, {String? format}) {
    format ??= "MM-dd-yyyy";
    if (dateStr != null) {
      if (DateTimeUtils.parseDateTime(dateStr, format: format) == null) {
        return "Invalid format: must be $format";
      }
    }
    return null;
  }

  SurveyDataWidget? _buildNumericSurveySection(SurveyQuestionNumeric? survey, {bool enabled = true}) {
    if (survey == null) return null;

    if (survey.style == 'slider') {
      return _buildSliderSurveySection(survey, enabled: enabled);
    }

    String? initialValue;
    if (survey.response != null) {
      initialValue = survey.response.toString();
    }

    Widget? numericText = _buildTextFormFieldWidget('Response', readOnly: !enabled, initialValue: initialValue, inputType: TextInputType.number, textCapitalization: TextCapitalization.words, onChanged: (value) {
      num? val;
      if (survey.wholeNum) {
        val = int.tryParse(value);
      } else {
        val = double.tryParse(value);
      }

      if (val != null) {
        survey.response = val;
        _onChangeResponse(false);
      }
    }).widget;

    return SurveyDataWidget(numericText);
  }

  SurveyDataWidget? _buildSliderSurveySection(SurveyQuestionNumeric? survey, {bool enabled = true}) {
    if (survey == null) return null;

    double min = survey.minimum ?? 0.0;
    double max = survey.maximum ?? 1.0;
    String label;
    if (survey.wholeNum && min >= 0 && max <= 10) {
      return SurveyDataWidget(_buildDiscreteNumsSurveySection(survey, enabled: enabled));
    }

    double value = 0;
    dynamic response = survey.response;
    if (response is double) {
      value = response;
    } else if (response is int) {
      value = response.toDouble();
    } else if (response == null) {
      survey.response = 0;
    }

    if (survey.wholeNum) {
      label = value.toInt().toString();
    } else {
      label = value.toString();
    }

    return SurveyDataWidget(Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(decoration: BoxDecoration(color: Styles().colors?.surface, borderRadius: BorderRadius.circular(8)),child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Text(label, style: Styles().textStyles?.getTextStyle('headline3')),
        )),
        Expanded(
          child: Slider(value: value, min: min, max: max, label: label, activeColor: Styles().colors?.fillColorPrimary, onChanged: enabled ? (value) {
           survey.response = value;
           _onChangeResponse(false);
          } : null)
        ),
      ],
    ));
  }

  Widget? _buildDiscreteNumsSurveySection(SurveyQuestionNumeric? survey, {bool enabled = true}) {
    if (survey == null) return null;

    int min = survey.minimum?.toInt() ?? 0;
    int max = survey.maximum?.toInt() ?? 10;

    int? value;
    dynamic response = survey.response;
    if (response is int) {
      value = response;
    }

    List<Widget> buttons = [];
    for (int i = min; i <= max; i++) {
      buttons.add(Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
       Text(i.toString(), style: Styles().textStyles?.getTextStyle('label')),
       Radio(value: i, groupValue: value, activeColor: Styles().colors?.fillColorPrimary,
         onChanged: enabled ? (Object? value) {
           survey.response = value;
           _onChangeResponse(false);
         } : null
       )
      ]));
    }

    return Column(
      children: [
        Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: buttons),
        Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: Container(height: 1, color: Styles().colors?.dividerLine),
        )
      ],
    );
  }

  SurveyDataWidget _buildTextFormFieldWidget(String field, {bool readOnly = false, int? maxLength, bool multipleLines = false, String? initialValue, String? hint,
    TextInputType? inputType, Function(String)? onFieldSubmitted, Function(String)? onChanged, String? Function(String?)? validator,
    TextCapitalization textCapitalization= TextCapitalization.none, List<TextInputFormatter>? inputFormatters} ) {
    return SurveyDataWidget(FormFieldText(field, readOnly: readOnly, maxLength: maxLength, multipleLines: multipleLines,
      inputType: inputType, onFieldSubmitted: onFieldSubmitted, onChanged: onChanged, validator: validator, initialValue: initialValue,
      textCapitalization: textCapitalization, hint: hint, inputFormatters: inputFormatters
    ));
  }

  // SurveyDataWidget _buildPageWidget(SurveyDataPage? survey, /*{bool enabled = true}*/) {
  //   return SurveyDataWidget(Container());
  // }

  void _setSurvey(Survey survey) {
    _survey = survey;
    _mainSurveyData = widget.surveyDataKey != null ? survey.data[widget.surveyDataKey] : Surveys().getFirstQuestion(survey);

    Surveys().evaluateDefaultDataResponse(_survey!, _mainSurveyData, defaultResponses: widget.defaultResponses);
    Surveys().evaluate(_survey!);
  }

  void _onTapContinue() {
    // final targetContext = dataKey?.currentContext;
    // if (targetContext != null) {
    //   double startScroll = _scrollController.position.pixels;
    //   await Scrollable.ensureVisible(
    //     targetContext,
    //     duration: const Duration(milliseconds: 400),
    //     curve: Curves.easeInOut,
    //   );
    //   dataKey = null;
    //   double scrollDiff = _scrollController.position.pixels - startScroll;
    //   if (scrollDiff.abs() > 20.0) {
    //     return;
    //   }
    // }

    if (!Surveys().canContinue(_survey!)) {
      AppToast.show("Please answer all required questions to continue");
      return;
    }

    _survey!.dateUpdated = DateTime.now();
    _finishSurvey();
  }

  void _finishSurvey() {
    _setSaving(true);
    widget.controller.beforeComplete?.call();
    Surveys().evaluate(_survey!, evalResultRules: true, summarizeResultRules: widget.summarizeResultRules).then((result) {
      if (result is! SurveyResponse && !widget.summarizeResultRules) {
        result = SurveyResponse('', _survey!, DateTime.now().toUtc(), null);
      }
      widget.controller.onComplete?.call(result);
      _setSaving(false);
      if (widget.summarizeResultRules) {
        _onPreviewContinue(result);
      }
    });
  }

  void _onPreviewContinue(dynamic result) {
    if (widget.summarizeResultRulesWidget != null) {
      showDialog(context: context, builder: (BuildContext context) => widget.summarizeResultRulesWidget!);
    } else if (result is List<RuleAction>) {
      List<InlineSpan> textSpans = [TextSpan(
        text: "These are the actions that would have been taken had a user completed this survey as you did\n\n",
        style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'),
      )];
      for (RuleAction action in result) {
        if (RuleAction.supportedPreviews.contains(action.action)) {
          textSpans.add(TextSpan(
            text: '\u2022 ${RuleAction.supportedActions[action.action]} ',
            style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'),
          ));
          textSpans.add(TextSpan(
            text: action.getSummary().replaceAll('${RuleAction.supportedActions[action.action]!} ', ''),
            style: Styles().textStyles?.getTextStyle('widget.button.title.medium.fat.underline'),
            recognizer: TapGestureRecognizer()..onTap = () => Rules().evaluateAction(_survey!, action, immediate: true),
          ));
          textSpans.add(TextSpan(
            text: '\n',
            style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'),
          ));
        } else {
          textSpans.add(TextSpan(
            text: '\u2022 ${action.getSummary()}\n',
            style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'),
          ));
        }
      }

      PopupMessage.show(context: context,
        title: "Actions",
        messageWidget: Padding(padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8), child: Text.rich(TextSpan(children: textSpans))),
        buttonTitle: Localization().getStringEx("dialog.ok.title", "OK"),
        onTapButton: (context) {
          Navigator.pop(context);
        },
      );
    }
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _loading = loading;
      });
    }
  }

  void _setSaving(bool saving) {
    if (mounted) {
      setState(() {
        widget.controller.saving = saving;
      });
    }
  }
}

enum WidgetOrientation { below, left, right }

class SurveyDataWidget {
  Widget? widget;
  WidgetOrientation orientation;
  bool containsText;
  bool containsMoreInfo;

  SurveyDataWidget(this.widget, {this.orientation = WidgetOrientation.below,
    this.containsText = false, this.containsMoreInfo = false});
}

class CustomIconSelectionList extends StatelessWidget {
  final List<OptionData> optionList;
  final void Function(int)? onChanged;
  final List<dynamic>? selectedValues;
  final List<dynamic>? correctAnswers;
  final bool scored;
  final double iconSize;
  final Widget? unselectedIcon;
  final Widget? selectedIcon;
  final Widget? checkIcon;
  final Widget? incorrectIcon;

  const CustomIconSelectionList({
    Key? key,
    required this.optionList,
    this.onChanged,
    this.selectedValues,
    this.iconSize = 24.0,
    this.correctAnswers,
    this.scored = false,
    this.unselectedIcon,
    this.selectedIcon,
    this.checkIcon,
    this.incorrectIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? correctAnswer;
    bool answerIsWrong = false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
            shrinkWrap: true,
            // physics: const NeverScrollableScrollPhysics(),
            physics: const ScrollPhysics(),
            itemCount: optionList.length,
            itemBuilder: (BuildContext context, int index) {
              OptionData option = optionList[index];
              Widget? optionIcon;
              // IconAsset optionIcon = unselectedIcon!;
              // chosen, correct => check mark
              // chosen, incorrect => cross mark
              // unchosen, correct => check mark
              // unchosen, incorrect => selected mark

              // no correctAnswers: only chosen and unchosen
              bool selected = isOptionSelected(selectedValues, option);
              if (correctAnswers == null || !scored) {
                optionIcon = selected ? selectedIcon : unselectedIcon!;
              } else {
                if (isOptionCorrect(correctAnswers, option)) {
                  optionIcon = checkIcon;
                  if (optionIcon == checkIcon) {
                    correctAnswer = option.title;
                  }
                } else {
                  optionIcon = selected ? incorrectIcon : unselectedIcon;
                  if (optionIcon == incorrectIcon) {
                    answerIsWrong = true;
                  }
                }
              }

              return Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                    child: InkWell(
                      onTap: onChanged != null ? () => onChanged!(index) : null,
                      child: ListTile(
                        title: Transform.translate(offset: const Offset(-15, 0), child: Text(optionList[index].title, style: selected ? Styles().textStyles?.getTextStyle('labelSelected') : Styles().textStyles?.getTextStyle('label'))),
                        leading:
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: optionIcon),
                          ],
                        ),
                        contentPadding: const EdgeInsets.all(8),
                      ),
                    )
                ),
              );
            }),
        Visibility(
          visible: answerIsWrong && correctAnswer != null,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                      "Correct Answer: ",
                      textAlign: TextAlign.start,
                      style: Styles().textStyles?.getTextStyle('headline2')),
                  Text(
                      correctAnswer ?? "",
                      textAlign: TextAlign.start,
                      style: Styles().textStyles?.getTextStyle('body'))
                ],
              ),
        )),
      ]
    );
  }

  bool isOptionCorrect(List<dynamic>? correctAnswers, OptionData option) {
    if (correctAnswers == null) return true;

    return correctAnswers.contains(option.responseValue);
  }

  bool isOptionSelected(List<dynamic>? selectedValues, OptionData option) {
    if (selectedValues == null || selectedValues.isEmpty) return false;

    // return selectedValues!.contains(answer);
    for (int i = 0; i < selectedValues.length; i++) {
      if (selectedValues[i] == option.responseValue) return true;
    }

    return false;
  }
}

class SingleSelectionList extends StatelessWidget {
  final List<OptionData> selectionList;
  final void Function(int)? onChanged;
  final OptionData? selectedValue;

  const SingleSelectionList({
    Key? key,
    required this.selectionList,
    this.onChanged,
    this.selectedValue
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: selectionList.length,
        itemBuilder: (BuildContext context, int index) {
          String title = selectionList[index].title;
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Card(
                clipBehavior: Clip.hardEdge,
                child: RadioListTile(
                  title: Transform.translate(offset: const Offset(-15, 0), child: Text(title, style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.headlineText))),
                  activeColor: Styles().colors?.fillColorSecondary,
                  value: title,
                  groupValue: selectedValue?.title,
                  onChanged: onChanged != null ? (_) => onChanged!(index) : null,
                  contentPadding: const EdgeInsets.all(8),
                )
              ));
        });
  }
}

class MultiSelectionList extends StatelessWidget {
  final List<OptionData> selectionList;
  final List<bool>? isChecked;
  final void Function(int)? onChanged;

  const MultiSelectionList({
    Key? key,
    required this.selectionList,
    this.onChanged,
    this.isChecked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: selectionList.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Card(
                  child: InkWell(
                    onTap: onChanged != null ? () => onChanged!(index) : null,
                    child: CheckboxListTile(
                      title: Transform.translate(offset: const Offset(-15, 0), child: Text(selectionList[index].title, style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.headlineText))),
                      checkColor: Colors.white,
                      activeColor: Styles().colors?.fillColorSecondary,
                      value: isChecked?[index],
                      onChanged: onChanged != null ? (_) => onChanged!(index) : null,
                      contentPadding: const EdgeInsets.all(8),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  )
              ));
        });
  }
}
