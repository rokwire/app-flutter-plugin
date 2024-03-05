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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/gen/styles.dart';

import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/model/options.dart';
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widget_builders/buttons.dart';
import 'package:rokwire_plugin/ui/widgets/expansion_tile.dart' as rokwire;
import 'package:rokwire_plugin/utils/utils.dart';

typedef AddRemoveFunc = Function(int, SurveyElement, RuleElement?);
typedef EditFunc = Function(int, SurveyElement, RuleElement?, RuleElement?);
typedef SurveyElementWidgetBuilder = Widget Function(int, dynamic, SurveyElement, RuleElement?, int);

enum SurveyElementListType { data, textEntry, checklist, rules, options, actions }

class SurveyElementList extends StatefulWidget {
  final SurveyElementListType type;
  final String label;
  final List<dynamic> dataList;
  final List<String?>? dataSubtitles;
  final List<GlobalKey>? widgetKeys;
  final List<GlobalKey>? targetWidgetKeys;
  final SurveyElement surveyElement;

  final AddRemoveFunc? onAdd;
  final EditFunc? onEdit;
  final AddRemoveFunc? onRemove;
  final Function(int, dynamic)? onChanged;
  final Function(int, int)? onDrag;
  final Function(GlobalKey?)? onScroll;
  final rokwire.ExpansionTileController? controller;

  final bool labelStart;
  final bool singleton;
  final int? limit;

  const SurveyElementList({
    Key? key,
    required this.type,
    required this.label,
    required this.dataList,
    this.dataSubtitles,
    this.widgetKeys,
    this.targetWidgetKeys,
    required this.surveyElement,
    this.onAdd,
    this.onEdit,
    this.onRemove,
    this.onChanged,
    this.onDrag,
    this.onScroll,
    this.controller,
    this.labelStart = false,
    this.singleton = false,
    this.limit
  }) : super(key: key);

  @override
  State<SurveyElementList> createState() => _SurveyElementListState();
}

class _SurveyElementListState extends State<SurveyElementList> {
  final double _entryManagementButtonSize = 36;
  //TODO: make 17 a function of screen width
  int _flexMax = 17;
  bool _handleScrolling = false;

  @override
  void initState() {
    if (widget.singleton) {
      _flexMax--;
    }
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    _handleScrolling = CollectionUtils.isNotEmpty(widget.widgetKeys) || CollectionUtils.isNotEmpty(widget.targetWidgetKeys);

    late SurveyElementWidgetBuilder listItemBuilder;
    switch (widget.type) {
      case SurveyElementListType.data:
        listItemBuilder = _buildSurveyDataWidget;
        break;
      case SurveyElementListType.textEntry:
        listItemBuilder = _buildTextEntryWidget;
        break;
      case SurveyElementListType.checklist:
        listItemBuilder = _buildChecklistWidget;
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
      return widget.dataList.isNotEmpty ? listItemBuilder(0, widget.dataList.first, widget.surveyElement, null, 0) : Container();
    }
    return _buildCollapsibleWrapper(widget.label, widget.dataList, listItemBuilder, widget.surveyElement);
  }

  Widget _buildCollapsibleWrapper(String label, Iterable<dynamic> dataList, SurveyElementWidgetBuilder listItemBuilder, SurveyElement surveyElement,
    {RuleElement? parentElement, int? parentIndex, RuleElement? grandParentElement, int depth = 0}) {
    bool useSubtitle = surveyElement == SurveyElement.followUpRules && grandParentElement == null && parentIndex != null && _handleScrolling && widget.dataSubtitles?[parentIndex] != null;
    bool titleAddRemove = parentElement != null && parentIndex != null && (grandParentElement != null || surveyElement != SurveyElement.followUpRules);
    int numButtons = _numEntryManagementButtons(parentIndex ?? -1, element: parentElement, parentElement: grandParentElement, addRemove: titleAddRemove, editable: parentElement != null);
    Widget title = Row(children: [
      Expanded(flex: _flexMax - 2 * numButtons - depth, child: _handleScrolling && widget.dataSubtitles != null ? Text.rich(
        TextSpan(children: _buildTextSpansForLink(label, surveyElement)),
        overflow: TextOverflow.ellipsis,
        maxLines: 3,
      ) : Text(
        label,
        style: AppTextStyles.widgetDetailMedium,
        overflow: TextOverflow.ellipsis,
        maxLines: 3,
      )),
      Expanded(flex: 2 * numButtons, child: _buildEntryManagementOptions(parentIndex ?? -1, surveyElement,
        element: parentElement, parentElement: grandParentElement, addRemove: titleAddRemove, editable: parentElement != null
      )),
    ],);
    return Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: Padding(
      padding: parentElement != null ? const EdgeInsets.symmetric(vertical: 4) : EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        elevation: parentElement != null ? 1.0 : 0.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        child: ListTileTheme(horizontalTitleGap: 8, child: rokwire.ExpansionTile(
          key: grandParentElement == null && (parentIndex ?? 0) > 0 && _handleScrolling ? (widget.targetWidgetKeys?[parentIndex! - 1]) : null,
          controller: parentElement == null ? widget.controller : null,
          iconColor: AppColors.fillColorSecondary,
          backgroundColor: AppColors.background,
          collapsedBackgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          title: useSubtitle ? GestureDetector(
            onTap: widget.onScroll != null && parentIndex > 0 ? () => widget.onScroll!(widget.widgetKeys![parentIndex - 1]) : null,
            child: Text.rich(TextSpan(children: [
              TextSpan(
                text: 'From ',
                style: AppTextStyles.widgetDetailMedium,
              ),
              TextSpan(
                text: widget.dataSubtitles![parentIndex]!,
                style: AppTextStyles.widgetButtonTitleMediumBoldUnderline,
              ),
            ],),),
          ) : title,
          subtitle: useSubtitle ? Padding(padding: const EdgeInsets.only(bottom: 4), child: title) : null,
          children: [
            Container(height: 2, color: AppColors.fillColorSecondary,),
            dataList.isNotEmpty ? ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: dataList.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: listItemBuilder(index, dataList.elementAt(index), surveyElement, parentElement, depth));
              },
            ) : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _buildEntryManagementOptions(-1, surveyElement, parentElement: parentElement, editable: false)
            ),
          ],
        ))
      )
    ));
  }

  Widget _buildSurveyDataWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement, int depth) {
    String entryText = '';
    if (data is SurveyData) {
      entryText = data.key;
      if (CollectionUtils.isNotEmpty(data.sections)) {
        entryText += ' (${data.sections!.join(', ')})';
      } else if (data.section?.isNotEmpty ?? false) {
        entryText += ' (${data.section})';
      }
    } else if (data is String) {
      entryText = data;
    }
    
    Widget dataKeyText = Text('${index + 1}. $entryText', style: AppTextStyles.widgetDetailMedium, overflow: TextOverflow.ellipsis, maxLines: 2,);
    List<Widget> textWidgets = [dataKeyText];
    if (_handleScrolling && widget.dataSubtitles?[index] != null) {
      textWidgets.add(GestureDetector(
        onTap: widget.onScroll != null ? () => widget.onScroll!(widget.widgetKeys![index]) : null,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(widget.dataSubtitles![index]!, style: AppTextStyles.widgetButtonTitleMediumBoldUnderline)
        )
      ));
    }
    Widget surveyDataText = Column(crossAxisAlignment: CrossAxisAlignment.start, children: textWidgets);
    int numButtons = _numEntryManagementButtons(index);
    Widget displayEntry = Card(
      key: _handleScrolling ? (widget.targetWidgetKeys?[index]) : null,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      child: InkWell(
        onTap: widget.onEdit != null ? () => widget.onEdit!(index, surveyElement, null, null) : null,
        child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(flex: _flexMax - 2 * numButtons - depth, child: Padding(padding: const EdgeInsets.only(left: 8), child: surveyDataText)),
          Expanded(flex: 2 * numButtons, child: _buildEntryManagementOptions(index, surveyElement)),
        ],))
      )
    );

    return widget.onDrag != null ? LongPressDraggable<Pair<int, SurveyElement>>(
      data: Pair(index, surveyElement),
      maxSimultaneousDrags: 1,
      feedback: Card(child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: AppColors.surface),
        child: Align(alignment: Alignment.centerLeft, child: dataKeyText),
      )),
      child: DragTarget<Pair<int, SurveyElement>>(
        builder: (BuildContext context, List<Pair<int, SurveyElement>?> accepted, List<dynamic> rejected) {
          return displayEntry;
        },
        onAcceptWithDetails: (DragTargetDetails<Pair<int, SurveyElement>> details) => details.data.right == surveyElement && details.data.left != index ? widget.onDrag!(details.data.left, index) : null,
      ),
      childWhenDragging: displayEntry,
      axis: Axis.vertical,
    ) : displayEntry;
  }

  Widget _buildTextEntryWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement, int depth) {
    Widget sectionTextEntry = TextField(
      controller: data as TextEditingController,
      style: AppTextStyles.widgetDetailMedium,
      decoration: InputDecoration.collapsed(
        hintText: surveyElement == SurveyElement.sections ? "Section Name" : "Value",
        border: InputBorder.none,
      ),
    );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(flex: 3, child: Padding(padding: const EdgeInsets.only(left: 8), child: sectionTextEntry)),
          Expanded(child: _buildEntryManagementOptions(index, surveyElement, editable: false)),
      ],))
    );
  }
  
  Widget _buildChecklistWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement, int depth) {
    if (data is Pair<String, bool>) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: AppColors.surface,
        child: SurveyElementCreationWidget.buildCheckboxWidget(data.left, data.right, widget.onChanged != null ? (value) => widget.onChanged!(index, value) : null, padding: EdgeInsets.zero)
      );
    }
    return Container();
  }

  Widget _buildRuleWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement, int depth) {
    if (data is RuleElement) {
      String summary = data.getSummary(prefix: parentElement is Rule ? (index == 0 ? 'Yes:' : 'No:') : null);
      if (widget.labelStart && index == 0 && surveyElement == SurveyElement.followUpRules && parentElement == null) {
        summary = "Start: $summary";
      }

      bool addRemove = false;
      int? ruleElemIndex;
      if (parentElement is RuleCases) {
        ruleElemIndex = parentElement.cases.indexOf(data as Rule);
      } else if (parentElement is RuleActionList) {
        addRemove = true;
        ruleElemIndex = parentElement.actions.indexOf(data as RuleAction);
      } else if (parentElement is RuleLogic) {
        addRemove = true;
        ruleElemIndex = parentElement.conditions.indexOf(data as RuleCondition);
      } else if (parentElement == null && !widget.singleton) {
        addRemove = (surveyElement == SurveyElement.resultRules);
        ruleElemIndex = index;
      }

      late Widget displayEntry;
      if (data is RuleReference || data is RuleAction || data is RuleComparison) {
        List<Widget> textWidgets = [];
        if (widget.dataSubtitles != null) {
          if (surveyElement == SurveyElement.followUpRules && parentElement == null && _handleScrolling && widget.dataSubtitles![index] != null) {
            textWidgets.add(Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text.rich(TextSpan(children: [
                TextSpan(
                  text: 'From ',
                  style: AppTextStyles.widgetDetailMedium,
                ),
                TextSpan(
                  text: widget.dataSubtitles![index]!,
                  style: AppTextStyles.widgetButtonTitleMediumBoldUnderline,
                  recognizer: TapGestureRecognizer()..onTap = widget.onScroll != null ? () => widget.onScroll!(widget.widgetKeys![index - 1]) : null 
                ),
              ],), overflow: TextOverflow.ellipsis, maxLines: 2,)
            ));
          }
          textWidgets.add(Text.rich(TextSpan(children: _buildTextSpansForLink(summary, surveyElement)), overflow: TextOverflow.ellipsis, maxLines: 2,));
        } else {
          textWidgets.add(Text(summary, style: AppTextStyles.widgetDetailMedium, overflow: TextOverflow.ellipsis, maxLines: 2,));
        }
        Widget ruleText = Column(crossAxisAlignment: CrossAxisAlignment.start, children: textWidgets);
        int numButtons = _numEntryManagementButtons(index, element: data, parentElement: parentElement, addRemove: addRemove);
        displayEntry = Card(
          key: _handleScrolling && parentElement == null && index > 0 ? (widget.targetWidgetKeys?[index - 1]) : null,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          child: InkWell(
            onTap: widget.onEdit != null ? () => widget.onEdit!(index, surveyElement, data, parentElement) : null,
            child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
              Expanded(flex: _flexMax - 2 * numButtons - depth, child: Padding(padding: const EdgeInsets.only(left: 8), child: ruleText)),
              Expanded(flex: 2 * numButtons, child: _buildEntryManagementOptions(index, surveyElement, element: data, parentElement: parentElement, addRemove: addRemove)),
            ],))
          )
        );
      } else if (data is RuleLogic) {
        displayEntry = _buildCollapsibleWrapper(parentElement is Rule ? 'Conditions' : summary, data.conditions, _buildRuleWidget, surveyElement, parentElement: data, parentIndex: ruleElemIndex, grandParentElement: parentElement, depth: ++depth);
      } else if (data is Rule) {
        bool isComparison = data.condition is RuleComparison;
        String label = data.condition?.getSummary(prefix: parentElement is Rule ? (index == 0 ? 'Yes:' : 'No:') : null) ?? "";
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
        displayEntry = _buildCollapsibleWrapper(label, elementsSlice, _buildRuleWidget, surveyElement, parentElement: data, parentIndex: ruleElemIndex, grandParentElement: parentElement, depth: ++depth);
      } else if (data is RuleCases) {
        displayEntry = _buildCollapsibleWrapper(summary, data.cases, _buildRuleWidget, surveyElement, parentElement: data, parentIndex: ruleElemIndex, grandParentElement: parentElement, depth: ++depth);
      } else if (data is RuleActionList) {
        displayEntry = _buildCollapsibleWrapper(summary, data.actions, _buildRuleWidget, surveyElement, parentElement: data, parentIndex: ruleElemIndex, grandParentElement: parentElement, depth: ++depth);
      }

      // return LongPressDraggable<String>(
      //   data: ruleElem.id,
      //   maxSimultaneousDrags: 1,
      //   feedback: Card(child: Container(
      //     padding: const EdgeInsets.all(16),
      //     decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: AppColors.surface),
      //     child: Align(alignment: Alignment.centerLeft, child: ruleText)
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

  Widget _buildOptionsWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement, int depth) {
    if (data is OptionData) {
      String entryText = data.title;
      if (data.value != null) {
        String valueString = data.value.toString();
        if (valueString.isNotEmpty && valueString != entryText) {
          entryText += entryText.isNotEmpty ? ' ($valueString)' : '($valueString)';
        }
      }
      Widget optionDataText = Text(
        '${index + 1}. $entryText',
        style: data.isCorrect ? AppTextStyles.widgetDetailRegularBold : AppTextStyles.widgetDetailMedium,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      );
      Widget displayEntry = Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        child: InkWell(
          onTap: widget.onEdit != null ? () => widget.onEdit!(index, surveyElement, null, null) : null,
          child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
            Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(left: 8), child: optionDataText)),
            Expanded(child: _buildEntryManagementOptions(index, surveyElement, parentElement: parentElement)),
          ],))
        )
      );

      return widget.onDrag != null ? LongPressDraggable<int>(
        data: index,
        maxSimultaneousDrags: 1,
        feedback: Card(child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: AppColors.surface),
          child: optionDataText,
        )),
        child: DragTarget<int>(
          builder: (BuildContext context, List<int?> accepted, List<dynamic> rejected) {
            return displayEntry;
          },
          onAcceptWithDetails: (DragTargetDetails<int> details) => details.data != index ? widget.onDrag!(details.data, index) : null,
        ),
        childWhenDragging: displayEntry,
        axis: Axis.vertical,
      ) : displayEntry;
    }
    return Container();
  }

  Widget _buildActionsWidget(int index, dynamic data, SurveyElement surveyElement, RuleElement? parentElement, int depth) {
    if (data is ActionData) {
      Widget actionDataText = Text('${index + 1}. ${data.label ?? 'New Action'}', style: AppTextStyles.widgetDetailMedium, overflow: TextOverflow.ellipsis, maxLines: 2,);
      List<Widget> textWidgets = [actionDataText];
      if (data.data != null) {
        String dataString = data.data.toString();
        if (dataString.isNotEmpty) {
          textWidgets.add(Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(dataString, style: AppTextStyles.widgetDetailMedium)
          ));
        }
      }
      Widget actionText = Column(crossAxisAlignment: CrossAxisAlignment.start, children: textWidgets);
      Widget displayEntry = Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        child: InkWell(
          onTap: widget.onEdit != null ? () => widget.onEdit!(index, surveyElement, null, null) : null,
          child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
            Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(left: 8), child: actionText)),
            Expanded(child: _buildEntryManagementOptions(index, surveyElement, parentElement: parentElement)),
          ],))
        )
      );

      return widget.onDrag != null ? LongPressDraggable<int>(
        data: index,
        maxSimultaneousDrags: 1,
        feedback: Card(child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: AppColors.surface),
          child: actionDataText,
        )),
        child: DragTarget<int>(
          builder: (BuildContext context, List<int?> accepted, List<dynamic> rejected) {
            return displayEntry;
          },
          onAcceptWithDetails: (DragTargetDetails<int> details) => details.data != index ? widget.onDrag!(details.data, index) : null,
        ),
        childWhenDragging: displayEntry,
        axis: Axis.vertical,
      ) : displayEntry;
    }
    return Container();
  }

  Widget _buildEntryManagementOptions(int index, SurveyElement surveyElement, {RuleElement? element, RuleElement? parentElement, bool addRemove = true, bool editable = true}) {
    if (element is! RuleLogic || parentElement is! Rule) {
      bool ruleRemove = true;
      if ((parentElement is RuleLogic || parentElement is RuleCases || parentElement is RuleActionList) && index < 2) {
        ruleRemove = false;
      }

      bool belowLimit = true;
      if (widget.limit != null && widget.dataList.length >= widget.limit!) {
        belowLimit = false;
      }

      double buttonSize = _entryManagementButtonSize / 2;
      return Align(alignment: Alignment.centerRight, child: Row(mainAxisSize: MainAxisSize.min, children: [
        Visibility(visible: addRemove && belowLimit, child: SizedBox(width: _entryManagementButtonSize, height: _entryManagementButtonSize, child: IconButton(
          icon: Styles().images.getImage('plus-circle', color: AppColors.fillColorPrimary, size: buttonSize) ?? const Icon(Icons.add),
          onPressed: widget.onAdd != null ? () => widget.onAdd!(index + 1, surveyElement, parentElement) : null,
          padding: EdgeInsets.zero,
          splashRadius: buttonSize,
        ))),
        Visibility(visible: editable, child: SizedBox(width: _entryManagementButtonSize, height: _entryManagementButtonSize, child: IconButton(
          icon: Styles().images.getImage('edit-white', color: AppColors.fillColorPrimary, size: buttonSize) ?? const Icon(Icons.edit),
          onPressed: widget.onEdit != null ? () => widget.onEdit!(index, surveyElement, element, parentElement) : null,
          padding: EdgeInsets.zero,
          splashRadius: buttonSize,
        ))),
        Visibility(visible: addRemove && ruleRemove && index >= 0, child: SizedBox(width: _entryManagementButtonSize, height: _entryManagementButtonSize, child: IconButton(
          icon: Styles().images.getImage('clear', size: buttonSize) ?? const Icon(Icons.remove),
          onPressed: widget.onRemove != null ? () => _onRemove(index, surveyElement, parentElement) : null,
          padding: EdgeInsets.zero,
          splashRadius: buttonSize,
        ))),
      ]));
    }
    return Container();
  }

  int _numEntryManagementButtons(int index, {RuleElement? element, RuleElement? parentElement, bool addRemove = true, bool editable = true}) {
    int numButtons = 0;
    if (element is! RuleLogic || parentElement is! Rule) {
      bool ruleRemove = true;
      if ((parentElement is RuleLogic || parentElement is RuleCases || parentElement is RuleActionList) && index < 2) {
        ruleRemove = false;
      }

      bool belowLimit = true;
      if (widget.limit != null && widget.dataList.length >= widget.limit!) {
        belowLimit = false;
      }

      if (addRemove && belowLimit) {
        numButtons++;
      }
      if (editable) {
        numButtons++;
      }
      if (addRemove && ruleRemove && index >= 0) {
        numButtons++;
      }
    }
    return numButtons;
  }

  List<InlineSpan> _buildTextSpansForLink(String label, SurveyElement surveyElement) {
    List<String> splitLabel = label.split(" ");
    int widgetKeyOffset = surveyElement == SurveyElement.followUpRules ? -1 : 0;
    List<InlineSpan> textSpans = [];
    bool previousLink = false;
    for (String partialLink in splitLabel) {
      int dataKeyIndex = widget.dataSubtitles!.indexOf(partialLink);
      if (dataKeyIndex > 0) {
        textSpans.add(TextSpan(
          text: partialLink,
          style: AppTextStyles.widgetButtonTitleMediumBoldUnderline,
          recognizer: TapGestureRecognizer()..onTap = widget.onScroll != null ? () => widget.onScroll!(widget.widgetKeys![dataKeyIndex + widgetKeyOffset]) : null,  
        ));
        previousLink = true;
      } else {
        String text = partialLink;
        if (previousLink) {
          text = ' ' + text;
        }
        if (partialLink != splitLabel.last) {
          text += ' ';
        }
        textSpans.add(TextSpan(
          text: text,
          style: AppTextStyles.widgetDetailMedium,
        ));
        previousLink = false;
      }
    }

    return textSpans;
  }

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
    widget.onRemove!(index, surveyElement, parentElement);
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

  const SurveyElementCreationWidget({Key? key, required this.body, required this.completionOptions, required this.scrollController}) : super(key: key);

  @override
  State<SurveyElementCreationWidget> createState() => _SurveyElementCreationWidgetState();

  static Widget buildDropdownWidget<T>(Map<T?, String> supportedItems, String label, T? value, Function(T?)? onChanged,
    {EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16), EdgeInsetsGeometry margin = const EdgeInsets.only(top: 16)}) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: AppColors.surface),
      padding: padding,
      margin: margin,
      child: Row(children: [
        Text(label, style: AppTextStyles.widgetMessageRegular),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<T>(
            icon: Styles().images.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: AppTextStyles.widgetDetailRegular,
            items: buildDropdownItems<T>(supportedItems),
            value: value,
            onChanged: onChanged,
            dropdownColor: AppColors.surface,
          ),
        ),))],
      )
    );
  }

  static Widget buildCheckboxWidget(String label, bool value, Function(bool?)? onChanged, {EdgeInsetsGeometry padding = const EdgeInsets.only(top: 16.0)}) {
    return Padding(padding: padding, child: CheckboxListTile(
      title: Padding(padding: const EdgeInsets.only(left: 8), child: Text(label, style: AppTextStyles.widgetMessageRegular)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      tileColor: AppColors.surface,
      checkColor: AppColors.surface,
      activeColor: AppColors.fillColorPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(item.value, style: AppTextStyles.widgetDetailRegular, textAlign: TextAlign.center, maxLines: 2,)
        ),
        alignment: Alignment.centerRight,
      ));
    }
    return items;
  }

  static dynamic parseTextForType(String text) {
    text = text.trim();
    bool? valueBool = text.toLowerCase() == 'true' ? true : (text.toLowerCase() == 'false' ? false : null);
    return num.tryParse(text) ?? DateTimeUtils.dateTimeFromString(text) ?? valueBool ?? (text == null.toString() ? null : text);
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
          color: AppColors.backgroundVariant,
          child: widget.completionOptions,
        ),
      ],
    );
  }
}