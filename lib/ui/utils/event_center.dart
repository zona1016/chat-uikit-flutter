import 'dart:async';

import 'package:event_bus/event_bus.dart';

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
  SendRedPacketNotice();
}

// 红包点击
class RedPacketTipNotice {
  RedPacketTipNotice();
}


// 快捷访问
final eventCenter = EventCenter();
