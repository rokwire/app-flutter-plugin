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

class VerticalTitleValueSection extends StatelessWidget {
  final String? title;
  final String? titleFontFamily;
  final double titleFontSize;
  final Color? titleTextColor;
  final TextStyle? titleTextStyle;
  
  final String? value;
  final String? valueFontFamily;
  final double valueFontSize;
  final Color? valueTextColor;
  final TextStyle? valueTextStyle;

  final String? hint;
  final String? hintFontFamily;
  final double hintFontSize;
  final Color? hintTextColor;
  final TextStyle? hintTextStyle;

  final BoxBorder? border;
  final Color? borderColor;
  final double borderWidth;

  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const VerticalTitleValueSection({Key? key,
    this.title,
    this.titleFontFamily,
    this.titleFontSize = 14,
    this.titleTextColor,
    this.titleTextStyle,

    this.value,
    this.valueFontFamily,
    this.valueFontSize = 24,
    this.valueTextColor,
    this.valueTextStyle,

    this.hint,
    this.hintFontFamily,
    this.hintFontSize = 12,
    this.hintTextColor,
    this.hintTextStyle,

    this.border,
    this.borderColor,
    this.borderWidth = 3,

    this.margin = const EdgeInsets.all(16),
    this.padding = const EdgeInsets.only(left: 10),
  }) : super(key: key);

  @protected Color? get defaultTitleTextColor => AppColors.fillColorPrimary;
  @protected Color? get displayTitleTextColor => titleTextColor ?? defaultTitleTextColor;
  
  @protected String? get defaultTitleFontFamily => AppFontFamilies.regular;
  @protected String? get displayTitleFontFamily => titleFontFamily ?? defaultTitleFontFamily;

  @protected TextStyle get defaultTitleTextStyle => TextStyle(fontFamily: displayTitleFontFamily, fontSize: titleFontSize, color: displayTitleTextColor);
  @protected TextStyle get displayTitleTextStyle => titleTextStyle ?? defaultTitleTextStyle;

  @protected Color? get defaultValueTextColor => AppColors.fillColorPrimary;
  @protected Color? get displayValueTextColor => valueTextColor ?? defaultValueTextColor;
  
  @protected String? get defaultValueFontFamily => AppFontFamilies.extraBold;
  @protected String? get displayValueFontFamily => valueFontFamily ?? defaultValueFontFamily;

  @protected TextStyle get defaultValueTextStyle => TextStyle(fontFamily: displayValueFontFamily, fontSize: valueFontSize, color: displayValueTextColor);
  @protected TextStyle get displayValueTextStyle => valueTextStyle ?? defaultValueTextStyle;

  @protected Color? get defaultHintTextColor => AppColors.textDark;
  @protected Color? get displayHintTextColor => hintTextColor ?? defaultHintTextColor;
  
  @protected String? get defaultHintFontFamily => AppFontFamilies.regular;
  @protected String? get displayHintFontFamily => hintFontFamily ?? defaultHintFontFamily;

  @protected TextStyle get defaultHintTextStyle => TextStyle(fontFamily: displayHintFontFamily, fontSize: hintFontSize, color: displayHintTextColor);
  @protected TextStyle get displayHintTextStyle => hintTextStyle ?? defaultHintTextStyle;

  @protected Color get defaultBorderColor => AppColors.fillColorSecondary ?? Colors.transparent;
  @protected Color get displayBorderColor => borderColor ?? defaultBorderColor;

  @protected BoxBorder get defaultBorder => Border(left: BorderSide(color: displayBorderColor, width: borderWidth));
  @protected BoxBorder get displayBorder => border ?? defaultBorder;

  @protected Decoration get defaultDecoration => BoxDecoration(border: displayBorder);
  @protected Decoration get displayDecoration => defaultDecoration;

  @override
  Widget build(BuildContext context) {
    return Semantics(label: title, value: value, excludeSemantics: true, child:
      Padding(padding: margin, child:
        Container(decoration: displayDecoration, child:
          Padding(padding: padding, child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              (title != null) ? Row(children: [Expanded(child: Text(title ?? '', style: displayTitleTextStyle,))]) : Container(),
              (value != null) ? Row(children: [Expanded(child: Text(value ?? '', style: displayValueTextStyle))]) : Container(),
              (hint != null) ? Row(children: [Expanded(child: Text(hint ?? '', style: displayHintTextStyle))]) : Container(),
            ],),
          ),
        ),
      ),
    );
  }
}