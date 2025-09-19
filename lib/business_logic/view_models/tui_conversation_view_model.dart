// ignore_for_file: unnecessary_getters_setters

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/conversation_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_profile_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_self_info_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/user_disappearing_configs.dart';
import 'package:tencent_cloud_chat_uikit/data_services/conversation/conversation_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitProfile/disappearing_message.dart';

List<T> removeDuplicates<T>(
    List<T> list, bool Function(T first, T second) isEqual) {
  List<T> output = [];
  for (var i = 0; i < list.length; i++) {
    bool found = false;
    for (var j = 0; j < output.length; j++) {
      if (isEqual(list[i], output[j])) {
        found = true;
      }
    }
    if (!found) {
      output.add(list[i]);
    }
  }

  return output;
}

class TUIConversationViewModel extends ChangeNotifier {
  final TUISelfInfoViewModel selfInfoViewModel =
      serviceLocator<TUISelfInfoViewModel>();
  final ConversationService _conversationService =
      serviceLocator<ConversationService>();
  final FriendshipServices _friendshipServices =
      serviceLocator<FriendshipServices>();
  final TUIChatGlobalModel _chatGlobalModel =
      serviceLocator<TUIChatGlobalModel>();
  final MessageService _messageService = serviceLocator<MessageService>();
  late V2TimConversationListener _conversationListener;
  List<V2TimConversation?> _conversationList = [];
  static V2TimConversation? _selectedConversation;
  Map<String, String> webDraftMap = {};

  bool _haveMoreData = true;
  int _totalUnReadCount = 0;
  String? _scrollToConversation;
  final TUIChatGlobalModel globalChatModel =
      serviceLocator<TUIChatGlobalModel>();

  List<String> needUpdateGroup = [];

  String _nextSeq = "0";
  ConversationLifeCycle? _lifeCycle;

  // 用来处理定时删除聊天消息
  Timer? _timer;

  List<V2TimConversation?> get conversationList {
    if (PlatformUtils().isWeb) {
      try {
        _conversationList.sort((a, b) {
          return b!.lastMessage!.timestamp!
              .compareTo(a!.lastMessage!.timestamp!);
        });

        final pinnedConversation = _conversationList
            .where((element) => element?.isPinned == true)
            .toList();
        _conversationList.removeWhere((element) => element?.isPinned == true);
        _conversationList = [...pinnedConversation, ..._conversationList];
        // ignore: empty_catches
      } catch (e) {}
    } else {
      _conversationList.sort((a, b) => b!.orderkey!.compareTo(a!.orderkey!));
    }
    return _conversationList;
  }

  String? get scrollToConversation => _scrollToConversation;

  set scrollToConversation(String? value) {
    _scrollToConversation = value;
    notifyListeners();
  }

  void clearScrollToConversation() {
    _scrollToConversation = null;
  }

  bool get haveMoreData {
    return _haveMoreData;
  }

  int get totalUnReadCount => _totalUnReadCount;

  set totalUnReadCount(int value) {
    _totalUnReadCount = value;
  }

  set lifeCycle(ConversationLifeCycle? value) {
    _lifeCycle = value;
  }

  set conversationList(List<V2TimConversation?> conversationList) {
    _conversationList = conversationList;
    notifyListeners();
  }

  set selectedConversation(V2TimConversation? value) {
    _selectedConversation = value;
    notifyListeners();
  }

  needNotifyListeners() {
    notifyListeners();
  }

  V2TimConversation? get selectedConversation {
    return _selectedConversation;
  }

  static V2TimConversation? of() {
    return _selectedConversation;
  }

  TUIConversationViewModel() {
    _conversationListener = V2TimConversationListener(
      onConversationChanged: (conversationList) {
        _onConversationListChanged(conversationList);
      },
      onNewConversation: (conversationList) async {
        _addNewConversation(conversationList);
        getDisappearingDuration(list: conversationList);
      },
      onTotalUnreadMessageCountChanged: (totalUnread) {
        _totalUnReadCount = totalUnread;
        _chatGlobalModel.totalUnReadCount = totalUnread;
        notifyListeners();
      },
      onSyncServerFinish: () {
        // Remove the process to load such a many of conversations after launching
        if (!PlatformUtils().isWeb) {
          loadInitConversation();
        }
      },
      onConversationDeleted: (conversationIDList) {
        _onConversationListDelete(conversationIDList);
      },
    );
  }

  loadInitConversation() async {
    await loadData(count: 40);
    // Remove the process to load such a many of conversations after launching
    // if (selfInfoViewModel.globalConfig?.isPreloadMessagesAfterInit ?? true) {
    //   _chatGlobalModel.initMessageMapFromLocalDatabase(_conversationList);
    // }
  }

  initConversation() async {
    clearData();
    loadInitConversation();
  }

  Future<void> loadData({required int count}) async {
    _haveMoreData = true;
    final isRefresh = _nextSeq == "0";
    final conversationResult = await _conversationService.getConversationList(
        nextSeq: _nextSeq, count: count);
    _nextSeq = conversationResult?.nextSeq ?? "";
    final conversationList = conversationResult?.conversationList;
    if (conversationList != null) {
      if (conversationList.isEmpty || conversationList.length < count) {
        _haveMoreData = false;
      }
      List<V2TimConversation?> combinedConversationList = [];
      if (isRefresh) {
        combinedConversationList = conversationList;
      } else {
        combinedConversationList = [..._conversationList, ...conversationList];
      }
      final List<V2TimConversation?> finalConversationList = await _lifeCycle
              ?.conversationListWillMount(combinedConversationList) ??
          combinedConversationList;
      _conversationList = removeDuplicates<V2TimConversation?>(
          finalConversationList,
          (item1, item2) => item1?.conversationID == item2?.conversationID);

      // 获取是否设置了清空消息 如果是获取最小的刷新时间
      getDisappearingDuration(list: _conversationList);
      // 处理数据
      notifyListeners();
    }
    _totalUnReadCount = await _conversationService.getTotalUnreadCount();
    notifyListeners();
    return;
  }

  void setSelectedConversation(V2TimConversation conversation) {
    _selectedConversation = conversation;
    notifyListeners();
  }

  Future<V2TimCallback> pinConversation({
    required String conversationID,
    required bool isPinned,
  }) {
    return _conversationService.pinConversation(
        conversationID: conversationID, isPinned: isPinned);
  }

  Future<V2TimCallback?> clearHistoryMessage(
      {required String convID, required int convType}) async {
    if (_lifeCycle?.shouldClearHistoricalMessageForConversation != null &&
        await _lifeCycle!.shouldClearHistoricalMessageForConversation(convID) ==
            false) {
      return null;
    }

    globalChatModel.setMessageList(convID, []);

    if (convType == 1) {
      return _messageService.clearC2CHistoryMessage(userID: convID);
    } else {
      return _messageService.clearGroupHistoryMessage(groupID: convID);
    }
  }

  searchFriends(String searchKey) async {
    final res = await _friendshipServices.searchFriends(
        searchParam: V2TimFriendSearchParam(keywordList: [searchKey]));
    return res;
  }

  Future<V2TimCallback?> deleteConversation(
      {required String conversationID}) async {
    if (_lifeCycle?.shouldDeleteConversation != null &&
        await _lifeCycle!.shouldDeleteConversation(conversationID) == false) {
      return null;
    }
    final res = await _conversationService.deleteConversation(
        conversationID: conversationID);
    if (res.code == 0) {
      _conversationList
          .removeWhere((element) => element?.conversationID == conversationID);
      notifyListeners();
    }
    return res;
  }

  _onConversationListChanged(List<V2TimConversation> list) async {
    for (int element = 0; element < list.length; element++) {
      V2TimConversation conversation = list[element];
      // 处理是否要刷新
      final isChannelOrTeam = (TencentUtils.india == conversation.groupID ||
          TencentUtils.korea == conversation.groupID ||
          TencentUtils.english == conversation.groupID ||
          TencentUtils.chinese == conversation.groupID ||
          TencentUtils.french == conversation.groupID ||
          TencentUtils.german == conversation.groupID ||
          TencentUtils.aidTeam == conversation.groupID);
      if (isChannelOrTeam) {
        if (conversation.lastMessage?.elemType != 9 &&
            conversation.lastMessage?.elemType != 11) {
          if (conversation.groupID != null &&
              !needUpdateGroup.contains(conversation.groupID)) {
            needUpdateGroup.add(conversation.groupID!);
          }
        }
      }

      int index = _conversationList.indexWhere(
          (item) => item!.conversationID == list[element].conversationID);
      if (index > -1) {
        _conversationList.setAll(
            index, [list[element]] as List<V2TimConversation?>);
      } else {
        _conversationList.add(list[element]);
      }
    }

    notifyListeners();
  }

  _onConversationListDelete(List<String> list) async {
    _conversationList.removeWhere(
        (conversation) => list.contains('group_${conversation?.groupID}'));
    notifyListeners();
  }

  _addNewConversation(List<V2TimConversation> list) {
    _conversationList.addAll(list);
    _conversationList = removeDuplicates<V2TimConversation?>(_conversationList,
        (item1, item2) => item1?.conversationID == item2?.conversationID);
    notifyListeners();
  }

  setConversationListener() {
    _conversationService.addConversationListener(
        listener: _conversationListener);
  }

  removeConversationListener() {
    _conversationService.removeConversationListener(
        listener: _conversationListener);
  }

  Future<V2TimCallback> setConversationDraft({
    required String conversationID,
    String? draftText,
    bool isTopic = false,
    String? groupID,
    bool isAllowWeb = true,
  }) async {
    assert(!isTopic || (groupID != null && groupID.isNotEmpty),
        "When 'isTopic' is true, 'groupID' must not be null or empty.");
    if (PlatformUtils().isWeb && isAllowWeb) {
      webDraftMap[conversationID] = draftText ?? "";
      return V2TimCallback(code: 0, desc: "");
    } else {
      if (isTopic) {
        final topicInfoList = await TencentImSDKPlugin.v2TIMManager
            .getGroupManager()
            .getTopicInfoList(groupID: groupID!, topicIDList: [conversationID]);
        final topicInfo = topicInfoList.data?.first.topicInfo;
        topicInfo?.draftText = draftText;
        //tencent_chat 8.5
        final res = await TencentImSDKPlugin.v2TIMManager
            .getGroupManager()
            .setTopicInfo(topicInfo: topicInfo!);
        //tencent_chat 8.2 - 确定升级了才去掉
        // final res = await TencentImSDKPlugin.v2TIMManager.getGroupManager().setTopicInfo(groupID: groupID, topicInfo: topicInfo!);
        return res;
      } else {
        return _conversationService.setConversationDraft(
            conversationID: conversationID, draftText: draftText);
      }
    }
  }

  clearWebDraft({
    required String conversationID,
  }) {
    webDraftMap[conversationID] = "";
  }

  String? getWebDraft({
    required String conversationID,
  }) {
    return TencentUtils.checkString(webDraftMap[conversationID]);
  }

  clearData() {
    _conversationList = [];
    _selectedConversation = null;
    _nextSeq = "0";
    _haveMoreData = true;
    notifyListeners();
  }

  refresh({int count = 100}) {
    _nextSeq = "0";
    _haveMoreData = true;
    loadData(count: count);
  }

  // 定时删除聊天历史消息 相关方法
  Future<void> getDisappearingDuration({
    required List<V2TimConversation?> list,
  }) async {
    List<String> userIDs = [];
    List<String> groupIDs = [];
    List<UserGroupDisappearingConfig> configs = [];

    for (var item in list) {
      if (item?.userID != null) {
        userIDs.add(item!.userID!);
      }
      if (item?.groupID != null) {
        groupIDs.add(item!.groupID!);
      }
    }

    final loginUserInfo = TIMUIKitCore.getInstance().loginInfo;
    final storageKey = 'disappearing_message_${loginUserInfo.userID}';

    // 读取旧数据
    final oldJson = await GetStorage().read(storageKey);
    UserDisappearingConfigs oldConfigs = oldJson != null
        ? UserDisappearingConfigs.fromJson(oldJson)
        : UserDisappearingConfigs(
        loginUserID: loginUserInfo.userID, groupConfigs: []);

    print(oldConfigs.toJson());
    print('-----------------');
    print(oldConfigs.groupConfigs.length);
    // 1. 获取用户信息
    final userInfo =
    await TIMUIKitCore.getInstance().getUsersInfo(userIDList: userIDs);
    if (userInfo.code == 0) {
      for (V2TimUserFullInfo userFullInfo in userInfo.data ?? []) {
        if (userFullInfo.customInfo != null &&
            userFullInfo.customInfo!['disappea'] != null) {
          String disappea = userFullInfo.customInfo!['disappea']!;
          final parsed = jsonDecode(disappea);
          if (parsed['disappearing_message_${loginUserInfo.userID}'] != null) {
            final userConfig = DisappearingMessageConfig.fromJson(
                jsonDecode(parsed['disappearing_message_${loginUserInfo.userID}']!));
            if (userConfig.totalDuration.inSeconds > 0 &&
                oldConfigs.getConfigByUserID(userFullInfo.userID ?? '') == null) {
              if (DateTime.now().millisecondsSinceEpoch >=
                  int.parse(userConfig.startTime) +
                      userConfig.totalDuration.inMilliseconds) {
                final result = await clearHistoryMessage(
                    convID: userFullInfo.userID ?? '', convType: 1);
                if (result?.code == 0) {
                  userConfig.startTime =
                      DateTime.now().millisecondsSinceEpoch.toString();
                }
              }
              configs.add(UserGroupDisappearingConfig(
                  userID: userFullInfo.userID ?? '', config: userConfig));
            }
          }
        }
      }
    } else {
      print("获取好友信息失败: ${userInfo.code}, ${userInfo.desc}");
    }

    // 2. 获取群组信息
    final groupInfo = await TencentImSDKPlugin.v2TIMManager
        .getGroupManager()
        .getGroupsInfo(groupIDList: groupIDs);
    if (groupInfo.code == 0) {
      for (var item in groupInfo.data ?? []) {
        V2TimGroupInfo? group = item.groupInfo;
        if (group != null &&
            group.customInfo != null &&
            group.customInfo!['disappearing'] != null &&
            group.customInfo!['disappearing']!.isNotEmpty) {
          final userConfig = DisappearingMessageConfig.fromJson(
              jsonDecode(group.customInfo!['disappearing']!));
          if (userConfig.totalDuration.inSeconds > 0 &&
              oldConfigs.getConfigByGroupID(group.groupID ?? '') == null) {
            if (DateTime.now().millisecondsSinceEpoch >=
                int.parse(userConfig.startTime) +
                    userConfig.totalDuration.inMilliseconds) {
              final result =
              await clearHistoryMessage(convID: group.groupID, convType: 2);
              if (result?.code == 0) {
                userConfig.startTime =
                    DateTime.now().millisecondsSinceEpoch.toString();
              }
            }
            configs.add(UserGroupDisappearingConfig(
                groupID: group.groupID, config: userConfig));
          }
        }
      }
    } else {
      print("获取群组信息失败: ${groupInfo.code}, ${groupInfo.desc}");
    }

    print('#########');
    print(configs.length);
    // 🔑 合并并保存
    await saveConfigs(
      loginUserID: loginUserInfo.userID,
      newConfigs: configs,
    );

    // 定时器逻辑
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final oldJson = await GetStorage().read(storageKey);
      if (oldJson == null) return;

      UserDisappearingConfigs configs =
      UserDisappearingConfigs.fromJson(oldJson);

      for (UserGroupDisappearingConfig item in configs.groupConfigs) {
        if ((item.config.totalDuration != Duration.zero) &&
            (DateTime.now().millisecondsSinceEpoch >=
                int.parse(item.config.startTime) +
                    item.config.totalDuration.inMilliseconds)) {
          V2TimCallback? result;
          if (item.userID != null && item.userID!.isNotEmpty) {
            result = await clearHistoryMessage(convID: item.userID!, convType: 1);
          }
          if (item.groupID != null && item.groupID!.isNotEmpty) {
            result =
            await clearHistoryMessage(convID: item.groupID!, convType: 2);
          }
          if (result?.code == 0) {
            notifyListeners();
            item.config.startTime =
                DateTime.now().millisecondsSinceEpoch.toString();
          }
        }
      }

      // 保存更新后的
      await saveConfigs(
        loginUserID: loginUserInfo.userID,
        newConfigs: configs.groupConfigs,
      );
    });
  }

  /// 统一的保存逻辑：读 → 合并 → 写
  Future<void> saveConfigs({
    required String loginUserID,
    required List<UserGroupDisappearingConfig> newConfigs,
  }) async {
    final storageKey = 'disappearing_message_$loginUserID';
    final oldJson = await GetStorage().read(storageKey);
    final oldConfigs = oldJson != null
        ? UserDisappearingConfigs.fromJson(oldJson)
        : UserDisappearingConfigs(loginUserID: loginUserID, groupConfigs: []);

    final merged = {
      for (var item in oldConfigs.groupConfigs)
        ((item.userID?.isNotEmpty ?? false) ? item.userID! : item.groupID!): item,
      for (var item in newConfigs)
        ((item.userID?.isNotEmpty ?? false) ? item.userID! : item.groupID!): item,
    };

    final result = UserDisappearingConfigs(
      loginUserID: loginUserID,
      groupConfigs: merged.values.toList(),
    );

    print('!!!!!!!!!!!!!!!!!!');
    print(result.groupConfigs.length);
    await GetStorage().write(storageKey, result.toJson());
  }

}
