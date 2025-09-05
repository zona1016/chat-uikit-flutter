// ignore_for_file: unnecessary_getters_setters, avoid_print

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/group_profile_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/user_disappearing_configs.dart';
import 'package:tencent_cloud_chat_uikit/data_services/conversation/conversation_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/core_services_implements.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/group/group_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitProfile/disappearing_message.dart';
import 'package:tencent_im_base/tencent_im_base.dart';

class TUIGroupProfileModel extends ChangeNotifier {
  final CoreServicesImpl _coreServices = serviceLocator<CoreServicesImpl>();
  final GroupServices _groupServices = serviceLocator<GroupServices>();
  final ConversationService _conversationService =
      serviceLocator<ConversationService>();
  final MessageService _messageService = serviceLocator<MessageService>();
  final FriendshipServices _friendshipServices =
      serviceLocator<FriendshipServices>();
  final TUIChatGlobalModel _chatGlobalModel =
      serviceLocator<TUIChatGlobalModel>();
  GroupProfileLifeCycle? _lifeCycle;

  V2TimConversation? _conversation;
  String _groupID = "";
  List<V2TimFriendInfo>? _contactList;
  List<V2TimGroupMemberFullInfo?>? _groupMemberList;
  List<V2TimGroupMemberFullInfo?>? _groupOwnerList;
  List<V2TimGroupMemberFullInfo?>? _groupAdminMemberList;
  List<V2TimGroupMemberFullInfo?>? _groupCommonMemberList;
  String _groupMemberListSeq = "0";
  V2TimGroupInfo? _groupInfo;
  bool? _selfDestructMode;
  int _burnSeconds = 15;
  Function(String userID, TapDownDetails? tapDetails)? onClickUser;

  GroupProfileLifeCycle? get lifeCycle => _lifeCycle;

  set lifeCycle(GroupProfileLifeCycle? value) {
    _lifeCycle = value;
  }

  V2TimConversation? get conversation => _conversation;

  set conversation(V2TimConversation? value) {
    _conversation = value;
  }

  String get groupID => _groupID;

  set groupID(String value) {
    _groupID = value;
  }

  List<V2TimFriendInfo> get contactList => _contactList ?? [];

  set contactList(List<V2TimFriendInfo> value) {
    _contactList = value;
  }

  List<V2TimGroupMemberFullInfo?> get groupMemberList => _groupMemberList ?? [];

  List<V2TimGroupMemberFullInfo?> get groupOwnerList => _groupOwnerList ?? [];

  List<V2TimGroupMemberFullInfo?> get groupAdminMemberList =>
      _groupAdminMemberList ?? [];

  List<V2TimGroupMemberFullInfo?> get groupCommonMemberList =>
      _groupCommonMemberList ?? [];

  set groupMemberList(List<V2TimGroupMemberFullInfo?> value) {
    _groupMemberList = value;
  }

  V2TimGroupInfo? get groupInfo => _groupInfo;

  set groupInfo(V2TimGroupInfo? value) {
    _groupInfo = value;
  }

  bool? get selfDestructMode => _selfDestructMode;

  set selfDestructMode(bool? value) {
    _selfDestructMode = value;
  }

  int get burnSeconds => _burnSeconds;

  void loadData(String groupID) {
    _groupID = groupID;
    loadGroupInfo(groupID);
    loadGroupMemberList(groupID: groupID);
    _loadGroupOwnerMemberList(groupID: groupID);
    _loadGroupAdminMemberList(groupID: groupID);
    _loadGroupCommonMemberList(groupID: groupID);
    _loadConversation();
    _loadContactList();
    _loadSelfDestructMode();
    loadBurnSeconds("group_$groupID");
  }

  loadGroupInfo(String groupID) async {
    final groupInfo =
        await _groupServices.getGroupsInfo(groupIDList: [groupID]);
    if (groupInfo != null) {
      final groupRes = groupInfo.first;
      if (groupRes.resultCode == 0) {
        _groupInfo = groupRes.groupInfo;
      }
    }
    notifyListeners();
  }

  Future<void> loadGroupMemberList(
      {required String groupID, int count = 100, String? seq}) async {
    final String? nextSeq = await _loadGroupMemberListFunction(
        groupID: groupID, seq: seq, count: count);
    if (nextSeq != null && nextSeq != "0" && nextSeq != "") {
      return await loadGroupMemberList(
          groupID: groupID, count: count, seq: nextSeq);
    } else {
      notifyListeners();
    }
  }

  Future<String?> _loadGroupMemberListFunction(
      {required String groupID, int count = 100, String? seq}) async {
    if (seq == null || seq == "" || seq == "0") {
      _groupMemberList?.clear();
    }
    final res = await _groupServices.getGroupMemberList(
        groupID: groupID,
        filter: GroupMemberFilterTypeEnum.V2TIM_GROUP_MEMBER_FILTER_ALL,
        count: count,
        nextSeq: seq ?? _groupMemberListSeq);
    final groupMemberListRes = res.data;
    if (res.code == 0 && groupMemberListRes != null) {
      final groupMemberListTemp = groupMemberListRes.memberInfoList ?? [];
      // TODO
      outputLogger.i(
          "loadGroupMemberListfinish,groupMemberListTemp, ${groupMemberListRes.nextSeq},  ${groupMemberListTemp.length}");
      _groupMemberList = [...?_groupMemberList, ...groupMemberListTemp];
      _groupMemberListSeq = groupMemberListRes.nextSeq ?? "0";
    }
    return groupMemberListRes?.nextSeq;
  }

  Future<void> _loadGroupOwnerMemberList({required String groupID}) async {
    final res = await _groupServices.getGroupMemberList(
        groupID: groupID,
        filter: GroupMemberFilterTypeEnum.V2TIM_GROUP_MEMBER_FILTER_OWNER,
        count: 1,
        nextSeq: '0');
    final groupMemberListRes = res.data;
    if (res.code == 0 && groupMemberListRes != null) {
      _groupOwnerList = groupMemberListRes.memberInfoList ?? [];
    }
  }

  Future<void> _loadGroupAdminMemberList({required String groupID}) async {
    final res = await _groupServices.getGroupMemberList(
        groupID: groupID,
        filter: GroupMemberFilterTypeEnum.V2TIM_GROUP_MEMBER_FILTER_ADMIN,
        count: 10,
        nextSeq: '0');
    final groupMemberListRes = res.data;
    if (res.code == 0 && groupMemberListRes != null) {
      _groupAdminMemberList = groupMemberListRes.memberInfoList ?? [];
    }
  }

  Future<void> _loadGroupCommonMemberList({required String groupID}) async {
    final res = await _groupServices.getGroupMemberList(
        groupID: groupID,
        filter: GroupMemberFilterTypeEnum.V2TIM_GROUP_MEMBER_FILTER_COMMON,
        count: 10,
        nextSeq: '0');
    final groupMemberListRes = res.data;
    if (res.code == 0 && groupMemberListRes != null) {
      _groupCommonMemberList = groupMemberListRes.memberInfoList ?? [];
    }
  }

  _loadConversation() async {
    conversation = await _conversationService.getConversation(
        conversationID: "group_$_groupID");
  }

  _loadContactList() async {
    final res = await _friendshipServices.getFriendList();
    _contactList = res;
  }

  _loadSelfDestructMode() async {
    try {
      final conversationID = "group_$_groupID";

      // First check if there's a pending mode in global model
      final globalMode = _chatGlobalModel.getSelfDestructMode(conversationID);
      final pendingMode =
          _chatGlobalModel.getPendingConversationMode(conversationID);

      if (pendingMode != null) {
        // Use pending mode if available
        _selfDestructMode = pendingMode;
        print(
            'Loaded pending self-destruct mode for group: $_selfDestructMode');
        return;
      }

      if (globalMode) {
        // Use global model state if available
        _selfDestructMode = globalMode;
        print('Loaded global self-destruct mode for group: $_selfDestructMode');
        return;
      }

      // Fall back to conversation custom data
      final customData = await _getConversationCustomData(conversationID);
      _selfDestructMode =
          customData['conversation_default_mode'] == 'self_destruct';

      // Only update global model if we have explicit mode data - don't overwrite existing state
      if (customData.containsKey('conversation_default_mode')) {
        _chatGlobalModel.updateSelfDestructMode(
            conversationID, _selfDestructMode ?? false);
        print(
            'Updated global model with explicit mode for group: $_selfDestructMode');
      } else {
        print(
            'No explicit mode found, keeping existing global state for group');
      }

      print(
          'Loaded self-destruct mode from custom data for group: $_selfDestructMode');
    } catch (e) {
      print('Error loading self-destruct mode for group: $e');
      _selfDestructMode = false;
    }
  }

  pinedConversation(bool isPined) async {
    await _conversationService.pinConversation(
        conversationID: "group_$_groupID", isPinned: isPined);
    conversation?.isPinned = isPined;
    notifyListeners();
  }

  setMessageDisturb(bool value) async {
    final res = await _messageService.setGroupReceiveMessageOpt(
        groupID: _groupID,
        opt: value
            ? ReceiveMsgOptEnum.V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE
            : ReceiveMsgOptEnum.V2TIM_RECEIVE_MESSAGE);
    if (res.code == 0) {
      conversation?.recvOpt = (value
              ? ReceiveMsgOptEnum.V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE
              : ReceiveMsgOptEnum.V2TIM_RECEIVE_MESSAGE)
          .index;
    }
    notifyListeners();
  }

  setSelfDestructMode(bool value) async {
    try {
      // Get existing custom data
      final customData = await _getConversationCustomData("group_$_groupID");

      // Update the mode preference
      customData['conversation_default_mode'] =
          value ? 'self_destruct' : 'normal';

      // Clear burn_seconds when disabling self-destruct mode
      if (!value && customData.containsKey('burn_seconds')) {
        customData.remove('burn_seconds');
        print(
            'Cleared burn_seconds for group conversation since self-destruct mode disabled');
      }

      // Try to save to conversation custom data
      final saveSuccess = await _setConversationCustomDataWithResult(
          "group_$_groupID", customData);

      if (!saveSuccess) {
        // Conversation doesn't exist yet, store as pending
        _chatGlobalModel.setPendingConversationMode("group_$_groupID", value);
        print('Stored pending self-destruct mode for group: $value');
      } else {
        print('Saved self-destruct mode to custom data for group: $value');
      }

      // Update local state
      _selfDestructMode = value;
      notifyListeners();

      // Update the global model's self-destruct state for this conversation
      _chatGlobalModel.updateSelfDestructMode("group_$_groupID", value);
      print('Updated global model self-destruct mode: $value');
    } catch (e) {
      print('Error setting self-destruct mode: $e');
    }
  }

  setBurnSeconds(String conversationID, int seconds) async {
    try {
      // Update local state
      _burnSeconds = seconds;
      notifyListeners();

      // Update the global model's burn seconds for this conversation
      await _chatGlobalModel.setConversationBurnSeconds(
          conversationID, seconds);
      print('Updated conversation burn seconds for group: $seconds');
    } catch (e) {
      print('Error setting burn seconds for group: $e');
    }
  }

  loadBurnSeconds(String conversationID) async {
    try {
      // Load burn seconds from global model
      _burnSeconds =
          _chatGlobalModel.getConversationBurnSeconds(conversationID);

      // Also try to load from conversation custom data to sync
      final customData = await _getConversationCustomData(conversationID);
      final burnSeconds = customData['burn_seconds'] as int?;
      if (burnSeconds != null) {
        _burnSeconds = burnSeconds;
        // Update global model with the loaded value
        await _chatGlobalModel.setConversationBurnSeconds(
            conversationID, burnSeconds);
      }

      print('Loaded burn seconds for group conversation: $_burnSeconds');
      notifyListeners();
    } catch (e) {
      print('Error loading burn seconds: $e');
      _burnSeconds = _chatGlobalModel.defaultBurnSeconds;
    }
  }

  /// Get conversation custom data
  Future<Map<String, dynamic>> _getConversationCustomData(
      String conversationID) async {
    try {
      final result = await TencentImSDKPlugin.v2TIMManager
          .getConversationManager()
          .getConversation(conversationID: conversationID);

      if (result.code == 0 && result.data != null) {
        final customDataStr = result.data!.customData ?? "";
        if (customDataStr.isNotEmpty) {
          return Map<String, dynamic>.from(jsonDecode(customDataStr));
        }
      }
    } catch (e) {
      print('Error getting conversation custom data: $e');
    }
    return {};
  }

  /// Set conversation custom data and return success status
  Future<bool> _setConversationCustomDataWithResult(
      String conversationID, Map<String, dynamic> customData) async {
    try {
      final result = await TencentImSDKPlugin.v2TIMManager
          .getConversationManager()
          .setConversationCustomData(
        conversationIDList: [conversationID],
        customData: jsonEncode(customData),
      );
      return result.code == 0;
    } catch (e) {
      print('Error setting conversation custom data: $e');
      return false;
    }
  }

  Future<V2TimValueCallback<V2GroupMemberInfoSearchResult>> searchGroupMember(
      V2TimGroupMemberSearchParam searchParam) async {
    final res =
        await _groupServices.searchGroupMembers(searchParam: searchParam);

    if (res.code == 0) {}
    return res;
  }

  disappearing(Map<String, String>? groupCustomInfo) async {
    if (_groupInfo != null) {
      groupCustomInfo?['disappearing_message_time'] =
          DateTime.now().millisecondsSinceEpoch.toString();
      final customInfo = Map<String, String>.from(_groupInfo!.customInfo ?? {});
      customInfo['disappearing'] = jsonEncode(groupCustomInfo);

      final info = V2TimGroupInfo(
        groupID: _groupID,
        groupType: _groupInfo!.groupType,
        customInfo: customInfo,
      );
      final response = await _groupServices.setGroupInfo(info: info);
      if (response.code == 0) {
        final loginUserInfo = TIMUIKitCore.getInstance().loginInfo;
        final disappearingMessage = await GetStorage().read('disappearing_message_${loginUserInfo.userID}');
        UserDisappearingConfigs configs = UserDisappearingConfigs.fromJson(disappearingMessage);

        bool found = false;

        for (UserGroupDisappearingConfig item in configs.groupConfigs) {
          if (item.userID == _groupID) {
            item.config.startTime =
                DateTime.now().millisecondsSinceEpoch.toString();
            found = true;
            break; // 已找到，退出循环
          }
        }

        if (!found) {
          configs.groupConfigs.add(
            UserGroupDisappearingConfig(
              groupID: _groupID,
              config: DisappearingMessageConfig.fromJson(customInfo),
            ),
          );
        }
        await GetStorage().write('disappearing_message_${loginUserInfo.userID}', configs.toJson());

        _groupInfo!.customInfo = customInfo;
        notifyListeners();
      }
    }
  }

  allowAddingFriends(bool isAllow) async {
    if (_groupInfo != null) {
      final customInfo = Map<String, String>.from(_groupInfo!.customInfo ?? {});
      customInfo['url_detail'] = isAllow ? 'true' : 'false';
      final info = V2TimGroupInfo(
        groupID: _groupID,
        groupType: _groupInfo!.groupType,
        customInfo: customInfo,
      );
      final response = await _groupServices.setGroupInfo(info: info);
      if (response.code == 0) {
        _groupInfo!.customInfo = customInfo;
        notifyListeners();
      }
    }
  }

  Future<V2TimCallback?> setGroupFaceUrl(String faceUrl) async {
    if (_groupInfo != null) {
      String? originalGroupFaceUrl = _groupInfo?.faceUrl;
      _groupInfo?.faceUrl = faceUrl;
      final info = V2TimGroupInfo(
        groupID: _groupID,
        groupType: _groupInfo!.groupType,
        faceUrl: faceUrl,
      );
      final response = await _groupServices.setGroupInfo(info: info);
      if (response.code != 0) {
        _groupInfo?.faceUrl = originalGroupFaceUrl;
      }
      notifyListeners();
      return response;
    }
    return null;
  }

  Future<V2TimCallback?> setGroupName(String groupName) async {
    if (_groupInfo != null) {
      String? originalGroupName = _groupInfo?.groupName;
      _groupInfo?.groupName = groupName;
      final info = V2TimGroupInfo(
        groupID: _groupID,
        groupType: _groupInfo!.groupType,
        groupName: groupName,
      );
      final response = await _groupServices.setGroupInfo(info: info);
      if (response.code != 0) {
        _groupInfo?.groupName = originalGroupName;
      }
      notifyListeners();
      return response;
    }
    return null;
  }

  setGroupNotification(String notification) async {
    if (_groupInfo != null) {
      final info = V2TimGroupInfo(
        groupID: _groupID,
        groupType: _groupInfo!.groupType,
        notification: notification,
      );
      final response = await _groupServices.setGroupInfo(info: info);
      if (response.code == 0) {
        notifyListeners();
        _groupInfo?.notification = notification;
      }
    }
  }

  String getSelfNameCard() {
    try {
      final loginUserID = _coreServices.loginUserInfo?.userID;
      String nameCard = "";
      if (_groupMemberList != null) {
        nameCard = groupMemberList
                .firstWhere((element) => element?.userID == loginUserID)
                ?.nameCard ??
            "";
      }

      return nameCard;
    } catch (err) {
      return "";
    }
  }

  Future<V2TimCallback?> setNameCard(String nameCard) async {
    final loginUserID = _coreServices.loginUserInfo?.userID;
    if (loginUserID != null) {
      final res = await _groupServices.setGroupMemberInfo(
          groupID: _groupID, userID: loginUserID, nameCard: nameCard);
      if (res.code == 0) {
        final targetIndex = _groupMemberList
            ?.indexWhere((element) => element?.userID == loginUserID);
        if (targetIndex != -1) {
          _groupMemberList![targetIndex!]!.nameCard = nameCard;
          notifyListeners();
        }
      }
      return res;
    }
    return null;
  }

  Future<V2TimCallback?> setGroupAddOpt(int addOpt) async {
    if (_groupInfo != null) {
      int? originalAddopt = _groupInfo?.groupAddOpt;
      _groupInfo?.groupAddOpt = addOpt;
      final response = await _groupServices.setGroupInfo(
          info: V2TimGroupInfo.fromJson({
        "groupID": _groupID,
        "groupType": _groupInfo!.groupType,
        "groupAddOpt": addOpt
      }));
      if (response.code != 0) {
        _groupInfo?.groupAddOpt = originalAddopt;
      }
      notifyListeners();
      return response;
    }
    return null;
  }

  Future<V2TimCallback> setMemberToNormal(String userID) async {
    final res = await _groupServices.setGroupMemberRole(
        groupID: _groupID,
        userID: userID,
        role: GroupMemberRoleTypeEnum.V2TIM_GROUP_MEMBER_ROLE_MEMBER);
    if (res.code == 0) {
      final targetIndex =
          _groupMemberList!.indexWhere((e) => e!.userID == userID);
      if (targetIndex != -1) {
        final targetElem = _groupMemberList![targetIndex];
        targetElem?.role = GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_MEMBER;
        _groupMemberList![targetIndex] = targetElem;
      }
      notifyListeners();
    }
    return res;
  }

  Future<V2TimCallback> setMemberToAdmin(String userID) async {
    final res = await _groupServices.setGroupMemberRole(
        groupID: _groupID,
        userID: userID,
        role: GroupMemberRoleTypeEnum.V2TIM_GROUP_MEMBER_ROLE_ADMIN);
    if (res.code == 0) {
      final targetIndex =
          _groupMemberList!.indexWhere((e) => e!.userID == userID);
      if (targetIndex != -1) {
        final targetElem = _groupMemberList![targetIndex];
        targetElem?.role = GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_ADMIN;
        _groupMemberList![targetIndex] = targetElem;
      }
      notifyListeners();
    }
    return res;
  }

  bool canInviteMember() {
    final groupType = _groupInfo?.groupType;
    return groupType == GroupType.Work || groupType == "Private";
  }

  bool canKickOffMember() {
    final isGroupOwner =
        _groupInfo?.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_OWNER;
    final isAdmin =
        _groupInfo?.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_ADMIN;
    if (_groupInfo?.groupType == GroupType.Work) {
      /// work 群主才能踢人
      return isGroupOwner;
    }

    if (_groupInfo?.groupType == GroupType.Public ||
        _groupInfo?.groupType == GroupType.Meeting) {
      /// public || meeting 群主和管理员可以踢人
      return isGroupOwner || isAdmin;
    }

    return false;
  }

  Future<V2TimCallback?> setMuteAll(bool muteAll) async {
    if (_groupInfo != null) {
      _groupInfo?.isAllMuted = muteAll;
      final response = await _groupServices.setGroupInfo(
          info: V2TimGroupInfo.fromJson({
        "groupID": _groupInfo!.groupID,
        "groupType": _groupInfo!.groupType,
        "isAllMuted": muteAll
      }));
      if (response.code != 0) {
        _groupInfo?.isAllMuted = muteAll;
      }
      notifyListeners();
      return response;
    }
    return null;
  }

  Future<V2TimCallback?> muteGroupMember(
      String userID, bool isMute, int? serverTime) async {
    const muteTime = 315360000;
    final res = await _groupServices.muteGroupMember(
        groupID: _groupID, userID: userID, seconds: isMute ? muteTime : 0);
    if (res.code == 0) {
      final targetIndex =
          _groupMemberList!.indexWhere((e) => e!.userID == userID);
      if (targetIndex != -1) {
        final targetElem = _groupMemberList![targetIndex];
        targetElem?.muteUntil = isMute ? (serverTime ?? 0) + muteTime : 0;
        _groupMemberList![targetIndex] = targetElem;
      }
      notifyListeners();
    }
    return null;
  }

  Future<V2TimCallback> kickOffMember(List<String> userIDs) async {
    final res = await _groupServices.kickGroupMember(
        groupID: _groupID, memberList: userIDs);
    return res;
  }

  Future<V2TimValueCallback<List<V2TimGroupMemberOperationResult>>>
      inviteUserToGroup(List<String> userIDS) async {
    final res = await _groupServices.inviteUserToGroup(
        groupID: _groupID, userList: userIDS);
    return res;
  }
}
