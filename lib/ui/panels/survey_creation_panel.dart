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
  late final List<TextEditingController> _sectionTextControllers;

  final List<SurveyData> _data = [];
  int dataCount = 0;
  int sectionCount = 0;
  bool _scored = true;

  final List<RuleResult> _followUpRules = [];
  final List<RuleResult> _resultRules = [];

  // final Map<String, String> _constants = {};
  // final Map<String, Map<String, String>> _strings = {};
  // final Map<String, Rule> _subRules = {};
  // List<String>? _responseKeys;

  final Map<String, String> _supportedLangs = {};

  @override
  void initState() {
    _textControllers = {
      "title": TextEditingController(),
      "more_info": TextEditingController(),
    };
    _sectionTextControllers = [];
    super.initState();
  }

  @override
  void dispose() {
    _textControllers.forEach((_, value) { value.dispose(); });
    for (TextEditingController controller in _sectionTextControllers) {
      controller.dispose();
    }

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
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Column(children: [
      // title
      FormFieldText('Title', padding: const EdgeInsets.only(top: 16), controller: _textControllers["title"], inputType: TextInputType.text, textCapitalization: TextCapitalization.words, required: true),
      // more_info
      FormFieldText('Additional Information', padding: const EdgeInsets.only(top: 16), controller: _textControllers["more_info"], multipleLines: true, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),

      // sections
      Padding(padding: const EdgeInsets.only(top: 16.0), child: 
        _buildCollapsibleWrapper("Sections", _sectionTextControllers, _buildSectionTextEntryWidget, SurveyElement.sections),
      ),

      // scored
      Row(children: [
        Padding(padding: const EdgeInsets.only(top: 16, left: 16), child: Text("Scored", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
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
        title: Row(children: [
          Expanded(child: Text(
            label,
            maxLines: 2,
            style: Styles().textStyles?.getTextStyle('widget.detail.small'),
          )),
          Expanded(child: _buildEntryManagementOptions((parentIndex ?? -1) + 1, surveyElement, 
            element: parentElement,
            parentElement: grandParentElement,
            addRemove: parentElement != null && parentIndex != null && !hideEntryManagement,
            editable: parentElement != null && !hideEntryManagement
          )),
        ],),
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          dataList.isNotEmpty ? ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
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
              Expanded(child: _buildEntryManagementOptions(0, surveyElement, parentElement: parentElement))
            ]
          )),
        ],
      ),
    );
  }

  Widget _buildSurveyDataWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? _) {
    String entryText = (data as SurveyData).key;
    if (data.section?.isNotEmpty ?? false) {
      entryText += ' (${data.section})';
    }
    Widget surveyDataText = Text(entryText, style: Styles().textStyles?.getTextStyle('widget.detail.small'),);
    Widget displayEntry = Card(child: Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        surveyDataText,
        Expanded(child: _buildEntryManagementOptions(index + 1, surveyElement)),
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
    Widget ruleText = Text(summary, style: Styles().textStyles?.getTextStyle('widget.detail.small'), overflow: TextOverflow.fade);
    if (ruleElem is RuleReference || ruleElem is RuleAction || ruleElem is RuleComparison) {
      displayEntry = Card(child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: Row(children: [
          ruleText,
          Expanded(child: _buildEntryManagementOptions(index + 1, surveyElement, element: ruleElem, parentElement: parentElement, addRemove: addRemove)),
        ],)
      ));
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

    return LongPressDraggable<int>(
      data: index,
      maxSimultaneousDrags: 1,
      feedback: Card(child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: ruleText
      )),
      child: DragTarget<int>(
        builder: (BuildContext context, List<int?> accepted, List<dynamic> rejected) {
          return displayEntry;
        },
        onAccept: (oldIndex) => surveyElement == SurveyElement.followUpRules ? _onAcceptFlowRuleDrag(oldIndex, index) : _onAcceptResultRuleDrag(oldIndex, index),
      ),
      childWhenDragging: displayEntry,
      axis: Axis.vertical,
    );
  }

  Widget _buildSectionTextEntryWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement) {
    Widget sectionTextEntry = TextField(controller: data as TextEditingController, style: Styles().textStyles?.getTextStyle('widget.detail.small'),);
    return Row(children: [
      Expanded(child: sectionTextEntry),
      Expanded(child: _buildEntryManagementOptions(index + 1, surveyElement, editable: false)),
    ],);
  }

  Widget _buildEntryManagementOptions(int index, SurveyElement surveyElement, {RuleElement? element, RuleElement? parentElement, bool addRemove = true, bool editable = true}) {
    //TODO: in certain cases, do not show remove button when list size is = 2 (logic, cases, actions)
    BoxConstraints constraints = const BoxConstraints(maxWidth: 64, maxHeight: 80,);
    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
      Visibility(visible: addRemove, child: IconButton(
        icon: Styles().images?.getImage('plus-circle', color: Styles().colors?.getColor('fillColorPrimary'), size: 14) ?? const Icon(Icons.add),
        onPressed: () => _onTapAdd(index, surveyElement, parentElement: parentElement),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        constraints: constraints,
      )),
      Visibility(visible: addRemove && index > 0, child: IconButton(
        icon: Styles().images?.getImage('clear', size: 14) ?? const Icon(Icons.remove),
        onPressed: () => _onTapRemove(index - 1, surveyElement, parentElement: parentElement),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        constraints: constraints,
      )),
      Visibility(visible: editable && index > 0, child: IconButton(
        icon: Styles().images?.getImage('edit-white', color: Styles().colors?.getColor('fillColorPrimary'), size: 14) ?? const Icon(Icons.edit),
        onPressed: () => _onTapEdit(index - 1, surveyElement, element: element),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        constraints: constraints,
      )),
    ]);
  }

  void _onTapAdd(int index, SurveyElement surveyElement, {RuleElement? parentElement}) {
    switch (surveyElement) {
      case SurveyElement.data: _onTapAddDataAtIndex(index); break;
      case SurveyElement.sections: _onTapAddSectionAtIndex(index); break;
      default: _onTapAddRuleElementForId(index, surveyElement, parentElement); break;
    }
  }

  void _onTapRemove(int index, SurveyElement surveyElement, {RuleElement? parentElement}) {
    switch (surveyElement) {
      case SurveyElement.data: _onTapRemoveDataAtIndex(index); break;
      case SurveyElement.sections: _onTapRemoveSectionAtIndex(index); break;
      default: _onTapRemoveRuleElementForId(index, surveyElement, parentElement); break;
    }
  }

  void _onTapEdit(int index, SurveyElement surveyElement, {RuleElement? element}) {
    switch (surveyElement) {
      case SurveyElement.data: _onTapEditData(index); break;
      case SurveyElement.followUpRules: _onTapEditRuleElement(element, surveyElement); break;
      case SurveyElement.resultRules: _onTapEditRuleElement(element, surveyElement); break;
      default: return;
    }
  }

  void _onAcceptDataDrag(int oldIndex, int newIndex) {
    _updateState(() {
      SurveyData temp = _data[oldIndex];
      _data.removeAt(oldIndex);
      _data.insert(newIndex, temp);
    });

    _onAcceptFlowRuleDrag(oldIndex, newIndex);
  }

  void _onAcceptFlowRuleDrag(int oldIndex, int newIndex) {
    _updateState(() {
      RuleResult temp = _followUpRules[oldIndex];
      _followUpRules.removeAt(oldIndex);
      _followUpRules.insert(newIndex, temp);
    });
  }

  void _onAcceptResultRuleDrag(int oldIndex, int newIndex) {
    _updateState(() {
      RuleResult temp = _resultRules[oldIndex];
      _resultRules.removeAt(oldIndex);
      _resultRules.insert(newIndex, temp);
    });
  }

  void _onTapEditData(int index) async {
    List<String> sections = [];
    for (TextEditingController controller in _sectionTextControllers) {
      if (controller.text.isNotEmpty) {
        sections.add(controller.text);
      }
    }
    SurveyData updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataCreationPanel(data: _data[index], sections: sections, tabBar: widget.tabBar)));
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
            if (_followUpRules[i].updateElementById(ruleElement)) {
              return;
            }
          }
        } else {
          for (int i = 0; i < _resultRules.length; i++) {
            if (element.id == _resultRules[i].id && ruleElement is RuleResult) {
              _resultRules[i] = ruleElement;
              return;
            }
            if (_resultRules[i].updateElementById(ruleElement)) {
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
    } else {
      insert = SurveyQuestionTrueFalse(text: "", key: "data${dataCount++}");
    }
    _updateState(() {
      _data.insert(index, insert);
      if (index == 0) {
        if (_followUpRules.isEmpty) {
          _followUpRules.add(RuleAction(action: "return", data: "data.${insert.key}"));
        } else {
          _followUpRules[0] = RuleAction(action: "return", data: "data.${insert.key}");
          _followUpRules.insert(1, RuleAction(action: "return", data: "data.${_data[1].key}"));
        }
      } else {
        _followUpRules.insert(index, RuleAction(action: "return", data: "data.${_data[index].key}"));
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

  void _onTapAddSectionAtIndex(int index) {
    _updateState(() {
      _sectionTextControllers.insert(index, TextEditingController(text: index > 0 ? _sectionTextControllers[index - 1].text : ''));
    });
  }

  void _onTapRemoveSectionAtIndex(int index) {
    _sectionTextControllers[index].dispose();
    _updateState(() {
      _sectionTextControllers.removeAt(index);
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
      element.conditions.insert(index, RuleComparison(dataKey: "", operator: "==", compareTo: ""));
    }

    _updateState(() {
      if (element == null && surveyElement == SurveyElement.resultRules) {
         _resultRules.insert(index, RuleAction(action: "save", data: null));
      } else if (element != null) {
        for (RuleResult result in surveyElement == SurveyElement.followUpRules ? _followUpRules : _resultRules) {
          if (result.updateElementById(element)) {
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
      } else if (element != null) {
        for (RuleResult result in surveyElement == SurveyElement.followUpRules ? _followUpRules : _resultRules) {
          if (result.updateElementById(element)) {
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
  
  Survey _buildSurvey() {
    String? defaultDataKey;
    RuleResult? defaultDataKeyRule;
    for (int i = 0; i < _followUpRules.length; i++) {
      RuleResult rule = _followUpRules[i];
      if (i == 0) {
        if (rule is RuleAction && rule.action == 'return' && rule.data is String && (rule.data as String).isNotEmpty) {
          defaultDataKey = (rule.data as String).split('.').last;
        } else {
          defaultDataKeyRule = rule;
        }
      } else {
        if (rule is RuleAction && rule.action == 'return' && rule.data is String && (rule.data as String).isNotEmpty) {
          _data[i].defaultFollowUpKey = (rule.data as String).split('.').last;
        } else {
          _data[i].followUpRule = rule;
        }
      }
    }

    //TODO: map rules into each survey data
    return Survey(
      id: '',
      data: Map.fromIterable(_data, key: (item) => (item as SurveyData).key),
      type: '',
      scored: _scored,
      title: _textControllers["title"]?.text ?? 'New Survey',
      moreInfo: _textControllers["more_info"]?.text,
      defaultDataKey: defaultDataKey,
      defaultDataKeyRule: defaultDataKeyRule,
      resultRules: _resultRules,
      // responseKeys: _responseKeys,
      // constants: _constants,
      // strings: _strings,
      // subRules: _subRules,
    );
  }

  void _onTapPreview() {
    // describe result rules that would have been evaluated on continue
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

enum SurveyElement { data, sections, followUpRules, resultRules }
