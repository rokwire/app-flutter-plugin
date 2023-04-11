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

import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/panels/rule_element_creation_panel.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/panels/survey_data_creation_panel.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widget_builders/loading.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class SurveyCreationPanel extends StatefulWidget {
  final Widget? tabBar;
  final Widget? offlineWidget;

  const SurveyCreationPanel({Key? key, this.tabBar, this.offlineWidget}) : super(key: key);

  @override
  _SurveyCreationPanelState createState() => _SurveyCreationPanelState();
}

class _SurveyCreationPanelState extends State<SurveyCreationPanel> {
  GlobalKey? dataKey;

  bool _loading = false;
  final ScrollController _scrollController = ScrollController();
  late final Map<String, TextEditingController> _textControllers;

  final List<SurveyData> _data = [];
  int dataCount = 0;
  bool _scored = true;
  // bool _sensitive = false;

  // final Map<String, String> _constants = {};
  // final Map<String, Map<String, String>> _strings = {};

  final List<RuleResult> _followUpRules = [];
  final List<RuleResult> _resultRules = [];
  // final Map<String, Rule> _subRules = {};
  // List<String>? _responseKeys;

  final Map<String, String> _supportedLangs = {};

  @override
  void initState() {
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

    for (String lang in Localization().defaultSupportedLanguages) {
      _supportedLangs[lang] = lang;
    }

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
    return Padding(padding: const EdgeInsets.only(left: 8, right: 8, top: 20), child: Column(children: [
      // title
      FormFieldText('Title', controller: _textControllers["title"], inputType: TextInputType.text, textCapitalization: TextCapitalization.words, required: true),
      // more_info
      FormFieldText('Additional Information', controller: _textControllers["more_info"], multipleLines: true, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),
      // survey type (make this a dropdown?)
      FormFieldText('Type', controller: _textControllers["type"], multipleLines: false, inputType: TextInputType.text, textCapitalization: TextCapitalization.words, required: true),

      //TODO: sections list entry

      // scored
      Row(children: [
        Padding(padding: const EdgeInsets.only(left: 16), child: Text("Scored", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
        Expanded(child: Align(alignment: Alignment.centerRight, child: Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: _scored,
          onChanged: _onToggleScored,
        ))),
      ],),

      // data
      Padding(padding: const EdgeInsets.only(top: 16.0), child: 
        _buildCollapsibleWrapper("Survey Data", _data, _buildSurveyDataWidget, SurveyElement.data),
      ),
      
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

      // follow up rules (determine survey data ordering/flow)
      Padding(padding: const EdgeInsets.only(top: 16.0), child: 
        _buildCollapsibleWrapper("Flow Rules", _followUpRules, _buildRuleWidget, SurveyElement.followUpRules),
      ),
      // result_rules
      Padding(padding: const EdgeInsets.only(top: 16.0), child: 
        _buildCollapsibleWrapper("Result Rules", _resultRules, _buildRuleWidget, SurveyElement.resultRules),
      ),
    ],));
  }

  Widget _buildPreviewAndContinue() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
        label: 'Preview',
        borderColor: Styles().colors?.getColor("fillColorPrimaryVariant"),
        backgroundColor: Styles().colors?.surface,
        textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
        onTap: _onTapPreview,
      ))),
      Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: Stack(children: [
        Visibility(visible: _loading, child: LoadingBuilder.loading()),
        RoundedButton(
          label: 'Continue',
          borderColor: Styles().colors?.getColor("fillColorPrimaryVariant"),
          backgroundColor: Styles().colors?.surface,
          textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
          onTap: _onTapContinue,
        ),
      ]))),
    ],);
  }

  Widget _buildCollapsibleWrapper(String label, List<dynamic> dataList, Widget Function(int, dynamic, SurveyElement, RuleElement?) listItemBuilder, SurveyElement surveyElement, {RuleElement? parentElement, int? parentIndex, RuleElement? grandParentElement}) {
    bool hideEntryManagement = parentElement is RuleLogic && grandParentElement is Rule;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        //TODO: make into Cards
        title: Row(children: [
          Text(
            label,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
          ),
          Expanded(child: _buildEntryManagementOptions((parentIndex ?? -1) + 1, surveyElement, 
            element: parentElement,
            parentElement: grandParentElement,
            addRemove: parentElement != null && parentIndex != null && !hideEntryManagement,
            editable: parentElement != null && !hideEntryManagement
          )),
        ],),
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
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: listItemBuilder(index, dataList[index], surveyElement, parentElement)),
                  ],
                );
              },
            ) : Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Row(children: [
                Container(height: 0),
                Expanded(child: _buildEntryManagementOptions(0, surveyElement, parentElement: parentElement, editable: false))
              ]
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyDataWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? _) {
    Widget surveyDataText = Text((data as SurveyData).key, style: Styles().textStyles?.getTextStyle('widget.detail.regular'),);
    Widget displayEntry = Row(children: [
      surveyDataText,
      Expanded(child: _buildEntryManagementOptions(index + 1, surveyElement)),
    ],);

    return LongPressDraggable<int>(
      data: index,
      feedback: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: surveyDataText
      ),
      child: DragTarget<int>(
        builder: (BuildContext context, List<int?> accepted, List<dynamic> rejected) {
          return Ink(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
            child: displayEntry,
          );
        },
        onAccept: (oldIndex) => _onAcceptDataDrag(oldIndex, index),
      ),
      childWhenDragging: displayEntry,
    );
  }

  Widget _buildRuleWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement) {
    RuleElement ruleElem = data as RuleElement;
    String summary = ruleElem.getSummary();
    if (index == 0 && surveyElement == SurveyElement.followUpRules) {
      summary = "Start: $summary";
    }

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
    Widget ruleText = Text(summary, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), overflow: TextOverflow.fade);
    if (ruleElem is RuleReference || ruleElem is RuleAction) {
      displayEntry = Row(children: [
        ruleText,
        Expanded(child: _buildEntryManagementOptions(index + 1, surveyElement, element: ruleElem, parentElement: parentElement, addRemove: addRemove)),
      ],);
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

    //LongPressDraggable
    return LongPressDraggable<int>(
      data: index,
      feedback: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: ruleText
      ),
      child: DragTarget<int>(
        builder: (BuildContext context, List<int?> accepted, List<dynamic> rejected) {
          return Ink(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
            child: displayEntry,
          );
        },
        onAccept: (oldIndex) => surveyElement == SurveyElement.followUpRules ? _onAcceptFlowRuleDrag(oldIndex, index) : _onAcceptResultRuleDrag(oldIndex, index),
      ),
      childWhenDragging: displayEntry,
    );
  }

  Widget _buildEntryManagementOptions(int index, SurveyElement surveyElement, {RuleElement? element, RuleElement? parentElement, bool addRemove = true, bool editable = true}) {
    //TODO: in certain cases, do not show remove button when list size is = 2 (logic, cases, actions)
    BoxConstraints constraints = const BoxConstraints(maxWidth: 64, maxHeight: 80,);
    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
      Visibility(visible: addRemove, child: IconButton(
        icon: Styles().images?.getImage('plus-circle', color: Styles().colors?.getColor('fillColorPrimary'), size: 14) ?? const Icon(Icons.add),
        onPressed: () => surveyElement == SurveyElement.data ? _onTapAddDataAtIndex(index) : _onTapAddRuleElementForId(index, surveyElement, parentElement),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        constraints: constraints,
      )),
      Visibility(visible: addRemove, child: IconButton(
        icon: Styles().images?.getImage('clear', size: 14) ?? const Icon(Icons.remove),
        onPressed: () => surveyElement == SurveyElement.data ? _onTapRemoveDataAtIndex(index - 1) : _onTapRemoveRuleElementForId(index - 1, surveyElement, parentElement),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        constraints: constraints,
      )),
      Visibility(visible: editable, child: IconButton(
        icon: Styles().images?.getImage('edit-white', color: Styles().colors?.getColor('fillColorPrimary'), size: 14) ?? const Icon(Icons.edit),
        onPressed: () => surveyElement == SurveyElement.data ? _onTapEditData(index) : _onTapEditRuleElement(element, surveyElement),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        constraints: constraints,
      )),
    ]);
  }

  void _onAcceptDataDrag(int oldIndex, int newIndex) {
    _updateState(() {
      SurveyData temp = _data[oldIndex];
      _data.removeAt(oldIndex);
      _data.insert(newIndex, temp);
      _updateFollowUpRules();
    });

    _onAcceptFlowRuleDrag(oldIndex, newIndex);
  }

  void _onAcceptFlowRuleDrag(int oldIndex, int newIndex) {
    _updateState(() {
      RuleResult temp = _followUpRules[oldIndex];
      _followUpRules.removeAt(oldIndex);
      _followUpRules.insert(newIndex, temp);
      _updateFollowUpRules();
    });
  }

  void _onAcceptResultRuleDrag(int oldIndex, int newIndex) {
    _updateState(() {
      RuleResult temp = _resultRules[oldIndex];
      _resultRules.removeAt(oldIndex);
      _resultRules.insert(newIndex, temp);
      _updateFollowUpRules();
    });
  }

  void _onTapEditData(int index) async {
    SurveyData updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataCreationPanel(data: _data[index], tabBar: widget.tabBar)));
    _updateState(() {
      _data[index] = updatedData;
      _updateFollowUpRules();
    });
  }

  void _updateFollowUpRules() {
    //TODO: update follow up rules appropriately
  }

  void _onTapEditRuleElement(RuleElement? element, SurveyElement surveyElement, {RuleElement? parentElement}) async {
    if (element != null) {
      RuleElement ruleElement = await Navigator.push(context, CupertinoPageRoute(builder: (context) => RuleElementCreationPanel(
        data: element,
        dataKeys: List.generate(_data.length, (index) => _data[index].key),
        tabBar: widget.tabBar, mayChangeType: parentElement is! RuleCases && parentElement is! RuleActionList
      )));
      _updateState(() {
        if (surveyElement == SurveyElement.followUpRules) {
          for (int i = 0; i < _followUpRules.length; i++) {
            if (element.id == _followUpRules[i].id && ruleElement is RuleResult) {
              _followUpRules[i] = ruleElement;
              return;
            }
            if (_followUpRules[i].updateElementById(element.id, ruleElement)) {
              return;
            }
          }
        } else {
          for (int i = 0; i < _resultRules.length; i++) {
            if (element.id == _resultRules[i].id && ruleElement is RuleResult) {
              _resultRules[i] = ruleElement;
              return;
            }
            if (_resultRules[i].updateElementById(element.id, ruleElement)) {
              return;
            }
          }
        }
      });
    }
  }

  void _onTapAddDataAtIndex(int index) {
    SurveyData insert;
    if (index > 0) {
      insert = SurveyData.fromOther(_data[index-1]);
      insert.key = "data${dataCount++}";
      insert.text = "New survey data";
    } else {
      insert = SurveyQuestionTrueFalse(text: "New True/False Question", key: "data${dataCount++}");
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
      _updateFollowUpRules();
    });
  }

  void _onTapRemoveDataAtIndex(int index) {
    _updateState(() {
      _data.removeAt(index);
      _followUpRules.removeAt(index);
      _updateFollowUpRules();
    });
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
      element.conditions.insertAll(index, [
        RuleComparison(dataKey: "", operator: "==", compareTo: ""),
        RuleComparison(dataKey: "", operator: "==", compareTo: ""),
      ]);
    }

    _updateState(() {
      if (element == null && surveyElement == SurveyElement.resultRules) {
         _resultRules.insert(index, RuleAction(action: "save", data: null));
      } else {
        for (RuleResult result in surveyElement == SurveyElement.followUpRules ? _followUpRules : _resultRules) {
          if (result.updateElementById(element!.id, element)) {
            return;
          }
        }
      }
      //TODO: update follow up rules and result rules other than returns
    });
  }

  void _onTapRemoveRuleElementForId(int index, SurveyElement surveyElement, RuleElement? element) {
    if (element is RuleCases) {
      element.cases.removeAt(index);
    } else if (element is RuleActionList) {
      element.actions.removeAt(index);
    } else if (element is RuleLogic) {
      element.conditions.removeAt(index);
    }

    _updateState(() {
      if (element == null && surveyElement == SurveyElement.resultRules) {
         _resultRules.removeAt(index);
      } else {
        for (RuleResult result in surveyElement == SurveyElement.followUpRules ? _followUpRules : _resultRules) {
          if (result.updateElementById(element!.id, element)) {
            return;
          }
        }
      }
      //TODO: update follow up rules and result rules other than returns
    });
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

  
  Survey _buildSurvey() {
    //TODO: map rules into each survey data
    return Survey(
      id: '',
      data: Map.fromIterable(_data, key: (item) => (item as SurveyData).key),
      type: _textControllers["type"]?.text ?? 'survey',
      scored: _scored,
      title: _textControllers["title"]?.text ?? 'New Survey',
      moreInfo: _textControllers["more_info"]?.text,
      // defaultDataKeyRule: _defaultDataKeyRule,
      resultRules: _resultRules,
      // responseKeys: _responseKeys,
      // constants: _constants,
      // strings: _strings,
      // subRules: _subRules,
    );
  }

  void _onTapPreview() {
    // should preview evaluate rules?/which rules should it evaluate if not all of them?
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: _buildSurvey())));
  }

  void _onTapContinue() {
    setLoading(true);
    Surveys().createSurvey(_buildSurvey()).then((success) {
      setLoading(false);
      PopupMessage.show(context: context,
        title: "Create Survey",
        message: "Survey creation ${success == true ? "succeeded" : "failed"}",
        buttonTitle: Localization().getStringEx("dialog.ok.title", "OK"),
        onTapButton: (context) {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        barrierDismissible: false,
      );
    });
  }

  void setLoading(bool value) {
    if (mounted) {
      setState(() {
        _loading = value;
      });
    }
  }

  void _updateState(Function() fn) {
    if (mounted) {
      setState(() {
        fn();
      });
    }
  }
}

enum SurveyElement { data, followUpRules, resultRules }