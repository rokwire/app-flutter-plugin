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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class RoundedButton extends StatefulWidget {
  final String label;
  final void Function()? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  final double contentWeight;
  final MainAxisAlignment conentAlignment;
  
  final Widget? textWidget;
  final TextStyle? textStyle;
  final Color? textColor;
  final String? fontFamily;
  final double fontSize;
  final TextAlign textAlign;

  final Widget? leftIcon;
  final EdgeInsetsGeometry? leftIconPadding;
  
  final Widget? rightIcon;
  final EdgeInsetsGeometry? rightIconPadding;

  final double iconPadding;

  final String? hint;
  final bool enabled;

  final Border? border;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? borderShadow;
  final double? maxBorderRadius;
  final double elevation;

  final Border? secondaryBorder;
  final Color? secondaryBorderColor;
  final double? secondaryBorderWidth;

  final bool? progress;
  final Color? progressColor;
  final double? progressSize;
  final double? progressStrokeWidth;

  const RoundedButton({
    Key? key,
    required this.label,
    this.onTap,
    this.backgroundColor,      //= Styles().colors.white
    this.padding                 = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.contentWeight           = 1.0,
    this.conentAlignment         = MainAxisAlignment.center,

    this.textWidget,
    this.textStyle,
    this.textColor,            //= Styles().colors.fillColorPrimary
    this.fontFamily,           //= Styles().fontFamilies.bold
    this.fontSize                = 20.0,
    this.textAlign               = TextAlign.center,

    this.leftIcon,
    this.leftIconPadding,
    this.rightIcon,
    this.rightIconPadding,
    this.iconPadding             = 8,

    this.hint,
    this.enabled                 = true,

    this.border,
    this.borderColor,          //= Styles().colors.fillColorSecondary
    this.borderWidth             =  2.0,
    this.borderShadow,
    this.elevation               = 0,
    this.maxBorderRadius         = 36.0,

    this.secondaryBorder,
    this.secondaryBorderColor,
    this.secondaryBorderWidth,
    
    this.progress,
    this.progressColor,
    this.progressSize,
    this.progressStrokeWidth,
  }) : super(key: key);

  @protected Color? get defaultBackgroundColor => Styles().colors.surface;
  @protected Color? get displayBackgroundColor => backgroundColor ?? defaultBackgroundColor;
  
  @protected Color? get defautTextColor => Styles().colors.fillColorPrimary;
  @protected Color? get displayTextColor => textColor ?? defautTextColor;
  @protected String? get defaultFontFamily => Styles().fontFamilies.bold;
  @protected String? get displayFontFamily => fontFamily ?? defaultFontFamily;
  @protected TextStyle get defaultTextStyle => TextStyle(fontFamily: displayFontFamily, fontSize: fontSize, color: displayTextColor);
  @protected TextStyle get displayTextStyle => textStyle ?? defaultTextStyle;
  @protected Widget get defaultTextWidget => Text(label, style: displayTextStyle, textAlign: textAlign,);
  @protected Widget get displayTextWidget => textWidget ?? defaultTextWidget;

  @protected Color get defaultBorderColor => Styles().colors.fillColorSecondary;
  @protected Color get displayBorderColor => borderColor ?? defaultBorderColor;
  @protected Border get defaultBorder => Border.all(color: displayBorderColor, width: borderWidth);
  @protected Border get displayBorder => border ?? defaultBorder;
  @protected double get displaySecondaryBorderWidth => secondaryBorderWidth ?? borderWidth;
  @protected Border? get defaultSecondaryBorder => (secondaryBorderColor != null) ? Border.all(color: secondaryBorderColor!, width: displaySecondaryBorderWidth) : null;
  @protected Border? get displaySecondaryBorder => secondaryBorder ?? defaultSecondaryBorder;

  @protected Widget get displayLeftIcon => leftIcon ?? Container();
  @protected EdgeInsetsGeometry get defaultLeftIconPadding => EdgeInsets.all(iconPadding);
  @protected EdgeInsetsGeometry get displayLeftIconPadding => leftIconPadding ?? defaultLeftIconPadding;
  
  @protected Widget get displayRightIcon => rightIcon ?? Container();
  @protected EdgeInsetsGeometry get defaultRightIconPadding => EdgeInsets.all(iconPadding);
  @protected EdgeInsetsGeometry get displayRightIconPadding => rightIconPadding ?? defaultRightIconPadding;

  @protected Color? get displayProgressColor => progressColor ?? displayBorderColor;
  @protected double get displayProgressStrokeWidth => progressStrokeWidth ?? borderWidth;

  @override
  _RoundedButtonState createState() => _RoundedButtonState();
}

class _RoundedButtonState extends State<RoundedButton> {
  final GlobalKey _contentKey = GlobalKey();
  Size? _contentSize;

  double get progressSize => widget.progressSize ?? ((_contentSize?.height ?? 0) / 2);
  bool get hasLeftIcon => (widget.leftIcon != null) || (widget.leftIconPadding != null);
  bool get hasRightIcon => (widget.rightIcon != null) || (widget.rightIconPadding != null);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evalContentSize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return (widget.progress == true)
      ? Stack(alignment: Alignment.center, children: [ _outerContent, _progressContent, ],)
      : _outerContent;
  }

  Widget get _outerContent {
    //TODO: Fix ripple effect from InkWell (behind button content)
    return Material(color: Colors.transparent, borderRadius: borderRadius, elevation: widget.elevation,
      child: Semantics(label: widget.label, hint: widget.hint, button: true,
        enabled: widget.enabled, child: _wrapperContent,),
    );
  }

  Widget get _wrapperContent {
    if (1.0 <= widget.contentWeight) {
      return Row(children: [
        Expanded(child: _borderContent)
      ]);
    }
    else if (widget.contentWeight <= 0.0) {
      // Not safe for overflow
      return Row(mainAxisSize: MainAxisSize.min, children: [
        _borderContent
      ]);
    }
    else {
      if (widget.conentAlignment == MainAxisAlignment.start) {
        return Row(children: [
          Expanded(flex: (100 * widget.contentWeight).toInt(), child: _borderContent),
          Expanded(flex: (100 * (1 - widget.contentWeight)).toInt(), child: Container()),
        ]);
      }
      else if (widget.conentAlignment == MainAxisAlignment.end) {
        return Row(children: [
          Expanded(flex: (100 * (1 - widget.contentWeight)).toInt(), child: Container()),
          Expanded(flex: (100 * widget.contentWeight).toInt(), child: _borderContent),
        ]);
      }
      else {
        return Row(children: [
          Expanded(flex: (100 * (1 - widget.contentWeight) ~/ 2), child: Container()),
          Expanded(flex: (100 * widget.contentWeight).toInt(), child: _borderContent),
          Expanded(flex: (100 * (1 - widget.contentWeight) ~/ 2), child: Container()),
        ]);
      }
    }
  }

  Widget get _borderContent {
    Border? secondaryBorder = widget.displaySecondaryBorder;
    // BorderRadiusGeometry? borderRadius = 
    return InkWell(
      onTap: widget.onTap,
      borderRadius: borderRadius,
      child: Ink(key: _contentKey, decoration: BoxDecoration(color: widget.displayBackgroundColor, border: widget.displayBorder, borderRadius: borderRadius, boxShadow: widget.borderShadow), child: (secondaryBorder != null)
        ? Ink(decoration: BoxDecoration(color: widget.displayBackgroundColor, border: secondaryBorder, borderRadius: borderRadius), child: _innerContent)
        : _innerContent
      ),
    );
  }

  BorderRadius? get borderRadius => (_contentSize != null) ? BorderRadius.circular((widget.maxBorderRadius != null) ? min(_contentSize!.height / 2, widget.maxBorderRadius!) : (_contentSize!.height / 2)) : null;

  Widget get _innerContent {
    if ((widget.rightIcon != null) || (widget.leftIcon != null)) {
      List<Widget> rowContent = <Widget>[];
      
      if (hasLeftIcon) {
        rowContent.add(Padding(padding: widget.displayLeftIconPadding, child: widget.displayLeftIcon,));
      }
      else if (hasRightIcon && (widget.textAlign == TextAlign.center)) {
        // add space keeper at left to keep text content centered
        rowContent.add(Padding(padding: widget.displayRightIconPadding, child: Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child: widget.displayRightIcon)));
      }

      rowContent.add((0.0 < widget.contentWeight) ?
        Expanded(child:
          Padding(padding: widget.padding, child:
            widget.displayTextWidget
          )
        ) :
        Padding(padding: widget.padding, child:
          widget.displayTextWidget
        )
      );

      if (hasRightIcon) {
        rowContent.add(Padding(padding: widget.displayRightIconPadding, child: widget.displayRightIcon,));
      }
      else if (hasLeftIcon && (widget.textAlign == TextAlign.center)) {
        // add space keeper at right to keep text content centered
        rowContent.add(Padding(padding: widget.displayLeftIconPadding, child: Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child: widget.displayLeftIcon)));
      }

      return Semantics(excludeSemantics: true, child:
        Row(mainAxisAlignment: MainAxisAlignment.center, children: rowContent)
      );
    }
    else {
      return Semantics(excludeSemantics: true, child:
        Padding(padding: widget.padding, child:
          widget.displayTextWidget
        )
      );
    }
  }

  Widget get _progressContent {
    return (_contentSize != null) ? SizedBox(width: _contentSize!.width, height: _contentSize!.height,
      child: Align(alignment: Alignment.center,
        child: SizedBox(height: progressSize, width: progressSize,
            child: CircularProgressIndicator(strokeWidth: widget.displayProgressStrokeWidth, valueColor: AlwaysStoppedAnimation<Color?>(widget.displayProgressColor), )
        ),
      ),
    ): Container();
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

