import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_app_bar.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_screen.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/time_ago.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/main.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/tim_uikit_chat_file_elem.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';

enum SearchResultType { file, link, sound }

class SearchResultWidget extends StatefulWidget {
  final List<V2TimMessage> messageList;
  final SearchResultType type;

  const SearchResultWidget(
      {super.key, required this.messageList, required this.type});

  @override
  State<SearchResultWidget> createState() => _SearchResultWidgetState();
}

class _SearchResultWidgetState
    extends TIMUIKitState<SearchResultWidget> {
  Map<String, List<V2TimMessage>>? messageResult;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    groupMessagesByMonth();
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final TUIChatSeparateViewModel model =
        Provider.of<TUIChatSeparateViewModel>(context);
    return TUIKitScreenUtils.getDeviceWidget(
        context: context,
        desktopWidget: Placeholder(),
        defaultWidget: ChatBaseScreen(
            safeAreaTop: false,
            safeAreaBottom: false,
            backgroundColor: Colors.transparent,
            backgroundImage: AidaBaseColors.baseBackgroundImage,
            appBar: ChatBaseAppBar(
              title: (widget.type == SearchResultType.file)
                  ? TIM_t("文件")
                  : (widget.type == SearchResultType.link)
                      ? TIM_t("链接")
                      : (widget.type == SearchResultType.sound)
                          ? TIM_t("音频")
                          : '',
            ),
            body: ListView.builder(
              itemCount: messageResult?.keys.length,
              itemBuilder: (_, superIndex) {
                final keys = messageResult?.keys.toList() ?? [];
                final key = keys[superIndex];
                final result = messageResult?[key];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key,
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: result?.length,
                        itemBuilder: (_, index) {
                          V2TimMessage message = result![index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 16,
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    margin: const EdgeInsets.only(right: 10),
                                    child: Avatar(
                                      borderRadius: BorderRadius.circular(12),
                                      faceUrl: message.faceUrl ?? "",
                                      showName: _getShowName(message),
                                      type: 1,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _getShowName(message),
                                      style: const TextStyle(
                                          color: AidaBaseColors.white,
                                          fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    TimeAgo().getTimeStringForChat(
                                            message.timestamp as int) ??
                                        "",
                                    style: const TextStyle(
                                        color: AidaBaseColors.white,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              if (widget.type == SearchResultType.file)
                                TIMUIKitFileElem(
                                  chatModel: model,
                                  message: result[index],
                                  messageID: result[index].msgID,
                                  fileElem: result[index].fileElem,
                                  isSelf: false,
                                  isShowJump: false,
                                  isShowMessageReaction: false,
                                ),
                              if (widget.type == SearchResultType.link)
                                TIMUIKitTextElem(
                                  chatModel: model,
                                  message: message,
                                  isFromSelf: false,
                                  clearJump: () {},
                                  isShowJump: false,
                                  isShowMessageReaction: false,
                                ),
                              if (widget.type == SearchResultType.sound)
                                TIMUIKitSoundElem(
                                  chatModel: model,
                                  message: result[index],
                                  msgID: result[index].msgID!,
                                  soundElem: result[index].soundElem!,
                                  isFromSelf: false,
                                  isShowJump: false,
                                  isShowMessageReaction: false,
                                ),
                            ],
                          );
                        },
                      )
                    ],
                  ),
                );
              },
            )));
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

  _getShowName(V2TimMessage message) {
    String showName = message.sender ?? "";
    if (message.nameCard != null && message.nameCard!.isNotEmpty) {
      showName = message.nameCard!;
    } else if (message.friendRemark != null &&
        message.friendRemark!.isNotEmpty) {
      showName = message.friendRemark!;
    } else if (message.nickName != null && message.nickName!.isNotEmpty) {
      showName = message.nickName!;
    }
    return showName;
  }
}
