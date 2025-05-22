import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/text_input_bottom_sheet.dart';

import 'package:tencent_im_base/tencent_im_base.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';

import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';

class GroupProfileDetailCard extends TIMUIKitStatelessWidget {
  final V2TimGroupInfo groupInfo;
  final void Function(String groupName)? updateGroupName;
  final TextEditingController controller = TextEditingController();
  final bool isHavePermission;

  GroupProfileDetailCard(
      {Key? key,
      required this.groupInfo,
      this.isHavePermission = false,
      this.updateGroupName})
      : super(key: key);

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final model = Provider.of<TUIGroupProfileModel>(context);
    final faceUrl = groupInfo.faceUrl ?? "";
    final groupID = groupInfo.groupID;
    final showName = groupInfo.groupName ?? groupID;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

    return InkWell(
      onTapDown: !isHavePermission
          ? null
          : ((details) {
              if (isDesktopScreen) {
                TextInputBottomSheet.showTextInputBottomSheet(
                    context: context,
                    title: TIM_t("修改群名称"),
                    initText: showName,
                    initOffset: Offset(
                        min(details.globalPosition.dx,
                            MediaQuery.of(context).size.width - 350),
                        min(details.globalPosition.dy + 20,
                            MediaQuery.of(context).size.height - 470)),
                    onSubmitted: (String newText) async {
                      final text = newText.trim();
                      if (updateGroupName != null) {
                        updateGroupName!(text);
                      } else {
                        model.setGroupName(text);
                      }
                    },
                    theme: theme);
              } else {
                showCupertinoModalPopup<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return CupertinoActionSheet(
                        cancelButton: Container(
                          color: AidaBaseColors.black.withOpacity(0.8),
                          child: CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.pop(
                                context,
                              );
                            },
                            child: Text(
                              TIM_t("取消"),
                              style: const TextStyle(
                                  color: AidaBaseColors.weakTextColor),
                            ),
                            // isDefaultAction: false,
                          ),
                        ),
                        actions: [
                          Container(
                            color: AidaBaseColors.black.withOpacity(0.8),
                            child: CupertinoActionSheetAction(
                              onPressed: () {
                                controller.text = groupInfo.groupName ?? "";
                                showModalBottomSheet(
                                    isScrollControlled: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    context: context,
                                    builder: (context) {
                                      return Container(
                                        decoration: const BoxDecoration(
                                            color: AidaBaseColors.black,
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(10.0),
                                                topRight:
                                                    Radius.circular(10.0))),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 20),
                                              child: Text(
                                                TIM_t("修改群名称"),
                                                style: const TextStyle(
                                                    color:
                                                        AidaBaseColors.white),
                                              ),
                                            ),
                                            const Divider(
                                                height: 2,
                                                color: AidaBaseColors.black),
                                            Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                        color: AidaBaseColors
                                                            .inputFillColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15)),
                                                    child: Center(
                                                      child: Row(
                                                        children: [
                                                          TextField(
                                                            style: const TextStyle(
                                                                color:
                                                                    AidaBaseColors
                                                                        .white),
                                                            controller:
                                                                controller,
                                                            decoration:
                                                                const InputDecoration(
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              fillColor:
                                                                  AidaBaseColors
                                                                      .inputFillColor,
                                                              filled: true,
                                                              isDense: true,
                                                              hintText: '',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Text(
                                                    TIM_t("修改群名称"),
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        color: AidaBaseColors
                                                            .weakTextColor),
                                                    textAlign: TextAlign.left,
                                                  ),
                                                  const SizedBox(
                                                    height: 30,
                                                  ),
                                                  SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          final text =
                                                              controller.text
                                                                  .trim();
                                                          if (updateGroupName !=
                                                              null) {
                                                            updateGroupName!(
                                                                text);
                                                          } else {
                                                            model.setGroupName(
                                                                text);
                                                          }
                                                          Navigator.pop(
                                                              context);
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: Text(
                                                          TIM_t("确定"),
                                                          style: const TextStyle(
                                                              color: AidaBaseColors
                                                                  .primaryColor),
                                                        ),
                                                      )),
                                                  const SizedBox(
                                                    height: 20,
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        bottom: MediaQuery.of(
                                                                context)
                                                            .viewInsets
                                                            .bottom),
                                                  )
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      );
                                    });
                              },
                              child: Text(
                                TIM_t("修改群名称"),
                                style: const TextStyle(
                                    color: AidaBaseColors.white),
                              ),
                              isDefaultAction: false,
                            ),
                          )
                        ]);
                  },
                );
              }
            }),
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.only(
            top: isDesktopScreen ? 20 : 12,
            bottom: isDesktopScreen ? 20 : 12,
            right: isDesktopScreen ? 16 : 0,
            left: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: isDesktopScreen ? 40 : 48,
              height: isDesktopScreen ? 40 : 48,
              child: Avatar(
                faceUrl: faceUrl,
                showName: showName,
                borderRadius: BorderRadius.circular(isDesktopScreen ? 20 : 24),
                type: 2,
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      showName,
                      style: TextStyle(
                          fontSize: isDesktopScreen ? 15 : 18,
                          color: const Color(0xFF00BBBD),
                          fontWeight: FontWeight.w600),
                    ),
                    SizedBox(
                      height: isDesktopScreen ? 4 : 8,
                    ),
                    Row(
                      children: [
                        SelectableText("ID: $groupID",
                            style: TextStyle(
                                fontSize: isDesktopScreen ? 13 : 13,
                                color: theme.weakTextColor)),
                        GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: groupID));
                              TUIToast.show(content: TIM_t('已复制'));
                            },
                            child: const Icon(
                              Icons.copy,
                              color: AidaBaseColors.primaryColor,
                              size: 16,
                            )),
                      ],
                    )
                  ],
                ),
              ),
            ),
            if (isHavePermission)
              Icon(
                Icons.keyboard_arrow_right,
                color: theme.weakTextColor,
              )
          ],
        ),
      ),
    );
  }
}
