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

/*
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';

import 'package:rokwire_plugin/ui/widgets/survey.dart';

import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyPanel extends StatefulWidget {
  final Survey survey;
  final String? currentSurveyKey;
  final Function? onComplete;
  final bool showSummaryOnFinish;
  final bool allowBack;
  final int initPanelDepth;

  const SurveyPanel({required this.survey, this.currentSurveyKey, this.showSummaryOnFinish = false, this.allowBack = true, this.onComplete, this.initPanelDepth = 0});

  @override
  _SurveyPanelState createState() => _SurveyPanelState();
}

class _SurveyPanelState extends State<SurveyPanel> {
  late Survey _survey;
  late Map<String, SurveyData> _surveyQuestions;
  String? _surveyQuestionKey;
  SurveyData? _mainSurveyQuestion;

  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  bool _scrollEnd = false;

  late final SurveyWidgets widgets;

  @override
  void initState() {
    super.initState();

    widgets = SurveyWidgets(context, _onChangeSurveyResponse);

    _survey = widget.survey;
    _surveyQuestionKey = widget.currentSurveyKey ?? _survey.firstQuestion?.key;
    if (_survey.data.isEmpty || !_survey.data.containsKey(_surveyQuestionKey)) {
      _popSurveyPanels();
      return;
    }
    _surveyQuestions = _survey.data;

    _mainSurveyQuestion = _surveyQuestions[_surveyQuestionKey];
    _mainSurveyQuestion?.evaluateDefaultResponse(_survey);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_checkScroll);
    return WillPopScope(
      onWillPop: () async => widget.allowBack,
      child: Scaffold(
          backgroundColor: Styles().colors?.background,
          body: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  HeaderBar(title: _survey.title),
                  Expanded(child: _buildScrollView()),
                  _buildContinueButton(),
              ]),
            ],
          )),
    );
  }

  Widget _buildScrollView() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scrollbar(
        radius: const Radius.circular(2),
        thumbVisibility: true,
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_mainSurveyQuestion == null) {
      return Text(Localization().getStringEx("panel.survey.error.invalid_data.title", "Invalid survey data"));
    }

    Widget? questionWidget = widgets.buildInlineSurveyWidget(_mainSurveyQuestion!);
    List<Widget> followUps = [];
    for (SurveyData? data = _mainSurveyQuestion?.followUp(_survey); data != null; data = data.followUp(_survey)) {
      Widget? followUp;
      if (data is SurveyDataSurvey) {
        followUp = widgets.buildInlineSurveyWidget(data, onComplete: (val) {
          setState(() {
            _mainSurveyQuestion?.response = val;
          });
        });
      } else {
        followUp = widgets.buildInlineSurveyWidget(data);
      }
      if (followUp != null) {
        GlobalKey? key;
        if (data.response == null) {
          key = GlobalKey();
          dataKey = key;
        }
        followUps.add(Padding(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Card(
              color: Styles().colors?.background,
              margin: EdgeInsets.zero,
              elevation: 0.0,
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: followUp)),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(children: [
        questionWidget ?? Container(),
        Wrap(children: followUps),
      ]),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, right: 32.0, bottom: 16.0),
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
        RoundedButton(label: Localization().getStringEx("panel.survey.button.action.continue.title", "Continue"), onTap: _onTapContinue, progress: null),
      ]),
    );
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

  void _onTapContinue() async {
    final targetContext = dataKey?.currentContext;
    if (targetContext != null) {
      double startScroll = _scrollController.position.pixels;
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      dataKey = null;
      double scrollDiff = _scrollController.position.pixels - startScroll;
      if (scrollDiff.abs() > 20.0) {
        return;
      }
    }

    if (_mainSurveyQuestion?.canContinue(_survey) == false) {
      AppToast.show("Please answer all required questions to continue");
      return;
    }

    // show survey summary or return to home page on finishing events
    // SurveyData? followUp = _mainSurveyQuestion?.followUp(_survey);
    // if (followUp == null) {
    _survey.lastUpdated = DateTime.now();

      // if (widget.showSummaryOnFinish) {
      // } else {
    _finishSurvey();
      // }

      // return;
    // }

    // Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: _survey, currentSurveyKey: followUp.key, showSummaryOnFinish: widget.showSummaryOnFinish, onComplete: widget.onComplete, initPanelDepth: widget.initPanelDepth + 1,)));
  }

  void _finishSurvey() {
    _popSurveyPanels();
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  void _popSurveyPanels() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int count = 0;
      Navigator.of(context).popUntil((route) => count++ > widget.initPanelDepth);
    });
  }
}
*/