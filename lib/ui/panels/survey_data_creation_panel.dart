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
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/survey_data_options_panel.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyDataCreationPanel extends StatefulWidget {
  final SurveyData data;
  final Widget? tabBar;
  final List<String> sections;

  const SurveyDataCreationPanel({Key? key, required this.data, required this.sections, this.tabBar}) : super(key: key);

  @override
  _SurveyDataCreationPanelState createState() => _SurveyDataCreationPanelState();
}

class _SurveyDataCreationPanelState extends State<SurveyDataCreationPanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  late final Map<String, TextEditingController> _textControllers;
  final List<String> _defaultTextControllers = ["key", "text", "more_info", "maximum_score"];

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

  Widget _buildCollapsibleWrapper(String label, List<dynamic> dataList, Widget Function(int, dynamic) listItemBuilder) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        title: Text(label, style: Styles().textStyles?.getTextStyle('widget.detail.small'),),
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          dataList.isNotEmpty ? ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: dataList.length,
            itemBuilder: (BuildContext context, int index) {
              return Column(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: listItemBuilder(index, dataList[index])),
                ],
              );
            },
          ) : Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Row(children: [
              Container(height: 0),
              Expanded(child: _buildEntryManagementOptions(0))
            ]
          )),
        ],
      ),
    );
  }

  Widget _buildEntryManagementOptions(int index) {
    //TODO: in certain cases, do not show remove button when list size is = 2 (logic, cases, actions)
    BoxConstraints constraints = const BoxConstraints(maxWidth: 64, maxHeight: 80,);
    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
      IconButton(
        icon: Styles().images?.getImage('plus-circle', color: Styles().colors?.getColor('fillColorPrimary'), size: 14) ?? const Icon(Icons.add),
        onPressed: () => _onTapAddDataAtIndex(index),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        constraints: constraints,
      ),
      Visibility(visible: index > 0, child: IconButton(
        icon: Styles().images?.getImage('clear', size: 14) ?? const Icon(Icons.remove),
        onPressed: () => _onTapRemoveDataAtIndex(index - 1),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        constraints: constraints,
      )),
      Visibility(visible: index > 0, child: IconButton(
        icon: Styles().images?.getImage('edit-white', color: Styles().colors?.getColor('fillColorPrimary'), size: 14) ?? const Icon(Icons.edit),
        onPressed: () => _onTapEditData(index - 1),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        constraints: constraints,
      )),
    ]);
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
      dataContent.add(_buildCollapsibleWrapper('Options', (_data as SurveyQuestionMultipleChoice).options, _buildOptionsWidget));
      
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
      dataContent.add(_buildCollapsibleWrapper('Actions', (_data as SurveyDataResult).actions ?? [], _buildActionsWidget));
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
            value: _getTypeString(),
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

      // type specific data
      Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('Type Specific', style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'))),

      ...dataContent,

      //TODO
      // defaultResponseRule
      // _buildRuleWidget(0, "$textGroup.default_response_rule"),
      // scoreRule (show entry if survey is scored)
      // _buildRuleWidget(0, "$textGroup.score_rule"),
    ];

    return Column(children: baseContent,);
  }

  Widget _buildOptionsWidget(int index, dynamic data) {
    Widget surveyDataText = Text((data as OptionData).title, style: Styles().textStyles?.getTextStyle(data.isCorrect ? 'widget.detail.small.fat' : 'widget.detail.small'),);
    Widget displayEntry = Card(child: Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        surveyDataText,
        Expanded(child: _buildEntryManagementOptions(index + 1)),
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

  Widget _buildActionsWidget(int index, dynamic data) {
    Widget surveyDataText = Text((data as ActionData).label ?? '', style: Styles().textStyles?.getTextStyle('widget.detail.small'),);
    Widget displayEntry = Card(child: Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        surveyDataText,
        Expanded(child: _buildEntryManagementOptions(index + 1)),
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
        (_data as SurveyQuestionMultipleChoice).options.insert(index, OptionData(title: index > 0 ? (_data as SurveyQuestionMultipleChoice).options[index-1].title : "New Option"));
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
      if (mounted) {
        setState(() {
          (_data as SurveyQuestionMultipleChoice).options[index] = updatedData;
        });
      }
    } else if (_data is SurveyDataResult) {
      dynamic updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataOptionsPanel(data: (_data as SurveyDataResult).actions![index], tabBar: widget.tabBar)));
      if (mounted) {
        setState(() {
          (_data as SurveyDataResult).actions![index] = updatedData;
        });
      }
    }
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

  String? _getTypeString() {
    if (_data is SurveyQuestionTrueFalse) {
      return "survey_data.true_false";
    } else if (_data is SurveyQuestionMultipleChoice) {
      return "survey_data.multiple_choice";
    } else if (_data is SurveyQuestionDateTime) {
      return "survey_data.date_time";
    } else if (_data is SurveyQuestionNumeric) {
      return "survey_data.numeric";
    } else if (_data is SurveyQuestionText) {
      return "survey_data.text";
    } else if (_data is SurveyDataResult) {
      return "survey_data.result";
    }
    return null;
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