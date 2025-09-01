import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitProfile/widget/tim_uikit_operation_item.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/common_utils.dart';
import 'package:tencent_im_base/tencent_im_base.dart';

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
    final conversationID = model.groupInfo?.groupID;
    
    // Don't show toggle for read-only conversations
    if (_isReadOnlyConversation("group_$conversationID")) {
      return const SizedBox.shrink();
    }

    // Get current self-destruct mode status from model
    final isSelfDestructEnabled = model.selfDestructMode ?? false;

    return TIMUIKitOperationItem(
      isEmpty: false,
      operationName: TIM_t("打开阅后即焚模式"),
      type: "switch",
      isUseCheckedBoxOnWide: true,
      operationValue: isSelfDestructEnabled,
      onSwitchChange: (value) {
        model.setSelfDestructMode(value);
      },
    );
  }
}