import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';

class SelfDestructQueue {
  static final SelfDestructQueue _instance = SelfDestructQueue._internal();
  factory SelfDestructQueue() => _instance;
  SelfDestructQueue._internal();

  final Map<String, Timer> _burnTimers = {};
  final Map<String, int> _remainingSeconds = {};
  final Set<String> _viewedMessages = {};
  static const int burnSeconds = 15;
  late TUIChatSeparateViewModel chatModel;

  // 用于UI更新的回调
  Function(String msgID, int remainingSeconds)? onCountdownUpdate;
  Function(String msgID)? onMessageDeleted;

  /// 查看消息并开始倒计时
  void viewMessage(String msgID, V2TimMessage message) {
    if (_viewedMessages.contains(msgID)) {
      return; // 已经查看过了
    }

    _viewedMessages.add(msgID);

    try {
      Map<String, dynamic> customData = jsonDecode(message.cloudCustomData ?? "{}");
      
      if (customData['isSelfDestruct'] == true) {
        _startCountdown(msgID, burnSeconds);
      }
    } catch (e) {
      print('解析消息失败: $e');
    }
  }

  /// 开始倒计时
  void _startCountdown(String msgID, int seconds) {
    _remainingSeconds[msgID] = seconds;
    
    _burnTimers[msgID] = Timer.periodic(const Duration(seconds: 1), (timer) {
      int remaining = _remainingSeconds[msgID]! - 1;
      _remainingSeconds[msgID] = remaining;
      
      // 通知UI更新倒计时
      onCountdownUpdate?.call(msgID, remaining);
      
      if (remaining <= 0) {
        timer.cancel();
        _deleteMessage(msgID);
      }
    });
  }

  /// 删除消息
  Future<void> _deleteMessage(String msgID) async {
    try {
      chatModel.deleteMsg(msgID);
      await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .deleteMessages(msgIDs: [msgID]);
      
      _burnTimers.remove(msgID);
      _remainingSeconds.remove(msgID);
      _viewedMessages.remove(msgID);
      
      // 通知UI删除消息
      onMessageDeleted?.call(msgID);
      
      debugPrint('消息已销毁: $msgID');
    } catch (e) {
      debugPrint('删除消息失败: $e');
    }
  }

  /// 获取剩余时间
  int getRemainingSeconds(String msgID) {
    return _remainingSeconds[msgID] ?? burnSeconds;
  }

  /// 检查消息是否已查看
  bool isMessageViewed(String msgID) {
    return _viewedMessages.contains(msgID);
  }

  void dispose() {
    for (var timer in _burnTimers.values) {
      timer.cancel();
    }
    _burnTimers.clear();
    _remainingSeconds.clear();
    _viewedMessages.clear();
  }
}