import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';

class ChatBaseScreen extends StatelessWidget {
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final Color safeAreaBottomColor;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final SystemUiOverlayStyle statusBarTheme;
  final bool extendBodyBehindAppBar;
  final String? backgroundImage;
  final DecorationImage? decorationBackgroundImage;
  final bool? resizeToAvoidBottomInset;

  const ChatBaseScreen({
    super.key,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.safeAreaBottomColor = Colors.transparent,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.statusBarTheme = SystemUiOverlayStyle.dark,
    this.extendBodyBehindAppBar = false,
    this.backgroundImage,
    this.decorationBackgroundImage,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSoftKeyboardVisible =
        MediaQuery.of(context).viewInsets.bottom > 100;
    final double safeAreaBottomHeight = MediaQuery.of(context).padding.bottom;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Container(
          decoration:
          backgroundImage != null || decorationBackgroundImage != null
              ? BoxDecoration(
              image: decorationBackgroundImage ??
                  DecorationImage(
                      fit: BoxFit.fill,
                      image: AssetImage(backgroundImage!, package: 'tencent_cloud_chat_uikit'),
                      alignment: Alignment.center))
              : null,
          child: Scaffold(
            extendBody: true,
            backgroundColor: backgroundColor ?? AidaBaseColors.whiteGray,
            appBar: appBar,
            drawer: drawer,
            endDrawer: endDrawer,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            body: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: safeAreaBottomColor,
                    height: isSoftKeyboardVisible ? 0 : safeAreaBottomHeight,
                  ),
                ),
                SafeArea(
                  top: safeAreaTop,
                  bottom: safeAreaBottom,
                  child: body,
                )
              ],
            ),
            floatingActionButton: floatingActionButton,
            bottomNavigationBar: bottomNavigationBar,
            extendBodyBehindAppBar: extendBodyBehindAppBar,
          ),
        ),
      ),
    );
  }
}
