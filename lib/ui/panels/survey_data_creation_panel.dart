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
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyDataCreationPanel extends StatefulWidget {
  final SurveyData data;
  final List<String> dataKeys;
  final List<String> dataTypes;
  final Widget? tabBar;
  final List<String> sections;
  final bool scoredSurvey;

  const SurveyDataCreationPanel({Key? key, required this.data, required this.dataKeys, required this.dataTypes, required this.sections, required this.scoredSurvey, this.tabBar}) : super(key: key);

  @override
  _SurveyDataCreationPanelState createState() => _SurveyDataCreationPanelState();
}

class _SurveyDataCreationPanelState extends State<SurveyDataCreationPanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  late final Map<String, TextEditingController> _textControllers;
  final List<String> _defaultTextControllers = ["key", "text", "more_info", "maximum_score"];

  late SurveyData _data;
  RuleResult? _defaultResponseRule;
  RuleResult? _scoreRule;
  final Map<String, String> _supportedActions = {};

  @override
  void initState() {
    _data = widget.data;
    for (ActionType action in ActionType.values) {
      _supportedActions[action.name] = action.name;
    }

    _textControllers = {
      "key": TextEditingController(text: _data.key),
      "text": TextEditingController(text: _data.text),
      "more_info": TextEditingController(text: _data.moreInfo),
      "maximum_score": TextEditingController(text: _data.maximumScore?.toString()),
    };

    if (_data.section != null && !widget.sections.contains(_data.section)) {
      _data.section = null;
    }

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
      backgroundColor: Styles().colors?.background,
      body: Column(
        children: [
          Expanded(child: Scrollbar(
            radius: const Radius.circular(2),
            thumbVisibility: true,
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: _buildSurveyDataComponents(),
            ),
          )),
          Container(
            color: Styles().colors?.backgroundVariant,
            child: _buildDone(),
          ),
        ],
    ));
  }

  Widget _buildCollapsibleWrapper(String label, List<dynamic> dataList, Widget Function(int, dynamic, SurveyElement, RuleElement?) listItemBuilder, SurveyElement surveyElement, {RuleElement? parentElement, int? parentIndex, RuleElement? grandParentElement}) {
    bool hideEntryManagement = parentElement is RuleLogic && grandParentElement is Rule;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        title: Row(children: [
          Expanded(child: Text(
            label,
            maxLines: 2,
            style: Styles().textStyles?.getTextStyle('widget.detail.small'),
          )),
          Expanded(child: _buildEntryManagementOptions((parentIndex ?? -1) + 1, surveyElement, 
            element: parentElement,
            parentElement: grandParentElement,
            addRemove: parentElement != null && parentIndex != null && !hideEntryManagement,
            editable: parentElement != null && !hideEntryManagement
          )),
        ],),
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          dataList.isNotEmpty ? ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: dataList.length,
            itemBuilder: (BuildContext context, int index) {
              return Column(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: listItemBuilder(index, dataList[index], surveyElement, parentElement)),
                ],
              );
            },
          ) : Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Row(children: [
              Container(height: 0),
              Expanded(child: _buildEntryManagementOptions(0, surveyElement, parentElement: parentElement))
            ]
          )),
        ],
      ),
    );
  }

  Widget _buildSurveyDataComponents() {
    List<Widget> dataContent = [];
    if (_data is SurveyQuestionTrueFalse) {
      // style
      dataContent.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
        Text("Style", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildSurveyDropDownItems<String>(SurveyQuestionTrueFalse.supportedStyles),
            value: (_data as SurveyQuestionTrueFalse).style ?? SurveyQuestionTrueFalse.supportedStyles.entries.first.key,
            onChanged: _onChangeStyle,
            dropdownColor: Styles().colors?.getColor('background'),
          ),
        ),))],)
      ));

      // correct answer (dropdown: Yes/True, No/False, null)
      Map<bool?, String> supportedAnswers = {true: "Yes/True", false: "No/False", null: ""};
      
      dataContent.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
        Text("Correct Answer", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<bool?>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildSurveyDropDownItems<bool?>(supportedAnswers),
            value: (_data as SurveyQuestionTrueFalse).correctAnswer,
            onChanged: _onChangeCorrectAnswer,
            dropdownColor: Styles().colors?.getColor('background'),
          ),
        ),))],)
      ));
    } else if (_data is SurveyQuestionMultipleChoice) {
      // style
      dataContent.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
        Text("Style", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildSurveyDropDownItems<String>(SurveyQuestionMultipleChoice.supportedStyles),
            value: (_data as SurveyQuestionMultipleChoice).style ?? SurveyQuestionMultipleChoice.supportedStyles.entries.first.key,
            onChanged: _onChangeStyle,
            dropdownColor: Styles().colors?.getColor('background'),
          ),
        ),))],)
      ));

      // options
      dataContent.add(Padding(padding: const EdgeInsets.only(top: 16.0), child: 
        _buildCollapsibleWrapper('Options', (_data as SurveyQuestionMultipleChoice).options, _buildOptionsWidget, SurveyElement.data))
      );
      
      // allowMultiple
      dataContent.add(Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 16, left: 16), child: Text("Multiple Answers", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
        Expanded(child: Align(alignment: Alignment.centerRight, child: Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: (_data as SurveyQuestionMultipleChoice).allowMultiple,
          onChanged: _onToggleMultipleAnswers,
        ))),
      ],));
      
      // selfScore
      dataContent.add(Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 16, left: 16), child: Text("Self-Score", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
        Expanded(child: Align(alignment: Alignment.centerRight, child: Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: (_data as SurveyQuestionMultipleChoice).selfScore,
          onChanged: _onToggleSelfScore,
        ))),
      ],));
    } else if (_data is SurveyQuestionDateTime) {
      _textControllers["start_time"] ??= TextEditingController(text: DateTimeUtils.localDateTimeToString((_data as SurveyQuestionDateTime).startTime, format: "MM-dd-yyyy"));
      _textControllers["end_time"] ??= TextEditingController(text: DateTimeUtils.localDateTimeToString((_data as SurveyQuestionDateTime).endTime, format: "MM-dd-yyyy"));

      // startTime (datetime picker?)
      dataContent.add(FormFieldText('Start Date',
        inputType: TextInputType.datetime,
        hint: "MM-dd-yyyy",
        controller: _textControllers["start_time"],
        validator: _validateDate,
      ));
      // endTime (datetime picker?)
      dataContent.add(FormFieldText('End Date',
        inputType: TextInputType.datetime,
        hint: "MM-dd-yyyy",
        controller: _textControllers["end_time"],
        validator: _validateDate,
      ));

      // askTime
      // dataContent.add(Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      //   Text("Ask Time", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
      //   Checkbox(
      //     checkColor: Styles().colors?.surface,
      //     activeColor: Styles().colors?.fillColorPrimary,
      //     value: (_data as SurveyQuestionDateTime).askTime,
      //     onChanged: _onToggleAskTime,
      //   ),
      // ],));
    } else if (_data is SurveyQuestionNumeric) {
      
      // style
      dataContent.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
        Text("Style", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildSurveyDropDownItems<String>(SurveyQuestionNumeric.supportedStyles),
            value: (_data as SurveyQuestionNumeric).style ?? SurveyQuestionNumeric.supportedStyles.entries.first.key,
            onChanged: _onChangeStyle,
            dropdownColor: Styles().colors?.getColor('background'),
          ),
        ),))],)
      ));

      _textControllers["minimum"] ??= TextEditingController(text: (_data as SurveyQuestionNumeric).minimum?.toString());
      _textControllers["maximum"] ??= TextEditingController(text: (_data as SurveyQuestionNumeric).maximum?.toString());
      //minimum
      dataContent.add(FormFieldText('Minimum', controller: _textControllers["minimum"], inputType: TextInputType.number,));
      //maximum
      dataContent.add(FormFieldText('Maximum', controller: _textControllers["maximum"], inputType: TextInputType.number,));

      // wholeNum
      dataContent.add(Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 16, left: 16), child: Text("Whole Number", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
        Expanded(child: Align(alignment: Alignment.centerRight, child: Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: (_data as SurveyQuestionNumeric).wholeNum,
          onChanged: _onToggleWholeNumber,
        ))),
      ],));

      // selfScore
      dataContent.add(Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 16, left: 16), child: Text("Self-Score", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
        Expanded(child: Align(alignment: Alignment.centerRight, child: Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: (_data as SurveyQuestionNumeric).selfScore,
          onChanged: _onToggleSelfScore,
        ))),
      ],));
    } else if (_data is SurveyQuestionText) {
      _textControllers["min_length"] ??= TextEditingController(text: (_data as SurveyQuestionText).minLength.toString());
      _textControllers["max_length"] ??= TextEditingController(text: (_data as SurveyQuestionText).maxLength?.toString());
      //minLength*
      dataContent.add(FormFieldText('Minimum Length', controller: _textControllers["min_length"], inputType: TextInputType.number, required: true));
      //maxLength
      dataContent.add(FormFieldText('Maximum Length', controller: _textControllers["max_length"], inputType: TextInputType.number,));
    } else if (_data is SurveyDataResult) {
      // actions
      dataContent.add(Padding(padding: const EdgeInsets.only(top: 16.0), child: 
        _buildCollapsibleWrapper('Actions', (_data as SurveyDataResult).actions ?? [], _buildActionsWidget, SurveyElement.data))
      );
    }
    // add SurveyDataPage and SurveyDataEntry later

    List<Widget> baseContent = [
      Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('General', style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'))),
      // data type
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
        Text("Type", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildSurveyDropDownItems<String>(SurveyData.supportedTypes),
            value: _data.type,
            onChanged: _onChangeType,
            dropdownColor: Styles().colors?.getColor('background'),
          ),
        ))),],)
      ),

      //section
      Visibility(visible: widget.sections.isNotEmpty, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
        Text("Section", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildSurveyDropDownItems<String>(Map.fromIterable(widget.sections)),
            value: _data.section,
            onChanged: _onChangeSection,
            dropdownColor: Styles().colors?.getColor('background'),
          ),
        ),))],)
      )),

      //key*
      FormFieldText('Key', padding: const EdgeInsets.only(top: 16), controller: _textControllers["key"], inputType: TextInputType.text, required: true),
      //question text*
      FormFieldText('Question Text', padding: const EdgeInsets.only(top: 16), controller: _textControllers["text"], inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences, required: true),
      //more info (Additional Info)
      FormFieldText('Additional Info', padding: const EdgeInsets.only(top: 16), controller: _textControllers["more_info"], multipleLines: true, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences,),
      //maximum score (number, show if survey is scored)
      Visibility(visible: _data.isQuestion, child: FormFieldText('Maximum Score', padding: const EdgeInsets.only(top: 16), controller: _textControllers["maximum_score"], inputType: TextInputType.number,)),

      // allowSkip
      Visibility(visible: _data.isQuestion, child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 16, left: 16), child: Text("Required", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
        Expanded(child: Align(alignment: Alignment.centerRight, child: Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: !_data.allowSkip,
          onChanged: (value) => _onToggleRequired(value),
        ))),
      ],)),

      // replace
      // Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      //   Text("Scored", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
      //   Checkbox(
      //     checkColor: Styles().colors?.surface,
      //     activeColor: Styles().colors?.fillColorPrimary,
      //     value: _data.replace,
      //     onChanged: _onToggleReplace,
      //   ),
      // ],),

      // defaultResponseRule
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Padding(padding: const EdgeInsets.only(top: 16, left: 16), child: Text("Default Response Rule", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
        Padding(padding: const EdgeInsets.only(top: 16, right: 16), child: GestureDetector(
          onTap: _onTapManageDefaultResponseRule,
          child: Text(_defaultResponseRule == null ? "None" : "Clear", style: Styles().textStyles?.getTextStyle('widget.button.title.medium.underline'))
        )),
      ],),
      Visibility(visible: _defaultResponseRule != null, child: Padding(padding: const EdgeInsets.only(top: 16.0), child: 
        _buildRuleWidget(0, _defaultResponseRule, SurveyElement.defaultResponseRule, null)
      ),),

      // scoreRule (show entry if survey is scored)
      Visibility(visible: widget.scoredSurvey, child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Padding(padding: const EdgeInsets.only(top: 16, left: 16), child: Text("Score Rule", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
          Padding(padding: const EdgeInsets.only(top: 16, right: 16), child: GestureDetector(
            onTap: _onTapManageScoreRule,
            child: Text(_scoreRule == null ? "None" : "Clear", style: Styles().textStyles?.getTextStyle('widget.button.title.medium.underline'))
          )),
        ],),
        Visibility(visible: _scoreRule != null, child: Padding(padding: const EdgeInsets.only(top: 16.0), child: 
          _buildRuleWidget(0, _scoreRule, SurveyElement.scoreRule, null)
        ),),
      ])),

      // type specific data
      Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('Type Specific', style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'))),

      ...dataContent,
    ];

    return Column(children: baseContent,);
  }

  Widget _buildRuleWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement) {
    if (data != null) {
      RuleElement ruleElem = data as RuleElement;
      String summary = ruleElem.getSummary();
      
      bool addRemove = false;
      int? ruleElemIndex;
      if (parentElement is RuleCases) {
        addRemove = true;
        ruleElemIndex = parentElement.cases.indexOf(ruleElem as Rule);
      } else if(parentElement is RuleActionList) {
        addRemove = true;
        ruleElemIndex = parentElement.actions.indexOf(ruleElem as RuleAction);
      } else if (parentElement is RuleLogic) {
        addRemove = true;
        ruleElemIndex = parentElement.conditions.indexOf(ruleElem as RuleCondition);
      } else if (parentElement == null && surveyElement == SurveyElement.resultRules) {
        addRemove = true;
        ruleElemIndex = index;
      }

      late Widget displayEntry;
      Widget ruleText = Text(summary, style: Styles().textStyles?.getTextStyle('widget.detail.small'), overflow: TextOverflow.fade);
      if (ruleElem is RuleReference || ruleElem is RuleAction || ruleElem is RuleComparison) {
        displayEntry = Card(child: Ink(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
          child: Row(children: [
            ruleText,
            Expanded(child: _buildEntryManagementOptions(index + 1, surveyElement, element: ruleElem, parentElement: parentElement, addRemove: addRemove)),
          ],)
        ));
      } else if (ruleElem is RuleLogic) {
        displayEntry = _buildCollapsibleWrapper(parentElement is Rule ? 'Conditions' : summary, ruleElem.conditions, _buildRuleWidget, surveyElement, parentElement: ruleElem, parentIndex: ruleElemIndex, grandParentElement: parentElement);
      } else if (ruleElem is Rule) {
        bool isComparison = ruleElem.condition is RuleComparison;
        String label = ruleElem.condition?.getSummary() ?? "";
        List<RuleElement> elementsSlice = [];
        if (!isComparison) {
          elementsSlice.add(ruleElem.condition!);
        }
        if (ruleElem.trueResult != null) {
          elementsSlice.add(ruleElem.trueResult!);
        }
        if (ruleElem.falseResult != null) {
          elementsSlice.add(ruleElem.falseResult!);
        }
        displayEntry = _buildCollapsibleWrapper(label, elementsSlice, _buildRuleWidget, surveyElement, parentElement: ruleElem, parentIndex: ruleElemIndex, grandParentElement: parentElement);
      } else if (ruleElem is RuleCases) {
        displayEntry = _buildCollapsibleWrapper(summary, ruleElem.cases, _buildRuleWidget, surveyElement, parentElement: ruleElem, parentIndex: ruleElemIndex, grandParentElement: parentElement);
      } else if (ruleElem is RuleActionList) {
        displayEntry = _buildCollapsibleWrapper(summary, ruleElem.actions, _buildRuleWidget, surveyElement, parentElement: ruleElem, parentIndex: ruleElemIndex, grandParentElement: parentElement);
      }

      return LongPressDraggable<String>(
        data: ruleElem.id,
        maxSimultaneousDrags: 1,
        feedback: Card(child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
          child: ruleText
        )),
        child: DragTarget<String>(
          builder: (BuildContext context, List<String?> accepted, List<dynamic> rejected) {
            return displayEntry;
          },
          onAccept: (swapId) => _onAcceptRuleDrag(swapId, ruleElem.id, surveyElement, parentElement: parentElement),
        ),
        childWhenDragging: displayEntry,
        axis: Axis.vertical,
      );
    }
    return Container();
  }

  Widget _buildEntryManagementOptions(int index, SurveyElement surveyElement, {RuleElement? element, RuleElement? parentElement, bool addRemove = true, bool editable = true}) {
    bool ruleRemove = true;
    if ((parentElement is RuleLogic || parentElement is RuleCases || parentElement is RuleActionList) && index <= 2) {
      ruleRemove = false;
    }

    double buttonBoxSize = 36;
    double splashRadius = 18;
    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
      Visibility(visible: addRemove, child: SizedBox(width: buttonBoxSize, height: buttonBoxSize, child: IconButton(
        icon: Styles().images?.getImage('plus-circle', color: Styles().colors?.getColor('fillColorPrimary'), size: 14) ?? const Icon(Icons.add),
        onPressed: () => _onTapAdd(index, surveyElement, parentElement: parentElement),
        padding: EdgeInsets.zero,
        splashRadius: splashRadius,
      ))),
      Visibility(visible: addRemove && ruleRemove && index > 0, child: SizedBox(width: buttonBoxSize, height: buttonBoxSize, child: IconButton(
        icon: Styles().images?.getImage('clear', size: 14) ?? const Icon(Icons.remove),
        onPressed: () => _onTapRemove(index - 1, surveyElement, parentElement: parentElement),
        padding: EdgeInsets.zero,
        splashRadius: splashRadius,
      ))),
      Visibility(visible: editable && index > 0, child: SizedBox(width: buttonBoxSize, height: buttonBoxSize, child: IconButton(
        icon: Styles().images?.getImage('edit-white', color: Styles().colors?.getColor('fillColorPrimary'), size: 14) ?? const Icon(Icons.edit),
        onPressed: () => _onTapEdit(index - 1, surveyElement, element: element),
        padding: EdgeInsets.zero,
        splashRadius: splashRadius,
      ))),
    ]);
  }

  Widget _buildOptionsWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement) {
    String entryText = (data as OptionData).title;
    if (data.value != null) {
      String valueString = data.value.toString();
      if (valueString.isNotEmpty && valueString != entryText) {
        entryText += entryText.isNotEmpty ? ' ($valueString)' : '($valueString)';
      }
    }
    Widget surveyDataText = Text(entryText, style: Styles().textStyles?.getTextStyle(data.isCorrect ? 'widget.detail.small.fat' : 'widget.detail.small'),);
    Widget displayEntry = Card(child: Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        surveyDataText,
        Expanded(child: _buildEntryManagementOptions(index + 1, surveyElement, parentElement: parentElement)),
      ],)
    ));

    return LongPressDraggable<int>(
      data: index,
      maxSimultaneousDrags: 1,
      feedback: Card(child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: surveyDataText,
      )),
      child: DragTarget<int>(
        builder: (BuildContext context, List<int?> accepted, List<dynamic> rejected) {
          return displayEntry;
        },
        onAccept: (oldIndex) => _onAcceptDataDrag(oldIndex, index),
      ),
      childWhenDragging: displayEntry,
      axis: Axis.vertical,
    );
  }

  Widget _buildActionsWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement) {
    Widget surveyDataText = Text((data as ActionData).label ?? '', style: Styles().textStyles?.getTextStyle('widget.detail.small'),);
    Widget displayEntry = Card(child: Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        surveyDataText,
        Expanded(child: _buildEntryManagementOptions(index + 1, surveyElement, parentElement: parentElement)),
      ],)
    ));

    return LongPressDraggable<int>(
      data: index,
      maxSimultaneousDrags: 1,
      feedback: Card(child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: surveyDataText,
      )),
      child: DragTarget<int>(
        builder: (BuildContext context, List<int?> accepted, List<dynamic> rejected) {
          return displayEntry;
        },
        onAccept: (oldIndex) => _onAcceptDataDrag(oldIndex, index),
      ),
      childWhenDragging: displayEntry,
      axis: Axis.vertical,
    );
  }

  Widget _buildDone() {
    return Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
      label: 'Done',
      borderColor: Styles().colors?.fillColorPrimaryVariant,
      backgroundColor: Styles().colors?.surface,
      textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
      onTap: _onTapDone,
    ));
  }

  List<DropdownMenuItem<T>> _buildSurveyDropDownItems<T>(Map<T, String> supportedItems) {
    List<DropdownMenuItem<T>> items = [];

    for (MapEntry<T, String> item in supportedItems.entries) {
      items.add(DropdownMenuItem<T>(
        value: item.key,
        child: Align(alignment: Alignment.center, child: Container(
          color: Styles().colors?.getColor('background'),
          child: Text(item.value, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)
        )),
      ));
    }
    return items;
  }

  void _onTapAdd(int index, SurveyElement surveyElement, {RuleElement? parentElement}) {
    switch (surveyElement) {
      case SurveyElement.data: _onTapAddDataAtIndex(index); break;
      case SurveyElement.defaultResponseRule: _onTapAddRuleElementForId(index, surveyElement, parentElement); break;
      case SurveyElement.scoreRule: _onTapAddRuleElementForId(index, surveyElement, parentElement); break;
      default: return;
    }
  }

  void _onTapRemove(int index, SurveyElement surveyElement, {RuleElement? parentElement}) {
    switch (surveyElement) {
      case SurveyElement.data: _onTapRemoveDataAtIndex(index); break;
      case SurveyElement.defaultResponseRule: _onTapRemoveRuleElementForId(index, surveyElement, parentElement); break;
      case SurveyElement.scoreRule: _onTapRemoveRuleElementForId(index, surveyElement, parentElement); break;
      default: return;
    }
  }

  void _onTapEdit(int index, SurveyElement surveyElement, {RuleElement? element}) {
    switch (surveyElement) {
      case SurveyElement.data: _onTapEditData(index); break;
      case SurveyElement.defaultResponseRule: _onTapEditRuleElement(element, surveyElement); break;
      case SurveyElement.scoreRule: _onTapEditRuleElement(element, surveyElement); break;
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

  //TODO: does it make sense to swap?
  void _onAcceptRuleDrag(String swapId, String id, SurveyElement surveyElement, {RuleElement? parentElement}) {
    RuleElement? current = (surveyElement == SurveyElement.defaultResponseRule ? _defaultResponseRule : _scoreRule)?.findElement(id);
    RuleElement? swap = (surveyElement == SurveyElement.defaultResponseRule ? _defaultResponseRule : _scoreRule)?.findElement(swapId);
    current?.id = swapId;
    swap?.id = id;

    if (_maySwapRuleElements(current, swap, parentElement)) {
      setState(() {
        if (surveyElement == SurveyElement.defaultResponseRule) {
          if (swap!.id == _defaultResponseRule!.id && swap is RuleResult) {
            _defaultResponseRule = swap;
          } else {
            _defaultResponseRule!.updateElement(swap);
          }
          if (current!.id == _defaultResponseRule!.id && current is RuleResult) {
            _defaultResponseRule = current;
          } else {
            _defaultResponseRule!.updateElement(current);
          }
        } else {
          if (swap!.id == _scoreRule!.id && swap is RuleResult) {
            _scoreRule = swap;
          } else {
            _scoreRule!.updateElement(swap);
          }
          if (current!.id == _scoreRule!.id && current is RuleResult) {
            _scoreRule = current;
          } else {
            _scoreRule!.updateElement(current);
          }
        }
      });
    }
  }

  bool _maySwapRuleElements(RuleElement? current, RuleElement? swap, RuleElement? parentElement) {
    if (current is Rule) {
      return (swap is RuleResult) && (parentElement is! RuleCases);
    } else if (current is RuleAction) {
      return (swap is RuleResult) && (parentElement is! RuleActionList);
    } else if (current is RuleActionList || current is RuleCases) {
      return swap is RuleResult;
    } else if (current is RuleCondition) {
      return swap is RuleCondition;
    }
    return false;
  }

  void _onTapAddDataAtIndex(int index) {
    setState(() {
      if (_data is SurveyQuestionMultipleChoice) {
        (_data as SurveyQuestionMultipleChoice).options.insert(index, OptionData(
          title: index > 0 ? (_data as SurveyQuestionMultipleChoice).options[index-1].title : "New Option",
          value: index > 0 ? (_data as SurveyQuestionMultipleChoice).options[index-1].value : ""
        ));
      } else if (_data is SurveyDataResult) {
        (_data as SurveyDataResult).actions ??= [];
        (_data as SurveyDataResult).actions!.insert(index, ActionData(label: 'New Action'));
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
      dynamic updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataOptionsPanel(data: (_data as SurveyQuestionMultipleChoice).options[index], tabBar: widget.tabBar)));
      if (updatedData != null && mounted) {
        setState(() {
          (_data as SurveyQuestionMultipleChoice).options[index] = updatedData;
        });
      }
    } else if (_data is SurveyDataResult) {
      dynamic updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataOptionsPanel(data: (_data as SurveyDataResult).actions![index], tabBar: widget.tabBar)));
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
      element.cases.insert(index, Rule(
        condition: RuleComparison(dataKey: "", operator: "==", compareTo: ""),
        trueResult: RuleAction(action: "return", data: null),
      ));
    } else if (element is RuleActionList) {
      element.actions.insert(index, RuleAction(action: "return", data: null));
    } else if (element is RuleLogic) {
      element.conditions.insert(index, RuleComparison(dataKey: "", operator: "==", compareTo: ""));
    }

    if (element != null) {
      setState(() {
        (surveyElement == SurveyElement.defaultResponseRule ? _defaultResponseRule : _scoreRule)?.updateElement(element);
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
        (surveyElement == SurveyElement.defaultResponseRule ? _defaultResponseRule : _scoreRule)?.updateElement(element);
      });
    }
  }

  void _onTapEditRuleElement(RuleElement? element, SurveyElement surveyElement, {RuleElement? parentElement}) async {
    if (element != null) {
      RuleElement? ruleElement = await Navigator.push(context, CupertinoPageRoute(builder: (context) => RuleElementCreationPanel(
        data: element,
        dataKeys: widget.dataKeys,
        dataTypes: widget.dataTypes,
        sections: widget.sections,
        tabBar: widget.tabBar, mayChangeType: parentElement is! RuleCases && parentElement is! RuleActionList
      )));

      if (ruleElement != null && mounted) {
        setState(() {
          if (surveyElement == SurveyElement.defaultResponseRule) {
            if (element.id == _defaultResponseRule!.id && ruleElement is RuleResult) {
              _defaultResponseRule = ruleElement;
            }
            else {
              _defaultResponseRule!.updateElement(ruleElement);
            }
          } else {
            if (element.id == _scoreRule!.id && ruleElement is RuleResult) {
              _scoreRule = ruleElement;
            }
            else {
              _scoreRule!.updateElement(ruleElement);
            }
          }
        });
      }
    }
  }

  void _onTapManageDefaultResponseRule() {
    setState(() {
      //TODO: use SurveyData type to determine what default data field should be
      _defaultResponseRule = _defaultResponseRule == null ? RuleAction(action: "return", data: null) : null;
    });
  }

  void _onTapManageScoreRule() {
    setState(() {
      _scoreRule = _scoreRule == null ? RuleAction(action: "return", data: 0) : null;
    });
  }

  void _onChangeType(String? type) {
    String key = _textControllers["key"]!.text;
    String text = _textControllers["text"]!.text;
    String? moreInfo = _textControllers["more_info"]!.text.isNotEmpty ? _textControllers["more_info"]!.text : null;
    num? maximumScore = num.tryParse(_textControllers["maximum_score"]!.text);
    _removeTextControllers(keepDefaults: true);

    setState(() {
      switch (type) {
        case "survey_data.true_false":
          _data = SurveyQuestionTrueFalse(key: key, text: text, moreInfo: moreInfo, section: _data.section, maximumScore: maximumScore);
          break;
        case "survey_data.multiple_choice":
          _data = SurveyQuestionMultipleChoice(key: key, text: text, moreInfo: moreInfo, section: _data.section, maximumScore: maximumScore, options: []);
          break;
        case "survey_data.date_time":
          _data = SurveyQuestionDateTime(key: key, text: text, moreInfo: moreInfo, section: _data.section, maximumScore: maximumScore);
          break;
        case "survey_data.numeric":
          _data = SurveyQuestionNumeric(key: key, text: text, moreInfo: moreInfo, section: _data.section, maximumScore: maximumScore);
          break;
        case "survey_data.text":
          _data = SurveyQuestionText(key: key, text: text, moreInfo: moreInfo, section: _data.section, maximumScore: maximumScore);
          break;
        case "survey_data.result":
          _data = SurveyDataResult(key: key, text: text, moreInfo: moreInfo);
          break;
      }
    });
  }

  void _onChangeSection(String? section) {
    setState(() {
      _data.section = section;
    });
  }

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
      _data.allowSkip = value ?? false;
    });
  }

  // void _onToggleReplace(bool? value) {
  //   setState(() {
  //     _data.replace = value ?? false;
  //   });
  // }

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

  // void _onToggleAskTime(bool? value) {
  //   setState(() {
  //     (_data as SurveyQuestionDateTime).askTime = value ?? false;
  //   });
  // }

  void _onToggleWholeNumber(bool? value) {
    setState(() {
      (_data as SurveyQuestionNumeric).wholeNum = value ?? false;
    });
  }

  String? _validateDate(String? dateStr) {
    if (dateStr != null) {
      if (DateTimeUtils.parseDateTime(dateStr, format: "MM-dd-yyyy") == null) {
        return "Invalid format: must be MM-dd-yyyy";
      }
    }
    return null;
  }

  void _onTapDone() {
    // defaultFollowUpKey and followUpRule will be handled by rules defined on SurveyCreationPanel
    _data.key = _textControllers["key"]!.text;
    _data.text = _textControllers["text"]!.text;
    _data.moreInfo = _textControllers["more_info"]!.text.isNotEmpty ? _textControllers["more_info"]!.text : null;
    _data.maximumScore = num.tryParse(_textControllers["maximum_score"]!.text);

    if (_data is SurveyQuestionMultipleChoice) {
      for (OptionData option in (_data as SurveyQuestionMultipleChoice).options) {
        if (option.isCorrect) {
          (_data as SurveyQuestionMultipleChoice).correctAnswers ??= [];
          (_data as SurveyQuestionMultipleChoice).correctAnswers!.add(option.value);
        }
      }
    } else if (_data is SurveyQuestionDateTime) {
      (_data as SurveyQuestionDateTime).startTime = DateTimeUtils.dateTimeFromString(_textControllers["start_time"]!.text);
      (_data as SurveyQuestionDateTime).endTime = DateTimeUtils.dateTimeFromString(_textControllers["end_time"]!.text);
    } else if (_data is SurveyQuestionNumeric) {
      (_data as SurveyQuestionNumeric).minimum = double.tryParse(_textControllers["minimum"]!.text);
      (_data as SurveyQuestionNumeric).maximum = double.tryParse(_textControllers["maximum"]!.text);
    } else if (_data is SurveyQuestionText) {
      (_data as SurveyQuestionText).minLength = int.tryParse(_textControllers["min_length"]!.text) ?? 0;
      (_data as SurveyQuestionText).maxLength = int.tryParse(_textControllers["max_length"]!.text);
    } else if (_data is SurveyDataResult) {
      // for (int i = 0; i < ((_data as SurveyDataResult).actions?.length ?? 0); i++) {
        //TODO: data, params
      // }
    }
    
    Navigator.of(context).pop(_data);
  }
}