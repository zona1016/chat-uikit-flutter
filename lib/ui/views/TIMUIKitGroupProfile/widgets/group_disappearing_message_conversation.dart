import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitGroupProfile/widgets/group_disappearing_message.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitProfile/disappearing_message.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitProfile/widget/tim_uikit_operation_item.dart';

import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_im_base/tencent_im_base.dart';

class GroupDisappearingMessageConversation extends TIMUIKitStatelessWidget {
  GroupDisappearingMessageConversation({Key? key}) : super(key: key);

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final model = Provider.of<TUIGroupProfileModel>(context);
    DisappearingMessageConfig config;
    if (model.groupInfo?.customInfo != null &&
        model.groupInfo?.customInfo!['disappearing'] != null &&
        model.groupInfo!.customInfo!['disappearing']!.isNotEmpty) {
      Map<String, dynamic> tempMap =
          jsonDecode(model.groupInfo!.customInfo!['disappearing']!);
      Map<String, String> customData =
          tempMap.map((key, value) => MapEntry(key, value.toString()));
      config = DisappearingMessageConfig.fromJson(customData);
    } else {
      config = DisappearingMessageConfig(
          hour: 0, minute: 0, type: '3', startTime: '', desc: TIM_t('关闭'));
    }
    return InkWell(
      onTap: () {
        final isDesktopScreen =
            TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
        if (!isDesktopScreen) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GroupDisappearingMessage(
                        onSubmitted: (customData) {
                          model.disappearing(customData);
                        },
                        config: config,
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
              tr('disappear.disappearing_message'),
              style: const TextStyle(fontSize: 16, color: AidaBaseColors.white),
            ),
            const Spacer(),
            Text(
              config.desc,
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
