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

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/ui/panels/web_panel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher_string.dart';

/*
  "emergency": {
    "title": "Emergency",
    "text": "Something urgent happened.",
    "can_close": true,
    "buttons":[
      {"title":"Yes", "link": {"url": "https://illinois.edu", "options": { "target": "internal", "title": "Yes Web Panel" } } },
      {"title":"No", "link": {"url": "https://illinois.edu", "options": { "target": "external" } } },
      {"title":"Maybe", "link": {"url": "https://illinois.edu", "options": { "target": { "ios": "internal", "android": "external" } } } }
    ]
  }
*/

class FlexContent extends StatefulWidget {
  final String? contentKey;
  final Map<String, dynamic>? contentJson;
  final void Function(BuildContext context)? onClose;

  const FlexContent({Key? key, this.contentKey, this.contentJson, this.onClose}) : super(key: key);

  @override
  FlexContentWidgetState createState() => FlexContentWidgetState();

  @protected
  Color? get backgroundColor => Styles().colors?.lightGray;

  @protected
  Color? get topSplitterColor => Styles().colors?.fillColorPrimaryVariant;

  @protected
  double? get topSplitterHeight => 1;

  @protected
  Widget get topSplitter => Container(height: topSplitterHeight, color: topSplitterColor);

  @protected
  Widget? buildContent(BuildContext context, Map<String, dynamic>? contentJson) {
    if (contentJson != null) {
      String? title = JsonUtils.stringValue(contentJson['title']);
      String? text = JsonUtils.stringValue(contentJson['text']);
      List<dynamic>? buttonsJson = JsonUtils.listValue(contentJson['buttons']);
      return Padding(padding: contentPadding, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          buildTitle(title),
          buildText(text),
          buildButtons(context, buttonsJson)
        ],),
      );
    }
    return null;
  }

  @protected
  EdgeInsetsGeometry get contentPadding => const EdgeInsets.symmetric(horizontal: 20, vertical: 30);

  @protected
  Widget buildTitle(String? title) => Visibility(visible: StringUtils.isNotEmpty(title), child:
    Padding(padding: titlePadding, child:
      Text(title ?? '', style: titleTextStyle,),
    ),
  );

  @protected
  EdgeInsetsGeometry get titlePadding => const EdgeInsets.only(top: 0);

  @protected
  TextStyle get titleTextStyle => TextStyle(color: Styles().colors?.fillColorPrimary, fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20, );

  @protected
  Widget buildText(String? text) => Visibility(visible: StringUtils.isNotEmpty(text), child:
    Padding(padding: textPadding, child:
      Text(StringUtils.ensureNotEmpty(text), style: textTextStyle, ),
    ),
  );

  @protected
  EdgeInsetsGeometry get textPadding => const EdgeInsets.only(top: 10);

  @protected
  TextStyle get textTextStyle => TextStyle(color: Styles().colors?.textSurface, fontFamily: Styles().fontFamilies?.medium, fontSize: 16, );

  @protected
  Widget buildButtons(BuildContext context, List<dynamic>? buttonsJson) {
    if (CollectionUtils.isNotEmpty(buttonsJson)) {
      List<Widget> buttons = [];
      for (dynamic buttonsJsonEntry in buttonsJson!) {
        Widget? buttonEntry = buildButtonEntry(context, JsonUtils.mapValue(buttonsJsonEntry));
        if (buttonEntry != null) {
          buttons.add(buttonEntry);
        }
      }
      return Padding(padding: buttonsPadding, child: Wrap(spacing: buttonsSpacing, runSpacing: buttonsRunSpacing, children: buttons));
    }
    return Container();
  }

  @protected
  EdgeInsetsGeometry get buttonsPadding => const EdgeInsets.only(top: 20);

  @protected
  double get buttonsRunSpacing => 8;

  @protected
  double get buttonsSpacing => 16;

  @protected
  Widget? buildButtonEntry(BuildContext context, Map<String, dynamic>? button) => (button != null) ?
    Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
      buildButton(context, button)
    ],) : null;

  @protected
  Widget buildButton(BuildContext context, Map<String, dynamic> button) => RoundedButton(
    label: StringUtils.ensureNotEmpty(JsonUtils.stringValue(button['title'])),
    textColor: Styles().colors!.fillColorPrimary,
    borderColor: Styles().colors!.fillColorSecondary,
    backgroundColor: Styles().colors!.white,
    contentWeight: 0.0,
    onTap: () => onTapButton(context, button),
  );

  @protected
  Widget? buildCloseButton(BuildContext context, { void Function()? onTap }) {
    String? imageKey = closeButtonKey;
    if (imageKey != null) {
      return Semantics(label: closeButtonLabel, hint: closeButtonHint, button: true, excludeSemantics: true, child:
        InkWell(onTap: onTap, child:
          Container(width: closeButtonSize.width, height: closeButtonSize.height, alignment: Alignment.center, child:
            Styles().images?.getImage(imageKey, excludeFromSemantics: true)
          )
        )
      );
    }
    return null;
  }

  @protected
  bool canClose(Map<String, dynamic>? contentJson) => (contentJson != null) && (contentJson['can_close'] == true);

  @protected
  String get closeButtonLabel => 'Close';
  
  @protected
  String get closeButtonHint => '';

  @protected
  Size get closeButtonSize => const Size(48, 48);

  @protected
  String? get closeButtonKey => null;

  @protected
  void onTapButton(BuildContext context, Map<String, dynamic> button) {
    Map<String, dynamic>? linkJson = JsonUtils.mapValue(button['link']);
    if (linkJson != null) {
      String? url = JsonUtils.stringValue(linkJson['url']);
      if (StringUtils.isNotEmpty(url)) {
        Map<String, dynamic>? options = JsonUtils.mapValue(linkJson['options']);
        dynamic target = (options != null) ? options['target'] : 'internal';
        if (target is Map) {
          target = target[Platform.operatingSystem.toLowerCase()];
        }

        if (target == 'external') {
          launchExternal(context, url!);
        }
        else {
          launchInternal(context, url!, title: (options != null) ? JsonUtils.stringValue(options['title']) : null);
        }
      }
    }
  }

  @protected
  void launchExternal(BuildContext context, String url) {
    launchUrlString(url);
  }

  @protected
  void launchInternal(BuildContext context, String url, { String? title }) =>
    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => WebPanel(url: url, title: title)));

  @protected
  void onTapClose(FlexContentWidgetState state) {
    if (onClose != null) {
      onClose!(state.context);
    }
    else {
      state.hide();
    }
  }
}

class FlexContentWidgetState extends State<FlexContent> implements NotificationsListener {
  bool _visible = true;
  Map<String, dynamic>? _contentJson;

  @override
  void initState() {
    _contentJson = widget.contentJson;
    if (widget.contentKey != null) {
      _contentJson ??= Content().contentWidget(widget.contentKey!);
      NotificationService().subscribe(this, Content.notifyContentWidgetsChanged);
    }
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param){
    if (name == Content.notifyContentWidgetsChanged) {
      if (widget.contentKey != null) {
        Map<String, dynamic>? contentJson = Content().contentWidget(widget.contentKey!);
        if (!const DeepCollectionEquality().equals(contentJson, _contentJson)) {
          setState(() {
            _contentJson = contentJson;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: _visible && (_contentJson != null), child:
      Semantics(container: true, child:
        Container(color: widget.backgroundColor, child:
          Row(children: <Widget>[
            Expanded(child:
              Stack(children: <Widget>[
                widget.topSplitter,
                widget.buildContent(context, _contentJson) ?? Container(),
                Visibility(visible: widget.canClose(_contentJson), child:
                  Container(alignment: Alignment.topRight, child:
                    widget.buildCloseButton(context, onTap: _onClose) ?? Container(height: widget.closeButtonSize.height)
                  ),
                ),
              ],),
            )],
          ),
        ),
    ),);
  }

  void _onClose() {
    widget.onTapClose(this);
  }

  void hide() {
    if (mounted) {
      setState(() {
        _visible = false;
      });
    }
  }
}
