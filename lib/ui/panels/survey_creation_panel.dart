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
import 'package:flutter/gestures.dart';
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
import 'package:rokwire_plugin/ui/widgets/expansion_tile.dart' as rokwire;
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/survey_creation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

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
  List<GlobalKey> _dataToRuleKeys = [];
  List<GlobalKey> _ruleToDataKeys = [];
  List<GlobalKey> _actionKeys = [];
  final _maxBranchDepth = 10;

  bool _loading = false;
  final ScrollController _scrollController = ScrollController();
  late final Map<String, TextEditingController> _textControllers;
  final List<TextEditingController> _sectionTextControllers = [];
  final rokwire.ExpansionTileController _questionDataController = rokwire.ExpansionTileController();
  final rokwire.ExpansionTileController _actionDataController = rokwire.ExpansionTileController();
  final rokwire.ExpansionTileController _followUpRulesController = rokwire.ExpansionTileController();

  final List<SurveyData> _questionData = [];
  final List<SurveyData> _actionData = [];
  int _dataCount = 0;
  bool _scored = true;
  int _branchDepth = 0;

  final List<RuleResult> _followUpRules = [];
  List<RuleResult> _resultRules = [];
  Survey? _survey;

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
        _followUpRules.add(RuleAction(action: 'show', data: "data.${widget.survey!.defaultDataKey ?? Survey.defaultQuestionKey}"));
      }
      _handleFollowUpRuleBranches(widget.survey!, firstData);
      for (SurveyData surveyData in widget.survey!.data.values) {
        if (surveyData.isAction) {
          _actionData.add(surveyData);
        } else if (CollectionUtils.isNotEmpty(surveyData.sections)) {
          for (String section in surveyData.sections!) {
            if (!sections.contains(section)) {
              sections.add(section);
              _sectionTextControllers.add(TextEditingController(text: section));
            }
          }
        } else if (surveyData.section != null && !sections.contains(surveyData.section)) {
          sections.add(surveyData.section!);
          _sectionTextControllers.add(TextEditingController(text: surveyData.section!));
          
          int questionIndex = _questionData.indexWhere((element) => element.key == surveyData.key);
          _questionData[questionIndex].sections = [surveyData.section!];
        }
      }

      _dataToRuleKeys = List.generate(_questionData.length, (index) => GlobalKey());
      _ruleToDataKeys = List.generate(_questionData.length, (index) => GlobalKey());
      _actionKeys = List.generate(_actionData.length, (index) => GlobalKey());
      _dataCount = _questionData.length + _actionData.length;
      _textControllers["title"]!.text = widget.survey!.title;
      _textControllers["more_info"]!.text = widget.survey!.moreInfo ?? '';
    }

    super.initState();
  }

  void _handleFollowUpRuleBranches(Survey survey, SurveyData? firstData) {
    if (_branchDepth <= _maxBranchDepth) {
      for (SurveyData? surveyData = firstData; surveyData != null; surveyData = Surveys().getFollowUp(survey, surveyData)) {
        if (_questionData.indexWhere((element) => element.key == surveyData!.key) != -1) {
          break;
        }
        _questionData.add(surveyData);
        if (surveyData.followUpRule != null) {
          surveyData.followUpRule!.updateSupportedOption('return', 'show');
          _followUpRules.add(surveyData.followUpRule!);
          List<RuleAction> possibleActions = surveyData.followUpRule!.possibleActions;
          for (RuleAction action in possibleActions) {
            dynamic result = Rules().evaluateAction(survey, action);
            if (result is SurveyData) {
              _branchDepth++;
              _handleFollowUpRuleBranches(survey, result);
            }
          }
        } else {
          _followUpRules.add(RuleAction(action: 'show', data: surveyData.defaultFollowUpKey != null ? "data.${surveyData.defaultFollowUpKey}" : null));
        }
      }
    }
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

  List<String> get sections {
    List<String> sectionList = [];
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
      body: SurveyElementCreationWidget(body: _buildSurveyCreationTools(), completionOptions: _buildPreviewAndSave(), scrollController: _scrollController,),
    );
  }

  Widget _buildSurveyCreationTools() {
    if (_branchDepth <= _maxBranchDepth) {
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
          label: 'Question Scoring Sections (${_sectionTextControllers.length})',
          dataList: _sectionTextControllers,
          surveyElement: SurveyElement.sections,
          onAdd: _onTapAdd,
          onRemove: _onTapRemove,
        )),

        // data (questions and info)
        Padding(padding: const EdgeInsets.only(top: 16.0), child: SurveyElementList(
          type: SurveyElementListType.data,
          label: 'Questions and Textual Information (${_questionData.length})',
          dataList: _questionData,
          dataSubtitles: List.filled(_questionData.length, 'Follow up rule'),
          widgetKeys: _dataToRuleKeys,
          targetWidgetKeys: _ruleToDataKeys,
          surveyElement: SurveyElement.questionData,
          onAdd: _onTapAdd,
          onEdit: _onTapEdit,
          onRemove: _onTapRemove,
          onDrag: _onAcceptQuestionDataDrag,
          onScroll: _onScroll,
          controller: _questionDataController,
        )),

        // follow up rules (determine survey data ordering/flow)
        Padding(padding: const EdgeInsets.only(top: 16.0), child: SurveyElementList(
          type: SurveyElementListType.rules,
          label: 'Question Flow Rules (${_followUpRules.length})',
          dataList: _followUpRules,
          dataSubtitles: List.generate(_questionData.length + 1, (index) => index > 0 ? _questionData[index - 1].key : null),
          widgetKeys: _ruleToDataKeys,
          targetWidgetKeys: _dataToRuleKeys,
          surveyElement: SurveyElement.followUpRules,
          onAdd: _onTapAdd,
          onEdit: _onTapEdit,
          onRemove: _onTapRemove,
          onScroll: _onScroll,
          controller: _followUpRulesController,
          labelStart: true,
        )),

        // data (actions) -> these do not have follow ups because they are actions taken as the result of rule evaluation
        Padding(padding: const EdgeInsets.only(top: 16.0), child: SurveyElementList(
          type: SurveyElementListType.data,
          label: 'Popups (${_actionData.length})',
          dataList: _actionData,
          targetWidgetKeys: _actionKeys,
          surveyElement: SurveyElement.actionData,
          onAdd: _onTapAdd,
          onEdit: _onTapEdit,
          onRemove: _onTapRemove,
          onDrag: _onAcceptActionDataDrag,
          controller: _actionDataController,
        )),

        // result_rules
        Padding(padding: const EdgeInsets.only(top: 16.0), child: SurveyElementList(
          type: SurveyElementListType.rules,
          label: 'Post-Completion Rules (${_resultRules.length})',
          dataList: _resultRules,
          dataSubtitles: List.generate(_questionData.length + _actionData.length, (index) => index < _questionData.length ? _questionData[index].key : _actionData[index - _questionData.length].key),
          widgetKeys: _ruleToDataKeys + _actionKeys,
          surveyElement: SurveyElement.resultRules,
          onAdd: _onTapAdd,
          onEdit: _onTapEdit,
          onRemove: _onTapRemove,
          onScroll: _onScroll,
        )),
      ],));
    }
    return Text("Maximum question branch depth ($_maxBranchDepth) exceeded. Your survey may not be shown correctly.", style: Styles().textStyles?.getTextStyle('widget.error.regular.fat'));
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
      case SurveyElement.questionData: _onTapAddDataAtIndex(index, surveyElement); break;
      case SurveyElement.actionData: _onTapAddDataAtIndex(index, surveyElement); break;
      case SurveyElement.sections: _onTapAddSectionAtIndex(index); break;
      default: _onTapAddRuleElementForId(index, surveyElement, parentElement); break;
    }
  }

  void _onTapRemove(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    switch (surveyElement) {
      case SurveyElement.questionData: _onTapRemoveDataAtIndex(index, surveyElement); break;
      case SurveyElement.actionData: _onTapRemoveDataAtIndex(index, surveyElement); break;
      case SurveyElement.sections: _onTapRemoveSectionAtIndex(index); break;
      default: _onTapRemoveRuleElementForId(index, surveyElement, parentElement); break;
    }
  }

  void _onTapEdit(int index, SurveyElement surveyElement, RuleElement? element, RuleElement? parentElement) {
    switch (surveyElement) {
      case SurveyElement.questionData: _onTapEditQuestionData(index); break;
      case SurveyElement.actionData: _onTapEditActionData(index); break;
      case SurveyElement.followUpRules: _onTapEditRuleElement(element, surveyElement, parentElement: parentElement); break;
      case SurveyElement.resultRules: _onTapEditRuleElement(element, surveyElement, parentElement: parentElement); break;
      default: return;
    }
  }

  void _onScroll(GlobalKey? key) {
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(key!.currentContext!, duration: const Duration(seconds: 1), alignment: 0.5);
    } else if (_dataToRuleKeys.contains(key) == true) {
      _followUpRulesController.target = key;
      _followUpRulesController.expand?.call();
    } else if (_ruleToDataKeys.contains(key) == true) {
      _questionDataController.target = key;
      _questionDataController.expand?.call();
    } else if (_actionKeys.contains(key) == true) {
      _actionDataController.target = key;
      _actionDataController.expand?.call();
    }
  }

  // sections

  void _onTapAddSectionAtIndex(int index) {
    setState(() {
      _sectionTextControllers.insert(index, TextEditingController());
    });
  }

  void _onTapRemoveSectionAtIndex(int index) {
    _sectionTextControllers[index].dispose();
    setState(() {
      _sectionTextControllers.removeAt(index);
    });
  }

  // question data

  void _onTapAddDataAtIndex(int index, SurveyElement surveyElement) {
    bool isQuestionInfo = surveyElement == SurveyElement.questionData;
    SurveyData insert;
    if (index > 0) {
      insert = SurveyData.fromOther(isQuestionInfo ? _questionData[index-1] : _actionData[index-1]);
      insert.key = "data${_dataCount++}";
    } else if (isQuestionInfo) {
      insert = SurveyQuestionTrueFalse(text: "", key: "data${_dataCount++}");
    } else {
      insert = SurveyDataResult(key: "data${_dataCount++}", text: "New Action", actions: []);
    }
    setState(() {
      if (isQuestionInfo) {
        _dataToRuleKeys.insert(index, GlobalKey());
        _ruleToDataKeys.insert(index, GlobalKey());
        _questionData.insert(index, insert);
        if (index == 0) {
          _followUpRules.insert(0, RuleAction(action: "show", data: null));
        }
        _followUpRules.insert(index, RuleAction(action: "show", data: "data.${_questionData[index].key}"));
      } else {
        _actionKeys.insert(index, GlobalKey());
        _actionData.insert(index, insert);
      }
    });
  }

  void _onTapRemoveDataAtIndex(int index, SurveyElement surveyElement) {
    setState(() {
      if (surveyElement == SurveyElement.questionData) {
        _dataToRuleKeys.removeAt(index);
        _ruleToDataKeys.removeAt(index);
        _questionData.removeAt(index);
        _followUpRules.removeAt(index);
        if (_questionData.isEmpty) {
          _followUpRules.removeAt(0);
        }
      } else {
        _actionKeys.removeAt(index);
        _actionData.removeAt(index);
      }
    });
  }

  void _onTapEditQuestionData(int index) async {
    String oldKey = _questionData[index].key;
    SurveyData? updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataCreationPanel(
      data: SurveyData.fromOther(_questionData[index]),
      dataKeys: List.generate(_questionData.length, (index) => _questionData[index].key),
      dataTypes: List.generate(_questionData.length, (index) => _questionData[index].type),
      sections: sections,
      scoredSurvey: _scored,
      tabBar: widget.tabBar
    )));

    if (updatedData != null && mounted) {
      setState(() {
        _questionData[index] = updatedData;
        // update follow up rules
        if (oldKey != updatedData.key) {
          for (int i = 0; i < _followUpRules.length; i++) {
            _followUpRules[i].updateDataKeys(oldKey, updatedData.key);
          }
        }
      });
    }
  }

  void _onAcceptQuestionDataDrag(int oldIndex, int newIndex) {
    setState(() {
      SurveyData temp = _questionData[oldIndex];
      _questionData.removeAt(oldIndex);
      _questionData.insert(newIndex, temp);

      RuleResult tempRule = _followUpRules[oldIndex];
      _followUpRules.removeAt(oldIndex);
      _followUpRules.insert(newIndex, tempRule);

      GlobalKey tempKey = _dataToRuleKeys[oldIndex];
      _dataToRuleKeys.removeAt(oldIndex);
      _dataToRuleKeys.insert(newIndex, tempKey);
      _ruleToDataKeys.removeAt(oldIndex);
      _ruleToDataKeys.insert(newIndex, tempKey);
    });
  }

  // action data

  void _onTapEditActionData(int index) async {
    SurveyData? updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataCreationPanel(
      data: SurveyData.fromOther(_actionData[index]),
      dataKeys: List.generate(_questionData.length, (index) => _questionData[index].key),
      dataTypes: List.generate(_questionData.length, (index) => _questionData[index].type),
      sections: sections,
      scoredSurvey: _scored,
      mayChangeType: false,
      tabBar: widget.tabBar
    )));

    if (updatedData != null && mounted) {
      setState(() {
        _actionData[index] = updatedData;
      });
    }
  }

  void _onAcceptActionDataDrag(int oldIndex, int newIndex) {
    setState(() {
      SurveyData temp = _actionData[oldIndex];
      _actionData.removeAt(oldIndex);
      _actionData.insert(newIndex, temp);

      GlobalKey tempKey = _actionKeys[oldIndex];
      _actionKeys.removeAt(oldIndex);
      _actionKeys.insert(newIndex, tempKey);
    });
  }

  // rules

  void _onTapAddRuleElementForId(int index, SurveyElement surveyElement, RuleElement? element) {
    if (index > 0) {
      // elements should not need to be inserted at the front of the list for any of the following
      if (element is RuleCases) {
        element.cases.insert(index, Rule.fromOther(element.cases[index-1]));
      } else if (element is RuleActionList) {
        element.actions.insert(index, RuleAction.fromOther(element.actions[index-1]));
      } else if (element is RuleLogic) {
        element.conditions.insert(index, RuleCondition.fromOther(element.conditions[index-1]));
      }
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

  void _onTapEditRuleElement(RuleElement? element, SurveyElement surveyElement, {RuleElement? parentElement}) async {
    if (element != null) {
      RuleElement? ruleElement = await Navigator.push(context, CupertinoPageRoute(builder: (context) => RuleElementCreationPanel(
        data: RuleElement.fromOther(element),
        surveyElement: surveyElement,
        questionDataKeys: List.generate(_questionData.length, (index) => _questionData[index].key),
        questionDataTypes: List.generate(_questionData.length, (index) => _questionData[index].type),
        actionDataKeys: List.generate(_actionData.length, (index) => _actionData[index].key),
        sections: sections,
        tabBar: widget.tabBar,
        mayChangeType: parentElement is! RuleCases && parentElement is! RuleActionList
      )));

      if (ruleElement != null && mounted) {
        setState(() {
          List<RuleResult> ruleList = surveyElement == SurveyElement.followUpRules ? _followUpRules : _resultRules;
          for (int i = 0; i < _followUpRules.length; i++) {
            if (element.id == ruleList[i].id && ruleElement is RuleResult) {
              ruleList[i] = ruleElement;
              return;
            }
            if (ruleList[i].updateElement(ruleElement)) {
              return;
            }
          }
        });
      }
    }
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
        if (rule is RuleAction && rule.action == 'show') {
          defaultDataKey = (rule.data is String && (rule.data as String).isNotEmpty) ? (rule.data as String).split('.').last : null;
          defaultDataKeyRule = null;
        } else {
          defaultDataKeyRule = rule;
          defaultDataKey = null;
        }
      } else {
        if (rule is RuleAction && rule.action == 'show') {
          _questionData[i-1].defaultFollowUpKey = (rule.data is String && (rule.data as String).isNotEmpty) ? (rule.data as String).split('.').last : null;
          _questionData[i-1].followUpRule = null;
        } else {
          _questionData[i-1].followUpRule = rule;
          _questionData[i-1].defaultFollowUpKey = null;
        }
      }
    }

    Map<String, SurveyData> data = <String, SurveyData>{for (var data in _questionData + _actionData) data.key: SurveyData.fromOther(data)};
    return _survey = Survey(
      id: widget.survey != null ? widget.survey!.id : '',
      data: data,
      type: 'user',
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
    if (result is List<RuleAction>) {
      List<InlineSpan> textSpans = [TextSpan(
        text: "These are the actions that would have been taken had a user completed this survey as you did\n\n",
        style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'),
      )];
      for (RuleAction action in result) {
        if (RuleAction.supportedPreviews.contains(action.action)) {
          textSpans.add(TextSpan(
            text: '\u2022 ${RuleAction.supportedActions[action.action]} ',
            style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'),
          ));
          textSpans.add(TextSpan(
            text: action.getSummary().replaceAll('${RuleAction.supportedActions[action.action]!} ', ''),
            style: Styles().textStyles?.getTextStyle('widget.button.title.medium.fat.underline'),
            recognizer: TapGestureRecognizer()..onTap = () => Rules().evaluateAction(_survey!, action, immediate: true),  
          ));
          textSpans.add(TextSpan(
            text: '\n',
            style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'),
          ));
        } else {
          textSpans.add(TextSpan(
            text: '\u2022 ${action.getSummary()}\n',
            style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'),
          ));
        }
      }
      PopupMessage.show(context: context,
        title: "Actions",
        messageWidget: Padding(padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8), child: Text.rich(TextSpan(children: textSpans))),
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
