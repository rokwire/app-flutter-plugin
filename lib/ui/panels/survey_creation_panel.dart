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

import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/rules.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/panels/rule_element_creation_panel.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/panels/survey_data_creation_panel.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widget_builders/buttons.dart';
import 'package:rokwire_plugin/ui/widget_builders/loading.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/survey_creation.dart';

class SurveyCreationPanel extends StatefulWidget {
  final Survey? survey;
  final Widget? tabBar;
  final Widget? offlineWidget;

  const SurveyCreationPanel({Key? key, this.survey, this.tabBar, this.offlineWidget}) : super(key: key);

  @override
  _SurveyCreationPanelState createState() => _SurveyCreationPanelState();
}

class _SurveyCreationPanelState extends State<SurveyCreationPanel> {
  GlobalKey? dataKey;

  bool _loading = false;
  final ScrollController _scrollController = ScrollController();
  late final Map<String, TextEditingController> _textControllers;
  final List<TextEditingController> _sectionTextControllers = [];

  final List<SurveyData> _data = [];
  int _dataCount = 0;
  bool _scored = true;

  final List<RuleResult> _followUpRules = [];
  List<RuleResult> _resultRules = [];

  // final Map<String, String> _constants = {};
  // final Map<String, Map<String, String>> _strings = {};
  // final Map<String, Rule> _subRules = {};
  // List<String>? _responseKeys;

  // final Map<String, String> _supportedLangs = {};

  @override
  void initState() {
    _textControllers = {
      "title": TextEditingController(),
      "more_info": TextEditingController(),
    };

    if (widget.survey != null) {
      _resultRules = widget.survey!.resultRules ?? [];
      _scored = widget.survey!.scored;

      List<String> sections = [];
      SurveyData? firstData = Surveys().getFirstQuestion(widget.survey!);
      if (widget.survey!.defaultDataKeyRule != null) {
        _followUpRules.add(widget.survey!.defaultDataKeyRule!);
      } else {
        _followUpRules.add(RuleAction(action: 'return', data: "data.${widget.survey!.defaultDataKey ?? Survey.defaultQuestionKey}"));
      }
      _handleFollowUpRuleBranches(widget.survey!, firstData);
      for (SurveyData surveyData in widget.survey!.data.values) {
        if (surveyData.isAction) {
          _data.add(surveyData);
        }
        if (surveyData.section != null && !sections.contains(surveyData.section)) {
          sections.add(surveyData.section!);
          _sectionTextControllers.add(TextEditingController(text: surveyData.section!));
        }
      }

      _dataCount = _data.length;
      _textControllers["title"]!.text = widget.survey!.title;
      _textControllers["more_info"]!.text = widget.survey!.moreInfo ?? '';
    }

    super.initState();
  }

  @override
  void dispose() {
    _textControllers.forEach((_, value) { value.dispose(); });
    for (TextEditingController controller in _sectionTextControllers) {
      controller.dispose();
    }

    // for (String lang in Localization().defaultSupportedLanguages) {
    //   _supportedLangs[lang] = lang;
    // }

    super.dispose();
  }

  List<String?> get sections {
    List<String?> sectionList = [null];
    for (TextEditingController controller in _sectionTextControllers) {
      if (controller.text.isNotEmpty) {
        sectionList.add(controller.text);
      }
    }
    return sectionList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: widget.survey != null ? "Update Survey" : "Create Survey"),
      bottomNavigationBar: widget.tabBar,
      backgroundColor: Styles().colors?.background,
      body: SurveyElementCreationWidget(body: _buildSurveyCreationTools(), completionOptions: _buildPreviewAndSave(), scrollController: _scrollController,)
    );
  }

  Widget _buildSurveyCreationTools() {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      // title
      FormFieldText('Title', padding: const EdgeInsets.only(bottom: 16), controller: _textControllers["title"], inputType: TextInputType.text, textCapitalization: TextCapitalization.words, required: true),
      // more_info
      FormFieldText('Additional Information', padding: const EdgeInsets.only(bottom: 16), controller: _textControllers["more_info"], multipleLines: true, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),

      // scored
      SurveyElementCreationWidget.buildCheckboxWidget("Scored", _scored, _onToggleScored, padding: EdgeInsets.zero),

      // sections
      Padding(padding: const EdgeInsets.only(top: 16.0), child: SurveyElementList(
        type: SurveyElementListType.textEntry,
        label: 'Sections (${_sectionTextControllers.length})',
        dataList: _sectionTextControllers,
        surveyElement: SurveyElement.sections,
        onAdd: _onTapAdd,
        onRemove: _onTapRemove,
      )),

      // data
      Padding(padding: const EdgeInsets.only(top: 16.0), child: SurveyElementList(
        type: SurveyElementListType.data,
        label: 'Survey Data (${_data.length})',
        dataList: _data,
        surveyElement: SurveyElement.data,
        onAdd: _onTapAdd,
        onEdit: _onTapEdit,
        onRemove: _onTapRemove,
        onDrag: _onAcceptDataDrag,
      )),

      // follow up rules (determine survey data ordering/flow)
      Padding(padding: const EdgeInsets.only(top: 16.0), child: SurveyElementList(
        type: SurveyElementListType.rules,
        label: 'Flow Rules (${_followUpRules.length})',
        dataList: _followUpRules,
        surveyElement: SurveyElement.followUpRules,
        onAdd: _onTapAdd,
        onEdit: _onTapEdit,
        onRemove: _onTapRemove,
        labelStart: true,
      )),

      // result_rules
      Padding(padding: const EdgeInsets.only(top: 16.0), child: SurveyElementList(
        type: SurveyElementListType.rules,
        label: 'Result Rules (${_resultRules.length})',
        dataList: _resultRules,
        surveyElement: SurveyElement.resultRules,
        onAdd: _onTapAdd,
        onEdit: _onTapEdit,
        onRemove: _onTapRemove,
      )),
    ],));
  }

  Widget _buildPreviewAndSave() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(8.0), child: RoundedButton(
        label: 'Preview',
        borderColor: Styles().colors?.getColor("fillColorPrimaryVariant"),
        backgroundColor: Styles().colors?.surface,
        textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
        onTap: _onTapPreview,
      ))),
      Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(8.0), child: Stack(children: [
        RoundedButton(
          label: 'Save',
          borderColor: Styles().colors?.getColor("fillColorPrimaryVariant"),
          backgroundColor: Styles().colors?.surface,
          textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
          onTap: _onTapSave,
          enabled: !_loading
        ),
        Visibility(visible: _loading, child: Padding(padding: const EdgeInsets.only(top: 4), child: LoadingBuilder.loading())),
      ]))),
    ],);
  }

  void _onTapAdd(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    switch (surveyElement) {
      case SurveyElement.data: _onTapAddDataAtIndex(index); break;
      case SurveyElement.sections: _onTapAddSectionAtIndex(index); break;
      default: _onTapAddRuleElementForId(index, surveyElement, parentElement); break;
    }
  }

  void _onTapRemove(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    switch (surveyElement) {
      case SurveyElement.data: _onTapRemoveDataAtIndex(index); break;
      case SurveyElement.sections: _onTapRemoveSectionAtIndex(index); break;
      default: _onTapRemoveRuleElementForId(index, surveyElement, parentElement); break;
    }
  }

  void _onTapEdit(int index, SurveyElement surveyElement, RuleElement? element) {
    switch (surveyElement) {
      case SurveyElement.data: _onTapEditData(index); break;
      case SurveyElement.followUpRules: _onTapEditRuleElement(element, surveyElement); break;
      case SurveyElement.resultRules: _onTapEditRuleElement(element, surveyElement); break;
      default: return;
    }
  }

  void _onAcceptDataDrag(int oldIndex, int newIndex) {
    setState(() {
      SurveyData temp = _data[oldIndex];
      _data.removeAt(oldIndex);
      _data.insert(newIndex, temp);

      RuleResult tempRule = _followUpRules[oldIndex];
      _followUpRules.removeAt(oldIndex);
      _followUpRules.insert(newIndex, tempRule);
    });
  }

  void _onTapEditData(int index) async {
    SurveyData oldData = SurveyData.fromOther(_data[index]);
    SurveyData? updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataCreationPanel(
      data: _data[index],
      dataKeys: List.generate(_data.length, (index) => _data[index].key),
      dataTypes: List.generate(_data.length, (index) => _data[index].type),
      sections: sections,
      scoredSurvey: _scored,
      tabBar: widget.tabBar
    )));

    if (updatedData != null && mounted) {
      setState(() {
        _data[index] = updatedData;

        if (updatedData.isAction && !oldData.isAction) {
          _followUpRules.removeAt(index);
        } else if (!updatedData.isAction && oldData.isAction) {
          _followUpRules.insert(index, RuleAction(action: "return", data: "data.${_data[index].key}"));
        }
        _updateFollowUpRules(oldData.key, updatedData.key);
      });
    }
  }

  void _updateFollowUpRules(String oldKey, String newKey) {
    if (oldKey != newKey) {
      setState(() {
        for (int i = 0; i < _followUpRules.length; i++) {
          _followUpRules[i].updateDataKeys(oldKey, newKey);
        }
      }); 
    }
  }

  void _onTapEditRuleElement(RuleElement? element, SurveyElement surveyElement, {RuleElement? parentElement}) async {
    if (element != null) {
      RuleElement? ruleElement = await Navigator.push(context, CupertinoPageRoute(builder: (context) => RuleElementCreationPanel(
        data: element,
        dataKeys: List.generate(_data.length, (index) => _data[index].key),
        dataTypes: List.generate(_data.length, (index) => _data[index].type),
        sections: sections,
        forceActionReturnData: surveyElement == SurveyElement.followUpRules,
        tabBar: widget.tabBar,
        mayChangeType: parentElement is! RuleCases && parentElement is! RuleActionList
      )));

      if (ruleElement != null && mounted) {
        setState(() {
          if (surveyElement == SurveyElement.followUpRules) {
            for (int i = 0; i < _followUpRules.length; i++) {
              if (element.id == _followUpRules[i].id && ruleElement is RuleResult) {
                _followUpRules[i] = ruleElement;
                return;
              }
              if (_followUpRules[i].updateElement(ruleElement)) {
                return;
              }
            }
          } else {
            for (int i = 0; i < _resultRules.length; i++) {
              if (element.id == _resultRules[i].id && ruleElement is RuleResult) {
                _resultRules[i] = ruleElement;
                return;
              }
              if (_resultRules[i].updateElement(ruleElement)) {
                return;
              }
            }
          }
        });
      }
    }
  }

  void _handleFollowUpRuleBranches(Survey survey, SurveyData? firstData) {
    for (SurveyData? surveyData = firstData; surveyData != null; surveyData = Surveys().getFollowUp(survey, surveyData)) {
      _data.add(surveyData);
      if (surveyData.followUpRule != null) {
        _followUpRules.add(surveyData.followUpRule!);
        List<RuleAction> possibleActions = surveyData.followUpRule!.possibleActions;
        for (RuleAction action in possibleActions) {
          dynamic result = Rules().evaluateAction(survey, action);
          if (result is SurveyData) {
            _handleFollowUpRuleBranches(survey, result);
          }
        }
      } else if (surveyData.defaultFollowUpKey != null) {
        _followUpRules.add(RuleAction(action: 'return', data: "data.${surveyData.defaultFollowUpKey}"));
      }
    }
  }

  void _onTapAddDataAtIndex(int index) {
    SurveyData insert;
    if (index > 0) {
      insert = SurveyData.fromOther(_data[index-1]);
      insert.key = "data${_dataCount++}";
    } else {
      insert = SurveyQuestionTrueFalse(text: "", key: "data${_dataCount++}");
    }
    setState(() {
      _data.insert(index, insert);
      if (!insert.isAction) {
        _followUpRules.insert(index, RuleAction(action: "return", data: "data.${_data[index].key}"));
      }
    });
  }

  void _onTapRemoveDataAtIndex(int index) {
    setState(() {
      _data.removeAt(index);
      _followUpRules.removeAt(index);
    });
  }

  void _onTapAddSectionAtIndex(int index) {
    setState(() {
      _sectionTextControllers.insert(index, TextEditingController(text: index > 0 ? _sectionTextControllers[index - 1].text : ''));
    });
  }

  void _onTapRemoveSectionAtIndex(int index) {
    _sectionTextControllers[index].dispose();
    setState(() {
      _sectionTextControllers.removeAt(index);
    });
  }

  void _onTapAddRuleElementForId(int index, SurveyElement surveyElement, RuleElement? element) {
    //TODO: what should defaults be?
    if (element is RuleCases) {
      element.cases.insert(index, index > 0 ? Rule.fromOther(element.cases[index-1]) : Rule(
        condition: RuleComparison(dataKey: "", operator: "==", compareTo: ""),
        trueResult: RuleAction(action: "return", data: null),
      ));
    } else if (element is RuleActionList) {
      element.actions.insert(index, index > 0 ? RuleAction.fromOther(element.actions[index-1]) : RuleAction(action: "return", data: null));
    } else if (element is RuleLogic) {
      element.conditions.insert(index, index > 0 ? RuleCondition.fromOther(element.conditions[index-1]) : RuleComparison(dataKey: "", operator: "==", compareTo: ""));
    }

    setState(() {
      if (element == null && surveyElement == SurveyElement.resultRules) {
         _resultRules.insert(index, index > 0 ? RuleResult.fromOther(_resultRules[index-1]) : RuleAction(action: "save", data: null));
      } else if (element != null) {
        for (RuleResult result in surveyElement == SurveyElement.followUpRules ? _followUpRules : _resultRules) {
          if (result.updateElement(element)) {
            return;
          }
        }
      }
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

    setState(() {
      if (element == null && surveyElement == SurveyElement.resultRules) {
         _resultRules.removeAt(index);
      } else if (element != null) {
        for (RuleResult result in surveyElement == SurveyElement.followUpRules ? _followUpRules : _resultRules) {
          if (result.updateElement(element)) {
            return;
          }
        }
      }
    });
  }

  void _onToggleScored(bool? value) {
    setState(() {
      _scored = value ?? true;
    });
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
          _data[i-1].defaultFollowUpKey = (rule.data as String).split('.').last;
        } else {
          _data[i-1].followUpRule = rule;
        }
      }
    }

    return Survey(
      id: widget.survey != null ? widget.survey!.id : '',
      data: SplayTreeMap.fromIterable(_data, key: (data) => (data as SurveyData).key, value: (data) => SurveyData.fromOther(data)),
      type: '',
      scored: _scored,
      title: (_textControllers["title"]?.text.isNotEmpty ?? false) ? _textControllers["title"]!.text : 'New Survey',
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
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(
      survey: _buildSurvey(),
      onComplete: _onPreviewContinue,
      summarizeResultRules: true,
      tabBar: widget.tabBar
    )));
  }

  void _onPreviewContinue(dynamic result) {
    if (result is List<String>) {
      String summary = '';
      for (String actionSummary in result) {
        summary += '\u2022 $actionSummary\n';
      }
      PopupMessage.show(context: context,
        title: "Actions",
        message: "These are the actions that would have been taken had a user completed this survey as you did\n\n$summary",
        buttonTitle: Localization().getStringEx("dialog.ok.title", "OK"),
        onTapButton: (context) {
          Navigator.pop(context);
        },
      );
    }
  }

  void _onTapSave() {
    List<Widget> buttons = [
      Padding(padding: const EdgeInsets.only(right: 8), child: ButtonBuilder.standardRoundedButton(label: 'Yes', onTap: _saveSurvey)),
      Padding(padding: const EdgeInsets.only(left: 8), child: ButtonBuilder.standardRoundedButton(label: 'No', onTap: _dismissSaveSurvey)),
    ];
    ActionsMessage.show(context: context,
      title: "Save Survey",
      message: "Are you sure you want to save this survey?", //TODO: you may return to edit it later
      buttons: buttons,
    );
  }

  void _saveSurvey() {
    Navigator.pop(context);
    setLoading(true);
    if (widget.survey != null) {
      Surveys().updateSurvey(_buildSurvey()).then(_saveSurveyCallback);
    } else {
      Surveys().createSurvey(_buildSurvey()).then(_saveSurveyCallback);
    }
  }

  void _dismissSaveSurvey() {
    Navigator.pop(context);
  }

  void _saveSurveyCallback(bool? success) {
    setLoading(false);
    PopupMessage.show(context: context,
      title: "Save Survey",
      message: "Survey save ${success == true ? "succeeded" : "failed"}", //TODO: better messaging here
      buttonTitle: Localization().getStringEx("dialog.ok.title", "OK"),
      onTapButton: (context) {
        Navigator.pop(context);
        Navigator.pop(context);
      },
      barrierDismissible: success != true,
    );
  }

  void setLoading(bool value) {
    setState(() {
      _loading = value;
    });
  }
}
