import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/calling_message/calling_message_data_provider.dart';

class CallMessageItem extends StatelessWidget {
  final CallingMessageDataProvider callingMessageDataProvider;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isShowIcon;

  const CallMessageItem({
    Key? key,
    required this.callingMessageDataProvider,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.isShowIcon = true,
  }) : super(key: key);

  Widget _callElemBuilder(BuildContext context) {

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (callingMessageDataProvider.direction == CallMessageDirection.incoming)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Image.asset(
              callingMessageDataProvider.streamMediaType == CallStreamMediaType.audio
                  ? "images/voice_call.png"
                  : "images/video_call.png",
              height: 16,
              width: 16,
              package: 'tencent_cloud_chat_uikit',
            ),
          ),

        Text(callingMessageDataProvider.content),

        if (callingMessageDataProvider.direction == CallMessageDirection.outcoming)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Image.asset(
              callingMessageDataProvider.streamMediaType == CallStreamMediaType.audio
                  ? "images/voice_call.png"
                  : "images/video_call_self.png",
              height: 16,
              width: 16,
              package: 'tencent_cloud_chat_uikit',
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadiusDefault = callingMessageDataProvider.direction == CallMessageDirection.incoming
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
    return Container(
      padding: padding ?? const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? borderRadiusDefault,
      ),
      constraints: const BoxConstraints(maxWidth: 240),
      child: _callElemBuilder(context),
    );
  }
}