import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitGroupProfile/widgets/group_disappearing_message.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitProfile/widget/tim_uikit_operation_item.dart';

import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_im_base/tencent_im_base.dart';

class GroupDisappearingMessageConversation extends TIMUIKitStatelessWidget {
  GroupDisappearingMessageConversation({Key? key}) : super(key: key);

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final model = Provider.of<TUIGroupProfileModel>(context);
    return InkWell(
      onTap: () {
        final isDesktopScreen =
            TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
        if (!isDesktopScreen) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const GroupDisappearingMessage(
                        selectedTime: '',
                      )));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          color: AidaBaseColors.whiteWithOpacity01,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              TIM_t("限时消息"),
              style: const TextStyle(fontSize: 16, color: AidaBaseColors.white),
            ),
            const Spacer(),
            Text(
              TIM_t("关闭"),
              style: const TextStyle(
                  fontSize: 16, color: AidaBaseColors.weakTextColor),
            ),
            const SizedBox(
              width: 8,
            ),
            const Icon(
              Icons.chevron_right,
              color: AidaBaseColors.weakTextColor,
            )
          ],
        ),
      ),
    );
  }
}
