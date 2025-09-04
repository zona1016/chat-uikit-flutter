// ignore_for_file: must_be_immutable, avoid_print

import 'dart:convert';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/chat_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/listener_model/tui_group_listener_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_conversation_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_self_info_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_friendship_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/constants/history_message_constant.dart';
import 'package:tencent_cloud_chat_uikit/ui/controller/tim_uikit_chat_controller.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/frame.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/optimize_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitTextField/at_member_panel.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/tim_uikit_multi_select_panel.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/tim_uikit_send_file.dart';

import 'TIMUIKItMessageList/TIMUIKitTongue/tim_uikit_chat_history_message_list_tongue.dart';
import 'TIMUIKItMessageList/tim_uikit_chat_history_message_list_config.dart';
import 'TIMUIKItMessageList/tim_uikit_history_message_list_container.dart';

class TIMUIKitChat extends StatefulWidget {
  int startTime = 0;
  int endTime = 0;

  bool? showInput;

  final void Function(String groupID, TUIChatSeparateViewModel model)? onTap;

  /// The chat controller you tend to used.
  /// You have to provide this before using it since tencent_cloud_chat_uikit 0.1.4.
  final TIMUIKitChatController? controller;

  /// [Update] It is suggested to provide the `V2TimConversation` once directly, since tencent_cloud_chat_uikit 1.5.0.
  /// `conversationID` / `conversationType` / `groupAtInfoList` / `conversationShowName` are not necessary to be provided, unless you want to cover these fields manually.
  final V2TimConversation conversation;

  /// The ID of the Group that the topic belongs to, only need for topic.
  final String? groupID;

  /// Conversation id, use for load history message list.
  /// This field is not necessary to be provided, when `conversation` is provided, unless you want to cover this field manually.
  final String? conversationID;

  /// Conversation type.
  /// This field is not necessary to be provided, when `conversation` is provided, unless you want to cover this field manually.
  final ConvType? conversationType;

  /// use for customize avatar
  final Widget Function(BuildContext context, V2TimMessage message)?
      userAvatarBuilder;

  /// Use for show conversation name.
  /// This field is not necessary to be provided, when `conversation` is provided, unless you want to cover this field manually.
  final String? conversationShowName;

  /// Avatar and name in message reaction tap callback.
  final void Function(String userID, TapDownDetails tapDetails)? onTapAvatar;

  /// Avatar and name in message reaction secondary tap callback.
  final void Function(String userID, TapDownDetails tapDetails)?
      onSecondaryTapAvatar;

  @Deprecated(
      "Nickname will not shows in one-to-one chat, if you tend to control it in group chat, please use `isShowSelfNameInGroup` and `isShowOthersNameInGroup` from `config: TIMUIKitChatConfig` instead")

  /// Should show the nick name.
  final bool showNickName;

  /// Message item builder, can customize partial message item for different types or the layout for the whole line.
  final MessageItemBuilder? messageItemBuilder;

  /// Is show unread message count, default value is false
  final bool showTotalUnReadCount;

  /// Deprecated("Please use [extraTipsActionItemBuilder] instead")
  final Widget? Function(V2TimMessage message, Function() closeTooltip,
      [Key? key, BuildContext? context])? exteraTipsActionItemBuilder;

  /// The builder for extra tips action.
  final Widget? Function(V2TimMessage message, Function() closeTooltip,
      [Key? key, BuildContext? context])? extraTipsActionItemBuilder;

  /// The text of draft shows in TextField.
  /// [Recommend]: You can specify this field with the draftText from V2TimConversation.
  final String? draftText;

  /// The target message been jumped just after entering the chat page.
  final V2TimMessage? initFindingMsg;

  /// The hint text shows at input field.
  final String? textFieldHintText;

  /// The configuration for appbar.
  final AppBar? appBarConfig;

  /// The configuration for historical message list.
  final TIMUIKitHistoryMessageListConfig? mainHistoryListConfig;

  /// The configuration for more panel, can customize actions.
  final MorePanelConfig? morePanelConfig;

  /// The builder for the tongue on the right bottom.
  /// Used for back to bottom, shows the count of unread new messages,
  /// and prompts the messages that @ user.
  final TongueItemBuilder? tongueItemBuilder;

  /// The `groupAtInfoList` from `V2TimConversation`.
  /// This field is not necessary to be provided, when `conversation` is provided,
  /// unless you want to cover this field manually.
  final List<V2TimGroupAtInfo?>? groupAtInfoList;

  /// The configuration for the whole `TIMUIKitChat` widget.
  final TIMUIKitChatConfig? config;

  /// The callback for jumping to the page for `TIMUIKitGroupApplicationList`
  /// or other pages to deal with enter group application for group administrator manually,
  /// in the case of [public group].
  /// The parameter here is `String groupID`
  final ValueChanged<String>? onDealWithGroupApplication;

  /// The generator for the abstract summary preview of a message,
  /// typically used in replied and forwarded messages.
  /// Returns `null` to use the default message summary.
  final String? Function(V2TimMessage message)? abstractMessageBuilder;

  /// The configuration for tool tips panel, long press messages will show this panel.
  final ToolTipsConfig? toolTipsConfig;

  /// The life cycle for chat business logic.
  final ChatLifeCycle? lifeCycle;

  /// The top fixed widget.
  final Widget? topFixWidget;

  /// Specify the custom small png emoji packages.
  final List<CustomEmojiFaceData> customEmojiStickerList;

  final Widget? customAppBar;

  final Widget? inputTopBuilder;

  /// Custom emoji panel.
  final CustomStickerPanel? customStickerPanel;

  /// This parameter accepts a custom widget to be displayed when the mouse hovers over a message,
  /// replacing the default message hover action bar.
  /// Applicable only on desktop platforms.
  /// If provided, the default message action functionality will appear in the right-click context menu instead.
  /// Returns `null` to use default hover bar.
  final Widget? Function(V2TimMessage message)? customMessageHoverBarOnDesktop;

  /// Custom text field
  final Widget Function(BuildContext context)? textFieldBuilder;

  /// An optional parameter `groupMemberList` can be provided.
  /// `groupMemberList` accepts a list of nullable `V2TimGroupMemberFullInfo` objects.
  /// The purpose of this parameter is to allow the client to supply a pre-fetched list
  /// of group member information. If this list is provided, it will not make
  /// additional network requests to fetch the group member information internally.
  List<V2TimGroupMemberFullInfo?>? groupMemberList;

  TIMUIKitChat(
      {Key? key,
      this.showInput,
      this.onTap,
      this.groupID,
      required this.conversation,
      this.conversationID,
      this.conversationType,
      this.groupMemberList,
      this.conversationShowName,
      this.abstractMessageBuilder,
      this.onTapAvatar,
      @Deprecated(
          "Nickname will not show in one-to-one chat, if you tend to control it in group chat, please use `isShowSelfNameInGroup` and `isShowOthersNameInGroup` from `config: TIMUIKitChatConfig` instead")
      this.showNickName = false,
      this.showTotalUnReadCount = false,
      this.messageItemBuilder,
      @Deprecated("Please use [extraTipsActionItemBuilder] instead")
      this.exteraTipsActionItemBuilder,
      this.extraTipsActionItemBuilder,
      this.draftText,
      this.textFieldHintText,
      this.initFindingMsg,
      this.userAvatarBuilder,
      this.appBarConfig,
      this.controller,
      this.morePanelConfig,
      this.customStickerPanel,
      this.config = const TIMUIKitChatConfig(),
      this.tongueItemBuilder,
      this.groupAtInfoList,
      this.mainHistoryListConfig,
      this.onDealWithGroupApplication,
      this.toolTipsConfig,
      this.lifeCycle,
      this.topFixWidget = const SizedBox(),
      this.textFieldBuilder,
      this.customEmojiStickerList = const [],
      this.customAppBar,
      this.inputTopBuilder,
      this.onSecondaryTapAvatar,
      this.customMessageHoverBarOnDesktop})
      : super(key: key) {
    startTime = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  State<StatefulWidget> createState() => _TUIChatState();
}

class _TUIChatState extends TIMUIKitState<TIMUIKitChat> {
  TUIChatSeparateViewModel model = TUIChatSeparateViewModel();
  final TUISelfInfoViewModel selfInfoViewModel =
      serviceLocator<TUISelfInfoViewModel>();
  final TUIThemeViewModel themeViewModel = serviceLocator<TUIThemeViewModel>();
  final TUIConversationViewModel conversationViewModel =
      serviceLocator<TUIConversationViewModel>();
  TIMUIKitInputTextFieldController textFieldController =
      TIMUIKitInputTextFieldController();
  bool isInit = false;
  bool _hasShownModeDialog = false;
  final TUIChatGlobalModel chatGlobalModel =
      serviceLocator<TUIChatGlobalModel>();
  bool _dragging = false;

  final GlobalKey alignKey = GlobalKey();
  final GlobalKey listContainerKey = GlobalKey();

  late AutoScrollController autoController = AutoScrollController(
    viewportBoundaryGetter: () =>
        Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
    axis: Axis.vertical,
  );

  late AutoScrollController atMemberPanelScroll = AutoScrollController(
    viewportBoundaryGetter: () =>
        Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
    axis: Axis.vertical,
  );

  Widget? _joinInGroupCallWidget;

  @override
  void initState() {
    super.initState();
    if (kProfileMode) {
      Frame.init();
    }
    model.abstractMessageBuilder = widget.abstractMessageBuilder;
    model.onTapAvatar = widget.onTapAvatar;
    
    // Check conversation mode when chat screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      widget.endTime = DateTime.now().millisecondsSinceEpoch;
      int timeSpend = widget.endTime - widget.startTime;
      outputLogger.i("Page render time:$timeSpend ms");
      
      // Check and set conversation mode after the widget is built with a small delay
      await Future.delayed(const Duration(milliseconds: 100));
      await _checkAndSetConversationMode();
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      updateDraft();
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (kProfileMode) {
      Frame.destroy();
    }
    model.dispose();
  }


  @override
  void didUpdateWidget(TIMUIKitChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversationID != oldWidget.conversationID) {
      debugPrint('=== CONVERSATION CHANGED ===');
      debugPrint('Old conversation: ${oldWidget.conversationID}');
      debugPrint('New conversation: ${widget.conversationID}');
      debugPrint('Resetting _hasShownModeDialog from $_hasShownModeDialog to false');
      
      isInit = false;
      _hasShownModeDialog = false;  // Reset for new conversation
      chatGlobalModel.clearCurrentConversation();
      model = TUIChatSeparateViewModel();
      model.abstractMessageBuilder = widget.abstractMessageBuilder;
      model.onTapAvatar = widget.onTapAvatar;
      Future.delayed(const Duration(milliseconds: 100), () async {
        updateDraft();
        textFieldController.requestFocus();
        try {
          autoController.jumpTo(
            autoController.position.minScrollExtent,
          );
          autoController.jumpTo(
            autoController.position.minScrollExtent,
          );
          // ignore: empty_catches
        } catch (e) {}
        
        // Refresh conversation mode when conversation changes - add small delay for SDK to load
        await Future.delayed(const Duration(milliseconds: 100));
        await _checkAndSetConversationMode();
      });
    }
    if (oldWidget.textFieldBuilder != null && widget.textFieldBuilder == null) {
      textFieldController = TIMUIKitInputTextFieldController();
    }
    if (oldWidget.groupMemberList != widget.groupMemberList) {
      model.groupMemberList = widget.groupMemberList;
    }
  }

  updateDraft() async {
    final isTopic = widget.conversation.conversationID.contains("@TOPIC#");
    if (isTopic) {
      final topicInfoList = await TencentImSDKPlugin.v2TIMManager
          .getGroupManager()
          .getTopicInfoList(
              groupID: widget.groupID!,
              topicIDList: [widget.conversation.conversationID]);
      final topicInfo = topicInfoList.data?.first.topicInfo;
      final draftText = topicInfo?.draftText;
      if (TencentUtils.checkString(draftText) != null) {
        textFieldController.setTextField(draftText!);
      }
    }
  }

  Widget _renderJoinGroupApplication(int amount, TUITheme theme) {
    String option1 = amount.toString();
    return Container(
      height: 36,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2)),
      child: GestureDetector(
        onTap: () {
          if (widget.onDealWithGroupApplication != null) {
            widget.onDealWithGroupApplication!(_getConvID());
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              TIM_t_para("{{option1}} 条入群请求", "$option1 条入群请求")(
                  option1: option1),
              style: const TextStyle(fontSize: 12, color: AidaBaseColors.white),
            ),
            Container(
              margin: const EdgeInsets.only(left: 12),
              child: Text(
                TIM_t("去处理"),
                style: const TextStyle(
                    fontSize: 12, color: AidaBaseColors.primaryColor),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    // First try the manually provided conversation show name
    final manualName = TencentUtils.checkString(widget.conversationShowName);
    if (manualName != null) return manualName;
    
    // Then try the conversation's show name
    final showName = TencentUtils.checkString(widget.conversation.showName);
    if (showName != null) return showName;
    
    // For C2C conversations, try to get friend information for better display name
    if (widget.conversation.type == 1) {
      final userID = widget.conversation.userID;
      if (userID != null && userID.isNotEmpty) {
        // Try to get friend info from friendship view model
        try {
          final TUIFriendShipViewModel friendShipModel = serviceLocator<TUIFriendShipViewModel>();
          final friendList = friendShipModel.friendList;
          if (friendList != null) {
            final friendInfo = friendList.firstWhere(
              (friend) => friend.userID == userID,
              orElse: () => V2TimFriendInfo(userID: userID),
            );
            
            // Check friend remark first, then nickname, then userID
            final remark = TencentUtils.checkString(friendInfo.friendRemark);
            if (remark != null) return remark;
            
            final nickName = TencentUtils.checkString(friendInfo.userProfile?.nickName);
            if (nickName != null) return nickName;
          }
          
        } catch (e) {
          print('Error getting friend info for title: $e');
        }
        
        // Fallback to userID if friend info not available
        return userID;
      }
    }
    
    // For group conversations, try to use groupName or groupID
    if (widget.conversation.type == 2) {
      final groupID = widget.conversation.groupID;
      if (groupID != null && groupID.isNotEmpty) {
        return groupID;
      }
    }
    
    // Finally, try the raw conversationID as a last resort
    final conversationID = TencentUtils.checkString(widget.conversation.conversationID);
    if (conversationID != null) {
      // Clean up the conversation ID for display
      if (conversationID.startsWith('c2c_')) {
        return conversationID.substring(4); // Remove 'c2c_' prefix
      } else if (conversationID.startsWith('group_')) {
        return conversationID.substring(6); // Remove 'group_' prefix
      }
      return conversationID;
    }
    
    return "Chat";
  }

  String _getConvID() {
    return TencentUtils.checkString(widget.conversationID) ??
        (widget.conversation.type == 1
            ? widget.conversation.userID
            : widget.conversation.groupID) ??
        "";
  }

  ConvType _getConvType() {
    return widget.conversation.type == 1 ? ConvType.c2c : ConvType.group;
  }

  _updateJoinInGroupCallWidget() async {
    if (_getConvType() != ConvType.group) {
      return;
    }
    final w = await TUICore.instance
        .raiseExtension(TUIExtensionID.joinInGroup, {GROUP_ID: _getConvID()});
    if (w != _joinInGroupCallWidget) {
      setState(() {
        _joinInGroupCallWidget = w;
      });
    }
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final closePanel =
        OptimizeUtils.throttle((_) => textFieldController.hideAllPanel(), 60);
    final isBuild = isInit;
    isInit = true;
    _updateJoinInGroupCallWidget();
    
    return TIMUIKitChatProviderScope(
        model: model,
        groupID: widget.groupID,
        scrollController: autoController,
        textFieldController: textFieldController,
        conversationID: _getConvID(),
        groupMemberList: widget.groupMemberList,
        conversationType: _getConvType(),
        lifeCycle: widget.lifeCycle,
        config: widget.config,
        isBuild: isBuild,
        providers: [
          Provider(create: (_) => widget.config),
        ],
        builder: (context, model, w) {
          final TUIChatGlobalModel chatGlobalModel =
              Provider.of<TUIChatGlobalModel>(context, listen: true);

          // Sync self-destruct mode from global model if it has changed
          final conversationID = widget.conversation.conversationID ?? _getConvID();
          final globalSelfDestructMode = chatGlobalModel.getSelfDestructMode(conversationID);
          if (model.selfDestructMode != globalSelfDestructMode) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Use silent setter to avoid unnecessary toasts during sync
              model.setSelfDestructModeSilently(globalSelfDestructMode);
            });
          }

          widget.controller?.model = model;
          widget.controller?.textFieldController = textFieldController;
          widget.controller?.scrollController = autoController;
          List<V2TimGroupApplication> filteredApplicationList = [];
          if (_getConvType() == ConvType.group &&
              widget.onDealWithGroupApplication != null) {
            filteredApplicationList =
                chatGlobalModel.groupApplicationList.where((item) {
              return (item.groupID == _getConvID()) && item.handleStatus == 0;
            }).toList();
          }

          final selfUserID = selfInfoViewModel.loginInfo?.userID;
          final TUIGroupListenerModel groupListenerModel =
              Provider.of<TUIGroupListenerModel>(context, listen: true);
          final NeedUpdate? needUpdate = groupListenerModel.needUpdate;
          if (needUpdate != null &&
              needUpdate.groupID == widget.conversationID) {
            groupListenerModel.needUpdate = null;
            switch (needUpdate.updateType) {
              case UpdateType.groupInfo:
                model.loadGroupInfo(_getConvID());
                break;
              case UpdateType.memberList:
                if (widget.groupMemberList == null) {
                  model.loadGroupMemberList(groupID: _getConvID());
                }
                model.loadGroupInfo(_getConvID());
                break;
              default:
                break;
            }
          }

          List<CustomEmojiFaceData> customImageSmallPngEmojiPackages = [];
          if (widget.config?.stickerPanelConfig?.customStickerPackages !=
                  null &&
              widget.config!.stickerPanelConfig!.customStickerPackages
                  .isNotEmpty) {
            customImageSmallPngEmojiPackages = widget
                .config!.stickerPanelConfig!.customStickerPackages
                .where((element) => element.isEmoji == true)
                .map((e) {
              return CustomEmojiFaceData(
                  name: e.name,
                  isEmoji: true,
                  icon: e.menuItem.url ?? "",
                  list: e.stickerList.map((e) => e.url ?? "").toList());
            }).toList();
          }
          if (customImageSmallPngEmojiPackages.isEmpty) {
            customImageSmallPngEmojiPackages
                .addAll(widget.customEmojiStickerList);
          }

          return GestureDetector(
            onTap: () {
              textFieldController.hideAllPanel();
            },
            child: Scaffold(
                backgroundColor: Colors.transparent,
                resizeToAvoidBottomInset: false,
                appBar: (widget.customAppBar == null)
                    ? TIMUIKitAppBar(
                        showTotalUnReadCount: widget.showTotalUnReadCount,
                        config: widget.appBarConfig,
                        conversationShowName: _getTitle(),
                        conversationID: _getConvID(),
                        showC2cMessageEditStatus:
                            widget.config?.showC2cMessageEditStatus ?? true,
                      )
                    : null,
                body: DropTarget(
                  onDragDone: (detail) {
                    setState(() {
                      _dragging = false;
                      sendFileWithConfirmation(
                          files: detail.files,
                          conversation: widget.conversation,
                          conversationType: _getConvType(),
                          model: model,
                          theme: theme,
                          context: context);
                    });
                  },
                  onDragEntered: (detail) {
                    setState(() {
                      _dragging = true;
                    });
                  },
                  onDragExited: (detail) {
                    setState(() {
                      _dragging = false;
                    });
                  },
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.customAppBar != null) widget.customAppBar!,
                          if (filteredApplicationList.isNotEmpty)
                            _renderJoinGroupApplication(
                                filteredApplicationList.length, theme),
                          if (widget.topFixWidget != null) widget.topFixWidget!,
                          if (_joinInGroupCallWidget != null)
                            Center(child: _joinInGroupCallWidget!),
                          Expanded(
                              child: Container(
                            color: theme.chatBgColor,
                            child: Align(
                                key: alignKey,
                                alignment: Alignment.topCenter,
                                child: Listener(
                                  onPointerMove: closePanel,
                                  child: TIMUIKitHistoryMessageListContainer(
                                    customMessageHoverBarOnDesktop:
                                        widget.customMessageHoverBarOnDesktop,
                                    conversation: widget.conversation,
                                    groupMemberInfo: model.groupMemberList
                                        ?.firstWhere(
                                            (element) =>
                                                element?.userID == selfUserID,
                                            orElse: () => null),
                                    textFieldController: textFieldController,
                                    customEmojiStickerList:
                                        widget.customEmojiStickerList,
                                    isUseDefaultEmoji:
                                        widget.config!.isUseDefaultEmoji,
                                    key: listContainerKey,
                                    isAllowScroll: true,
                                    userAvatarBuilder: widget.userAvatarBuilder,
                                    toolTipsConfig: widget.toolTipsConfig,
                                    groupAtInfoList: widget.groupAtInfoList,
                                    tongueItemBuilder: widget.tongueItemBuilder,
                                    onLongPressForOthersHeadPortrait:
                                        (String? userId, String? nickName) {
                                      textFieldController.longPressToAt(
                                          nickName, userId);
                                    },
                                    mainHistoryListConfig:
                                        widget.mainHistoryListConfig,
                                    initFindingMsg: widget.initFindingMsg,
                                    extraTipsActionItemBuilder:
                                        widget.extraTipsActionItemBuilder ??
                                            widget.exteraTipsActionItemBuilder,
                                    conversationType: _getConvType(),
                                    scrollController: autoController,
                                    onSecondaryTapAvatar:
                                        widget.onSecondaryTapAvatar,
                                    onTapAvatar: widget.onTapAvatar,
                                    // ignore: deprecated_member_use_from_same_package
                                    showNickName: widget.showNickName,
                                    messageItemBuilder:
                                        widget.messageItemBuilder,
                                    conversationID: _getConvID(),
                                  ),
                                )),
                          )),
                          widget.inputTopBuilder ?? Container(),
                          if (widget.showInput == true)
                            Selector<TUIChatSeparateViewModel, bool>(
                              builder: (context, value, child) {
                                return value
                                    ? MultiSelectPanel(
                                        conversationType: _getConvType(),
                                      )
                                    : (widget.textFieldBuilder != null
                                        ? widget.textFieldBuilder!(context)
                                        : TIMUIKitInputTextField(
                                            onTap: widget.onTap,
                                            chatConfig: widget.config,
                                            backgroundColor:
                                                Colors.white.withOpacity(0.1),
                                            groupID: widget.groupID,
                                            atMemberPanelScroll:
                                                atMemberPanelScroll,
                                            groupType:
                                                widget.conversation.groupType,
                                            currentConversation:
                                                widget.conversation,
                                            model: model,
                                            controller: textFieldController,
                                            customEmojiStickerList:
                                                customImageSmallPngEmojiPackages,
                                            isUseDefaultEmoji: widget
                                                .config!.isUseDefaultEmoji,
                                            customStickerPanel:
                                                widget.customStickerPanel,
                                            morePanelConfig:
                                                widget.morePanelConfig,
                                            scrollController: autoController,
                                            conversationID: _getConvID(),
                                            conversationType: _getConvType(),
                                            initText: TencentUtils.checkString(
                                                    widget.draftText) ??
                                                (PlatformUtils().isWeb
                                                    ? TencentUtils.checkString(
                                                        conversationViewModel
                                                            .getWebDraft(
                                                                conversationID: widget
                                                                    .conversation
                                                                    .conversationID))
                                                    : TencentUtils.checkString(
                                                        widget.conversation
                                                            .draftText)),
                                            hintText: widget.textFieldHintText,
                                            showMorePanel: widget.config
                                                    ?.isAllowShowMorePanel ??
                                                true,
                                            showSendAudio: widget.config
                                                    ?.isAllowSoundMessage ??
                                                true,
                                            showSendEmoji: widget.config
                                                    ?.isAllowEmojiPanel ??
                                                true,
                                          ));
                              },
                              selector: (c, model) {
                                return model.isMultiSelect;
                              },
                            )
                        ],
                      ),
                      if (_dragging)
                        TIMUIKitSendFile(
                          conversation: widget.conversation,
                        ),
                      AtMemberPanel(
                        atMemberPanelScroll: atMemberPanelScroll,
                        onSelectMember: (member) =>
                            textFieldController.handleAtMember(member),
                      )
                    ],
                  ),
                )),
          );
        });
  }

  /// Check if conversation is read-only (aid_team or channels)
  bool _isReadOnlyConversation(String? conversationID) {
    if (conversationID == null) return false;
    
    // Handle group_ prefix in conversation IDs
    final cleanConversationID = conversationID.startsWith('group_') 
        ? conversationID.substring(6) // Remove "group_" prefix
        : conversationID;
    
    // Original hardcoded detection
    final isReadOnly = (TencentUtils.aidTeam == cleanConversationID ||
        TencentUtils.india == cleanConversationID ||
        TencentUtils.korea == cleanConversationID ||
        TencentUtils.english == cleanConversationID ||
        TencentUtils.chinese == cleanConversationID ||
        TencentUtils.french == cleanConversationID ||
        TencentUtils.german == cleanConversationID);
    
    if (isReadOnly) {
      debugPrint('Read-only conversation detected: $conversationID (cleaned: $cleanConversationID)');
      return true;
    }
    
    // Additional detection conditions
    final conversation = widget.conversation;
    
    // Check if it's a broadcast group or special group type
    if (conversation.groupType != null) {
      if (conversation.groupType == 'AVChatRoom' || conversation.groupType == 'BChatRoom') {
        return true;
      }
    }
    
    // Check custom data for read-only flag
    if (conversation.customData != null && conversation.customData!.isNotEmpty) {
      try {
        final customData = jsonDecode(conversation.customData!);
        if (customData['isReadOnly'] == true || customData['readonly'] == true) {
          return true;
        }
      } catch (e) {
        // Ignore JSON parse errors
      }
    }
    
    return false;
  }

  /// Check and set conversation mode when chat screen loads
  Future<void> _checkAndSetConversationMode() async {
    final conversationID = widget.conversation.conversationID;
    if (conversationID == null || conversationID.isEmpty) return;
    
    debugPrint('=== _checkAndSetConversationMode START for $conversationID ===');
    debugPrint('Current _hasShownModeDialog: $_hasShownModeDialog');
    debugPrint('Current global model state: ${chatGlobalModel.getSelfDestructMode(conversationID)}');
    debugPrint('Current pending mode: ${chatGlobalModel.getPendingConversationMode(conversationID)}');
    
    // Skip mode selection for read-only conversations
    if (_isReadOnlyConversation(conversationID)) {
      model.setSelfDestructModeSilently(false);
      chatGlobalModel.updateSelfDestructMode(conversationID, false);
      debugPrint('Skipped read-only conversation: $conversationID');
      return;
    }
    
    try {
      // Get conversation custom data
      final customData = await _getConversationCustomData(conversationID);
      debugPrint('Custom data for $conversationID: $customData');
      
      // Check if mode preference already exists
      if (customData.containsKey('conversation_default_mode')) {
        final mode = customData['conversation_default_mode'];
        final shouldActivateSelfDestruct = mode == 'self_destruct';
        
        // Apply the saved preference
        model.setSelfDestructModeSilently(shouldActivateSelfDestruct);
        chatGlobalModel.updateSelfDestructMode(conversationID, shouldActivateSelfDestruct);
        
        debugPrint('Applied saved conversation mode: $conversationID -> $shouldActivateSelfDestruct');
        return;
      }
      
      // Show mode selection dialog if no preference exists and hasn't been shown yet
      debugPrint('Dialog check - mounted: $mounted, _hasShownModeDialog: $_hasShownModeDialog');
      if (mounted && !_hasShownModeDialog) {  // Only show dialog once per session
        debugPrint('Will show mode selection dialog for $conversationID');
        _hasShownModeDialog = true;  // Mark as shown for this session
        final selectedMode = await _showModeSelectionDialog();
        
        if (selectedMode != null) {
          final shouldActivateSelfDestruct = selectedMode == 'self_destruct';
          
          // Try to save the selected mode, but don't fail if conversation doesn't exist yet
          customData['conversation_default_mode'] = selectedMode;
          
          // Clear burn_seconds when normal mode is selected
          if (selectedMode == 'normal' && customData.containsKey('burn_seconds')) {
            customData.remove('burn_seconds');
            debugPrint('Cleared burn_seconds for $conversationID since normal mode selected');
          }
          
          final saveSuccess = await _setConversationCustomData(conversationID, customData);
          
          if (!saveSuccess) {
            // Conversation doesn't exist yet, store mode preference temporarily in global model
            // This will be applied when first message is sent and conversation is created
            chatGlobalModel.setPendingConversationMode(conversationID, shouldActivateSelfDestruct);
            debugPrint('Stored pending conversation mode: $conversationID -> $shouldActivateSelfDestruct');
          } else {
            debugPrint('Saved new conversation mode: $conversationID -> $shouldActivateSelfDestruct');
          }
          
          model.selfDestructMode = shouldActivateSelfDestruct;  // Show toast for user selection
          chatGlobalModel.updateSelfDestructMode(conversationID, shouldActivateSelfDestruct);
        } else {
          // User cancelled, default to normal mode
          model.setSelfDestructModeSilently(false);
          chatGlobalModel.updateSelfDestructMode(conversationID, false);
        }
      } else {
        // Default to normal mode if no preference and dialog not shown
        debugPrint('No dialog shown, defaulting to normal mode for $conversationID');
        model.setSelfDestructModeSilently(false);
        chatGlobalModel.updateSelfDestructMode(conversationID, false);
      }
    } catch (e) {
      debugPrint('Error checking conversation mode: $e');
      // Default to normal mode on error
      model.setSelfDestructModeSilently(false);
      chatGlobalModel.updateSelfDestructMode(conversationID, false);
    }
    
    debugPrint('=== _checkAndSetConversationMode END for $conversationID ===');
    debugPrint('Final _hasShownModeDialog: $_hasShownModeDialog');
    debugPrint('Final global model state: ${chatGlobalModel.getSelfDestructMode(conversationID)}');
  }

  /// Get conversation custom data with retry logic
  Future<Map<String, dynamic>> _getConversationCustomData(String conversationID, {int retryCount = 0}) async {
    debugPrint('Getting conversation custom data for $conversationID (attempt ${retryCount + 1})');
    
    try {
      final result = await TencentImSDKPlugin.v2TIMManager
          .getConversationManager()
          .getConversation(conversationID: conversationID);
      
      debugPrint('SDK getConversation result for $conversationID: code=${result.code}, hasData=${result.data != null}');
      
      if (result.code == 0 && result.data != null) {
        final customDataStr = result.data!.customData ?? "";
        if (customDataStr.isNotEmpty) {
          try {
            final parsed = Map<String, dynamic>.from(jsonDecode(customDataStr));
            debugPrint('Successfully parsed custom data for $conversationID: $parsed');
            return parsed;
          } catch (parseError) {
            debugPrint('Failed to parse custom data JSON for $conversationID: $parseError, raw: $customDataStr');
            return {};
          }
        } else {
          debugPrint('Empty custom data for conversation: $conversationID');
        }
      } else {
        debugPrint('SDK error getting conversation $conversationID: code=${result.code}, desc=${result.desc}');
        
        // Retry once if conversation not found and this is the first attempt
        if (result.code != 0 && retryCount == 0) {
          debugPrint('Will retry conversation data retrieval for $conversationID in 300ms...');
          await Future.delayed(const Duration(milliseconds: 300));
          return _getConversationCustomData(conversationID, retryCount: 1);
        }
      }
    } catch (e) {
      debugPrint('Exception getting conversation custom data for $conversationID: $e');
      
      // Retry once on exception if this is the first attempt
      if (retryCount == 0) {
        debugPrint('Will retry conversation data retrieval for $conversationID due to exception in 300ms...');
        await Future.delayed(const Duration(milliseconds: 300));
        return _getConversationCustomData(conversationID, retryCount: 1);
      }
    }
    
    debugPrint('Returning empty custom data for $conversationID after ${retryCount + 1} attempts');
    return {};
  }

  /// Set conversation custom data
  Future<bool> _setConversationCustomData(String conversationID, Map<String, dynamic> customData) async {
    try {
      final result = await TencentImSDKPlugin.v2TIMManager
          .getConversationManager()
          .setConversationCustomData(
            conversationIDList: [conversationID],
            customData: jsonEncode(customData),
          );
      return result.code == 0;
    } catch (e) {
      debugPrint('Error setting conversation custom data: $e');
      return false;
    }
  }

  /// Show mode selection dialog
  Future<String?> _showModeSelectionDialog() async {
    if (!mounted) {
      return null;
    }
    
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(TIM_t('选择聊天模式')),
          content: Text(TIM_t('请选择此对话的默认模式 （ 您可以稍后通过对话设置更改此模式 ）：')),
          actions: <Widget>[
            TextButton(
              child: Text(TIM_t('普通模式')),
              onPressed: () {
                // debugPrint('User selected: normal');
                Navigator.of(context).pop('normal');
              },
            ),
            TextButton(
              child: Text(TIM_t('阅后即焚')),
              onPressed: () {
                // debugPrint('User selected: self_destruct');
                Navigator.of(context).pop('self_destruct');
              },
            ),
          ],
        );
      },
    );
  }
}

class TIMUIKitChatProviderScope extends StatelessWidget {
  final TUIChatGlobalModel globalModel = serviceLocator<TUIChatGlobalModel>();
  TUIChatSeparateViewModel? model;
  final TUIGroupListenerModel groupListenerModel =
      serviceLocator<TUIGroupListenerModel>();
  final TUIThemeViewModel themeViewModel = serviceLocator<TUIThemeViewModel>();
  final Widget? child;

  /// You could get the model from here, and transfer it to other widget from TUIKit.
  final Widget Function(BuildContext, TUIChatSeparateViewModel, Widget?)
      builder;
  final List<SingleChildWidget>? providers;

  /// `TIMUIKitChatController` needs to be provided if you use it outside.
  final TIMUIKitChatController? controller;

  /// The global config for TIMUIKitChat.
  final TIMUIKitChatConfig? config;

  /// Conversation id, use for get history message list.
  final String conversationID;

  final String? groupID;

  /// Conversation type
  final ConvType conversationType;

  /// The life cycle for chat business logic.
  final ChatLifeCycle? lifeCycle;

  /// The controller for text field.
  final TIMUIKitInputTextFieldController? textFieldController;

  final bool? isBuild;

  final AutoScrollController? scrollController;

  /// An optional parameter `groupMemberList` can be provided.
  /// `groupMemberList` accepts a list of nullable `V2TimGroupMemberFullInfo` objects.
  /// The purpose of this parameter is to allow the client to supply a pre-fetched list
  /// of group member information. If this list is provided, it will not make
  /// additional network requests to fetch the group member information internally.
  List<V2TimGroupMemberFullInfo?>? groupMemberList;

  TIMUIKitChatProviderScope(
      {Key? key,
      this.child,
      this.providers,
      this.groupMemberList,
      this.textFieldController,
      required this.builder,
      this.model,
      this.groupID,
      this.isBuild,
      required this.conversationID,
      required this.conversationType,
      this.controller,
      this.config,
      this.lifeCycle,
      this.scrollController})
      : super(key: key) {
    if (isBuild ?? false) {
      return;
    }
    model ??= TUIChatSeparateViewModel();
    controller?.model = model;
    controller?.textFieldController = textFieldController;
    controller?.scrollController = scrollController;
    if (config != null) {
      model?.chatConfig = config!;
    }
    model?.lifeCycle = lifeCycle;
    model?.initForEachConversation(
      conversationType,
      conversationID,
      (String value) {
        textFieldController?.textEditingController?.text = value;
      },
      preGroupMemberList: groupMemberList,
      groupID: groupID,
    );
    model?.showC2cMessageEditStatus = (conversationType == ConvType.c2c
        ? config?.showC2cMessageEditStatus ?? true
        : false);
    loadData();
  }

  loadData() {
    // Use the same robust pattern-based detection for channels
    final isChannel = _isChannelConversation(conversationID);
    print(kIsWeb
        ? 15
        : isChannel
            ? 100000
            : HistoryMessageDartConstant.getCount);
    model!.loadChatRecord(
        count: kIsWeb
            ? 15
            : isChannel
                ? 100000
                : HistoryMessageDartConstant.getCount);
    // }
  }

  /// Check if conversation is a channel (aid_team or language channels)
  /// Uses pattern-based detection to automatically handle future language channels
  static bool _isChannelConversation(String? conversationID) {
    if (conversationID == null || conversationID.isEmpty) return false;
    
    // Aid team check (exact match)
    if (conversationID == TencentUtils.aidTeam) {
      return true;
    }
    
    // Language channel pattern: @TGS#_@TGS#c[LETTERS]VBKMxxxxxx
    final languageChannelPattern = RegExp(r'^@TGS#_@TGS#c[A-Z0-9]+VBKM[A-Z0-9]+$');
    return languageChannelPattern.hasMatch(conversationID);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: model),
        ChangeNotifierProvider.value(value: globalModel),
        ChangeNotifierProvider.value(value: themeViewModel),
        ChangeNotifierProvider.value(value: groupListenerModel),
        Provider(create: (_) => const TIMUIKitChatConfig()),
        ...?providers
      ],
      child: child,
      builder: (context, w) => builder(context, model!, w),
    );
  }
}
