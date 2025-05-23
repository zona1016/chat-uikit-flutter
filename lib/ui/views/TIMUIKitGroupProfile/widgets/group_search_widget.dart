import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_screen.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitSearch/group_message_search.dart';

class GroupSearchWidget extends StatefulWidget {
  const GroupSearchWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => GroupSearchWidgetState();
}

class GroupSearchWidgetState extends TIMUIKitState<GroupSearchWidget> {
  bool isShowManageBox = false;

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    final model = Provider.of<TUIGroupProfileModel>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: AidaBaseColors.whiteWithOpacity01,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              final isDesktopScreen =
                  TUIKitScreenUtils.getFormFactor(context) ==
                      DeviceType.Desktop;
              if (!isDesktopScreen) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatBaseScreen(
                          safeAreaTop: true,
                          safeAreaBottom: false,
                          backgroundColor: Colors.transparent,
                          backgroundImage: AidaBaseColors.baseBackgroundImage,
                          body: GroupMessageSearch(
                            model: model,
                          )),
                    ));
              } else {
                setState(() {
                  isShowManageBox = !isShowManageBox;
                });
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TIM_t("消息历史"),
                  style: TextStyle(
                      fontSize: isDesktopScreen ? 14 : 16,
                      color: AidaBaseColors.white),
                ),
                AnimatedRotation(
                  turns: isShowManageBox ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_right,
                      color: theme.weakTextColor),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
