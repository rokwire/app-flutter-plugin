import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class RibbonButton extends StatefulWidget {
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

  final bool? progress;
  final Color? progressColor;
  final double? progressSize;
  final double? progressStrokeWidth;
  final EdgeInsetsGeometry progressPadding;
  final AlignmentGeometry progressAlignment;
  final bool progressHidesIcon;

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

    this.progress,
    this.progressColor,
    this.progressSize,
    this.progressStrokeWidth,
    this.progressPadding            = const EdgeInsets.symmetric(horizontal: 12),
    this.progressAlignment          = Alignment.centerRight,
    this.progressHidesIcon          = true,

    this.hint,
    this.semanticsValue,
  }) : super(key: key);

  @override
  _RibbonButtonState createState() => _RibbonButtonState();

  @protected
  void onTapWidget(BuildContext context) {
    if (onTap != null) {
      onTap!();
    }
  }
}

class _RibbonButtonState extends State<RibbonButton> {

  final GlobalKey _contentKey = GlobalKey();
  Size? _contentSize;

  Color? get _backgroundColor => widget.backgroundColor ?? Styles().colors?.white;
  Color? get _textColor => widget.textColor ?? Styles().colors?.fillColorPrimary;
  String? get _fontFamily => widget.fontFamily ?? Styles().fontFamilies?.bold;
  TextStyle get ensuredTextStyle => widget.textStyle ?? TextStyle(fontFamily: _fontFamily, fontSize: widget.fontSize, color: _textColor);
  Widget get _textWidget => widget.textWidget ?? Text(widget.label ?? '', style: ensuredTextStyle, textAlign: widget.textAlign,);

  Widget? get _leftIconImage => (widget.leftIconAsset != null) ? Image.asset(widget.leftIconAsset!, excludeFromSemantics: true) : null;
  Widget? get _rightIconImage => (widget.rightIconAsset != null) ? Image.asset(widget.rightIconAsset!, excludeFromSemantics: true) : null;

  Color? get _progressColor => widget.progressColor ?? Styles().colors?.fillColorSecondary;
  double get _progressSize => widget.progressSize ?? ((_contentSize?.height ?? 0) / 2.5);
  double get _progressStrokeWidth => widget.progressStrokeWidth ?? 2.0;

  bool get _progressHidesLeftIcon => (widget.progress == true) && (widget.progressHidesIcon == true) && (widget.progressAlignment == Alignment.centerLeft);
  bool get _progressHidesRightIcon => (widget.progress == true) && (widget.progressHidesIcon == true) && (widget.progressAlignment == Alignment.centerRight);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _evalContentSize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return (widget.progress == true)
      ? Stack(children: [ _contentWidget, _progressWidget, ],)
      : _contentWidget;
  }

  Widget get _contentWidget {
    Widget? leftIconWidget = !_progressHidesLeftIcon ? (widget.leftIcon ?? _leftIconImage) : null;
    Widget? rightIconWidget = !_progressHidesRightIcon ? (widget.rightIcon ?? _rightIconImage) : null;
    return Semantics(label: widget.label, hint: widget.hint, value : widget.semanticsValue, button: true, excludeSemantics: true, child:
      GestureDetector(onTap: () => widget.onTapWidget(context), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(child:
            Container(key: _contentKey, decoration: BoxDecoration(color: _backgroundColor, border: widget.border, borderRadius: widget.borderRadius, boxShadow: widget.borderShadow), child:
              Padding(padding: widget.padding, child:
                Row(children: <Widget>[
                  (leftIconWidget != null) ? Padding(padding: widget.leftIconPadding, child: leftIconWidget) : Container(),
                  Expanded(child:
                    _textWidget
                  ),
                  (rightIconWidget != null) ? Padding(padding: widget.rightIconPadding, child: rightIconWidget) : Container(),
                ],),
              ),
            )
          ),
        ],),
      ),
    );
  }

  Widget get _progressWidget {
    return (_contentSize != null) ? SizedBox(width: _contentSize!.width, height: _contentSize!.height, child:
      Padding(padding: widget.progressPadding, child:
        Align(alignment: widget.progressAlignment, child:
          SizedBox(height: _progressSize, width: _progressSize, child:
            CircularProgressIndicator(strokeWidth: _progressStrokeWidth, valueColor: AlwaysStoppedAnimation<Color?>(_progressColor), )
          ),
        ),
      ),
    ) : Container();
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
