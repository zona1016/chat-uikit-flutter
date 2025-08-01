import 'dart:async';
import 'dart:convert';

import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/self_destruct_queue.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitTextField/special_text/DefaultSpecialTextSpanBuilder.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/link_preview/link_preview_entry.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/link_preview/widgets/link_preview.dart';
import 'TIMUIKitMessageReaction/tim_uikit_message_reaction_show_panel.dart';

class TIMUIKitTextElem extends StatefulWidget {
  final V2TimMessage message;
  final bool isFromSelf;
  final bool isShowJump;
  final VoidCallback clearJump;
  final TextStyle? fontStyle;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? textPadding;
  final TUIChatSeparateViewModel chatModel;
  final bool? isShowMessageReaction;
  final bool isUseDefaultEmoji;
  final List<CustomEmojiFaceData> customEmojiStickerList;

  const TIMUIKitTextElem(
      {Key? key,
      required this.message,
      required this.isFromSelf,
      required this.isShowJump,
      required this.clearJump,
      this.fontStyle,
      this.borderRadius,
      this.isShowMessageReaction,
      this.backgroundColor,
      this.textPadding,
      required this.chatModel,
      this.isUseDefaultEmoji = false,
      this.customEmojiStickerList = const []})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitTextElemState();
}

class _TIMUIKitTextElemState extends TIMUIKitState<TIMUIKitTextElem> {
  final SelfDestructQueue _selfDestructQueue = SelfDestructQueue();
  bool _isViewed = false;
  int _remainingSeconds = SelfDestructQueue.burnSeconds;

  bool isSelfDestruct = false;
  bool isOpen = false;
  bool isShowJumpState = false;
  bool isShining = false;

  @override
  void initState() {
    super.initState();
    // get the link preview info
    _selfDestructQueue.chatModel = widget.chatModel;
    _setupCallbacks();
    _getLinkPreview();

    debugPrint('CUSTOM DATA TEXT ${widget.message.msgID} ' + (widget.message.cloudCustomData ?? 'NOTHING'));
    final customData = (widget.message.cloudCustomData?.trim().isNotEmpty ?? false)
        ? jsonDecode(widget.message.cloudCustomData!)
        : {};
    setState(() {
      isSelfDestruct = customData['isSelfDestruct'] ?? false;
      if (widget.message.status == MessageStatus.V2TIM_MSG_STATUS_SEND_SUCC) {
        _isViewed = _selfDestructQueue.isMessageViewed(widget.message.msgID!);
        isOpen = _isViewed;
        _remainingSeconds =
            _selfDestructQueue.getRemainingSeconds(widget.message.msgID!);
      }
    });
  }

  @override
  void didUpdateWidget(TIMUIKitTextElem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.msgID == null && widget.message.msgID != null) {
      _getLinkPreview();
    }
  }

  _openMessage() {
    _viewMessage();
    setState(() {
      isOpen = true;
    });
  }

  void _onCountdownUpdate(String msgID, int remaining) {
    debugPrint('remaining seconds $remaining for msg id $msgID');
    if (msgID == widget.message.msgID && mounted) {
      setState(() {
        _remainingSeconds = remaining;
      });
    }
  }

  void _onMessageDeleted(String msgID) {
    if (msgID == widget.message.msgID) {
      //widget.onDeleted?.call();
    }
  }
  void _setupCallbacks() {
    // _selfDestructQueue.addCountdownListener((msgID, remaining) {
    //   // debugPrint('countdown remaining seconds $remaining s');
    //   debugPrint('current widget msgID: $_currentMsgID vs $msgID');
    //   if (msgID == widget.message.msgID! && mounted) {
    //     debugPrint('Updating UI with remaining: $remaining');
    //     setState(() {
    //       _remainingSeconds = remaining;
    //     });
    //   }
    // });

    // _selfDestructQueue.dele = (msgID) {
    //   if (msgID == _currentMsgID) {
    //     //widget.onDeleted?.call();
    //   }
    // };
    _selfDestructQueue.addCountdownListener(_onCountdownUpdate);
    _selfDestructQueue.addMessageDeletedListener(_onMessageDeleted);
  }

  void _viewMessage() {
    if (!_isViewed) {
      setState(() {
        _isViewed = true;
      });
      debugPrint('view message ${widget.message.msgID}');
      _selfDestructQueue.viewMessage(widget.message.msgID!, widget.message);
    }
  }

  @override
  void dispose() {
    _selfDestructQueue.removeCountdownListener(_onCountdownUpdate);
    _selfDestructQueue.removeMessageDeletedListener(_onMessageDeleted);
    super.dispose();
  }

  _showJumpColor() {
    if ((widget.chatModel.jumpMsgID != widget.message.msgID) &&
        (widget.message.msgID?.isNotEmpty ?? true)) {
      return;
    }
    isShining = true;
    int shineAmount = 6;
    setState(() {
      isShowJumpState = true;
    });
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted) {
        setState(() {
          isShowJumpState = shineAmount.isOdd ? true : false;
        });
      }
      if (shineAmount == 0 || !mounted) {
        isShining = false;
        timer.cancel();
      }
      shineAmount--;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.clearJump();
    });
  }

  // get the link preview info
  _getLinkPreview() {
    if (widget.chatModel.chatConfig.urlPreviewType !=
        UrlPreviewType.previewCardAndHyperlink) {
      return;
    }
    try {
      if (widget.message.localCustomData != null &&
          widget.message.localCustomData!.isNotEmpty) {
        final String localJSON = widget.message.localCustomData!;
        final LocalCustomDataModel? localPreviewInfo =
            LocalCustomDataModel.fromMap(json.decode(localJSON));
        // If [localCustomData] is not empty, check if the link preview info exists
        if (localPreviewInfo == null || localPreviewInfo.isLinkPreviewEmpty()) {
          // If not exists, get it
          _initLinkPreview();
        }
      } else {
        // It [localCustomData] is empty, get the link info
        _initLinkPreview();
      }
    } catch (e) {
      return null;
    }
  }

  _initLinkPreview() async {
    // Get the link preview info from extension, let it update the message UI automatically by providing a [onUpdateMessage].
    // The `onUpdateMessage` can use the `updateMessage()` from the [TIMUIKitChatController] directly.
    LinkPreviewEntry.getFirstLinkPreviewContent(
        message: widget.message,
        onUpdateMessage: (message) {
          widget.chatModel.updateMessageFromController(
              msgID: widget.message.msgID!, message: message);
        });
  }

  Widget? _renderPreviewWidget() {
    // If the link preview info from [localCustomData] is available, use it to render the preview card.
    // Otherwise, it will returns null.
    if (widget.message.localCustomData != null &&
        widget.message.localCustomData!.isNotEmpty) {
      try {
        final String localJSON = widget.message.localCustomData!;
        final LocalCustomDataModel? localPreviewInfo =
            LocalCustomDataModel.fromMap(json.decode(localJSON));
        if (localPreviewInfo != null &&
            !localPreviewInfo.isLinkPreviewEmpty()) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            child:
                // You can use this default widget [LinkPreviewWidget] to render preview card, or you can use custom widget.
                LinkPreviewWidget(linkPreview: localPreviewInfo),
          );
        } else {
          return null;
        }
      } catch (e) {
        return null;
      }
    } else {
      return null;
    }
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    final textWithLink = LinkPreviewEntry.getHyperlinksText(
        widget.message.textElem?.text ?? "",
        widget.chatModel.chatConfig.isSupportMarkdownForTextMessage,
        onLinkTap: widget.chatModel.chatConfig.onTapLink,
        isUseQQPackage: (widget.chatModel.chatConfig.stickerPanelConfig
                    ?.useTencentCloudChatStickerPackage ??
                true) ||
            widget.isUseDefaultEmoji,
        isUseTencentCloudChatPackage: widget.chatModel.chatConfig
                .stickerPanelConfig?.useTencentCloudChatStickerPackage ??
            true,
        customEmojiStickerList: widget.customEmojiStickerList,
        isEnableTextSelection:
            widget.chatModel.chatConfig.isEnableTextSelection ?? false);
    final borderRadius = widget.isFromSelf
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
    if ((widget.chatModel.jumpMsgID == widget.message.msgID)) {}
    if (widget.isShowJump) {
      if (!isShining) {
        Future.delayed(Duration.zero, () {
          _showJumpColor();
        });
      } else {
        if ((widget.chatModel.jumpMsgID == widget.message.msgID) &&
            (widget.message.msgID?.isNotEmpty ?? false)) {
          widget.clearJump();
        }
      }
    }
    final defaultStyle = widget.isFromSelf
        ? AidaBaseColors.primaryColor
        : AidaBaseColors.whiteWithOpacity01;

    final backgroundColor = isShowJumpState
        ? const Color.fromRGBO(245, 166, 35, 1)
        : (defaultStyle ?? widget.backgroundColor);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (isOpen || widget.message.isSelf! || !isSelfDestruct)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: widget.textPadding ??
                    EdgeInsets.all(isDesktopScreen ? 12 : 10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: widget.borderRadius ?? borderRadius,
                ),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // If the [elemType] is text message, it will not be null here.
                    // You can render the widget from extension directly, with a [TextStyle] optionally.
                    widget.chatModel.chatConfig.urlPreviewType !=
                            UrlPreviewType.none
                        ? textWithLink!(
                            style: widget.fontStyle ??
                                TextStyle(
                                    color: isDesktopScreen
                                        ? Colors.black
                                        : AidaBaseColors.white,
                                    fontSize: isDesktopScreen ? 14 : 16,
                                    textBaseline: TextBaseline.ideographic,
                                    height:
                                        widget.chatModel.chatConfig.textHeight))
                        : ExtendedText(widget.message.textElem?.text ?? "",
                            softWrap: true,
                            style: widget.fontStyle ??
                                TextStyle(
                                    fontSize: isDesktopScreen ? 14 : 16,
                                    height:
                                        widget.chatModel.chatConfig.textHeight),
                            specialTextSpanBuilder:
                                DefaultSpecialTextSpanBuilder(
                              isUseQQPackage: (widget
                                          .chatModel
                                          .chatConfig
                                          .stickerPanelConfig
                                          ?.useTencentCloudChatStickerPackage ??
                                      true) ||
                                  widget.isUseDefaultEmoji,
                              isUseTencentCloudChatPackage: widget
                                      .chatModel
                                      .chatConfig
                                      .stickerPanelConfig
                                      ?.useTencentCloudChatStickerPackage ??
                                  true,
                              customEmojiStickerList:
                                  widget.customEmojiStickerList,
                              showAtBackground: true,
                            )),
                    // If the link preview info is available, render the preview card.
                    if (_renderPreviewWidget() != null &&
                        widget.chatModel.chatConfig.urlPreviewType ==
                            UrlPreviewType.previewCardAndHyperlink)
                      _renderPreviewWidget()!,
                    if (widget.isShowMessageReaction ?? true)
                      TIMUIKitMessageReactionShowPanel(message: widget.message)
                  ],
                ),
              ),
            ],
          ),
        if (!isOpen && !widget.message.isSelf! && isSelfDestruct)
          GestureDetector(
            onTap: () {
              _openMessage();
            },
            child: Container(
              padding: widget.textPadding ??
                  EdgeInsets.all(isDesktopScreen ? 12 : 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: widget.borderRadius ?? borderRadius,
              ),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TIM_t("点击查看"),
                        style: TextStyle(
                            color: isDesktopScreen
                                ? Colors.black
                                : AidaBaseColors.white),
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'images/vanish_text.png',
                        package: 'tencent_cloud_chat_uikit',
                        width: 17,
                        height: 15,
                      ),
                      const SizedBox(width: 10),
                    ],
                  )
                ],
              ),
            ),
          ),
        if (isSelfDestruct)
          Positioned(
              top: 0,
              left: widget.message.isSelf! ? -6.5 : null,
              right: !widget.message.isSelf! ? -6.5 : null,
              child: Image.asset(
                'images/vanish_icon.png',
                package: 'tencent_cloud_chat_uikit',
                height: 13,
                width: 13,
              )),
        if (isOpen && isSelfDestruct && !widget.message.isSelf!)
          Positioned(
              bottom: 0,
              right: -25,
              child: Text('${_remainingSeconds}s',
                  style:
                      const TextStyle(color: AidaBaseColors.selfDestructMode))),
        if (widget.message.isPeerRead != null && widget.message.isPeerRead! && isSelfDestruct && widget.message.isSelf!)
          Positioned(
              bottom: 0,
              left: -25,
              child: Text('${_remainingSeconds}s',
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(color: AidaBaseColors.selfDestructMode))),
      ],
    );
  }
}
