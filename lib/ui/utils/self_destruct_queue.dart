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
  static const Map<String, int> burnSecondsOptions = {
    '15s': 15,
    '30s': 30,
    '1min': 60,
  };
  
  int _currentBurnSeconds = 15;
  late TUIChatSeparateViewModel chatModel;

  // 用于UI更新的回调
  // Function(String msgID, int remainingSeconds)? onCountdownUpdate;
  // Function(String msgID)? onMessageDeleted;
  final Set<void Function(String msgID, int remainingSeconds)>
    _countdownListeners = {};
  final Set<void Function(String msgID)> _messageDeletedListeners = {};

  void addCountdownListener(
    void Function(String msgID, int remainingSeconds) listener) {
    _countdownListeners.add(listener);
  }

  void removeCountdownListener(
    void Function(String msgID, int remainingSeconds) listener) {
    _countdownListeners.remove(listener);
  }

  void addMessageDeletedListener(void Function(String msgID) listener) {
    _messageDeletedListeners.add(listener);
  }

  void removeMessageDeletedListener(void Function(String msgID) listener) {
    _messageDeletedListeners.remove(listener);
  }

  /// 查看消息并开始倒计时
  void viewMessage(String msgID, V2TimMessage message, {int? conversationBurnSeconds}) {
    if (conversationBurnSeconds != null) {
      _currentBurnSeconds = conversationBurnSeconds;
    }
    if (_viewedMessages.contains(msgID)) {
      return; // 已经查看过了
    }

    _viewedMessages.add(msgID);

    try {
      Map<String, dynamic> customData = jsonDecode(message.cloudCustomData ?? "{}");
      
      if (customData['isSelfDestruct'] == true) {
        // Use conversation-specific burn seconds if provided, otherwise use current default
        final burnSeconds = conversationBurnSeconds ?? _currentBurnSeconds;
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
      // onCountdownUpdate?.call(msgID, remaining);
      for (final listener in _countdownListeners) {
        listener(msgID, remaining);
      }
      
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
      // onMessageDeleted?.call(msgID);
      for (final listener in _messageDeletedListeners) {
        listener(msgID);
      }
      
      debugPrint('消息已销毁: $msgID');
    } catch (e) {
      debugPrint('删除消息失败: $e');
    }
  }

  /// 获取剩余时间
  int getRemainingSeconds(String msgID) {
    return _remainingSeconds[msgID] ?? _currentBurnSeconds;
  }

  /// 检查消息是否已查看
  bool isMessageViewed(String msgID) {
    return _viewedMessages.contains(msgID);
  }

  /// 设置自毁时间
  void setBurnSeconds(int seconds) {
    _currentBurnSeconds = seconds;
  }

  /// 获取当前自毁时间
  int get currentBurnSeconds => _currentBurnSeconds;

  void dispose() {
    for (var timer in _burnTimers.values) {
      timer.cancel();
    }
    _burnTimers.clear();
    _remainingSeconds.clear();
    _viewedMessages.clear();
  }
}