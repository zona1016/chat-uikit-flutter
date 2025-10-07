import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_image.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/constants/history_message_constant.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/common_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/image_hero.dart';

class MultiImageScreen extends StatefulWidget {
  final List<V2TimMessage> images;
  final int initialIndex;
  final Future<void> Function(V2TimMessage message) downloadFn;

  const MultiImageScreen({
    Key? key,
    required this.images,
    required this.initialIndex,
    required this.downloadFn,
  }) : super(key: key);

  @override
  State<MultiImageScreen> createState() => _MultiImageScreenState();
}

class _MultiImageScreenState extends State<MultiImageScreen> {
  late int _currentIndex;
  late ExtendedPageController _pageController;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = ExtendedPageController(initialPage: widget.initialIndex, pageSpacing: 50, shouldIgnorePointerWhenScrolling: true);
    serviceLocator<CoreServicesImpl>().onCallback =
        (TIMCallback callbackValue) {
      if (callbackValue.type == TIMCallbackType.INFO &&
          (callbackValue.infoCode == 6660406 ||
              callbackValue.infoCode == 6660407)) {
        TUIToast.show(
            content: callbackValue.infoRecommendText ?? '',
            gravity: TUIGravity.top);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
            Navigator.pop(context);
          }
        },
        child: ExtendedImageGesturePageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final message = widget.images[index];
          final imageElem = message.imageElem;
          final smallImg = getImageFromList(
              V2TimImageTypesEnum.small, imageElem?.imageList);
          final originalImg = getImageFromList(
              V2TimImageTypesEnum.original, imageElem?.imageList);
      
          Widget imageWidget;
      
          try {
            // ✅ 第一优先：自己发送的图片本地路径
            if (imageElem?.path != null &&
                imageElem!.path!.isNotEmpty &&
                File(imageElem.path!).existsSync()) {
              imageWidget = ExtendedImage.file(
                File(imageElem.path!),
                fit: BoxFit.contain,
                mode: ExtendedImageMode.gesture,
                enableSlideOutPage: true,
                initGestureConfigHandler: _initGestureConfig,
              );
            }
            // ✅ 第二优先：SDK 下载缓存路径
            else if ((TencentUtils.checkString(smallImg?.localUrl) != null &&
                    File(smallImg!.localUrl!).existsSync()) ||
                (TencentUtils.checkString(originalImg?.localUrl) != null &&
                    File(originalImg!.localUrl!).existsSync())) {
              final path = File(smallImg?.localUrl ?? originalImg!.localUrl!);
              imageWidget = ExtendedImage.file(
                path,
                fit: BoxFit.contain,
                mode: ExtendedImageMode.gesture,
                enableSlideOutPage: true,
                initGestureConfigHandler: _initGestureConfig,
              );
            }
            // ✅ 第三优先：远程图片 URL
            else if ((smallImg?.url ?? originalImg?.url) != null &&
                (smallImg?.url ?? originalImg?.url)!.isNotEmpty) {
              imageWidget = ExtendedImage.network(
                smallImg?.url ?? originalImg!.url!,
                cache: true,
                fit: BoxFit.contain,
                mode: ExtendedImageMode.gesture,
                enableSlideOutPage: true,
                initGestureConfigHandler: _initGestureConfig,
                loadStateChanged: _loadStateChanged,
              );
            } else {
              // ❌ 全部失败，展示错误提示
              imageWidget = const Center(
                child: Icon(Icons.broken_image, color: Colors.white),
              );
            }
          } catch (e) {
            imageWidget = const Center(
              child: Icon(Icons.error_outline, color: Colors.white),
            );
          }
      
          return Stack(
            fit: StackFit.expand,
            children: [
              Center(child: imageWidget),
              Positioned(
                bottom: 40,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () async {
                      debugPrint('Starting image download...');
                      await widget.downloadFn(message);
                      debugPrint('Image download completed.');
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  GestureConfig _initGestureConfig(ExtendedImageState state) {
    return GestureConfig(
      minScale: 1,
      animationMinScale: 1,
      maxScale: 6,
      animationMaxScale: 6.5,
      inertialSpeed: 100.0,
      initialScale: 1.0,
      inPageView: true,
      initialAlignment: InitialAlignment.center,
    );
  }

  Widget? _loadStateChanged(ExtendedImageState state) {
    switch (state.extendedImageLoadState) {
      case LoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadState.failed:
        return const Center(child: Icon(Icons.error, color: Colors.white));
      default:
        return null;
    }
  }

  V2TimImage? getImageFromList(
      V2TimImageTypesEnum imgType, List<V2TimImage?>? imageList) {
    return MessageUtils.getImageFromImgList(
      imageList,
      HistoryMessageDartConstant.imgPriorMap[imgType] ??
          HistoryMessageDartConstant.oriImgPrior,
    );
  }
}
