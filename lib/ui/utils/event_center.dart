import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';

class EventCenter {
  static final EventCenter _instance = EventCenter._internal();

  factory EventCenter() => _instance;

  EventCenter._internal();

  final EventBus _eventBus = EventBus();

  // 发送事件
  void post<T>(T event) {
    _eventBus.fire(event);
  }

  // 监听事件（需要手动管理 subscription）
  StreamSubscription<T> listen<T>(void Function(T event) onData) {
    return _eventBus.on<T>().listen(onData);
  }

  // 获取 Stream（可用于更灵活控制）
  Stream<T> on<T>() {
    return _eventBus.on<T>();
  }
}

// 发红包
class SendRedPacketNotice {
  /// 会话ID
  final String conversationID;

  /// 会话类型
  final ConvType conversationType;
  SendRedPacketNotice({required this.conversationType, required this.conversationID});
}

// 红包点击
class RedPacketTipNotice {
  final String redEnvelopId;
  final String desc;
  RedPacketTipNotice({required this.redEnvelopId, required this.desc});
}

// 个人名片点击 加好友
class CardTipNotice {
  final bool isFriend;
  final String userId;

  CardTipNotice({required this.isFriend, required this.userId});
}

// 群聊消息搜索点击
class SearchMessageTipNotice {
  final V2TimConversation selectedConversation;
  final V2TimMessage? message;

  SearchMessageTipNotice(
      {required this.selectedConversation, required this.message});
}

// 快捷访问
final eventCenter = EventCenter();
