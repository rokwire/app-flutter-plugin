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
  final Map<String, Rule> _subRules = {};
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
      _buildCollapsibleWrapper("Constants", "constants", _constants.length, _buildStringEntryWidget),
      // strings
      _buildCollapsibleWrapper("Strings", "strings", _strings.length, _buildStringMapWidget),
      // result_rules
      _buildCollapsibleWrapper("Result Rules", "result_rules", _resultRules?.length ?? 0, _buildRuleWidget),
      // sub_rules
      _buildCollapsibleWrapper("Sub Rules", "sub_rules", _subRules.length, _buildRuleWidget),
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
              ) : _buildAddRemoveButtons(0, "response_keys"),
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
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Stack(children: [
        Visibility(visible: _loading, child: LoadingBuilder.loading()),
        RoundedButton(
          label: 'Continue',
          borderColor: Styles().colors?.fillColorSecondary,
          backgroundColor: Styles().colors?.surface,
          textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
          onTap: _onTapContinue,
        ),
      ])),
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

  Widget _buildStringEntryWidget(int index, String textGroup) {
    
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      FormFieldText('Key', controller: _textControllers["$textGroup$index.key"], inputType: TextInputType.text, required: true),
      FormFieldText('Value', controller: _textControllers["$textGroup$index.value"], inputType: TextInputType.text, required: true),
      _buildAddRemoveButtons(index, textGroup),
    ]);
  }

  Widget _buildStringMapWidget(int index, String textGroup) {
    // language code
              // unique ID: string
    Map<String, String> supportedLangs = {};
    for (String lang in Localization().defaultSupportedLanguages) {
      supportedLangs[lang] = lang;
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
            items: _buildSurveyDropDownItems(supportedLangs),
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
            child: Scrollbar(
              child: _buildStringEntryWidget(index, textGroup),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRemoveButtons(int index, String textGroup) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      IconButton(icon: Styles().images?.getImage('plus-circle', color: Styles().colors?.getColor('surface')) ?? const Icon(Icons.add), onPressed: () => _onTapAddDataAtIndex(index, textGroup),),
      IconButton(icon: Styles().images?.getImage('minus-circle', color: Styles().colors?.getColor('alert')) ?? const Icon(Icons.add), onPressed: () => _onTapRemoveDataAtIndex(index, textGroup),),
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
          items: _buildSurveyDropDownItems(SurveyQuestionTrueFalse.supportedStyles),
          value: SurveyQuestionTrueFalse.supportedStyles.entries.first.key,
          onChanged: (_) => _onChangeSurveyDataStyle(index),
          dropdownColor: Styles().colors?.textBackground,
        ),
      ));
      // "true_false"
                // correct answer (dropdown: Yes/True, No/False, null)
    } else if (_data[index] is SurveyQuestionMultipleChoice) {
      // style
      dataContent.add(DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems(SurveyQuestionMultipleChoice.supportedStyles),
          value: SurveyQuestionMultipleChoice.supportedStyles.entries.first.key,
          onChanged: (_) => _onChangeSurveyDataStyle(index),
          dropdownColor: Styles().colors?.textBackground,
        ),
      ));
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
      dataContent.add(DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDropDownItems(SurveyQuestionNumeric.supportedStyles),
          value: SurveyQuestionNumeric.supportedStyles.entries.first.key,
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
          items: _buildSurveyDropDownItems(supportedActions),
          value: supportedActions.entries.first.key,
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
      _buildRuleWidget(0, "$textGroup.default_response_rule"),
      // followUpRule (overrides display ordering)
      _buildRuleWidget(0, "$textGroup.follow_up_rule"),
      // scoreRule (show entry if survey is scored)
      _buildRuleWidget(0, "$textGroup.score_rule"),
    ];
    dataContent.addAll(baseContent);

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

  void _onTapRemoveDataAtIndex(int index, String textGroup) {
    //TODO
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
}