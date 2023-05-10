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
import 'package:rokwire_plugin/model/alert.dart';
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/survey_data_options_panel.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/survey_creation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class RuleElementCreationPanel extends StatefulWidget {
  final RuleElement data;
  final List<String> questionDataKeys;
  final List<String> questionDataTypes;
  final List<String>? actionDataKeys;
  final List<String?> sections;
  final bool mayChangeType;
  final bool forceReturn;
  final bool forceReturnQuestionData;
  final Widget? tabBar;

  const RuleElementCreationPanel({Key? key, required this.data, required this.questionDataKeys, required this.questionDataTypes, this.actionDataKeys, required this.sections,
    this.mayChangeType = true, this.forceReturn = false, this.forceReturnQuestionData = false, this.tabBar}) : super(key: key);

  @override
  _RuleElementCreationPanelState createState() => _RuleElementCreationPanelState();
}

class _RuleElementCreationPanelState extends State<RuleElementCreationPanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  late final Map<String, TextEditingController> _textControllers;
  final List<TextEditingController> _customValueTextControllers = [];

  late RuleElement _ruleElem;
  List<ActionData>? _actions;

  final Map<String, String?> _dataKeySettings = {
    "survey_option": null, // survey, stats, or data
    "survey": null,
    "stats": null,
    "data": null,
    "key": null,
  };

  final Map<String, String?> _compareToSettings = {
    "survey_option": null, // survey, stats, or data
    "survey": null,
    "stats": null,
    "data": null,
    "key": null,
  };

  final Map<String, String?> _actionSettings = {
    "local_notify.period": null,

    "survey_option": null, // survey, stats, or data
    "survey": null,
    "stats": null,
    "data": null,
    "key": null,
  };

  String _customValueSelection = 'survey';
  final Map<String, String> _customValueOptions = {
    'survey': 'Survey Value',
    'custom_single': 'Custom Value (Single)',
    'custom_multiple': 'Custom Value (Multiple)'
  };
  final Map<String, String> _surveyPropertyOptions = {
    'survey': 'Survey',
    'stats': 'Stats',
    'data': 'Survey Data',
  };

  @override
  void initState() {
    _ruleElem = widget.data;

    RuleComparison? comparison;
    if (_ruleElem is RuleComparison) {
      comparison = _ruleElem as RuleComparison;
    } else if (_ruleElem is Rule) {
      RuleCondition? condition = (_ruleElem as Rule).condition;
      comparison = (condition is RuleComparison) ? condition : null;
    }

    String? customData;
    String? localNotifyTitle;
    String? localNotifyText;
    int? localNotifyPeriod;
    if (comparison != null) {
      _dataKeySettings.addEntries(_initSettings(comparison.dataKey));

      //TODO: combine with below
      if (comparison.compareTo is String) {
        customData = comparison.compareTo as String;
        if (customData.contains('stats') || customData.contains('data') || ListUtils.contains(Surveys.properties.keys, customData)!) {
          _compareToSettings.addEntries(_initSettings(customData));
          _customValueSelection = 'survey';
        } else {
          _customValueSelection = 'custom_single';
        }
      } else if (comparison.compareTo is Iterable) {
        for (dynamic value in comparison.compareTo as Iterable) {
          _customValueTextControllers.add(TextEditingController(text: value.toString()));
        }
        _customValueSelection = 'custom_multiple';
      } else if (comparison.compareTo is DateTime) {
        customData = DateTimeUtils.utcDateTimeToString(comparison.compareTo, format: "MM-dd-yyyy") ?? '';
        _customValueSelection = 'custom_single';
      } else {
        customData = comparison.compareTo?.toString() ?? '';
        _customValueSelection = 'custom_single';
      }
    } else if (_ruleElem is RuleAction) {
      RuleAction action = _ruleElem as RuleAction;
      if (action.data is String) {
        customData = action.data as String;
        if (customData.contains('stats') || customData.contains('data') || ListUtils.contains(Surveys.properties.keys, customData)!) {
          _actionSettings.addEntries(_initSettings(customData));
          _customValueSelection = 'survey';
        } else {
          _customValueSelection = 'custom_single';
        }
      } else if (action.data is Iterable) {
        for (dynamic value in action.data as Iterable) {
          _customValueTextControllers.add(TextEditingController(text: value.toString()));
        }
        _customValueSelection = 'custom_multiple';
      } else if (action.data is DateTime) {
        customData = DateTimeUtils.utcDateTimeToString(action.data, format: "MM-dd-yyyy") ?? '';
        _customValueSelection = 'custom_single';
      } else {
        customData = action.data?.toString() ?? '';
        _customValueSelection = 'custom_single';
      }

      if (action.action == 'local_notify') {
        Alert alert = action.data as Alert;
        _actions = alert.actions;
        localNotifyTitle = alert.title;
        localNotifyText = alert.text;
        Duration? duration = alert.timeToAlert;
        if (duration != null) {
          if (duration.inDays > 0) {
            localNotifyPeriod = duration.inDays;
            _actionSettings['local_notify.period'] = 'days';
          } else if (duration.inHours > 0) {
            localNotifyPeriod = duration.inHours;
            _actionSettings['local_notify.period'] = 'hours';
          } else if (duration.inMinutes > 0) {
            localNotifyPeriod = duration.inMinutes;
            _actionSettings['local_notify.period'] = 'minutes';
          } else if (duration.inSeconds > 0) {
            localNotifyPeriod = duration.inSeconds;
            _actionSettings['local_notify.period'] = 'seconds';
          }
        }
      }
    }

    _textControllers = {
      "custom_compare": TextEditingController(text: customData),
      "result_data_key": TextEditingController(text: (_ruleElem is RuleAction) ? (_ruleElem as RuleAction).dataKey : null),
      "local_notify.title": TextEditingController(text: localNotifyTitle),
      "local_notify.text": TextEditingController(text: localNotifyText),
      "local_notify.period": TextEditingController(text: localNotifyPeriod?.toString())
    };
    super.initState();
  }

  List<MapEntry<String, String>> _initSettings(String data) {
    List<MapEntry<String, String>> settingsEntries = [];
    
    List<String> dataFields = data.split(".");
    if (dataFields.length == 1) {
      settingsEntries.add(const MapEntry('survey_option', 'survey'));
      settingsEntries.add(MapEntry('survey', dataFields[0]));
    } else if (dataFields.length > 1) {
      settingsEntries.add(MapEntry('survey_option', dataFields[0]));
      if (dataFields[0] == 'stats') {
        settingsEntries.add(MapEntry('stats', dataFields[1]));
        if (dataFields.length > 2 && widget.sections.contains(dataFields[2])) {
          settingsEntries.add(MapEntry('key', dataFields[2]));
        }
      } else if (dataFields[0] == 'data') {
        settingsEntries.add(MapEntry('key', dataFields[1]));
        if (dataFields.length > 2) {
          settingsEntries.add(MapEntry('data', dataFields[2]));
        }
      }
    }

    return settingsEntries;
  }

  @override
  void dispose() {
    _textControllers.forEach((_, value) {
      value.dispose();
    });
    for (TextEditingController controller in _customValueTextControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderBar(title: "Edit Rule Element"),
      bottomNavigationBar: widget.tabBar,
      backgroundColor: Styles().colors?.background,
      body: SurveyElementCreationWidget(body: _buildRuleElement(), completionOptions: _buildDone(), scrollController: _scrollController,)
    );
  }

  Widget _buildRuleElement() {
    Map<String, String> supportedTypes = Map.from(_ruleElem.supportedAlternatives);
    if (widget.forceReturnQuestionData) {
      supportedTypes.remove('action_list');
    }
    List<Widget> content = [Visibility(
      visible: widget.mayChangeType,
      child: SurveyElementCreationWidget.buildDropdownWidget<String>(supportedTypes, "Type", _getElementTypeString(), _onChangeElementType, margin: EdgeInsets.zero)
    )];

    String? operator;
    if (_ruleElem is RuleComparison) {
      operator = (_ruleElem as RuleComparison).operator;
    } else if (_ruleElem is Rule) {
      RuleCondition? condition = (_ruleElem as Rule).condition;
      operator = (condition is RuleComparison) ? condition.operator : null;
    }

    if (operator != null) {
      // dataKey
      content.add(_buildSurveyPropertyOptions('data_key'));

      // operator
      content.add(SurveyElementCreationWidget.buildDropdownWidget<String>(RuleComparison.supportedOperators, "Operator", operator, _onChangeComparisonType));

      // compareTo
      content.add(SurveyElementCreationWidget.buildDropdownWidget<String>(_customValueOptions, "Compare To", _customValueSelection, _onChangeCustomValueSelection));
      content.add(_buildSurveyPropertyOptions('compare_to'));
    } else if (_ruleElem is RuleReference) {
      //TODO: add later - dropdown showing existing rules by summary? (pass existing rules into panel?)
    } else if (_ruleElem is RuleAction) {
      // action
      content.add(SurveyElementCreationWidget.buildDropdownWidget<String>(widget.forceReturnQuestionData || widget.forceReturn ? {'return': 'Return'} : RuleAction.supportedActions,
        "Action", (_ruleElem as RuleAction).action, _onChangeActionType));

      content.add(_buildActionSurveyOptions());
    }

    return Padding(padding: const EdgeInsets.all(16), child: Column(children: content));
  }

  Widget _buildActionSurveyOptions() {
    RuleAction ruleAction = _ruleElem as RuleAction;
    switch (ruleAction.action) {
      case 'return':
        if (widget.forceReturnQuestionData) {
          Map<String?, String> options = Map.fromIterable(widget.questionDataKeys);
          options[null] = 'END SURVEY';
          return SurveyElementCreationWidget.buildDropdownWidget<String>(options, "Survey data key", _actionSettings['key'], (value) => _onChangeActionSetting(value, 'return'));
        }

        return Column(children: [
          SurveyElementCreationWidget.buildDropdownWidget<String>(_customValueOptions, "Value Type", _customValueSelection, _onChangeCustomValueSelection),
          _buildSurveyPropertyOptions('action'),
        ]);
      case 'set_result':
        return Column(children: [
          SurveyElementCreationWidget.buildDropdownWidget<String>(_customValueOptions, "Value Type", _customValueSelection, _onChangeCustomValueSelection),
          _buildSurveyPropertyOptions('action'),
          FormFieldText('Result Key', padding: const EdgeInsets.only(top: 16), controller: _textControllers["result_data_key"], inputType: TextInputType.text),
        ]);
      case 'alert':
        return SurveyElementCreationWidget.buildDropdownWidget<String>(Map.fromIterable(widget.actionDataKeys ?? []), "Survey data key", _actionSettings['key'],
          (value) => _onChangeActionSetting(value, 'alert'), padding: const EdgeInsets.all(16));
      case 'alert_result':
        return Column(children: [
          SurveyElementCreationWidget.buildDropdownWidget<String>(Map.fromIterable(widget.actionDataKeys ?? []), "Survey data key", _actionSettings['key'],
            (value) => _onChangeActionSetting(value, 'alert_result'), padding: const EdgeInsets.all(16)),
          FormFieldText('Result Key', padding: const EdgeInsets.only(top: 16), controller: _textControllers["result_data_key"], inputType: TextInputType.text)
        ]);
      case 'local_notify':
        Map<String, String> unitOptions = {'seconds': 'Seconds', 'minutes': 'Minutes', 'hours': 'Hours', 'days': 'Days'};
        return Column(children: [
          // title
          FormFieldText('Title', padding: const EdgeInsets.only(top: 16), controller: _textControllers["local_notify.title"], textCapitalization: TextCapitalization.words,),
          // text
          FormFieldText('Text', padding: const EdgeInsets.symmetric(vertical: 16), controller: _textControllers["local_notify.text"], inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences,),
          // actions
          SurveyElementList(
            type: SurveyElementListType.actions,
            label: 'Actions (${_actions?.length ?? 0})',
            dataList: _actions ?? [],
            surveyElement: SurveyElement.actionData,
            onAdd: _onTapAddAction,
            onEdit: _onTapEditAction,
            onRemove: _onTapRemoveAction,
            onDrag: _onAcceptDataDrag,
          ),
          // period
          Row(children: [
            Flexible(
              flex: 1,
              child: FormFieldText('Period', padding: const EdgeInsets.only(top: 16, right: 8), controller: _textControllers["local_notify.period"], inputType: TextInputType.number),
            ),
            Flexible(
              flex: 1,
              child: SurveyElementCreationWidget.buildDropdownWidget<String>(unitOptions, "Unit", _actionSettings['local_notify.period'],
                (value) => _onChangeActionSetting(value, 'local_notify.period'), margin: const EdgeInsets.only(top: 16, left: 8)),
            ),
          ],)
        ]);
    }

    return Container();
  }

  Widget _buildSurveyPropertyOptions(String settings) {
    if (_customValueSelection == 'survey' || settings == 'data_key') {
      List<Widget> content = [];

      String? surveyOption;
      Map<String, String?> settingsMap = {};
      switch (settings) {
        case 'data_key':
          surveyOption = _dataKeySettings['survey_option'];
          settingsMap = _dataKeySettings;
          break;
        case 'compare_to':
          surveyOption = _compareToSettings['survey_option'];
          settingsMap = _compareToSettings;
          break;
        case 'action':
          surveyOption = _actionSettings['survey_option'];
          settingsMap = _actionSettings;
          break;
      }

      content.add(SurveyElementCreationWidget.buildDropdownWidget<String>(_surveyPropertyOptions, "Data Field", surveyOption, (value) => _onChangeSurveyPropertySetting(value, settings, 'survey_option')));

      switch (surveyOption) {
        case 'survey':
          content.add(SurveyElementCreationWidget.buildDropdownWidget<String>(Surveys.properties, "Survey option", settingsMap['survey'],
            (value) => _onChangeSurveyPropertySetting(value, settings, 'survey')));
          break;
        case 'stats':
          content.add(SurveyElementCreationWidget.buildDropdownWidget<String>(Surveys.statsProperties, "Stats option", settingsMap['stats'],
            (value) => _onChangeSurveyPropertySetting(value, settings, 'stats')));
          if (settingsMap['stats'] == 'percentage') {
            content.add(SurveyElementCreationWidget.buildDropdownWidget<String>(Map.fromIterable(widget.sections, value: (v) => v ?? 'None'), "Section",
              settingsMap['key'], (value) => _onChangeSurveyPropertySetting(value, settings, 'key')));
          } else if (settingsMap['stats'] == 'response_data') {
            content.add(Visibility(
              visible: widget.sections.isNotEmpty,
              child: SurveyElementCreationWidget.buildDropdownWidget<String>(Map.fromIterable(widget.sections, value: (v) => v ?? 'None'), "Section",
                settingsMap['key'], (value) => _onChangeSurveyPropertySetting(value, settings, 'key'))
            ));
          }
          break;
        case 'data':
          content.add(SurveyElementCreationWidget.buildDropdownWidget<String>(Map.fromIterable(widget.questionDataKeys + (widget.actionDataKeys ?? [])), "Survey data key",
            settingsMap['key'], (value) => _onChangeSurveyPropertySetting(value, settings, 'key')));

          Map<String, String> dataProperties = Surveys.dataProperties;
          int dataKeyIndex = widget.questionDataKeys.indexOf(settingsMap['key'] ?? '');
          String dataType = dataKeyIndex >= 0 ? widget.questionDataTypes[dataKeyIndex] : '';
          if (dataType != 'survey_data.true_false') {
            dataProperties.remove('correct_answer');
          }
          if (dataType != 'survey_data.multiple_choice') {
            dataProperties.remove('correct_answers');
          }
          
          content.add(SurveyElementCreationWidget.buildDropdownWidget<String>(dataProperties, "Survey data option", settingsMap['data'],
            (value) => _onChangeSurveyPropertySetting(value, settings, 'data')));
          break;
      }

      return Column(children: content,);
    } else if (_customValueSelection == 'custom_single') {
      return FormFieldText('Value', padding: const EdgeInsets.only(top: 16.0), controller: _textControllers["custom_compare"], inputType: TextInputType.text, required: true);
    }

    return Padding(padding: const EdgeInsets.only(top: 16.0), child: SurveyElementList(
      type: SurveyElementListType.textEntry,
      label: 'Values (${_customValueTextControllers.length})',
      dataList: _customValueTextControllers,
      surveyElement: SurveyElement.sections,
      onAdd: _onTapAddValueAtIndex,
      onRemove: _onTapRemoveValueAtIndex,
    ));
  }

  Widget _buildDone() {
    return Padding(padding: const EdgeInsets.all(8.0), child: RoundedButton(
      label: 'Done',
      borderColor: Styles().colors?.fillColorPrimaryVariant,
      backgroundColor: Styles().colors?.surface,
      textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
      onTap: _onTapDone,
    ));
  }

  String _toSurveyPropertyString(String settings) {
    Map<String, String?> settingsMap = settings == 'data_key' ? _dataKeySettings : _actionSettings;
    switch (settingsMap['survey_option']) {
      case 'survey':
        return settingsMap['survey'] ?? '';
      case 'stats':
        String statsProperty = settingsMap['stats'] ?? '';
        String dataKey = settingsMap['key'] ?? '';
        return statsProperty.isNotEmpty ? (dataKey.isNotEmpty ? 'stats.$statsProperty.$dataKey' : 'stats.$statsProperty') : 'stats';
      case 'data':
        String dataKey = settingsMap['key'] ?? '';
        String dataProperty = settingsMap['data'] ?? '';
        return dataKey.isNotEmpty ? (dataProperty.isNotEmpty ? 'data.$dataKey.$dataProperty' : 'data.$dataKey') : 'data';
      default:
        return '';
    }
  }

  dynamic get compareToValue {
    if (_customValueSelection == 'custom_single') {
      return SurveyElementCreationWidget.parseTextForType(_textControllers['custom_compare']!.text);
    } else if (_customValueSelection == 'custom_multiple') {
      return customValueList;
    }

    switch (_compareToSettings['survey_option']) {
      case 'survey':
        return _compareToSettings['survey'];
      case 'stats':
        String statsProperty = _compareToSettings['stats'] ?? '';
        return statsProperty.isNotEmpty ? 'stats.$statsProperty' : null;
      case 'data':
        String dataKey = _compareToSettings['key'] ?? '';
        String dataProperty = _compareToSettings['data'] ?? '';
        return dataKey.isNotEmpty && dataProperty.isNotEmpty ? 'data.$dataKey.$dataProperty' : null;
      default:
        return '';
    }
  }

  List<dynamic> get customValueList {
    List<dynamic> valueList = [];
    for (TextEditingController controller in _customValueTextControllers) {
      valueList.add(SurveyElementCreationWidget.parseTextForType(controller.text));
    }
    return valueList;
  }

  RuleComparison get defaultRuleComparison => RuleComparison(dataKey: _toSurveyPropertyString('data_key'), operator: "==", compareTo: compareToValue);

  RuleAction get defaultRuleAction => RuleAction(action: "return", data: null);

  void _onChangeElementType(String? elemType) {
    setState(() {
      String id = _ruleElem.id;
      switch (elemType) {
        case "if":
          if (_ruleElem is RuleCondition) {
            _ruleElem = defaultRuleComparison;
          } else if (_ruleElem is Rule) {
            _ruleElem = Rule(condition: defaultRuleComparison, trueResult: (_ruleElem as Rule).trueResult, falseResult: (_ruleElem as Rule).falseResult);
          } else {
            _ruleElem = Rule(condition: defaultRuleComparison, trueResult: defaultRuleAction, falseResult: defaultRuleAction);
          }
          _customValueSelection = 'survey';
          break;
        case "and":
          RuleLogic defaultAnd = RuleLogic("and", [defaultRuleComparison, defaultRuleComparison]);
          if (_ruleElem is RuleCondition) {
            _ruleElem = defaultAnd;
          } else if (_ruleElem is Rule) {
            _ruleElem = Rule(condition: defaultAnd, trueResult: (_ruleElem as Rule).trueResult, falseResult: (_ruleElem as Rule).falseResult);
          } else {
            _ruleElem = Rule(condition: defaultRuleComparison, trueResult: defaultRuleAction, falseResult: defaultRuleAction);
          }
          break;
        case "or":
          RuleLogic defaultOr = RuleLogic("or", [defaultRuleComparison, defaultRuleComparison]);
          if (_ruleElem is RuleCondition) {
            _ruleElem = defaultOr;
          } else if (_ruleElem is Rule) {
            _ruleElem = Rule(condition: defaultOr, trueResult: (_ruleElem as Rule).trueResult, falseResult: (_ruleElem as Rule).falseResult);
          } else {
            _ruleElem = Rule(condition: defaultRuleComparison, trueResult: defaultRuleAction, falseResult: defaultRuleAction);
          }
          break;
        case "cases":
          _ruleElem = RuleCases(cases: [
            Rule(condition: defaultRuleComparison, trueResult: defaultRuleAction),
            Rule(condition: defaultRuleComparison, trueResult: defaultRuleAction)
          ]);
          break;
        case "action":
          _ruleElem = defaultRuleAction;
          break;
        case "action_list":
          _ruleElem = RuleActionList(actions: [defaultRuleAction, defaultRuleAction]);
          break;
        // case "reference":
        //   _ruleElem = RuleReference("");
        //   break;
      }
      _ruleElem.id = id;
    });
  }

  void _onChangeCustomValueSelection(String? value) {
    setState(() {
      _customValueSelection = value ?? 'survey';
    });
  }

  void _onChangeSurveyPropertySetting(String? value, String settings, String key) {
    setState(() {
      switch (settings) {
        case 'data_key':
          _dataKeySettings[key] = value;
          break;
        case 'compare_to':
          _compareToSettings[key] = value;
          break;
        case 'action':
          _actionSettings[key] = value;
          break;
      }
    });
  }

  void _onChangeActionSetting(String? value, String key) {
    setState(() {
      _actionSettings[key] = value;
    });
  }

  void _onChangeComparisonType(String? compType) {
    if (compType != null) {
      setState(() {
        if ((_ruleElem as Rule).condition is RuleComparison) {
          ((_ruleElem as Rule).condition as RuleComparison).operator = compType;
        } else if (_ruleElem is RuleComparison) {
          (_ruleElem as RuleComparison).operator = compType;
        }
      });
    }
  }

  void _onChangeActionType(String? actionType) {
    if (actionType != null) {
      setState(() {
        (_ruleElem as RuleAction).action = actionType;
        if (actionType == 'local_notify') {
          _actions ??= [];
        }
        _actionSettings['key'] = null;
      });
    }
  }

  void _onTapAddAction(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    setState(() {
      _actions ??= [];
      _actions!.insert(index, index > 0 ? _actions![index-1] : ActionData(label: 'New Action', type: ActionType.launchUri, params: {}));
    });
  }

  void _onTapRemoveAction(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    setState(() {
      _actions!.removeAt(index);
    });
  }

  void _onTapEditAction(int index, SurveyElement surveyElement, RuleElement? element) async {
    dynamic updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataOptionsPanel(
      data: _actions![index],
      dataKeys: widget.questionDataKeys,
      isRuleData: true,
      tabBar: widget.tabBar
    )));
    if (updatedData != null && mounted) {
      setState(() {
        _actions![index] = updatedData;
      });
    }
  }

  void _onAcceptDataDrag(int oldIndex, int newIndex) {
    setState(() {
      ActionData temp = _actions![oldIndex];
      _actions!.removeAt(oldIndex);
      _actions!.insert(newIndex, temp);
    });
  }

  void _onTapAddValueAtIndex(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    setState(() {
      _customValueTextControllers.insert(index, TextEditingController(text: index > 0 ? _customValueTextControllers[index - 1].text : ''));
    });
  }

  void _onTapRemoveValueAtIndex(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    _customValueTextControllers[index].dispose();
    setState(() {
      _customValueTextControllers.removeAt(index);
    });
  }

  String? _getElementTypeString() {
    if (_ruleElem is RuleComparison) {
      return "if";
    } else if (_ruleElem is RuleLogic) {
      return (_ruleElem as RuleLogic).operator;
    } else if (_ruleElem is Rule && (_ruleElem as Rule).condition != null) {
      RuleCondition condition = (_ruleElem as Rule).condition!;
      return condition is RuleComparison ? "if" : (condition as RuleLogic).operator;
    } else if (_ruleElem is RuleAction) {
      return "action";
    } else if (_ruleElem is RuleActionList) {
      return "action_list";
    } else if (_ruleElem is RuleCases) {
      return "cases";
    }
    // else if (_ruleElem is RuleReference) {
    //   return "reference";
    // }
    return null;
  }

  void _onTapDone() {
    bool error = false;
    if (_ruleElem is RuleComparison) {
      String dataKeyString = _toSurveyPropertyString('data_key');
      error = dataKeyString.isEmpty;
      (_ruleElem as RuleComparison).dataKey = dataKeyString;
      (_ruleElem as RuleComparison).compareTo = compareToValue;
      (_ruleElem as RuleComparison).defaultResult = false;
    } else if (_ruleElem is Rule && (_ruleElem as Rule).condition is RuleComparison) {
      String dataKeyString = _toSurveyPropertyString('data_key');
      error = dataKeyString.isEmpty;
      ((_ruleElem as Rule).condition as RuleComparison).dataKey = dataKeyString;
      ((_ruleElem as Rule).condition as RuleComparison).compareTo = compareToValue;
      ((_ruleElem as Rule).condition as RuleComparison).defaultResult = false;
    } else if (_ruleElem is RuleAction) {
      switch ((_ruleElem as RuleAction).action) {
        case 'return':
          error = widget.forceReturnQuestionData ? false : (_textControllers['custom_compare']?.text.isEmpty ?? true);
          (_ruleElem as RuleAction).data = widget.forceReturnQuestionData ? 'data.${_actionSettings['key']}' : compareToValue;
          break;
        case 'set_result':
          error = _customValueSelection == 'survey' && (_actionSettings['key'] == null);
          (_ruleElem as RuleAction).data = _customValueSelection == 'survey' ? _toSurveyPropertyString('action') : compareToValue;
          String? dataKey = _textControllers['result_data_key']?.text;
          (_ruleElem as RuleAction).dataKey = (dataKey?.isNotEmpty ?? false) ? dataKey : null;
          break;
        case 'alert':
          error = _actionSettings['key'] == null;
          (_ruleElem as RuleAction).data = 'data.${_actionSettings['key']}';
          break;
        case 'alert_result':
          error = _actionSettings['key'] == null;
          (_ruleElem as RuleAction).data = 'data.${_actionSettings['key']}';
          String? dataKey = _textControllers['result_data_key']?.text;
          (_ruleElem as RuleAction).dataKey = (dataKey?.isNotEmpty ?? false) ? dataKey : null;
          break;
        case 'save':
          (_ruleElem as RuleAction).data = (_ruleElem as RuleAction).dataKey = null;
          break;
        case 'local_notify':
          int? periodValue = int.tryParse(_textControllers['local_notify.period']!.text);
          error = CollectionUtils.isEmpty(_actions) || periodValue == null || _actionSettings['local_notify.period'] == null;
          if (!error) {
            (_ruleElem as RuleAction).data = Alert(
              title: _textControllers['local_notify.title']!.text,
              text: _textControllers['local_notify.text']!.text,
              actions: _actions,
              params: <String, dynamic>{
                'type': 'relative',  //TODO: implement other types
                'schedule': <String, int>{
                  _actionSettings['local_notify.period']!: periodValue,
                }
              }
            );
          }
      }
    }

    //TODO:
    // better error messaging (required dropdowns missing selection)
    // handle missing data keys for survey data comparisons
    if (error) {
      PopupMessage.show(context: context,
        title: "Invalid Data Key",
        message: "Please fill in all required fields.",
        buttonTitle: Localization().getStringEx("dialog.ok.title", "OK"),
        onTapButton: (context) {
          Navigator.pop(context);
        },
      );
    } else {
      Navigator.of(context).pop(_ruleElem);
    }    
  }
}