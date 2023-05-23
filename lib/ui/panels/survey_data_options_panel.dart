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
import 'package:rokwire_plugin/model/options.dart';
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/survey_data_default_response_panel.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/survey_creation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyDataOptionsPanel extends StatefulWidget {
  final dynamic data;
  final List<String> dataKeys;
  final bool isRuleData;
  final Widget? tabBar;

  const SurveyDataOptionsPanel({Key? key, required this.data, required this.dataKeys, this.isRuleData = false, this.tabBar}) : super(key: key);

  @override
  _SurveyDataOptionsPanelState createState() => _SurveyDataOptionsPanelState();
}

class _SurveyDataOptionsPanelState extends State<SurveyDataOptionsPanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  final Map<String, TextEditingController> _textControllers = {};

  late dynamic _data;
  String _headerText = '';
  String? _actionDataType;
  List<String>? _defaultResponseKeys;
  List<dynamic>? _defaultResponseValues;

  @override
  void initState() {
    _data = widget.data;

    if (_data is OptionData) {
      _headerText = 'Edit Option';

      _textControllers["title"] = TextEditingController(text: (_data as OptionData).title);
      _textControllers["hint"] = TextEditingController(text: (_data as OptionData).hint);
      _textControllers["value"] = TextEditingController(text: (_data as OptionData).value?.toString() ?? '');
      _textControllers["score"] = TextEditingController(text: (_data as OptionData).score?.toString());
    } else if (_data is ActionData) {
      _headerText = 'Edit Action';

      _textControllers["label"] = TextEditingController(text: (_data as ActionData).label?.toString());
      _textControllers["data"] = TextEditingController(text: (_data as ActionData).data?.toString() ?? '');

      dynamic actionData = (_data as ActionData).data;
      if (actionData is String) {
        if (actionData.startsWith('tel:')) {
          _actionDataType = 'phone';
          _textControllers["data"]!.text = _textControllers["data"]!.text.substring(6);
        } else if (actionData.startsWith('http')) {
          _actionDataType = 'url';
        }
      }
      if ((_data as ActionData).type == ActionType.showSurvey) {
        Map<String, dynamic>? defaultResponses = (_data as ActionData).defaultResponsesForNotification;
        for (MapEntry<String, dynamic> response in defaultResponses?.entries ?? []) {
          _defaultResponseKeys ??= [];
          _defaultResponseKeys!.add(response.key);
          _defaultResponseValues ??= [];
          _defaultResponseValues!.add(response.value);
        }
      }
    }

    super.initState();
  }

  @override
  void dispose() {
    _textControllers.forEach((_, value) {
      value.dispose();
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: _headerText),
      bottomNavigationBar: widget.tabBar,
      backgroundColor: Styles().colors?.background,
      body: SurveyElementCreationWidget(body: _buildSurveyDataOptions(), completionOptions: _buildDone(), scrollController: _scrollController,),
    );
  }

  Widget _buildSurveyDataOptions() {
    List<Widget> content = [];
    if (_data is OptionData) {
      content.addAll([
        //title*
        FormFieldText('Title', padding: EdgeInsets.zero, controller: _textControllers["title"], inputType: TextInputType.text, textCapitalization: TextCapitalization.words,),
        //hint
        FormFieldText('Hint', padding: const EdgeInsets.only(top: 16), controller: _textControllers["hint"], inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),
        //value* (dynamic value = _value ?? title)
        FormFieldText('Value', padding: const EdgeInsets.only(top: 16), controller: _textControllers["value"], inputType: TextInputType.text),
        //score
        FormFieldText('Score', padding: const EdgeInsets.only(top: 16), controller: _textControllers["score"], inputType: TextInputType.number,),
      ],);

      // correct answer
      content.add(SurveyElementCreationWidget.buildCheckboxWidget("Correct Answer", (_data as OptionData).isCorrect, _onToggleCorrect));
    } else if (_data is ActionData) {
      //type*
      content.add(SurveyElementCreationWidget.buildDropdownWidget<String>(ActionData.supportedTypes, "Type", (_data as ActionData).type.name, _onChangeAction, margin: EdgeInsets.zero));
      //label
      content.add(FormFieldText('Label', padding: const EdgeInsets.only(top: 16), controller: _textControllers["label"], inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences));
      
      //data
      Map<String, String>? supportedDataTypes = _getSupportedActionDataTypes((_data as ActionData).type);
      if (supportedDataTypes != null) {
        content.add(SurveyElementCreationWidget.buildDropdownWidget<String>(supportedDataTypes, "Data Type", _actionDataType, _onChangeActionDataType));

        content.add(FormFieldText('Value', padding: const EdgeInsets.only(top: 16), controller: _textControllers["data"],
          inputType: _getActionTextInputType(_actionDataType), maxLength: _getActionTextMaxLength(_actionDataType)));
      }
      
      //params
      if ((_data as ActionData).type == ActionType.launchUri && _actionDataType == 'url') {
        content.add(SurveyElementCreationWidget.buildCheckboxWidget("Internal", (_data as ActionData).isInternalUri ?? false, _onToggleInternal));
      } else if ((_data as ActionData).type == ActionType.showSurvey) {
        content.add(SurveyElementCreationWidget.buildCheckboxWidget("Primary", (_data as ActionData).isPrimaryForNotification ?? false, _onTogglePrimary, padding: const EdgeInsets.symmetric(vertical: 16)));
        
        List<String> defaultResponseSummaries = [];
        if (CollectionUtils.isNotEmpty(_defaultResponseKeys)) {
          defaultResponseSummaries = List.generate(_defaultResponseKeys!.length, (index) {
            String response = _defaultResponseValues![index];
            if (response == '${_defaultResponseKeys![index]}.response') {
              response = 'Previous Answer';
            }
            return '${_defaultResponseKeys![index].substring(5)} ($response)';
          });
        }
        content.add(Visibility(
          visible: widget.dataKeys.isNotEmpty,
          child: SurveyElementList(
            type: SurveyElementListType.data,
            label: 'Default Responses (${_defaultResponseKeys?.length ?? 0})',
            dataList: defaultResponseSummaries,
            surveyElement: SurveyElement.questionData,
            onAdd: _onTapAddDefaultResponse,
            onEdit: _onTapEditDefaultResponse,
            onRemove: _onTapRemoveDefaultResponse,
            limit: widget.dataKeys.length,
          ),
        ));
      }
    }

    return Padding(padding: const EdgeInsets.all(16), child: Column(children: content,));
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

  Map<String, String>? _getSupportedActionDataTypes(ActionType actionType) {
    switch (actionType) {
      case ActionType.launchUri:
        //TODO: add more URI types (e.g., email?, sms?)
        return {'phone': 'Phone', 'url': 'Web Browser'};
      case ActionType.showSurvey:
        //TODO: get list of surveys that the creator may "link" to?
      case ActionType.showPanel:
        //TODO: get list of panels that the creator may "link" to?
      default:
        return null;
    }
  }

  TextInputType? _getActionTextInputType(String? actionDataType) {
    switch (actionDataType) {
      case 'phone':
        return TextInputType.phone;
      case 'url':
        return TextInputType.url;
      default:
        return null;
    }
  }

  int? _getActionTextMaxLength(String? actionDataType) {
    switch (actionDataType) {
      case 'phone':
        return 10;
      default:
        return null;
    }
  }

  void _onTapAddDefaultResponse(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    setState(() {
      _defaultResponseKeys ??= [];
      _defaultResponseKeys!.insert(index, widget.dataKeys[index]);
      _defaultResponseValues ??= [];
      _defaultResponseValues!.insert(index, 'data.${widget.dataKeys[index]}.response');
    });
  }

  void _onTapRemoveDefaultResponse(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    setState(() {
      _defaultResponseKeys!.removeAt(index);
      _defaultResponseValues!.removeAt(index);
    });
  }

  void _onTapEditDefaultResponse(int index, SurveyElement surveyElement, RuleElement? element, RuleElement? parentElement) async {
    MapEntry<String, dynamic>? updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataDefaultResponsePanel(
      dataKey: _defaultResponseKeys![index],
      dataKeys: widget.dataKeys,
      response: _defaultResponseValues![index],
      tabBar: widget.tabBar
    )));
    if (updatedData != null && mounted) {
      setState(() {
        _defaultResponseKeys![index] = updatedData.key;
        _defaultResponseValues![index] = updatedData.value;
      });
    }
  }

  void _onChangeAction(String? action) {
    setState(() {
      (_data as ActionData).type = action != null ? ActionType.values.byName(action) : ActionType.none;
      Map<String, String>? supportedDataTypes = _getSupportedActionDataTypes((_data as ActionData).type);
      _actionDataType = supportedDataTypes?.isNotEmpty ?? false ? supportedDataTypes!.keys.first : null;
    });
  }

  void _onChangeActionDataType(String? dataType) {
    setState(() {
      _actionDataType = dataType;
    });
  }

  void _onToggleCorrect(bool? value) {
    setState(() {
      (_data as OptionData).isCorrect = value ?? false;
    });
  }

  void _onTogglePrimary(bool? value) {
    setState(() {
      (_data as ActionData).isPrimaryForNotification = value;
    });
  }

  void _onToggleInternal(bool? value) {
    setState(() {
      (_data as ActionData).isInternalUri = value;
    });
  }

  void _onTapDone() {
    if (_data is OptionData) {
      (_data as OptionData).title = _textControllers["title"]!.text;
      (_data as OptionData).hint = _textControllers["hint"]!.text;
      (_data as OptionData).score = num.tryParse(_textControllers["score"]!.text);
      (_data as OptionData).value =  SurveyElementCreationWidget.parseTextForType(_textControllers['value']!.text);
    } else if (_data is ActionData) {
      (_data as ActionData).label = _textControllers["label"]!.text;
      (_data as ActionData).data = (_data as ActionData).type == ActionType.showSurvey ? 'this' : _textControllers["data"]!.text;
      if (_actionDataType == 'phone') {
        (_data as ActionData).data = 'tel:${StringUtils.constructUsPhone((_data as ActionData).data)}';
      }
      if ((_data as ActionData).type == ActionType.showSurvey) {
        (_data as ActionData).defaultResponsesForNotification = Map.fromIterables(_defaultResponseKeys ?? [], _defaultResponseValues ?? []);
      }
    }

    Navigator.of(context).pop(_data);
  }
}