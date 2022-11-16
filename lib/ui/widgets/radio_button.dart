// Copyright 2022 Board of Trustees of the University of Illinois.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';

class RadioButton extends StatefulWidget {
  final String label;
  final void Function()? onTap;
  final Color? activeColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  
  final Widget? textWidget;
  final TextStyle? textStyle;
  final Color? textColor;
  final String? fontFamily;
  final double fontSize;
  final TextAlign textAlign;

  final bool enabled;

  final Border? border;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? borderShadow;
  final double? maxBorderRadius;

  RadioButton(
    this.label,
    this.onTap,
    this.activeColor,
    this.backgroundColor,
    this.padding,

    this.textWidget,
    this.textStyle,
    this.textColor,
    this.fontFamily,
    this.fontSize,
    this.textAlign,

    this.enabled,

    this.border,
    this.borderColor,
    this.borderWidth,
    this.borderShadow,
    this.maxBorderRadius,
  );

  @override
  _RadioButtonState createState() => _RadioButtonState();
}

class _RadioButtonState extends State<RadioButton> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}