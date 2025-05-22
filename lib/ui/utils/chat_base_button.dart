import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';

enum ChatBaseButtonType { primary, secondary, custom }

class ChatBaseButton extends StatelessWidget {
  final ChatBaseButtonType type;
  final BorderRadiusGeometry? borderRadius;
  final double? width;
  final double? height;
  final Gradient? gradient;
  final VoidCallback? onPressed;
  final String text;
  final TextStyle? style;
  final BoxDecoration? customDecoration;
  final Color? textColor;
  final double? fontSize;
  final bool isDynamicWidth;
  final bool isCircleShape;
  final Widget? child;
  final bool enabled;
  final BoxDecoration? disabledDecoration;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;
  final Widget? leftIcon;

  const ChatBaseButton({
    super.key,
    this.type = ChatBaseButtonType.primary,
    required this.onPressed,
    required this.text,
    this.borderRadius,
    this.width,
    this.height,
    this.gradient,
    this.style,
    this.textColor,
    this.child,
    this.isDynamicWidth = false,
    this.isCircleShape = false,
    this.customDecoration,
    this.enabled = true,
    this.fontSize,
    this.padding,
    this.icon,
    this.leftIcon,
    this.disabledDecoration,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = this.borderRadius ?? BorderRadius.circular(30);
    return Container(
      width: isDynamicWidth ? null : width ?? double.infinity,
      height: height ?? 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: getButtonDecoration(context, borderRadius),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ButtonStyle(
            padding: WidgetStatePropertyAll(padding ??
                EdgeInsets.symmetric(
                    horizontal: type == ChatBaseButtonType.primary ? 12 : 6)),
            elevation: const WidgetStatePropertyAll(1),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
            overlayColor: const WidgetStatePropertyAll(Colors.black12),
            shape: WidgetStatePropertyAll(isCircleShape
                ? const CircleBorder()
                : RoundedRectangleBorder(borderRadius: borderRadius))),
        child: child ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leftIcon != null) leftIcon!,
                Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: text.contains(' ') || text.contains('\n') ? 2 : 1,
                  style: style ?? getTextStyle(context),
                ),
                if (icon != null) icon!
              ],
            ),
      ),
    );
  }

  TextStyle getTextStyle(BuildContext context) {
    switch (type) {
      case ChatBaseButtonType.primary:
      case ChatBaseButtonType.secondary:
      case ChatBaseButtonType.custom:
        return TextStyle(
            fontSize: fontSize ?? 16,
            height: 1.25,
            color: textColor ?? getTextColor());
    }
  }

  BoxDecoration? getButtonDecoration(
      BuildContext context, BorderRadiusGeometry borderRadius) {
    switch (type) {
      case ChatBaseButtonType.primary:
        return !enabled && disabledDecoration != null
            ? disabledDecoration
            : customDecoration ??
                const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/image/wallet/confirm_bg.png'),
                      fit: BoxFit.fill),
                );
      case ChatBaseButtonType.secondary:
        return !enabled && disabledDecoration != null
            ? disabledDecoration
            : customDecoration ??
                const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/image/wallet/cancel_bg.png'),
                      fit: BoxFit.fill),
                );
      case ChatBaseButtonType.custom:
        return customDecoration;
    }
  }

  Color getTextColor() {
    switch (type) {
      case ChatBaseButtonType.primary:
        return enabled ? AidaBaseColors.white : AidaBaseColors.lightGray;
      case ChatBaseButtonType.secondary:
        return AidaBaseColors.white;
      case ChatBaseButtonType.custom:
        return textColor ?? Colors.white;
    }
  }
}
