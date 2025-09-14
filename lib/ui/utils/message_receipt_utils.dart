import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/self_destruct_queue.dart';

/// Utility class for handling message read receipt operations
class MessageReceiptUtils {
  /// Check if a group message has been read by all members
  /// 
  /// Priority order for getting messageReceiptMap:
  /// 1. messageReceiptMap parameter (if provided)
  /// 2. chatModel.globalModel.messageReadReceiptMap (if chatModel provided)
  /// 3. context Provider<TUIChatGlobalModel> (if context provided)
  /// 4. serviceLocator<TUIChatGlobalModel> (fallback)
  static bool isGroupMessageReadByAll({
    required V2TimMessage message,
    Map<String, V2TimMessageReceipt>? messageReceiptMap,
    TUIChatSeparateViewModel? chatModel,
    BuildContext? context,
  }) {
    // Basic validation
    debugPrint('message receipt utils: context $context - groupID ${message.groupID} - msgID ${message.msgID}');
    if (message.groupID == null || message.msgID == null) {
      return false;
    }
    
    Map<String, V2TimMessageReceipt>? receiptMap;
    
    // Priority 1: Direct parameter
    if (messageReceiptMap != null) {
      receiptMap = messageReceiptMap;
      debugPrint('message receipt utils: by direct parameter');
    }
    // Priority 2: Chat model
    else if (chatModel != null) {
      receiptMap = chatModel.globalModel.messageReadReceiptMap;
      debugPrint('message receipt utils: by chat model');
    }
    // Priority 3: Context provider
    else if (context != null) {
      try {
        final globalModel = Provider.of<TUIChatGlobalModel>(context, listen: false);
        receiptMap = globalModel.messageReadReceiptMap;
        debugPrint('message receipt utils: by context');
      } catch (e) {
        // Provider not available, continue to fallback
      }
    }
    debugPrint('message receipt utils: receiptMap: $receiptMap');
    // Priority 4: Service locator fallback
    if (receiptMap == null) {
      try {
        final globalModel = serviceLocator<TUIChatGlobalModel>();
        receiptMap = globalModel.messageReadReceiptMap;
      } catch (e) {
        return false;
      }
    }
    
    bool isReadByAll = false;
    
    // Check cached read receipt
    final receipt = receiptMap[message.msgID!];
    if (receipt != null) {
      debugPrint('message receipt utils: actual receipt ${receipt.unreadCount}');
      isReadByAll = receipt.unreadCount == 0;
    } else {
      // Fallback: try to use the private property if it exists
      try {
        isReadByAll = (message as dynamic)._messageGroupReceiptUnreadCount == 0;
      } catch (e) {
        return false;
      }
    }
    
    return isReadByAll;
  }
  
  /// Check if a group message has been read by all members and handle self-destruct logic
  /// This is a convenience method that also triggers self-destruct behavior
  static bool isGroupMessageReadByAllWithSelfDestruct({
    required V2TimMessage message,
    Map<String, V2TimMessageReceipt>? messageReceiptMap,
    TUIChatSeparateViewModel? chatModel,
    BuildContext? context,
    Function(String msgID, V2TimMessage message, {int? conversationBurnSeconds})? onSelfDestructTrigger,
  }) {
    final isReadByAll = isGroupMessageReadByAll(
      message: message,
      messageReceiptMap: messageReceiptMap,
      chatModel: chatModel,
      context: context,
    );
    
    // Handle self-destruct logic if message is read by all
    if (isReadByAll && message.isSelf == true && onSelfDestructTrigger != null) {
      // Check if it's a self-destruct message
      try {
        final customData = (message.cloudCustomData?.trim().isNotEmpty ?? false)
            ? jsonDecode(message.cloudCustomData!)
            : {};
        
        final shouldTriggerSelfDestruct = customData['isSelfDestruct'] == true;
        if (shouldTriggerSelfDestruct && message.msgID != null) {
          debugPrint('Group message ${message.msgID} read by all members, triggering self-destruct');
          
          // Get burn seconds
          TUIChatGlobalModel? globalModel;
          if (chatModel != null) {
            globalModel = chatModel.globalModel;
          } else if (context != null) {
            try {
              globalModel = Provider.of<TUIChatGlobalModel>(context, listen: false);
            } catch (e) {
              // Continue to fallback
            }
          }
          if (globalModel == null) {
            try {
              globalModel = serviceLocator<TUIChatGlobalModel>();
            } catch (e) {
              // No global model available
            }
          }
          
          int? burnSeconds;
          if (globalModel != null) {
            final conversationID = message.groupID != null ? 
                                   'group_${message.groupID}' : 
                                   'c2c_${message.userID ?? message.sender}';
            burnSeconds = globalModel.getConversationBurnSeconds(conversationID);
          }
          
          onSelfDestructTrigger(message.msgID!, message, conversationBurnSeconds: burnSeconds);
        }
      } catch (e) {
        debugPrint('Error processing self-destruct logic: $e');
      }
    }
    
    return isReadByAll;
  }
}