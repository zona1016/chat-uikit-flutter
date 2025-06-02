import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'dart:convert';

import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/event_center.dart';

class SearchDateWidget extends StatefulWidget {
  final TUIGroupProfileModel model;

  const SearchDateWidget({Key? key, required this.model}) : super(key: key);

  @override
  State<SearchDateWidget> createState() => _SearchDateWidgetState();
}

class _SearchDateWidgetState extends State<SearchDateWidget> {
  DateTime? serverNow;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchServerTime();
  }

  Future<void> fetchServerTime() async {
    V2TimValueCallback<int> loginRes =
        await TencentImSDKPlugin.v2TIMManager.getServerTime();
    setState(() {
      final result = ServerTimeResponse.fromJson(loginRes.toJson());
      if (result.code == 0) {
        serverNow = result.toDateTime();
        selectedDate = result.toDateTime();
      } else {
        serverNow = DateTime.now(); // fallback
        selectedDate = DateTime.now();
      }
    });
  }

  List<Widget> buildCalendarForMonth(DateTime monthDate) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final totalGridCount = daysInMonth + firstWeekday;
    final rows = (totalGridCount / 7).ceil();

    List<Widget> dayWidgets = [];

    for (int i = 0; i < rows * 7; i++) {
      final dayNumber = i - firstWeekday + 1;

      if (i < firstWeekday || dayNumber > daysInMonth) {
        dayWidgets.add(Container()); // 空格
      } else {
        final dayDate = DateTime(monthDate.year, monthDate.month, dayNumber);

        final isCurrentMonth = serverNow!.year == monthDate.year &&
            serverNow!.month == monthDate.month;

        if (isCurrentMonth && dayDate.isAfter(serverNow!)) {
          dayWidgets.add(Container()); // 用空格占位
          continue;
        }

        final isToday = dayDate.year == serverNow!.year &&
            dayDate.month == serverNow!.month &&
            dayDate.day == serverNow!.day;

        dayWidgets.add(
          GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = dayDate;
                searchMessageFunction();
              });
            },
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isToday
                        ? AidaBaseColors.secondPrimaryColor
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      color: selectedDate?.day == dayNumber &&
                              selectedDate?.month == monthDate.month &&
                              !isToday
                          ? AidaBaseColors.secondPrimaryColor
                          : Colors.white,
                      fontWeight: selectedDate?.day == dayNumber &&
                              selectedDate?.month == monthDate.month
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isToday)
                  const Text(
                    "今天",
                    style: TextStyle(
                        color: AidaBaseColors.secondPrimaryColor, fontSize: 12),
                  ),
              ],
            ),
          ),
        );
      }
    }

    return dayWidgets;
  }

  @override
  Widget build(BuildContext context) {
    if (serverNow == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final previousMonth = DateTime(serverNow!.year, serverNow!.month - 1);

    return Scaffold(
      backgroundColor: AidaBaseColors.whiteWithOpacity01,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                DateFormat("yyyy年M月").format(
                  DateTime(serverNow!.year, serverNow!.month - 1),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("日"),
                  Text("一"),
                  Text("二"),
                  Text("三"),
                  Text("四"),
                  Text("五"),
                  Text("六"),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: buildCalendarForMonth(previousMonth),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                DateFormat("M月").format(serverNow!),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: buildCalendarForMonth(serverNow!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  searchMessageFunction() async {
    int seconds = selectedDate!.difference(serverNow!).inDays.abs();
    DateTime startOfDay = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
    ).add(const Duration(days: 1));
    V2TimMessageSearchParam searchParam = V2TimMessageSearchParam(
        conversationID: "group_${widget.model.groupID}",
        // conversationID == null，代表搜索全部会话，conversationID != null，代表搜索指定会话。
        keywordList: [],
        // 关键字列表，最多支持5个。当消息发送者以及消息类型均未指定时，关键字列表必须非空；否则，关键字列表可以为空。
        type: 1,
        // 获取历史消息类型
        userIDList: null,
        // 指定 userID 发送的消息，最多支持5个。
        messageTypeList: [1, 2, 3, 4, 5, 6, 7],
        // 消息类型过滤列表
        searchTimePeriod: 24 * 60 * 60,
        // 从起始时间点开始的过去时间范围，单位秒。默认为0即代表不限制时间范围，传24x60x60代表过去一天。
        searchTimePosition:
            seconds == 0 ? 0 : startOfDay.millisecondsSinceEpoch ~/ 1000,
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
        eventCenter.post(SearchMessageTipNotice(
            message: searchLocalMessagesRes
                .data!.messageSearchResultItems!.first.messageList!.last,
            selectedConversation: V2TimConversation(
                conversationID: "group_${widget.model.groupID}",
                groupID: widget.model.groupID,
                faceUrl: widget.model.groupInfo?.faceUrl ?? '',
                showName: widget.model.groupInfo?.groupName ?? '',
                type: 2)));
      } else {
        TUIToast.show(content: '当前时间无消息');
      }
    });
  }
}

class ServerTimeResponse {
  final int code;
  final String desc;
  final int data; // 时间戳（例如：1748222660）

  ServerTimeResponse({
    required this.code,
    required this.desc,
    required this.data,
  });

  factory ServerTimeResponse.fromJson(Map<String, dynamic> json) {
    return ServerTimeResponse(
      code: json['code'],
      desc: json['desc'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'desc': desc,
      'data': data,
    };
  }

  /// 转换为 DateTime（秒级时间戳 → DateTime）
  DateTime toDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(data * 1000);
  }
}
