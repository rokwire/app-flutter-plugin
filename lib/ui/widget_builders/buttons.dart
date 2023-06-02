import 'package:flutter/widgets.dart';
import 'package:rokwire_plugin/gen/styles.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class ButtonBuilder {
  static Widget standardRoundedButton({String label = '', void Function()? onTap}) {
    return RoundedButton(
      label: label,
      borderColor: AppColors.fillColorSecondary,
      backgroundColor: AppColors.surface,
      textStyle: AppTextStyles.widgetDetailRegularBold,
      onTap: onTap,
    );
  }
}