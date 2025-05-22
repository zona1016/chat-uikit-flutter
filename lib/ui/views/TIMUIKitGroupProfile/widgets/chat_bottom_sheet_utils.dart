
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';

class ChatBottomSheetUtils {
  static Future<T?> showBaseBottomSheet<T>(
      {required BuildContext context,
        bool isDismissible = true,
        double? maxModalHeightRatio,
        EdgeInsetsGeometry? padding,
        bool isDynamicHeight = false,
        String? title,
        String? cancelTitle,
        bool showCancel = true,
        Color? backgroundColor,
        double? height,
        Widget? child}) {
    return showModalBottomSheet(
        useSafeArea: true,
        isScrollControlled: true,
        context: context,
        backgroundColor: backgroundColor ?? Colors.transparent,
        builder: (BuildContext context) {
          return SingleChildScrollView(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: isDynamicHeight ? null : height ?? double.infinity,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * (maxModalHeightRatio ?? 0.9)),
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Padding(
                  padding: padding ?? const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: SizedBox(
                            height: 44,
                            child: Stack(
                              children: [
                                if (showCancel && cancelTitle != null)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 6),
                                        child: Text(
                                          cancelTitle,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: AidaBaseColors.weakTextColor),
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                Center(
                                    child: Text(
                                      title,
                                      style: const TextStyle(fontSize: 17, color: AidaBaseColors.primaryColor),
                                    ))
                              ],
                            ),
                          ),
                        ),
                      if (child != null) child
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}
