import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/tim_uikit_wide_modal_operation_key.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitGroupProfile/widgets/chat_bottom_sheet_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitGroupProfile/widgets/group_add_opt_widget.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/column_menu.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:tencent_im_base/tencent_im_base.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';



import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';

class GroupProfileAddOpt extends TIMUIKitStatelessWidget {
  GroupProfileAddOpt({Key? key}) : super(key: key);

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final model = Provider.of<TUIGroupProfileModel>(context);
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

    String addOpt = TIM_t("未知");

    final groupAddOpt = model.groupInfo?.groupAddOpt;
    switch (groupAddOpt) {
      case GroupAddOptType.V2TIM_GROUP_ADD_ANY:
        addOpt = TIM_t("自动审批");
        break;
      case GroupAddOptType.V2TIM_GROUP_ADD_AUTH:
        addOpt = TIM_t("管理员审批");
        break;
      case GroupAddOptType.V2TIM_GROUP_ADD_FORBID:
        addOpt = TIM_t("禁止加群");
        break;
    }

    final actionList = [
      {"label": TIM_t("禁止加群"), "id": GroupAddOptType.V2TIM_GROUP_ADD_FORBID},
      {"label": TIM_t("自动审批"), "id": GroupAddOptType.V2TIM_GROUP_ADD_ANY},
      {"label": TIM_t("管理员审批"), "id": GroupAddOptType.V2TIM_GROUP_ADD_AUTH}
    ];

    _handleActionTap(int addOpt) async {
      model.setGroupAddOpt(addOpt).then((res) {});
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.only(bottom: isDesktopScreen ? 0 : 1),
      decoration: BoxDecoration(
          color: AidaBaseColors.whiteWithOpacity01,
      ),
      child: InkWell(
        onTapDown: (details) async {
          if(isDesktopScreen){
            TUIKitWidePopup.showPopupWindow(
                operationKey: TUIKitWideModalOperationKey.groupAddOpt,
                isDarkBackground: false,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                context: context,
                offset: Offset(min(details.globalPosition.dx,
                    MediaQuery.of(context).size.width - 186), details.globalPosition.dy),
                child: (onClose) => TUIKitColumnMenu(
                  data: [
                    ...actionList
                        .map((e){
                       return ColumnMenuItem(label: e["label"] as String, onClick: (){
                         _handleActionTap(e["id"] as int);
                         onClose();
                       });
                    }),
                  ],
                )
            );
          }else{
            ChatBottomSheetUtils.showBaseBottomSheet(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              title: TIM_t("加群方式"),
              isDynamicHeight: true,
              context: context,
              showCancel: false,
              backgroundColor: AidaBaseColors.black,
              child: GroupAddOptWidget(
                callback: (type) {
                  _handleActionTap(type);
                },
              ),
            );
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              TIM_t("加群方式"),
              style: TextStyle(fontSize: isDesktopScreen ? 14 : 16, color: AidaBaseColors.white),
            ),
            Row(
              children: [
                Text(
                  addOpt,
                  style: TextStyle(fontSize: isDesktopScreen ? 14 : 16, color: AidaBaseColors.weakTextColor),
                ),
                const Icon(Icons.keyboard_arrow_right, color: AidaBaseColors.weakTextColor)
              ],
            )
          ],
        ),
      ),
    );
  }
}
