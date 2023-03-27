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
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widget_builders/loading.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class SurveyCreationPanel extends StatefulWidget {
  final Function(SurveyResponse?)? onComplete;
  final Widget? tabBar;
  final Widget? offlineWidget;

  const SurveyCreationPanel({Key? key, this.onComplete, this.tabBar, this.offlineWidget}) : super(key: key);

  @override
  _SurveyCreationPanelState createState() => _SurveyCreationPanelState();
}

class _SurveyCreationPanelState extends State<SurveyCreationPanel> {
  GlobalKey? dataKey;

  bool _loading = false;
  final ScrollController _scrollController = ScrollController();
  late final Map<String, TextEditingController> _textControllers;

  final List<SurveyData> _data = [];
  bool _scored = true;
  // bool _sensitive = false;

  final Map<String, String> _constants = {};
  final Map<String, Map<String, String>> _strings = {};

  Rule? _defaultDataKeyRule;
  List<Rule>? _resultRules;
  final Map<String, Rule> _subRules = {};
  List<String>? _responseKeys;

  @override
  void initState() {
    _textControllers = {
      "title": TextEditingController(),
      "more_info": TextEditingController(),
      "type": TextEditingController(),
      "default_data_key": TextEditingController(),
    };
    super.initState();
  }

  @override
  void dispose() {
    _textControllers.forEach((_, value) { value.dispose(); });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderBar(title: "Create Survey"),
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
              child: _buildSurveyCreationTools(),
            ),
          )),
          Container(
            color: Styles().colors?.backgroundVariant,
            child: _buildPreviewAndContinue(),
          ),
        ],
    ));
  }

  Widget _buildSurveyCreationTools() {
    return Column(children: [
      // title
      FormFieldText('Title', controller: _textControllers["title"], inputType: TextInputType.text, textCapitalization: TextCapitalization.words, required: true),
      // more_info
      FormFieldText('Additional Information', controller: _textControllers["more_info"], multipleLines: true, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),
      // survey type (make this a dropdown?)
      FormFieldText('Type', controller: _textControllers["type"], multipleLines: false, inputType: TextInputType.text, textCapitalization: TextCapitalization.words, required: true),

      // data
      _buildCollapsibleWrapper("Survey Data", "data", _data.length, _buildSurveyDataWidget),

      // scored
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("Scored", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
        Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: _scored,
          onChanged: _onToggleScored,
        ),
      ],),
      
      // sensitive
      // Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      //   Text("Scored", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
      //   Checkbox(
      //     checkColor: Styles().colors?.surface,
      //     activeColor: Styles().colors?.fillColorPrimary,
      //     value: _sensitive,
      //     onChanged: _onToggleSensitive,
      //   ),
      // ],),

      // default data key (i.e., first "question") -> assume first data widget represents first question
      FormFieldText('First Item', controller: _textControllers["default_data_key"], multipleLines: false, inputType: TextInputType.text,),

      // default data key rule (i.e., rule for determining first "question") -> checkbox to use rule to determine first question, when checked shows UI to create rule
      _buildRuleWidget(0, "default_data_key_rule"),

      // constants
      _buildCollapsibleWrapper("Constants", "constants", _constants.length, _buildStringMapEntryWidget),
      // strings
      _buildCollapsibleWrapper("Strings", "strings", _strings.length, _buildStringMapWidget),
      // result_rules
      _buildCollapsibleWrapper("Result Rules", "result_rules", _resultRules?.length ?? 0, _buildRuleWidget),
      // sub_rules
      _buildCollapsibleWrapper("Sub Rules", "sub_rules", _subRules.length, _buildRuleWidget),
      // response_keys
      _buildCollapsibleWrapper("Response Keys", "response_keys", _responseKeys?.length ?? 0, _buildStringListEntryWidget),
    ],);
  }

  Widget _buildPreviewAndContinue() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
        label: 'Preview',
        borderColor: Styles().colors?.fillColorPrimaryVariant,
        backgroundColor: Styles().colors?.surface,
        textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
        onTap: _onTapPreview,
      ))),
      Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: Stack(children: [
        Visibility(visible: _loading, child: LoadingBuilder.loading()),
        RoundedButton(
          label: 'Continue',
          borderColor: Styles().colors?.fillColorSecondary,
          backgroundColor: Styles().colors?.surface,
          textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
          onTap: _onTapContinue,
        ),
      ]))),
    ],);
  }

  Widget _buildCollapsibleWrapper(String label, String textGroup, int dataLength, Widget Function(int, String) listItemBuilder) {
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
            child: dataLength > 0 ? Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: dataLength,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      listItemBuilder(index, textGroup),
                      Container(height: 1, color: Styles().colors?.getColor('dividerLine'),),
                    ],
                  );
                },
              ),
            ) : _buildAddRemoveButtons(0, textGroup),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyDataWidget(int index, String textGroup) {
    return Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        title: Text(
          _data[index].key,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
        ),
        trailing: _buildAddRemoveButtons(index + 1, textGroup),
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500
            ),
            child: Scrollbar(
              child: _buildSurveyDataComponents(index, textGroup),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleWidget(int index, String textGroup) {
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

  Widget _buildStringListEntryWidget(int index, String textGroup) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      FormFieldText('Value', controller: _textControllers["$textGroup$index.value"], inputType: TextInputType.text, required: true),
      _buildAddRemoveButtons(index, textGroup),
    ]);
  }

  Widget _buildStringMapEntryWidget(int index, String textGroup) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      FormFieldText('Key', controller: _textControllers["$textGroup$index.key"], inputType: TextInputType.text, required: true),
      FormFieldText('Value', controller: _textControllers["$textGroup$index.value"], inputType: TextInputType.text, required: true),
      _buildAddRemoveButtons(index, textGroup),
    ]);
  }

  Widget _buildStringMapWidget(int index, String textGroup) {
    Map<String, String> supportedLangs = {};
    for (String lang in Localization().defaultSupportedLanguages) {
      if (_strings[lang] == null) {
        supportedLangs[lang] = lang;
      }
    }

    return Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        title: Text(
          _data[index].key,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
        ),
        leading: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildSurveyDropDownItems<String>(supportedLangs),
            value: supportedLangs.entries.first.key,
            onChanged: (_) => _onChangeSurveyDataStyle(index),
            dropdownColor: Styles().colors?.textBackground,
          ),
        ),
        trailing: _buildAddRemoveButtons(index + 1, textGroup),
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500
            ),
            // child: dataLength > 0 ? Scrollbar(
            //   child: ListView.builder(
            //     shrinkWrap: true,
            //     itemCount: dataLength,
            //     itemBuilder: (BuildContext context, int index) {
            //       return Column(
            //         children: [
            //           listItemBuilder(index, textGroup),
            //           Container(height: 1, color: Styles().colors?.getColor('dividerLine'),),
            //         ],
            //       );
            //     },
            //   ),
            // ) : _buildAddRemoveButtons(0, textGroup),
            child: Scrollbar(
              child: _buildStringMapEntryWidget(index, textGroup),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildSurveyDataComponents(int index, String textGroup) {
    //TODO: determine widget order for survey data
    List<Widget> dataContent = [];
    if (_data[index] is SurveyQuestionTrueFalse) {
      // style
      dataContent.add(DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems<String>(SurveyQuestionTrueFalse.supportedStyles),
          value: (_data[index] as SurveyQuestionTrueFalse).style ?? SurveyQuestionTrueFalse.supportedStyles.entries.first.key,
          onChanged: (_) => _onChangeSurveyDataStyle(index),
          dropdownColor: Styles().colors?.textBackground,
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
          value: (_data[index] as SurveyQuestionTrueFalse).correctAnswer,
          onChanged: (_) => _onChangeSurveyDataStyle(index),
          dropdownColor: Styles().colors?.textBackground,
        ),
      ));
    } else if (_data[index] is SurveyQuestionMultipleChoice) {
      // style
      dataContent.add(DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems<String>(SurveyQuestionMultipleChoice.supportedStyles),
          value: (_data[index] as SurveyQuestionMultipleChoice).style ?? SurveyQuestionMultipleChoice.supportedStyles.entries.first.key,
          onChanged: (_) => _onChangeSurveyDataStyle(index),
          dropdownColor: Styles().colors?.textBackground,
        ),
      ));
      dataContent.add(_buildCollapsibleWrapper('Options', "$textGroup$index.options", (_data[index] as SurveyQuestionMultipleChoice).options.length, _buildOptionDataWidget));
      // "multiple_choice"
                // OptionData options
                    // title;
                    // optional hint;
                    // dynamic value (value = _value ?? title);
                    // optional score;
      // correctAnswers
      dataContent.add(_buildCollapsibleWrapper('Correct Answer(s)', "$textGroup$index.correct_answers", (_data[index] as SurveyQuestionMultipleChoice).correctAnswers?.length ?? 0, _buildStringListEntryWidget));
      // allowMultiple
      dataContent.add(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("Multiple Answers", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
        Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: (_data[index] as SurveyQuestionMultipleChoice).allowMultiple,
          onChanged: (value) => _onToggleMultipleAnswers(value, index),
        ),
      ],));
      // selfScore
      dataContent.add(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("Self-Score", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
        Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: (_data[index] as SurveyQuestionMultipleChoice).selfScore,
          onChanged: (value) => _onToggleSelfScore(value, index),
        ),
      ],));
    } else if (_data[index] is SurveyQuestionDateTime) {
      // "date_time"
                // optional DateTime startTime (datetime picker?)
                // optional DateTime endTime (datetime picker?)
                // askTime flag
    } else if (_data[index] is SurveyQuestionNumeric) {
      // style
      dataContent.add(DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems<String>(SurveyQuestionNumeric.supportedStyles),
          value: (_data[index] as SurveyQuestionNumeric).style ?? SurveyQuestionNumeric.supportedStyles.entries.first.key,
          onChanged: (_) => _onChangeSurveyDataStyle(index),
          dropdownColor: Styles().colors?.textBackground,
        ),
      ));
      // "numeric"
                // optional minimum
                // optional maximum
                // wholeNum flag
                // selfScore (default to survey scored flag)
    } else if (_data[index] is SurveyQuestionText) {
      // "text"
                // minLength
                // optional maxLength
    } else if (_data[index] is SurveyDataResult) {
      // "result"
      Map<String, String> supportedActions = {};
      for (ActionType action in ActionType.values) {
        //TODO: better name formatting for SurveyDataResult actions
        supportedActions[action.name] = action.name;
      }

      dataContent.add(DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems<String>(supportedActions),
          value: supportedActions.entries.first.key, //TODO
          onChanged: (_) => _onChangeSurveyDataAction(index),
          dropdownColor: Styles().colors?.textBackground,
        ),
      ));
      // optional ActionData actions (null for "pure info")
          // type (launchUri, showSurvey, showPanel, dismiss, none) -> ActionType.values? ActionType.values
          // optional label
          // dynamic data
          // Map<String, dynamic> params
    } else {
      //TODO: return widget with invalid survey data message
    }
    //TODO: add SurveyDataPage and SurveyDataEntry later


    _textControllers["$textGroup$index.key"] ??= TextEditingController();
    _textControllers["$textGroup$index.text"] ??= TextEditingController();
    _textControllers["$textGroup$index.more_info"] ??= TextEditingController();
    _textControllers["$textGroup$index.section"] ??= TextEditingController();
    _textControllers["$textGroup$index.maximum_score"] ??= TextEditingController();
    _textControllers["$textGroup$index.default_follow_up_key"] ??= TextEditingController();
    List<Widget> baseContent = [
      //key*
      FormFieldText('Key', controller: _textControllers["$textGroup$index.key"], multipleLines: false, inputType: TextInputType.text, required: true),
      //question text*
      FormFieldText('Question Text', controller: _textControllers["$textGroup$index.text"], multipleLines: false, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences, required: true),
      //more info (Additional Info)
      FormFieldText('Additional Info', controller: _textControllers["$textGroup$index.more_info"], multipleLines: false, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences,),
      //section
      FormFieldText('Section', controller: _textControllers["$textGroup$index.section"], multipleLines: false, inputType: TextInputType.text,),
      //maximum score (number, show if survey is scored)
      FormFieldText('Maximum Score', controller: _textControllers["$textGroup$index.maximum_score"], multipleLines: false, inputType: TextInputType.number,),
      //defaultFollowUpKey (defaults to next data in list if unspecified)
      FormFieldText('Next Question Key', controller: _textControllers["$textGroup$index.default_follow_up_key"], multipleLines: false, inputType: TextInputType.text,),

      // data type
      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems<String>(SurveyData.supportedTypes),
          value: SurveyData.supportedTypes.entries.first.key,
          onChanged: (type) => _onChangeSurveyDataType(index, textGroup, type),
          dropdownColor: Styles().colors?.textBackground,
        ),
      ),

      // allowSkip
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("Required", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
        Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: !_data[index].allowSkip,
          onChanged: (value) => _onToggleRequired(value, index),
        ),
      ],),
      
      // replace
      // Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      //   Text("Scored", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
      //   Checkbox(
      //     checkColor: Styles().colors?.surface,
      //     activeColor: Styles().colors?.fillColorPrimary,
      //     value: _data[index].replace,
      //     onChanged: (value) => _onToggleReplace(value, index),
      //   ),
      // ],),

      // type specific data
      ...dataContent,

      // defaultResponseRule (assume follow ups go in order given (populate defaultFollowUpKey fields "onCreate"))
      _buildRuleWidget(0, "$textGroup.default_response_rule"),
      // followUpRule (overrides display ordering)
      _buildRuleWidget(0, "$textGroup.follow_up_rule"),
      // scoreRule (show entry if survey is scored)
      _buildRuleWidget(0, "$textGroup.score_rule"),
    ];

    return Column(children: dataContent,);
  }

  Widget _buildOptionDataWidget(int index, String textGroup) {
    //TODO
    return Container();
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

  //TODO: this causes some UI exceptions
  void _onTapAddDataAtIndex(int index, String textGroup) {
    if (mounted) {
      SurveyData insert;
      if (index > 0) {
        insert = SurveyData.fromOther(_data[index-1]);
        insert.key = "$textGroup$index";
        insert.text = "New survey data";
        insert.defaultFollowUpKey = index == _data.length ? null : _data[index].key;
      } else {
        insert = SurveyQuestionTrueFalse(text: "New True/False Question", key: "$textGroup$index");
      }
      setState(() {
        _data.insert(index, insert);
        if (index > 0 && _data[index-1].followUpRule == null) {
          _data[index-1].defaultFollowUpKey = "$textGroup$index";
        }
        //TODO: how to update follow up rules?
      });
    }
  }

// final Map<String, String> _constants = {};
//   final Map<String, Map<String, String>> _strings = {};

//   List<Rule>? _resultRules;
//   final Map<String, Rule> _subRules = {};
//   List<String>? _responseKeys;
  void _addDataToConstants(int index, String textGroup) {
    if (mounted) {
      setState(() {
        _constants["$textGroup$index"] = "";
      });
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
    //     insert.defaultFollowUpKey = index == _data.length ? null : _data[index].key;
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

  void _onChangeSurveyDataType(int index, String textGroup, String? type) {
    if (mounted) {
      setState(() {
        switch (type) {
          case "survey_data.true_false":
            _data[index] = SurveyQuestionTrueFalse(text: "New True/False Question", key: "$textGroup$index");
            break;
          case "survey_data.multiple_choice":
            _data[index] = SurveyQuestionMultipleChoice(text: "New Multiple Choice Question", key: "$textGroup$index", options: []);
            break;
          case "survey_data.date_time":
            _data[index] = SurveyQuestionDateTime(text: "New Date/Time Question", key: "$textGroup$index");
            break;
          case "survey_data.numeric":
            _data[index] = SurveyQuestionNumeric(text: "New Numeric Question", key: "$textGroup$index");
            break;
          case "survey_data.text":
            _data[index] = SurveyQuestionText(text: "New Text Question", key: "$textGroup$index");
            break;
          case "survey_data.result":
            _data[index] = SurveyDataResult(text: "New Info/Action", key: "$textGroup$index");
            break;
        }
      });
    }
  }

  void _onChangeSurveyDataStyle(int index) {
    //TODO
  }

  void _onChangeSurveyDataAction(int index) {
    //TODO
  }

  void _onToggleScored(bool? value) {
    if (mounted) {
      setState(() {
        _scored = value ?? true;
      });
    }
  }

  // void _onToggleSensitive(bool? value) {
  //   if (mounted) {
  //     setState(() {
  //       _sensitive = value ?? false;
  //     });
  //   }
  // }

  void _onToggleRequired(bool? value, int index) {
    if (mounted) {
      setState(() {
        _data[index].allowSkip = value ?? false;
      });
    }
  }

  // void _onToggleReplace(bool? value, int index) {
  //   if (mounted) {
  //     setState(() {
  //       _data[index].replace = value ?? false;
  //     });
  //   }
  // }

  void _onToggleMultipleAnswers(bool? value, int index) {
    if (mounted) {
      setState(() {
        (_data[index] as SurveyQuestionMultipleChoice).allowMultiple = value ?? false;
      });
    }
  }

  void _onToggleSelfScore(bool? value, int index) {
    if (mounted) {
      setState(() {
        (_data[index] as SurveyQuestionMultipleChoice).selfScore = value ?? false;
      });
    }
  }
  
  Survey _buildSurvey() {
    return Survey(
      id: '',
      data: Map.fromIterable(_data, key: (item) => (item as SurveyData).key),
      type: _textControllers["type"]?.text ?? 'survey',
      scored: _scored,
      title: _textControllers["title"]?.text ?? 'New Survey',
      moreInfo: _textControllers["more_info"]?.text,
      defaultDataKey: _textControllers["default_data_key"]?.text ?? (_defaultDataKeyRule == null && _data.isNotEmpty ? _data.first.key : null),
      defaultDataKeyRule: _defaultDataKeyRule,
      resultRules: _resultRules,
      responseKeys: _responseKeys,
      constants: _constants,
      strings: _strings,
      subRules: _subRules,
    );
  }

  void _onTapPreview() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: _buildSurvey(), inputEnabled: false)));
  }

  void _onTapContinue() {
    setLoading(true);
    Surveys().createSurvey(_buildSurvey()).then((success) {
      setLoading(false);
      if (success != true) {
        PopupMessage.show(context: context,
          title: "Create Survey",
          message: "Survey creation failed",
          buttonTitle: Localization().getStringEx("dialog.ok.title", "OK")
        );
      }
    });
  }

  void setLoading(bool value) {
    if (mounted) {
      setState(() {
        _loading = value;
      });
    }
  }

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
}