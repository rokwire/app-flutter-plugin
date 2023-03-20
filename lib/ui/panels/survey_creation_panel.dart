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

import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';

import 'package:rokwire_plugin/ui/widgets/survey.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';

class SurveyCreationPanel extends StatefulWidget {
  final Function(SurveyResponse?)? onComplete;
  final bool showSummaryOnFinish;
  final bool allowBack;
  final Widget? tabBar;
  final Widget? offlineWidget;

  const SurveyCreationPanel({Key? key, this.showSummaryOnFinish = false, this.allowBack = true, this.onComplete, this.tabBar, this.offlineWidget}) : super(key: key);

  @override
  _SurveyCreationPanelState createState() => _SurveyCreationPanelState();
}

class _SurveyCreationPanelState extends State<SurveyCreationPanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();

  String _title = '';
  bool _scored = true;
  bool _sensitive = false;
  late final SurveyWidgetController _surveyController;

  @override
  void initState() {
    _surveyController = SurveyWidgetController(onComplete: widget.onComplete);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderBar(title: "Create Survey"),
      bottomNavigationBar: widget.tabBar,
      backgroundColor: Styles().colors?.background,
      body: Column(
        children: [
          // Visibility(visible: _loading, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors?.fillColorPrimary))),
          Expanded(child: Scrollbar(
            radius: const Radius.circular(2),
            thumbVisibility: true,
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: _buildSurveyCreationTools(),
            ),
          )),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: SurveyWidget.buildContinueButton(_surveyController),
          ),
        ],
    ));
  }

  Widget _buildSurveyCreationTools() {
    return Column(children: [
      // title
      const FormFieldText('Title', inputType: TextInputType.text, textCapitalization: TextCapitalization.words),
      // more_info
      const FormFieldText('Additional Information', multipleLines: true, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),

      // type
      //TODO: use dropdown here

      // scored
      Checkbox(
        checkColor: Styles().colors?.surface,
        activeColor: Styles().colors?.fillColorPrimary,
        value: _scored,
        onChanged: (value) {
          if (mounted) {
            setState(() {
              _scored = value ?? true;
            });
          }
        },
      ),

      // sensitive
      Checkbox(
        checkColor: Styles().colors?.surface,
        activeColor: Styles().colors?.fillColorPrimary,
        value: _sensitive,
        onChanged: (value) {
          if (mounted) {
            setState(() {
              _sensitive = value ?? false;
            });
          }
        },
      ),
    ],);
    //TODO:
    
    // data
        // "true_false"
        // "multiple_choice"
        // "date_time"
        // "numeric"
        // "text"
        // "entry"
        // "result"
        // "page"
    // default data key (i.e., first "question")
    // default data key rule (i.e., rule for determining first "question")
    // constants
        // unique ID: value
    // strings
        // language code
            // unique ID: string
    // result_rules (list)
        // dropdown for actions
            // "return":
            // "sum":
            // "set_result":
            // "show_survey":
            // "alert":
            // "alert_result":
            // "notify":
            // "save":
            // "local_notify"
        // dropdown for comparison options
            // "<":
            // ">":
            // "<=":
            // ">=":
            // "==":
            // "!=":
            // "in_range":
            // "any":
            // "all"
        // dropdown for data keys, compare_to options (stats, responses, constants, strings, etc.)
    // sub_rules
    // response_keys? (history?)

  }
}