// ignore_for_file: unrelated_type_equality_checks

import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/ui/constants/history_message_constant.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/calling_message/calling_message_data_provider.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/common_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_im_base/tencent_im_base.dart';
import 'package:tim_ui_kit_sticker_plugin/constant/emoji.dart';

class TIMUIKitLastMsg extends StatefulWidget {
  final V2TimMessage? lastMsg;
  final List<V2TimGroupAtInfo?> groupAtInfoList;
  final BuildContext context;
  final double fontSize;

  const TIMUIKitLastMsg(
      {Key? key,
      this.lastMsg,
      required this.groupAtInfoList,
      required this.context,
      this.fontSize = 14.0})
      : super(key: key);

  @override
  State<TIMUIKitLastMsg> createState() => _TIMUIKitLastMsgState();
}

class _TIMUIKitLastMsgState extends TIMUIKitState<TIMUIKitLastMsg> {
  String groupTipsAbstractText = "";

  @override
  void initState() {
    super.initState();
    _getMsgElem();
  }

  @override
  void didUpdateWidget(covariant TIMUIKitLastMsg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.lastMsg?.msgID != widget.lastMsg?.msgID) ||
        (oldWidget.lastMsg?.id != widget.lastMsg?.id) ||
        (oldWidget.lastMsg?.status != widget.lastMsg?.status)) {
      _getMsgElem();
    }
  }

  (bool isRevoke, bool isRevokeByAdmin) isRevokeMessage(V2TimMessage? message) {
    if (message == null) {
      return (false, false);
    }
    if (message.status == 6) {
      return (true, false);
    } else {
      try {
        final customData = jsonDecode(message.cloudCustomData ?? "{}");
        final isRevoke = customData["isRevoke"] ?? false;
        final revokeByAdmin = customData["revokeByAdmin"] ?? false;
        return (isRevoke, revokeByAdmin);
      } catch (e) {
        return (false, false);
      }
    }
  }

  void _getMsgElem() async {
    final revokeStatus = isRevokeMessage(widget.lastMsg);
    final isRevokedMessage = revokeStatus.$1;
    final isAdminRevoke = revokeStatus.$2;

    if (widget.lastMsg?.elemType ==
            MessageElemType.V2TIM_ELEM_TYPE_GROUP_TIPS &&
        (TencentUtils.aidTeam == widget.lastMsg?.groupID ||
            TencentUtils.india == widget.lastMsg?.groupID ||
            TencentUtils.korea == widget.lastMsg?.groupID ||
            TencentUtils.english == widget.lastMsg?.groupID ||
            TencentUtils.chinese == widget.lastMsg?.groupID ||
            TencentUtils.french == widget.lastMsg?.groupID ||
            TencentUtils.german == widget.lastMsg?.groupID)) {
      final message = await pressedFunction();
      if (message != null) {
        final newText =
            await _getLastMsgShowText(message, widget.context) ?? "";
        if (mounted) {
          setState(() {
            groupTipsAbstractText =
                (message.nickName ?? message.sender ?? '') +
                    '：' +
                    newText;
          });
        }
      } else {
        groupTipsAbstractText = '';
      }
      return;
    }

    if (isRevokedMessage) {
      final isSelf = widget.lastMsg!.isSelf ?? true;
      final option1 = isAdminRevoke
          ? TIM_t("管理员")
          : (isSelf
              ? TIM_t("您")
              : widget.lastMsg!.nickName ?? widget.lastMsg?.sender);
      if (mounted) {
        setState(() {
          groupTipsAbstractText = TIM_t_para(
              "{{option1}}撤回了一条消息", "$option1撤回了一条消息")(option1: option1);
        });
      }
    } else {
      final newText =
          await _getLastMsgShowText(widget.lastMsg, widget.context) ?? "";
      if (mounted) {
        setState(() {
          groupTipsAbstractText =
              (widget.lastMsg?.nickName ?? widget.lastMsg?.sender ?? '') +
                  '：' +
                  newText;
        });
      }
    }
  }

  Future<V2TimMessage?> pressedFunction() async {
    V2TimMessageSearchParam searchParam = V2TimMessageSearchParam(
        conversationID: "group_${widget.lastMsg?.groupID}",
        // conversationID == null，代表搜索全部会话，conversationID != null，代表搜索指定会话。
        keywordList: [],
        // 关键字列表，最多支持5个。当消息发送者以及消息类型均未指定时，关键字列表必须非空；否则，关键字列表可以为空。
        type: 3,
        // 获取历史消息类型
        userIDList: null,
        // 指定 userID 发送的消息，最多支持5个。
        messageTypeList: [1, 2, 3, 4, 5, 6],
        // 消息类型过滤列表
        searchTimePeriod: 0,
        // 从起始时间点开始的过去时间范围，单位秒。默认为0即代表不限制时间范围，传24x60x60代表过去一天。
        searchTimePosition: 0,
        // 搜索的起始时间点。默认为0即代表从现在开始搜索。UTC 时间戳，单位：秒
        pageIndex: 0,
        // 分页的页号：用于分页展示查找结果，从零开始起步。
        pageSize: 1000000);
    V2TimValueCallback<V2TimMessageSearchResult> searchLocalMessagesRes =
        await TencentImSDKPlugin.v2TIMManager
            .getMessageManager()
            .searchLocalMessages(searchParam: searchParam);
    final items = searchLocalMessagesRes.data?.messageSearchResultItems;
    final hasMessages = items != null &&
        items.isNotEmpty &&
        items.first.messageList != null &&
        items.first.messageList!.isNotEmpty;
    V2TimMessage? message;
    if (hasMessages) {
      message = items.first.messageList!.first;
    }

    if (message?.nickName == null && message?.sender != null) {
      V2TimValueCallback<List<V2TimUserFullInfo>> result =
      await TencentImSDKPlugin.v2TIMManager
          .getUsersInfo(userIDList: [message!.sender!]);

      if (result.code == 0 && result.data != null && result.data!.isNotEmpty) {
        message.nickName = result.data!.first.nickName;
      }
    }
    // 获取用户的昵称
    return message;
  }

  Future<String?> _getLastMsgShowText(
      V2TimMessage? message, BuildContext context) async {
    final msgType = message!.elemType;
    switch (msgType) {
      case MessageElemType.V2TIM_ELEM_TYPE_CUSTOM:
        final isCallType = message.customElem?.data != null &&
            message.customElem!.data!.contains('call_type');
        if (isCallType) {
          final callingMessageDataProvider =
              CallingMessageDataProvider(message);
          return callingMessageDataProvider.content;
        }
        return message.groupID == TencentUtils.aidTeam
            ? '[${tr('chat.announcement_message')}]'
            : TIM_t("[自定义]");
      case MessageElemType.V2TIM_ELEM_TYPE_SOUND:
        return TIM_t("[语音]");
      case MessageElemType.V2TIM_ELEM_TYPE_TEXT:
        final text = (message.textElem?.text)?.trim() ?? "";
        final emojiPattern = RegExp(r'\[.*?\]');
        return text.replaceAllMapped(emojiPattern, (match) {
          var key = match.group(0)!.substring(1, match.group(0)!.length - 1);
          if (TUIKitStickerConstData.emojiMapList.containsKey(key)) {
            key = TUIKitStickerConstData.emojiMapList[key]!;
          } else if (CustomTUIKitStickerConstData.emojiMapListTCC1.containsKey(key)) {
            key = CustomTUIKitStickerConstData.emojiMapListTCC1[key]!;
          }
          return TIM_t("[$key]");
        });
      case MessageElemType.V2TIM_ELEM_TYPE_FACE:
        return TIM_t("[表情]");
      case MessageElemType.V2TIM_ELEM_TYPE_FILE:
        final option1 = widget.lastMsg!.fileElem!.fileName;
        return TIM_t_para("[文件] {{option1}}", "[文件] $option1")(
            option1: option1);
      case MessageElemType.V2TIM_ELEM_TYPE_GROUP_TIPS:
        return await MessageUtils.groupTipsMessageAbstract(
            message.groupTipsElem!, []);
      case MessageElemType.V2TIM_ELEM_TYPE_IMAGE:
        return TIM_t("[图片]");
      case MessageElemType.V2TIM_ELEM_TYPE_VIDEO:
        return TIM_t("[视频]");
      case MessageElemType.V2TIM_ELEM_TYPE_LOCATION:
        return TIM_t("[位置]");
      case MessageElemType.V2TIM_ELEM_TYPE_MERGER:
        return TIM_t("[聊天记录]");
      default:
        return null;
    }
  }

  Icon? _getIconByMsgStatus(BuildContext context) {
    final msgStatus = widget.lastMsg!.status;
    final theme = Provider.of<TUIThemeViewModel>(context).theme;
    if (msgStatus == MessageStatus.V2TIM_MSG_STATUS_SEND_FAIL) {
      return Icon(Icons.error, color: theme.cautionColor, size: 16);
    }
    if (msgStatus == MessageStatus.V2TIM_MSG_STATUS_SENDING) {
      return Icon(Icons.arrow_back, color: theme.weakTextColor, size: 16);
    }
    return null;
  }

  String _getAtMessage() {
    String msg = "";
    for (var item in widget.groupAtInfoList) {
      if (item!.atType == 1) {
        msg = TIM_t("[有人@我] ");
      } else {
        msg = TIM_t("[@所有人] ");
      }
    }
    return msg;
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final icon = _getIconByMsgStatus(context);
    return Row(children: [
      if (icon != null)
        Container(
          margin: const EdgeInsets.only(right: 2),
          child: icon,
        ),
      if (widget.groupAtInfoList.isNotEmpty)
        Text(_getAtMessage(),
            style: TextStyle(
                color: theme.cautionColor, fontSize: widget.fontSize)),
      if (TencentUtils.checkString(groupTipsAbstractText) != null)
        Expanded(
            child: Text(
          groupTipsAbstractText,
          softWrap: true,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              height: 1, color: theme.weakTextColor, fontSize: widget.fontSize),
        )),
    ]);
  }
}
