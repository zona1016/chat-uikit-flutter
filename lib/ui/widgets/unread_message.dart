import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';

class UnreadMessage extends TIMUIKitStatelessWidget {
  final int unreadCount;
  final String? convID;
  final double? width;
  final double? height;

  UnreadMessage(
      {Key? key,
      required this.unreadCount,
      this.convID,
      this.width = 22.0,
      this.height = 22.0})
      : super(key: key);

  String generateUnreadText() =>
      unreadCount > 99 ? '99+' : unreadCount.toString();

  double generateFontSize(String text) => text.length * -2 + 13;

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;

    final unreadText = TencentUtils.india == convID ? '' : generateUnreadText();
    final fontSize = generateFontSize(unreadText);
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF00BBBD),
      ),
      child: unreadText != "0"
          ? Center(
              child: Text(
                unreadText,
                style: TextStyle(
                  color: theme.conversationItemUnreadCountTextColor,
                  fontSize: fontSize,
                ),
              ),
            )
          : null,
    );
  }
}
