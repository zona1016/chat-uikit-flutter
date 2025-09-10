import 'package:easy_localization/easy_localization.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';

class DisappearingMessageConfig {
  int hour;
  int minute;
  String type; // "0"=24小时, "1"=7天, "2"=90天, "3"=已关闭
  String startTime; // 秒
  String desc;
  String userName;

  DisappearingMessageConfig({
    required this.hour,
    required this.minute,
    required this.type,
    required this.startTime,
    this.desc = '',
    this.userName = ''
  });

  /// 从 JSON 创建
  factory DisappearingMessageConfig.fromJson(Map<String, dynamic> json) {
    final hour = int.tryParse(json['disappearing_message_hour']?.toString() ?? '0') ?? 0;
    final minute = int.tryParse(json['disappearing_message_minute']?.toString() ?? '0') ?? 0;
    final type = json['disappearing_message_type']?.toString() ?? "";
    final startTime = json['disappearing_message_time']?.toString() ?? "";
    final userName = json['disappearing_message_name']?.toString() ?? "";

    String desc = "";
    if (hour == 0 && minute == 0) {
      switch (type) {
        case "0":
          desc = "24 ${tr('wallet.hours')}";
          break;
        case "1":
          desc = "7 ${tr('wallet.days')}";
          break;
        case "2":
          desc = "90 ${tr('wallet.days')}";
          break;
        case "3":
          desc = TIM_t('关闭');
          break;
        default:
          desc = "";
          break;
      }
    } else {
      desc = '$hour ${tr('wallet.hours')} $minute ${tr('wallet.minutes')}';
    }

    return DisappearingMessageConfig(
      hour: hour,
      minute: minute,
      type: type,
      startTime: startTime,
      desc: desc,
      userName: userName
    );
  }

  /// 转回 Map<String, String>
  Map<String, String> toJson() {
    return {
      "disappearing_message_hour": hour.toString(),
      "disappearing_message_minute": minute.toString(),
      "disappearing_message_type": type,
      "disappearing_message_time": startTime.toString(),
      "disappearing_message_name": userName.toString(),
    };
  }

  /// 获取总时长
  Duration get totalDuration {
    if (hour == 0 && minute == 0) {
      switch (type) {
        case "0":
          return const Duration(hours: 24);
        case "1":
          return const Duration(days: 7);
        case "2":
          return const Duration(days: 90);
        case "3":
        default:
          return Duration.zero;
      }
    } else {
      return Duration(hours: hour, minutes: minute);
    }
  }
}
