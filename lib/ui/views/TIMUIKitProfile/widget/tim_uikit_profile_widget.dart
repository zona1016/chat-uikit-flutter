import 'dart:convert';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_class.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/tim_uikit_wide_modal_operation_key.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/controller/tim_uikit_chat_controller.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_button.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitProfile/disappearing_message.dart';

import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/self_destruct_queue.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_profile_view_model.dart';
import 'package:provider/provider.dart';

class TIMUIKitProfileWidget extends TIMUIKitClass {
  static final bool isDesktopScreen =
      TUIKitScreenUtils.getFormFactor() == DeviceType.Desktop;

  static Widget operationDivider(
      {Color? color, double? height, EdgeInsetsGeometry? margin}) {
    return Container(
      color: Colors.transparent,
      margin: margin,
      height: height ?? 10,
    );
  }

  /// Remarks
  static Widget remarkBar(
      BuildContext context,
      String remark,
      Function({Offset? offset, String? initText})? handleTap,
      bool smallCardMode) {
    final GlobalKey key = GlobalKey();
    return InkWell(
      onTapDown: (details) {
        if (handleTap != null) {
          handleTap(
              offset: Offset(
                  min(details.globalPosition.dx,
                      MediaQuery.of(context).size.width - 400),
                  min(details.globalPosition.dy,
                      MediaQuery.of(context).size.height - 100)),
              initText: remark);
        }
      },
      child: TIMUIKitOperationItem(
        smallCardMode: smallCardMode,
        itemBoxKey: key,
        isEmpty: remark.isEmpty,
        wideEditText: TIM_t("设置备注名"),
        operationName: TIM_t("备注名"),
        operationRightWidget:
            Text(remark, textAlign: isDesktopScreen ? null : TextAlign.end),
      ),
    );
  }

  /// add to block list
  static Widget addToBlackListBar(bool value, BuildContext context,
      Function(bool value)? onChanged, bool smallCardMode) {
    return TIMUIKitOperationItem(
      smallCardMode: smallCardMode,
      isEmpty: false,
      operationName: TIM_t("加入黑名单"),
      type: "switch",
      operationValue: value,
      onSwitchChange: (value) {
        if (onChanged != null) {
          onChanged(value);
        }
      },
    );
  }

  /// pin the conversation to the top
  static Widget pinConversationBar(bool value, BuildContext context,
      Function(bool value)? onChanged, bool smallCardMode) {
    return TIMUIKitOperationItem(
      smallCardMode: smallCardMode,
      isEmpty: false,
      operationName: TIM_t("置顶聊天"),
      type: "switch",
      operationValue: value,
      onSwitchChange: (value) {
        if (onChanged != null) {
          onChanged(value);
        }
      },
    );
  }

  /// message disturb
  static Widget messageDisturb(BuildContext context, bool isDisturb,
      Function(bool value)? onChanged, bool smallCardMode) {
    return TIMUIKitOperationItem(
      smallCardMode: smallCardMode,
      isEmpty: false,
      operationName: TIM_t("消息免打扰"),
      type: "switch",
      operationValue: isDisturb,
      onSwitchChange: (value) {
        if (onChanged != null) {
          onChanged(value);
        }
      },
    );
  }

  static Widget disappearingMessage(
      BuildContext context,
      String disappearTime,
      DisappearingMessageConfig config,
      Function() onChanged,
      bool smallCardMode) {
    final GlobalKey key = GlobalKey();
    return InkWell(
      onTap: onChanged,
      child: TIMUIKitOperationItem(
        smallCardMode: smallCardMode,
        itemBoxKey: key,
        isEmpty: disappearTime.isEmpty,
        wideEditText: TIM_t("限时消息"),
        operationName: TIM_t("限时消息"),
        operationRightWidget: Text(config.desc,
            textAlign: isDesktopScreen ? null : TextAlign.end),
      ),
    );
  }

  /// self destruct mode
  static Widget selfDestructMode(BuildContext context, bool isEnabled,
      Function(bool value)? onChanged, bool smallCardMode) {
    return TIMUIKitOperationItem(
      smallCardMode: smallCardMode,
      isEmpty: false,
      operationName: TIM_t("打开阅后即焚模式"),
      type: "switch",
      operationValue: isEnabled,
      onSwitchChange: (value) {
        if (onChanged != null) {
          onChanged(value);
        }
      },
    );
  }

  /// burn seconds time setting for self-destruct mode
  static Widget burnSecondsOption(BuildContext context, String conversationID,
      TUITheme theme, TUIProfileViewModel profileModel, bool smallCardMode,
      {bool isEnabled = true}) {
    String getCurrentBurnSecondsText(int seconds) {
      const burnSecondsOptions = SelfDestructQueue.burnSecondsOptions;
      final entry = burnSecondsOptions.entries.firstWhere(
          (e) => e.value == seconds,
          orElse: () => MapEntry('${seconds}s', seconds));
      return _translateBurnSecondsKey(entry.key);
    }

    return GestureDetector(
      onTap: isEnabled
          ? () {
              _showBurnSecondsSelector(
                  context, conversationID, theme, profileModel);
            }
          : null,
      child: TIMUIKitOperationItem(
        smallCardMode: smallCardMode,
        isEmpty: false,
        operationName: TIM_t("自毁时间"),
        type: "arrow",
        rightIconColor: AidaBaseColors.weakTextColor,
        operationRightWidget: Consumer<TUIProfileViewModel>(
          builder: (context, model, child) {
            return Text(
                textAlign: TextAlign.end,
                getCurrentBurnSecondsText(model.burnSeconds));
          },
        ),
      ),
    );
  }

  static String _translateBurnSecondsKey(String key) {
    switch (key) {
      case '15s':
        return '15${tr("general.second_short")}';
      case '30s':
        return '30${tr("general.second_short")}';
      case '1min':
        return '1${tr("general.minute_short")}';
      default:
        return key;
    }
  }

  static void _showBurnSecondsSelector(
      BuildContext context,
      String conversationID,
      TUITheme theme,
      TUIProfileViewModel profileModel) async {
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

    const burnSecondsOptions = SelfDestructQueue.burnSecondsOptions;

    if (isDesktopScreen) {
      TUIKitWidePopup.showPopupWindow(
          operationKey: TUIKitWideModalOperationKey.custom,
          context: context,
          width: MediaQuery.of(context).size.width * 0.4,
          height: MediaQuery.of(context).size.height * 0.5,
          title: TIM_t("选择自毁时间"),
          child: (onClose) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: burnSecondsOptions.entries.map((entry) {
                final isSelected = entry.value == profileModel.burnSeconds; 
                return ListTile(
                  title: Text(
                      _translateBurnSecondsKey(entry.key),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  trailing: profileModel.burnSeconds == entry.value 
                      ? Icon(Icons.check, color: theme.primaryColor) 
                      : null,
                  onTap: () async {
                    await profileModel.setBurnSeconds(conversationID, entry.value);
                    onClose();
                  },
                );
              }
              ).toList(),
            ),
          ));
    } else {
      showCupertinoModalPopup<String>(
        context: context,
        builder: (BuildContext context) {
          return CupertinoActionSheet(
            title: Text(TIM_t("选择自毁时间")),
            actions: burnSecondsOptions.entries.map((entry) {
              final isSelected = entry.value == profileModel.burnSeconds;
              return CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  await profileModel.setBurnSeconds(conversationID, entry.value);
                },
                child: Text(
                  _translateBurnSecondsKey(entry.key),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? CupertinoColors.systemBlue : null,
                  ),
                ),
                // isDefaultAction: profileModel.burnSeconds == entry.value,
              );
            }).toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(TIM_t("取消")),
              // isDefaultAction: false,
            ),
          );
        },
      );
    }
  }

  static Widget operationItem(
      {required String operationName,
      required String type,
      bool? operationValue,
      String? operationText,
      required bool isEmpty,
      void Function(bool newValue)? onSwitchChange,
      required bool smallCardMode}) {
    return TIMUIKitOperationItem(
      smallCardMode: smallCardMode,
      isEmpty: isEmpty,
      operationName: operationName,
      type: type,
      operationRightWidget: Text(operationText ?? "",
          textAlign: isDesktopScreen ? null : TextAlign.end),
      operationValue: operationValue,
      onSwitchChange: onSwitchChange,
    );
  }

  /// find history message
  static Widget searchBar(
    BuildContext context,
    V2TimConversation conversation,
    bool smallCardMode, {
    Function()? handleTap,
  }) {
    return InkWell(
      onTap: () {
        if (handleTap != null) {
          handleTap();
        }
      },
      child: TIMUIKitOperationItem(
        isEmpty: true,
        wideEditText: TIM_t("立即搜索"),
        operationName: TIM_t("查找聊天内容"),
      ),
    );
  }

  /// portrait
  static Widget portraitBar(Widget portraitWidget, bool smallCardMode) {
    return SizedBox(
      child: TIMUIKitOperationItem(
        smallCardMode: smallCardMode,
        isEmpty: false,
        operationName: TIM_t("头像"),
        operationRightWidget: portraitWidget,
        showAllowEditStatus: false,
      ),
    );
  }

  /// defaultPortraitWidget
  static Widget defaultPortraitWidget(
      V2TimUserFullInfo? userInfo, bool smallCardMode) {
    return SizedBox(
      width: 48,
      height: 48,
      child: userInfo != null
          ? Avatar(
              faceUrl: userInfo.faceUrl ?? "",
              showName: userInfo.nickName ?? "",
              type: 1,
            )
          : Container(),
    );
  }

  /// nickname
  static Widget nicknameBar(
    String nickName,
    bool smallCardMode,
  ) {
    return SizedBox(
      child: TIMUIKitOperationItem(
        smallCardMode: smallCardMode,
        isEmpty: nickName.isEmpty,
        showAllowEditStatus: false,
        operationName: TIM_t("昵称"),
        operationRightWidget:
            Text(nickName, textAlign: isDesktopScreen ? null : TextAlign.end),
      ),
    );
  }

  /// user account
  static Widget userAccountBar(String userNum, bool smallCardMode) {
    return SizedBox(
      child: TIMUIKitOperationItem(
        smallCardMode: smallCardMode,
        isEmpty: false,
        showAllowEditStatus: false,
        operationName: TIM_t("账号"),
        operationRightWidget: SelectableText(userNum,
            textAlign: isDesktopScreen ? null : TextAlign.end),
      ),
    );
  }

  /// signature
  static Widget signatureBar(String signature, bool smallCardMode) {
    return SizedBox(
      child: TIMUIKitOperationItem(
        smallCardMode: smallCardMode,
        isEmpty: false,
        showAllowEditStatus: false,
        operationName: TIM_t("个性签名"),
        operationRightWidget:
            Text(signature, textAlign: isDesktopScreen ? null : TextAlign.end),
      ),
    );
  }

  /// gender
  static Widget genderBar(int gender, bool smallCardMode) {
    Map genderMap = {
      0: TIM_t("未填写"),
      1: TIM_t("男"),
      2: TIM_t("女"),
    };
    return SizedBox(
      child: TIMUIKitOperationItem(
        smallCardMode: smallCardMode,
        isEmpty: false,
        showAllowEditStatus: false,
        operationName: TIM_t("性别"),
        operationRightWidget: Text(genderMap[gender],
            textAlign: isDesktopScreen ? null : TextAlign.end),
      ),
    );
  }

  /// gender
  static Widget genderBarWithArrow(int gender, bool smallCardMode) {
    Map genderMap = {
      0: TIM_t("未填写"),
      1: TIM_t("男"),
      2: TIM_t("女"),
    };
    return SizedBox(
      child: TIMUIKitOperationItem(
        smallCardMode: smallCardMode,
        isEmpty: false,
        operationName: TIM_t("性别"),
        operationRightWidget: Text(genderMap[gender],
            textAlign: isDesktopScreen ? null : TextAlign.end),
      ),
    );
  }

  /// birthday
  static Widget birthdayBar(int? birthday, bool smallCardMode) {
    try {
      final date = DateTime.parse(birthday.toString());
      DateFormat formatter = DateFormat('yyyy-MM-dd');
      return TIMUIKitOperationItem(
        smallCardMode: smallCardMode,
        isEmpty: false,
        showAllowEditStatus: false,
        operationName: TIM_t("生日"),
        operationRightWidget: Text(formatter.format(date),
            textAlign: isDesktopScreen ? null : TextAlign.end),
      );
    } catch (e) {
      return TIMUIKitOperationItem(
        smallCardMode: smallCardMode,
        isEmpty: false,
        showAllowEditStatus: false,
        operationName: TIM_t("生日"),
        operationRightWidget: Text(TIM_t("未填写"),
            textAlign: isDesktopScreen ? null : TextAlign.end),
      );
    }
  }

  /// default button area
  static Widget addAndDeleteArea(
      BuildContext context,
      V2TimFriendInfo friendInfo,
      V2TimConversation conversation,
      int friendType,
      bool isDisturb,
      bool isBlocked,
      TUITheme theme,
      VoidCallback handleAddFriend,
      VoidCallback handleDeleteFriend,
      bool smallCardMode) {
    _buildDeleteFriend(V2TimConversation conversation, theme) {
      return ChatBaseButton(
        type: ChatBaseButtonType.secondary,
        onPressed: () {
          handleDeleteFriend();
        },
        text: TIM_t("清除好友"),
      );
    }

    _buildAddOperation() {
      return ChatBaseButton(
        onPressed: () {
          handleAddFriend();
        },
        text: TIM_t("加为好友"),
      );
    }

    _clearHistory(BuildContext context, theme) async {
      final isDesktopScreen =
          TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

      final sdkInstance = TIMUIKitCore.getSDKInstance();
      final TIMUIKitChatController _timuiKitChatController =
          TIMUIKitChatController();
      if (isDesktopScreen) {
        TUIKitWidePopup.showSecondaryConfirmDialog(
            operationKey: TUIKitWideModalOperationKey.confirmClearChatHistory,
            context: context,
            text: TIM_t("清空聊天记录"),
            theme: theme,
            onCancel: () {},
            onConfirm: () async {
              if (PlatformUtils().isWeb) {
                final res = await sdkInstance
                    .getConversationManager()
                    .deleteConversation(
                        conversationID: conversation.conversationID);
                if (res.code == 0) {
                  _timuiKitChatController.clearHistory(friendInfo.userID);
                  TUIToast.show(
                      content: tr('meeting.chat_deleted_success'),
                      gravity: TUIGravity.top);
                }
              } else {
                final res = await sdkInstance
                    .getMessageManager()
                    .clearC2CHistoryMessage(userID: friendInfo.userID);
                if (res.code == 0) {
                  _timuiKitChatController.clearHistory(friendInfo.userID);
                  TUIToast.show(
                      content: tr('meeting.chat_deleted_success'),
                      gravity: TUIGravity.top);
                }
              }
            });
      } else {
        showCupertinoModalPopup<String>(
          context: context,
          builder: (BuildContext context) {
            return CupertinoActionSheet(
              cancelButton: CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },
                child: Text(TIM_t("取消")),
                isDefaultAction: false,
              ),
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    Navigator.pop(
                      context,
                    );
                    if (PlatformUtils().isWeb) {
                      final res = await sdkInstance
                          .getConversationManager()
                          .deleteConversation(
                              conversationID: conversation.conversationID);
                      if (res.code == 0) {
                        _timuiKitChatController.clearHistory(friendInfo.userID);
                        TUIToast.show(
                            content: tr('meeting.chat_deleted_success'),
                            gravity: TUIGravity.top);
                      }
                    } else {
                      final res = await sdkInstance
                          .getMessageManager()
                          .clearC2CHistoryMessage(userID: friendInfo.userID);
                      if (res.code == 0) {
                        _timuiKitChatController.clearHistory(friendInfo.userID);
                        TUIToast.show(
                            content: tr('meeting.chat_deleted_success'),
                            gravity: TUIGravity.top);
                      }
                    }
                  },
                  child: Text(
                    TIM_t("清空聊天记录"),
                    style: TextStyle(color: theme.cautionColor),
                  ),
                  isDefaultAction: false,
                )
              ],
            );
          },
        );
      }
    }

    _buildClearOperation() {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ChatBaseButton(
          type: ChatBaseButtonType.secondary,
          onPressed: () {
            _clearHistory(context, theme);
          },
          text: TIM_t("清空消息"),
        ),
      );
    }

    return Column(
      children: [
        _buildClearOperation(),
        if (friendType != 0) _buildDeleteFriend(conversation, theme),
        if (friendType == 0 && !isBlocked) _buildAddOperation()
      ],
    );
  }

  static Widget addAudioAndVideoArea(
      V2TimFriendInfo friendInfo,
      V2TimConversation conversation,
      int type,
      bool isDisturb,
      bool isBlocked,
      TUITheme theme,
      VoidCallback handleAddFriend,
      VoidCallback handleDeleteFriend,
      bool smallCardMode) {
    _buildVideo(V2TimConversation conversation, theme) {
      return ChatBaseButton(
        onPressed: () {
          TUICore().callService(TUICALLKIT_SERVICE_NAME, METHOD_NAME_CALL, {
            PARAM_NAME_TYPE: TYPE_AUDIO,
            PARAM_NAME_USERIDS: [conversation.userID!],
            PARAM_NAME_GROUPID: ""
          });
        },
        text: TIM_t("语音通话"),
      );
    }

    _buildAudio(V2TimConversation conversation, theme) {
      return ChatBaseButton(
        onPressed: () async {
          TUICore().callService(TUICALLKIT_SERVICE_NAME, METHOD_NAME_CALL, {
            PARAM_NAME_TYPE: TYPE_VIDEO,
            PARAM_NAME_USERIDS: [conversation.userID!],
            PARAM_NAME_GROUPID: ""
          });
        },
        text: TIM_t("视频通话"),
      );
    }

    return Column(
      children: [
        if (type != 0) _buildAudio(conversation, theme),
        if (type == 0) _buildVideo(conversation, theme)
      ],
    );
  }

  static Widget wideButton({
    required VoidCallback onPressed,
    required String text,
    required Color color,
    required bool smallCardMode,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 10),
      child: smallCardMode
          ? OutlinedButton(
              onPressed: onPressed,
              child: Text(
                text,
                style: TextStyle(color: color),
              ),
              style: ButtonStyle(
                minimumSize:
                    MaterialStateProperty.all<Size>(const Size(160, 40)),
              ))
          : ElevatedButton(
              onPressed: onPressed,
              child: Text(text),
              style: ButtonStyle(
                  minimumSize:
                      MaterialStateProperty.all<Size>(const Size(180, 46)),
                  backgroundColor: MaterialStateProperty.all<Color>(color)),
            ),
    );
  }

  /// default button area
  static Widget addAndDeleteAreaWide(
    V2TimFriendInfo friendInfo,
    V2TimConversation conversation,
    int friendType,
    bool isDisturb,
    bool isBlocked,
    TUITheme theme,
    VoidCallback handleAddFriend,
    VoidCallback handleDeleteFriend,
    bool smallCardMode,
  ) {
    _buildDeleteFriend(V2TimConversation conversation, theme) {
      return wideButton(
        smallCardMode: smallCardMode,
        onPressed: () {
          handleDeleteFriend();
        },
        color: theme.cautionColor ?? Colors.red,
        text: TIM_t("清除好友"),
      );
    }

    _buildAddOperation() {
      return wideButton(
        smallCardMode: smallCardMode,
        onPressed: handleAddFriend,
        color: theme.primaryColor ?? hexToColor("3e4b67"),
        text: TIM_t("加为好友"),
      );
    }

    _buildClearOperation() {
      return wideButton(
        smallCardMode: smallCardMode,
        onPressed: handleAddFriend,
        color: theme.primaryColor ?? hexToColor("3e4b67"),
        text: TIM_t("清空消息"),
      );
    }

    return Column(
      children: [
        _buildClearOperation(),
        if (friendType != 0) _buildDeleteFriend(conversation, theme),
        if (friendType == 0 && !isBlocked) _buildAddOperation()
      ],
    );
  }
}
