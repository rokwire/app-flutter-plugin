import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class RibbonButton extends StatelessWidget {
  final String? label;
  final void Function()? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  final Widget? textWidget;
  final TextStyle? textStyle;
  final Color? textColor;
  final String? fontFamily;
  final double fontSize;
  final TextAlign textAlign;

  final Widget? leftIcon;
  final String? leftIconAsset;
  final EdgeInsetsGeometry leftIconPadding;
  
  final Widget? rightIcon;
  final String? rightIconAsset;
  final EdgeInsetsGeometry rightIconPadding;

  final BoxBorder? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? borderShadow;

  final String? hint;
  final String? semanticsValue;

  const RibbonButton({Key? key,
    this.label,
    this.onTap,
    this.backgroundColor,      //= Styles().colors.white
    this.padding                 = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

    this.textWidget,
    this.textStyle,
    this.textColor,            //= Styles().colors.fillColorPrimary
    this.fontFamily,           //= Styles().fontFamilies.bold
    this.fontSize                = 16.0,
    this.textAlign               = TextAlign.left,

    this.leftIcon,
    this.leftIconAsset,
    this.leftIconPadding         = const EdgeInsets.only(right: 8),
    
    this.rightIcon,
    this.rightIconAsset,
    this.rightIconPadding        = const EdgeInsets.only(left: 8),

    this.border,
    this.borderShadow,
    this.borderRadius,

    this.hint,
    this.semanticsValue,
  }) : super(key: key);

  Color? get _backgroundColor => backgroundColor ?? Styles().colors?.white;
  
  Color? get _textColor => textColor ?? Styles().colors?.fillColorPrimary;
  String? get _fontFamily => fontFamily ?? Styles().fontFamilies?.bold;
  TextStyle get _textStyle => textStyle ?? TextStyle(fontFamily: _fontFamily, fontSize: fontSize, color: _textColor);
  Widget get _textWidget => textWidget ?? Text(label ?? '', style: _textStyle, textAlign: textAlign,);

  @protected
  Widget? get leftIconImage => (leftIconAsset != null) ? Image.asset(leftIconAsset!, excludeFromSemantics: true) : null;
  
  @protected
  Widget? get rightIconImage => (rightIconAsset != null) ? Image.asset(rightIconAsset!, excludeFromSemantics: true) : null;

  @override
  Widget build(BuildContext context) {
    Widget? leftIconWidget = leftIcon ?? leftIconImage;
    Widget? rightIconWidget = rightIcon ?? rightIconImage;
    return Semantics(label: label, hint: hint, value : semanticsValue, button: true, excludeSemantics: true, child:
      GestureDetector(onTap: () => onTapWidget(context), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(child:
            Container(decoration: BoxDecoration(color: _backgroundColor, border: border, borderRadius: borderRadius, boxShadow: borderShadow), child:
              Padding(padding: padding, child:
                Row(children: <Widget>[
                  (leftIconWidget != null) ? Padding(padding: leftIconPadding, child: leftIconWidget) : Container(),
                  Expanded(child:
                    _textWidget
                  ),
                  (rightIconWidget != null) ? Padding(padding: rightIconPadding, child: rightIconWidget) : Container(),
                ],),
              ),
            )
          ),
        ],),
      ),
    );
  }

  @protected
  void onTapWidget(BuildContext context) {
    if (onTap != null) {
      onTap!();
    }
  }
}

class ToggleRibbonButton extends RibbonButton {

  final bool toggled;
  final Map<bool, Widget>? leftIcons;
  final Map<bool, String>? leftIconAssets;

  final Map<bool, Widget>? rightIcons;
  final Map<bool, String>? rightIconAssets;

  final Map<bool, String>? semanticsValues;

  const ToggleRibbonButton({
    Key? key,
    String? label,
    void Function()? onTap,
    Color? backgroundColor,
    EdgeInsetsGeometry padding          = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

    Widget? textWidget,
    TextStyle? textStyle,
    Color? textColor,
    String? fontFamily,
    double fontSize                     = 16.0,
    TextAlign textAlign                 = TextAlign.left,

    Widget? leftIcon,
    String? leftIconAsset,
    EdgeInsetsGeometry leftIconPadding  = const EdgeInsets.only(right: 8),
    
    Widget? rightIcon,
    String? rightIconAsset,
    EdgeInsetsGeometry rightIconPadding = const EdgeInsets.only(left: 8),

    BoxBorder? border,
    BorderRadius? borderRadius,
    List<BoxShadow>? borderShadow,

    String? hint,
    String? semanticsValue,

    this.toggled = false,
    
    this.leftIcons,
    this.leftIconAssets,
    
    this.rightIcons,
    this.rightIconAssets,

    this.semanticsValues,
  }): super(
    key: key,
    label: label,
    onTap: onTap,
    backgroundColor: backgroundColor,
    padding: padding,

    textWidget: textWidget,
    textStyle: textStyle,
    textColor: textColor,
    fontFamily: fontFamily,
    fontSize: fontSize,
    textAlign: textAlign,

    leftIcon: leftIcon,
    leftIconAsset: leftIconAsset,
    leftIconPadding: leftIconPadding,
    
    rightIcon: rightIcon,
    rightIconAsset: rightIconAsset,
    rightIconPadding: rightIconPadding,

    border: border,
    borderRadius: borderRadius,
    borderShadow: borderShadow,

    hint: hint,
    semanticsValue: semanticsValue,
  );

  Widget? get _leftIcon => (leftIcons != null) ? leftIcons![toggled] : null;
  String? get _leftIconAsset => (leftIconAssets != null) ? leftIconAssets![toggled] : null;
  Widget? get _rightIcon => (rightIcons != null) ? rightIcons![toggled] : null;
  String? get _rightIconAsset => (rightIconAssets != null) ? rightIconAssets![toggled] : null;
  String? get _semanticsValue => (semanticsValues != null) ? semanticsValues![toggled] : null;

  @override
  Widget? get leftIcon => _leftIcon ?? super.leftIcon;
  
  @override
  String? get leftIconAsset => _leftIconAsset ?? super.leftIconAsset;

  @override
  Widget? get rightIcon => _rightIcon ?? super.rightIcon;
  
  @override
  String? get rightIconAsset => _rightIconAsset ?? super.rightIconAsset;

  @override
  String? get semanticsValue => _semanticsValue ?? super.semanticsValue;

  @protected
  String? get semanticStateChangeAnnouncementMessage {
    if (StringUtils.isNotEmpty(label) && StringUtils.isNotEmpty(semanticsValue)) {
      return "$label, $semanticsValue";
    }
    else if (StringUtils.isNotEmpty(semanticsValue)) {
      return semanticsValue;
    }
    else if (StringUtils.isNotEmpty(label)) {
      return label;
    }
    else {
      return null;
    }
  }

  @override
  void onTapWidget(BuildContext context) {
    super.onTapWidget(context);

    String? announcementMessage = (onTap != null) ? semanticStateChangeAnnouncementMessage : null;
    if (announcementMessage != null) {
      context.findRenderObject()?.sendSemanticsEvent(AnnounceSemanticsEvent(announcementMessage, TextDirection.ltr));
    }
  }
}
