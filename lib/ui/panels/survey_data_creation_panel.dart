/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/model/options.dart';
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/rule_element_creation_panel.dart';
import 'package:rokwire_plugin/ui/panels/survey_data_options_panel.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widget_builders/buttons.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/survey_creation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyDataCreationPanel extends StatefulWidget {
  final SurveyData data;
  final List<String> dataKeys;
  final List<String> dataTypes;
  final Widget? tabBar;
  final List<String> sections;
  final bool scoredSurvey;
  final bool mayChangeType;

  const SurveyDataCreationPanel({Key? key, required this.data, required this.dataKeys, required this.dataTypes, required this.sections, required this.scoredSurvey,
    this.mayChangeType = true, this.tabBar}) : super(key: key);

  @override
  _SurveyDataCreationPanelState createState() => _SurveyDataCreationPanelState();
}

class _SurveyDataCreationPanelState extends State<SurveyDataCreationPanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  late final Map<String, TextEditingController> _textControllers;
  final List<String> _defaultTextControllers = ["key", "text", "more_info"];

  late SurveyData _data;

  @override
  void initState() {
    _data = widget.data;

    _textControllers = {
      "key": TextEditingController(text: _data.key),
      "text": TextEditingController(text: _data.text),
      "more_info": TextEditingController(text: _data.moreInfo),
    };

    if (CollectionUtils.isNotEmpty(_data.sections)) {
      List<String> validSections = [];
      for (String section in _data.sections!) {
        if (widget.sections.contains(section)) {
          validSections.add(section);
        }
      }
      _data.sections = validSections;
    } else if (_data.section != null && !widget.sections.contains(_data.section)) {
      _data.section = null;
    }

    _data.defaultResponseRule?.updateSupportedOption('return', 'set_to');
    _data.scoreRule?.updateSupportedOption('return', 'set_to');

    super.initState();
  }

  @override
  void dispose() {
    _removeTextControllers();
    super.dispose();
  }

  void _removeTextControllers({bool keepDefaults = false}) {
    List<String> removedControllers = [];
    _textControllers.forEach((key, value) {
      if (!keepDefaults || !_defaultTextControllers.contains(key)) {
        value.dispose();
        removedControllers.add(key);
      }
    });

    for (String removed in removedControllers) {
      _textControllers.remove(removed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderBar(title: "Edit Survey Data"),
      bottomNavigationBar: widget.tabBar,
      backgroundColor: Styles().colors.background,
      body: SurveyElementCreationWidget(body: _buildSurveyDataComponents(), completionOptions: _buildDone(), scrollController: _scrollController,),
    );
  }

  Widget _buildSurveyDataComponents() {
    List<Widget> dataContent = [];
    if (_data is SurveyQuestionTrueFalse) {
      // style
      String styleVal = (_data as SurveyQuestionTrueFalse).style ?? SurveyQuestionTrueFalse.supportedStyles.entries.first.key;
      dataContent.add(SurveyElementCreationWidget.buildDropdownWidget<String>(SurveyQuestionTrueFalse.supportedStyles, "Style", styleVal, _onChangeStyle));

      // correct answer (dropdown: Yes/True, No/False, null)
      bool yesNo = (_data as SurveyQuestionTrueFalse).style == "yes_no";
      Map<bool?, String> supportedAnswers = {null: "None", true: yesNo ? "Yes" : "True", false: yesNo ? "No" : "False"};
      dataContent.add(SurveyElementCreationWidget.buildDropdownWidget<bool?>(supportedAnswers, "Correct Answer", (_data as SurveyQuestionTrueFalse).correctAnswer, _onChangeCorrectAnswer));
    } else if (_data is SurveyQuestionMultipleChoice) {
      // style
      String styleVal = (_data as SurveyQuestionMultipleChoice).style ?? SurveyQuestionMultipleChoice.supportedStyles.entries.first.key;
      dataContent.add(SurveyElementCreationWidget.buildDropdownWidget<String>(SurveyQuestionMultipleChoice.supportedStyles, "Style", styleVal, _onChangeStyle));

      // options
      List<OptionData> options = (_data as SurveyQuestionMultipleChoice).options;
      dataContent.add(Padding(padding: const EdgeInsets.only(top: 16.0), child: SurveyElementList(
        type: SurveyElementListType.options,
        label: 'Options (${options.length})',
        dataList: options,
        surveyElement: SurveyElement.questionData,
        onAdd: _onTapAdd,
        onEdit: _onTapEdit,
        onRemove: _onTapRemove,
        onDrag: _onAcceptDataDrag,
      )));
      
      // allowMultiple
      dataContent.add(SurveyElementCreationWidget.buildCheckboxWidget("Multiple Answers", (_data as SurveyQuestionMultipleChoice).allowMultiple, _onToggleMultipleAnswers));
      
      // selfScore
      if (_data.scoreRule == null) {
        dataContent.add(SurveyElementCreationWidget.buildCheckboxWidget("Self-Score", (_data as SurveyQuestionMultipleChoice).selfScore, _onToggleSelfScore));
      }
    } else if (_data is SurveyQuestionDateTime) {
      String format = "MM-dd-yyyy";
      _textControllers["start_time"] ??= TextEditingController(text: DateTimeUtils.localDateTimeToString((_data as SurveyQuestionDateTime).startTime, format: format));
      _textControllers["end_time"] ??= TextEditingController(text: DateTimeUtils.localDateTimeToString((_data as SurveyQuestionDateTime).endTime, format: format));

      // startTime (datetime picker?)
      dataContent.add(FormFieldText('Start Date',
        inputType: TextInputType.datetime,
        hint: format,
        controller: _textControllers["start_time"],
        validator: (value) => _validateDate(value, format: format),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ));
      // endTime (datetime picker?)
      dataContent.add(FormFieldText('End Date',
        inputType: TextInputType.datetime,
        hint: format,
        controller: _textControllers["end_time"],
        validator: (value) => _validateDate(value, format: format),
        padding: EdgeInsets.zero,
      ));
    } else if (_data is SurveyQuestionNumeric) {
      // style
      String styleVal = (_data as SurveyQuestionNumeric).style ?? SurveyQuestionNumeric.supportedStyles.entries.first.key;
      dataContent.add(SurveyElementCreationWidget.buildDropdownWidget<String>(SurveyQuestionNumeric.supportedStyles, "Style", styleVal, _onChangeStyle));

      _textControllers["minimum"] ??= TextEditingController(text: (_data as SurveyQuestionNumeric).minimum?.toString());
      _textControllers["maximum"] ??= TextEditingController(text: (_data as SurveyQuestionNumeric).maximum?.toString());
      //minimum
      dataContent.add(FormFieldText('Minimum', padding: const EdgeInsets.symmetric(vertical: 16), controller: _textControllers["minimum"], inputType: TextInputType.number,));
      //maximum
      dataContent.add(FormFieldText('Maximum', padding: EdgeInsets.zero, controller: _textControllers["maximum"], inputType: TextInputType.number,));

      // wholeNum
      dataContent.add(SurveyElementCreationWidget.buildCheckboxWidget("Whole Number", (_data as SurveyQuestionNumeric).wholeNum, _onToggleWholeNumber));

      // selfScore
      if (_data.scoreRule == null) {
        dataContent.add(SurveyElementCreationWidget.buildCheckboxWidget("Self-Score", (_data as SurveyQuestionNumeric).selfScore, _onToggleSelfScore));
      }
    } else if (_data is SurveyQuestionText) {
      _textControllers["min_length"] ??= TextEditingController(text: (_data as SurveyQuestionText).minLength.toString());
      _textControllers["max_length"] ??= TextEditingController(text: (_data as SurveyQuestionText).maxLength?.toString());
      //minLength*
      dataContent.add(FormFieldText('Minimum Length', padding: const EdgeInsets.symmetric(vertical: 16), controller: _textControllers["min_length"], inputType: TextInputType.number, required: true));
      //maxLength
      dataContent.add(FormFieldText('Maximum Length', padding: EdgeInsets.zero, controller: _textControllers["max_length"], inputType: TextInputType.number,));
    } else if (_data is SurveyDataResult && _data.type == 'survey_data.action') {
      // actions
      List<ActionData> actions = (_data as SurveyDataResult).actions ?? [];
      dataContent.add(Padding(padding: const EdgeInsets.only(top: 16.0), child: SurveyElementList(
        type: SurveyElementListType.actions,
        label: 'Buttons (${actions.length})',
        dataList: actions,
        surveyElement: SurveyElement.actionData,
        onAdd: _onTapAdd,
        onEdit: _onTapEdit,
        onRemove: _onTapRemove,
        onDrag: _onAcceptDataDrag,
      )));
    }
    // add SurveyDataPage and SurveyDataEntry later

    List<Pair<String, bool>> sectionsList = List.generate(widget.sections.length, (index) =>
      Pair(widget.sections[index], _data.sections?.contains(widget.sections[index]) ?? (_data.section == widget.sections[index]))
    );
    String sectionsLabel = 'Sections';
    if (CollectionUtils.isNotEmpty(_data.sections)) {
      sectionsLabel += ' (${_data.sections!.join(', ')})';
    }
    List<Widget> baseContent = [
      // data type
      SurveyElementCreationWidget.buildDropdownWidget<String>(widget.mayChangeType ? SurveyData.supportedTypes : {"survey_data.action": "Action"}, "Type", _data.type, _onChangeType, margin: EdgeInsets.zero),
      
      // sections
      Visibility(
        visible: widget.sections.isNotEmpty && _data is! SurveyDataResult,
        child: Padding(padding: const EdgeInsets.only(top: 16), child: SurveyElementList(
          type: SurveyElementListType.checklist,
          label: sectionsLabel,
          dataList: sectionsList,
          surveyElement: SurveyElement.sections,
          onChanged: _onChangeSection,
        )),
      ),
      // legacy section (set this to allow section scoring on survey in app version <5.0)
      // Visibility(
      //   visible: widget.sections.isNotEmpty && _data is! SurveyDataResult,
      //   child: SurveyElementCreationWidget.buildDropdownWidget<String>(Map.fromIterable(<String?>[null] + widget.sections, value: (v) => v ?? 'None'), "Legacy Section", _data.section, _onChangeLegacySection),
      // ),
      
      // key*
      FormFieldText('Reference Key', padding: const EdgeInsets.only(top: 16), controller: _textControllers["key"], inputType: TextInputType.text, required: true),
      // question text*
      FormFieldText(_data.isQuestion ? 'Question Text' : 'Title', padding: const EdgeInsets.only(top: 16), controller: _textControllers["text"], multipleLines: true, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences, required: true),
      // more info (Additional Info)
      FormFieldText(_data.isQuestion ? 'Additional Info' : 'Text', padding: const EdgeInsets.only(top: 16), controller: _textControllers["more_info"], multipleLines: true, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences,),

      // allowSkip
      Visibility(visible: _data.isQuestion, child: SurveyElementCreationWidget.buildCheckboxWidget("Required", !_data.allowSkip, _onToggleRequired)),
      
      // defaultResponseRule
      Visibility(visible: _data is! SurveyDataResult, child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors.getColor('surface')),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text("Default Response Rule", style: Styles().textStyles.getTextStyle('widget.message.regular'), maxLines: 2, overflow: TextOverflow.ellipsis,)),
            GestureDetector(
              onTap: _onTapManageDefaultResponseRule,
              child: Text(_data.defaultResponseRule == null ? "Create" : "Remove", style: Styles().textStyles.getTextStyle('widget.button.title.medium.underline'))
            ),
          ],),
          Visibility(visible: _data.defaultResponseRule != null, child: Padding(padding: const EdgeInsets.only(top: 16), child: 
            SurveyElementList(
              type: SurveyElementListType.rules,
              label: '',
              dataList: [_data.defaultResponseRule],
              surveyElement: SurveyElement.defaultResponseRule,
              onAdd: _onTapAdd,
              onEdit: _onTapEdit,
              onRemove: _onTapRemove,
              singleton: true,
            )
          )),
        ])
      )),

      // scoreRule (show entry if survey is scored)
      Visibility(visible: _data is! SurveyDataResult && widget.scoredSurvey, child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors.getColor('surface')),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Score Rule", style: Styles().textStyles.getTextStyle('widget.message.regular')),
            GestureDetector(
              onTap: _onTapManageScoreRule,
              child: Text(_data.scoreRule == null ? "Create" : "Remove", style: Styles().textStyles.getTextStyle('widget.button.title.medium.underline'))
            ),
          ],),
          Visibility(visible: _data.scoreRule != null, child: Padding(padding: const EdgeInsets.only(top: 16), child: 
            SurveyElementList(
              type: SurveyElementListType.rules,
              label: '',
              dataList: [_data.scoreRule],
              surveyElement: SurveyElement.scoreRule,
              onAdd: _onTapAdd,
              onEdit: _onTapEdit,
              onRemove: _onTapRemove,
              singleton: true,
            )
          )),
        ])
      )),

      // type specific data
      ...dataContent,
    ];

    return Padding(padding: const EdgeInsets.all(16), child: Column(children: baseContent,));
  }

  Widget _buildDone() {
    return Padding(padding: const EdgeInsets.all(8.0), child: RoundedButton(
      label: 'Done',
      borderColor: Styles().colors.fillColorPrimaryVariant,
      backgroundColor: Styles().colors.surface,
      textStyle: Styles().textStyles.getTextStyle('widget.detail.large.fat'),
      onTap: _onTapDone,
    ));
  }

  void _onTapAdd(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    switch (surveyElement) {
      case SurveyElement.questionData: _onTapAddDataAtIndex(index); break;
      case SurveyElement.actionData: _onTapAddDataAtIndex(index); break;
      case SurveyElement.defaultResponseRule: _onTapAddRuleElementForId(index, surveyElement, parentElement); break;
      case SurveyElement.scoreRule: _onTapAddRuleElementForId(index, surveyElement, parentElement); break;
      default: return;
    }
  }

  void _onTapRemove(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    switch (surveyElement) {
      case SurveyElement.questionData: _onTapRemoveDataAtIndex(index); break;
      case SurveyElement.actionData: _onTapRemoveDataAtIndex(index); break;
      case SurveyElement.defaultResponseRule: _onTapRemoveRuleElementForId(index, surveyElement, parentElement); break;
      case SurveyElement.scoreRule: _onTapRemoveRuleElementForId(index, surveyElement, parentElement); break;
      default: return;
    }
  }

  void _onTapEdit(int index, SurveyElement surveyElement, RuleElement? element, RuleElement? parentElement) {
    switch (surveyElement) {
      case SurveyElement.questionData: _onTapEditData(index); break;
      case SurveyElement.actionData: _onTapEditData(index); break;
      case SurveyElement.defaultResponseRule: _onTapEditRuleElement(element, surveyElement, parentElement: parentElement); break;
      case SurveyElement.scoreRule: _onTapEditRuleElement(element, surveyElement, parentElement: parentElement); break;
      default: return;
    }
  }

  void _onAcceptDataDrag(int oldIndex, int newIndex) {
    setState(() {
      if (_data is SurveyQuestionMultipleChoice) {
        OptionData temp = (_data as SurveyQuestionMultipleChoice).options[oldIndex];
        (_data as SurveyQuestionMultipleChoice).options.removeAt(oldIndex);
        (_data as SurveyQuestionMultipleChoice).options.insert(newIndex, temp);
      } else if (_data is SurveyDataResult) {
        ActionData temp = (_data as SurveyDataResult).actions![oldIndex];
        (_data as SurveyDataResult).actions!.removeAt(oldIndex);
        (_data as SurveyDataResult).actions!.insert(newIndex, temp);
      }
    });
  }

  void _onTapAddDataAtIndex(int index) {
    setState(() {
      if (_data is SurveyQuestionMultipleChoice) {
        (_data as SurveyQuestionMultipleChoice).options.insert(index, index > 0 ? OptionData.fromOther((_data as SurveyQuestionMultipleChoice).options[index-1]) : OptionData(title: "New Option", value: ""));
      } else if (_data is SurveyDataResult) {
        (_data as SurveyDataResult).actions ??= [];
        (_data as SurveyDataResult).actions!.insert(index, index > 0 ? ActionData.fromOther((_data as SurveyDataResult).actions![index-1]) : ActionData(label: 'New Action', type: ActionType.launchUri, params: {}));
      }
    });
  }

  void _onTapRemoveDataAtIndex(int index) {
    setState(() {
      if (_data is SurveyQuestionMultipleChoice) {
        (_data as SurveyQuestionMultipleChoice).options.removeAt(index);
      } else if (_data is SurveyDataResult) {
        (_data as SurveyDataResult).actions!.removeAt(index);
      }
    });
  }

  void _onTapEditData(int index) async {
    if (_data is SurveyQuestionMultipleChoice) {
      dynamic updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataOptionsPanel(
        data: (_data as SurveyQuestionMultipleChoice).options[index],
        dataKeys: widget.dataKeys,
        tabBar: widget.tabBar
      )));
      if (updatedData != null && mounted) {
        setState(() {
          (_data as SurveyQuestionMultipleChoice).options[index] = updatedData;
        });
      }
    } else if (_data is SurveyDataResult) {
      dynamic updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataOptionsPanel(
        data: (_data as SurveyDataResult).actions![index],
        dataKeys: widget.dataKeys,
        tabBar: widget.tabBar
      )));
      if (updatedData != null && mounted) {
        setState(() {
          (_data as SurveyDataResult).actions![index] = updatedData;
        });
      }
    }
  }

  void _onTapAddRuleElementForId(int index, SurveyElement surveyElement, RuleElement? element) {
    //TODO: what should defaults be?
    if (element is RuleCases) {
      element.cases.insert(index, index > 0 ? Rule.fromOther(element.cases[index-1]) : Rule(
        condition: RuleComparison(dataKey: "", operator: "==", compareTo: ""),
        trueResult: RuleAction(action: "set_to", data: null),
      ));
    } else if (element is RuleActionList) {
      element.actions.insert(index, index > 0 ? RuleAction.fromOther(element.actions[index-1]) : RuleAction(action: "set_to", data: null));
    } else if (element is RuleLogic) {
      element.conditions.insert(index, index > 0 ? RuleCondition.fromOther(element.conditions[index-1]) : RuleComparison(dataKey: "", operator: "==", compareTo: ""));
    }

    if (element != null) {
      setState(() {
        (surveyElement == SurveyElement.defaultResponseRule ? _data.defaultResponseRule : _data.scoreRule)?.updateElement(element);
      });
    }
  }

  void _onTapRemoveRuleElementForId(int index, SurveyElement surveyElement, RuleElement? element) {
    if (element is RuleCases) {
      element.cases.removeAt(index);
    } else if (element is RuleActionList) {
      element.actions.removeAt(index);
    } else if (element is RuleLogic) {
      element.conditions.removeAt(index);
    }

    if (element != null) {
      setState(() {
        (surveyElement == SurveyElement.defaultResponseRule ? _data.defaultResponseRule : _data.scoreRule)?.updateElement(element);
      });
    }
  }

  void _onTapEditRuleElement(RuleElement? element, SurveyElement surveyElement, {RuleElement? parentElement}) async {
    if (element != null) {
      List<String> dataKeys = List.from(widget.dataKeys);
      int oldKeyIndex = dataKeys.indexOf(widget.data.key);
      if (oldKeyIndex != -1) {
        dataKeys[oldKeyIndex] = _textControllers['key']!.text;
      }
      RuleElement? ruleElement = await Navigator.push(context, CupertinoPageRoute(builder: (context) => RuleElementCreationPanel(
        data: element,
        surveyElement: surveyElement,
        questionDataKeys: dataKeys,
        questionDataTypes: widget.dataTypes,
        sections: widget.sections,
        mayChangeType: parentElement is! RuleCases && parentElement is! RuleActionList,
        tabBar: widget.tabBar,
      )));

      if (ruleElement != null && mounted) {
        setState(() {
          if (surveyElement == SurveyElement.defaultResponseRule) {
            if (element.id == _data.defaultResponseRule!.id && ruleElement is RuleResult) {
              _data.defaultResponseRule = ruleElement;
            } else {
              _data.defaultResponseRule!.updateElement(ruleElement);
            }
          } else {
            if (element.id == _data.scoreRule!.id && ruleElement is RuleResult) {
              _data.scoreRule = ruleElement;
            } else {
              _data.scoreRule!.updateElement(ruleElement);
            }
          }
        });
      }
    }
  }

  void _onTapManageDefaultResponseRule() {
    if (_data.defaultResponseRule != null) {
      _onRemoveRule(() {
        _data.defaultResponseRule = null;
      });
    } else {
      RuleResult? defaultRule;
      switch (_data.type) {
        case "survey_data.true_false":
          List<OptionData> options = (_data as SurveyQuestionTrueFalse).options;
          defaultRule = RuleAction(action: "set_to", data: options.first.responseValue);
          break;
        case "survey_data.multiple_choice":
          List<OptionData> options = (_data as SurveyQuestionMultipleChoice).options;
          defaultRule = RuleAction(action: "set_to", data: options.isNotEmpty ? options.first.responseValue : 0);
          break;
        case "survey_data.date_time":
          defaultRule = RuleAction(action: "set_to", data: DateTimeUtils.localDateTimeToString(DateTime.now(), format: "MM-dd-yyyy"));
          break;
        case "survey_data.numeric":
          defaultRule = RuleAction(action: "set_to", data: 0);
          break;
        case "survey_data.text":
          defaultRule = RuleAction(action: "set_to", data: "");
          break;
      }
      setState(() {
        _data.defaultResponseRule = defaultRule;
      });
    }
  }

  void _onTapManageScoreRule() {
    if (_data.scoreRule != null) {
      _onRemoveRule(() {
        _data.scoreRule = null;
      });
    } else {
      setState(() {
        _data.scoreRule = RuleAction(action: "set_to", data: 0);
      });
    }
  }

  void _onRemoveRule(Function() removeFunc) {
    List<Widget> buttons = [
      Padding(padding: const EdgeInsets.only(right: 8), child: ButtonBuilder.standardRoundedButton(label: 'Yes', onTap: (() {
        Navigator.pop(context);
        setState(removeFunc);
      }))),
      Padding(padding: const EdgeInsets.only(left: 8), child: ButtonBuilder.standardRoundedButton(label: 'No', onTap: (() {
        Navigator.pop(context);
      }))),
    ];
    ActionsMessage.show(context: context,
      title: "Remove Rule",
      message: "Are you sure you want to remove this rule?",
      buttons: buttons,
    );
  }

  void _onChangeType(String? type) {
    String key = _textControllers["key"]!.text;
    String text = _textControllers["text"]!.text;
    String? moreInfo = _textControllers["more_info"]!.text.isNotEmpty ? _textControllers["more_info"]!.text : null;
    _removeTextControllers(keepDefaults: true);

    List<String>? sections = _data.sections != null ? List.from(_data.sections!) : null;
    setState(() {
      switch (type) {
        case "survey_data.true_false":
          _data = SurveyQuestionTrueFalse(key: key, text: text, moreInfo: moreInfo, section: _data.section, sections: sections);
          break;
        case "survey_data.multiple_choice":
          _data = SurveyQuestionMultipleChoice(key: key, text: text, moreInfo: moreInfo, section: _data.section, sections: sections, options: []);
          break;
        case "survey_data.date_time":
          _data = SurveyQuestionDateTime(key: key, text: text, moreInfo: moreInfo, section: _data.section, sections: sections);
          break;
        case "survey_data.numeric":
          _data = SurveyQuestionNumeric(key: key, text: text, moreInfo: moreInfo, section: _data.section, sections: sections);
          break;
        case "survey_data.text":
          _data = SurveyQuestionText(key: key, text: text, moreInfo: moreInfo, section: _data.section, sections: sections);
          break;
        case "survey_data.info":
          _data = SurveyDataResult(key: key, text: text, moreInfo: moreInfo);
          break;
        case "survey_data.action":
          _data = SurveyDataResult(key: key, text: text, moreInfo: moreInfo, actions: []);
          break;
      }
    });
  }

  void _onChangeSection(int index, dynamic value) {
    setState(() {
      String section = widget.sections[index];
      if (value is bool) {
        _data.sections ??= [];
        value ? _data.sections!.add(section) : _data.sections!.remove(section);
      }
    });
  }

  // void _onChangeLegacySection(String? section) {
  //   setState(() {
  //     _data.section = section;
  //   });
  // }

  void _onChangeStyle(String? style) {
    setState(() {
      if (_data is SurveyQuestionTrueFalse) {
        (_data as SurveyQuestionTrueFalse).style = style ?? SurveyQuestionTrueFalse.supportedStyles.keys.first;
      } else if (_data is SurveyQuestionMultipleChoice) {
        (_data as SurveyQuestionMultipleChoice).style = style ?? SurveyQuestionMultipleChoice.supportedStyles.keys.first;
      } else if (_data is SurveyQuestionNumeric) {
        (_data as SurveyQuestionNumeric).style = style ?? SurveyQuestionNumeric.supportedStyles.keys.first;
      }
    });
  }

  void _onChangeCorrectAnswer(bool? answer) {
    setState(() {
      (_data as SurveyQuestionTrueFalse).correctAnswer = answer;
    });
  }

  void _onToggleRequired(bool? value) {
    setState(() {
      _data.allowSkip = !(value ?? false);
    });
  }

  void _onToggleMultipleAnswers(bool? value) {
    setState(() {
      (_data as SurveyQuestionMultipleChoice).allowMultiple = value ?? false;
    });
  }

  void _onToggleSelfScore(bool? value) {
    setState(() {
      if (_data is SurveyQuestionMultipleChoice) {
        (_data as SurveyQuestionMultipleChoice).selfScore = value ?? false;
      } else if (_data is SurveyQuestionNumeric) {
        (_data as SurveyQuestionNumeric).selfScore = value ?? false;
      }
    });
  }

  void _onToggleWholeNumber(bool? value) {
    setState(() {
      (_data as SurveyQuestionNumeric).wholeNum = value ?? false;
    });
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

  void _onTapDone() {
    // defaultFollowUpKey and followUpRule will be handled by rules defined on SurveyCreationPanel
    _data.key = _textControllers["key"]!.text;
    _data.text = _textControllers["text"]!.text;
    _data.moreInfo = _textControllers["more_info"]!.text.isNotEmpty ? _textControllers["more_info"]!.text : null;

    if (_data is SurveyQuestionTrueFalse) {
      String? style = (_data as SurveyQuestionTrueFalse).style;
      if ((style == 'toggle' || style == 'checkbox') && _data.defaultResponseRule == null) {
        (_data as SurveyQuestionTrueFalse).response = false;
      }
    } else if (_data is SurveyQuestionMultipleChoice) {
      for (OptionData option in (_data as SurveyQuestionMultipleChoice).options) {
        if (option.isCorrect) {
          (_data as SurveyQuestionMultipleChoice).correctAnswers ??= [];
          (_data as SurveyQuestionMultipleChoice).correctAnswers!.add(option.responseValue);
        }
      }
    } else if (_data is SurveyQuestionDateTime) {
      (_data as SurveyQuestionDateTime).startTime = DateTimeUtils.parseDateTime(_textControllers["start_time"]!.text, format: "MM-dd-yyyy");
      (_data as SurveyQuestionDateTime).endTime = DateTimeUtils.parseDateTime(_textControllers["end_time"]!.text, format: "MM-dd-yyyy");
    } else if (_data is SurveyQuestionNumeric) {
      (_data as SurveyQuestionNumeric).minimum = double.tryParse(_textControllers["minimum"]!.text);
      (_data as SurveyQuestionNumeric).maximum = double.tryParse(_textControllers["maximum"]!.text);
    } else if (_data is SurveyQuestionText) {
      (_data as SurveyQuestionText).minLength = int.tryParse(_textControllers["min_length"]!.text) ?? 0;
      (_data as SurveyQuestionText).maxLength = int.tryParse(_textControllers["max_length"]!.text);
    }
    
    //TODO: update rules with contents of data key text entry
    // if (_data.defaultResponseRule != null) {
    // }
    // if (_data.scoreRule != null) {
    // }

    Navigator.of(context).pop(_data);
  }
}