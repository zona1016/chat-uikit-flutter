import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/tim_uikit_wide_modal_operation_key.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_app_bar.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_screen.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitProfile/widget/tim_uikit_operation_item.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/column_menu.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/radio_button.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:tencent_im_base/tencent_im_base.dart';

GlobalKey<_GroupProfileAddAdminState> groupProfileAddAdminKey = GlobalKey();

class GroupProfileGroupManage extends StatefulWidget {
  const GroupProfileGroupManage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => GroupProfileGroupManageState();
}

class GroupProfileGroupManageState
    extends TIMUIKitState<GroupProfileGroupManage> {
  bool isShowManageBox = false;

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    final model = Provider.of<TUIGroupProfileModel>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
          color: AidaBaseColors.whiteWithOpacity01,),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              final isDesktopScreen =
                  TUIKitScreenUtils.getFormFactor(context) ==
                      DeviceType.Desktop;
              if (!isDesktopScreen) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GroupProfileGroupManagePage(
                              model: model,
                            )));
              } else {
                setState(() {
                  isShowManageBox = !isShowManageBox;
                });
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TIM_t("群管理"),
                  style: TextStyle(
                      fontSize: isDesktopScreen ? 14 : 16,
                      color: AidaBaseColors.white),
                ),
                AnimatedRotation(
                  turns: isShowManageBox ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_right,
                      color: theme.weakTextColor),
                )
              ],
            ),
          ),
          if (isShowManageBox)
            GroupProfileGroupManagePage(
              model: model,
            )
        ],
      ),
    );
  }
}

/// 管理员设置页面
class GroupProfileGroupManagePage extends StatefulWidget {
  final TUIGroupProfileModel model;

  const GroupProfileGroupManagePage({
    Key? key,
    required this.model,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupProfileGroupManagePageState();
}

class _GroupProfileGroupManagePageState
    extends TIMUIKitState<GroupProfileGroupManagePage> {
  int? serverTime;

  @override
  void initState() {
    super.initState();
    getServerTime();
  }

  void getServerTime() async {
    final res = await TencentImSDKPlugin.v2TIMManager.getServerTime();
    setState(() {
      serverTime = res.data;
    });
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: widget.model),
          ChangeNotifierProvider.value(
              value: serviceLocator<TUIThemeViewModel>())
        ],
        builder: (context, w) {
          final memberList =
              Provider.of<TUIGroupProfileModel>(context).groupMemberList;
          final theme = Provider.of<TUIThemeViewModel>(context).theme;
          final isAllMuted = widget.model.groupInfo?.isAllMuted ?? false;
          final bool isAllowMuteMember =
              (widget.model.groupInfo?.groupType ?? "") != GroupType.Work;
          final isDesktopScreen =
              TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

          Widget managePage() {
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.only(
                      top: 12,
                      left: isDesktopScreen ? 0 : 16,
                      bottom: isDesktopScreen ? 0 : 12,
                      right: isDesktopScreen ? 0 : 12),
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: isDesktopScreen
                          ? null
                          : Border(
                              bottom: BorderSide(
                                  color: AidaBaseColors.whiteWithOpacity01))),
                  child: InkWell(
                    onTap: isDesktopScreen
                        ? null
                        : () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      GroupProfileSetManagerPage(
                                    model: widget.model,
                                  ),
                                ));
                          },
                    child: isDesktopScreen
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(TIM_t("群管理员"),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: theme.darkTextColor)),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(TIM_t("设置管理员"),
                                  style: TextStyle(
                                      fontSize: isDesktopScreen ? 14 : 16,
                                      color: AidaBaseColors.white)),
                              const Icon(Icons.keyboard_arrow_right,
                                  color: AidaBaseColors.white)
                            ],
                          ),
                  ),
                ),
                if (isDesktopScreen)
                  GroupProfileSetManagerPage(
                    model: widget.model,
                  ),
                if (!isDesktopScreen)
                  Container(
                    padding: const EdgeInsets.only(
                        top: 12, left: 16, bottom: 12, right: 12),
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border(
                            bottom: BorderSide(
                                color: AidaBaseColors.whiteWithOpacity01))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          TIM_t("全员禁言"),
                          style: const TextStyle(
                              fontSize: 16, color: AidaBaseColors.white),
                        ),
                        Switch(
                          value: isAllMuted,
                          onChanged: (value) async {
                            widget.model.setMuteAll(value);
                          },
                          activeColor: AidaBaseColors.black, // 轨道颜
                          thumbColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.selected)) {
                                return AidaBaseColors.secondPrimaryColor;
                              }
                              return Colors.grey;
                            },
                          ),// 关闭时滑块颜色
                          activeTrackColor: AidaBaseColors.black,
                          inactiveTrackColor: AidaBaseColors.black,
                        )
                      ],
                    ),
                  ),
                if (isDesktopScreen && isAllowMuteMember)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(TIM_t("禁言"),
                          style: TextStyle(
                              fontSize: 14, color: theme.darkTextColor)),
                    ],
                  ),
                if (isDesktopScreen)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TIMUIKitOperationItem(
                      isEmpty: false,
                      operationName: TIM_t("全员禁言"),
                      type: "switch",
                      isUseCheckedBoxOnWide: true,
                      operationDescription: TIM_t("全员禁言开启后，只允许群主和管理员发言。"),
                      operationValue: isAllMuted,
                      onSwitchChange: (value) {
                        widget.model.setMuteAll(value);
                      },
                    ),
                  ),
                if (!isDesktopScreen)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    color: Colors.transparent,
                    alignment: Alignment.topLeft,
                    child: Text(
                      TIM_t("全员禁言开启后，只允许群主和管理员发言。"),
                      style:
                          const TextStyle(fontSize: 12, color: AidaBaseColors.weakTextColor),
                    ),
                  ),
                if (!isAllMuted && isAllowMuteMember)
                  InkWell(
                    child: Container(
                        color: AidaBaseColors.whiteWithOpacity01,
                        padding: const EdgeInsets.only(left: 16),
                        child: Container(
                          padding: !isDesktopScreen
                              ? const EdgeInsets.symmetric(
                                  vertical: 12,
                                )
                              : const EdgeInsets.only(
                                  bottom: 4,
                                ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add_circle_outline,
                                color: AidaBaseColors.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Text(TIM_t("添加需要禁言的群成员"), style: const TextStyle(color: AidaBaseColors.white),)
                            ],
                          ),
                        )),
                    onTap: () async {
                      Widget muteMember() {
                        return GroupProfileAddAdmin(
                          key: groupProfileAddAdminKey,
                          appbarTitle: TIM_t("设置禁言"),
                          memberList: memberList.where((element) {
                            final isMute = (serverTime != null
                                ? (element?.muteUntil ?? 0) > serverTime!
                                : false);
                            final isMember = element!.role ==
                                GroupMemberRoleType
                                    .V2TIM_GROUP_MEMBER_ROLE_MEMBER;
                            return !isMute && isMember;
                          }).toList(),
                          selectCompletedHandler:
                              (context, selectedMember) async {
                            if (selectedMember.isNotEmpty) {
                              for (var member in selectedMember) {
                                final userID = member!.userID;
                                widget.model
                                    .muteGroupMember(userID, true, serverTime);
                              }
                            }
                          },
                        );
                      }

                      if (isDesktopScreen) {
                        TUIKitWidePopup.showPopupWindow(
                            operationKey: TUIKitWideModalOperationKey.setMute,
                            context: context,
                            title: TIM_t("设置禁言"),
                            width: MediaQuery.of(context).size.width * 0.5,
                            height: MediaQuery.of(context).size.height * 0.8,
                            onSubmit: () {
                              groupProfileAddAdminKey.currentState?.onSubmit();
                            },
                            child: (onClose) => muteMember());
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => muteMember()));
                      }
                    },
                  ),
                if (!isAllMuted && isAllowMuteMember)
                  ...memberList
                      .where((element) => (serverTime != null
                          ? (element?.muteUntil ?? 0) > serverTime!
                          : false))
                      .map((e) => Container(
                            padding: isDesktopScreen
                                ? const EdgeInsets.only(left: 16)
                                : null,
                            child: GestureDetector(
                              onSecondaryTapDown: (details) {
                                TUIKitWidePopup.showPopupWindow(
                                    operationKey:
                                        TUIKitWideModalOperationKey.setUnmute,
                                    isDarkBackground: false,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(4)),
                                    context: context,
                                    offset: Offset(
                                        min(
                                            details.globalPosition.dx,
                                            MediaQuery.of(context).size.width -
                                                80),
                                        details.globalPosition.dy),
                                    child: (onClose) => TUIKitColumnMenu(data: [
                                          ColumnMenuItem(
                                              label: TIM_t("删除"),
                                              icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                  size: 16),
                                              onClick: () {
                                                widget.model.muteGroupMember(
                                                    e.userID,
                                                    false,
                                                    serverTime);
                                                onClose();
                                              }),
                                        ]));
                              },
                              child: _buildListItem(
                                  context,
                                  e!,
                                  ActionPane(
                                      motion: const DrawerMotion(),
                                      children: [
                                        SlidableAction(
                                          onPressed: (_) {
                                            widget.model.muteGroupMember(
                                                e.userID, false, serverTime);
                                          },
                                          flex: 1,
                                          backgroundColor: theme.cautionColor ??
                                              CommonColor.cautionColor,
                                          autoClose: true,
                                          label: TIM_t("删除"),
                                        )
                                      ])),
                            ),
                          ))
                      .toList()
              ],
            );
          }

          return TUIKitScreenUtils.getDeviceWidget(
              context: context,
              desktopWidget: managePage(),
              defaultWidget: ChatBaseScreen(
                safeAreaTop: false,
                safeAreaBottom: false,
                backgroundColor: Colors.transparent,
                backgroundImage: AidaBaseColors.baseBackgroundImage,
                appBar: ChatBaseAppBar(
                  title: TIM_t("群管理"),
                ),
                body: managePage(),
              ));
        });
  }
}

_getShowName(V2TimGroupMemberFullInfo? item) {
  final friendRemark = item?.friendRemark ?? "";
  final nameCard = item?.nameCard ?? "";
  final nickName = item?.nickName ?? "";
  final userID = item?.userID ?? "";
  return friendRemark.isNotEmpty
      ? friendRemark
      : nameCard.isNotEmpty
          ? nameCard
          : nickName.isNotEmpty
              ? nickName
              : userID;
}

Widget _buildListItem(BuildContext context, V2TimGroupMemberFullInfo memberInfo,
    ActionPane? endActionPane) {
  final theme = Provider.of<TUIThemeViewModel>(context).theme;
  final isDesktopScreen =
      TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

  Widget nameItem() {
    return Container(
      color: Colors.transparent,
      child: Column(children: [
        ListTile(
          tileColor: Colors.black,
          leading: SizedBox(
            width: isDesktopScreen ? 30 : 36,
            height: isDesktopScreen ? 30 : 36,
            child: Avatar(
              faceUrl: memberInfo.faceUrl ?? "",
              showName: _getShowName(memberInfo),
              type: 2,
              borderRadius: BorderRadius.circular(isDesktopScreen ? 15 : 18),
            ),
          ),
          title: Row(
            children: [
              Text(_getShowName(memberInfo),
                  style: TextStyle(fontSize: isDesktopScreen ? 14 : 16, color: AidaBaseColors.white)),
            ],
          ),
          onTap: () {},
        ),
        if (!isDesktopScreen)
          Divider(
              thickness: 1,
              indent: 74,
              endIndent: 0,
              color: AidaBaseColors.whiteWithOpacity01,
              height: 0)
      ]),
    );
  }

  return TUIKitScreenUtils.getDeviceWidget(
      context: context,
      desktopWidget: nameItem(),
      defaultWidget: SingleChildScrollView(
          child: Slidable(endActionPane: endActionPane, child: nameItem())));
}

/// 选择管理员
class GroupProfileSetManagerPage extends StatefulWidget {
  final TUIGroupProfileModel model;

  const GroupProfileSetManagerPage({Key? key, required this.model})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupProfileSetManagerPageState();
}

class _GroupProfileSetManagerPageState
    extends TIMUIKitState<GroupProfileSetManagerPage> {
  List<V2TimGroupMemberFullInfo?> _getAdminMemberList(
      List<V2TimGroupMemberFullInfo?> memberList) {
    return memberList
        .where((member) =>
            member?.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_ADMIN)
        .toList();
  }

  List<V2TimGroupMemberFullInfo?> _getOwnerList(
      List<V2TimGroupMemberFullInfo?> memberList) {
    return memberList
        .where((member) =>
            member?.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_OWNER)
        .toList();
  }

  _removeAdmin(
      BuildContext context, V2TimGroupMemberFullInfo memberFullInfo) async {
    final res = await widget.model.setMemberToNormal(memberFullInfo.userID);
    if (res.code == 0) {
      onTIMCallback(TIMCallback(
          type: TIMCallbackType.INFO,
          infoRecommendText: TIM_t("成功取消管理员身份"),
          infoCode: 6661003));
    }
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;

    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: widget.model)],
      builder: (context, w) {
        final model = Provider.of<TUIGroupProfileModel>(context);
        final memberList = model.groupMemberList;
        final adminList = _getAdminMemberList(memberList);
        final ownerList = _getOwnerList(memberList);
        final String option2 = adminList.length.toString();
        final isDesktopScreen =
            TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

        Widget adminPage() {
          return SingleChildScrollView(
              child: Column(
            children: [
              if (!isDesktopScreen)
                Container(
                  alignment: Alignment.topLeft,
                  color: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  child: Text(
                    TIM_t("群主"),
                    style: const TextStyle(fontSize: 14, color: AidaBaseColors.white),
                  ),
                ),
              if (isDesktopScreen)
                Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(top: 10, bottom: 4, left: 16),
                  child: Text(
                    TIM_t("群主"),
                    style: TextStyle(fontSize: 14, color: theme.primaryColor),
                  ),
                ),
              ...ownerList
                  .map(
                    (e) => Container(
                      padding: isDesktopScreen
                          ? const EdgeInsets.only(left: 16)
                          : null,
                      child: _buildListItem(context, e!, null),
                    ),
                  )
                  .toList(),
              if (!isDesktopScreen)
                Container(
                  alignment: Alignment.topLeft,
                  color: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  child: Text(
                    TIM_t_para("管理员 ({{option2}}/10)", "管理员 ($option2/10)")(
                        option2: option2),
                    style: const TextStyle(fontSize: 14, color: AidaBaseColors.white),
                  ),
                ),
              if (isDesktopScreen)
                Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(top: 10, bottom: 4, left: 16),
                  child: Text(
                    TIM_t_para("管理员 ({{option2}}/10)", "管理员 ($option2/10)")(
                        option2: option2),
                    style: TextStyle(fontSize: 14, color: theme.primaryColor),
                  ),
                ),
              InkWell(
                child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.only(left: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      decoration: isDesktopScreen
                          ? null
                          : BoxDecoration(
                              color: Colors.transparent,
                              border: Border(
                                  bottom: BorderSide(
                                      color: AidaBaseColors.whiteWithOpacity01))),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_circle_outline,
                            color: AidaBaseColors.white,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Text(TIM_t("添加管理员"), style: const TextStyle(color: AidaBaseColors.white),)
                        ],
                      ),
                    )),
                onTap: () async {
                  if (isDesktopScreen) {
                    TUIKitWidePopup.showPopupWindow(
                        operationKey: TUIKitWideModalOperationKey.setAdmins,
                        context: context,
                        title: TIM_t("设置管理员"),
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.height * 0.8,
                        onSubmit: () {
                          groupProfileAddAdminKey.currentState?.onSubmit();
                        },
                        child: (onClose) => GroupProfileAddAdmin(
                              key: groupProfileAddAdminKey,
                              memberList: memberList
                                  .where((element) =>
                                      element?.role ==
                                      GroupMemberRoleType
                                          .V2TIM_GROUP_MEMBER_ROLE_MEMBER)
                                  .toList(),
                              appbarTitle: TIM_t("设置管理员"),
                              selectCompletedHandler:
                                  (context, selectedMember) async {
                                if (selectedMember.isNotEmpty) {
                                  for (var member in selectedMember) {
                                    final userID = member!.userID;
                                    widget.model.setMemberToAdmin(userID);
                                  }
                                }
                              },
                            ));
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GroupProfileAddAdmin(
                                  key: groupProfileAddAdminKey,
                                  memberList: memberList
                                      .where((element) =>
                                          element?.role ==
                                          GroupMemberRoleType
                                              .V2TIM_GROUP_MEMBER_ROLE_MEMBER)
                                      .toList(),
                                  appbarTitle: TIM_t("设置管理员"),
                                  selectCompletedHandler:
                                      (context, selectedMember) async {
                                    if (selectedMember.isNotEmpty) {
                                      for (var member in selectedMember) {
                                        final userID = member!.userID;
                                        widget.model.setMemberToAdmin(userID);
                                      }
                                    }
                                  },
                                )));
                  }
                },
              ),
              ...adminList
                  .map((e) => GestureDetector(
                        onSecondaryTapDown: (details) {
                          TUIKitWidePopup.showPopupWindow(
                              operationKey:
                                  TUIKitWideModalOperationKey.deleteAdmin,
                              isDarkBackground: false,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(4)),
                              context: context,
                              offset: Offset(
                                  min(details.globalPosition.dx,
                                      MediaQuery.of(context).size.width - 80),
                                  details.globalPosition.dy),
                              child: (onClose) => TUIKitColumnMenu(data: [
                                    ColumnMenuItem(
                                        label: TIM_t("删除"),
                                        icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 16),
                                        onClick: () {
                                          _removeAdmin(context, e);
                                          onClose();
                                        }),
                                  ]));
                        },
                        child: Container(
                          padding: isDesktopScreen
                              ? const EdgeInsets.only(left: 16)
                              : null,
                          child: _buildListItem(
                              context,
                              e!,
                              ActionPane(
                                  motion: const DrawerMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) {
                                        _removeAdmin(context, e);
                                      },
                                      flex: 1,
                                      backgroundColor: theme.cautionColor ??
                                          CommonColor.cautionColor,
                                      autoClose: true,
                                      label: TIM_t("删除"),
                                    )
                                  ])),
                        ),
                      ))
                  .toList(),
            ],
          ));
        }

        return TUIKitScreenUtils.getDeviceWidget(
            context: context,
            desktopWidget: adminPage(),
            defaultWidget: ChatBaseScreen(
              safeAreaTop: false,
              safeAreaBottom: false,
              backgroundColor: Colors.transparent,
              backgroundImage: AidaBaseColors.baseBackgroundImage,
              appBar: ChatBaseAppBar(
                title: TIM_t("设置管理员"),
              ),
              body: adminPage(),
            ));
      },
    );
  }
}

/// 添加管理员
class GroupProfileAddAdmin extends StatefulWidget {
  final List<V2TimGroupMemberFullInfo?> memberList;
  final String appbarTitle;
  final void Function(BuildContext context,
          List<V2TimGroupMemberFullInfo?> selectedMemberList)?
      selectCompletedHandler;

  const GroupProfileAddAdmin(
      {Key? key,
      required this.memberList,
      this.selectCompletedHandler,
      required this.appbarTitle})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupProfileAddAdminState();
}

class _GroupProfileAddAdminState extends TIMUIKitState<GroupProfileAddAdmin> {
  List<V2TimGroupMemberFullInfo?> selectedMemberList = [];

  void onSubmit() {
    if (widget.selectCompletedHandler != null) {
      widget.selectCompletedHandler!(context, selectedMemberList);
    }
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;

    Widget addAdminPage() {
      return SingleChildScrollView(
          child: Column(
        children: [
          Container(
            alignment: Alignment.topLeft,
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Text(
              TIM_t("群成员"),
              style: const TextStyle(fontSize: 14, color: AidaBaseColors.white),
            ),
          ),
          ...widget.memberList
              .map((e) => Container(
                    decoration: BoxDecoration(
                        color: AidaBaseColors.whiteWithOpacity01,
                        border: const Border(
                            bottom: BorderSide(
                                color: Colors.transparent))),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    child: InkWell(
                      onTap: () {
                        final isChecked = selectedMemberList.contains(e);
                        if (isChecked) {
                          selectedMemberList.remove(e);
                        } else {
                          selectedMemberList.add(e);
                        }
                        setState(() {});
                      },
                      child: Row(
                        children: [
                          CheckBoxButton(
                            onlyShow: true,
                            isChecked: selectedMemberList.contains(e),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: Avatar(
                              faceUrl: e?.faceUrl ?? "",
                              showName: _getShowName(e),
                              type: 2,
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(_getShowName(e),
                              style: const TextStyle(fontSize: 16, color: AidaBaseColors.white))
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ],
      ));
    }

    return TUIKitScreenUtils.getDeviceWidget(
        context: context,
        desktopWidget: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: addAdminPage(),
        ),
        defaultWidget: ChatBaseScreen(
            safeAreaTop: false,
            safeAreaBottom: false,
            backgroundColor: Colors.transparent,
            backgroundImage: AidaBaseColors.baseBackgroundImage,
            appBar: ChatBaseAppBar(
              title: widget.appbarTitle,
              leading: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  TIM_t("取消"),
                  style: const TextStyle(
                    color: AidaBaseColors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    onSubmit();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    TIM_t("完成"),
                    style: const TextStyle(
                      color: AidaBaseColors.white,
                      fontSize: 14,
                    ),
                  ),
                )
              ],
            ),
            body: addAdminPage()));
  }
}
