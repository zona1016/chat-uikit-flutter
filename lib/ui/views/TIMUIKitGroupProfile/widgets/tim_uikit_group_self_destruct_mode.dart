import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/self_destruct_queue.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/tim_uikit_wide_modal_operation_key.dart';

class GroupSelfDestructMode extends TIMUIKitStatelessWidget {
  GroupSelfDestructMode({Key? key}) : super(key: key);

  /// Check if conversation is read-only (aid_team or channels)
  bool _isReadOnlyConversation(String? conversationID) {
    if (conversationID == null) return false;
    
    // Handle group_ prefix in conversation IDs
    final cleanConversationID = conversationID.startsWith('group_') 
        ? conversationID.substring(6) // Remove "group_" prefix
        : conversationID;
    
    // Check against known read-only conversations
    final isReadOnly = (TencentUtils.aidTeam == cleanConversationID ||
        TencentUtils.india == cleanConversationID ||
        TencentUtils.korea == cleanConversationID ||
        TencentUtils.english == cleanConversationID ||
        TencentUtils.chinese == cleanConversationID ||
        TencentUtils.french == cleanConversationID ||
        TencentUtils.german == cleanConversationID);
    
    return isReadOnly;
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final model = Provider.of<TUIGroupProfileModel>(context);
    final theme = Provider.of<TUIThemeViewModel>(context).theme;
    final conversationID = model.groupInfo?.groupID;
    
    // Don't show toggle for read-only conversations
    if (_isReadOnlyConversation("group_$conversationID")) {
      return const SizedBox.shrink();
    }

    
    // Get current self-destruct mode status from model
    final isSelfDestructEnabled = model.selfDestructMode ?? false;

    return Column(
      children: [
        // Self-destruct mode toggle using existing component
        TIMUIKitOperationItem(
          isEmpty: false,
          operationName: TIM_t("打开阅后即焚模式"),
          type: "switch",
          isUseCheckedBoxOnWide: true,
          operationValue: isSelfDestructEnabled,
          onSwitchChange: (value) {
            model.setSelfDestructMode(value);
          },
        ),
        
        // Burn seconds setting (only show when self-destruct mode is enabled)
        if (isSelfDestructEnabled)
          GestureDetector(
            onTap: () {
              _showBurnSecondsSelector(context, "group_$conversationID", theme, model);
            },
            child: TIMUIKitOperationItem(
              isEmpty: false,
              operationName: TIM_t("自毁时间"),
              type: "arrow",
              rightIconColor: AidaBaseColors.weakTextColor,
              operationRightWidget: Consumer<TUIGroupProfileModel>(
                builder: (context, model, child) {
                  return Text(textAlign: TextAlign.end,_getCurrentBurnSecondsText(model.burnSeconds));
                },
              ),
            ),
          ),
      ],
    );
  }

  String _getCurrentBurnSecondsText(int seconds) {
    const burnSecondsOptions = SelfDestructQueue.burnSecondsOptions;
    final entry = burnSecondsOptions.entries.firstWhere(
      (e) => e.value == seconds, 
      orElse: () => MapEntry('${seconds}s', seconds)
    );
    return _translateBurnSecondsKey(entry.key);
  }

  String _translateBurnSecondsKey(String key) {
    switch (key) {
      case '15s':
        return '15${TIM_t("秒")}';
      case '30s':
        return '30${TIM_t("秒")}';
      case '1min':
        return '1${TIM_t("分钟")}';
      default:
        return key;
    }
  }

  void _showBurnSecondsSelector(
    BuildContext context, 
    String conversationID, 
    TUITheme theme,
    TUIGroupProfileModel profileModel) async {
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
              children: burnSecondsOptions.entries.map((option) {
                final isSelected = option.value == profileModel.burnSeconds;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      _translateBurnSecondsKey(option.key),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () async {
                      await profileModel.setBurnSeconds(conversationID, option.value);
                      onClose();
                    },
                  ),
                );
              }).toList(),
            ),
          ));
    } else {
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return CupertinoActionSheet(
            title: Text(TIM_t("选择自毁时间")),
            actions: burnSecondsOptions.entries.map((option) {
              final isSelected = option.value == profileModel.burnSeconds;
              return CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  await profileModel.setBurnSeconds(conversationID, option.value);
                },
                child: Text(
                  _translateBurnSecondsKey(option.key),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? CupertinoColors.systemBlue : null,
                  ),
                ),
              );
            }).toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(TIM_t("取消")),
            ),
          );
        },
      );
    }
  }
}