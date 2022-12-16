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

class RadioButton<T> extends StatefulWidget {
  final T value;
  final T? groupValue;
  final void Function(T value) onChanged;

  final EdgeInsetsGeometry outsidePadding;
  final EdgeInsetsGeometry insidePadding;
  final EdgeInsetsGeometry textPadding;
  final double size;
  
  final Widget? textWidget;
  final String? text;
  final TextStyle? textStyle;
  final Color? textColor;
  final String? fontFamily;
  final double fontSize;
  final TextAlign textAlign;

  final bool enabled;

  final ShapeBorder shape;
  final Decoration? borderDecoration;
  final Decoration? backgroundDecoration;
  final Widget? selectedWidget;
  final Widget? deselectedWidget;
  final Widget? disabledWidget;
  final Color? splashColor;
  final double splashRadius;

  final String? semanticsLabel;

  const RadioButton({
    Key? key,
    required this.value,
    this.groupValue,
    required this.onChanged,
    this.outsidePadding = const EdgeInsets.all(2),
    this.insidePadding = const EdgeInsets.all(8),
    this.textPadding = const EdgeInsets.only(top: 8),
    this.size = 48,

    this.textWidget,
    this.text,
    this.textStyle,
    this.textColor,
    this.fontFamily,
    this.fontSize = 12,
    this.textAlign = TextAlign.center,

    this.enabled = true,

    this.shape = const CircleBorder(),
    this.borderDecoration,
    this.backgroundDecoration,
    this.selectedWidget,
    this.deselectedWidget,
    this.disabledWidget,
    this.splashColor,
    this.splashRadius = 32,
    this.semanticsLabel,
  }) : super(key: key);

  @override
  _RadioButtonState<T> createState() => _RadioButtonState<T>();
}

class _RadioButtonState<T> extends State<RadioButton<T>> {
  @override
  Widget build(BuildContext context) {
    bool selected = widget.value == widget.groupValue;
    return Semantics(
      label: widget.semanticsLabel ?? widget.text,
      checked: selected,
      excludeSemantics: true,
      child: Column(key: widget.key, children: [
        InkResponse(key: widget.key,
          onTap: widget.enabled ? () => widget.onChanged(widget.value) : null,
          radius: widget.splashRadius,
          splashColor: widget.splashColor,
          child: Container(
            key: widget.key,
            width: widget.size,
            height: widget.size,
            decoration: widget.borderDecoration,
            padding: widget.outsidePadding,
            child: Container(
              key: widget.key,
              padding: widget.insidePadding,
              decoration: widget.backgroundDecoration,
              child: selected ? (widget.enabled ? widget.selectedWidget : widget.disabledWidget) : widget.deselectedWidget,
            ),
          )
        ),
        Visibility(visible: widget.textWidget != null || widget.text != null, child:
          Padding(padding: widget.textPadding, child:
            widget.textWidget ?? Text(widget.text ?? '', key: widget.key,
              style: widget.textStyle ?? TextStyle(color: widget.textColor, fontFamily: widget.fontFamily, fontSize: widget.fontSize),
              textAlign: widget.textAlign,
            )
          )
        ),
      ]),
    );
  }
}