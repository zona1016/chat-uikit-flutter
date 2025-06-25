
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/common_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/time_ago.dart';
import 'package:tencent_im_base/tencent_im_base.dart';

class TIMUIKitLastTime extends StatefulWidget {
  final V2TimMessage? lastMsg;
  final int? draftTimestamp;

  const TIMUIKitLastTime({Key? key,
    this.lastMsg,
    this.draftTimestamp,})
      : super(key: key);

  @override
  State<TIMUIKitLastTime> createState() => _TIMUIKitLastTimeState();
}

class _TIMUIKitLastTimeState extends TIMUIKitState<TIMUIKitLastTime> {
  String groupTipsAbstractText = "";

  @override
  void initState() {
    super.initState();
    _getTimeStringForChatWidget();
  }

  _getTimeStringForChatWidget() async {
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
      setState(() {
        groupTipsAbstractText = TimeAgo().getTimeStringForChat(message?.timestamp as int) ??
            "";
      });
      return;
    }

    try {
      if (widget.draftTimestamp != null && widget.draftTimestamp != 0) {
        setState(() {
          groupTipsAbstractText = TimeAgo().getTimeStringForChat(widget.draftTimestamp as int) ?? "";
        });
      } else if (widget.lastMsg != null) {
        setState(() {
          groupTipsAbstractText = TimeAgo().getTimeStringForChat(widget.lastMsg!.timestamp as int) ??
              "";
        });
      }
    } catch (err) {}
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
    if (hasMessages) {
      return items.first.messageList!.last;
    }
    return null;
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    return Text(
        groupTipsAbstractText,
        style: TextStyle(
          fontSize: 12,
          color: theme.conversationItemTitmeTextColor,
        ));
  }
}
