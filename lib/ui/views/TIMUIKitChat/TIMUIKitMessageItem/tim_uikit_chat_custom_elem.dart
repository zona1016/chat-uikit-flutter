// ignore_for_file: unrelated_type_equality_checks

import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/calling_message/calling_message_data_provider.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/calling_message/group_call_message_builder.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/calling_message/single_call_message_builder.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/event_center.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
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
    final backgroundColor = isDesktopScreen
        ? isFromSelf
            ? theme.lightPrimaryMaterialColor.shade50
            : theme.weakBackgroundColor
        : isFromSelf
            ? AidaBaseColors.primaryColor
            : AidaBaseColors.whiteWithOpacity01;

    if (message.customElem?.data != null &&
        message.customElem!.data!.contains('call_type')) {
      final callingMessageDataProvider = CallingMessageDataProvider(message);
      if (callingMessageDataProvider.participantType ==
          CallParticipantType.group) {
        // Group Call message
        return Container(
            padding: textPadding ?? const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: messageBackgroundColor ?? backgroundColor,
              borderRadius: messageBorderRadius ?? borderRadius,
            ),
            child: GroupCallMessageItem(
                callingMessageDataProvider: callingMessageDataProvider));
      } else {
        return GestureDetector(
          onTap: () {
            if (PlatformUtils().isMobile) {
              TUICore().callService(TUICALLKIT_SERVICE_NAME, METHOD_NAME_CALL, {
                PARAM_NAME_TYPE: callingMessageDataProvider.streamMediaType ==
                        CallStreamMediaType.audio
                    ? TYPE_AUDIO
                    : TYPE_VIDEO,
                PARAM_NAME_USERIDS: [message.userID!],
                PARAM_NAME_GROUPID: ""
              });
            }
          },
          child: Container(
              padding: textPadding ?? const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: messageBackgroundColor ?? backgroundColor,
                borderRadius: messageBorderRadius ?? borderRadius,
              ),
              child: CallMessageItem(
                  callingMessageDataProvider: callingMessageDataProvider,
                  padding: const EdgeInsets.all(0))),
        );
      }
    }

    if (message.customElem?.data != null) {
      Map<String, dynamic> result = getMap(message.customElem!.data!);

      return GestureDetector(
        onTap: () {
          _redPacketOnTap();
        },
        child: Container(
          height: 70,
          constraints: const BoxConstraints(maxWidth: 160),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/red_pagket_bg.png',
                  package: 'tencent_cloud_chat_uikit'), // 本地图片
              fit: BoxFit.fitHeight,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
              ),
              Image.asset(
                'images/red_pagket_icon.png',
                package: 'tencent_cloud_chat_uikit',
                width: 40,
                height: 40,
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                  child: Text(
                result['desc'] ?? 'AID 红包',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AidaBaseColors.white,
                ),
              )),
              const SizedBox(
                width: 16,
              ),
            ],
          ),
        ),
      );
    }

    if (message.customElem?.data != null &&
        isCardData(message.customElem!.data!)) {
      Map<String, dynamic> result = getMap(message.customElem!.data!);
      ContactCardModel model = ContactCardModel.fromJson(result);
      return GestureDetector(
        onTap: () {
          _cardOnTap(model);
        },
        child: Container(
            padding: textPadding ?? const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: messageBackgroundColor ?? backgroundColor,
              borderRadius: messageBorderRadius ?? borderRadius,
            ),
            constraints: const BoxConstraints(maxWidth: 180),
            child: cardWidget(model)),
      );
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
            Text(
              TIM_t("自定义消息"),
              style: TextStyle(
                  color: isDesktopScreen
                      ? Colors.black
                      : !isFromSelf
                          ? AidaBaseColors.primaryColor
                          : AidaBaseColors.white),
            )
          ],
        ));
  }

  _cardOnTap(ContactCardModel model) async {
    final FriendshipServices friendshipServices =
        serviceLocator<FriendshipServices>();
    final checkFriend = await friendshipServices.checkFriend(
        userIDList: [model.userID],
        checkType: FriendTypeEnum.V2TIM_FRIEND_TYPE_SINGLE);
    if (checkFriend != null) {
      final res = checkFriend.first;
      if (res.resultCode == 0 && res.resultType != 0) {
        eventCenter.post(CardTipNotice(isFriend: true, userId: model.userID));
        return;
      }
    }
    eventCenter.post(CardTipNotice(isFriend: false, userId: model.userID));
  }

  _redPacketOnTap() async {
    Map<String, dynamic> result = getMap(message.customElem!.data!);

    print(result);
    return;
    eventCenter.post(RedPacketTipNotice(redEnvelopId: 'redEnvelopId', desc: 'desc'));
  }

  cardWidget(ContactCardModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              width: 40,
              child: Avatar(
                faceUrl: model.imageUrl,
                showName: model.name,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Text(
              model.name,
              style: const TextStyle(color: AidaBaseColors.white),
            )
          ],
        ),
        const SizedBox(
          height: 8,
        ),
        const Divider(
          height: 1,
          color: AidaBaseColors.whiteGray,
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          tr('wallet.personal_card'),
          style: const TextStyle(color: AidaBaseColors.white),
        )
      ],
    );
  }

  bool isCardData(String data) {
    Map result = getMap(data);
    return result['type']?.toString().toLowerCase() == 'card';
  }

  Map<String, dynamic> getMap(String data) {
    Map<String, dynamic>? map;

    try {
      final decoded = json.decode(data);
      if (decoded is Map<String, dynamic>) {
        map = decoded;
      } else {
        return {}; // 解析后不是Map
      }
    } catch (e) {
      return {}; // 解析异常
    }

    return map;
  }
}

class ContactCardModel {
  final String type;
  final String name;
  final String imageUrl;
  final String userID;

  ContactCardModel({
    required this.type,
    required this.name,
    required this.imageUrl,
    required this.userID,
  });

  factory ContactCardModel.fromJson(Map<String, dynamic> json) {
    return ContactCardModel(
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      userID: json['userID'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BussinessID': type,
      'text': name,
      'imageUrl': imageUrl,
      'contactId': userID,
    };
  }
}
