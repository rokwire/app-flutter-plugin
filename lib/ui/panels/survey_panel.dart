/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
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
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/styles.dart';

import 'package:rokwire_plugin/ui/widgets/survey.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';

class SurveyPanel extends StatefulWidget {
  final dynamic survey;
  final String? surveyDataKey;
  final bool inputEnabled;
  final DateTime? dateTaken;
  final bool showResult;
  final Function? onComplete;
  final bool showSummaryOnFinish;
  final bool allowBack;
  final int initPanelDepth;

  const SurveyPanel({required this.survey, this.surveyDataKey, this.inputEnabled = true,
    this.showSummaryOnFinish = false, this.dateTaken, this.showResult = false, this.allowBack = true,
    this.onComplete, this.initPanelDepth = 0});

  @override
  _SurveyPanelState createState() => _SurveyPanelState();
}

class _SurveyPanelState extends State<SurveyPanel> {
  bool _loading = false;
  Survey? _survey;

  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  bool _scrollEnd = false;

  @override
  void initState() {
    if (widget.survey is Survey) {
      _survey = widget.survey;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_checkScroll);
    return Scaffold(
      appBar: HeaderBar(title: _survey?.title),
      backgroundColor: Styles().colors?.background,
      body: Stack(
        children: [
          Visibility(visible: _loading, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors?.fillColorPrimary))),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: _buildScrollView()),
          ]),
        ],
    ));
  }

  Widget _buildScrollView() {
    return Scrollbar(
      radius: const Radius.circular(2),
      thumbVisibility: true,
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SurveyWidget(
          survey: widget.survey,
          onChangeSurveyResponse: _onChangeSurveyResponse,
          inputEnabled: widget.inputEnabled,
          dateTaken: widget.dateTaken,
          showResult: widget.showResult,
          surveyDataKey: widget.surveyDataKey,
          onComplete: _onComplete,
          onLoad: _setSurvey,
        ),
      ),
    );
  }

  void _onComplete() {
    widget.onComplete?.call();
    Navigator.of(context).pop();
  }

  void _setSurvey(Survey? survey) {
    if (survey != null) {
      setState(() {
        _survey = survey;
      });
    }
  }

  void _checkScroll(Duration duration) {
    if (_scrollEnd) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      _scrollEnd = false;
    }
  }

  void _onChangeSurveyResponse(bool scrollEnd) {
    setState(() { });
  }

  bool isScrolledToEnd() {
    double maxScroll = _scrollController.position.maxScrollExtent;
    double currentScroll = _scrollController.position.pixels;
    double delta = 20.0;
    if (maxScroll - currentScroll <= delta) {
      return true;
    }
    return false;
  }
}