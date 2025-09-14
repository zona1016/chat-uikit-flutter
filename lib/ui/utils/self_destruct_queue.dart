import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';

class SelfDestructQueue {
  static final SelfDestructQueue _instance = SelfDestructQueue._internal();
  factory SelfDestructQueue() => _instance;
  SelfDestructQueue._internal();

  final Map<String, Timer> _burnTimers = {};
  final Map<String, int> _remainingSeconds = {};
  final Map<String, V2TimMessage> _messages = {}; // Store complete message data
  final Map<String, String> _conversationBurnSeconds = {}; // Cache conversation burn seconds
  
  static const Map<String, int> burnSecondsOptions = {
    '15s': 15,
    '30s': 30,
    '1min': 60,
  };
  
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

  /// Process message for self-destruct (centralized logic)
  void processMessage(String msgID, V2TimMessage message) {
    if (msgID.isEmpty) return;
    
    // Store message data
    _messages[msgID] = message;
    
    try {
      Map<String, dynamic> customData = jsonDecode(message.cloudCustomData ?? "{}");
      bool isSelfDestruct = customData['isSelfDestruct'] == true;
      
      if (!isSelfDestruct) return;
      
      final conversationID = _getConversationID(message);
      
      // For messages I sent, start countdown when read by all
      if (message.isSelf == true) {
        _handleSelfMessage(msgID, message, conversationID);
      } else {
        // For received messages, they start countdown when viewed
        _saveMessageState(msgID, message, conversationID, false);
      }
    } catch (e) {
      debugPrint('处理自毁消息失败: $e');
    }
  }
  
  /// Handle viewing a received message
  void viewMessage(String msgID) {
    final message = _messages[msgID];
    if (message == null || message.isSelf == true) return;
    
    final conversationID = _getConversationID(message);
    
    // Try to get burn seconds with retry if default is returned
    _getBurnSecondsWithRetry(msgID, message, conversationID);
  }
  
  /// Get burn seconds with retry mechanism
  void _getBurnSecondsWithRetry(String msgID, V2TimMessage message, String conversationID) {
    final burnSeconds = _getConversationBurnSeconds(conversationID);
    
    // If we get the default 15s, it might mean the conversation data isn't loaded yet
    if (burnSeconds == 15) {
      debugPrint('Got default 15s for $conversationID, retrying in 500ms...');
      // Retry after a short delay
      Timer(const Duration(milliseconds: 500), () {
        final retryBurnSeconds = _getConversationBurnSeconds(conversationID);
        debugPrint('Retry result for $conversationID: $retryBurnSeconds seconds');
        _startCountdown(msgID, retryBurnSeconds);
        _saveMessageState(msgID, message, conversationID, true);
      });
    } else {
      _startCountdown(msgID, burnSeconds);
      _saveMessageState(msgID, message, conversationID, true);
    }
  }
  
  /// Handle when my message is read by all
  void handleMessageReadByAll(String msgID) {
    final message = _messages[msgID];
    if (message == null || message.isSelf != true) return;
    
    // If not already counting down, start it
    if (!_burnTimers.containsKey(msgID)) {
      final conversationID = _getConversationID(message);
      _getBurnSecondsWithRetry(msgID, message, conversationID);
    }
  }

  /// 开始倒计时
  void _startCountdown(String msgID, int seconds) {
    debugPrint('Starting countdown for $msgID with $seconds seconds');
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
      _messages.remove(msgID);
      
      // Clean up persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('self_destruct_$msgID');
      
      // 通知UI删除消息
      for (final listener in _messageDeletedListeners) {
        listener(msgID);
      }
      
      debugPrint('消息已销毁: $msgID');
    } catch (e) {
      debugPrint('删除消息失败: $e');
    }
  }


  /// Get conversation ID from message
  String _getConversationID(V2TimMessage message) {
    return message.groupID != null ? 
           'group_${message.groupID}' : 
           'c2c_${message.userID ?? message.sender}';
  }
  
  /// Get burn seconds for conversation with fallback
  int _getConversationBurnSeconds(String conversationID) {
    // Check cache first
    final cached = _conversationBurnSeconds[conversationID];
    if (cached != null) {
      debugPrint('Using cached burn seconds for $conversationID: $cached');
      return int.tryParse(cached) ?? burnSecondsOptions['30s']!;
    }
    
    // Try to get from global model
    try {
      final globalModel = serviceLocator<TUIChatGlobalModel>();
      final burnSeconds = globalModel.getConversationBurnSeconds(conversationID);
      
      debugPrint('Got burn seconds from global model for $conversationID: $burnSeconds');
      
      // Cache the result
      _conversationBurnSeconds[conversationID] = burnSeconds.toString();
      return burnSeconds;
    } catch (e) {
      debugPrint('Error getting burn seconds for $conversationID: $e');
      // Fallback to default
      final defaultValue = burnSecondsOptions['30s']!;
      _conversationBurnSeconds[conversationID] = defaultValue.toString();
      return defaultValue;
    }
  }
  
  /// Handle self messages (messages I sent)
  void _handleSelfMessage(String msgID, V2TimMessage message, String conversationID) {
    // For self messages, we need to check if it's read by all to start countdown
    // This will be handled by handleMessageReadByAll() when called from message receipt
    _saveMessageState(msgID, message, conversationID, false);
  }
  
  /// Save message state persistently
  void _saveMessageState(String msgID, V2TimMessage message, String conversationID, bool isViewed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messageState = {
        'msgID': msgID,
        'conversationID': conversationID,
        'isSelf': message.isSelf ?? false,
        'isViewed': isViewed,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('self_destruct_$msgID', jsonEncode(messageState));
    } catch (e) {
      debugPrint('保存消息状态失败: $e');
    }
  }
  
  /// Load conversation burn seconds in background
  void preloadConversationBurnSeconds(String conversationID) {
    if (_conversationBurnSeconds.containsKey(conversationID)) return;
    
    Future.microtask(() {
      // Try to trigger global model to load conversation data
      try {
        final globalModel = serviceLocator<TUIChatGlobalModel>();
        // This will attempt to load from SDK if not cached
        globalModel.getConversationBurnSeconds(conversationID);
        debugPrint('Preloaded burn seconds for $conversationID');
      } catch (e) {
        debugPrint('Failed to preload burn seconds for $conversationID: $e');
      }
      
      // Cache the result in our local cache
      _getConversationBurnSeconds(conversationID);
    });
  }
  
  /// Check if message is self-destruct
  bool isSelfDestructMessage(String msgID) {
    final message = _messages[msgID];
    if (message == null) return false;
    
    try {
      final customData = jsonDecode(message.cloudCustomData ?? "{}");
      return customData['isSelfDestruct'] == true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get remaining seconds (main method for UI)
  int getRemainingSeconds(String msgID) {
    return _remainingSeconds[msgID] ?? 0;
  }
  
  /// Check if message is being viewed/countdown started
  bool isMessageViewed(String msgID) {
    return _burnTimers.containsKey(msgID) || _remainingSeconds.containsKey(msgID);
  }
  
  /// Clear cached burn seconds for a conversation (used when global model loads new data)
  void clearConversationCache(String conversationID) {
    _conversationBurnSeconds.remove(conversationID);
    debugPrint('Cleared conversation cache for $conversationID');
  }
  
  /// Get expected burn seconds for a conversation (for UI display, doesn't start countdown)
  int getExpectedBurnSeconds(String conversationID) {
    return _getConversationBurnSeconds(conversationID);
  }

  /// Load message states from persistent storage (call when app starts/conversation loads)
  Future<void> loadSavedStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('self_destruct_')).toList();
      
      for (final key in keys) {
        final stateJson = prefs.getString(key);
        if (stateJson == null) continue;
        
        try {
          final state = jsonDecode(stateJson);
          final msgID = state['msgID'] as String;
          final conversationID = state['conversationID'] as String;
          final isViewed = state['isViewed'] as bool;
          final timestamp = state['timestamp'] as int;
          // final isSelf = state['isSelf'] as bool;
          
          // Check if message is too old (older than max burn seconds)
          final age = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (age > 60000) { // More than 1 minute old
            await prefs.remove(key);
            continue;
          }
          
          // If message was viewed, restore countdown
          if (isViewed) {
            final burnSeconds = _getConversationBurnSeconds(conversationID);
            final elapsed = age ~/ 1000; // Convert to seconds
            final remaining = burnSeconds - elapsed;
            
            if (remaining > 0) {
              _remainingSeconds[msgID] = remaining;
              _startCountdownFromRemaining(msgID, remaining);
            } else {
              // Message should have been deleted, clean up
              await prefs.remove(key);
            }
          }
        } catch (e) {
          debugPrint('恢复消息状态失败: $e');
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('加载保存状态失败: $e');
    }
  }
  
  /// Start countdown from remaining seconds (for recovery)
  void _startCountdownFromRemaining(String msgID, int remainingSeconds) {
    _remainingSeconds[msgID] = remainingSeconds;
    
    _burnTimers[msgID] = Timer.periodic(const Duration(seconds: 1), (timer) {
      int remaining = _remainingSeconds[msgID]! - 1;
      _remainingSeconds[msgID] = remaining;
      
      // Notify UI
      for (final listener in _countdownListeners) {
        listener(msgID, remaining);
      }
      
      if (remaining <= 0) {
        timer.cancel();
        _deleteMessage(msgID);
      }
    });
  }
  
  /// Clean up old saved states
  Future<void> cleanupOldStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('self_destruct_')).toList();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      for (final key in keys) {
        final stateJson = prefs.getString(key);
        if (stateJson == null) continue;
        
        try {
          final state = jsonDecode(stateJson);
          final timestamp = state['timestamp'] as int;
          if ((now - timestamp) > 300000) { // Older than 5 minutes
            await prefs.remove(key);
          }
        } catch (e) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('清理旧状态失败: $e');
    }
  }

  void dispose() {
    for (var timer in _burnTimers.values) {
      timer.cancel();
    }
    _burnTimers.clear();
    _remainingSeconds.clear();
    _messages.clear();
    _conversationBurnSeconds.clear();
  }
}