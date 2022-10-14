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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/quiz_question_panel.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/utils/widget_utils.dart';

class QuizWidgets {
  BuildContext context;
  Function(bool) onChangeQuizResponse;

  QuizWidgets(this.context, this.onChangeQuizResponse);

  Widget? buildInlineQuizWidget(QuizData quiz, {TextStyle? textStyle, Function(dynamic)? onComplete}) {
    Widget? widget;

    if (quiz is QuizQuestionMultipleChoice) {
      widget = buildMultipleChoiceQuizSection(quiz);
    } else if (quiz is QuizQuestionTrueFalse) {
      widget = buildTrueFalseQuizSection(quiz);
    } else if (quiz is QuizQuestionDateTime) {
      widget = buildDateEntryQuizSection(quiz);
    } else if (quiz is QuizQuestionNumeric) {
      widget = buildNumericQuizSection(quiz);
    } else if (quiz is QuizDataResponse) {
      widget = buildResponseQuizSection(quiz);
    } else if (quiz is QuizQuestionText) {
      widget = buildTextQuizSection(quiz);
    } else if (quiz is QuizDataQuiz) {
      widget = buildQuizQuizSection(quiz, onComplete: onComplete);
    }

    return widget != null ? Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(visible: !quiz.allowSkip, child: Text("* ", style: Styles().uiStyles?.alert)),
              Flexible(
                child: Text(
                  quiz.text,
                  textAlign: TextAlign.start,
                  style: textStyle ?? Styles().uiStyles?.headline2,
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: StringUtils.isNotEmpty(quiz.moreInfo),
          child: Padding(
            padding: const EdgeInsets.only(left: 32, right: 32, top: 8),
            child: Text(
              quiz.moreInfo ?? '',
              textAlign: TextAlign.start,
              style: Styles().uiStyles?.body,
            ),
          ),
        ),
        Container(height: 8),
        widget,
        Container(height: 36),
      ],
    ) : null;
    // return widget;
  }

  Widget? buildResponseQuizSection(QuizDataResponse? quiz) {
    if (quiz == null) return null;
    ButtonAction? buttonAction = AppWidgets.actionTypeButtonAction(context, quiz.action);

    return Column(
      children: <Widget>[
        Text(quiz.body ?? "", style: Styles().uiStyles?.body),
        quiz.action != null && buttonAction != null ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: RoundedButton(label: buttonAction.title, borderColor: Styles().colors?.fillColorPrimary,
              backgroundColor: Styles().colors?.surface, textColor: Styles().colors?.headlineText, onTap: () => buttonAction.action)
        ) : Container(),
      ],
    );
  }

  Widget? buildTextQuizSection(QuizQuestionText? quiz, {bool readOnly = false}) {
    if (quiz == null) return null;

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: _buildTextFormFieldWidget("Response", readOnly: readOnly, multipleLines: true, initialValue: quiz.response, inputType: TextInputType.multiline, textCapitalization: TextCapitalization.sentences, onChanged: (value) {
          quiz.response = value;
          onChangeQuizResponse(false);
        }));
  }

  Widget? buildMultipleChoiceQuizSection(QuizQuestionMultipleChoice? quiz, {bool isSummaryWidget = false}) {
    if (quiz == null) return null;

    List<OptionData> optionList = quiz.options;
    if (quiz.allowMultiple) {
      return buildMultipleAnswerWidget(optionList, quiz, isSummaryWidget: isSummaryWidget);
    }

    OptionData? selected;
    for (OptionData data in optionList) {
      if (data.value == quiz.response) {
        selected = data;
        break;
      }
    }

    late Widget widget;
    if (isSummaryWidget) {
      widget = CustomIconSelectionList(
        optionList: optionList,
        selectedValues: selected != null ? [selected.value] : [],
        okAnswers: quiz.okAnswers,
        scored: quiz.scored,
      );
    } else {
      widget = OnboardingSingleSelectionList(
        selectionList: optionList,
        onChanged: (int index) {
          if (quiz.scored && quiz.response != null) {
            return;
          }
          quiz.response = optionList[index].value;
          onChangeQuizResponse(true);
        },
        selectedValue: selected);
    }

    return widget;
  }

  Widget buildMultipleAnswerWidget(List<OptionData> options, QuizQuestionMultipleChoice quiz, {bool isSummaryWidget = false}) {
    List<dynamic> selectedOptions = [];
    List<bool> isCheckedList = List<bool>.filled(options.length, false);

    for (int i = 0; i < options.length; i++) {
      OptionData data = options[i];
      dynamic response = quiz.response;
      if (response is List<dynamic>) {
        if (response.contains(data.value)) {
          isCheckedList[i] = true;
          selectedOptions.add(data.value);
        }
      }
    }

    late Widget widget;
    if (isSummaryWidget) {
      widget = CustomIconSelectionList(
        optionList: options,
        selectedValues: selectedOptions,
        okAnswers: quiz.okAnswers,
        scored: quiz.scored,
      );
    } else {
      widget = OnboardingMultiSelectionList(
        selectionList: options,
        isChecked: isCheckedList,
        onChanged: (int index) {
          //TODO: Prevent changing initial response when scored
          // if (quiz.scored && quiz.response != null) {
          //   return;
          // }

          if (!isCheckedList[index]) {
            selectedOptions.add(options[index].value);
          } else {
            selectedOptions.remove(options[index].value);
          }

          if (selectedOptions.isNotEmpty) {
            quiz.response = selectedOptions;
          } else {
            quiz.response = null;
          }
          onChangeQuizResponse(false);
        },
      );
    }

    return widget;
  }

  Widget? buildTrueFalseQuizSection(QuizQuestionTrueFalse? quiz, {bool isSummaryWidget = false}) {
    if (quiz == null) return null;

    List<OptionData> optionList = quiz.options;

    OptionData? selected;
    for (OptionData data in optionList) {
      if (data.value == quiz.response) {
        selected = data;
        break;
      }
    }

    late Widget widget;
    if (isSummaryWidget) {
      widget = CustomIconSelectionList(
        optionList: optionList,
        selectedValues: selected != null ? [selected.value] : [],
        okAnswers: quiz.okAnswer != null ? [quiz.okAnswer] : null,
        scored: quiz.scored,);
    } else {
      widget = OnboardingSingleSelectionList(
          selectionList: optionList,
          onChanged: (int index) {
            if (quiz.scored && quiz.response != null) {
              return;
            }
            quiz.response = optionList[index].value;
            onChangeQuizResponse(true);
          },
          selectedValue: selected
      );
    }

    return widget;
  }

  Widget? buildDateEntryQuizSection(QuizQuestionDateTime? quiz, {Widget? calendarIcon, String? defaultIconKey, bool enabled = true}) {
    if (quiz == null) return null;

    String? title = quiz.text;

    TextEditingController dateTextController = TextEditingController(text: quiz.response);

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
                onChangeQuizResponse(false);
              },
              onChanged: (value) {
                int select = dateTextController.value.selection.start;
                dateTextController.value = TextEditingValue(
                  text: value,
                  selection: TextSelection.fromPosition(
                    TextPosition(offset: select),
                  ),
                );
                quiz.response = value.trim();
              },
              onEditingComplete: onChangeQuizResponse(false),
              // maxLength: 10,
              onSaved: (value) => onChangeQuizResponse(false),
            ),
          ),
          Visibility(
            visible: enabled,
            child: IconButton(
              icon: calendarIcon ?? Styles().uiImages?.getImage(defaultIconKey ?? '') ?? Container(),
              tooltip: "Test hint",
              onPressed: () => _selectDate(context: context, initialDate: _getInitialDate(dateTextController.text, format),
                  firstDate: quiz.startTime, lastDate: quiz.endTime, callback: (DateTime picked) {
                    String date = DateFormat(format).format(picked);
                    dateTextController.text = date;
                    quiz.response = date;
                    onChangeQuizResponse(false);
                    // _formResults[currentKey] = DateFormat('MM-dd-yyyy').format(picked);
                  }),
            ),
          ),
        ],
      ),
    );
  }

  static DateTime _getInitialDate(String current, String format) {
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

  static void _selectDate({required BuildContext context, required Function(DateTime) callback, required DateTime initialDate, DateTime? firstDate, DateTime? lastDate}) async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate ?? DateTime(1900), //_dateTimeQuiz!.startTime ,
        lastDate: lastDate ?? DateTime(2025) //_dateTimeQuiz!.endTime );
    );

    if (picked != null) {
      callback(picked);
    }
  }

  Widget? buildNumericQuizSection(QuizQuestionNumeric? quiz, {bool readOnly = false}) {
    if (quiz == null) return null;

    if (quiz.slider) {
      return buildSliderQuizSection(quiz, readOnly: readOnly);
    }

    String? initialValue;
    if (quiz.response != null) {
      initialValue = quiz.response.toString();
    }

    Widget widget = _buildTextFormFieldWidget(quiz.text, readOnly: readOnly, initialValue: initialValue, inputType: TextInputType.number, textCapitalization: TextCapitalization.words, onChanged: (value) {
      num val;
      if (quiz.wholeNum) {
        val = int.parse(value);
      } else {
        val = double.parse(value);
      }
      quiz.response = val;
      onChangeQuizResponse(false);
    });

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: widget);
  }

  Widget? buildSliderQuizSection(QuizQuestionNumeric? quiz, {bool readOnly = false}) {
    if (quiz == null) return null;

    double min = quiz.minimum ?? 0.0;
    double max = quiz.maximum ?? 1.0;
    String label;
    if (quiz.wholeNum && min >= 0 && max <= 10) {
      return buildDiscreteNumsQuizSection(quiz, readOnly: readOnly);
    }

    double value = 0;
    dynamic response = quiz.response;
    if (response is double) {
      value = response;
    } else if (response is int) {
      value = response.toDouble();
    } else if (response == null) {
      quiz.response = 0;
    }

    if (quiz.wholeNum) {
      label = value.toInt().toString();
    } else {
      label = value.toString();
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(decoration: BoxDecoration(color: Styles().colors?.surface, borderRadius: BorderRadius.circular(8)),child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Text(label, style: Styles().uiStyles?.headline3),
        )),
        Expanded(
          child: Slider(value: value, min: min, max: max, label: label, activeColor: Styles().colors?.fillColorPrimary, onChanged: !readOnly ? (value) {
           quiz.response = value;
           onChangeQuizResponse(false);
          } : null)
        ),
      ],
    );
  }

  Widget? buildDiscreteNumsQuizSection(QuizQuestionNumeric? quiz, {bool readOnly = false}) {
    if (quiz == null) return null;

    int min = quiz.minimum?.toInt() ?? 0;
    int max = quiz.maximum?.toInt() ?? 10;

    int? value;
    dynamic response = quiz.response;
    if (response is int) {
      value = response;
    }

    List<Widget> buttons = [];
    for (int i = min; i <= max; i++) {
      buttons.add(Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
       Text(i.toString(), style: Styles().uiStyles?.label),
       Radio(value: i, groupValue: value, activeColor: Styles().colors?.fillColorPrimary,
         onChanged: readOnly ? null : (Object? value) {
           quiz.response = value;
           onChangeQuizResponse(false);
         }
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

  Widget? buildQuizQuizSection(QuizDataQuiz? quiz, {Function(dynamic)? onComplete}) {
    if (quiz == null) return null;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: RoundedButton(
          label: Localization().getStringEx("panel.home.button.action.take_quiz.title", "Take Quiz"),
          borderColor: Styles().colors?.fillColorPrimary,
          backgroundColor: Styles().colors?.surface,
          textColor: Styles().colors?.headlineText,
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => QuizQuestionPanel(quiz: quiz.quiz, onComplete: () {
              if (onComplete != null) {
                quiz.quiz.evaluate(plan, QuizEvent(quiz: quiz.quiz, date: DateTime.now()));
                onComplete(quiz.quiz.resultData);
              }
            })));
          }
        ),
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
}

class CustomIconSelectionList extends StatelessWidget {
  final List<OptionData> optionList;
  final void Function(int)? onChanged;
  final List<dynamic>? selectedValues;
  final List<dynamic>? okAnswers;
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
    this.okAnswers,
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
              late Widget optionIcon;
              // IconAsset optionIcon = unselectedIcon!;
              // chosen, correct => check mark
              // chosen, incorrect => cross mark
              // unchosen, correct => check mark
              // unchosen, incorrect => selected mark

              // no okAnswers: only chosen and unchosen
              bool selected = isOptionSelected(selectedValues, option);
              if (okAnswers == null || !scored) {
                optionIcon = selected ? selectedIcon! : unselectedIcon!;
              } else {
                if (isOptionCorrect(okAnswers, option)) {
                  optionIcon = checkIcon!;
                  if (optionIcon == checkIcon) {
                    correctAnswer = option.title;
                  }
                } else {
                  optionIcon = selected ? incorrectIcon! : unselectedIcon!;
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
                        title: Transform.translate(offset: const Offset(-15, 0), child: Text(optionList[index].title, style: selected ? Styles().uiStyles?.labelSelected : Styles().uiStyles?.label)),
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
                      style: Styles().uiStyles?.headline2),
                  Text(
                      correctAnswer ?? "",
                      textAlign: TextAlign.start,
                      style: Styles().uiStyles?.body)
                ],
              ),
        )),
      ]
    );
  }

  bool isOptionCorrect(List<dynamic>? okAnswers, OptionData option) {
    if (okAnswers == null) return true;

    return okAnswers.contains(option.value);
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