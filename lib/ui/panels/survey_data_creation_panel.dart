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
import 'package:rokwire_plugin/model/options.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

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
  final List<String> _defaultTextControllers = ["key", "text", "more_info", "section", "maximum_score", "default_follow_up_key"];

  late SurveyData _data;
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
      "section": TextEditingController(text: _data.section),
      "maximum_score": TextEditingController(text: _data.maximumScore?.toString()),
      "default_follow_up_key": TextEditingController(text: _data.defaultFollowUpKey),
    };
    super.initState();
  }

  @override
  void dispose() {
    _removeTextControllers();
    super.dispose();
  }

  void _removeTextControllers({bool keepDefaults = false}) {
    _textControllers.forEach((key, value) {
      if (!keepDefaults || !_defaultTextControllers.contains(key)) {
        value.dispose();
      }
    });
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
            child: dataLength > 0 ? ListView.builder(
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
            ) : _buildAddRemoveButtons(0, textGroup),
          ),
        ],
      ),
    );
  }

  // Widget _buildStringListEntryWidget(, String textGroup) {
  //   return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
  //     FormFieldText('Value', controller: _textControllers["$textGroup$index.value"], inputType: TextInputType.text, required: true),
  //     _buildAddRemoveButtons(index + 1, textGroup),
  //   ]);
  // }

  Widget _buildAddRemoveButtons(int index, String textGroup) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      IconButton(
        icon: Styles().images?.getImage('plus-circle', color: Styles().colors?.getColor('fillColorPrimary')) ?? const Icon(Icons.add),
        onPressed: () => _onTapAddDataAtIndex(index, textGroup),
        padding: EdgeInsets.zero,
      ),
      Visibility(visible: index > 0, child: IconButton(
        icon: Styles().images?.getImage('minus-circle', color: Styles().colors?.getColor('alert')) ?? const Icon(Icons.add),
        onPressed: () => _onTapRemoveDataAtIndex(index - 1, textGroup),
        padding: EdgeInsets.zero,
      )),
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
      dataContent.add(_buildCollapsibleWrapper('Options', 'options', (_data as SurveyQuestionMultipleChoice).options.length, _buildOptionsWidget));
      
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

      _textControllers["minimum"] ??= TextEditingController(text: (_data as SurveyQuestionNumeric).minimum?.toString());
      _textControllers["maximum"] ??= TextEditingController(text: (_data as SurveyQuestionNumeric).maximum?.toString());
      //minimum
      dataContent.add(FormFieldText('Minimum', controller: _textControllers["minimum"], inputType: TextInputType.number,));
      //maximum
      dataContent.add(FormFieldText('Maximum', controller: _textControllers["maximum"], inputType: TextInputType.number,));

      // wholeNum
      dataContent.add(Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Text("Whole Number", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
        Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: (_data as SurveyQuestionNumeric).wholeNum,
          onChanged: _onToggleWholeNumber,
        ),
      ],));
      // selfScore
      dataContent.add(Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Text("Self-Score", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
        Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: (_data as SurveyQuestionNumeric).selfScore,
          onChanged: _onToggleSelfScore,
        ),
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
      dataContent.add(_buildCollapsibleWrapper('Actions', 'actions', (_data as SurveyDataResult).actions?.length ?? 0, _buildActionsWidget));
    }
    // add SurveyDataPage and SurveyDataEntry later

    List<Widget> baseContent = [
      //key*
      FormFieldText('Key', controller: _textControllers["key"], inputType: TextInputType.text, required: true),
      //question text*
      FormFieldText('Question Text', controller: _textControllers["text"], inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences, required: true),
      //more info (Additional Info)
      FormFieldText('Additional Info', controller: _textControllers["more_info"], multipleLines: true, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences,),
      //section
      FormFieldText('Section', controller: _textControllers["section"], inputType: TextInputType.text,),
      //maximum score (number, show if survey is scored)
      FormFieldText('Maximum Score', controller: _textControllers["maximum_score"], inputType: TextInputType.number,),
      //defaultFollowUpKey (defaults to next data in list if unspecified)
      FormFieldText('Next Question Key', controller: _textControllers["default_follow_up_key"], inputType: TextInputType.text,),

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
      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
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
        leading: Row(mainAxisSize: MainAxisSize.min, children: [
          Text("Correct?", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
          Checkbox(
            checkColor: Styles().colors?.surface,
            activeColor: Styles().colors?.fillColorPrimary,
            value: (_data as SurveyQuestionMultipleChoice).correctAnswers?.contains((_data as SurveyQuestionMultipleChoice).options[index].value) ?? false,
            onChanged: (value) => _onToggleCorrect(index, value),
          ),
        ]),
        trailing: _buildAddRemoveButtons(index + 1, textGroup),
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          _buildOptionsItemWidget(index),
        ],
      ),
    );
  }

  Widget _buildOptionsItemWidget(int index) {
    _textControllers["options$index.title"] ??= TextEditingController(text: (_data as SurveyQuestionMultipleChoice).options[index].title);
    _textControllers["options$index.hint"] ??= TextEditingController(text: (_data as SurveyQuestionMultipleChoice).options[index].hint);
    _textControllers["options$index.value"] ??= TextEditingController(text: (_data as SurveyQuestionMultipleChoice).options[index].value.toString());
    _textControllers["options$index.score"] ??= TextEditingController(text: (_data as SurveyQuestionMultipleChoice).options[index].score?.toString());
    return Column(children: [
      //title*
      FormFieldText('Title', padding: const EdgeInsets.symmetric(vertical: 4.0), controller: _textControllers["options$index.title"], inputType: TextInputType.text, required: true),
      //hint
      FormFieldText('Hint', padding: const EdgeInsets.symmetric(vertical: 4.0), controller: _textControllers["options$index.hint"], inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),
      //value* (dynamic value = _value ?? title)
      FormFieldText('Value', padding: const EdgeInsets.symmetric(vertical: 4.0), controller: _textControllers["options$index.value"], inputType: TextInputType.text, required: true),
      //score
      FormFieldText('Score', padding: const EdgeInsets.symmetric(vertical: 4.0), controller: _textControllers["options$index.score"], inputType: TextInputType.number,),
    ],);
  }

  Widget _buildActionsWidget(int index, String textGroup) {
    return Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        title: Text(
          (_data as SurveyDataResult).actions![index].label ?? "New Action",
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
        ),
        trailing: _buildAddRemoveButtons(index + 1, textGroup),
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          _buildActionsItemWidget(index),
        ],
      ),
    );
  }

  Widget _buildActionsItemWidget(int index) {
    // optional ActionData actions (null for "pure info")
    _textControllers["actions$index.label"] ??= TextEditingController(text: (_data as SurveyDataResult).actions![index].label);
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
      FormFieldText('Label', padding: const EdgeInsets.symmetric(vertical: 4.0), controller: _textControllers["actions$index.label"], inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),
      //TODO
        // dynamic data (e.g., URL, phone num., sms num., etc.)
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
    _updateState(() {
      if (textGroup.contains("options") && _data is SurveyQuestionMultipleChoice) {
        (_data as SurveyQuestionMultipleChoice).options.insert(index, OptionData(title: index > 0 ? (_data as SurveyQuestionMultipleChoice).options[index-1].title : "New Option"));
      } else if (textGroup.contains("actions") && _data is SurveyDataResult) {
        (_data as SurveyDataResult).actions ??= [];
        (_data as SurveyDataResult).actions!.insert(index, ActionData());
        //TODO
        // "params"
      }
    });
  }

  void _onTapRemoveDataAtIndex(int index, String textGroup) {
    _updateState(() {
      if (textGroup.contains("options") && _data is SurveyQuestionMultipleChoice) {
        (_data as SurveyQuestionMultipleChoice).options.removeAt(index);
      } else if (textGroup.contains("actions") && _data is SurveyDataResult) {
        (_data as SurveyDataResult).actions!.removeAt(index);
        //TODO
        // "params"
      }
    });
  }

  void _onChangeType(String? type) {
    String key = _textControllers["key"]!.text;
    String text = _textControllers["text"]!.text;
    String? moreInfo = _textControllers["more_info"]!.text.isNotEmpty ? _textControllers["more_info"]!.text : null;
    String? section = _textControllers["section"]!.text.isNotEmpty ? _textControllers["section"]!.text : null;
    num? maximumScore = num.tryParse(_textControllers["maximum_score"]!.text);
    String? defaultFollowUpKey = _textControllers["default_follow_up_key"]!.text;
    _removeTextControllers(keepDefaults: true);

    _updateState(() {
      switch (type) {
        case "survey_data.true_false":
          _data = SurveyQuestionTrueFalse(key: key, text: text, moreInfo: moreInfo, section: section, maximumScore: maximumScore, defaultFollowUpKey: defaultFollowUpKey);
          break;
        case "survey_data.multiple_choice":
          _data = SurveyQuestionMultipleChoice(key: key, text: text, moreInfo: moreInfo, section: section, maximumScore: maximumScore, defaultFollowUpKey: defaultFollowUpKey, options: []);
          break;
        case "survey_data.date_time":
          _data = SurveyQuestionDateTime(key: key, text: text, moreInfo: moreInfo, section: section, maximumScore: maximumScore, defaultFollowUpKey: defaultFollowUpKey);
          break;
        case "survey_data.numeric":
          _data = SurveyQuestionNumeric(key: key, text: text, moreInfo: moreInfo, section: section, maximumScore: maximumScore, defaultFollowUpKey: defaultFollowUpKey);
          break;
        case "survey_data.text":
          _data = SurveyQuestionText(key: key, text: text, moreInfo: moreInfo, section: section, maximumScore: maximumScore, defaultFollowUpKey: defaultFollowUpKey);
          break;
        case "survey_data.result":
          _data = SurveyDataResult(key: key, text: text, moreInfo: moreInfo, defaultFollowUpKey: defaultFollowUpKey);
          break;
      }
    });
  }

  void _onChangeStyle(String? style) {
    _updateState(() {
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

  void _onToggleCorrect(int index, bool? value) {
    _updateState(() {
      if (value == true) {
        (_data as SurveyQuestionMultipleChoice).correctAnswers ??= [];
        (_data as SurveyQuestionMultipleChoice).correctAnswers!.add((_data as SurveyQuestionMultipleChoice).options[index].value);
      } else {
        (_data as SurveyQuestionMultipleChoice).correctAnswers!.remove((_data as SurveyQuestionMultipleChoice).options[index].value);
      }
    });
  }

  void _onToggleMultipleAnswers(bool? value) {
    _updateState(() {
      (_data as SurveyQuestionMultipleChoice).allowMultiple = value ?? false;
    });
  }

  void _onToggleSelfScore(bool? value) {
    _updateState(() {
      if (_data is SurveyQuestionMultipleChoice) {
        (_data as SurveyQuestionMultipleChoice).selfScore = value ?? false;
      } else if (_data is SurveyQuestionNumeric) {
        (_data as SurveyQuestionNumeric).selfScore = value ?? false;
      }
    });
  }

  // void _onToggleAskTime(bool? value) {
  //   _updateState(() {
  //     (_data as SurveyQuestionDateTime).askTime = value ?? false;
  //   });
  // }

  void _onToggleWholeNumber(bool? value) {
    _updateState(() {
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
    _data.key = _textControllers["key"]!.text;
    _data.text = _textControllers["text"]!.text;
    _data.moreInfo = _textControllers["more_info"]!.text.isNotEmpty ? _textControllers["more_info"]!.text : null;
    _data.section = _textControllers["section"]!.text.isNotEmpty ? _textControllers["section"]!.text : null;
    _data.maximumScore = num.tryParse(_textControllers["maximum_score"]!.text);
    //TODO: use dropdown for this (or some more convenient way of using default ordering or referencing other survey data)
    _data.defaultFollowUpKey = _textControllers["default_follow_up_key"]!.text;

    //TODO: handle these fields
    // _textControllers["start_time"]
    // _textControllers["end_time"] ?


    // _textControllers["minimum"]
    // _textControllers["maximum"]

    // _textControllers["min_length"]
    // _textControllers["max_length"]

    // _textControllers["options$index.title"]
    // _textControllers["options$index.hint"] 
    // _textControllers["options$index.value"]
    // _textControllers["options$index.score"]

    // _textControllers["actions$index.label"]
    Navigator.of(context).pop(_data);
  }

  void _updateState(Function() fn) {
    if (mounted) {
      setState(() {
        fn();
      });
    }
  }
}