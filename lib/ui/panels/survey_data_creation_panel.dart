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

import 'package:flutter/material.dart';

import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class SurveyDataCreationPanel extends StatefulWidget {
  final SurveyData data;
  final Widget? tabBar;

  const SurveyDataCreationPanel({Key? key, required this.data, this.tabBar}) : super(key: key);

  @override
  _SurveyDataCreationPanelState createState() => _SurveyDataCreationPanelState();
}

class _SurveyDataCreationPanelState extends State<SurveyDataCreationPanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  late final Map<String, TextEditingController> _textControllers;

  late SurveyData _data;
  final Map<String, String> _supportedActions = {};

  @override
  void initState() {
    _data = widget.data;
    _textControllers = {
      "key": TextEditingController(text: _data.key),
      "text": TextEditingController(text: _data.text),
      "more_info": TextEditingController(text: _data.moreInfo),
      "section": TextEditingController(text: _data.section),
      "maximum_score": TextEditingController(text: _data.maximumScore?.toString()),
      "default_follow_up_key": TextEditingController(text: _data.defaultFollowUpKey),
    };
    super.initState();
  }

  @override
  void dispose() {
    _textControllers.forEach((_, value) { value.dispose(); });

    for (ActionType action in ActionType.values) {
      _supportedActions[action.name] = action.name;
    }

    super.dispose();
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

  Widget _buildCollapsibleWrapper(String label, int dataLength, Widget Function(int, String) listItemBuilder) {
    return Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        title: Text(
          label,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
        ),
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500
            ),
            child: dataLength > 0 ? ListView.builder(
              shrinkWrap: true,
              itemCount: dataLength,
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  children: [
                    listItemBuilder(index),
                    Container(height: 1, color: Styles().colors?.getColor('dividerLine'),),
                  ],
                );
              },
            ) : _buildAddRemoveButtons(0, textGroup),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleWidget(String textGroup) {
    //RuleCondition
      //RuleComparison
      //RuleLogic
    //RuleResult
      //Rule
      //RuleReference
      //RuleActionResult
        //RuleAction
        //RuleActionList

    // condition = 
    // {
    //   "operator": "",
    //   "conditions": [
            // condition
    //   ]
    // } OR
    // {
    //   'operator': "",
    //   'data_key': "",
    //   'data_param': "",
    //   'compare_to': "",
    //   'compare_to_param': "",
    //   'default_result': "",
    // }
      //TODO
  // 
  // RuleAction.supportedActions
  // RuleComparison.supportedOperators
  // RuleLogic.supportedOperators
    
          // dropdown for actions
          // dropdown for comparison options
          // dropdown for logic options
          // dropdown for data keys, compare_to options (stats, responses, constants, strings, etc.)
    //TODO
    return Container();
  }

  Widget _buildStringListEntryWidget(, String textGroup) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      FormFieldText('Value', controller: _textControllers["$textGroup$index.value"], inputType: TextInputType.text, required: true),
      _buildAddRemoveButtons(index + 1, textGroup),
    ]);
  }

  Widget _buildAddRemoveButtons(int index, String textGroup) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      IconButton(
        icon: Styles().images?.getImage('plus-circle', color: Styles().colors?.getColor('fillColorPrimary')) ?? const Icon(Icons.add),
        onPressed: () => _onTapAddDataAtIndex(index, textGroup),
        padding: EdgeInsets.zero,
      ),
      IconButton(
        icon: Styles().images?.getImage('minus-circle', color: Styles().colors?.getColor('alert')) ?? const Icon(Icons.add),
        onPressed: () => _onTapRemoveDataAtIndex(index, textGroup),
        padding: EdgeInsets.zero,
      ),
    ]);
  }

  Widget _buildSurveyDataComponents() {
    List<Widget> dataContent = [];
    if (_data is SurveyQuestionTrueFalse) {
      // style
      dataContent.add(DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems<String>(SurveyQuestionTrueFalse.supportedStyles),
          value: (_data as SurveyQuestionTrueFalse).style ?? SurveyQuestionTrueFalse.supportedStyles.entries.first.key,
          onChanged: _onChangeStyle,
          dropdownColor: Styles().colors?.getColor('surface'),
        ),
      ));

      // correct answer (dropdown: Yes/True, No/False, null)
      Map<bool?, String> supportedAnswers = {true: "Yes/True", false: "No/False", null: ""};
      dataContent.add(DropdownButtonHideUnderline(child:
        DropdownButton<bool?>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems<bool?>(supportedAnswers),
          value: (_data as SurveyQuestionTrueFalse).correctAnswer,
          onChanged: _onChangeCorrectAnswer,
          dropdownColor: Styles().colors?.getColor('surface'),
        ),
      ));
    } else if (_data is SurveyQuestionMultipleChoice) {
      // style
      dataContent.add(DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems<String>(SurveyQuestionMultipleChoice.supportedStyles),
          value: (_data as SurveyQuestionMultipleChoice).style ?? SurveyQuestionMultipleChoice.supportedStyles.entries.first.key,
          onChanged: _onChangeStyle,
          dropdownColor: Styles().colors?.getColor('surface'),
        ),
      ));

      // options
      dataContent.add(_buildCollapsibleWrapper('Options', (_data as SurveyQuestionMultipleChoice).options.length, _buildOptionsWidget));
      
      // allowMultiple
      dataContent.add(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("Multiple Answers", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
        Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: (_data as SurveyQuestionMultipleChoice).allowMultiple,
          onChanged: _onToggleMultipleAnswers,
        ),
      ],));
      // selfScore
      dataContent.add(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("Self-Score", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
        Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: (_data as SurveyQuestionMultipleChoice).selfScore,
          onChanged: _onToggleSelfScore,
        ),
      ],));
    } else if (_data is SurveyQuestionDateTime) {
      // "date_time"
                // optional DateTime startTime (datetime picker?)
                // optional DateTime endTime (datetime picker?)
                // askTime flag
    } else if (_data is SurveyQuestionNumeric) {
      // style
      dataContent.add(DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems<String>(SurveyQuestionNumeric.supportedStyles),
          value: (_data as SurveyQuestionNumeric).style ?? SurveyQuestionNumeric.supportedStyles.entries.first.key,
          onChanged: _onChangeStyle,
          dropdownColor: Styles().colors?.getColor('surface'),
        ),
      ));
      // "numeric"
                // optional minimum
                // optional maximum
                // wholeNum flag
                // selfScore (default to survey scored flag)
    } else if (_data is SurveyQuestionText) {
      // "text"
                // minLength
                // optional maxLength
    } else if (_data is SurveyDataResult) {
      // actions
      dataContent.add(_buildCollapsibleWrapper('Actions', (_data as SurveyDataResult).actions?.length ?? 0, _buildActionsWidget));
    } else {
      //TODO: return widget with invalid survey data message
    }
    //TODO: add SurveyDataPage and SurveyDataEntry later


    List<Widget> baseContent = [
      //key*
      FormFieldText('Key', controller: _textControllers["key"], multipleLines: false, inputType: TextInputType.text, required: true),
      //question text*
      FormFieldText('Question Text', controller: _textControllers["text"], multipleLines: false, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences, required: true),
      //more info (Additional Info)
      FormFieldText('Additional Info', controller: _textControllers["more_info"], multipleLines: false, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences,),
      //section
      FormFieldText('Section', controller: _textControllers["section"], multipleLines: false, inputType: TextInputType.text,),
      //maximum score (number, show if survey is scored)
      FormFieldText('Maximum Score', controller: _textControllers["maximum_score"], multipleLines: false, inputType: TextInputType.number,),
      //defaultFollowUpKey (defaults to next data in list if unspecified)
      FormFieldText('Next Question Key', controller: _textControllers["default_follow_up_key"], multipleLines: false, inputType: TextInputType.text,),

      // data type
      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems<String>(SurveyData.supportedTypes),
          value: SurveyData.supportedTypes.entries.first.key,
          onChanged: _onChangeType,
          dropdownColor: Styles().colors?.textBackground,
        ),
      ),

      // allowSkip
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("Required", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
        Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: !_data.allowSkip,
          onChanged: (value) => _onToggleRequired(value),
        ),
      ],),
      
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

      // type specific data
      ...dataContent,

      // defaultResponseRule (assume follow ups go in order given (populate defaultFollowUpKey fields "onCreate"))
      // _buildRuleWidget(0, "$textGroup.default_response_rule"),
      // followUpRule (overrides display ordering)
      // _buildRuleWidget(0, "$textGroup.follow_up_rule"),
      // scoreRule (show entry if survey is scored)
      // _buildRuleWidget(0, "$textGroup.score_rule"),
    ];

    return Column(children: baseContent,);
  }

  Widget _buildOptionsWidget(int index, String textGroup) {
    String title = (_data as SurveyQuestionMultipleChoice).options[index].title;
    return Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        title: Text(
          title.isNotEmpty ? title : (_data as SurveyQuestionMultipleChoice).options[index].value ?? "New Option",
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
        ),
        trailing: _buildAddRemoveButtons(index + 1, textGroup),
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          _buildOptionsItemWidget(index),
        ],
      ),
    );
  }

  Widget _buildOptionsItemWidget(int index) {
    _textControllers["options$index.title"] ??= TextEditingController();
    _textControllers["options$index.title"]!.text = (_data as SurveyQuestionMultipleChoice).options[index].title;
    _textControllers["options$index.hint"] ??= TextEditingController();
    _textControllers["options$index.hint"]!.text = (_data as SurveyQuestionMultipleChoice).options[index].hint ?? "";
    _textControllers["options$index.value"] ??= TextEditingController();
    _textControllers["options$index.value"]!.text = (_data as SurveyQuestionMultipleChoice).options[index].value.toString();
    _textControllers["options$index.score"] ??= TextEditingController();
    _textControllers["options$index.score"]!.text = (_data as SurveyQuestionMultipleChoice).options[index].score?.toString() ?? "";
    return Column(children: [
      //title*
      FormFieldText('Title', padding: const EdgeInsets.symmetric(vertical: 4.0), controller: _textControllers["options$index.title"], multipleLines: false, inputType: TextInputType.text, required: true),
      //hint
      FormFieldText('Hint', padding: const EdgeInsets.symmetric(vertical: 4.0), controller: _textControllers["options$index.hint"], multipleLines: false, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),
      //value* (dynamic value = _value ?? title)
      FormFieldText('Value', padding: const EdgeInsets.symmetric(vertical: 4.0), controller: _textControllers["options$index.value"], multipleLines: false, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences, required: true),
      //score
      FormFieldText('Score', padding: const EdgeInsets.symmetric(vertical: 4.0), controller: _textControllers["options$index.score"], multipleLines: false, inputType: TextInputType.text,),
    ],);
  }

  Widget _buildActionsWidget(int index) {
    // optional ActionData actions (null for "pure info")
    _textControllers["actions$index.label"] ??= TextEditingController();
    _textControllers["actions$index.label"]!.text = (_data as SurveyDataResult).actions![index].label ?? "";
    return Column(children: [
      //type*
      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems<String>(_supportedActions),
          value: (_data as SurveyDataResult).actions![index].type.name,
          onChanged: (value) => _onChangeAction(index, value),
          dropdownColor: Styles().colors?.getColor('surface'),
        ),
      ),
      //label
      FormFieldText('Label', padding: const EdgeInsets.symmetric(vertical: 4.0), controller: _textControllers["actions$index.label"], multipleLines: false, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),
      //TODO
        // dynamic data
        // Map<String, dynamic> params
    ],);
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
        child: Align(alignment: Alignment.center, child: Text(item.value, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)),
      ));
    }
    return items;
  }

  void _onTapAddDataAtIndex(int index, String textGroup) {
    if (mounted) {
      if (textGroup.contains("options")) {
        //TODO
      } else if (textGroup.contains("correct_answers")) {
        //TODO
      } else if (textGroup.contains("actions")) {
        //TODO
        // "params"
      }
    }
  }

  void _onTapRemoveDataAtIndex(int index, String textGroup) {
    //TODO
    // if (mounted) {
    //   SurveyData insert;
    //   if (index > 0) {
    //     insert = SurveyData.fromOther(_data[index-1]);
    //     insert.key = "$textGroup$index";
    //     insert.text = "New survey data";
    //     insert.defaultFollowUpKey = index == _data.length ? null : _data.key;
    //   } else {
    //     insert = SurveyQuestionTrueFalse(text: "New True/False Question", key: "$textGroup$index");
    //   }
    //   setState(() {
    //     _data.insert(index, insert);
    //     if (index > 0 && _data[index-1].followUpRule == null) {
    //       _data[index-1].defaultFollowUpKey = "$textGroup$index";
    //     }
    //     //TODO: how to update follow up rules?
    //   });
    // }
  }

  void _onChangeType(String? type) {
    _updateState(() {
      switch (type) {
        case "survey_data.true_false":
          _data = SurveyQuestionTrueFalse(text: _data.text, key: _data.key);
          break;
        case "survey_data.multiple_choice":
          _data = SurveyQuestionMultipleChoice(text: _data.text, key: _data.key, options: []);
          break;
        case "survey_data.date_time":
          _data = SurveyQuestionDateTime(text: _data.text, key: _data.key);
          break;
        case "survey_data.numeric":
          _data = SurveyQuestionNumeric(text: _data.text, key: _data.key);
          break;
        case "survey_data.text":
          _data = SurveyQuestionText(text: _data.text, key: _data.key);
          break;
        case "survey_data.result":
          _data = SurveyDataResult(text: _data.text, key: _data.key);
          break;
      }
    });
  }

  void _onChangeStyle(String? style) {
    //TODO
  }

  void _onChangeCorrectAnswer(bool? answer) {
    _updateState(() {
      (_data as SurveyQuestionTrueFalse).correctAnswer = answer;
    });
  }

  void _onChangeAction(int index, String? action) {
    _updateState(() {
      (_data as SurveyDataResult).actions![index].type = action != null ? ActionType.values.byName(action) : ActionType.none;
    });
  }

  void _onToggleRequired(bool? value) {
    _updateState(() {
      _data.allowSkip = value ?? false;
    });
  }

  // void _onToggleReplace(bool? value) {
  //   _updateState(() {
  //     _data.replace = value ?? false;
  //   });
  // }

  void _onToggleMultipleAnswers(bool? value) {
    _updateState(() {
      (_data as SurveyQuestionMultipleChoice).allowMultiple = value ?? false;
    });
  }

  void _onToggleSelfScore(bool? value) {
    _updateState(() {
      (_data as SurveyQuestionMultipleChoice).selfScore = value ?? false;
    });
  }

  void _onTapDone() {
    _data.key = _textControllers["key"]!.text;
    _data.text = _textControllers["text"]!.text;
    _data.moreInfo = _textControllers["more_info"]!.text.isNotEmpty ? _textControllers["more_info"]!.text : null;
    _data.section = _textControllers["section"]!.text.isNotEmpty ? _textControllers["section"]!.text : null;
    _data.maximumScore = num.tryParse(_textControllers["maximum_score"]!.text);
    //TODO: use dropdown for this (or some more convenient way of using default ordering or referencing other survey data)
    _data.defaultFollowUpKey = _textControllers["default_follow_up_key"]!.text;
    Navigator.of(context).pop(_data);
  }

  //TODO: use these for SurveyQuestionDateTime
  // void _onStartDateTap() {
  //   DateTime initialDate = _startDate ?? DateTime.now();
  //   DateTime firstDate =
  //   DateTime.fromMillisecondsSinceEpoch(initialDate.millisecondsSinceEpoch)
  //       .add(Duration(days: -365));
  //   DateTime lastDate =
  //   DateTime.fromMillisecondsSinceEpoch(initialDate.millisecondsSinceEpoch)
  //       .add(Duration(days: 365));
  //   showDatePicker(
  //     context: context,
  //     firstDate: firstDate,
  //     lastDate: lastDate,
  //     initialDate: initialDate,
  //     builder: (BuildContext context, Widget? child) {
  //       return Theme(
  //         data: ThemeData.light(),
  //         child: child!,
  //       );
  //     },
  //   ).then((selectedDateTime) => _onStartDateChanged(selectedDateTime));
  // }

  // void _onStartDateChanged(DateTime? startDate) {
  //   if(mounted) {
  //     setState(() {
  //       _startDate = startDate;
  //     });
  //   }
  // }

  // void _onTapPickReminderTime() {
  //   if (_loading) {
  //     return;
  //   }
  //   TimeOfDay initialTime = TimeOfDay(hour: _reminderDateTime.hour, minute: _reminderDateTime.minute);
  //   showTimePicker(context: context, initialTime: initialTime).then((resultTime) {
  //     if (resultTime != null) {
  //       _reminderDateTime =
  //           DateTime(_reminderDateTime.year, _reminderDateTime.month, _reminderDateTime.day, resultTime.hour, resultTime.minute);
  //       _updateState();
  //     }
  //   });
  // }

  void _updateState(Function() fn) {
    if (mounted) {
      setState(() {
        fn();
      });
    }
  }
}