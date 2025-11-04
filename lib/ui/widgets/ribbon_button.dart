import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class RibbonButton extends StatefulWidget {
  final String? title;
  final String? description;
  final void Function()? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  final Widget? textWidget;
  final TextStyle? textStyle;
  final Color? textColor;
  final String? fontFamily;
  final double fontSize;
  final TextAlign textAlign;

  final Widget? descriptionWidget;
  final TextStyle? descriptionTextStyle;
  final Color? descriptionTextColor;
  final String? descriptionFontFamily;
  final double descriptionFontSize;
  final TextAlign descriptionTextAlign;
  final EdgeInsetsGeometry descriptionPadding;

  final Widget? leftIcon;
  final String? leftIconKey;
  final EdgeInsetsGeometry leftIconPadding;
  
  final Widget? rightIcon;
  final String? rightIconKey;
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

  final String? semanticsLabel;
  final String? semanticsHint;
  final String? semanticsValue;

  const RibbonButton({Key? key,
    this.title,
    this.description,
    this.onTap,
    this.backgroundColor,      //= Styles().colors.white
    this.padding,

    this.textWidget,
    this.textStyle,
    this.textColor,            //= Styles().colors.fillColorPrimary
    this.fontFamily,           //= Styles().fontFamilies.bold
    this.fontSize                = 16.0,
    this.textAlign               = TextAlign.left,

    this.descriptionWidget,
    this.descriptionTextStyle,
    this.descriptionTextColor,  //= Styles().colors.textSurface
    this.descriptionFontFamily, //= Styles().fontFamilies.regular
    this.descriptionFontSize    = 14.0,
    this.descriptionTextAlign   = TextAlign.left,
    this.descriptionPadding     = const EdgeInsets.only(top: 2),

    this.leftIcon,
    this.leftIconKey,
    this.leftIconPadding         = const EdgeInsets.only(right: 8),
    
    this.rightIcon,
    this.rightIconKey,
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

    this.semanticsLabel,
    this.semanticsHint,
    this.semanticsValue,
  }) : super(key: key);

  @protected Color? get defaultBackgroundColor => Styles().colors.white;
  @protected Color? get displayBackgroundColor => backgroundColor ?? defaultBackgroundColor;

  @protected EdgeInsetsGeometry get displayPadding => padding ?? (hasDescription ? complexPadding : simplePadding);
  @protected EdgeInsetsGeometry get simplePadding => const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  @protected EdgeInsetsGeometry get complexPadding => const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  @protected Color? get defaultTextColor => Styles().colors.fillColorPrimary;
  @protected Color? get displayTextColor => textColor ?? defaultTextColor;
  @protected String? get defaultFontFamily => Styles().fontFamilies.bold;
  @protected String? get displayFontFamily => fontFamily ?? defaultFontFamily;
  @protected TextStyle get displayTextStyle => textStyle ?? TextStyle(fontFamily: displayFontFamily, fontSize: fontSize, color: displayTextColor);
  @protected Widget get displayTextWidget => textWidget ?? Text(title ?? '', style: displayTextStyle, textAlign: textAlign,);

  @protected bool get hasDescription => StringUtils.isNotEmpty(description) || (descriptionWidget != null);
  @protected Color? get defaultDescriptionTextColor => Styles().colors.textSurface;
  @protected Color? get displayDescriptionTextColor => descriptionTextColor ?? defaultDescriptionTextColor;
  @protected String? get defaultDescriptionFontFamily => Styles().fontFamilies.regular;
  @protected String? get displayDescriptionFontFamily => descriptionFontFamily ?? defaultDescriptionFontFamily;
  @protected TextStyle get displayDescriptionTextStyle => descriptionTextStyle ?? TextStyle(fontFamily: displayDescriptionFontFamily, fontSize: fontSize, color: displayDescriptionTextColor);
  @protected Widget get displayDescriptionWidget => descriptionWidget ?? Text(description ?? '', style: displayDescriptionTextStyle, textAlign: descriptionTextAlign,);

  @protected Widget? get leftIconImage => (leftIconKey != null) ? Styles().images.getImage(leftIconKey, excludeFromSemantics: true) : null;
  @protected Widget? get rightIconImage => (rightIconKey != null) ? Styles().images.getImage(rightIconKey, excludeFromSemantics: true) : null;

  @protected Color? get defaultProgressColor => Styles().colors.fillColorSecondary;
  @protected Color? get displayProgressColor => progressColor ?? defaultProgressColor;
  @protected double get defaultStrokeWidth => 2.0;
  @protected double get displayProgressStrokeWidth => progressStrokeWidth ?? defaultStrokeWidth;

  @protected bool get progressHidesLeftIcon => (progress == true) && (progressHidesIcon == true) && (progressAlignment == Alignment.centerLeft);
  @protected bool get progressHidesRightIcon => (progress == true) && (progressHidesIcon == true) && (progressAlignment == Alignment.centerRight);

  @protected bool? get semanticsToggled => null;
  @protected bool? get semanticsEnabled => null;

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

  double get _progressSize => widget.progressSize ?? ((_contentSize?.height ?? 0) / 2.5);

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
      ? Stack(children: [ _contentWidget, _progressWidget, ],)
      : _contentWidget;
  }

  Widget get _contentWidget {
    Widget? leftIconWidget = !widget.progressHidesLeftIcon ? (widget.leftIcon ?? widget.leftIconImage) : null;
    Widget? rightIconWidget = !widget.progressHidesRightIcon ? (widget.rightIcon ?? widget.rightIconImage) : null;
    Widget textContentWidget = widget.hasDescription ?
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        widget.displayTextWidget,
        widget.displayDescriptionWidget,
      ],) : widget.displayTextWidget;
    return Semantics(label: widget.semanticsLabel ?? widget.title, hint: widget.semanticsHint, value : widget.semanticsValue, button: true, toggled: widget.semanticsToggled, enabled: widget.semanticsEnabled, excludeSemantics: true, child:
      GestureDetector(onTap: () => widget.onTapWidget(context), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(child:
            Container(key: _contentKey, decoration: BoxDecoration(color: widget.displayBackgroundColor, border: widget.border, borderRadius: widget.borderRadius, boxShadow: widget.borderShadow), child:
              Padding(padding: widget.displayPadding, child:
                Row(children: <Widget>[
                  (leftIconWidget != null) ? Padding(padding: widget.leftIconPadding, child: leftIconWidget) : Container(),
                  Expanded(child:
                    textContentWidget
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
            CircularProgressIndicator(strokeWidth: widget.displayProgressStrokeWidth, valueColor: AlwaysStoppedAnimation<Color?>(widget.displayProgressColor), )
          ),
        ),
      ),
    ) : Container();
  }

  void _evalContentSize() {
    try {
      final RenderObject? renderBox = _contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize) {
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
  final bool? enabled;

  final Map<bool, Widget>? leftIcons;
  final Map<bool, String>? leftIconKeys;

  final Map<bool, Widget>? rightIcons;
  final Map<bool, String>? rightIconKeys;

  final Map<bool, String>? semanticsValues;

  const ToggleRibbonButton({super.key,
    super.title,
    super.description,
    super.onTap,
    super.backgroundColor,
    super.padding,

    super.textWidget,
    super.textStyle,
    super.textColor,
    super.fontFamily,
    super.fontSize  = 16.0,
    super.textAlign = TextAlign.left,

    super.descriptionWidget,
    super.descriptionTextStyle,
    super.descriptionTextColor,
    super.descriptionFontFamily,
    super.descriptionFontSize   = 14,
    super.descriptionTextAlign  = TextAlign.left,
    super.descriptionPadding    = const EdgeInsets.only(top: 2),

    super.leftIcon,
    super.leftIconKey,
    super.leftIconPadding  = const EdgeInsets.only(right: 8),
    
    super.rightIcon,
    super.rightIconKey,
    super.rightIconPadding = const EdgeInsets.only(left: 8),

    super.border,
    super.borderRadius,
    super.borderShadow,

    super.progress,
    super.progressColor,
    super.progressSize,
    super.progressStrokeWidth,
    super.progressPadding = const EdgeInsets.symmetric(horizontal: 12),
    super.progressAlignment = Alignment.centerRight,
    super.progressHidesIcon = true,

    super.semanticsLabel,
    super.semanticsHint,
    super.semanticsValue,

    this.toggled = false,
    this.enabled,

    this.leftIcons,
    this.leftIconKeys,

    this.rightIcons,
    this.rightIconKeys,

    this.semanticsValues,
  });

  bool get _enabled => (enabled != false);
  bool get _toggled => _enabled && toggled;

  Widget? get _leftIcon => (leftIcons != null) ? leftIcons![_toggled] : null;
  String? get _leftIconKey => (leftIconKeys != null) ? leftIconKeys![_toggled] : null;
  Widget? get _rightIcon => (rightIcons != null) ? rightIcons![_toggled] : null;
  String? get _rightIconKey => (rightIconKeys != null) ? rightIconKeys![_toggled] : null;

  String? get _semanticsValue => (semanticsValues != null) ? semanticsValues![_toggled] : null;
  String? get _changedSemanticsValue => (semanticsValues != null) ? semanticsValues![!toggled] : null;

  @override Widget? get leftIcon => super.leftIcon ?? (_enabled ? _leftIcon : (disabledLeftIcon ?? _leftIcon));
  @override String? get leftIconKey => super.leftIconKey ?? _leftIconKey;
  @protected Widget? get disabledLeftIcon => null;

  @override Widget? get rightIcon => super.rightIcon ?? (_enabled ? _rightIcon : (disabledRightIcon ?? _rightIcon));
  @override String? get rightIconKey => super.rightIconKey ?? _rightIconKey;
  @protected Widget? get disabledRightIcon => null;

  @override String? get semanticsValue => super.semanticsValue ?? _semanticsValue;
  @override bool? get semanticsToggled => _toggled;
  @override bool? get semanticsEnabled => enabled;

  @protected
  String? get semanticStateChangeAnnouncementMessage {
    if (StringUtils.isNotEmpty(title) && StringUtils.isNotEmpty(_changedSemanticsValue)) {
      return "$_changedSemanticsValue, $title";
    }
    else if (StringUtils.isNotEmpty(_changedSemanticsValue)) {
      return _changedSemanticsValue;
    }
    else if (StringUtils.isNotEmpty(title)) {
      return title;
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
