import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/base_network_image.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_app_bar.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_screen.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/image_screen.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/constants/history_message_constant.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/permission.dart';
import 'package:universal_html/html.dart' as html;

class SearchImageVideoResultWidget extends StatefulWidget {
  final List<V2TimMessage> messageList;

  const SearchImageVideoResultWidget({super.key, required this.messageList});

  @override
  State<SearchImageVideoResultWidget> createState() =>
      _SearchImageVideoResultWidgetState();
}

class _SearchImageVideoResultWidgetState
    extends TIMUIKitState<SearchImageVideoResultWidget> {
  Map<String, List<V2TimMessage>>? messageResult;

  final TUIChatGlobalModel model = serviceLocator<TUIChatGlobalModel>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    groupMessagesByMonth();
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    return TUIKitScreenUtils.getDeviceWidget(
        context: context,
        desktopWidget: Placeholder(),
        defaultWidget: ChatBaseScreen(
            safeAreaTop: false,
            safeAreaBottom: false,
            backgroundColor: Colors.transparent,
            backgroundImage: AidaBaseColors.baseBackgroundImage,
            appBar: ChatBaseAppBar(
              title: TIM_t("图片和视频"),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: (messageResult == null)
                  ? [Text('无数据')]
                  : messageResult!.entries.map((entry) {
                      final month = entry.key;
                      final messages = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            month,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: messages.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              return _buildMessageItem(theme, msg);
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
            )));
  }

  Widget _buildMessageItem(TUITheme theme, V2TimMessage msg) {
    if (msg.elemType == 3) {
      final heroTag =
          "${msg.msgID ?? msg.id ?? msg.timestamp ?? DateTime.now().millisecondsSinceEpoch}";

      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) => ImageScreen(
                    imageProvider: CachedNetworkImageProvider(
                      msg.imageElem?.imageList?.first?.url ?? "",
                      cacheKey: msg.msgID,
                    ),
                    heroTag: heroTag,
                    messageID: msg.msgID,
                    downloadFn: () async {
                      await _saveImg(theme, msg);
                    })),
          );
        },
        child: BaseNetworkImage(
          imageURL: msg.imageElem?.imageList?.first?.url ?? '',
        ),
      );
    } else {
      return Stack(
        children: [
          BaseNetworkImage(
            imageURL: msg.videoElem?.videoUrl ?? '',
          ),
          if ((msg.videoElem?.duration ?? 0) > 0)
            const Center(child: Icon(Icons.play_circle, color: Colors.white)),
        ],
      );
    }
  }

  groupMessagesByMonth() {
    Map<String, List<V2TimMessage>> groupedMessages = {};

    for (var message in widget.messageList) {
      int? timestamp = message.timestamp;
      if (timestamp == null) continue;

      DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

      String monthKey = DateFormat('yyyy-MM').format(date);

      groupedMessages.putIfAbsent(monthKey, () => []);
      groupedMessages[monthKey]!.add(message);
    }

    setState(() {
      messageResult = groupedMessages;
    });
  }

  Future<void> _saveImg(TUITheme theme, V2TimMessage message) async {
    try {
      String? imageUrl;
      bool isAssetBool = false;
      final imageElem = message.imageElem;

      if (imageElem != null) {
        final originUrl = getOriginImgURL(message);
        final localUrl = imageElem.imageList?.firstOrNull?.localUrl;
        final filePath = imageElem.path;
        final isWeb = PlatformUtils().isWeb;

        if (!isWeb && filePath != null && File(filePath).existsSync()) {
          imageUrl = filePath;
          isAssetBool = true;
        } else if (localUrl != null &&
            (!isWeb && File(localUrl).existsSync())) {
          imageUrl = localUrl;
          isAssetBool = true;
        } else {
          imageUrl = originUrl;
          isAssetBool = false;
        }
      }

      if (imageUrl != null) {
        return await _saveImageToLocal(
          context,
          message,
          imageUrl,
          isLocalResource: isAssetBool,
          theme: theme,
        );
      }
    } catch (e) {
      onTIMCallback(TIMCallback(
          infoCode: 6660414,
          infoRecommendText: TIM_t("正在下载中"),
          type: TIMCallbackType.INFO));
      return;
    }
  }

  String getOriginImgURL(V2TimMessage message) {
    // 实际拿的是原图
    V2TimImage? img = MessageUtils.getImageFromImgList(
        message.imageElem!.imageList,
        HistoryMessageDartConstant.oriImgPrior);
    return img == null ? message.imageElem!.path! : img.url!;
  }

  Future<void> _saveImageToLocal(
      context,
  V2TimMessage message,
      String imageUrl, {
        bool isLocalResource = true,
        TUITheme? theme,
      }) async {
    if (PlatformUtils().isWeb) {
      download(imageUrl) async {
        final http.Response r = await http.get(Uri.parse(imageUrl));
        final data = r.bodyBytes;
        final base64data = base64Encode(data);
        final a =
        html.AnchorElement(href: 'data:image/jpeg;base64,$base64data');
        a.download = md5.convert(utf8.encode(imageUrl)).toString();
        a.click();
        a.remove();
      }

      download(imageUrl);
      return;
    }

    if (PlatformUtils().isIOS) {
      if (!await Permissions.checkPermission(
          context, Permission.photosAddOnly.value, theme!, false)) {
        return;
      }
    } else {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (PlatformUtils().isMobile) {
        if ((androidInfo.version.sdkInt) >= 33) {
          final photos = await Permissions.checkPermission(
            context,
            Permission.photos.value,
            theme,
          );
          if (!photos) {
            return;
          }
        } else {
          final storage = await Permissions.checkPermission(
            context,
            Permission.storage.value,
          );
          if (!storage) {
            return;
          }
        }
      }
    }

    if (!isLocalResource) {
      if (message.msgID == null || message.msgID!.isEmpty) {
        return;
      }

      if (model.getMessageProgress(message.msgID) == 100) {
        String savePath;
        if (message.imageElem!.path != null &&
            message.imageElem!.path != '' && File(message.imageElem!.path!).existsSync()) {
          savePath = message.imageElem!.path!;
        } else {
          savePath = model.getFileMessageLocation(message.msgID);
        }
        File f = File(savePath);
        if (f.existsSync()) {
          var result = await ImageGallerySaver.saveFile(savePath);

          if (PlatformUtils().isIOS) {
            if (result['isSuccess']) {
              onTIMCallback(TIMCallback(
                  type: TIMCallbackType.INFO,
                  infoRecommendText: TIM_t("图片保存成功"),
                  infoCode: 6660406));
            } else {
              onTIMCallback(TIMCallback(
                  type: TIMCallbackType.INFO,
                  infoRecommendText: TIM_t("图片保存失败"),
                  infoCode: 6660407));
            }
          } else {
            if (result != null) {
              onTIMCallback(TIMCallback(
                  type: TIMCallbackType.INFO,
                  infoRecommendText: TIM_t("图片保存成功"),
                  infoCode: 6660406));
            } else {
              onTIMCallback(TIMCallback(
                  type: TIMCallbackType.INFO,
                  infoRecommendText: TIM_t("图片保存失败"),
                  infoCode: 6660407));
            }
          }
          return;
        }
      } else {
        onTIMCallback(TIMCallback(
            type: TIMCallbackType.INFO,
            infoRecommendText: TIM_t("the message is downloading"),
            infoCode: -1));
      }
      return;
    }

    var result = await ImageGallerySaver.saveFile(imageUrl);

    if (PlatformUtils().isIOS) {
      if (result['isSuccess']) {
        onTIMCallback(TIMCallback(
            type: TIMCallbackType.INFO,
            infoRecommendText: TIM_t("图片保存成功"),
            infoCode: 6660406));
      } else {
        onTIMCallback(TIMCallback(
            type: TIMCallbackType.INFO,
            infoRecommendText: TIM_t("图片保存失败"),
            infoCode: 6660407));
      }
    } else {
      if (result != null) {
        onTIMCallback(TIMCallback(
            type: TIMCallbackType.INFO,
            infoRecommendText: TIM_t("图片保存成功"),
            infoCode: 6660406));
      } else {
        onTIMCallback(TIMCallback(
            type: TIMCallbackType.INFO,
            infoRecommendText: TIM_t("图片保存失败"),
            infoCode: 6660407));
      }
    }
    return;
  }

  Widget errorDisplay(BuildContext context, TUITheme? theme) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          border: Border.all(
            width: 2,
            color: theme?.weakDividerColor ?? Colors.grey,
          )),
      height: 170,
      width: 170,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.staggeredDotsWave(
              color: theme?.weakTextColor ?? Colors.grey,
              size: 28,
            )
          ],
        ),
      ),
    );
  }

  Widget getImage(image, {imageElem}) {
    Widget res = ClipRRect(
      clipper: ImageClipper(),
      child: image,
    );

    return res;
  }
}

class ImageClipper extends CustomClipper<RRect> {
  @override
  RRect getClip(Size size) {
    return RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, min(size.height, 256)),
        const Radius.circular(5));
  }

  @override
  bool shouldReclip(CustomClipper<RRect> oldClipper) {
    return oldClipper != this;
  }
}