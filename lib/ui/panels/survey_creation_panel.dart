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
  bool _scored = true;
  // bool _sensitive = false;

  // final Map<String, String> _constants = {};
  // final Map<String, Map<String, String>> _strings = {};

  final List<RuleResult> _followUpRules = [RuleAction(action: "return", data: "(missing Survey Data)", displayDepth: 0)];
  final List<Rule> _resultRules = [];
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
    return Column(children: [
      // title
      FormFieldText('Title', controller: _textControllers["title"], inputType: TextInputType.text, textCapitalization: TextCapitalization.words, required: true),
      // more_info
      FormFieldText('Additional Information', controller: _textControllers["more_info"], multipleLines: true, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),
      // survey type (make this a dropdown?)
      FormFieldText('Type', controller: _textControllers["type"], multipleLines: false, inputType: TextInputType.text, textCapitalization: TextCapitalization.words, required: true),

      // data
      _buildCollapsibleWrapper("Survey Data", _data, _buildSurveyDataWidget),

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

      // follow up rules (determine survey data ordering/flow)
      _buildCollapsibleWrapper("Flow Rules", _followUpRules, _buildSurveyRuleWidget, addRemove: false),
      // result_rules
      _buildCollapsibleWrapper("Result Rules", _resultRules, _buildSurveyRuleWidget, addRemove: false),

      // constants
      // _buildCollapsibleWrapper("Constants", "constants", _constants.length, _buildStringMapEntryWidget),
      // strings
      // _buildCollapsibleWrapper("Strings", "strings", _strings.length, _buildStringMapWidget),
      // sub_rules
      // _buildCollapsibleWrapper("Sub Rules", "sub_rules", _subRules.length, _buildRuleWidget), //TODO: rule map widget
      // response_keys
      // _buildCollapsibleWrapper("Response Keys", "response_keys", _responseKeys?.length ?? 0, _buildStringListEntryWidget),
    ],);
  }

  Widget _buildPreviewAndContinue() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
        label: 'Preview',
        borderColor: Styles().colors?.fillColorPrimaryVariant,
        backgroundColor: Styles().colors?.surface,
        textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
        onTap: _onTapPreview,
      ))),
      Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: Stack(children: [
        Visibility(visible: _loading, child: LoadingBuilder.loading()),
        RoundedButton(
          label: 'Continue',
          borderColor: Styles().colors?.fillColorSecondary,
          backgroundColor: Styles().colors?.surface,
          textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
          onTap: _onTapContinue,
        ),
      ]))),
    ],);
  }

  Widget _buildCollapsibleWrapper(String label, List<dynamic> dataList, Widget Function(int, List<dynamic>) listItemBuilder, {bool addRemove = true, Function(String)? parentEditor, String? parentId}) {
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
        //TODO: handle indentation using displayDepthz
        trailing: parentEditor != null && parentId != null ? Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
          label: 'Edit',
          borderColor: Styles().colors?.fillColorPrimaryVariant,
          backgroundColor: Styles().colors?.surface,
          textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
          onTap: () => parentEditor(parentId),
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
                    listItemBuilder(index, dataList),
                    Container(height: 1, color: Styles().colors?.getColor('dividerLine'),),
                  ],
                );
              },
            ) : addRemove ? _buildAddRemoveButtons(0) : Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyDataWidget(int index, List<dynamic> data) {
    Widget surveyDataText = Text(data[index].key, style: Styles().textStyles?.getTextStyle('widget.detail.regular'),);
    Widget displayEntry = Row(children: [
      Flexible(flex: 1, child: surveyDataText),
      Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
        label: 'Edit',
        borderColor: Styles().colors?.fillColorPrimaryVariant,
        backgroundColor: Styles().colors?.surface,
        textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
        onTap: () => _onTapEditData(index),
      ))),
      Flexible(flex: 1, child: _buildAddRemoveButtons(index + 1)),
    ],);

    return Draggable<int>(
      data: index,
      feedback: surveyDataText,
      childWhenDragging: DragTarget<int>(
        builder: (BuildContext context, List<int?> accepted, List<dynamic> rejected) {
          return displayEntry;
        },
        onAccept: (oldIndex) => _onAcceptDataDrag(oldIndex, index),
      ),
      child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: displayEntry,
      ),
    );
  }

  Widget _buildSurveyRuleWidget(int index, List<dynamic> ruleElements) {
    late Widget displayEntry;
    RuleResult followUpRule = ruleElements[index];
    Widget ruleText = Text(followUpRule.getSummary(), style: Styles().textStyles?.getTextStyle('widget.detail.regular'), overflow: TextOverflow.fade);
    if (followUpRule is RuleReference || followUpRule is RuleAction) {
      displayEntry = Row(children: [
        Flexible(flex: 1, child: ruleText),
        Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
          label: 'Edit',
          borderColor: Styles().colors?.fillColorPrimaryVariant,
          backgroundColor: Styles().colors?.surface,
          textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
          onTap: () => _onTapEditFlowRuleElement(followUpRule.id),
        ))),
      ],);
    } else if (followUpRule is Rule) {
      List<RuleElement> elementsSlice = [];
      if (followUpRule.trueResult != null) {
        elementsSlice.add(followUpRule.trueResult!);
      }
      if (followUpRule.falseResult != null) {
        elementsSlice.add(followUpRule.falseResult!);
      }
      displayEntry = _buildCollapsibleWrapper(followUpRule.condition?.getSummary() ?? "", elementsSlice, _buildSurveyRuleWidget, parentEditor: _onTapEditFlowRuleElement, parentId: followUpRule.condition?.id);
    } else if (followUpRule is RuleCases) {
      displayEntry = _buildCollapsibleWrapper(followUpRule.getSummary(), followUpRule.cases, _buildSurveyRuleWidget, parentEditor: _onTapEditFlowRuleElement, parentId: followUpRule.id);
    } else if (followUpRule is RuleActionList) {
      displayEntry = _buildCollapsibleWrapper(followUpRule.getSummary(), followUpRule.actions, _buildSurveyRuleWidget, parentEditor: _onTapEditFlowRuleElement, parentId: followUpRule.id);
    }

    return Draggable<int>(
      data: index,
      feedback: ruleText,
      childWhenDragging: DragTarget<int>(
        builder: (BuildContext context, List<int?> accepted, List<dynamic> rejected) {
          return displayEntry;
        },
        onAccept: (oldIndex) => _onAcceptRuleDrag(oldIndex, index),
      ),
      child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: displayEntry,
      ),
    );
  }

  /*
  Widget _buildStringListEntryWidget(int index, String textGroup) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      FormFieldText('Value', controller: _textControllers["$textGroup$index.value"], inputType: TextInputType.text, required: true),
      _buildAddRemoveButtons(index + 1, textGroup),
    ]);
  }

  Widget _buildStringMapEntryWidget(int index, String textGroup) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      FormFieldText('Key', controller: _textControllers["$textGroup$index.key"], inputType: TextInputType.text, required: true),
      FormFieldText('Value', controller: _textControllers["$textGroup$index.value"], inputType: TextInputType.text, required: true),
      _buildAddRemoveButtons(index + 1, textGroup),
    ]);
  }

  Widget _buildStringMapWidget(int index) {
    return Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        title: Text(
          "Language Strings",
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
        ),
        leading: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildSurveyDropDownItems<String>(_supportedLangs),
            value: index < _strings.length ? _strings.keys.elementAt(index) : Localization().defaultSupportedLanguages.first,
            onChanged: (value) => _onChangeStringsLanguage(index, value),
            dropdownColor: Styles().colors?.textBackground,
          ),
        ),
        trailing: _buildAddRemoveButtons(index + 1),
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500
            ),
            child: _strings[_strings.keys.elementAt(index)]?.isNotEmpty ?? false ? Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _strings[_strings.keys.elementAt(index)]!.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      _buildStringMapEntryWidget(index, "${_strings.keys.elementAt(index)}.$textGroup"),
                      Container(height: 1, color: Styles().colors?.getColor('dividerLine'),),
                    ],
                  );
                },
              ),
            ) : _buildAddRemoveButtons(0),
          ),
        ],
      ),
    );
  }
  */

  Widget _buildAddRemoveButtons(int index) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      IconButton(
        icon: Styles().images?.getImage('plus-circle', color: Styles().colors?.getColor('fillColorPrimary')) ?? const Icon(Icons.add),
        onPressed: () => _onTapAddDataAtIndex(index),
        padding: EdgeInsets.zero,
      ),
      IconButton(
        icon: Styles().images?.getImage('minus-circle', color: Styles().colors?.getColor('alert')) ?? const Icon(Icons.add),
        onPressed: () => _onTapRemoveDataAtIndex(index - 1),
        padding: EdgeInsets.zero,
      ),
    ]);
  }

  /*  
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
  */

  void _onAcceptDataDrag(int oldIndex, int newIndex) {
    _updateState(() {
      SurveyData temp = _data[oldIndex];
      _data.removeAt(oldIndex);
      _data.insert(newIndex, temp);
      //TODO: update follow up rules appropriately
    });
  }

  void _onAcceptRuleDrag(int oldIndex, int newIndex) {
    _updateState(() {
      RuleResult temp = _followUpRules[oldIndex];
      _followUpRules.removeAt(oldIndex);
      _followUpRules.insert(newIndex, temp);
      //TODO: update follow up rules appropriately
    });
  }

  void _onTapEditData(int index) async {
    SurveyData updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataCreationPanel(data: _data[index], tabBar: widget.tabBar)));
    _updateState(() {
      _data[index] = updatedData;
    });
  }

  void _onTapEditFlowRuleElement(String id) async {
    RuleElement? followUpRuleElem;
    for (RuleResult result in _followUpRules) {
      RuleElement? elem = result.findElementById(id);
      if (elem != null) {
        followUpRuleElem = elem;
      }
    }

    if (followUpRuleElem != null) {
      RuleElement ruleElement = await Navigator.push(context, CupertinoPageRoute(builder: (context) => RuleElementCreationPanel(data: followUpRuleElem!, tabBar: widget.tabBar)));
      _updateState(() {
        for (RuleResult result in _followUpRules) {
          result.updateElementById(id, ruleElement);
        }
      });
    }
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
      _followUpRules.insert(index + 1, RuleAction(action: "return", data: insert.key));
      //TODO: update follow up rules
    });
  }

  void _onTapRemoveDataAtIndex(int index) {
    _updateState(() {
      _data.removeAt(index);
      _followUpRules.removeAt(index + 1);
      //TODO: update follow up rules
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