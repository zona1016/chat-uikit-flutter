import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_app_bar.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_button.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_screen.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitProfile/disappearing_message.dart';

class GroupDisappearingMessage extends StatefulWidget {
  final Function(Map<String, String> customData) onSubmitted;
  final DisappearingMessageConfig config;
  final String? groupId;
  final String? userId;

  const GroupDisappearingMessage(
      {Key? key,
      required this.config,
      this.groupId,
      this.userId,
      required this.onSubmitted})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupDisappearingMessageState();
}

class _GroupDisappearingMessageState
    extends TIMUIKitState<GroupDisappearingMessage> {
  final List<String> options = ["24小时", "7天", "90天", TIM_t('关闭')];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    return ChatBaseScreen(
      safeAreaTop: false,
      safeAreaBottom: false,
      backgroundColor: Colors.transparent,
      backgroundImage: AidaBaseColors.baseBackgroundImage,
      appBar: ChatBaseAppBar(
        backgroundColor: Colors.transparent,
        title: TIM_t("限时消息"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 36,
              ),
              Center(
                child: Image.asset(
                  'images/disappearing_message_big.png',
                  width: 140,
                  height: 140,
                  package: 'tencent_cloud_chat_uikit',
                ),
              ),
              const SizedBox(
                height: 22.5,
              ),
              const Text(
                '设置此对话中的消息自动消失',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AidaBaseColors.white),
              ),
              const SizedBox(
                height: 16,
              ),
              const Text(
                '为更好地保护隐私并节省存储空间，在所选期限过后，此对话中的所有新消息都将在所有人设备上自动消失（除非消息已保留）。',
                style: TextStyle(
                    fontSize: 14, color: AidaBaseColors.weakTextColor),
              ),
              const SizedBox(
                height: 30,
              ),
              const Text(
                '消息保留期限',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AidaBaseColors.white),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AidaBaseColors.whiteWithOpacity01,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    ...options.asMap().entries.map((entry) {
                      final index = entry.key; // 索引
                      final option = entry.value; // 值

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          option,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                        trailing: widget.config.desc == option
                            ? const Icon(Icons.check,
                                color: AidaBaseColors.primaryColor)
                            : null,
                        splashColor: Colors.transparent,
                        // 移除水波纹
                        hoverColor: Colors.transparent,
                        // 移除鼠标悬浮效果（Web/桌面）
                        focusColor: Colors.transparent,
                        // 移除焦点颜色
                        onTap: () {
                          widget.config.type =
                              index.toString();
                          widget.config.hour = 0;
                          widget.config.minute = 0;
                          setState(() {
                            widget.config.desc = option;
                          });
                          widget.onSubmitted(widget.config.toJson());
                        },
                      );
                    }),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AidaBaseColors.whiteWithOpacity01,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timer_outlined,
                      color: Colors.white, size: 28),
                  title: const Text(
                    "自定义消息保留期限",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  subtitle: Text(
                    "${widget.config.hour}小时 ${widget.config.minute}分钟",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.white, size: 20),
                  splashColor: Colors.transparent,
                  // 移除水波纹
                  hoverColor: Colors.transparent,
                  // 移除鼠标悬浮效果（Web/桌面）
                  focusColor: Colors.transparent,
                  // 移除焦点颜色
                  onTap: () {
                    _showCustomPicker();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomPicker() {
    int selectedHourDefault = widget.config.hour;
    int selectedMinuteDefault = widget.config.minute;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E), // 背景色
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)), // 圆角
      ),
      builder: (context) {
        return SizedBox(
          height: 300,
          child: SafeArea(
            child: Column(
              children: [
                // 标题行
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(),
                      const Text("自定义期限",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text("取消",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
                // 选择器
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 小时选择器
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                              initialItem: selectedHourDefault),
                          itemExtent: 40,
                          onSelectedItemChanged: (value) {
                            setState(() => selectedHourDefault = value);
                          },
                          children: List.generate(
                            24,
                            (index) => Center(
                              child: Text(
                                "$index",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 分钟选择器
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                              initialItem: (selectedMinuteDefault - 1)),
                          itemExtent: 40,
                          onSelectedItemChanged: (value) {
                            setState(() => selectedMinuteDefault = value + 1);
                          },
                          children: List.generate(
                            59,
                            (index) => Center(
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 确定按钮
                ChatBaseButton(
                  width: 200,
                  height: 44,
                  borderRadius: BorderRadius.circular(30),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      widget.config.hour = selectedHourDefault;
                      widget.config.minute = selectedMinuteDefault;
                      widget.config.desc = '';
                      widget.onSubmitted(widget.config.toJson());
                    });
                  },
                  text: TIM_t('确定'),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
