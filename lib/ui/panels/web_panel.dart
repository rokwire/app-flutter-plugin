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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/tracking_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart' as flutter_webview;
// #docregion platform_imports
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
// #enddocregion platform_imports

class WebPanel extends StatefulWidget {
  final String? url;
  final String? title;
  final PreferredSizeWidget? headerBar;
  final Widget? tabBar;

  const WebPanel({Key? key, this.url, this.title, this.headerBar, this.tabBar}) : super(key: key);

  @override
  WebPanelState createState() => WebPanelState();

  @protected
  Future<bool> getOnline() async {
    return UrlUtils.isHostAvailable(Config().coreUrl);
  }

  @protected
  Future<bool> getTrackingEnabled() async {
    TrackingAuthorizationStatus? status = await TrackingServices.queryAuthorizationStatus();
    if (status == TrackingAuthorizationStatus.undetermined) {
      status = await TrackingServices.requestAuthorization();
    }
    return (status == TrackingAuthorizationStatus.allowed);
  }

  @protected
  Widget buildInitializing(BuildContext context) {
    return Center(child:
      CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary),),
    );
  }

  @protected
  Widget buildOfflineStatus(BuildContext context) {
    return buildStatus(context,
      title: "Web Content Not Available",
      message:"You need to be online in order to access web content. Please check your Internet connection.",
    );
  }

  @protected
  Widget buildTrackingDisabledStatus(BuildContext context) {
    return buildStatus(context,
      title: "Web Content Blocked",
      message: sprintf("You have opted to deny cookie usage for web content in this app, therefore we have blocked access to web sites. If you change your mind, change your preference <a href='%s'>here</a>. Your phone Settings may also need to have Privacy > Tracking enabled.", [appSettingsUrl]),
    );
  }

  @protected
  Widget buildStatus(BuildContext context, {String? title, String? message}) {
    List<Widget> contentList = <Widget>[];
    contentList.add(Expanded(flex: 1, child: Container()));
    
    if (title != null) {
      contentList.add(flutter_html.Html(data: title,
          onLinkTap: (url, context, element) => onTapStatusLink(url),
          style: { "body": flutter_html.Style(color: Styles().colors.fillColorPrimary,
              fontFamily: Styles().fontFamilies.bold, fontSize: flutter_html.FontSize(32),
              textAlign: TextAlign.center, padding: null /* EdgeInsets.zero, const flutter_html.HtmlPaddings() */, margin: flutter_html.Margins.zero), },),
      );
    }

    if ((title != null) && (message != null)) {
      contentList.add(Container(height: 48));
    }

    if ((message != null)) {
      contentList.add(flutter_html.Html(data: message,
        onLinkTap: (url, context, element) => onTapStatusLink(url),
        style: { "body": flutter_html.Style(color: Styles().colors.fillColorPrimary,
            fontFamily: Styles().fontFamilies.regular, fontSize: flutter_html.FontSize(20),
            textAlign: TextAlign.left, padding: null /* EdgeInsets.zero, const flutter_html.HtmlPaddings() */, margin: flutter_html.Margins.zero), },),
      );
    }

    contentList.add(Expanded(flex: 3, child: Container()));

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child:
      Column(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, children: contentList,)
    );
  }

  @protected
  String get appSettingsUrl => '${DeepLink().appUrl}/app_settings';

  @protected
  void onTapStatusLink(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if (uri != null) {
      launchUrl(uri);
    }
  }

}

class WebPanelState extends State<WebPanel> implements NotificationsListener {

  bool? _isOnline;
  bool? _isTrackingEnabled;
  bool _isPageLoading = true;
  bool _isForeground = true;
  late final flutter_webview.WebViewController _controller;


  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      AppLifecycle.notifyStateChanged,
      DeepLink.notifyUri,
    ]);

    // #docregion platform_features
    late final flutter_webview.PlatformWebViewControllerCreationParams params;
    if (flutter_webview.WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const flutter_webview.PlatformWebViewControllerCreationParams();
    }

    final flutter_webview.WebViewController controller =
      flutter_webview.WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    controller.setJavaScriptMode(flutter_webview.JavaScriptMode.unrestricted);
    controller.setBackgroundColor(const Color(0x00FFFFFF));

    controller.setNavigationDelegate(flutter_webview.NavigationDelegate(
      onProgress: onPageProgress,
      onPageStarted: onPageStarted,
      onPageFinished: onPageFinished,
      onWebResourceError: onPageWebResourceError,
      onNavigationRequest: processPageNavigationRequest,
      onHttpError: onPageHttpError,
      onUrlChange: onPageUrlChange,
      onHttpAuthRequest: onHttpAuthRequest,
    ),);

    controller.addJavaScriptChannel('Toaster',
      onMessageReceived: (flutter_webview.JavaScriptMessage message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.message)),
        );
      },
    );

    Uri? uri = (widget.url != null) ? Uri.tryParse(widget.url!) : null;
    if (uri != null) {
      controller.loadRequest(uri);
    }

    // #docregion platform_features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }
    // #enddocregion platform_features

    _controller = controller;

    widget.getOnline().then((bool isOnline) {
      setState(() {
        _isOnline = isOnline;
      });
      if (isOnline) {
        widget.getTrackingEnabled().then((bool trackingEnabled) {
          setState(() {
            _isTrackingEnabled = trackingEnabled;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    Widget contentWidget;
    if (_isOnline == false) {
      contentWidget = widget.buildOfflineStatus(context);
    }
    else if (_isTrackingEnabled == false) {
      contentWidget = widget.buildTrackingDisabledStatus(context);
    }
    else if ((_isOnline == true) && (_isTrackingEnabled == true)) {
      contentWidget = _buildWebView();
    }
    else {
      contentWidget = widget.buildInitializing(context);
    }

    return Scaffold(
      appBar: widget.headerBar ?? HeaderBar(title: widget.title),
      backgroundColor: Styles().colors.background,
      body: Column(children: <Widget>[
        Expanded(child: contentWidget),
        widget.tabBar ?? Container()
      ],),);
  }

  Widget _buildWebView() {
    return Stack(children: [
      Visibility(visible: _isForeground,
        child: flutter_webview.WebViewWidget(
          controller: _controller,
        ),
      ),
      Visibility(visible: _isPageLoading,
        child: const Center(
          child: CircularProgressIndicator(),
      )),
    ],);
  }

  @override
  void onNotification(String name, dynamic param){
    if (name == AppLifecycle.notifyStateChanged) {
      setState(() {
        _isForeground = (param == AppLifecycleState.resumed);
      });
    }
    else if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(JsonUtils.cast(param));
    }
  }

  void _onDeepLinkUri(Uri? uri) {
    if ((uri != null) && uri.matchDeepLinkUri(Uri.tryParse(widget.appSettingsUrl))) {
      RokwirePlugin.launchAppSettings();
    }
  }

  @protected
  void onPageProgress(int progress) {
    debugPrint('WebView is loading (progress : $progress%)');
  }

  @protected
  void onPageStarted(String url) {
    debugPrint('Page started loading: $url');
  }

  @protected
  void onPageFinished(String url) {
    debugPrint('Page finished loading: $url');
    if (mounted) {
      setState(() {
        _isPageLoading = false;
      });
    }
  }

  @protected
  FutureOr<flutter_webview.NavigationDecision> processPageNavigationRequest(flutter_webview.NavigationRequest navigation) async {
    String url = navigation.url;
    if (UrlUtils.launchInternal(url)) {
      return flutter_webview.NavigationDecision.navigate;
    }
    else {
      launchUrlString(url);
      return flutter_webview.NavigationDecision.prevent;
    }
  }

  @protected
  void onPageWebResourceError(flutter_webview.WebResourceError error) {
    debugPrint('Page resource error:\n\tcode: ${error.errorCode}\n\tdescription: ${error.description}\n\terrorType: ${error.errorType}\n\tisForMainFrame: ${error.isForMainFrame}\n');
  }

  @protected
  void onPageHttpError(flutter_webview.HttpResponseError error) {
    debugPrint('Error occurred on page: ${error.response?.statusCode}');
  }

  @protected
  void onPageUrlChange(flutter_webview.UrlChange change) {
    debugPrint('url change to ${change.url}');
  }

  @protected
  void onHttpAuthRequest(flutter_webview.HttpAuthRequest request) {
    //TBD: openDialog();
  }
}

