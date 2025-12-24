import 'dart:async';
import 'dart:convert';

import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/self_destruct_queue.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitTextField/special_text/DefaultSpecialTextSpanBuilder.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/link_preview/link_preview_entry.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/link_preview/widgets/link_preview.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/mosaic_privacy_overlay.dart';
import 'package:tencent_float_chat_widget/common/models/emoji.dart';
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
  int _remainingSeconds = 0;
  bool _isBurned = false;

  bool isSelfDestruct = false;
  bool isOpen = false;
  bool isShowJumpState = false;
  bool isShining = false;

  @override
  void initState() {
    super.initState();
    _selfDestructQueue.chatModel = widget.chatModel;
    _setupCallbacks();
    _getLinkPreview();

    if (widget.message.msgID != null) {
      _selfDestructQueue.processMessage(widget.message.msgID!, widget.message);

      final conversationID = widget.message.groupID != null
          ? 'group_${widget.message.groupID}'
          : 'c2c_${widget.message.userID ?? widget.message.sender}';
      _selfDestructQueue.preloadConversationBurnSeconds(conversationID);
    }

    setState(() {
      isSelfDestruct = _selfDestructQueue.isSelfDestructMessage(widget.message.msgID ?? '');
      _remainingSeconds = 0;
      _isBurned = widget.message.msgID != null &&
          widget.message.isSelf == true &&
          _selfDestructQueue.isMessageBurned(widget.message.msgID!);
    });

    if (widget.message.status == MessageStatus.V2TIM_MSG_STATUS_SEND_SUCC &&
        widget.message.msgID != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final msgID = widget.message.msgID!;
          _isViewed = _selfDestructQueue.isMessageViewed(msgID);
          isOpen = _isViewed;

          if (isSelfDestruct && !_selfDestructQueue.getRemainingSeconds(msgID).isNegative) {
            _checkAndStartCountdownIfNeeded();
          }

          if (!_isBurned) {
            int remainingSeconds = _selfDestructQueue.getRemainingSeconds(msgID);
            if (remainingSeconds == 0 && isSelfDestruct) {
              final conversationID = widget.message.groupID != null
                  ? 'group_${widget.message.groupID}'
                  : 'c2c_${widget.message.userID ?? widget.message.sender}';
              remainingSeconds = _selfDestructQueue.getExpectedBurnSeconds(conversationID);
            }

            if (mounted) {
              setState(() {
                _remainingSeconds = remainingSeconds;
              });
            }
          }
        }
      });
    }
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
    if (msgID == widget.message.msgID && mounted) {
      setState(() {
        _remainingSeconds = remaining;
      });
    }
  }

  void _onMessageDeleted(String msgID) {
    if (msgID == widget.message.msgID) {}
  }

  void _onMessageBurned(String msgID) {
    if (msgID == widget.message.msgID && mounted) {
      setState(() {
        _isBurned = true;
      });
    }
  }

  void _setupCallbacks() {
    _selfDestructQueue.addCountdownListener(_onCountdownUpdate);
    _selfDestructQueue.addMessageDeletedListener(_onMessageDeleted);
    _selfDestructQueue.addMessageBurnedListener(_onMessageBurned);
  }

  void _checkAndStartCountdownIfNeeded() {
    if (widget.message.msgID == null) return;
    if (_selfDestructQueue.getRemainingSeconds(widget.message.msgID!) > 0) return;

    bool shouldStartCountdown = false;

    if (widget.message.isSelf == true) {
      if (widget.message.groupID == null) {
        shouldStartCountdown = widget.message.isPeerRead == true;
      } else {
        shouldStartCountdown = _isGroupMessageReadByAll();
      }
    }

    if (shouldStartCountdown) {
      if (widget.message.isSelf == true) {
        _selfDestructQueue.handleMessageReadByAll(widget.message.msgID!);
      } else {
        _selfDestructQueue.viewMessage(widget.message.msgID!);
      }
    }
  }

  void _viewMessage() {
    if (!_isViewed && widget.message.msgID != null) {
      _selfDestructQueue.viewMessage(widget.message.msgID!);

      setState(() {
        _isViewed = true;
        int remainingSeconds = _selfDestructQueue.getRemainingSeconds(widget.message.msgID!);
        if (remainingSeconds == 0 && isSelfDestruct) {
          final conversationID = widget.message.groupID != null
              ? 'group_${widget.message.groupID}'
              : 'c2c_${widget.message.userID ?? widget.message.sender}';
          remainingSeconds = _selfDestructQueue.getExpectedBurnSeconds(conversationID);
        }
        _remainingSeconds = remainingSeconds;
      });
    }
  }

  bool _isGroupMessageReadByAll() {
    return MessageReceiptUtils.isGroupMessageReadByAllWithSelfDestruct(
      message: widget.message,
      chatModel: widget.chatModel,
      onSelfDestructTrigger: (msgID, message, {conversationBurnSeconds}) {
        if (isSelfDestruct) {
          final queue = SelfDestructQueue();
          queue.handleMessageReadByAll(msgID);
        }
      },
    );
  }

  @override
  void dispose() {
    _selfDestructQueue.removeCountdownListener(_onCountdownUpdate);
    _selfDestructQueue.removeMessageDeletedListener(_onMessageDeleted);
    _selfDestructQueue.removeMessageBurnedListener(_onMessageBurned);
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
        if (localPreviewInfo == null || localPreviewInfo.isLinkPreviewEmpty()) {
          _initLinkPreview();
        }
      } else {
        _initLinkPreview();
      }
    } catch (e) {
      return null;
    }
  }

  _initLinkPreview() async {
    LinkPreviewEntry.getFirstLinkPreviewContent(
        message: widget.message,
        onUpdateMessage: (message) {
          widget.chatModel.updateMessageFromController(
              msgID: widget.message.msgID!, message: message);
        });
  }

  Widget? _renderPreviewWidget() {
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
            child: LinkPreviewWidget(linkPreview: localPreviewInfo),
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

  // -------------------- Emoji 支持 --------------------
  bool isTUIEmoji(String text) {
    return text.contains('[TUIEmoji');
  }

  Widget buildTextWithEmoji(String text) {
    return ExtendedText(
      text,
      specialTextSpanBuilder: EmojiTextSpanBuilder(),
      style: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }
  // -------------------- Emoji 支持 END --------------------

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

    final originalText = widget.message.textElem?.text ?? "";
    final displayText = _isBurned && widget.message.msgID != null
        ? _selfDestructQueue.getObfuscatedContent(widget.message.msgID!, originalText)
        : originalText;

    final textWithLink = LinkPreviewEntry.getHyperlinksText(
        displayText,
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

    // -------------------- 核心渲染 --------------------
    Widget textWidget;
    if (isTUIEmoji(displayText)) {
      textWidget = buildTextWithEmoji(displayText);
    } else {
      textWidget = widget.chatModel.chatConfig.urlPreviewType !=
          UrlPreviewType.none
          ? textWithLink!(
          style: widget.fontStyle ??
              TextStyle(
                  color: isDesktopScreen
                      ? Colors.black
                      : AidaBaseColors.white,
                  fontSize: isDesktopScreen ? 14 : 16,
                  textBaseline: TextBaseline.ideographic,
                  height: widget.chatModel.chatConfig.textHeight))
          : ExtendedText(displayText,
          softWrap: true,
          style: widget.fontStyle ??
              TextStyle(
                  fontSize: isDesktopScreen ? 14 : 16,
                  height: widget.chatModel.chatConfig.textHeight),
          specialTextSpanBuilder: DefaultSpecialTextSpanBuilder(
            isUseQQPackage: (widget.chatModel.chatConfig.stickerPanelConfig
                ?.useTencentCloudChatStickerPackage ??
                true) ||
                widget.isUseDefaultEmoji,
            isUseTencentCloudChatPackage: widget
                .chatModel.chatConfig
                .stickerPanelConfig
                ?.useTencentCloudChatStickerPackage ??
                true,
            customEmojiStickerList: widget.customEmojiStickerList,
            showAtBackground: true,
          ));
    }
    // -------------------- 核心渲染 END --------------------

    // 原有的 Stack 布局逻辑保持不变
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ---------------- 主气泡 ----------------
        MosaicPrivacyOverlay(
          isVisible:
          !isOpen && isSelfDestruct && widget.message.isSelf! && !_isBurned,
          onTap: _openMessage,
          borderRadius: widget.borderRadius ?? borderRadius,
          vanishIconType: 'text',
          burnSeconds: isSelfDestruct
              ? _selfDestructQueue.getExpectedBurnSeconds(
              widget.message.groupID != null
                  ? 'group_${widget.message.groupID}'
                  : 'c2c_${widget.message.userID ?? widget.message.sender}')
              : null,
          child: Container(
            padding:
            widget.textPadding ?? EdgeInsets.all(isDesktopScreen ? 12 : 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: widget.borderRadius ?? borderRadius,
            ),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textWidget,
                if (_renderPreviewWidget() != null &&
                    widget.chatModel.chatConfig.urlPreviewType ==
                        UrlPreviewType.previewCardAndHyperlink)
                  _renderPreviewWidget()!,
                if (widget.isShowMessageReaction ?? true)
                  TIMUIKitMessageReactionShowPanel(message: widget.message),
              ],
            ),
          ),
        ),

        // ---------------- 🔥 阅后焚火焰图标 ----------------
        if (isSelfDestruct)
          Positioned(
            top: 0,
            left: widget.message.isSelf == true ? -6.5 : null,
            right: widget.message.isSelf == false ? -6.5 : null,
            child: Image.asset(
              'images/vanish_icon.png',
              package: 'tencent_cloud_chat_uikit',
              width: 13,
              height: 13,
            ),
          ),

        // ---------------- ⏱ 接收方倒计时（右侧） ----------------
        if (isOpen && isSelfDestruct && widget.message.isSelf == false)
          Positioned(
            bottom: 0,
            right: -25,
            child: Text(
              '${_remainingSeconds}s',
              style: const TextStyle(
                color: AidaBaseColors.selfDestructMode,
                fontSize: 12,
              ),
            ),
          ),

        // ---------------- ⏱ 发送方倒计时（左侧） ----------------
        if (isSelfDestruct &&
            widget.message.isSelf == true &&
            _remainingSeconds > 0)
          Positioned(
            bottom: 0,
            left: -25,
            child: Text(
              '${_remainingSeconds}s',
              style: const TextStyle(
                color: AidaBaseColors.selfDestructMode,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
