import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitProfile/disappearing_message.dart';

class UserDisappearingConfigs {
  final String loginUserID;
  final List<UserGroupDisappearingConfig> groupConfigs;

  UserDisappearingConfigs({
    required this.loginUserID,
    required this.groupConfigs,
  });

  factory UserDisappearingConfigs.fromJson(Map<String, dynamic> json) {
    final groupList = (json['groupConfigs'] as List<dynamic>? ?? [])
        .map((e) => UserGroupDisappearingConfig.fromJson(e))
        .toList();

    return UserDisappearingConfigs(
      loginUserID: json['loginUserID'] ?? '',
      groupConfigs: groupList,
    );
  }

  Map<String, dynamic> toJson() => {
        'loginUserID': loginUserID,
        'groupConfigs': groupConfigs.map((e) => e.toJson()).toList(),
      };

  /// 根据 groupID 获取 config
  DisappearingMessageConfig? getConfigByGroupID(String groupID) {
    try {
      return groupConfigs.firstWhere((e) => e.groupID == groupID).config;
    } catch (e) {
      return null; // 没有找到返回 null
    }
  }

  /// 根据 userID 获取 config
  DisappearingMessageConfig? getConfigByUserID(String userID) {
    try {
      return groupConfigs.firstWhere((e) => e.userID == userID).config;
    } catch (e) {
      return null; // 没有找到返回 null
    }
  }
}

class UserGroupDisappearingConfig {
  String? userID;
  String? groupID;
  DisappearingMessageConfig config; // 单个对象

  UserGroupDisappearingConfig({
    this.userID,
    this.groupID,
    required this.config,
  });

  factory UserGroupDisappearingConfig.fromJson(Map<String, dynamic> json) {
    return UserGroupDisappearingConfig(
      userID: json['userID'] ?? '',
      groupID: json['groupID'] ?? '',
      config: DisappearingMessageConfig.fromJson(json['config'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'userID': userID,
        'groupID': groupID,
        'config': config.toJson(),
      };
}
