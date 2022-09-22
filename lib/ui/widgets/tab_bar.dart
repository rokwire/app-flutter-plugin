import 'dart:math';

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/flex_ui.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class TabBar extends StatefulWidget {

  final TabController? tabController;

  const TabBar({Key? key, this.tabController}) : super(key: key);

  @override
  _TabBarState createState() => _TabBarState();

  @protected
  Color? get backgroundColor {
    switch(Config().configEnvironment) {
      case ConfigEnvironment.dev:        return Colors.yellowAccent;
      case ConfigEnvironment.test:       return Colors.lightGreenAccent;
      case ConfigEnvironment.production: return Styles().colors?.surface ?? Colors.white;
      default:                           return Colors.white;
    }
  }

  @protected
  BoxBorder? get border => Border(top: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1, style: BorderStyle.solid));

  @protected
  Decoration? get decoration => BoxDecoration(color: backgroundColor, border: border);

  @protected
  Widget? buildTab(BuildContext context, String code, int index) => null;

  @protected
  String get flexUiSection => 'tabbar';
}

class _TabBarState extends State<TabBar> implements NotificationsListener {

  List<dynamic>? _contentListCodes;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, FlexUI.notifyChanged);
    widget.tabController?.addListener(onTabControllerChanged);
    _contentListCodes = getContentListCodes();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
    widget.tabController?.removeListener(onTabControllerChanged);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      updateContentListCodes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(decoration: widget.decoration, child:
        SafeArea(child:
          Row(children: 
            buildTabs(),
          ),
        ),
      ),
    ],);
  }

  @protected
  List<Widget> buildTabs() {
    List<Widget> tabs = [];
    int tabsCount = (_contentListCodes != null) ? _contentListCodes!.length : 0;
    for (int tabIndex = 0; tabIndex < tabsCount; tabIndex++) {
      Widget? tab = widget.buildTab(context, _contentListCodes![tabIndex], tabIndex);
      if (tab != null) {
        tabs.add(Expanded(
          child: tab,
        ));
      }
    }
      
    return tabs;
  }

  @protected
  void onTabControllerChanged(){
    setState(() {});
  }

  @protected
  List<String>? getContentListCodes() {
    try {
      dynamic tabsList = FlexUI()[widget.flexUiSection];
      return (tabsList is List) ? tabsList.cast<String>() : null;
    }
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  @protected
  void updateContentListCodes() {
    List<String>? contentListCodes = getContentListCodes();
    if ((contentListCodes != null) && !const DeepCollectionEquality().equals(_contentListCodes, contentListCodes)) {
      if (mounted) {
        setState(() {
          _contentListCodes = contentListCodes;
        });
      }
    }
  }
}

class TabWidget extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? iconAsset;
  final String? selectedIconAsset;
  final bool selected;
  final void Function(TabWidget tabWidget) onTap;

  const TabWidget({
    Key? key,
    this.label,
    this.iconAsset,
    this.selectedIconAsset,
    this.hint,
    this.selected = false,
    required this.onTap
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () => onTap(this), behavior: HitTestBehavior.translucent, child:
      Stack(children: <Widget>[
        buildTab(context),
        selected ? buildSelectedIndicator(context) : Container(),
        ],
      ),
    );
  }

  // Tab

  @protected
  Widget buildTab(BuildContext context) => Center(child:
    Semantics(label: label, hint: hint, excludeSemantics: true, child:
      Padding(padding: tabPadding, child:
        Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Padding(padding: tabIconPadding, child:
            getTabIcon(context)
          ),
          Padding(padding: tabTextPadding, child:
            getTabText(context)
          ),
        ],),
      ),
    ),
  );

  @protected
  EdgeInsetsGeometry get tabPadding => const EdgeInsets.only(top: 8, bottom: 2);

  @protected
  EdgeInsetsGeometry get tabIconPadding => const EdgeInsets.only(bottom: 4);

  @protected
  EdgeInsetsGeometry get tabTextPadding => const EdgeInsets.all(0);

  @protected
  TextAlign get tabTextAlign => TextAlign.center;

  @protected
  TextStyle get tabTextStyle => TextStyle(fontFamily: Styles().fontFamilies!.bold, color: selected ? Styles().colors!.fillColorSecondary : Styles().colors!.mediumGray, fontSize: 12);

  @protected
  double getTextScaleFactor(BuildContext context) => min(MediaQuery.of(context).textScaleFactor, 2);

  @protected
  TextOverflow get textOverflow => TextOverflow.ellipsis;

  @protected
  Widget getTabText(BuildContext context) => Row(children: [
    Expanded(child:
      Text(label ?? '', textScaleFactor: getTextScaleFactor(context), textAlign: tabTextAlign, style: tabTextStyle, overflow: textOverflow,),
    )
  ]);

  @protected
  Widget getTabIcon(BuildContext context)  {
    String? asset = selected ? (selectedIconAsset ?? iconAsset) : iconAsset;
    Widget defaultIcon = SizedBox(width: tabIconSize.width, height: tabIconSize.height);
    return (asset != null) ? Styles().uiImages?.fromString(asset, width: tabIconSize.width, height: tabIconSize.height) ?? defaultIcon : defaultIcon;
  }

  @protected
  Size get tabIconSize => const Size(20, 20);

  // Selected Indicator

  @protected
  Widget buildSelectedIndicator(BuildContext context) => Positioned.fill(child:
    Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
      Container(height: selectedIndicatorHeight, color: selectedIndicatorColor)
    ],),
  );

  @protected
  double get selectedIndicatorHeight => 4;

  @protected
  Color? get selectedIndicatorColor => Styles().colors?.fillColorSecondary;

}

class TabCloseWidget extends StatelessWidget {
  final String? label;
  final String? hint;
  final String iconAsset;
  final void Function(TabCloseWidget tabWidget) onTap;

  const TabCloseWidget({
    Key? key,
    this.label,
    this.hint,
    required this.iconAsset,
    required this.onTap
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(label: label, hint: hint, button: true, child:
      GestureDetector(onTap: () => onTap(this), behavior: HitTestBehavior.translucent, child:
        Center(child:
          Styles().uiImages?.fromString(iconAsset, excludeFromSemantics: true,),
        ),
      )
    );
  }
}