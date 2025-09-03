// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/permission.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/self_destruct_queue.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/TIMUIKitMessageReaction/tim_uikit_message_reaction_wrapper.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/tim_uikit_chat_file_icon.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/textSize.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

class TIMUIKitFileElem extends StatefulWidget {
  final String? messageID;
  final V2TimFileElem? fileElem;
  final bool isSelf;
  final bool isShowJump;
  final VoidCallback? clearJump;
  final V2TimMessage message;
  final bool? isShowMessageReaction;
  final TUIChatSeparateViewModel chatModel;

  const TIMUIKitFileElem(
      {Key? key,
      required this.chatModel,
      required this.messageID,
      required this.fileElem,
      required this.isSelf,
      required this.isShowJump,
      this.clearJump,
      required this.message,
      this.isShowMessageReaction})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitFileElemState();
}

class _TIMUIKitFileElemState extends TIMUIKitState<TIMUIKitFileElem> {
  String filePath = "";
  bool isWebDownloading = false;
  final TUIChatGlobalModel model = serviceLocator<TUIChatGlobalModel>();
  int downloadProgress = 0;
  V2TimAdvancedMsgListener? advancedMsgListener;
  final GlobalKey containerKey = GlobalKey();
  double? containerHeight;
  bool? _downloadFailed = false;

  final SelfDestructQueue _selfDestructQueue = SelfDestructQueue();
  bool _isViewed = false;
  int _remainingSeconds = SelfDestructQueue().currentBurnSeconds;
  bool isSelfDestruct = false;
  bool isOpen = false;

  @override
  void dispose() {
    _selfDestructQueue.removeCountdownListener(_onCountdownUpdate);
    _selfDestructQueue.removeMessageDeletedListener(_onMessageDeleted);
    if (advancedMsgListener != null) {
      TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .removeAdvancedMsgListener(listener: advancedMsgListener);
      advancedMsgListener = null;
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selfDestructQueue.chatModel = widget.chatModel;
    _setupCallbacks();

    // debugPrint('CUSTOM DATA TEXT ${widget.message.msgID} ' + (widget.message.cloudCustomData ?? 'NOTHING'));
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
    if (!PlatformUtils().isWeb) {
      Future.delayed(const Duration(microseconds: 10), () {
        hasFile();
      });
    }
  }

  _openMessage() {
    _viewMessage();
    setState(() {
      isOpen = true;
    });
  }

  void _onCountdownUpdate(String msgID, int remaining) {
    // debugPrint('remaining seconds $remaining for msg id $msgID');
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
    if (!_isViewed && widget.message.msgID != null && isSelfDestruct && (_downloadFailed == true || downloadProgress == 100)) {
      // debugPrint('view message ${widget.message.msgID}');
      
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

  bool _isGroupMessageReadByAll() {
    return MessageReceiptUtils.isGroupMessageReadByAllWithSelfDestruct(
      message: widget.message,
      chatModel: widget.chatModel,
      onSelfDestructTrigger: (msgID, message, {conversationBurnSeconds}) {
        if (isSelfDestruct) {
          _selfDestructQueue.viewMessage(msgID, message, conversationBurnSeconds: conversationBurnSeconds);
        }
      },
    );
  }

  Future<bool> addAdvancedMsgListenerForDownload() async {
    if(advancedMsgListener != null){
      return false;
    }
    advancedMsgListener = V2TimAdvancedMsgListener(
      onMessageDownloadProgressCallback:
          (V2TimMessageDownloadProgress messageProgress) async {
        if (messageProgress.msgID == widget.message.msgID) {
          if (messageProgress.isError || messageProgress.errorCode != 0) {
            setState(() {
              _downloadFailed = true;
            });
            return;
          }

          if (messageProgress.isFinish) {
            if (mounted) {
              _viewMessage();
              setState(() {
                downloadProgress = 100;
              });

              if (advancedMsgListener != null) {
                TencentImSDKPlugin.v2TIMManager
                    .getMessageManager()
                    .removeAdvancedMsgListener(listener: advancedMsgListener);
                advancedMsgListener = null;
              }
            }
          } else {
            final currentProgress =
            (messageProgress.currentSize / messageProgress.totalSize * 100)
                .floor();
            if (mounted && currentProgress > downloadProgress) {
              setState(() {
                downloadProgress = currentProgress;
              });
            }
          }
        }
      },
    );
    await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .addAdvancedMsgListener(listener: advancedMsgListener!);
    return true;
  }

  Future<String> getSavePath() async {
    String savePathWithAppPath =
        '/storage/emulated/0/Android/data/com.tencent.flutter.tuikit/cache/' +
            (widget.message.msgID ?? "") +
            widget.fileElem!.fileName!;
    return savePathWithAppPath;
  }

  Future<bool> hasFile() async {
    if (PlatformUtils().isWeb) {
      return true;
    }
    String savePath = TencentUtils.checkString(
            model.getFileMessageLocation(widget.messageID)) ??
        TencentUtils.checkString(widget.message.fileElem!.localUrl) ??
        widget.message.fileElem?.path ??
        '';
    File f = File(savePath);
    if (f.existsSync() && widget.messageID != null) {
      filePath = savePath;
      if (downloadProgress != 100) {
        setState(() {
          downloadProgress = 100;
        });
      }
      if (model.getMessageProgress(widget.messageID) != 100) {
        model.setMessageProgress(widget.messageID!, 100);
      }
      if (advancedMsgListener != null) {
        TencentImSDKPlugin.v2TIMManager
            .getMessageManager()
            .removeAdvancedMsgListener(listener: advancedMsgListener);
        advancedMsgListener = null;
      }
      return true;
    }
    return false;
  }

  String showFileSize(int fileSize) {
    if (fileSize < 1024) {
      return fileSize.toString() + "B";
    } else if (fileSize < 1024 * 1024) {
      return (fileSize / 1024).toStringAsFixed(2) + "KB";
    } else if (fileSize < 1024 * 1024 * 1024) {
      return (fileSize / 1024 / 1024).toStringAsFixed(2) + "MB";
    } else {
      return (fileSize / 1024 / 1024 / 1024).toStringAsFixed(2) + "GB";
    }
  }

  addUrlToWaitingPath(TUITheme theme) async {
    if (widget.messageID != null) {
      model.addWaitingList(widget.messageID!);
    }
    if (model.getWaitingListLength() == 1) {
      await downloadFile(theme);
    }
  }

  checkIsWaiting() {
    bool res = false;
    try {
      if (widget.messageID!.isNotEmpty) {
        res = model.isWaiting(widget.messageID!);
      }
    } catch (err) {
      // err
    }
    return res;
  }

  downloadFile(TUITheme theme) async {
    if (PlatformUtils().isMobile) {
      if (PlatformUtils().isIOS) {
        if (!await Permissions.checkPermission(
            context, Permission.photosAddOnly.value, theme, false)) {
          return;
        }
      } else {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        if ((androidInfo.version.sdkInt) >= 33) {
        } else {
          var storage = await Permissions.checkPermission(
            context,
            Permission.storage.value,
          );
          if (!storage) {
            return;
          }
        }
      }
    }
    await model.downloadFile();
  }

  Future<bool> hasZeroSize(String filePath) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      return fileSize == 0;
    } catch (e) {
      return false;
    }
  }

  tryOpenFile(context, theme) async {
    if (!PlatformUtils().isWeb &&
        (await hasZeroSize(filePath) || widget.message.status == 3)) {
      onTIMCallback(TIMCallback(
          type: TIMCallbackType.INFO,
          infoRecommendText: "不支持 0KB 文件的传输",
          infoCode: 6660417));

          //consider file corrupted - start disappear timer as well
          _viewMessage();
      return;
    }
    if (PlatformUtils().isMobile) {
      if (PlatformUtils().isIOS) {
        if (!await Permissions.checkPermission(
            context, Permission.photosAddOnly.value, theme!, false)) {
          return;
        }
      } else {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        if ((androidInfo.version.sdkInt) >= 33) {
        } else {
          var storage = await Permissions.checkPermission(
            context,
            Permission.storage.value,
          );
          if (!storage) {
            return;
          }
        }
      }
    }

    try {
      if (PlatformUtils().isDesktop && !PlatformUtils().isWindows) {
        launchUrl(Uri.file(filePath));
      } else {
        OpenFile.open(filePath);
      }
      // ignore: empty_catches
    } catch (e) {
      OpenFile.open(filePath);
    }
  }

  void downloadWebFile(String fileUrl) async {
    if (mounted) {
      setState(() {
        isWebDownloading = true;
      });
    }
    String fileName = Uri.parse(fileUrl).pathSegments.last;
    try {
      http.Response response = await http.get(
        Uri.parse(fileUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      final html.AnchorElement downloadAnchor =
          html.document.createElement('a') as html.AnchorElement;

      final html.Blob blob = html.Blob([response.bodyBytes]);

      downloadAnchor.href = html.Url.createObjectUrlFromBlob(blob);
      downloadAnchor.download = widget.message.fileElem?.fileName ?? fileName;

      downloadAnchor.click();
    } catch (e) {
      html.AnchorElement(
        href: widget.fileElem?.path ?? "",
      )
        ..setAttribute(
            "download", widget.message.fileElem?.fileName ?? fileName)
        ..setAttribute("target", '_blank')
        ..style.display = "none"
        ..click();
    }
    if (mounted) {
      setState(() {
        isWebDownloading = false;
      });
    }
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final received = downloadProgress;
    final fileName = widget.fileElem!.fileName ?? "";
    final fileSize = widget.fileElem!.fileSize;
    final borderRadius = widget.isSelf
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
    String? fileFormat;
    if (widget.fileElem?.fileName != null &&
        widget.fileElem!.fileName!.isNotEmpty) {
      final String fileName = widget.fileElem!.fileName!;
      fileFormat = fileName.split(".")[max(fileName.split(".").length - 1, 0)];
    }
    final RenderBox? containerRenderBox =
        containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (containerRenderBox != null) {
      containerHeight = containerRenderBox.size.height;
    }

    final backgroundColor = widget.message.isSelf!
        ? AidaBaseColors.primaryColor
        : AidaBaseColors.whiteWithOpacity01;

    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (isOpen || widget.message.isSelf! || !isSelfDestruct)
          Row(
            key: containerKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isSelf && isWebDownloading)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  child: LoadingAnimationWidget.threeArchedCircle(
                    color: theme.weakTextColor ?? Colors.grey,
                    size: 20,
                  ),
                ),
              TIMUIKitMessageReactionWrapper(
                  chatModel: widget.chatModel,
                  isShowJump: widget.isShowJump,
                  clearJump: widget.clearJump,
                  isFromSelf: widget.message.isSelf ?? true,
                  isShowMessageReaction: widget.isShowMessageReaction ?? true,
                  message: widget.message,
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        if (PlatformUtils().isWeb) {
                          if (!isWebDownloading) {
                            downloadWebFile(widget.fileElem?.path ?? "");
                          }
                          return;
                        }

                        await addAdvancedMsgListenerForDownload();
                        if (await hasFile()) {
                          if (received == 100) {
                            tryOpenFile(context, theme);
                          } else {
                            onTIMCallback(
                              TIMCallback(
                                type: TIMCallbackType.INFO,
                                infoRecommendText: TIM_t("正在下载中"),
                                infoCode: 6660411,
                              ),
                            );
                          }
                          return;
                        }
                        if (checkIsWaiting()) {
                          onTIMCallback(
                            TIMCallback(
                                type: TIMCallbackType.INFO,
                                infoRecommendText: TIM_t("已加入待下载队列，其他文件下载中"),
                                infoCode: 6660413),
                          );
                          return;
                        } else {
                          await addUrlToWaitingPath(theme);
                        }
                      } catch (e) {
                        onTIMCallback(TIMCallback(
                            type: TIMCallbackType.INFO,
                            infoRecommendText: "文件处理异常",
                            infoCode: 6660416));
                      }
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 72),
                      child: Container(
                        width: 237,
                        decoration: BoxDecoration(
                            color: isDesktopScreen
                                ? theme.weakDividerColor ??
                                    CommonColor.weakDividerColor
                                : widget.isSelf
                                    ? AidaBaseColors.primaryColor
                                    : AidaBaseColors.whiteWithOpacity01,
                            borderRadius: borderRadius),
                        child: Stack(children: [
                          ClipRRect(
                            borderRadius: borderRadius,
                            child: LinearProgressIndicator(
                              minHeight: ((containerHeight) ?? 72) - 6,
                              value: (received == 100 ? 0 : received) / 100,
                              backgroundColor: received == 100
                                  ? widget.isSelf ? AidaBaseColors.primaryColor : AidaBaseColors.whiteWithOpacity01
                                  : AidaBaseColors.weakTextColor,
                              valueColor: AlwaysStoppedAnimation(
                                  widget.isSelf ? AidaBaseColors.primaryColor : AidaBaseColors.primaryColor.withValues(alpha: 0.5)),
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              child: Row(
                                  mainAxisAlignment: widget.isSelf
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          constraints:
                                              const BoxConstraints(maxWidth: 160),
                                          child: LayoutBuilder(
                                            builder: (buildContext, boxConstraints) {
                                              return CustomText(
                                                fileName,
                                                width: boxConstraints.maxWidth,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  color: isDesktopScreen
                                                      ? theme.darkTextColor
                                                      : AidaBaseColors.white,
                                                  fontSize: 16,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        if (fileSize != null)
                                          Text(
                                            showFileSize(fileSize),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: AidaBaseColors.white),
                                          )
                                      ],
                                    )),
                                    TIMUIKitFileIcon(
                                      fileFormat: fileFormat,
                                    ),
                                  ])),
                        ]),
                      ),
                    ),
                  )),
              if (!widget.isSelf && isWebDownloading)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  child: LoadingAnimationWidget.threeArchedCircle(
                    color: theme.weakTextColor ?? Colors.grey,
                    size: 20,
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
              padding: EdgeInsets.all(isDesktopScreen ? 12 : 10),
              decoration: BoxDecoration(
                color: backgroundColor,
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
                        TIM_t("点击查看"),
                        style: TextStyle(
                            color: isDesktopScreen
                                ? Colors.black
                                : AidaBaseColors.white),
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'images/vanish_file.png',
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
    );
  }
}
