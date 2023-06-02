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

class RoundedTab extends StatefulWidget {
  final String? title;
  final String? fontFamily;
  final double fontSize;
  final TextStyle? textStyle;
  final TextStyle? selectedTextStyle;
  final Color? textColor;
  final Color? selectedTextColor;

  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final BoxBorder? border;
  final BoxBorder? selectedBorder;
  final Color? borderColor;
  final Color? selectedBorderColor;
  final double borderWidth;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? borderShadow;

  final String? hint;
  final int tabIndex;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final void Function(RoundedTab tab)? onTap;

  const RoundedTab({ Key? key,
    this.title,
    this.textStyle,
    this.selectedTextStyle,
    this.textColor,
    this.selectedTextColor,
    this.fontFamily,
    this.fontSize = 16.0,

    this.backgroundColor,
    this.selectedBackgroundColor,
    this.border,
    this.selectedBorder,
    this.borderColor,
    this.selectedBorderColor,
    this.borderWidth = 1,
    this.borderRadius,
    this.borderShadow,

    this.hint,
    this.tabIndex = 0,
    this.selected = false,
    this.padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
    this.onTap,
  }): super(key: key);

  @protected Color? get defaultTextColor => selected ? AppColors.textLight : AppColors.fillColorPrimary;
  @protected Color? get displayTextColor => (selected ? selectedTextColor : textColor) ?? defaultTextColor;
  @protected String? get defaultFontFamily => AppFontFamilies.bold;
  @protected String? get displayFontFamily => fontFamily ?? defaultFontFamily;
  @protected TextStyle get defaultTextStyle => TextStyle(fontFamily: displayFontFamily, fontSize: fontSize, color: displayTextColor);
  @protected TextStyle get displayTextStyle => (selected ? selectedTextStyle : textStyle) ?? defaultTextStyle;

  @protected Color? get defaultBackgroundColor => selected ? AppColors.fillColorPrimary : AppColors.surfaceAccent;
  @protected Color? get displayBackgroundColor => (selected ? selectedBackgroundColor : backgroundColor) ?? defaultBackgroundColor;
  @protected Color get defaultBorderColor => const Color(0xffdadde1);
  @protected Color get displayBorderColor => (selected ? selectedBorderColor : borderColor) ?? defaultBorderColor;
  @protected BoxBorder get defaultBorder => Border.all(color: displayBorderColor, width: borderWidth);
  @protected BoxBorder get displayBorder => (selected ? selectedBorder : border) ?? defaultBorder;

  void _onPressed() {
    if (onTap != null) {
      onTap!(this);
    }
  }

  @override
  _RoundedTabState createState() => _RoundedTabState();
}

class _RoundedTabState extends State<RoundedTab> {
  final GlobalKey _contentKey = GlobalKey();
  Size? _contentSize;

  BorderRadiusGeometry? get displayBorderRadius => widget.borderRadius ?? ((_contentSize != null) ? BorderRadius.circular(_contentSize!.height/2) : null);
  Decoration? get displayDecoration => BoxDecoration(color: widget.displayBackgroundColor, border: widget.displayBorder, borderRadius: displayBorderRadius, boxShadow: widget.borderShadow);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evalContentSize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () => widget._onPressed(), child:
      Semantics(label: widget.title, hint: widget.hint, button: true, selected: widget.selected, excludeSemantics: true, child:
        Container(key: _contentKey, decoration: displayDecoration, child:
          Padding(padding: widget.padding, child:
            Text(widget.title ?? '', style: widget.displayTextStyle,),
          ),
        ),
      ),
    );
  }

  void _evalContentSize() {
    try {
      final RenderObject? renderBox = _contentKey.currentContext?.findRenderObject();
      if (renderBox is RenderBox) {
        if (mounted) {
          setState(() {
            _contentSize = renderBox.size;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
