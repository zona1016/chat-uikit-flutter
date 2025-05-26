import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/tim_uikit_wide_modal_operation_key.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_app_bar.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_screen.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/event_center.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/time_ago.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitSearch/group_search_member_list_page.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitSearch/pureUI/tim_uikit_search_input.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitSearch/pureUI/tim_uikit_search_item.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitSearch/search_date_widget.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitSearch/search_image_video_result_widget.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';

class GroupMessageSearch extends StatefulWidget {
  final TUIGroupProfileModel model;

  const GroupMessageSearch({super.key, required this.model});

  @override
  State<GroupMessageSearch> createState() => _GroupMessageSearchState();
}

class _GroupMessageSearchState extends State<GroupMessageSearch> {
  late TextEditingController textEditingController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  List<V2TimMessage>? messageList;

  bool showSearchWidget = false;
  bool showSearchText = true;

  List<String> userIDList = [];

  final List<Map<String, dynamic>> filters = [
    {'label': TIM_t('群成员'), 'type': 1},
    {'label': '日期', 'type': 2},
    {
      // [3, 5]
      'label': '图片与视频',
      'type': 3,
    },
    {'label': TIM_t('文件'), 'type': 4}, // 6
    {'label': '链接', 'type': 5},
    {'label': '音频', 'type': 6},
    {'label': '', 'type': 0},
    {'label': '交易', 'type': 7},
    {'label': '', 'type': 0},
  ];

  pressedFunction() async {
    List<String> keywordList = [];
    if (textEditingController.text.isNotEmpty) {
      keywordList.add(textEditingController.text);
    }

    if (keywordList.isEmpty) return;

    V2TimMessageSearchParam searchParam = V2TimMessageSearchParam(
        conversationID: "group_${widget.model.groupID}",
        // conversationID == null，代表搜索全部会话，conversationID != null，代表搜索指定会话。
        keywordList: keywordList,
        // 关键字列表，最多支持5个。当消息发送者以及消息类型均未指定时，关键字列表必须非空；否则，关键字列表可以为空。
        type: 3,
        // 获取历史消息类型
        userIDList: null,
        // 指定 userID 发送的消息，最多支持5个。
        messageTypeList: null,
        // 消息类型过滤列表
        searchTimePeriod: 0,
        // 从起始时间点开始的过去时间范围，单位秒。默认为0即代表不限制时间范围，传24x60x60代表过去一天。
        searchTimePosition: 0,
        // 搜索的起始时间点。默认为0即代表从现在开始搜索。UTC 时间戳，单位：秒
        pageIndex: 0,
        // 分页的页号：用于分页展示查找结果，从零开始起步。
        pageSize: 0);
    V2TimValueCallback<V2TimMessageSearchResult> searchLocalMessagesRes =
        await TencentImSDKPlugin.v2TIMManager
            .getMessageManager()
            .searchLocalMessages(searchParam: searchParam);
    setState(() {
      messageList = searchLocalMessagesRes
          .data?.messageSearchResultItems?.first.messageList;
    });
  }

  searchImageAndVideoFunction() async {
    V2TimMessageSearchParam searchParam = V2TimMessageSearchParam(
        conversationID: "group_${widget.model.groupID}",
        // conversationID == null，代表搜索全部会话，conversationID != null，代表搜索指定会话。
        keywordList: [],
        // 关键字列表，最多支持5个。当消息发送者以及消息类型均未指定时，关键字列表必须非空；否则，关键字列表可以为空。
        type: 1,
        // 获取历史消息类型
        userIDList: null,
        // 指定 userID 发送的消息，最多支持5个。
        messageTypeList: [3, 5],
        // 消息类型过滤列表
        searchTimePeriod: 0,
        // 从起始时间点开始的过去时间范围，单位秒。默认为0即代表不限制时间范围，传24x60x60代表过去一天。
        searchTimePosition: 0,
        // 搜索的起始时间点。默认为0即代表从现在开始搜索。UTC 时间戳，单位：秒
        pageIndex: 0,
        // 分页的页号：用于分页展示查找结果，从零开始起步。
        pageSize: 0);
    V2TimValueCallback<V2TimMessageSearchResult> searchLocalMessagesRes =
        await TencentImSDKPlugin.v2TIMManager
            .getMessageManager()
            .searchLocalMessages(searchParam: searchParam);
    setState(() {
      final items = searchLocalMessagesRes.data?.messageSearchResultItems;
      final hasMessages = items != null &&
          items.isNotEmpty &&
          items.first.messageList != null &&
          items.first.messageList!.isNotEmpty;
      if (hasMessages) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SearchImageVideoResultWidget(
                    messageList: items.first.messageList!)));
      } else {
        TUIToast.show(content: '暂无图片视频消息', duration: TUIDuration.long);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TUIKitScreenUtils.getDeviceWidget(
        context: context,
        desktopWidget: const Placeholder(),
        defaultWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TIMUIKitSearchInput(
              focusNode: focusNode,
              controller: textEditingController,
              onChange: (String value) {
                setState(() {
                  textEditingController.text = value;
                  messageList = [];
                  showSearchText = true;
                  showSearchWidget = true;
                });
              },
              prefixIcon: const Icon(
                Icons.search,
                size: 16,
                color: AidaBaseColors.white,
              ),
            ),
            showSearchWidget ? Expanded(child: searchWidget()) : defaultWidget()
          ],
        ));
  }

  searchWidget() {
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (textEditingController.text.isNotEmpty && showSearchText)
          GestureDetector(
            onTap: () {
              setState(() {
                showSearchText = false;
                pressedFunction();
              });
            },
            child: Container(
              alignment: Alignment.centerLeft,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: AidaBaseColors.whiteWithOpacity01,
              child: Text(
                '${TIM_t('搜索')}：${textEditingController.text}',
                style: const TextStyle(color: AidaBaseColors.primaryColor),
              ),
            ),
          ),
        if (messageList != null && messageList!.isNotEmpty)
          Expanded(
            child: ListView(
              children: [
                ..._renderListMessage(
                    messageList ?? [], context, isDesktopScreen)
              ],
            ),
          )
      ],
    );
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

  String _getMsgElem(V2TimMessage message) {
    final msgType = message.elemType;
    final revokeStatus = isRevokeMessage(message);
    final isRevokedMessage = revokeStatus.$1;
    final isAdminRevoke = revokeStatus.$2;
    if (isRevokedMessage) {
      final isSelf = message.isSelf ?? true;
      final option2 = isAdminRevoke
          ? TIM_t("管理员")
          : (isSelf ? TIM_t("您") : message.nickName ?? message.sender);
      return TIM_t_para("{{option2}}撤回了一条消息", "$option2撤回了一条消息")(
          option2: option2);
    }
    switch (msgType) {
      case MessageElemType.V2TIM_ELEM_TYPE_CUSTOM:
        return TIM_t("[自定义]");
      case MessageElemType.V2TIM_ELEM_TYPE_SOUND:
        return TIM_t("[语音]");
      case MessageElemType.V2TIM_ELEM_TYPE_TEXT:
        return message.textElem!.text as String;
      case MessageElemType.V2TIM_ELEM_TYPE_FACE:
        return TIM_t("[表情]");
      case MessageElemType.V2TIM_ELEM_TYPE_FILE:
        final option1 = message.fileElem!.fileName;
        return TIM_t_para("[文件] {{option1}}", "[文件] $option1")(
            option1: option1);
      case MessageElemType.V2TIM_ELEM_TYPE_IMAGE:
        return TIM_t("[图片]");
      case MessageElemType.V2TIM_ELEM_TYPE_VIDEO:
        return TIM_t("[视频]");
      case MessageElemType.V2TIM_ELEM_TYPE_LOCATION:
        return TIM_t("[位置]");
      case MessageElemType.V2TIM_ELEM_TYPE_MERGER:
        return TIM_t("[聊天记录]");
      default:
        return TIM_t("未知消息");
    }
  }

  List<Widget> _renderListMessage(
      List<V2TimMessage> msgList, BuildContext context, bool isDesktopScreen) {
    List<Widget> listWidget = [];

    listWidget = msgList.map((message) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: TIMUIKitSearchItem(
          faceUrl: message.faceUrl ?? "",
          showName: TencentUtils.checkString(message.nickName) ??
              TencentUtils.checkString(message.userID) ??
              message.sender ??
              "",
          lineOne: TencentUtils.checkString(message.nickName) ??
              TencentUtils.checkString(message.userID) ??
              message.sender ??
              "",
          lineOneRight: (isDesktopScreen && message.timestamp != null)
              ? TimeAgo().getTimeForMessage(message.timestamp!)
              : null,
          lineTwo: _getMsgElem(message),
          onClick: () {
            eventCenter.post(SearchMessageTipNotice(
                message: message,
                selectedConversation: V2TimConversation(
                    conversationID: "group_${widget.model.groupID}",
                    groupID: widget.model.groupID,
                    faceUrl: widget.model.groupInfo?.faceUrl ?? '',
                    showName: widget.model.groupInfo?.groupName ?? '',
                    type: 2)));
          },
        ),
      );
    }).toList();
    return listWidget;
  }

  defaultWidget() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              '搜索指定内容',
              style:
                  TextStyle(color: AidaBaseColors.weakTextColor, fontSize: 14),
            ),
          ),
        ),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 20,
            children: filters.map((item) {
              return GestureDetector(
                onTap: () {
                  switch (item['type']) {
                    case 1:
                      navigateToMemberList(
                          context, widget.model, widget.model.groupMemberList);
                      break;
                    case 2:
                      navigateToSearchDate();
                      break;
                    case 3:
                      searchImageAndVideoFunction();
                      break;
                  }
                  print('Clicked: ${item['type']}');
                },
                child: Container(
                  width: 90,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['label'],
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }

  void navigateToMemberList(BuildContext context, TUIGroupProfileModel model,
      List<V2TimGroupMemberFullInfo?> memberList) async {
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    if (!isDesktopScreen) {
      final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GroupSearchMemberListPage(model: model, memberList: memberList),
          ));
      if (result != null) {
        userIDList = result
                .where((member) => member?.userID != null)
                .map((member) => member!.userID!)
                .whereType<String>()
                .toList() ??
            [];
      }
    } else {
      final option1 = memberList.length.toString();
      TUIKitWidePopup.showPopupWindow(
          operationKey: TUIKitWideModalOperationKey.groupMembersList,
          context: context,
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.8,
          title: TIM_t_para("群成员({{option1}}人)", "群成员($option1人)")(
              option1: option1),
          child: (onClose) =>
              GroupSearchMemberListPage(model: model, memberList: memberList));
    }
  }

  navigateToSearchDate() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatBaseScreen(
              safeAreaTop: true,
              safeAreaBottom: false,
              backgroundColor: Colors.transparent,
              backgroundImage: AidaBaseColors.baseBackgroundImage,
              appBar: ChatBaseAppBar(
                title: TIM_t('按日期查找'),
              ),
              body: SearchDateWidget(
                model: widget.model,
              )),
        ));
  }
}
