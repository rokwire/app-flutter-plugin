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

import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class RuleElementCreationPanel extends StatefulWidget {
  final RuleElement data;
  final Widget? tabBar;

  const RuleElementCreationPanel({Key? key, required this.data, this.tabBar}) : super(key: key);

  @override
  _RuleElementCreationPanelState createState() => _RuleElementCreationPanelState();
}

class _RuleElementCreationPanelState extends State<RuleElementCreationPanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  late final Map<String, TextEditingController> _textControllers;
  final List<String> _defaultTextControllers = ["key", "text", "more_info", "section", "maximum_score"];

  late RuleElement _ruleElem;

  @override
  void initState() {
    _ruleElem = widget.data;

    // _textControllers = {
    //   "key": TextEditingController(text: _ruleElem.key),
    //   "text": TextEditingController(text: _ruleElem.text),
    //   "more_info": TextEditingController(text: _ruleElem.moreInfo),
    //   "section": TextEditingController(text: _ruleElem.section),
    //   "maximum_score": TextEditingController(text: _ruleElem.maximumScore?.toString()),
    // };
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
    //RuleCondition
      //RuleComparison
      //RuleLogic
    //RuleResult
      //Rule
      //RuleCases
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
    return Scaffold(
      appBar: const HeaderBar(title: "Edit Rule Element"),
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
              child: _buildRuleElementComponents(),
            ),
          )),
          Container(
            color: Styles().colors?.backgroundVariant,
            child: _buildDone(),
          ),
        ],
    ));
  }

  Widget _buildCollapsibleWrapper(String label, List<dynamic> dataList, Widget Function(int, List<dynamic>, Collapsible) listItemBuilder, Collapsible collType, {String? parentId}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0), child: Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        title: Text(
          label,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
        ),
        //TODO: handle indentation using displayDepth
        trailing: (collType == Collapsible.followUpRules || collType == Collapsible.resultRules) && parentId != null ? Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
          label: 'Edit',
          borderColor: Styles().colors?.fillColorPrimaryVariant,
          backgroundColor: Styles().colors?.surface,
          textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
          onTap: () => collType == Collapsible.followUpRules ? _onTapEditFlowRuleElement(parentId) : _onTapEditResultRuleElement(parentId),
        )) : null,
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500
            ),
            child: dataList.isNotEmpty ? ListView.builder(
              shrinkWrap: true,
              itemCount: dataList.length,
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: listItemBuilder(index, dataList, collType)),
                    Container(height: 1, color: Styles().colors?.getColor('dividerLine'),),
                  ],
                );
              },
            ) : (collType == Collapsible.data || collType == Collapsible.resultRules) ? _buildAddRemoveButtons(0) : Container(height: 0,),
          ),
        ],
      ),
    ));
  }

  Widget _buildRuleElementComponents() {
    List<Widget> content = [DropdownButtonHideUnderline(child:
      DropdownButton<String>(
        icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
        isExpanded: true,
        style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
        items: _buildDropDownItems<String>(RuleElement.supportedElements),
        value: _getElementTypeString(),
        onChanged: _onChangeElementType,
        dropdownColor: Styles().colors?.getColor('surface'),
      ),
    )];
    if (_ruleElem is RuleReference || _ruleElem is RuleAction) {
      
    } else if (_ruleElem is Rule) {
      
      displayEntry = _buildCollapsibleWrapper(ruleResult.condition?.getSummary() ?? "", elementsSlice, _buildRuleWidget, collType, parentId: ruleResult.condition?.id);
    } else if (_ruleElem is RuleCases) {
      displayEntry = _buildCollapsibleWrapper(summary, ruleResult.cases, _buildRuleWidget, collType, parentId: ruleResult.id);
    } else if (_ruleElem is RuleActionList) {
      displayEntry = _buildCollapsibleWrapper(summary, ruleResult.actions, _buildRuleWidget, collType, parentId: ruleResult.id);
    }
    if (_ruleElem is SurveyQuestionTrueFalse) {
      
    } else if (_ruleElem is SurveyQuestionMultipleChoice) {
      
    } else if (_ruleElem is SurveyQuestionDateTime) {
      
    } else if (_ruleElem is SurveyQuestionNumeric) {
      
    } else if (_ruleElem is SurveyQuestionText) {

    } else if (_ruleElem is SurveyDataResult) {
      
    }

    return Container();
  }

  List<DropdownMenuItem<T>> _buildDropDownItems<T>(Map<T, String> supportedItems) {
    List<DropdownMenuItem<T>> items = [];

    for (MapEntry<T, String> item in supportedItems.entries) {
      items.add(DropdownMenuItem<T>(
        value: item.key,
        child: Align(alignment: Alignment.center, child: Text(item.value, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)),
      ));
    }
    return items;
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

  void _onChangeElementType(String? elemType) {
    //TODO: what should defaults be for these?
    _updateState(() {
      switch (elemType) {
        case "comparison":
          _ruleElem = RuleComparison(dataKey: "", operator: "==", compareTo: "");
          break;
        case "logic":
          _ruleElem = RuleLogic("and", []);
          break;
        case "reference":
          _ruleElem = RuleReference("");
          break;
        case "action":
          _ruleElem = RuleAction(action: "return", data: null);
          break;
        case "action_list":
          _ruleElem = RuleActionList(actions: []);
          break;
        case "cases":
          _ruleElem = RuleCases(cases: []);
          break;
      }
    });
  }

  String? _getElementTypeString() {
    if (_ruleElem is RuleComparison) {
      return "comparison";
    } else if (_ruleElem is RuleLogic) {
      return "logic";
    } else if (_ruleElem is RuleReference) {
      return "reference";
    } else if (_ruleElem is RuleAction) {
      return "action";
    } else if (_ruleElem is RuleActionList) {
      return "action_list";
    } else if (_ruleElem is RuleCases) {
      return "cases";
    }
    return null;
  }

  void _onTapDone() {
    // defaultFollowUpKey and followUpRule will be handled by rules defined on SurveyCreationPanel
    // _ruleElem.key = _textControllers["key"]!.text;
    // _ruleElem.text = _textControllers["text"]!.text;
    // _ruleElem.moreInfo = _textControllers["more_info"]!.text.isNotEmpty ? _textControllers["more_info"]!.text : null;
    // _ruleElem.section = _textControllers["section"]!.text.isNotEmpty ? _textControllers["section"]!.text : null;
    // _ruleElem.maximumScore = num.tryParse(_textControllers["maximum_score"]!.text);

    if (_ruleElem is SurveyQuestionMultipleChoice) {
      
    } else if (_ruleElem is SurveyQuestionDateTime) {
    } else if (_ruleElem is SurveyQuestionNumeric) {
    } else if (_ruleElem is SurveyQuestionText) {
    } else if (_ruleElem is SurveyDataResult) {
    }
    
    Navigator.of(context).pop(_ruleElem);
  }

  void _updateState(Function() fn) {
    if (mounted) {
      setState(() {
        fn();
      });
    }
  }
}