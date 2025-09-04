// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tencent_im_base/tencent_im_base.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/profile_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/model/profile_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_friendship_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/conversation/conversation_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/core_services_implements.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';

class TUIProfileViewModel extends ChangeNotifier {
  final ConversationService _conversationService =
      serviceLocator<ConversationService>();
  final FriendshipServices _friendshipServices =
      serviceLocator<FriendshipServices>();
  final TUIFriendShipViewModel _friendShipViewModel =
      serviceLocator<TUIFriendShipViewModel>();
  final CoreServicesImpl _coreServices = serviceLocator<CoreServicesImpl>();
  final MessageService _messageService = serviceLocator<MessageService>();
  final TUIChatGlobalModel _chatGlobalModel = serviceLocator<TUIChatGlobalModel>();

  UserProfile? _userProfile;
  ProfileLifeCycle? _lifeCycle;
  bool? _shouldAddToBlackList;
  int _friendType = 0;
  bool? _isDisturb;
  bool _selfDestructMode = false;

  UserProfile? get userProfile {
    return _userProfile;
  }

  set userProfile(UserProfile? value) {
    _userProfile = value;
    notifyListeners();
  }

  bool? get isDisturb {
    return _isDisturb;
  }

  bool? get isAddToBlackList {
    return _shouldAddToBlackList;
  }

  bool get selfDestructMode {
    return _selfDestructMode;
  }

  int get friendType {
    return _friendType;
  }

  set lifeCycle(ProfileLifeCycle? value) {
    _lifeCycle = value;
  }

  loadData({required String userID, bool isNeedConversation = true}) async {
    if(userID.isEmpty){
      return;
    }
    V2TimFriendInfo? friendUserInfo;
    V2TimConversation? conversation;
    final userInfoList =
        await _friendshipServices.getFriendsInfo(userIDList: [userID]);
    final checkFriend = await _friendshipServices.checkFriend(
        userIDList: [userID],
        checkType: FriendTypeEnum.V2TIM_FRIEND_TYPE_SINGLE);

    if (checkFriend != null) {
      final res = checkFriend.first;
      if (res.resultCode == 0) {
        _friendType = res.resultType;
      }
    }

    if (userInfoList != null) {
      friendUserInfo = userInfoList[0].friendInfo;
    }

    if (isNeedConversation) {
      conversation = await _conversationService.getConversation(
          conversationID: "c2c_$userID");
      _isDisturb = conversation?.recvOpt == 2;
      // Load self-destruct mode state
      await _loadSelfDestructMode("c2c_$userID");
    }

    final friendInfo =
        await _lifeCycle?.didGetFriendInfo(friendUserInfo) ?? friendUserInfo;

    _isDisturb = conversation?.recvOpt == 2;
    _userProfile =
        UserProfile(friendInfo: friendInfo, conversation: conversation);

    _shouldAddToBlackList = _friendShipViewModel.blockList
            .indexWhere((element) => element.userID == userID) >
        -1;

    notifyListeners();
  }

  Future<V2TimCallback> pinedConversation(bool isPined, String convID) async {
    final res = await _conversationService.pinConversation(
        conversationID: convID, isPinned: isPined);
    _userProfile?.conversation!.isPinned = isPined;
    notifyListeners();
    return res;
  }

  Future<List<V2TimFriendOperationResult>?> addToBlackList(
      bool shouldAdd, String userID) async {
    if (_lifeCycle?.shouldAddToBlockList != null &&
        await _lifeCycle!.shouldAddToBlockList(userID) == false) {
      return null;
    }
    if (shouldAdd) {
      final res =
          await _friendshipServices.addToBlackList(userIDList: [userID]);
      if (res != null && res.isNotEmpty) {
        final result = res.first;
        if (result.resultCode == 0) {
          _shouldAddToBlackList = true;
          _friendType = 0;
        }
      }
      notifyListeners();
      return res;
    } else {
      final res =
          await _friendshipServices.deleteFromBlackList(userIDList: [userID]);
      if (res != null && res.isNotEmpty) {
        final result = res.first;
        if (result.resultCode == 0) {
          _shouldAddToBlackList = false;
          final checkFriend = await _friendshipServices.checkFriend(
              userIDList: [userID],
              checkType: FriendTypeEnum.V2TIM_FRIEND_TYPE_SINGLE);
          if (checkFriend != null) {
            final res = checkFriend.first;
            _friendType = res.resultType;
          }
        }
      }
      _friendShipViewModel.loadBlockListData();
      notifyListeners();
      return res;
    }
  }

  Future<V2TimFriendOperationResult?> deleteFriend(String userID) async {
    if (_lifeCycle?.shouldDeleteFriend != null &&
        await _lifeCycle!.shouldDeleteFriend(userID) == false) {
      return null;
    }
    final res = await _friendshipServices.deleteFromFriendList(
        userIDList: [userID],
        deleteType: FriendTypeEnum.V2TIM_FRIEND_TYPE_BOTH);
    if (res != null) {
      loadData(userID: userID);
      return res.first;
    }
    return null;
  }

  Future<V2TimCallback> changeFriendVerificationMethod(int allowType) async {
    final res = await _coreServices.setSelfInfo(
      userFullInfo: V2TimUserFullInfo.fromJson(
        {"allowType": allowType},
      ),
    );
    if (res.code == 0) {
      _userProfile?.friendInfo!.userProfile!.allowType = allowType;
      notifyListeners();
    }
    return res;
  }

  // 1：男 女：2
  Future<V2TimCallback> updateGender(int gender) async {
    final res = await _coreServices.setSelfInfo(
      userFullInfo: V2TimUserFullInfo.fromJson(
        {"gender": gender},
      ),
    );
    if (res.code == 0) {
      _userProfile?.friendInfo!.userProfile!.gender = gender;
      notifyListeners();
    }

    return res;
  }

  Future<V2TimCallback> updateNickName(String nickName) async {
    final res = await _coreServices.setSelfInfo(
      userFullInfo: V2TimUserFullInfo.fromJson(
        {"nickName": nickName},
      ),
    );

    if (res.code == 0) {
      _userProfile?.friendInfo!.userProfile!.nickName = nickName;
      notifyListeners();
    }

    return res;
  }

  Future<V2TimCallback> updateSelfSignature(String selfSignature) async {
    final res = await _coreServices.setSelfInfo(
      userFullInfo: V2TimUserFullInfo.fromJson(
        {"selfSignature": selfSignature},
      ),
    );
    if (res.code == 0) {
      _userProfile?.friendInfo!.userProfile!.selfSignature = selfSignature;
      notifyListeners();
    }
    return res;
  }

  Future<V2TimFriendOperationResult?> addFriend(String userID) async {
    if (_lifeCycle?.shouldAddFriend != null &&
        await _lifeCycle!.shouldAddFriend(userID) == false) {
      return null;
    }
    final res = await _friendshipServices.addFriend(
        userID: userID, addType: FriendTypeEnum.V2TIM_FRIEND_TYPE_BOTH);
    if (res.code == 0) {
      loadData(userID: userID);
      return res.data;
    }
    return null;
  }

  Future<V2TimCallback> updateRemarks(String userID, String remark) async {
    final res = await _friendshipServices.setFriendInfo(
        userID: userID, friendRemark: remark);

    if (res.code == 0) {
      _userProfile?.friendInfo!.friendRemark = remark;
      notifyListeners();
    }
    return res;
  }

  Future<V2TimCallback> updateCustomInfo(String userID, Map<String, String>? friendCustomInfo) async {
    final res = await _friendshipServices.setFriendInfo(
        userID: userID, friendCustomInfo: friendCustomInfo);

    if (res.code == 0) {
      _userProfile?.friendInfo!.friendCustomInfo = friendCustomInfo;
      notifyListeners();
    }
    return res;
  }

  Future<V2TimCallback> setMessageDisturb(String userID, bool isDisturb) async {
    final res = await _messageService.setC2CReceiveMessageOpt(
        userIDList: [userID],
        opt: isDisturb
            ? ReceiveMsgOptEnum.V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE
            : ReceiveMsgOptEnum.V2TIM_RECEIVE_MESSAGE);
    if (res.code == 0) {
      _isDisturb = isDisturb;
    }
    notifyListeners();
    return res;
  }

  setSelfDestructMode(String conversationID, bool value) async {
    try {
      // Get existing custom data
      final customData = await _getConversationCustomData(conversationID);
      
      // Update the mode preference
      customData['conversation_default_mode'] = value ? 'self_destruct' : 'normal';
      
      // Try to save to conversation custom data
      final saveSuccess = await _setConversationCustomDataWithResult(conversationID, customData);
      
      if (!saveSuccess) {
        // Conversation doesn't exist yet, store as pending
        _chatGlobalModel.setPendingConversationMode(conversationID, value);
        print('Stored pending self-destruct mode for C2C conversation: $value');
      } else {
        print('Saved self-destruct mode to custom data for C2C conversation: $value');
      }
      
      // Update local state
      _selfDestructMode = value;
      notifyListeners();
      
      // Update the global model's self-destruct state for this conversation
      _chatGlobalModel.updateSelfDestructMode(conversationID, value);
      print('Updated global model C2C self-destruct mode: $value');
      
    } catch (e) {
      print('Error setting self-destruct mode for C2C: $e');
    }
  }

  /// Get conversation custom data
  Future<Map<String, dynamic>> _getConversationCustomData(String conversationID) async {
    try {
      final result = await TencentImSDKPlugin.v2TIMManager
          .getConversationManager()
          .getConversation(conversationID: conversationID);
      
      if (result.code == 0 && result.data?.customData != null) {
        final customDataString = result.data!.customData!;
        if (customDataString.isNotEmpty) {
          final decoded = jsonDecode(customDataString);
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      print('Error getting conversation custom data: $e');
    }
    
    return <String, dynamic>{};
  }
  
  /// Set conversation custom data and return success status
  Future<bool> _setConversationCustomDataWithResult(String conversationID, Map<String, dynamic> customData) async {
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

  /// Set conversation custom data
  Future<void> _setConversationCustomData(String conversationID, Map<String, dynamic> data) async {
    try {
      final customDataString = jsonEncode(data);
      
      await TencentImSDKPlugin.v2TIMManager
          .getConversationManager()
          .setConversationCustomData(
            conversationIDList: [conversationID],
            customData: customDataString,
          );
          
      print('Updated conversation custom data for: $conversationID');
    } catch (e) {
      print('Error setting conversation custom data: $e');
    }
  }

  /// Load self-destruct mode state from conversation custom data
  Future<void> _loadSelfDestructMode(String conversationID) async {
    try {
      // First check if there's a pending mode in global model
      final globalMode = _chatGlobalModel.getSelfDestructMode(conversationID);
      final pendingMode = _chatGlobalModel.consumePendingConversationMode(conversationID);
      
      if (pendingMode != null) {
        // Use pending mode if available
        _selfDestructMode = pendingMode;
        // Put it back since we're just checking, not consuming yet
        _chatGlobalModel.setPendingConversationMode(conversationID, pendingMode);
        print('Loaded pending self-destruct mode for C2C conversation: $_selfDestructMode');
        return;
      }
      
      if (globalMode) {
        // Use global model state if available
        _selfDestructMode = globalMode;
        print('Loaded global self-destruct mode for C2C conversation: $_selfDestructMode');
        return;
      }
      
      // Fall back to conversation custom data
      final customData = await _getConversationCustomData(conversationID);
      final mode = customData['conversation_default_mode'] as String?;
      _selfDestructMode = mode == 'self_destruct';
      
      // Update global model with the loaded state
      _chatGlobalModel.updateSelfDestructMode(conversationID, _selfDestructMode);
      
      print('Loaded self-destruct mode from custom data for C2C conversation: $_selfDestructMode');
    } catch (e) {
      print('Error loading self-destruct mode: $e');
      _selfDestructMode = false;
    }
  }


  updateUserInfo(String key, dynamic value) {
    if (key == "nickName") {
      _userProfile?.friendInfo!.userProfile?.nickName = value;
    }
    if (key == "faceUrl") {
      _userProfile?.friendInfo!.userProfile?.faceUrl = value;
    }
    if (key == "nickName") {
      _userProfile?.friendInfo!.userProfile?.nickName = value;
    }
    if (key == "selfSignature") {
      _userProfile?.friendInfo!.userProfile?.selfSignature = value;
    }
    if (key == "gender") {
      _userProfile?.friendInfo!.userProfile?.gender = value;
    }
    if (key == "allowType") {
      _userProfile?.friendInfo!.userProfile?.allowType = value;
    }
    if (key == "customInfo") {
      _userProfile?.friendInfo!.userProfile?.customInfo = value;
    }
    if (key == "role") {
      _userProfile?.friendInfo!.userProfile?.role = value;
    }
    if (key == "level") {
      _userProfile?.friendInfo!.userProfile?.level = value;
    }
    if (key == "birthday") {
      _userProfile?.friendInfo!.userProfile?.birthday = value;
    }
  }

  Future<V2TimCallback> updateSelfInfo(Map<String, dynamic> newSelfInfo) async {
    final res = await _coreServices.setSelfInfo(
      userFullInfo: V2TimUserFullInfo.fromJson(
        newSelfInfo,
      ),
    );
    if (res.code == 0) {
      newSelfInfo.forEach((key, value) {
        updateUserInfo(key, value);
      });

      notifyListeners();
    }
    return res;
  }
}
