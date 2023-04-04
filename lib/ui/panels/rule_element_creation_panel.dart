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
              child: _buildRuleElement(),
            ),
          )),
          Container(
            color: Styles().colors?.backgroundVariant,
            child: _buildDone(),
          ),
        ],
    ));
  }

  Widget _buildCollapsibleWrapper(String label, List<RuleElement> dataList, Widget Function({RuleElement? element}) listItemBuilder) {
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
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: listItemBuilder(element: dataList[index])),
                    Container(height: 1, color: Styles().colors?.getColor('dividerLine'),),
                  ],
                );
              },
            ) : Container(),
          ),
        ],
      ),
    ));
  }

  Widget _buildRuleElement({RuleElement? element}) {
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

    // survey:
      // "completion":
      // "scores":
      // "date_updated":
      // "scored":
      // "type":
      // "stats":
      // "result_data":
      // "response_keys":
      // "data"
      // "auth"?
    // survey stats:
      // "total":
      // "complete":
      // "scored":
      // "scores":
      // "maximum_scores":
      // "percentage":
      // "total_score":
      // "response_data":
    // survey data:
      // "response":
      // "score":
      // "maximum_score":
      // "correct_answer":
      // "correct_answers"
    
    RuleElement ruleElem = element ?? _ruleElem;
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
    if (ruleElem is RuleComparison) {
      // dropdown showing comparison options (RuleComparison.supportedOperators)
      content.add(DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildDropDownItems<String>(RuleComparison.supportedOperators),
          value: ruleElem.operator,
          onChanged: (compType) => _onChangeComparisonType(ruleElem.id, compType),
          dropdownColor: Styles().colors?.getColor('surface'),
        ),
      ));
      // dropdown for data keys, compare_to options (stats, responses, etc., text entry as alternative)
    } else if (ruleElem is RuleLogic) {
      // dropdown showing logic options (RuleLogic.supportedOperators)
      content.add(DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildDropDownItems<String>(RuleLogic.supportedOperators),
          value: ruleElem.operator,
          onChanged: (logicType) => _onChangeLogicType(ruleElem.id, logicType),
          dropdownColor: Styles().colors?.getColor('surface'),
        ),
      ));
      // collapsible list of conditions
    } else if (ruleElem is RuleReference) {
      //TODO
      // dropdown showing existing rules by summary? (pass existing rules into panel?)
    } else if (ruleElem is RuleAction) {
      // dropdown for action options (RuleAction.supportedActions)
      content.add(DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
          isExpanded: true,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          items: _buildDropDownItems<String>(RuleAction.supportedActions),
          value: ruleElem.action,
          onChanged: (actionType) => _onChangeActionType(ruleElem.id, actionType),
          dropdownColor: Styles().colors?.getColor('surface'),
        ),
      ));
      // data entry
      // data key entry/dropdown
    } else if (ruleElem is RuleCases) {
      //collapsible list of cases
      _buildCollapsibleWrapper('Cases', ruleElem.cases, _buildRuleElement);
    } else if (ruleElem is RuleActionList) {
      // collapsible list of actions
      _buildCollapsibleWrapper('Actions', ruleElem.actions, _buildRuleElement);
    }
    // displayEntry = _buildCollapsibleWrapper(ruleResult.condition?.getSummary() ?? "", elementsSlice, _buildRuleWidget, collType, parentId: ruleResult.condition?.id);

    return Column(children: content);
  }

  List<DropdownMenuItem<T>> _buildDropDownItems<T>(Map<T, String> supportedItems) {
    List<DropdownMenuItem<T>> items = [];

    for (MapEntry<T, String> item in supportedItems.entries) {
      items.add(DropdownMenuItem<T>(
        value: item.key,
        child: Align(alignment: Alignment.center, child: Container(
          color: Styles().colors?.getColor('surface'),
          child: Text(item.value, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)
        )),
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

  void _onChangeComparisonType(String id, String? compType) {
    //TODO: what should defaults be?
    if (compType != null) {
      RuleComparison newComparison = RuleComparison(dataKey: "", operator: compType, compareTo: "");
      _updateState(() {
        _ruleElem.updateElementById(id, newComparison);
      });
    }
  }

  void _onChangeLogicType(String id, String? logicType) {
    if (logicType != null) {
      RuleLogic newLogic = RuleLogic(logicType, []);
      _updateState(() {
        _ruleElem.updateElementById(id, newLogic);
      });
    }
  }

  void _onChangeActionType(String id, String? actionType) {
    if (actionType != null) {
      RuleAction newAction = RuleAction(data: null, action: actionType);
      _updateState(() {
        _ruleElem.updateElementById(id, newAction);
      });
    }
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

/*
  void _onTapAddDataAtIndex(int index) {
    SurveyData insert;
    if (index > 0) {
      insert = SurveyData.fromOther(_data[index-1]);
      insert.key = "data${_data.length}";
      insert.text = "New survey data";
      insert.defaultFollowUpKey = index == _data.length ? null : _data[index].key;
    } else {
      insert = SurveyQuestionTrueFalse(text: "New True/False Question", key: "data${_data.length}");
    }
    _updateState(() {
      _data.insert(index, insert);
      if (index == 0) {
        if (_followUpRules.isEmpty) {
          _followUpRules.add(RuleAction(action: "return", data: insert.key));
        } else {
          _followUpRules[0] = RuleAction(action: "return", data: insert.key);
          _followUpRules.insert(1, RuleAction(action: "return", data: _data[1].key));
        }
      } else {
        _followUpRules.insert(index, RuleAction(action: "return", data: _data[index].key));
      }
      //update follow up rules other than returns
      // if index > 0:
        // update keys for _followUpRules[index-1]
    });
  }

  void _onTapRemoveDataAtIndex(int index) {
    _updateState(() {
      _data.removeAt(index);
      _followUpRules.removeAt(index);
    });
  }

  void _onTapEditResultRuleElement(String id) async {
    RuleElement? resultRulesElem;
    for (RuleResult result in _resultRules) {
      RuleElement? elem = result.findElementById(id);
      if (elem != null) {
        resultRulesElem = elem;
      }
    }

    if (resultRulesElem != null) {
      RuleElement ruleElement = await Navigator.push(context, CupertinoPageRoute(builder: (context) => RuleElementCreationPanel(data: resultRulesElem!, tabBar: widget.tabBar)));
      _updateState(() {
        for (RuleResult result in _resultRules) {
          result.updateElementById(id, ruleElement);
        }
      });
    }
  }
  */

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