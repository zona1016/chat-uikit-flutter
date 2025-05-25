import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';

class SearchDateWidget extends StatefulWidget {
  const SearchDateWidget({Key? key}) : super(key: key);

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
    setState(() {
      serverNow = DateTime.now(); // fallback
      selectedDate = DateTime.now();
    });
    // final response = await http.get(Uri.parse("http://worldtimeapi.org/api/timezone/Asia/Shanghai"));
    //
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   final timeStr = data["datetime"];
    //   final time = DateTime.parse(timeStr);
    //   setState(() {
    //     serverNow = time;
    //     selectedDate = time;
    //   });
    // } else {
    //
    // }
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
        final isToday = serverNow != null &&
            dayDate.year == serverNow!.year &&
            dayDate.month == serverNow!.month &&
            dayDate.day == serverNow!.day;

        dayWidgets.add(
          GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = dayDate;
              });
            },
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isToday ? Colors.green : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      color: Colors.white,
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
                    style: TextStyle(color: AidaBaseColors.primaryColor, fontSize: 12),
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
          children: [
            const SizedBox(height: 8),
            // 月份文本（只显示当前月）
            Text(
              DateFormat("yyyy年M月").format(serverNow!),
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 16),
            // 日历头部
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
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
            const SizedBox(height: 8),

            // 上一月日历
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: buildCalendarForMonth(previousMonth),
              ),
            ),

            const SizedBox(height: 16),
            // 当前月日历
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
}
