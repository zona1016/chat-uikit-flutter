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
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/tim_uikit_chat_file_elem.dart';

class SearchFileResultWidget extends StatefulWidget {
  final List<V2TimMessage> messageList;

  const SearchFileResultWidget({super.key, required this.messageList});

  @override
  State<SearchFileResultWidget> createState() => _SearchFileResultWidgetState();
}

class _SearchFileResultWidgetState extends TIMUIKitState<SearchFileResultWidget> {

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
    final TUIChatSeparateViewModel model = Provider.of<TUIChatSeparateViewModel>(context);
    return TUIKitScreenUtils.getDeviceWidget(
        context: context,
        desktopWidget: Placeholder(),
        defaultWidget: ChatBaseScreen(
            safeAreaTop: false,
            safeAreaBottom: false,
            backgroundColor: Colors.transparent,
            backgroundImage: AidaBaseColors.baseBackgroundImage,
            appBar: ChatBaseAppBar(
              title: TIM_t("文件"),
            ),
            body: ListView.builder(
              itemCount: messageResult?.keys.length,
              itemBuilder: (_, superIndex) {
                final keys = messageResult?.keys.toList() ?? [];
                final key = keys[superIndex];
                final result = messageResult?[key];
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: result?.length,
                  itemBuilder: (_, index) {
                    return TIMUIKitFileElem(
                      chatModel: model,
                      message: result![index],
                      messageID: result[index].msgID,
                      fileElem: result[index].fileElem,
                      isSelf: false,
                      isShowJump: false,
                      isShowMessageReaction: false,
                    );
                  },
                );
              },
            ),
        ));
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
}
