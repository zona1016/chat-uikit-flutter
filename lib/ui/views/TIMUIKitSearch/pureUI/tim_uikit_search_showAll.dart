// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';

import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';

class TIMUIKitSearchShowALl extends TIMUIKitStatelessWidget {
  final String textShow;
  final VoidCallback? onClick;
  final bool isNeedMoreBottom;

  TIMUIKitSearchShowALl(
      {Key? key,
      this.onClick,
      required this.textShow,
      this.isNeedMoreBottom = false})
      : super(key: key);

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final isDesktopScreen = TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    return InkWell(
      onTap: onClick,
      child: Container(
        decoration: BoxDecoration(
            color: AidaBaseColors.whiteWithOpacity01,
        ),
        padding: EdgeInsets.fromLTRB(0, 8, 0, (isNeedMoreBottom ? 24 : 8)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              color: AidaBaseColors.white,
            ),
            Expanded(
                child: Container(
              margin: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    // height: 24,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      textShow,
                      style: TextStyle(
                          color: AidaBaseColors.white,
                          fontSize: isDesktopScreen ? 14 : 16.0,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ],
              ),
            )),
            const Icon(
              Icons.expand_more,
              color: AidaBaseColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
