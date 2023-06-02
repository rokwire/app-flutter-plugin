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
import 'package:rokwire_plugin/gen/styles.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ExpandableSection extends StatefulWidget {
  final String? title;
  final TextStyle? titleStyle;
  final Widget? titleWidget;
  final TextStyle? subtitleStyle;
  final String? subtitle;
  final Widget? subtitleWidget;
  final String? iconKey;
  final Widget? contents;
  final bool initiallyExpanded;

  ExpandableSection({this.title, this.titleStyle, this.titleWidget, this.subtitle, this.subtitleStyle,
    this.subtitleWidget, this.iconKey, this.contents, this.initiallyExpanded = false, Key? key}) : super(key: key);

  @override
  ExpandableSectionState createState() => ExpandableSectionState();

  @protected Color? get defaultTitleColor => AppColors.textPrimary;
  @protected String? get defaultTitleFontFamily => AppFontFamilies.bold;
  @protected double? get defaultTitleSize => 18;
  @protected TextStyle get defaultTitleStyle => TextStyle(fontFamily: defaultTitleFontFamily,
      fontSize: defaultTitleSize, color: defaultTitleColor);
  @protected TextStyle get displayTitleStyle => titleStyle ?? defaultTitleStyle;
  @protected Widget get defaultTitleWidget => Text(title ?? '', style: displayTitleStyle);
  @protected Widget get displayTitleWidget => titleWidget ?? defaultTitleWidget;

  @protected Color? get defaultSubtitleColor => AppColors.textDark;
  @protected String? get defaultSubtitleFontFamily => AppFontFamilies.bold;
  @protected double? get defaultSubtitleSize => 16;
  @protected TextStyle get defaultSubtitleStyle => TextStyle(fontFamily: defaultSubtitleFontFamily,
      fontSize: defaultSubtitleSize, color: defaultSubtitleColor);
  @protected TextStyle get displaySubtitleStyle => subtitleStyle ?? defaultSubtitleStyle;
  @protected Widget? get defaultSubtitleWidget => subtitle != null ? Text(subtitle ?? '', style: displaySubtitleStyle) : null;
  @protected Widget? get displaySubtitleWidget => subtitleWidget ?? defaultSubtitleWidget;
}

class ExpandableSectionState extends State<ExpandableSection> {
  bool _expanded = false;

  @override
  void initState() {
    _expanded = widget.initiallyExpanded;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          initiallyExpanded: widget.initiallyExpanded,
          title: widget.displayTitleWidget,
          subtitle: widget.displaySubtitleWidget,
          trailing: Styles().images?.getImage(_expanded ? 'chevron-up' : 'chevron-down',
            defaultSpec: FontAwesomeImageSpec(
                type: 'fa.icon',
                source: _expanded ? '0xf077' : '0xf078',
                weight: 'solid',
                size: 18,
                color: AppColors.fillColorSecondary
            )
          ),
          children: [widget.contents ?? Container(),],
          onExpansionChanged: (bool expanded) {
            setState(() => _expanded = expanded);
          },
        )
      ],
    );
  }
}