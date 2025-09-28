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
        // For received messages, check if they should already be viewed (state recovery)
        _handleReceivedMessage(msgID, message, conversationID);
      }
    } catch (e) {
      debugPrint('处理自毁消息失败: $e');
    }
  }
  
  /// Handle viewing a received message
  void viewMessage(String msgID) {
    final message = _messages[msgID];
    if (message == null || message.isSelf == true) return;
    
    debugPrint('viewMessage called for $msgID, timer exists: ${_burnTimers.containsKey(msgID)}');
    
    // Skip if timer already exists
    if (_burnTimers.containsKey(msgID)) {
      debugPrint('Timer already exists for received message $msgID, skipping');
      return;
    }
    
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
    
    debugPrint('handleMessageReadByAll called for $msgID, timer exists: ${_burnTimers.containsKey(msgID)}');
    
    // If not already counting down, start it
    if (!_burnTimers.containsKey(msgID)) {
      final conversationID = _getConversationID(message);
      _getBurnSecondsWithRetry(msgID, message, conversationID);
    }
  }

  /// 开始倒计时
  void _startCountdown(String msgID, int seconds) {
    // Prevent duplicate timers
    if (_burnTimers.containsKey(msgID)) {
      debugPrint('Timer already exists for $msgID, skipping duplicate');
      return;
    }
    
    debugPrint('Starting countdown for $msgID with $seconds seconds');
    _remainingSeconds[msgID] = seconds;
    
    _burnTimers[msgID] = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Safety check - if remaining seconds was cleaned up by another timer, stop this one
      final currentRemaining = _remainingSeconds[msgID];
      if (currentRemaining == null) {
        debugPrint('Remaining seconds for $msgID was null, stopping timer');
        timer.cancel();
        _burnTimers.remove(msgID);
        return;
      }
      
      int remaining = currentRemaining - 1;
      _remainingSeconds[msgID] = remaining;
      
      // 通知UI更新倒计时
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
      debugPrint('Deleting self-destruct message: $msgID');
      
      // Cancel and remove timer first to prevent race conditions
      final timer = _burnTimers.remove(msgID);
      timer?.cancel();
      
      _remainingSeconds.remove(msgID);
      _messages.remove(msgID);
      
      chatModel.deleteMsg(msgID);
      await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .deleteMessages(msgIDs: [msgID]);
      
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
  
  /// Handle received messages with state recovery
  void _handleReceivedMessage(String msgID, V2TimMessage message, String conversationID) {
    // Check if this message should already be considered "viewed" based on various indicators
    bool shouldBeViewed = _shouldMessageBeViewed(message);
    
    if (shouldBeViewed && !_burnTimers.containsKey(msgID)) {
      // Message should be viewed but no countdown exists - restart countdown
      debugPrint('Detected previously viewed message without countdown, restarting: $msgID');
      final burnSeconds = _getConversationBurnSeconds(conversationID);
      _startCountdown(msgID, burnSeconds);
      _saveMessageState(msgID, message, conversationID, true);
    } else {
      // Normal case - save state but don't start countdown until user views
      _saveMessageState(msgID, message, conversationID, false);
    }
  }
  
  /// Determine if a received message should already be considered "viewed"
  bool _shouldMessageBeViewed(V2TimMessage message) {
    // For received messages, do NOT auto-start based on time
    // Self-destruct messages should only start countdown when explicitly viewed by user
    
    // Check persistent storage for previously viewed state
    if (message.msgID != null) {
      final isViewed = isMessageViewed(message.msgID!);
      if (isViewed) {
        debugPrint('Message ${message.msgID} was previously viewed (from storage)');
        return true;
      }
    }
    
    // If not found in storage, default to not viewed
    return false;
  }
  
  /// Handle self messages (messages I sent)
  void _handleSelfMessage(String msgID, V2TimMessage message, String conversationID) {
    // Check if this self message should already have countdown started
    if (_shouldSelfMessageHaveCountdown(message) && !_burnTimers.containsKey(msgID)) {
      debugPrint('Detected self message that should be counting down, starting: $msgID');
      final burnSeconds = _getConversationBurnSeconds(conversationID);
      _startCountdown(msgID, burnSeconds);
      _saveMessageState(msgID, message, conversationID, true);
    } else {
      // Normal case - save state and wait for read receipt
      _saveMessageState(msgID, message, conversationID, false);
    }
  }
  
  /// Determine if a self message should already have countdown started
  bool _shouldSelfMessageHaveCountdown(V2TimMessage message) {
    // For C2C messages, check if peer has read it
    if (message.groupID == null) {
      if (message.isPeerRead == true) {
        debugPrint('Self message ${message.msgID} is read by peer');
        return true;
      }
    } else {
      // For group messages, check if read by all members
      // Note: This requires access to chat model for read receipt utils
      // Since we don't have direct access here, we'll need to rely on
      // the message elements to properly trigger countdown via handleMessageReadByAll()
      // For now, only start if explicitly marked as viewed in storage
      if (message.msgID != null && isMessageViewed(message.msgID!)) {
        debugPrint('Self group message ${message.msgID} is marked as viewed in storage');
        return true;
      }
    }
    
    return false;
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
    // Check if there's an active countdown
    if (_burnTimers.containsKey(msgID) || _remainingSeconds.containsKey(msgID)) {
      return true;
    }
    
    // Check if message should be considered viewed based on its state
    final message = _messages[msgID];
    if (message != null) {
      if (message.isSelf == true) {
        // For self messages, check if they should have countdown
        return _shouldSelfMessageHaveCountdown(message);
      } else {
        // For received messages, check if they should be viewed
        return _shouldMessageBeViewed(message);
      }
    }
    
    return false;
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
  
  /// Force check if a message needs countdown recovery (for edge cases)
  void checkMessageRecovery(String msgID) {
    final message = _messages[msgID];
    if (message == null) return;
    
    bool shouldHaveCountdown = false;
    
    if (message.isSelf == true) {
      // For self messages, check if they should be counting down
      shouldHaveCountdown = _shouldSelfMessageHaveCountdown(message);
    } else {
      // For received messages, check if they should be viewed
      shouldHaveCountdown = _shouldMessageBeViewed(message);
    }
    
    if (shouldHaveCountdown && !_burnTimers.containsKey(msgID)) {
      debugPrint('Manual recovery check: restarting countdown for $msgID (isSelf: ${message.isSelf})');
      final conversationID = _getConversationID(message);
      final burnSeconds = _getConversationBurnSeconds(conversationID);
      _startCountdown(msgID, burnSeconds);
      _saveMessageState(msgID, message, conversationID, true);
    }
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
    // Prevent duplicate timers
    if (_burnTimers.containsKey(msgID)) {
      debugPrint('Timer already exists for $msgID during recovery, skipping duplicate');
      return;
    }
    
    debugPrint('Starting recovery countdown for $msgID with $remainingSeconds seconds');
    _remainingSeconds[msgID] = remainingSeconds;
    
    _burnTimers[msgID] = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Safety check - if remaining seconds was cleaned up by another timer, stop this one
      final currentRemaining = _remainingSeconds[msgID];
      if (currentRemaining == null) {
        debugPrint('Remaining seconds for $msgID was null during recovery, stopping timer');
        timer.cancel();
        _burnTimers.remove(msgID);
        return;
      }
      
      int remaining = currentRemaining - 1;
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