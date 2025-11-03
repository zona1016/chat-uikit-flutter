import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';

class DialogUtils {
  static void showBaseDialog(
      {bool barrierDismissible = true,
      required String title,
      String? desc,
      final void Function()? onConfirmPressed,
      final void Function()? onCancelPressed,
      Widget? child,
      String? confirmText,
      String? cancelText}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    showDialog<void>(
      context: Get.context!,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          shadowColor: Colors.transparent,
          // backgroundColor: AidaBaseColors.whiteWithOpacity01,
          // surfaceTintColor: AidaBaseColors.whiteWithOpacity01,
          contentPadding: EdgeInsets.zero,
          content: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: AidaBaseColors.inputFillColor,
            ),
            width: Get.width * 0.6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 25,
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                ),
                if (desc != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      desc,
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (child != null) child,
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showComingSoonDialog() {
    showBaseDialog(
      title: tr("general.coming_soon"),
      confirmText: tr("button.confirm"),
      onConfirmPressed: () {
        Get.back();
      },
    );
  }
}
