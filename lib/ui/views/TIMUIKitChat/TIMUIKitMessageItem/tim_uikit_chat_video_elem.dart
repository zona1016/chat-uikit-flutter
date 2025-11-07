import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/self_destruct_queue.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/TIMUIKitMessageReaction/tim_uikit_message_reaction_wrapper.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/video_screen.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/mosaic_privacy_overlay.dart';
import 'package:url_launcher/url_launcher.dart';

class TIMUIKitVideoElem extends StatefulWidget {
  final V2TimMessage message;
  final bool isFromSelf;
  final bool isShowJump;
  final VoidCallback? clearJump;
  final String? isFrom;
  final TUIChatSeparateViewModel chatModel;
  final bool? isShowMessageReaction;

  const TIMUIKitVideoElem(this.message,
      {Key? key,
      this.isShowJump = false,
      this.clearJump,
      this.isFrom,
      this.isFromSelf = false,
      this.isShowMessageReaction,
      required this.chatModel})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitVideoElemState();
}

class _TIMUIKitVideoElemState extends TIMUIKitState<TIMUIKitVideoElem> {
  final MessageService _messageService = serviceLocator<MessageService>();
  late V2TimVideoElem stateElement = widget.message.videoElem!;

  final SelfDestructQueue _selfDestructQueue = SelfDestructQueue();
  bool _isViewed = false;
  int _remainingSeconds = 0;
  bool _isBurned = false;

  bool isSelfDestruct = false;
  bool isOpen = false;
  bool isCompletedPlay = false; // Track if video playback is completed

  Widget errorDisplay(TUITheme? theme) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
        width: 1,
        color: Colors.black12,
      )),
      height: 100,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: theme?.cautionColor,
              size: 16,
            ),
            Text(
              TIM_t("视频加载失败"),
              style: TextStyle(color: theme?.cautionColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget generateSnapshot(TUITheme theme, int height) {
    if (!PlatformUtils().isWeb) {
      final current = (DateTime.now().millisecondsSinceEpoch / 1000).ceil();
      final timeStamp = widget.message.timestamp ?? current;
      if (current - timeStamp < 300) {
        if (stateElement.snapshotPath != null &&
            stateElement.snapshotPath != '') {
          File imgF = File(stateElement.snapshotPath!);
          bool isExist = imgF.existsSync();
          if (isExist) {
            return Image.file(File(stateElement.snapshotPath!),
                fit: BoxFit.fitWidth);
          }
        }
      }
    }

    if ((stateElement.snapshotUrl == null || stateElement.snapshotUrl == '') &&
        (stateElement.snapshotPath == null ||
            stateElement.snapshotPath == '')) {
      return Container(
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            border: Border.all(
              width: 1,
              color: Colors.black12,
            )),
        height: double.parse(height.toString()),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingAnimationWidget.staggeredDotsWave(
                color: theme.weakTextColor ?? Colors.grey,
                size: 28,
              )
            ],
          ),
        ),
      );
    }
    return (!PlatformUtils().isWeb && stateElement.snapshotUrl == null ||
            widget.message.status == MessageStatus.V2TIM_MSG_STATUS_SENDING)
        ? (stateElement.snapshotPath!.isNotEmpty
            ? Image.file(File(stateElement.snapshotPath!), fit: BoxFit.fitWidth)
            : Image.file(File(stateElement.localSnapshotUrl!),
                fit: BoxFit.fitWidth))
        : (PlatformUtils().isWeb ||
                stateElement.localSnapshotUrl == null ||
                stateElement.localSnapshotUrl == "")
            ? Image.network(stateElement.snapshotUrl!, fit: BoxFit.fitWidth)
            : Image.file(File(stateElement.localSnapshotUrl!),
                fit: BoxFit.fitWidth);
  }

  downloadMessageDetailAndSave() async {
    if (TencentUtils.checkString(widget.message.msgID) != null) {
      if (TencentUtils.checkString(widget.message.videoElem!.videoUrl) ==
          null) {
        final response = await _messageService.getMessageOnlineUrl(
            msgID: widget.message.msgID!);
        if (response.data != null) {
          widget.message.videoElem = response.data!.videoElem;
          Future.delayed(const Duration(microseconds: 10), () {
            setState(() => stateElement = response.data!.videoElem!);
          });
        }
      }
      if (!PlatformUtils().isWeb) {
        if (TencentUtils.checkString(widget.message.videoElem!.localVideoUrl) ==
                null ||
            !File(widget.message.videoElem!.localVideoUrl!).existsSync()) {
          _messageService.downloadMessage(
              msgID: widget.message.msgID!,
              messageType: 5,
              imageType: 0,
              isSnapshot: false);
        }
        if (TencentUtils.checkString(
                    widget.message.videoElem!.localSnapshotUrl) ==
                null ||
            !File(widget.message.videoElem!.localSnapshotUrl!).existsSync()) {
          _messageService.downloadMessage(
              msgID: widget.message.msgID!,
              messageType: 5,
              imageType: 0,
              isSnapshot: true);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selfDestructQueue.chatModel = widget.chatModel;
    _setupCallbacks();
    downloadMessageDetailAndSave();

    // debugPrint('CUSTOM DATA VIDEO ' + (widget.message.cloudCustomData ?? 'NOTHING'));
    // Process message with centralized queue
    if (widget.message.msgID != null) {
      _selfDestructQueue.processMessage(widget.message.msgID!, widget.message);
      
      // Preload conversation burn seconds
      final conversationID = widget.message.groupID != null ? 
                            'group_${widget.message.groupID}' : 
                            'c2c_${widget.message.userID ?? widget.message.sender}';
      _selfDestructQueue.preloadConversationBurnSeconds(conversationID);
    }
    
    // Basic initialization in setState
    setState(() {
      isSelfDestruct = _selfDestructQueue.isSelfDestructMessage(widget.message.msgID ?? '');
      _remainingSeconds = 0; // Initialize with 0, will be updated later
      // Only mark SENDER messages as burned, receivers should always see unopened state
      _isBurned = widget.message.msgID != null &&
                  widget.message.isSelf == true &&
                  _selfDestructQueue.isMessageBurned(widget.message.msgID!);
    });
    
    // Complex logic after setState to avoid widget loading issues
    if (widget.message.status == MessageStatus.V2TIM_MSG_STATUS_SEND_SUCC && 
        widget.message.msgID != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final msgID = widget.message.msgID!;
          _isViewed = _selfDestructQueue.isMessageViewed(msgID);
          isOpen = _isViewed;
          
          // Check if this message should already have countdown based on read status
          if (isSelfDestruct && !_selfDestructQueue.getRemainingSeconds(msgID).isNegative) {
            _checkAndStartCountdownIfNeeded();
          }
          
          // Get current remaining seconds, or expected burn seconds if not started yet
          // BUT: Don't show countdown if message is already burned
          if (!_isBurned) {
            int remainingSeconds = _selfDestructQueue.getRemainingSeconds(msgID);
            if (remainingSeconds == 0 && isSelfDestruct) {
              // If countdown not started yet, show expected burn seconds instead of 0
              final conversationID = widget.message.groupID != null ?
                                    'group_${widget.message.groupID}' :
                                    'c2c_${widget.message.userID ?? widget.message.sender}';
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

  _openMessage() {
    setState(() {
      isOpen = true; // Display the video element so user can play it
    });
    // Note: Do NOT call _viewMessage() here for videos
    // Do NOT set isCompletedPlay = true here
    // Timer should only start after video playback completes
    // _viewMessage() will be called by VideoScreen's onVideoCompleted callback
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

  void _onMessageBurned(String msgID) {
    if (msgID == widget.message.msgID && mounted) {
      setState(() {
        _isBurned = true;
      });
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
    _selfDestructQueue.addMessageBurnedListener(_onMessageBurned);
  }

  void _viewMessage() {
    if (!_isViewed && widget.message.msgID != null) {
      _selfDestructQueue.viewMessage(widget.message.msgID!);
      
      setState(() {
        _isViewed = true;
        isCompletedPlay = true; // Mark video as completed, this will trigger countdown display
        
        // Get current remaining seconds, or expected burn seconds if not started yet
        int remainingSeconds = _selfDestructQueue.getRemainingSeconds(widget.message.msgID!);
        if (remainingSeconds == 0 && isSelfDestruct) {
          // If countdown not started yet (due to retry delay), show expected burn seconds
          final conversationID = widget.message.groupID != null ? 
                                'group_${widget.message.groupID}' : 
                                'c2c_${widget.message.userID ?? widget.message.sender}';
          remainingSeconds = _selfDestructQueue.getExpectedBurnSeconds(conversationID);
        }
        _remainingSeconds = remainingSeconds;
      });
    }
  }

  /// Check if countdown should be started based on message read status
  void _checkAndStartCountdownIfNeeded() {
    if (widget.message.msgID == null) return;
    
    // Skip if countdown already active
    if (_selfDestructQueue.getRemainingSeconds(widget.message.msgID!) > 0) return;
    
    bool shouldStartCountdown = false;
    
    if (widget.message.isSelf == true) {
      // For self messages, check if peer has read it (C2C) or if it's old (group)
      if (widget.message.groupID == null) {
        // C2C message - check peer read status
        shouldStartCountdown = widget.message.isPeerRead == true;
      } else {
        // Group message - check if all members have read it
        shouldStartCountdown = _isGroupMessageReadByAll();
      }
    }
    
    if (shouldStartCountdown) {
      debugPrint('Self group message ${widget.message.msgID} is read by all, starting countdown');
      // Start countdown immediately
      if (widget.message.isSelf == true) {
        _selfDestructQueue.handleMessageReadByAll(widget.message.msgID!);
      } else {
        _selfDestructQueue.viewMessage(widget.message.msgID!);
      }
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

  void launchDesktopFile(String path) {
    if (PlatformUtils().isWindows) {
      OpenFile.open(path);
    } else {
      launchUrl(Uri.file(path));
    }
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final heroTag =
        "${widget.message.msgID ?? widget.message.id ?? widget.message.timestamp ?? DateTime.now().millisecondsSinceEpoch}${widget.isFrom}";

    final backgroundColor = widget.isFromSelf
        ? AidaBaseColors.primaryColor
        : AidaBaseColors.whiteWithOpacity01;

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

    // When burned, show simple 1-line obfuscated text with icon (SENDER ONLY)
    // Receiver should still see "点击播放" unopened state
    if (_isBurned && isSelfDestruct && widget.message.isSelf == true) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AidaBaseColors.primaryColor,
              borderRadius: borderRadius,
            ),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selfDestructQueue.generateObfuscatedText(8),
                  style: const TextStyle(color: AidaBaseColors.white),
                ),
                const SizedBox(width: 10),
                // Image.asset(
                //   'images/vanish_video.png',
                //   package: 'tencent_cloud_chat_uikit',
                //   width: 17,
                //   height: 15,
                // ),
                // const SizedBox(width: 10),
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
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Ensure Stack always has at least one non-positioned child
        // BUT: Show content if message is burned (so user can see random symbols)
        if (!isOpen && isSelfDestruct && widget.message.isSelf! && !_isBurned)
          const SizedBox.shrink(),
        if (isOpen || !isSelfDestruct || _isBurned)
          MosaicPrivacyOverlay(
            isVisible: !isOpen && isSelfDestruct && widget.message.isSelf! && !_isBurned,
            onTap: _openMessage,
            borderRadius: borderRadius,
            vanishIconType: 'video',
            burnSeconds: isSelfDestruct ? _selfDestructQueue.getExpectedBurnSeconds(
              widget.message.groupID != null ?
                'group_${widget.message.groupID}' :
                'c2c_${widget.message.userID ?? widget.message.sender}'
            ) : null,
            child: GestureDetector(
            onTap: () {
              if (PlatformUtils().isWeb) {
                final url = widget.message.videoElem?.videoUrl ??
                    widget.message.videoElem?.videoPath ??
                    "";
                TUIKitWidePopup.showMedia(
                    context: context,
                    mediaURL: url,
                    onClickOrigin: () => launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        ));
                return;
              }
              if (PlatformUtils().isDesktop) {
                final videoElem = widget.message.videoElem;
                if (videoElem != null) {
                  final localVideoUrl =
                      TencentUtils.checkString(videoElem.localVideoUrl);
                  final videoPath =
                      TencentUtils.checkString(videoElem.videoPath);
                  final videoUrl = videoElem.videoUrl;
                  if (localVideoUrl != null) {
                    launchDesktopFile(localVideoUrl);
                    // todo
                    // TUIKitWidePopup.showMedia(
                    //     context: context,
                    //     mediaPath: localVideoUrl,
                    //     onClickOrigin: () => launchDesktopFile(localVideoUrl));
                  } else if (videoPath != null &&
                      File(videoPath).existsSync()) {
                    launchDesktopFile(videoPath);
                    // todo
                    // TUIKitWidePopup.showMedia(
                    //     context: context,
                    //     mediaPath: videoPath,
                    //     onClickOrigin: () => launchDesktopFile(videoPath));
                  } else if (TencentUtils.isTextNotEmpty(videoUrl)) {
                    onTIMCallback(TIMCallback(
                        infoCode: 6660414,
                        infoRecommendText: TIM_t("正在下载中"),
                        type: TIMCallbackType.INFO));
                  }
                }
              } else {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false, // set to false
                    pageBuilder: (_, __, ___) => VideoScreen(
                      message: widget.message,
                      heroTag: heroTag,
                      videoElement: stateElement,
                      onVideoCompleted: _viewMessage,
                    ),
                  ),
                );
              }
            },
            child: Hero(
                tag: heroTag,
                child: TIMUIKitMessageReactionWrapper(
                    chatModel: widget.chatModel,
                    message: widget.message,
                    isShowJump: widget.isShowJump,
                    isShowMessageReaction: widget.isShowMessageReaction ?? true,
                    clearJump: widget.clearJump,
                    isFromSelf: widget.message.isSelf ?? true,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      child: LayoutBuilder(builder:
                          (BuildContext context, BoxConstraints constraints) {
                        double? positionRadio;
                        if ((stateElement.snapshotWidth) != null &&
                            stateElement.snapshotHeight != null &&
                            stateElement.snapshotWidth != 0 &&
                            stateElement.snapshotHeight != 0) {
                          positionRadio = (stateElement.snapshotWidth! /
                              stateElement.snapshotHeight!);
                        }
                        return ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: PlatformUtils().isWeb
                                    ? 300
                                    : constraints.maxWidth * 0.5,
                                maxHeight:
                                    min(constraints.maxHeight * 0.8, 300),
                                minHeight: 20,
                                minWidth: 20),
                            child: Stack(
                              children: <Widget>[
                                if (positionRadio != null &&
                                    (stateElement.snapshotUrl != null ||
                                        stateElement.snapshotUrl != null))
                                  AspectRatio(
                                    aspectRatio: positionRadio,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                          color: Colors.transparent),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Expanded(
                                        child: generateSnapshot(theme,
                                            stateElement.snapshotHeight ?? 100))
                                  ],
                                ),
                                if (widget.message.status !=
                                            MessageStatus
                                                .V2TIM_MSG_STATUS_SENDING &&
                                        (stateElement.snapshotUrl != null ||
                                            stateElement.snapshotPath !=
                                                null) &&
                                        stateElement.videoPath != null ||
                                    stateElement.videoUrl != null)
                                  Positioned.fill(
                                    // alignment: Alignment.center,
                                    child: Center(
                                        child: Image.asset('images/play.png',
                                            package: 'tencent_cloud_chat_uikit',
                                            height: 64)),
                                  ),
                                if (widget.message.videoElem?.duration !=
                                        null &&
                                    widget.message.videoElem!.duration! > 0)
                                  Positioned(
                                      right: 10,
                                      bottom: 10,
                                      child: Text(
                                          MessageUtils.formatVideoTime(widget
                                                  .message.videoElem!.duration!)
                                              .toString(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12))),
                              ],
                            ));
                      }),
                    ))),
          ),
        ),
        if (!isOpen && !widget.message.isSelf! && isSelfDestruct && !_isBurned)
          GestureDetector(
            onTap: () {
              _openMessage();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isFromSelf
                    ? AidaBaseColors.primaryColor
                    : AidaBaseColors.whiteWithOpacity01,
                borderRadius: borderRadius,
              ),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TIM_t("点击播放"),
                        style: const TextStyle(color: AidaBaseColors.white),
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'images/vanish_video.png',
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
        if (isCompletedPlay && isSelfDestruct && !widget.message.isSelf!)
          Positioned(
              bottom: 0,
              right: -25,
              child: Text('${_remainingSeconds}s',
                  style:
                      const TextStyle(color: AidaBaseColors.selfDestructMode))),
        // Show countdown immediately for sender (new behavior)
        if (isSelfDestruct && widget.message.isSelf! && _remainingSeconds > 0)
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
