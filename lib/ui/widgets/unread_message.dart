import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_conversation_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';

class UnreadMessage extends StatefulWidget {
  final int unreadCount;
  final String? convID;
  final double? width;
  final double? height;

  const UnreadMessage(
      {Key? key,
      required this.unreadCount,
      this.convID,
      this.width = 22.0,
      this.height = 22.0})
      : super(key: key);

  @override
  State<UnreadMessage> createState() => _UnreadMessageState();
}

class _UnreadMessageState extends State<UnreadMessage> {
  final TUIConversationViewModel model =
  serviceLocator<TUIConversationViewModel>();

  String generateUnreadText() =>
      widget.unreadCount > 99 ? '99+' : widget.unreadCount.toString();

  double generateFontSize(String text) => text.length * -2 + 13;

  String unreadText = '0';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    unreadText = TencentUtils.india == widget.convID ? '' : generateUnreadText();
    handleShowUnRead();
  }

  handleShowUnRead() async {
    final isChannelOrTeam = (TencentUtils.india == widget.convID ||
        TencentUtils.korea == widget.convID ||
        TencentUtils.english == widget.convID ||
        TencentUtils.chinese == widget.convID ||
        TencentUtils.french == widget.convID ||
        TencentUtils.german == widget.convID ||
        TencentUtils.aidTeam == widget.convID);

    if (isChannelOrTeam) {

      final res = await TencentImSDKPlugin.v2TIMManager.getLoginUser();
      if (res.code == 0) {
        bool isToday = await isGroupCheckedToday(res.data!, widget.convID!, DateTime.now().millisecondsSinceEpoch);
        if (isToday) {
          setState(() {
            unreadText = '0';
          });
        } else {
          bool haveMessage = await pressedFunction();
          if (haveMessage) {
            setState(() {
              print(widget.convID);
              unreadText = '';
            });
          } else {
            setState(() {
              unreadText = '0';
            });
          }
        }
      } else {
        setState(() {
          unreadText = '0';
        });
      }

      // 获取触发时间是否是今天

      // 是 不展示

      // 不是 今天是否有有非群提示消息

      // 没有 不展示
      // 有 展示

      // 点击消除

    }
  }

  Future<bool> isGroupCheckedToday(String userID, String groupID, int currentServerTime) async {
    final key = '${TencentUtils.unreadMark}_${userID}_$groupID';
    final saved = await GetStorage().read(key);

    if (saved == null) return false;

    final savedDate = DateTime.fromMillisecondsSinceEpoch(int.parse(saved.toString()));
    final currentDate = DateTime.fromMillisecondsSinceEpoch(currentServerTime);

    return savedDate.year == currentDate.year &&
        savedDate.month == currentDate.month &&
        savedDate.day == currentDate.day;
  }

  Future<bool> pressedFunction() async {

    final now = DateTime.now(); // 当前本地时间
    final todayZero = DateTime(now.year, now.month, now.day); // 今天 0 点
    final duration = now.difference(todayZero); // 当前时间 - 今天 0 点

    final secondsSinceMidnight = duration.inSeconds;
    V2TimMessageSearchParam searchParam = V2TimMessageSearchParam(
        conversationID: "group_${widget.convID}",
        // conversationID == null，代表搜索全部会话，conversationID != null，代表搜索指定会话。
        keywordList: [],
        // 关键字列表，最多支持5个。当消息发送者以及消息类型均未指定时，关键字列表必须非空；否则，关键字列表可以为空。
        type: 3,
        // 获取历史消息类型
        userIDList: null,
        // 指定 userID 发送的消息，最多支持5个。
        messageTypeList: [1, 2, 3, 4, 5, 6],
        // 消息类型过滤列表
        searchTimePeriod: secondsSinceMidnight,
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
    return hasMessages;
  }

  @override
  Widget build(BuildContext context) {

    final fontSize = generateFontSize(unreadText);
    if (model.needUpdateGroup.contains(widget.convID)) {
      model.needUpdateGroup.remove(widget.convID);
      handleShowUnRead();
    }
    return unreadText != "0" ? Container(
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF00BBBD),
      ),
      child: Center(
              child: Text(
                unreadText,
                style: TextStyle(
                  color: AidaBaseColors.white,
                  fontSize: fontSize,
                ),
              ),
            )
    ) : Container();
  }
}
