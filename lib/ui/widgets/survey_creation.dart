// Copyright 2023 Board of Trustees of the University of Illinois.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/model/options.dart';
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widget_builders/buttons.dart';

typedef EntryManagementFunc = Function(int, SurveyElement, RuleElement?);

enum SurveyElementListType { data, sections, rules, options, actions }

class SurveyElementList extends StatefulWidget {
  final SurveyElementListType type;
  final String label;
  final List<dynamic> dataList;
  final SurveyElement surveyElement;

  final EntryManagementFunc? onAdd;
  final EntryManagementFunc? onEdit;
  final EntryManagementFunc? onRemove;
  final Function(int, int)? onDrag;

  final bool labelStart;
  final bool singleton;

  const SurveyElementList({Key? key, required this.type, required this.label, required this.dataList, required this.surveyElement,
    this.onAdd, this.onEdit, this.onRemove, this.onDrag, this.labelStart = false, this.singleton = false});

  @override
  State<SurveyElementList> createState() => _SurveyElementListState();
}

class _SurveyElementListState extends State<SurveyElementList> {
  @override
  Widget build(BuildContext context) {
    late Widget Function(int, dynamic, SurveyElement, RuleElement?) listItemBuilder;
    switch (widget.type) {
      case SurveyElementListType.data:
        listItemBuilder = _buildSurveyDataWidget;
        break;
      case SurveyElementListType.sections:
        listItemBuilder = _buildSectionTextEntryWidget;
        break;
      case SurveyElementListType.rules:
        listItemBuilder = _buildRuleWidget;
        break;
      case SurveyElementListType.options:
        listItemBuilder = _buildOptionsWidget;
        break;
      case SurveyElementListType.actions:
        listItemBuilder = _buildActionsWidget;
        break;
    }

    if (widget.singleton) {
      return widget.dataList.isNotEmpty ? listItemBuilder(0, widget.dataList.first, widget.surveyElement, null) : Container();
    }
    return _buildCollapsibleWrapper(widget.label, widget.dataList, listItemBuilder, widget.surveyElement);
  }

  Widget _buildCollapsibleWrapper(String label, List<dynamic> dataList, Widget Function(int, dynamic, SurveyElement, RuleElement?) listItemBuilder, SurveyElement surveyElement, {RuleElement? parentElement, int? parentIndex, RuleElement? grandParentElement}) {
    bool hideEntryManagement = parentElement is RuleLogic && grandParentElement is Rule;
    return Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(
      iconColor: Styles().colors?.getColor('fillColorSecondary'),
      backgroundColor: Styles().colors?.getColor('background'),
      collapsedBackgroundColor: Styles().colors?.getColor('surface'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      title: Row(children: [
        Expanded(child: Text(
          label,
          maxLines: 2,
          style: Styles().textStyles?.getTextStyle(parentElement == null ? 'widget.detail.regular' : 'widget.detail.small'),
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
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: listItemBuilder(index, dataList[index], surveyElement, parentElement));
          },
        ) : Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0), child: Row(children: [
            Container(height: 0),
            Expanded(child: _buildEntryManagementOptions(0, surveyElement, parentElement: parentElement, editable: false))
          ]
        )),
      ],
    ));
  }

  Widget _buildSurveyDataWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement) {
    if (data is SurveyData) {
      String entryText = data.key;
      if (data.section?.isNotEmpty ?? false) {
        entryText += ' (${data.section})';
      }
      Widget surveyDataText = Text(entryText, style: Styles().textStyles?.getTextStyle('widget.detail.small'), overflow: TextOverflow.ellipsis);
      Widget displayEntry = Card(child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Padding(padding: const EdgeInsets.only(left: 8), child: surveyDataText),
          Expanded(child: _buildEntryManagementOptions(index + 1, surveyElement)),
        ],))
      ));

      return LongPressDraggable<int>(
        data: index,
        maxSimultaneousDrags: 1,
        feedback: Card(child: Container(
          height: 32,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Align(alignment: Alignment.centerLeft, child: surveyDataText)),
        )),
        child: DragTarget<int>(
          builder: (BuildContext context, List<int?> accepted, List<dynamic> rejected) {
            return displayEntry;
          },
          onAccept: widget.onDrag != null ? (oldIndex) => widget.onDrag!(oldIndex, index) : null,
        ),
        childWhenDragging: displayEntry,
        axis: Axis.vertical,
      );
    }
    return Container();
  }

  Widget _buildSectionTextEntryWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement) {
    Widget sectionTextEntry = TextField(
      controller: data as TextEditingController,
      style: Styles().textStyles?.getTextStyle('widget.detail.small'),
      decoration: const InputDecoration.collapsed(
        hintText: "Section Name",
        border: InputBorder.none,
      ),
    );
    return Card(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
      Expanded(child: Padding(padding: const EdgeInsets.only(left: 8), child: sectionTextEntry)),
      Expanded(child: _buildEntryManagementOptions(index + 1, surveyElement, editable: false)),
    ],)));
  }

  Widget _buildRuleWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement) {
    if (data is RuleElement) {
      String? prefix;
      if (parentElement is Rule) {
        prefix = index == 0 ? 'Yes:' : 'No:';
      }
      String summary = data.getSummary(prefix: prefix);
      if (widget.labelStart && index == 0 && surveyElement == SurveyElement.followUpRules && parentElement == null) {
        summary = "Start: $summary";
      }

      bool addRemove = false;
      int? ruleElemIndex;
      if (parentElement is RuleCases) {
        addRemove = true;
        ruleElemIndex = parentElement.cases.indexOf(data as Rule);
      } else if(parentElement is RuleActionList) {
        addRemove = true;
        ruleElemIndex = parentElement.actions.indexOf(data as RuleAction);
      } else if (parentElement is RuleLogic) {
        addRemove = true;
        ruleElemIndex = parentElement.conditions.indexOf(data as RuleCondition);
      } else if (parentElement == null && surveyElement == SurveyElement.resultRules) {
        addRemove = true;
        ruleElemIndex = index;
      }

      late Widget displayEntry;
      Widget ruleText = Text(summary, style: Styles().textStyles?.getTextStyle('widget.detail.small'), overflow: TextOverflow.fade);
      if (data is RuleReference || data is RuleAction || data is RuleComparison) {
        displayEntry = Card(child: Ink(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
          child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
            Padding(padding: const EdgeInsets.only(left: 8), child: ruleText),
            Expanded(child: _buildEntryManagementOptions(index + 1, surveyElement, element: data, parentElement: parentElement, addRemove: addRemove)),
          ],))
        ));
      } else if (data is RuleLogic) {
        displayEntry = _buildCollapsibleWrapper(parentElement is Rule ? 'Conditions' : summary, data.conditions, _buildRuleWidget, surveyElement, parentElement: data, parentIndex: ruleElemIndex, grandParentElement: parentElement);
      } else if (data is Rule) {
        bool isComparison = data.condition is RuleComparison;
        String label = data.condition?.getSummary() ?? "";
        List<RuleElement> elementsSlice = [];
        if (!isComparison) {
          elementsSlice.add(data.condition!);
        }
        if (data.trueResult != null) {
          elementsSlice.add(data.trueResult!);
        }
        if (data.falseResult != null) {
          elementsSlice.add(data.falseResult!);
        }
        displayEntry = _buildCollapsibleWrapper(label, elementsSlice, _buildRuleWidget, surveyElement, parentElement: data, parentIndex: ruleElemIndex, grandParentElement: parentElement);
      } else if (data is RuleCases) {
        displayEntry = _buildCollapsibleWrapper(summary, data.cases, _buildRuleWidget, surveyElement, parentElement: data, parentIndex: ruleElemIndex, grandParentElement: parentElement);
      } else if (data is RuleActionList) {
        displayEntry = _buildCollapsibleWrapper(summary, data.actions, _buildRuleWidget, surveyElement, parentElement: data, parentIndex: ruleElemIndex, grandParentElement: parentElement);
      }

      //TODO: should rule elements be draggable/swappable?
      // return LongPressDraggable<String>(
      //   data: ruleElem.id,
      //   maxSimultaneousDrags: 1,
      //   feedback: Card(child: Container(
      //     height: 32,
      //     decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      //     child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Align(alignment: Alignment.centerLeft, child: ruleText))
      //   )),
      //   child: DragTarget<String>(
      //     builder: (BuildContext context, List<String?> accepted, List<dynamic> rejected) {
      //       return displayEntry;
      //     },
      //     onAccept: (swapId) => _onAcceptRuleDrag(swapId, ruleElem.id, surveyElement, parentElement: parentElement),
      //   ),
      //   childWhenDragging: displayEntry,
      //   axis: Axis.vertical,
      // );
      return displayEntry;
    }
    return Container();
  }

  Widget _buildOptionsWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement) {
    if (data is OptionData) {
      String entryText = data.title;
      if (data.value != null) {
        String valueString = data.value.toString();
        if (valueString.isNotEmpty && valueString != entryText) {
          entryText += entryText.isNotEmpty ? ' ($valueString)' : '($valueString)';
        }
      }
      Widget surveyDataText = Text(entryText, style: Styles().textStyles?.getTextStyle(data.isCorrect ? 'widget.detail.small.fat' : 'widget.detail.small'),);
      Widget displayEntry = Card(child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        padding: const EdgeInsets.all(8.0),
        child: Row(children: [
          surveyDataText,
          Expanded(child: _buildEntryManagementOptions(index + 1, surveyElement, parentElement: parentElement)),
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
          onAccept: widget.onDrag != null ? (oldIndex) => widget.onDrag!(oldIndex, index) : null,
        ),
        childWhenDragging: displayEntry,
        axis: Axis.vertical,
      );
    }
    return Container();
  }

  Widget _buildActionsWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement) {
    if (data is ActionData) {
      Widget surveyDataText = Text(data.label ?? '', style: Styles().textStyles?.getTextStyle('widget.detail.small'),);
      Widget displayEntry = Card(child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        padding: const EdgeInsets.all(8.0),
        child: Row(children: [
          surveyDataText,
          Expanded(child: _buildEntryManagementOptions(index + 1, surveyElement, parentElement: parentElement)),
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
          onAccept: widget.onDrag != null ? (oldIndex) => widget.onDrag!(oldIndex, index) : null,
        ),
        childWhenDragging: displayEntry,
        axis: Axis.vertical,
      );
    }
    return Container();
  }

  Widget _buildEntryManagementOptions(int index, SurveyElement surveyElement, {RuleElement? element, RuleElement? parentElement, bool addRemove = true, bool editable = true}) {
    bool ruleRemove = true;
    if ((parentElement is RuleLogic || parentElement is RuleCases || parentElement is RuleActionList) && index <= 2) {
      ruleRemove = false;
    }

    double buttonBoxSize = 36;
    double splashRadius = 18;
    double buttonSize = 18;
    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
      Visibility(visible: addRemove, child: SizedBox(width: buttonBoxSize, height: buttonBoxSize, child: IconButton(
        icon: Styles().images?.getImage('plus-circle', color: Styles().colors?.getColor('fillColorPrimary'), size: buttonSize) ?? const Icon(Icons.add),
        onPressed: widget.onAdd != null ? () => widget.onAdd!(index, surveyElement, parentElement) : null,
        padding: EdgeInsets.zero,
        splashRadius: splashRadius,
      ))),
      Visibility(visible: editable, child: SizedBox(width: buttonBoxSize, height: buttonBoxSize, child: IconButton(
        icon: Styles().images?.getImage('edit-white', color: Styles().colors?.getColor('fillColorPrimary'), size: buttonSize) ?? const Icon(Icons.edit),
        onPressed: widget.onEdit != null ? () => widget.onEdit!(index - 1, surveyElement, element) : null,
        padding: EdgeInsets.zero,
        splashRadius: splashRadius,
      ))),
      Visibility(visible: addRemove && ruleRemove && index > 0, child: SizedBox(width: buttonBoxSize, height: buttonBoxSize, child: IconButton(
        icon: Styles().images?.getImage('clear', size: buttonSize) ?? const Icon(Icons.remove),
        onPressed: widget.onRemove != null ? () => _onRemove(index, surveyElement, parentElement) : null,
        padding: EdgeInsets.zero,
        splashRadius: splashRadius,
      ))),
    ]);
  }

  //TODO: add option to noot show removal popup again?
  void _onRemove(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    List<Widget> buttons = [
      Padding(padding: const EdgeInsets.only(right: 8), child: ButtonBuilder.standardRoundedButton(label: 'Yes', onTap: () => _removeElement(index, surveyElement, parentElement))),
      Padding(padding: const EdgeInsets.only(left: 8), child: ButtonBuilder.standardRoundedButton(label: 'No', onTap: _dismissRemoveElement)),
    ];
    ActionsMessage.show(context: context,
      title: "Remove Element",
      message: "Are you sure you want to remove this element?",
      buttons: buttons,
    );
  }

  void _removeElement(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    Navigator.pop(context);
    widget.onRemove!(index - 1, surveyElement, parentElement);
  }

  void _dismissRemoveElement() {
    Navigator.pop(context);
  }

  /*
  void _onAcceptRuleDrag(String swapId, String id, SurveyElement surveyElement, {RuleElement? parentElement}) {
    RuleElement? current = (surveyElement == SurveyElement.defaultResponseRule ? _defaultResponseRule : _scoreRule)?.findElement(id);
    RuleElement? swap = (surveyElement == SurveyElement.defaultResponseRule ? _defaultResponseRule : _scoreRule)?.findElement(swapId);
    current?.id = swapId;
    swap?.id = id;

    if (_maySwapRuleElements(current, swap, parentElement)) {
      setState(() {
        if (surveyElement == SurveyElement.defaultResponseRule) {
          if (swap!.id == _defaultResponseRule!.id && swap is RuleResult) {
            _defaultResponseRule = swap;
          } else {
            _defaultResponseRule!.updateElement(swap);
          }
          if (current!.id == _defaultResponseRule!.id && current is RuleResult) {
            _defaultResponseRule = current;
          } else {
            _defaultResponseRule!.updateElement(current);
          }
        } else {
          if (swap!.id == _scoreRule!.id && swap is RuleResult) {
            _scoreRule = swap;
          } else {
            _scoreRule!.updateElement(swap);
          }
          if (current!.id == _scoreRule!.id && current is RuleResult) {
            _scoreRule = current;
          } else {
            _scoreRule!.updateElement(current);
          }
        }
      });
    }
  }

  bool _maySwapRuleElements(RuleElement? current, RuleElement? swap, RuleElement? parentElement) {
    if (current is Rule) {
      return (swap is RuleResult) && (parentElement is! RuleCases);
    } else if (current is RuleAction) {
      return (swap is RuleResult) && (parentElement is! RuleActionList);
    } else if (current is RuleActionList || current is RuleCases) {
      return swap is RuleResult;
    } else if (current is RuleCondition) {
      return swap is RuleCondition;
    }
    return false;
  }
  */
}

class SurveyElementCreationWidget extends StatefulWidget {
  final Widget body;
  final Widget completionOptions;
  final ScrollController scrollController;

  const SurveyElementCreationWidget({Key? key, required this.body, required this.completionOptions, required this.scrollController});

  @override
  State<SurveyElementCreationWidget> createState() => _SurveyElementCreationWidgetState();

  static Widget buildDropdownWidget<T>(Map<T?, String> supportedItems, String label, T? value, Function(T?)? onChanged,
    {EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16), EdgeInsetsGeometry margin = const EdgeInsets.only(top: 16)}) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      padding: padding,
      margin: margin,
      child: Row(children: [
        Text(label, style: Styles().textStyles?.getTextStyle('widget.message.regular')),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<T>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: buildDropdownItems<T>(supportedItems),
            value: value,
            onChanged: onChanged,
            dropdownColor: Styles().colors?.getColor('surface'),
          ),
        ),))],
      )
    );
  }

  static Widget buildCheckboxWidget(String label, bool? value, Function(bool?)? onChanged, {EdgeInsetsGeometry padding = const EdgeInsets.only(top: 16.0)}) {
    return Padding(padding: padding, child: CheckboxListTile(
      title: Padding(padding: const EdgeInsets.only(left: 8), child: Text(label, style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      tileColor: Styles().colors?.getColor('surface'),
      checkColor: Styles().colors?.getColor('surface'),
      activeColor: Styles().colors?.getColor('fillColorPrimary'),
      value: value,
      onChanged: onChanged,
    ),);
  }

  static List<DropdownMenuItem<T>> buildDropdownItems<T>(Map<T?, String> supportedItems) {
    List<DropdownMenuItem<T>> items = [];

    for (MapEntry<T?, String> item in supportedItems.entries) {
      items.add(DropdownMenuItem<T>(
        value: item.key,
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Text(item.value, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)
        ),
        alignment: Alignment.centerRight,
      ));
    }
    return items;
  }
}

class _SurveyElementCreationWidgetState extends State<SurveyElementCreationWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: Scrollbar(
          radius: const Radius.circular(2),
          thumbVisibility: true,
          controller: widget.scrollController,
          child: SingleChildScrollView(
            controller: widget.scrollController,
            child: widget.body,
          ),
        )),
        Container(
          color: Styles().colors?.backgroundVariant,
          child: widget.completionOptions,
        ),
      ],
    );
  }
}