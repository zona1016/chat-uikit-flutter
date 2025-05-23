// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_app_bar.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_screen.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_im_base/tencent_im_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/group_member_list.dart';

class GroupSearchMemberListPage extends StatefulWidget {
  List<V2TimGroupMemberFullInfo?> memberList;
  TUIGroupProfileModel model;

  GroupSearchMemberListPage({
    Key? key,
    required this.memberList,
    required this.model,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => GroupProfileMemberListPageState();
}

class GroupProfileMemberListPageState
    extends TIMUIKitState<GroupSearchMemberListPage> {
  List<V2TimGroupMemberFullInfo?>? selectedMemberList;
  String? searchText;

  _kickedOffMember(String userID) async {
    widget.model.kickOffMember([userID]);
  }

  bool isSearchTextExist(String? searchText) {
    return searchText != null && searchText != "";
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor() == DeviceType.Desktop;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.model),
      ],
      builder: (BuildContext context, Widget? w) {
        final TUIGroupProfileModel groupProfileModel =
            Provider.of<TUIGroupProfileModel>(context);
        String option1 = groupProfileModel.groupInfo?.memberCount.toString() ??
            widget.memberList.length.toString();
        if (isDesktopScreen) {
          return GroupProfileMemberList(
            memberList: groupProfileModel.groupMemberList,
            removeMember: _kickedOffMember,
            touchBottomCallBack: () {},
            onTapMemberItem: (friendInfo, details) {
              if (widget.model.onClickUser != null) {
                widget.model.onClickUser!(friendInfo.userID, details);
              }
            },
          );
        }
        return ChatBaseScreen(
            safeAreaTop: false,
            safeAreaBottom: false,
            backgroundColor: Colors.transparent,
            backgroundImage: AidaBaseColors.baseBackgroundImage,
            appBar: ChatBaseAppBar(
              title: TIM_t_para("群成员({{option1}}人)", "群成员($option1人)")(
                  option1: option1),
              actions: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context, selectedMemberList);
                  },
                  child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Text(TIM_t('完成'),
                          style: const TextStyle(
                            color: AidaBaseColors.white,
                          ))),
                )
              ],
            ),
            body: GroupProfileMemberList(
                canSelectMember: true,
                memberList: groupProfileModel.groupMemberList,
                removeMember: _kickedOffMember,
                touchBottomCallBack: () {},
                onTapMemberItem: (friendInfo, details) {
                  if (widget.model.onClickUser != null) {
                    widget.model.onClickUser!(friendInfo.userID, details);
                  }
                },
                maxSelectNum: 5,
                onSelectedMemberChange: (member) {
                  setState(() {
                    selectedMemberList = member;
                  });
                }));
      },
    );
  }
}
