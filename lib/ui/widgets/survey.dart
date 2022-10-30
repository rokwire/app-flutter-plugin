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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/options.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widget_builders/survey.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyWidget extends StatefulWidget {
  final dynamic survey;
  final String? surveyDataKey;
  final bool inputEnabled;
  final DateTime? dateTaken;
  final bool showResult;
  final Function(bool) onChangeSurveyResponse;
  final Function? onComplete;
  final Function(Survey?)? onLoad;

  SurveyWidget({required this.survey, required this.onChangeSurveyResponse,
    this.inputEnabled = true, this.dateTaken, this.showResult = false, this.surveyDataKey,
    this.onComplete, this.onLoad});

  @override
  State<SurveyWidget> createState() => _SurveyWidgetState();
}

class _SurveyWidgetState extends State<SurveyWidget> {
  bool _loading = false;
  Survey? _survey;
  SurveyData? _mainSurveyData;

  @override
  void initState() {
    super.initState();

    if (widget.survey is Survey) {
      _survey = widget.survey;
      _mainSurveyData = widget.surveyDataKey != null ? _survey?.data[widget.surveyDataKey] : _survey?.firstQuestion;
      _mainSurveyData?.evaluateDefaultResponse(_survey!);
    } else if (widget.survey is String) {
      _setLoading(true);
      Polls().loadSurvey(widget.survey).then((survey) {
        if (survey != null) {
          _survey = survey;
          _mainSurveyData = widget.surveyDataKey != null ? _survey?.data[widget.surveyDataKey] : _survey?.firstQuestion;
          _mainSurveyData?.evaluateDefaultResponse(_survey!);
          if (widget.onLoad != null) {
            widget.onLoad!(survey);
          }
        }
        if (mounted) {
          _setLoading(false);
        }
      });
    }
  }

  @override
  void dispose() {
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
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Visibility(visible: widget.dateTaken != null, child: _buildDateTaken()),
            Visibility(visible: _survey?.moreInfo != null, child: _buildMoreInfo()),
            _buildContent(),
            Visibility(visible: widget.showResult, child: _buildResult() ?? Container()),
            Visibility(visible: widget.inputEnabled, child: _buildContinueButton()),
        ]),
      ) : Container();
  }

  Widget _buildDateTaken() {
    DateTime? dateTaken = widget.dateTaken;
    if (dateTaken == null) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(DateTimeUtils.getDisplayDateTime(dateTaken), style: Styles().textStyles?.getTextStyle('widget.detail.regular'),),
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
    Widget? questionWidget = _buildInlineSurveyWidget(_mainSurveyData!);
    List<Widget> followUps = [];
    //TODO: use replace flag
    for (SurveyData? data = _mainSurveyData!.followUp(_survey!); data != null; data = data.followUp(_survey!)) {
      Widget? followUp = _buildInlineSurveyWidget(data);
      if (followUp != null) {
        // GlobalKey? key;
        // if (data.response == null) {
        //   key = GlobalKey();
        //   dataKey = key;
        // }
        followUps.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: followUp));
      }
    }

    return Column(children: [
      questionWidget ?? Container(),
      Wrap(children: followUps),
    ]);
  }

  Widget? _buildInlineSurveyWidget(SurveyData survey, {TextStyle? textStyle, EdgeInsets textPadding = const EdgeInsets.only(bottom: 8),
    EdgeInsets moreInfoPadding = const EdgeInsets.only(left: 32, right: 32, top: 8)}) {
    Widget? surveyWidget;

    if (survey is SurveyQuestionMultipleChoice) {
      surveyWidget = _buildMultipleChoiceSurveySection(survey, enabled: widget.inputEnabled);
    } else if (survey is SurveyQuestionTrueFalse) {
      surveyWidget = _buildTrueFalseSurveySection(survey, enabled: widget.inputEnabled);
    } else if (survey is SurveyQuestionDateTime) {
      surveyWidget = _buildDateEntrySurveySection(survey, enabled: widget.inputEnabled);
    } else if (survey is SurveyQuestionNumeric) {
      surveyWidget = _buildNumericSurveySection(survey, enabled: widget.inputEnabled);
    } else if (survey is SurveyDataResult) {
      surveyWidget = _buildResultSurveySection(survey);
    } else if (survey is SurveyQuestionText) {
      surveyWidget = _buildTextSurveySection(survey);
    }

    return surveyWidget != null ? Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: textPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(visible: !survey.allowSkip, child: Text("* ", style: textStyle ?? Styles().textStyles?.getTextStyle('widget.error.regular.fat'))),
              Flexible(
                child: Text(
                  survey.text,
                  textAlign: TextAlign.start,
                  style: textStyle ?? Styles().textStyles?.getTextStyle('widget.message.medium'),
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: StringUtils.isNotEmpty(survey.moreInfo),
          child: Padding(
            padding: moreInfoPadding,
            child: Text(
              survey.moreInfo ?? '',
              textAlign: TextAlign.start,
              style: Styles().textStyles?.getTextStyle('body'),
            ),
          ),
        ),
        // Container(height: 8),
        surveyWidget,
        Container(height: 24),
      ],
    ) : null;
  }

  Widget? _buildResultSurveySection(SurveyDataResult? survey) {
    return SurveyBuilder.surveyDataResult(context, survey);
  }

  Widget? _buildTextSurveySection(SurveyQuestionText? survey, {bool readOnly = false}) {
    if (survey == null) return null;

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: _buildTextFormFieldWidget("Response", readOnly: readOnly, multipleLines: true, initialValue: survey.response, inputType: TextInputType.multiline, textCapitalization: TextCapitalization.sentences, onChanged: (value) {
          survey.response = value;
          widget.onChangeSurveyResponse(false);
        }));
  }

  Widget? _buildMultipleChoiceSurveySection(SurveyQuestionMultipleChoice? survey, {bool enabled = true}) {
    if (survey == null) return null;

    List<OptionData> optionList = survey.options;
    if (survey.allowMultiple) {
      return _buildMultipleAnswerWidget(optionList, survey, enabled: enabled);
    }

    OptionData? selected;
    for (OptionData data in optionList) {
      if (data.value == survey.response) {
        selected = data;
        break;
      }
    }

    Widget multipleChoice;
    // if (enabled) {
    multipleChoice = SingleSelectionList(
        selectionList: optionList,
        onChanged: enabled ? (int index) {
          // if (survey.scored && survey.response != null) {
          //   return;
          // }
          survey.response = optionList[index].value;
          widget.onChangeSurveyResponse(true);
        } : null,
        selectedValue: selected);
    // }
    // else {
    //   multipleChoice = CustomIconSelectionList(
    //     optionList: optionList,
    //     selectedValues: selected != null ? [selected.value] : [],
    //     correctAnswers: survey.correctAnswers,
    //     scored: survey.scored,
    //   );
    // }

    return multipleChoice;
  }

  Widget _buildMultipleAnswerWidget(List<OptionData> options, SurveyQuestionMultipleChoice survey, {bool enabled = true}) {
    List<dynamic> selectedOptions = [];
    List<bool> isCheckedList = List<bool>.filled(options.length, false);

    for (int i = 0; i < options.length; i++) {
      OptionData data = options[i];
      dynamic response = survey.response;
      if (response is List<dynamic>) {
        if (response.contains(data.value)) {
          isCheckedList[i] = true;
          selectedOptions.add(data.value);
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
          selectedOptions.add(options[index].value);
        } else {
          selectedOptions.remove(options[index].value);
        }

        if (selectedOptions.isNotEmpty) {
          survey.response = selectedOptions;
        } else {
          survey.response = null;
        }
        widget.onChangeSurveyResponse(false);
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

  Widget? _buildTrueFalseSurveySection(SurveyQuestionTrueFalse? survey, {bool enabled = true}) {
    if (survey == null) return null;

    List<OptionData> optionList = survey.options;

    OptionData? selected;
    for (OptionData data in optionList) {
      if (data.value == survey.response) {
        selected = data;
        break;
      }
    }

    Widget trueFalse;
    // if (enabled) {
    trueFalse = SingleSelectionList(
        selectionList: optionList,
        onChanged: enabled ? (int index) {
          if (survey.scored && survey.response != null) {
            return;
          }
          survey.response = optionList[index].value;
          widget.onChangeSurveyResponse(true);
        } : null,
        selectedValue: selected
    );
    // } else {
    //   trueFalse = CustomIconSelectionList(
    //     optionList: optionList,
    //     selectedValues: selected != null ? [selected.value] : [],
    //     correctAnswers: survey.correctAnswer != null ? [survey.correctAnswer] : null,
    //     scored: survey.scored,);
    // }

    return trueFalse;
  }

  Widget? _buildDateEntrySurveySection(SurveyQuestionDateTime? survey, {Widget? calendarIcon, String? defaultIconKey, bool enabled = true}) {
    if (survey == null) return null;

    String? title = survey.text;

    TextEditingController dateTextController = TextEditingController(text: survey.response);

    String format = "MM-dd-yyyy";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextFormField(
              style: const TextStyle(
                fontSize: 16.0,
                height: 1.0,
              ),
              maxLines: 1,
              keyboardType: TextInputType.datetime,
              autofocus: false,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              enabled: enabled,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(24.0),
                labelText: title,
                hintText: "MM-dd-yyyy",
                filled: true,
                fillColor: !enabled ? Styles().colors?.disabledTextColor : Colors.white,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Colors.white)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(width: 2, color: Styles().colors?.fillColorPrimary ?? Colors.white)),
              ),
              controller: dateTextController,
              // validator: _validationFunctions[field.key],
              onFieldSubmitted: (value) {
                widget.onChangeSurveyResponse(false);
              },
              onChanged: (value) {
                int select = dateTextController.value.selection.start;
                dateTextController.value = TextEditingValue(
                  text: value,
                  selection: TextSelection.fromPosition(
                    TextPosition(offset: select),
                  ),
                );
                survey.response = value.trim();
              },
              onEditingComplete: widget.onChangeSurveyResponse(false),
              // maxLength: 10,
              onSaved: (value) => widget.onChangeSurveyResponse(false),
            ),
          ),
          Visibility(
            visible: enabled,
            child: IconButton(
              icon: calendarIcon ?? Styles().images?.getImage(defaultIconKey ?? '') ?? Container(),
              tooltip: "Test hint",
              onPressed: () => _selectDate(context: context, initialDate: _getInitialDate(dateTextController.text, format),
                  firstDate: survey.startTime, lastDate: survey.endTime, callback: (DateTime picked) {
                    String date = DateFormat(format).format(picked);
                    dateTextController.text = date;
                    survey.response = date;
                    widget.onChangeSurveyResponse(false);
                    // _formResults[currentKey] = DateFormat('MM-dd-yyyy').format(picked);
                  }),
            ),
          ),
        ],
      ),
    );
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

  Widget? _buildNumericSurveySection(SurveyQuestionNumeric? survey, {bool enabled = true}) {
    if (survey == null) return null;

    if (survey.slider) {
      return _buildSliderSurveySection(survey, enabled: enabled);
    }

    String? initialValue;
    if (survey.response != null) {
      initialValue = survey.response.toString();
    }

    Widget numericText = _buildTextFormFieldWidget(survey.text, readOnly: enabled, initialValue: initialValue, inputType: TextInputType.number, textCapitalization: TextCapitalization.words, onChanged: (value) {
      num val;
      if (survey.wholeNum) {
        val = int.parse(value);
      } else {
        val = double.parse(value);
      }
      survey.response = val;
      widget.onChangeSurveyResponse(false);
    });

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: numericText);
  }

  Widget? _buildSliderSurveySection(SurveyQuestionNumeric? survey, {bool enabled = true}) {
    if (survey == null) return null;

    double min = survey.minimum ?? 0.0;
    double max = survey.maximum ?? 1.0;
    String label;
    if (survey.wholeNum && min >= 0 && max <= 10) {
      return _buildDiscreteNumsSurveySection(survey, enabled: enabled);
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

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(decoration: BoxDecoration(color: Styles().colors?.surface, borderRadius: BorderRadius.circular(8)),child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Text(label, style: Styles().textStyles?.getTextStyle('headline3')),
        )),
        Expanded(
          child: Slider(value: value, min: min, max: max, label: label, activeColor: Styles().colors?.fillColorPrimary, onChanged: enabled ? (value) {
           survey.response = value;
           widget.onChangeSurveyResponse(false);
          } : null)
        ),
      ],
    );
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
           widget.onChangeSurveyResponse(false);
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

  Widget _buildTextFormFieldWidget(String field, {bool readOnly = false, bool multipleLines = false, String? initialValue, String? hint, TextInputType? inputType, Function(String)? onFieldSubmitted, Function(String)? onChanged, String? Function(String?)? validator, TextCapitalization textCapitalization= TextCapitalization.none, List<TextInputFormatter>? inputFormatters} ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Semantics(
          label: field,
          child: FormFieldText(field, readOnly: readOnly, multipleLines: multipleLines, inputType: inputType, onFieldSubmitted: onFieldSubmitted, onChanged: onChanged, validator: validator, initialValue: initialValue, textCapitalization: textCapitalization, hint: hint, inputFormatters: inputFormatters)
      ),
    );
  }

  Widget _buildContinueButton() {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
      RoundedButton(label: Localization().getStringEx("widget.survey.button.action.continue.title", "Continue"), onTap: _onTapContinue, progress: null),
    ]);
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

    if (!_survey!.canContinue()) {
      AppToast.show("Please answer all required questions to continue");
      return;
    }

    // show survey summary or return to home page on finishing events
    // SurveyData? followUp = _mainSurveyQuestion?.followUp(_survey);
    // if (followUp == null) {
    _survey!.dateUpdated = DateTime.now();

      // if (widget.showSummaryOnFinish) {
      // } else {
    _finishSurvey();
      // }

      // return;
    // }

    // Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: _survey, currentSurveyKey: followUp.key, showSummaryOnFinish: widget.showSummaryOnFinish, onComplete: widget.onComplete, initPanelDepth: widget.initPanelDepth + 1,)));
  }

  void _finishSurvey() {
    _survey?.evaluate(evalResultRules: true);
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  void _setLoading(bool loading) {
    setState(() {
      _loading = loading;
    });
  }
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

    return correctAnswers.contains(option.value);
  }

  bool isOptionSelected(List<dynamic>? selectedValues, OptionData option) {
    if (selectedValues == null || selectedValues.isEmpty) return false;

    // return selectedValues!.contains(answer);
    for (int i = 0; i < selectedValues.length; i++) {
      if (selectedValues[i] == option.value) return true;
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
        padding: EdgeInsets.only(top: 8),
        itemCount: selectionList.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Card(
                  child: InkWell(
                    onTap: onChanged != null ? () => onChanged!(index) : null,
                    child: ListTile(
                      title: Transform.translate(offset: const Offset(-15, 0), child: Text(selectionList[index].title, style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.headlineText))),
                      leading: Radio<String>(
                        activeColor: Styles().colors?.fillColorSecondary,
                        value: selectionList[index].title,
                        groupValue: selectedValue != null ? selectedValue!.title : null,
                        onChanged: onChanged != null ? (_) => onChanged!(index) : null,
                      ),
                      contentPadding: const EdgeInsets.all(8),
                    ),
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
                    child: ListTile(
                      title: Transform.translate(offset: const Offset(-15, 0), child: Text(selectionList[index].title, style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.headlineText))),
                      leading: Checkbox(
                        checkColor: Colors.white,
                        activeColor: Styles().colors?.fillColorSecondary,
                        value: isChecked?[index],
                        onChanged: onChanged != null ? (_) => onChanged!(index) : null,
                      ),
                      contentPadding: const EdgeInsets.all(8),
                    ),
                  )
              ));
        });
  }
}