// ignore_for_file: unrelated_type_equality_checks


import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/calling_message/calling_message_data_provider.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/calling_message/group_call_message_builder.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/calling_message/single_call_message_builder.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_im_base/tencent_im_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';


class TIMUIKitCustomElem extends TIMUIKitStatelessWidget {
  final V2TimCustomElem? customElem;
  final bool isFromSelf;
  final TextStyle? messageFontStyle;
  final BorderRadius? messageBorderRadius;
  final Color? messageBackgroundColor;
  final EdgeInsetsGeometry? textPadding;
  final V2TimMessage message;
  final bool? isShowMessageReaction;

  TIMUIKitCustomElem({
    Key? key,
    required this.message,
    this.isShowMessageReaction,
    this.customElem,
    this.isFromSelf = false,
    this.messageFontStyle,
    this.messageBorderRadius,
    this.messageBackgroundColor,
    this.textPadding,
  }) : super(key: key);

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    final borderRadius = isFromSelf
        ? const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(2),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10))
        : const BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10));
    final backgroundColor = isDesktopScreen ? isFromSelf
        ? theme.lightPrimaryMaterialColor.shade50
        : theme.weakBackgroundColor : isFromSelf
        ? const Color(0xFF00BBBD) : const Color(0xFFFFFFFF);

    if (message.customElem?.data != null && message.customElem!.data!.contains('call_type')) {
      final callingMessageDataProvider = CallingMessageDataProvider(message);
      if (callingMessageDataProvider.participantType == CallParticipantType.group) {
        // Group Call message
        return Container(
            padding: textPadding ?? const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: messageBackgroundColor ?? backgroundColor,
              borderRadius: messageBorderRadius ?? borderRadius,
            ),
            child: GroupCallMessageItem(callingMessageDataProvider: callingMessageDataProvider));
      } else {
        return Container(
            padding: textPadding ?? const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: messageBackgroundColor ?? backgroundColor,
              borderRadius: messageBorderRadius ?? borderRadius,
            ),
            child: CallMessageItem(
                callingMessageDataProvider: callingMessageDataProvider,
                padding: const EdgeInsets.all(0)));
      }
    }

    return Container(
        padding: textPadding ?? const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: messageBackgroundColor ?? backgroundColor,
          borderRadius: messageBorderRadius ?? borderRadius,
        ),
        constraints: const BoxConstraints(maxWidth: 240),
        child: Column(
          children: [
            Text(TIM_t("自定义消息"), style: TextStyle(color: isDesktopScreen ? Colors.black : !isFromSelf
                ? const Color(0xFF00BBBD) : const Color(0xFFFFFFFF)),)
          ],
        ));
  }
}
