// ignore_for_file: unrelated_type_equality_checks

import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/base_network_image.dart';
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
import 'package:url_launcher/url_launcher.dart';

class TIMUIKitCustomElem extends StatefulWidget {
  final V2TimCustomElem? customElem;
  final bool isFromSelf;
  final TextStyle? messageFontStyle;
  final BorderRadius? messageBorderRadius;
  final Color? messageBackgroundColor;
  final EdgeInsetsGeometry? textPadding;
  final V2TimMessage message;
  final bool? isShowMessageReaction;

  const TIMUIKitCustomElem({
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
  State<StatefulWidget> createState() => _TIMUIKitCustomElemState();
}

class _TIMUIKitCustomElemState extends TIMUIKitState<TIMUIKitCustomElem> {
  // 你可以在这里声明需要刷新的状态
  bool _isLoading = false;
  String _path = '';

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    final borderRadius = widget.isFromSelf
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
        ? widget.isFromSelf
            ? theme.lightPrimaryMaterialColor.shade50
            : theme.weakBackgroundColor
        : widget.isFromSelf
            ? AidaBaseColors.primaryColor
            : AidaBaseColors.whiteWithOpacity01;

    if (widget.message.customElem?.data != null &&
        widget.message.customElem!.data!.contains('call_type')) {
      final callingMessageDataProvider =
          CallingMessageDataProvider(widget.message);
      if (callingMessageDataProvider.participantType ==
          CallParticipantType.group) {
        // Group Call message
        return Container(
            padding: widget.textPadding ?? const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.messageBackgroundColor ?? backgroundColor,
              borderRadius: widget.messageBorderRadius ?? borderRadius,
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
                PARAM_NAME_USERIDS: [widget.message.userID!],
                PARAM_NAME_GROUPID: ""
              });
            }
          },
          child: Container(
              padding: widget.textPadding ?? const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.messageBackgroundColor ?? backgroundColor,
                borderRadius: widget.messageBorderRadius ?? borderRadius,
              ),
              child: CallMessageItem(
                  callingMessageDataProvider: callingMessageDataProvider,
                  padding: const EdgeInsets.all(0))),
        );
      }
    }

    /// AID 团队
    if (widget.message.customElem?.data != null &&
        widget.message.customElem!.data!.contains('aid_team_notice')) {
      final map = getMap(widget.message.customElem!.data!);
      return _aidTeam(map);
    }

    /// 红包
    if (widget.message.customElem?.data != null &&
        widget.message.customElem!.data!.contains('Envelopes')) {
      return _redPacketItem();
    }

    /// 名片
    if (widget.message.customElem?.data != null &&
        widget.message.customElem!.data!.contains('Card') &&
        isCardData(widget.message.customElem!.data!)) {
      return _cardItem(backgroundColor, borderRadius);
    }

    return Container(
        padding: widget.textPadding ?? const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.messageBackgroundColor ?? backgroundColor,
          borderRadius: widget.messageBorderRadius ?? borderRadius,
        ),
        constraints: const BoxConstraints(maxWidth: 240),
        child: Column(
          children: [
            Text(
              TIM_t("自定义消息"),
              style: TextStyle(
                  color: isDesktopScreen
                      ? Colors.black
                      : !widget.isFromSelf
                          ? AidaBaseColors.primaryColor
                          : AidaBaseColors.white),
            )
          ],
        ));
  }

  _cardItem(backgroundColor, borderRadius) {
    Map<String, dynamic> result = getMap(widget.message.customElem!.data!);
    ContactCardModel model = ContactCardModel.fromJson(result);
    return GestureDetector(
      onTap: () {
        _cardOnTap(model);
      },
      child: Container(
          padding: widget.textPadding ?? const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.messageBackgroundColor ?? backgroundColor,
            borderRadius: widget.messageBorderRadius ?? borderRadius,
          ),
          constraints: const BoxConstraints(maxWidth: 180),
          child: cardWidget(model)),
    );
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

  _redPacketItem() {
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
              widget.message.customElem?.desc ??
                  'AID ${tr('wallet.red_packet')}',
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

  _redPacketOnTap() async {
    eventCenter.post(RedPacketTipNotice(
        redEnvelopId: widget.message.customElem!.extension!,
        desc: widget.message.customElem!.desc!));
  }

  _aidTeam(Map<String, dynamic> result) {
    final Map<String, dynamic> titleMap = result['title'];
    final Map<String, dynamic> contentMap = result['content'];
    String title = '';
    String content = '';
    String image = result['image'] ?? '';
    String url = result['video'] ?? '';
    if (titleMap.isNotEmpty) {
      final locale = GetStorage().read(TencentUtils.currentLocale);
      title = titleMap[locale] ?? '';
      if (title.isEmpty) {
        title = titleMap.values.first;
      }
    }

    if (contentMap.isNotEmpty) {
      final locale = GetStorage().read(TencentUtils.currentLocale);
      content = titleMap[locale] ?? '';
      if (content.isEmpty) {
        content = contentMap.values.first;
      }
    }

    if (url.isNotEmpty) {
      _loadVideoImage(url);
    }

    return GestureDetector(
      onTap: () {
        eventCenter.post(AidTeamTipNotice(message: widget.message));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 5, right: 5, top: 5),
        decoration: BoxDecoration(
            color: AidaBaseColors.whiteWithOpacity01,
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 188,
              decoration: BoxDecoration(
                  // color: AidaBaseColors.primaryColor,
                  borderRadius: BorderRadius.circular(10)),
              child: _isLoading
                  ? Image.file(
                      File(_path),
                      width: 345,
                      height: 188,
                      fit: BoxFit.cover,
                    )
                  : BaseNetworkImage(
                      imageURL: TencentUtils.baseUrl + image,
                      fit: BoxFit.contain,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AidaBaseColors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  _loadVideoImage(url) async {

    if (_isLoading) return;

    final plugin = FcNativeVideoThumbnail();
    final Directory tempDir = await getTemporaryDirectory();
    final String destFile =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      final thumbnailGenerated = await plugin.getVideoThumbnail(
          srcFile: url,
          srcFileUri: true,
          destFile: destFile,
          width: 300,
          height: 300,
          format: 'jpeg',
          quality: 90);
      _path = destFile;
      setState(() {
        _isLoading = true;
      });
    } catch (error) {
      print('---------');
      print(error);
    }
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
