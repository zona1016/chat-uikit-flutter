import 'dart:async';
import 'dart:math';
import 'dart:convert';

// import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/constants/history_message_constant.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/self_destruct_queue.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/sound_record.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';

import 'TIMUIKitMessageReaction/tim_uikit_message_reaction_show_panel.dart';

class TIMUIKitSoundElem extends StatefulWidget {
  final V2TimMessage message;
  final V2TimSoundElem soundElem;
  final String msgID;
  final bool isFromSelf;
  final int? localCustomInt;
  final bool isShowJump;
  final VoidCallback? clearJump;
  final TextStyle? fontStyle;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? textPadding;
  final bool? isShowMessageReaction;
  final TUIChatSeparateViewModel chatModel;

  const TIMUIKitSoundElem(
      {Key? key,
      required this.soundElem,
      required this.msgID,
      required this.isFromSelf,
      this.isShowJump = false,
      this.clearJump,
      this.localCustomInt,
      this.fontStyle,
      this.borderRadius,
      this.backgroundColor,
      this.textPadding,
      required this.message,
      this.isShowMessageReaction,
      required this.chatModel})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitSoundElemState();
}

class _TIMUIKitSoundElemState extends TIMUIKitState<TIMUIKitSoundElem> {
  final int charLen = 8;
  bool isPlaying = false;
  bool isOpen = false;
  StreamSubscription<Object>? subscription;
  bool isShowJumpState = false;
  bool isSelfDestruct = false;
  bool isShining = false;
  final TUIChatGlobalModel globalModel = serviceLocator<TUIChatGlobalModel>();
  final MessageService _messageService = serviceLocator<MessageService>();
  late V2TimSoundElem stateElement = widget.message.soundElem!;

  final SelfDestructQueue _selfDestructQueue = SelfDestructQueue();
  bool _isViewed = false;
  int _remainingSeconds = SelfDestructQueue().currentBurnSeconds;

  _playSound() async {
    if (!SoundPlayer.isInit) {
      SoundPlayer.initSoundPlayer();
    }
    if (widget.localCustomInt == null ||
        widget.localCustomInt != HistoryMessageDartConstant.read) {
      globalModel.setLocalCustomInt(widget.msgID,
          HistoryMessageDartConstant.read, widget.chatModel.conversationID);
    }
    if (isPlaying) {
      SoundPlayer.stop();
      widget.chatModel.currentPlayedMsgId = "";
    } else {
      SoundPlayer.play(url: stateElement.url!);
      widget.chatModel.currentPlayedMsgId = widget.msgID;
    }
  }

  downloadMessageDetailAndSave() async {
    if (widget.message.msgID != null && widget.message.msgID != '') {
      if (widget.message.soundElem!.url == null ||
          widget.message.soundElem!.url == '') {
        final response = await _messageService.getMessageOnlineUrl(
            msgID: widget.message.msgID!);
        if (response.data != null) {
          widget.message.soundElem = response.data!.soundElem;
          Future.delayed(const Duration(microseconds: 10), () {
            setState(() => stateElement = response.data!.soundElem!);
          });
        }
      }
      if (!PlatformUtils().isWeb) {
        if (widget.message.soundElem!.localUrl == null ||
            widget.message.soundElem!.localUrl == '') {
          _messageService.downloadMessage(
              msgID: widget.message.msgID!,
              messageType: 4,
              imageType: 0,
              isSnapshot: false);
        }
      }
    }
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      isPlaying = widget.chatModel.currentPlayedMsgId != '' &&
          widget.chatModel.currentPlayedMsgId == widget.msgID;
    });
  }

  @override
  void initState() {
    super.initState();
    _selfDestructQueue.chatModel = widget.chatModel;
    _setupCallbacks();

    // debugPrint('CUSTOM DATA ' + (widget.message.cloudCustomData ?? 'NOTHING'));
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
    subscription = SoundPlayer.playStateListener(listener: (PlayerState state) {
      if (state.processingState == ProcessingState.completed) {
        widget.chatModel.currentPlayedMsgId = "";
        _viewMessage();
        setState(() {
          isOpen = true;
        });
      }
    });

    downloadMessageDetailAndSave();
  }

  void _onCountdownUpdate(String msgID, int remaining) {
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
    // _selfDestructQueue.onCountdownUpdate = (msgID, remaining) {
    //   if (msgID == widget.message.msgID && mounted) {
    //     setState(() {
    //       _remainingSeconds = remaining;
    //     });
    //   }
    // };

    // _selfDestructQueue.onMessageDeleted = (msgID) {
    //   if (msgID == widget.message.msgID) {
    //     //widget.onDeleted?.call();
    //   }
    // };
    _selfDestructQueue.addCountdownListener(_onCountdownUpdate);
    _selfDestructQueue.addMessageDeletedListener(_onMessageDeleted);
  }

  void _viewMessage() {
    if (!_isViewed && widget.message.msgID != null) {
      final globalModel = serviceLocator<TUIChatGlobalModel>();
      final conversationID = widget.message.groupID != null ? 
                           'group_${widget.message.groupID}' : 
                           'c2c_${TencentUtils.checkString(widget.message.userID) ?? TencentUtils.checkString(widget.message.sender)}';
      final burnSeconds = globalModel.getConversationBurnSeconds(conversationID);
      
      setState(() {
        _isViewed = true;
        _remainingSeconds = burnSeconds;
      });
      _selfDestructQueue.viewMessage(widget.message.msgID!, widget.message, 
          conversationBurnSeconds: burnSeconds);
    }
  }

  /// Check if group message is read by all members using centralized utility
  bool _isGroupMessageReadByAll() {
    return MessageReceiptUtils.isGroupMessageReadByAllWithSelfDestruct(
      message: widget.message,
      chatModel: widget.chatModel,
      onSelfDestructTrigger: (msgID, message, {conversationBurnSeconds}) {
        if (isSelfDestruct) {
          debugPrint('Group sound message $msgID read by all members, adding to self-destruct queue');
          _selfDestructQueue.viewMessage(msgID, message, conversationBurnSeconds: conversationBurnSeconds);
        }
      },
    );
  }

  @override
  void dispose() {
    _selfDestructQueue.removeCountdownListener(_onCountdownUpdate);
    _selfDestructQueue.removeMessageDeletedListener(_onMessageDeleted);
    if (isPlaying) {
      SoundPlayer.stop();
      widget.chatModel.currentPlayedMsgId = "";
    }
    subscription?.cancel();
    super.dispose();
  }

  double _getSoundLen() {
    double soundLen = 32;
    if (stateElement.duration != null) {
      final realSoundLen = stateElement.duration!;
      int sdLen = 32;
      if (realSoundLen > 10) {
        sdLen = 12 * charLen + ((realSoundLen - 10) * charLen / 0.5).floor();
      } else if (realSoundLen > 2) {
        sdLen = 2 * charLen + realSoundLen * charLen;
      }
      sdLen = min(sdLen, 20 * charLen);
      soundLen = sdLen.toDouble();
    }

    return soundLen;
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
    widget.clearJump!();
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;

    final backgroundColor = widget.isFromSelf
        ? AidaBaseColors.primaryColor
        : AidaBaseColors.whiteWithOpacity01;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

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
          widget.clearJump!();
        }
      }
    }
    return GestureDetector(
      onTap: () => _playSound(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: widget.textPadding ?? const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isShowJumpState
                  ? const Color.fromRGBO(245, 166, 35, 1)
                  : (widget.backgroundColor ?? backgroundColor),
              borderRadius: widget.borderRadius ?? borderRadius,
            ),
            constraints: const BoxConstraints(maxWidth: 240),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.isFromSelf
                      ? [
                          Container(width: _getSoundLen()),
                          Text(
                            "''${stateElement.duration} ",
                            style: isDesktopScreen
                                ? widget.fontStyle
                                : const TextStyle(color: Color(0xFFFFFFFF)),
                          ),
                          isPlaying
                              ? Image.asset(
                                  'images/play_voice_send.gif',
                                  package: 'tencent_cloud_chat_uikit',
                                  width: 16,
                                  height: 16,
                                )
                              : Image.asset('images/voice_send.png',
                                  package: 'tencent_cloud_chat_uikit',
                                  width: 16,
                                  height: 16,
                                  color: isDesktopScreen
                                      ? null
                                      : const Color(0xFFFFFFFF)),
                        ]
                      : [
                          isPlaying
                              ? Image.asset(
                                  'images/play_voice_receive.gif',
                                  package: 'tencent_cloud_chat_uikit',
                                  width: 16,
                                  height: 16,
                                )
                              : Image.asset(
                                  'images/voice_receive.png',
                                  width: 16,
                                  height: 16,
                                  package: 'tencent_cloud_chat_uikit',
                                ),
                          Text(
                            " ${stateElement.duration}''",
                            style: isDesktopScreen
                                ? widget.fontStyle
                                : const TextStyle(color: AidaBaseColors.white),
                          ),
                          Container(width: _getSoundLen()),
                        ],
                ),
                if (widget.isShowMessageReaction ?? true)
                  TIMUIKitMessageReactionShowPanel(
                    message: widget.message,
                  )
              ],
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
                    style: const TextStyle(
                        color: AidaBaseColors.selfDestructMode))),
          if (isSelfDestruct && 
            widget.message.isSelf! && 
            ((widget.message.userID != null && 
              widget.message.isPeerRead != null && 
              widget.message.isPeerRead!) ||
            (widget.message.groupID != null && 
              _isGroupMessageReadByAll())))
          Positioned(
              bottom: 0,
              left: -25,
              child: Text('${_remainingSeconds}s',
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(color: AidaBaseColors.selfDestructMode))),
        ],
      ),
    );
  }
}
