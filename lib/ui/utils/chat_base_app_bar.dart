import 'package:flutter/material.dart';

class ChatBaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final TextStyle? titleStyle;
  final Color backgroundColor;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget? leading;

  const ChatBaseAppBar({
    Key? key,
    required this.title,
    this.leading,
    this.titleStyle,
    this.backgroundColor = const Color.fromRGBO(255, 255, 255, 0.05),
    this.onBack,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      leading: leading ?? IconButton(
        icon: Image.asset(
          'images/back.png',
          height: 40,
          width: 40,
          package: 'tencent_cloud_chat_uikit',
        ),
        onPressed: onBack ?? () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: titleStyle ??
            const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
