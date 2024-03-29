import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widget_builders/loading.dart';
import 'package:rokwire_plugin/ui/widgets/scroll_pager.dart';

class ScrollPagerBuilder {
  static Widget? buildScrollPagerFooter(ScrollPagerController controller) {
    if (controller.loading) {
      return LoadingBuilder.loading();
    } else if (controller.error) {
      return buildScrollPagerError(controller);
    }
    return null;
  }

  static Widget buildScrollPagerError(ScrollPagerController controller) {
    return Semantics(
        label: Localization().getStringEx('widget.scroll_pager.error.title', 'An error occurred'),
        hint: Localization().getStringEx('widget.scroll_pager.error.hint', 'Tap to try again'),
        button: true,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.loadPage(retry: true),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Styles().images.getImage('retry-gray', defaultSpec: FontAwesomeImageSpec(type: 'fa.icon', source: '0xf2f9', weight: 'solid', size: 18.0, color: Styles().colors.mediumGray)) ?? Container(),
                  const SizedBox(width: 8.0),
                  Text(Localization().getStringEx('widget.scroll_pager.error.title', 'Something went wrong'),
                      style: Styles().textStyles.getTextStyle('widget.message.light.regular')),
                ],
              ),
            ),
          ),
        ));
  }
}