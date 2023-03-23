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
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/survey.dart';

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
  late final SurveyWidgetController _surveyController;
  late final Map<String, TextEditingController> _textControllers;

  final List<SurveyData> _data = [];
  bool _scored = true;
  // bool _sensitive = false;

  final Map<String, String> _constants = {};
  final Map<String, Map<String, String>> _strings = {};

  Rule? _defaultDataKeyRule;
  List<Rule>? _resultRules;
  List<Rule>? _subRules;
  List<String>? _responseKeys;

  @override
  void initState() {
    _surveyController = SurveyWidgetController(onComplete: widget.onComplete);
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
            child: Column(children: [
              SingleChildScrollView(
                controller: _scrollController,
                child: Column(children: [
                  _buildSurveyCreationTools(),
                ]),
              ),
              _buildPreviewAndContinue(),
            ]
          ))),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: SurveyWidget.buildContinueButton(_surveyController),
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
      _buildCollapsibleWrapper(_data.length, _buildSurveyDataWidget),

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
      _buildRuleWidget(0),

      // constants
      _buildCollapsibleWrapper(_constants.length, _buildStringMapWidget),
      // strings
      _buildCollapsibleWrapper(_strings.length, _buildStringsWidget),
      // result_rules
      _buildCollapsibleWrapper(_resultRules?.length ?? 0, _buildRuleWidget),
      // sub_rules
      _buildCollapsibleWrapper(_subRules?.length ?? 0, _buildRuleWidget),
      // response_keys
      Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: ExpansionTile(
          iconColor: Styles().colors?.getColor('fillColorSecondary'),
          backgroundColor: Styles().colors?.getColor('surface'),
          collapsedBackgroundColor: Styles().colors?.getColor('surface'),
          title: Text(
            "Response Keys",
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          ),
          children: <Widget>[
            Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 500
              ),
              child: (_responseKeys?.length ?? 0) > 0 ? Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _responseKeys!.length,
                  itemBuilder: (BuildContext context, int index) {
                    _textControllers["response_keys$index"] ??= TextEditingController();
                    return Column(
                      children: [
                        FormFieldText('', controller: _textControllers["response_keys$index"], multipleLines: false, inputType: TextInputType.text, padding: EdgeInsets.zero),
                        Container(height: 1, color: Styles().colors?.getColor('dividerLine'),),
                      ],
                    );
                  },
                ),
              ) : _buildAddDataButton(0),
            ),
          ],
        ),
      )
    ],);
  }

  Widget _buildPreviewAndContinue() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: RoundedButton(
        label: 'Preview',
        borderColor: Styles().colors?.fillColorPrimaryVariant,
        backgroundColor: Styles().colors?.surface,
        textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
        onTap: _onTapPreview,
      )),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: RoundedButton(
        label: 'Continue',
        borderColor: Styles().colors?.fillColorSecondary,
        backgroundColor: Styles().colors?.surface,
        textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
        onTap: _onTapContinue,
      )),
    ],);
  }

  Widget _buildCollapsibleWrapper(int dataLength, Widget Function(int) listItemBuilder) {
    return Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        title: Text(
          "Survey Data",
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
                      listItemBuilder(index),
                      Container(height: 1, color: Styles().colors?.getColor('dividerLine'),),
                    ],
                  );
                },
              ),
            ) : _buildAddDataButton(0),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyDataWidget(int index) {
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
        trailing: _buildAddDataButton(index + 1),
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500
            ),
            child: Scrollbar(
              child: _buildSurveyDataComponents(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleWidget(int index) {
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

  Widget _buildStringMapWidget(int index) {
        // unique ID: value
  }

  Widget _buildStringsWidget(int index) {
    // language code (dropdown for supported languages?) -> Localization().defaultSupportedLanguages
              // unique ID: string
  }

  Widget _buildAddDataButton(int index) {
    return IconButton(icon: Styles().images?.getImage('plus-dark') ?? const Icon(Icons.add), onPressed: () => _onTapAddDataAtIndex(index),);
  }

  Widget _buildSurveyDataComponents(int index) {
    List<Widget> dataContent = [
      //key*
      FormFieldText(),
      //question text*
      FormFieldText(),
      //more info (Additional Info)
      FormFieldText(),
      //section
      FormFieldText(),
      //maximum score (number, show if survey is scored)
      FormFieldText(),
      //defaultFollowUpKey (defaults to next data in list if unspecified)
      FormFieldText(),

      // data type
      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems(SurveyData.supportedTypes),
          value: SurveyData.supportedTypes.entries.first.key,
          onChanged: (_) => _onChangeSurveyDataType(index),
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

      // defaultResponseRule (assume follow ups go in order given (populate defaultFollowUpKey fields "onCreate"))
      _buildRuleWidget(),
      // followUpRule (overrides display ordering)
      _buildRuleWidget(),
      // scoreRule (show entry if survey is scored)
      _buildRuleWidget(),
    ];
    if (_data[index] is SurveyQuestionTrueFalse) {
      // style
      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems(SurveyQuestionTrueFalse.supportedStyles),
          value: SurveyQuestionTrueFalse.supportedStyles.entries.first.key,
          onChanged: (_) => _onChangeSurveyDataStyle(index),
          dropdownColor: Styles().colors?.textBackground,
        ),
      ),
      // "true_false"
                // correct answer (dropdown: Yes/True, No/False, null)
    } else if (_data[index] is SurveyQuestionMultipleChoice) {
      // style
      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems(SurveyQuestionMultipleChoice.supportedStyles),
          value: SurveyQuestionMultipleChoice.supportedStyles.entries.first.key,
          onChanged: (_) => _onChangeSurveyDataStyle(index),
          dropdownColor: Styles().colors?.textBackground,
        ),
      ),
      // "multiple_choice"
                // OptionData options
                    // title;
                    // optional hint;
                    // dynamic value (value = _value ?? title);
                    // optional score;
                // optional correctAnswers
                // allowMultiple answers
                // selfScore (default to survey scored flag)
    } else if (_data[index] is SurveyQuestionDateTime) {
      // "date_time"
                // optional DateTime startTime (datetime picker?)
                // optional DateTime endTime (datetime picker?)
                // askTime flag
    } else if (_data[index] is SurveyQuestionNumeric) {
      // style
      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems(SurveyQuestionNumeric.supportedStyles),
          value: SurveyQuestionNumeric.supportedStyles.entries.first.key,
          onChanged: (_) => _onChangeSurveyDataStyle(index),
          dropdownColor: Styles().colors?.textBackground,
        ),
      ),
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
        supportedActions[action.name] = action.name;
      }

      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems(supportedActions),
          value: supportedActions.entries.first.key,
          onChanged: (_) => _onChangeSurveyDataAction(index),
          dropdownColor: Styles().colors?.textBackground,
        ),
      ),
      // optional ActionData actions (null for "pure info")
          // type (launchUri, showSurvey, showPanel, dismiss, none) -> ActionType.values? ActionType.values
          // optional label
          // dynamic data
          // Map<String, dynamic> params
    } else {
      //TODO: return widget with invalid survey data message
    }

    //TODO: add SurveyDataPage and SurveyDataEntry later
    return Column(children: dataContent,);
  }

  List<DropdownMenuItem<String>> _buildSurveyDropDownItems(Map<String, String> supportedItems) {
    List<DropdownMenuItem<String>> items = [];

    for (MapEntry<String, String> item in supportedItems.entries) {
      items.add(DropdownMenuItem<String>(
        value: item.key,
        child: Align(alignment: Alignment.center, child: Text(item.value, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)),
      ));
    }
    return items;
  }

  void _onTapAddDataAtIndex(int index) {
    if (mounted) {
      SurveyData insert;
      if (index > 0) {
        insert = SurveyData.fromOther(_data[index-1]);
        insert.key = "data$index";
        insert.text = "New survey data";
        insert.defaultFollowUpKey = index == _data.length ? null : _data[index].key;
      } else {
        insert = SurveyQuestionTrueFalse(text: "New True/False Question", key: "data$index");
      }
      setState(() {
        _data.insert(index, insert);
        if (index > 0 && _data[index-1].followUpRule == null) {
          _data[index-1].defaultFollowUpKey = "data$index";
        }
        //TODO: how to update follow up rules?
      });
    }
  }

  void _onChangeSurveyDataType(int index) {
    //TODO
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
  
  Survey _buildSurvey() {
    //TODO: create data map, subRules map
    return Survey(
      id: '',
      data: _data,
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
    //TODO
    // Map<String, SurveyData> 
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: _buildSurvey(), inputEnabled: false)));
  }

  void _onTapContinue() {
    setLoading(true);
    Surveys().createSurvey(_buildSurvey()).then((success) {
      setLoading(false);
      //TODO: if success != true, show error message
    });
  }

  void setLoading(bool value) {
    if (mounted) {
      setState(() {
        _loading = value;
      });
    }
  }
}