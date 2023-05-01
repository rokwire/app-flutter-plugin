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

import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/model/options.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyDataOptionsPanel extends StatefulWidget {
  final dynamic data;
  final Widget? tabBar;

  const SurveyDataOptionsPanel({Key? key, required this.data, this.tabBar}) : super(key: key);

  @override
  _SurveyDataOptionsPanelState createState() => _SurveyDataOptionsPanelState();
}

class _SurveyDataOptionsPanelState extends State<SurveyDataOptionsPanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  final Map<String, TextEditingController> _textControllers = {};

  late dynamic _data;
  String _headerText = '';
  final Map<String, String> _supportedActions = {};

  @override
  void initState() {
    _data = widget.data;

    if (_data is OptionData) {
      _headerText = 'Edit Option';

      _textControllers["title"] = TextEditingController(text: (_data as OptionData).title);
      _textControllers["hint"] = TextEditingController(text: (_data as OptionData).hint);
      _textControllers["value"] = TextEditingController(text: (_data as OptionData).value.toString());
      _textControllers["score"] = TextEditingController(text: (_data as OptionData).score?.toString());
    } else if (_data is ActionData) {
      _headerText = 'Edit Action';

      _textControllers["label"] = TextEditingController(text: (_data as ActionData).label?.toString());
    }

    for (ActionType action in ActionType.values) {
      _supportedActions[action.name] = action.name;
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
      body: Column(
        children: [
          Expanded(child: Scrollbar(
            radius: const Radius.circular(2),
            thumbVisibility: true,
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: _buildSurveyDataOptions(),
            ),
          )),
          Container(
            color: Styles().colors?.backgroundVariant,
            child: _buildDone(),
          ),
        ],
    ));
  }

  Widget _buildSurveyDataOptions() {
    List<Widget> content = [];
    if (_data is OptionData) {
      content.addAll([
        //title*
        FormFieldText('Title', padding: EdgeInsets.zero, controller: _textControllers["title"], inputType: TextInputType.text),
        //hint
        FormFieldText('Hint', padding: const EdgeInsets.only(top: 16), controller: _textControllers["hint"], inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),
        //value* (dynamic value = _value ?? title)
        FormFieldText('Value', padding: const EdgeInsets.only(top: 16), controller: _textControllers["value"], inputType: TextInputType.text),
        //score
        FormFieldText('Score', padding: const EdgeInsets.only(top: 16), controller: _textControllers["score"], inputType: TextInputType.number,),
      ],);

      // correct answer
      content.add(Padding(padding: const EdgeInsets.only(top: 16.0), child: CheckboxListTile(
        title: Padding(padding: const EdgeInsets.only(left: 8), child: Text("Correct Answer", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        tileColor: Styles().colors?.getColor('surface'),
        checkColor: Styles().colors?.getColor('surface'),
        activeColor: Styles().colors?.getColor('fillColorPrimary'),
        value: (_data as OptionData).isCorrect,
        onChanged: _onToggleCorrect,
      ),));
    } else if (_data is ActionData) {
      //type*
      content.add(Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: EdgeInsets.zero,
        child: Row(children: [
          Text("Type", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
          Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
            DropdownButton<String>(
              icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
              isExpanded: true,
              style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
              items: _buildDropdownItems<String>(_supportedActions),
              value: (_data as ActionData).type.name,
              onChanged: _onChangeAction,
              dropdownColor: Styles().colors?.getColor('surface'),
            ),
          ),))],
        )
      ));
      //label
      content.add(FormFieldText('Label', padding: const EdgeInsets.only(top: 16), controller: _textControllers["label"], inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences));
      //TODO
        // dynamic data (e.g., URL, phone num., sms num., etc.)
        // Map<String, dynamic> params
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

  List<DropdownMenuItem<T>> _buildDropdownItems<T>(Map<T, String> supportedItems) {
    List<DropdownMenuItem<T>> items = [];

    for (MapEntry<T, String> item in supportedItems.entries) {
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

  void _onChangeAction(String? action) {
    setState(() {
      (_data as ActionData).type = action != null ? ActionType.values.byName(action) : ActionType.none;
    });
  }

  void _onToggleCorrect(bool? value) {
    setState(() {
      (_data as OptionData).isCorrect = value ?? false;
    });
  }

  void _onTapDone() {
    if (_data is OptionData) {
      (_data as OptionData).title = _textControllers["title"]!.text;
      (_data as OptionData).hint = _textControllers["hint"]!.text;
      (_data as OptionData).score = num.tryParse(_textControllers["score"]!.text);

      String valueText = _textControllers['value']!.text;
      bool? valueBool = valueText.toLowerCase() == 'true' ? true : (valueText.toLowerCase() == 'false' ? false : null);
      (_data as OptionData).value = num.tryParse(valueText) ?? DateTimeUtils.dateTimeFromString(valueText) ?? valueBool ?? (valueText.isNotEmpty ? valueText : null);
    } else if (_data is ActionData) {
      (_data as ActionData).label = _textControllers["label"]!.text;
    }

    Navigator.of(context).pop(_data);
  }
}