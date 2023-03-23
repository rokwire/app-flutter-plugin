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

import 'package:rokwire_plugin/ui/widgets/survey.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';

class SurveyCreationPanel extends StatefulWidget {
  final Function(SurveyResponse?)? onComplete;
  final bool showSummaryOnFinish;
  final bool allowBack;
  final Widget? tabBar;
  final Widget? offlineWidget;

  const SurveyCreationPanel({Key? key, this.showSummaryOnFinish = false, this.allowBack = true, this.onComplete, this.tabBar, this.offlineWidget}) : super(key: key);

  @override
  _SurveyCreationPanelState createState() => _SurveyCreationPanelState();
}

class _SurveyCreationPanelState extends State<SurveyCreationPanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  late final SurveyWidgetController _surveyController;
  late final Map<String, TextEditingController> _textControllers;

  final List<SurveyData> _data = [];
  bool _scored = true;
  // bool _sensitive = false;
  Rule? _defaultDataKeyRule;
  List<Rule>? _resultRules;
  List<String>? _responseKeys;

  @override
  void initState() {
    _surveyController = SurveyWidgetController(onComplete: widget.onComplete);
    _textControllers = {
      "title": TextEditingController(),
      "more_info": TextEditingController(),
      "type": TextEditingController(),
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
          // Visibility(visible: _loading, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors?.fillColorPrimary))),
          Expanded(child: Scrollbar(
            radius: const Radius.circular(2),
            thumbVisibility: true,
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: _buildSurveyCreationTools(),
            ),
          )),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: SurveyWidget.buildContinueButton(_surveyController),
          ),
        ],
    ));

    //TODO:
    // Ability to preview survey being created -> pass survey object to SurveyPanel
  }

  Widget _buildSurveyCreationTools() {
    //TODO: use for required fields
    // Visibility(visible: !survey.allowSkip, child: Text("* ", semanticsLabel: Localization().getStringEx("widget.survey.label.required.hint", "Required"), style: textStyle ?? Styles().textStyles?.getTextStyle('widget.error.regular.fat'))),

    return Column(children: [
      //TODO: TextField
      // title
      FormFieldText('Title', controller: _textControllers["title"], inputType: TextInputType.text, textCapitalization: TextCapitalization.words),
      // more_info
      FormFieldText('Additional Information', controller: _textControllers["more_info"], multipleLines: true, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),
      // survey type
      //TODO: make this a dropdown?
      FormFieldText('Type', controller: _textControllers["type"], multipleLines: false, inputType: TextInputType.text, textCapitalization: TextCapitalization.words),

      // data
      _buildSurveyDataWrapper(),

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
    ],);
    
    // default data key (i.e., first "question") -> assume first data widget represents first question
    // default data key rule (i.e., rule for determining first "question") -> checkbox to use rule to determine first question, when checked shows UI to create rule
    // constants
        // unique ID: value
    // strings
        // language code (dropdown for supported languages?) -> Localization().defaultSupportedLanguages
            // unique ID: string
    // result_rules (list)
        // dropdown for actions
        // dropdown for comparison options
        // dropdown for logic options
        // dropdown for data keys, compare_to options (stats, responses, constants, strings, etc.)
    // sub_rules
    // response_keys? (history?)

    //TODO: "modifiable list widget"
    // Needs to be able to :
        // add to end of list
        // insert at any index in list
        // each entry is collapsible
  }

  Widget _buildSurveyDataWrapper() {
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
            child: _data.isNotEmpty ? Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _data.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      _buildSurveyDataWidget(index),
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

  Widget _buildAddDataButton(int index, {SurveyData? other}) {
    return IconButton(icon: Styles().images?.getImage('plus-dark') ?? const Icon(Icons.add), onPressed: () => _onTapAddDataAtIndex(index),);
  }

  Widget _buildSurveyDataComponents(int index) {
    List<Widget> dataContent = [
      //key*
      TextField(),
      //question text*
      TextField(),
      //more info (Additional Info)
      TextField(),
      //section
      TextField(),
      //maximum score (number, show if survey is scored)
      TextField(),

      // data type
      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDataTypeDropDownItems(),
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

    // data (assume follow ups go in order given (populate defaultFollowUpKey fields "onCreate"))
        // optional defaultResponseRule
        // optional followUpRule (overrides display ordering)
        // optional scoreRule (show entry if survey is scored)

  String? defaultFollowUpKey;
  Rule? defaultResponseRule;
  Rule? followUpRule;
  Rule? scoreRule;
    ];
    if (_data[index] is SurveyQuestionTrueFalse) {
      // style
      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildSurveyDataStyleDropDownItems(_data[index]),
          value: SurveyData.supportedTypes.entries.first.key,
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
          items: _buildSurveyDataStyleDropDownItems(_data[index]),
          value: SurveyData.supportedTypes.entries.first.key,
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
          items: _buildSurveyDataStyleDropDownItems(_data[index]),
          value: SurveyData.supportedTypes.entries.first.key,
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
                // optional ActionData actions (null for "pure info")
                    // type (launchUri, showSurvey, showPanel, dismiss, none) -> ActionType.values?
                    // optional label
                    // dynamic data
                    // Map<String, dynamic> params
    } else {
      //TODO: return widget with invalid survey data message
    }

    //TODO: add SurveyDataPage and SurveyDataEntry later
    return Column(children: dataContent,);
  }

  //TODO: merge dropdown items funcs into one?
  List<DropdownMenuItem<String>> _buildSurveyDataTypeDropDownItems() {
    List<DropdownMenuItem<String>> items = [];

    for (MapEntry<String, String> supportedType in SurveyData.supportedTypes.entries) {
      items.add(DropdownMenuItem<String>(
        value: supportedType.key,
        child: Align(alignment: Alignment.center, child: Text(supportedType.value, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)),
      ));
    }
    return items;
  }

  List<DropdownMenuItem<String>> _buildSurveyDataStyleDropDownItems(SurveyData data) {
    List<DropdownMenuItem<String>> items = [];

    Map<String, String>? supportedStyles;
    if (data is SurveyQuestionTrueFalse) {
      supportedStyles = SurveyQuestionTrueFalse.supportedStyles;
    } else if (data is SurveyQuestionMultipleChoice) {
      supportedStyles = SurveyQuestionTrueFalse.supportedStyles;
    } else if (data is SurveyQuestionNumeric) {
      supportedStyles = SurveyQuestionTrueFalse.supportedStyles;
    }
    for (MapEntry<String, String> supportedType in supportedStyles?.entries ?? []) {
      items.add(DropdownMenuItem<String>(
        value: supportedType.key,
        child: Align(alignment: Alignment.center, child: Text(supportedType.value, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)),
      ));
    }
    return items;
  }

  List<DropdownMenuItem<String>> _buildSurveyDataActionDropDownItems() {
    List<DropdownMenuItem<String>> items = [];

    for (ActionType action in ActionType.values) {
      items.add(DropdownMenuItem<String>(
        value: action.name,
        child: Align(alignment: Alignment.center, child: Text(action.name, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)),
      ));
    }
    return items;
  }

  List<DropdownMenuItem<String>> _buildRuleActionDropDownItems() {
    List<DropdownMenuItem<String>> items = [];

    for (MapEntry<String, String> supportedAction in RuleAction.supportedActions.entries) {
      items.add(DropdownMenuItem<String>(
        value: supportedAction.key,
        child: Align(alignment: Alignment.center, child: Text(supportedAction.value, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)),
      ));
    }
    return items;
  }

  List<DropdownMenuItem<String>> _buildRuleComparisonDropDownItems() {
    List<DropdownMenuItem<String>> items = [];

    for (MapEntry<String, String> operator in RuleComparison.supportedOperators.entries) {
      items.add(DropdownMenuItem<String>(
        value: operator.key,
        child: Align(alignment: Alignment.center, child: Text(operator.value, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)),
      ));
    }
    return items;
  }

  List<DropdownMenuItem<String>> _buildRuleLogicDropDownItems() {
    List<DropdownMenuItem<String>> items = [];

    for (MapEntry<String, String> operator in RuleLogic.supportedOperators.entries) {
      items.add(DropdownMenuItem<String>(
        value: operator.key,
        child: Align(alignment: Alignment.center, child: Text(operator.value, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)),
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
}