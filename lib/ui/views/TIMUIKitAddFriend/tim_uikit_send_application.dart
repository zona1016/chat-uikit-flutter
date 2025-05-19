import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/add_friend_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_self_info_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';

import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';

class SendApplication extends StatefulWidget {
  final V2TimUserFullInfo friendInfo;
  final TUISelfInfoViewModel model;
  final bool? isShowDefaultGroup;
  final AddFriendLifeCycle? lifeCycle;
  final Function(String detail)? addResult;

  const SendApplication(
      {Key? key,
      this.lifeCycle,
      required this.friendInfo,
      required this.model,
      this.isShowDefaultGroup = false,
      this.addResult})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SendApplicationState();
}

class _SendApplicationState extends TIMUIKitState<SendApplication> {
  final TextEditingController _verficationController = TextEditingController();
  final TextEditingController _nickNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final showName =
        widget.model.loginInfo?.nickName ?? widget.model.loginInfo?.userID;
    _verficationController.text = "我是: $showName";
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final FriendshipServices _friendshipServices =
        serviceLocator<FriendshipServices>();

    final faceUrl = widget.friendInfo.faceUrl ?? "";
    final userID = widget.friendInfo.userID ?? "";
    final String showName = ((widget.friendInfo.nickName != null &&
                widget.friendInfo.nickName!.isNotEmpty)
            ? widget.friendInfo.nickName
            : userID) ??
        "";
    final option2 = widget.friendInfo.selfSignature ?? "";

    Widget sendApplicationBody() {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: AidaBaseColors.whiteWithOpacity01,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24)
                    ),
                    child: Avatar(faceUrl: faceUrl, showName: showName, borderRadius: BorderRadius.circular(24),),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showName,
                        style:
                            const TextStyle(color: AidaBaseColors.white, fontSize: 18),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        "ID: $userID",
                        style:
                            const TextStyle(fontSize: 13, color: AidaBaseColors.weakTextColor),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      if (TencentUtils.checkString(option2) != null)
                        Text(
                          TIM_t_para("个性签名: {{option2}}", "个性签名: $option2")(
                              option2: option2),
                          style: const TextStyle(
                              fontSize: 13, color: AidaBaseColors.white),
                        ),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                TIM_t("填写验证信息"),
                style: const TextStyle(fontSize: 16, color: AidaBaseColors.white),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 6, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AidaBaseColors.whiteWithOpacity01,
              child: TextField(
                // minLines: 1,
                maxLines: 4,
                style: const TextStyle(color: AidaBaseColors.white),
                controller: _verficationController,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AidaBaseColors.white),
                  hintText: '',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                TIM_t("请填写备注"),
                style: const TextStyle(fontSize: 16, color: AidaBaseColors.white),
              ),
            ),
            Container(
              color: AidaBaseColors.whiteWithOpacity01,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TIM_t("备注"),
                    style: TextStyle(color: AidaBaseColors.white, fontSize: 16),
                  ),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _nickNameController,
                      style: const TextStyle(color: AidaBaseColors.white),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: AidaBaseColors.white,
                        ),
                        hintText: '',
                      ),
                    ),
                  )
                ],
              ),
            ),
            if (widget.isShowDefaultGroup == true)
              Container(
                color: AidaBaseColors.whiteWithOpacity01,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TIM_t("分组"),
                      style:
                          const TextStyle(color: AidaBaseColors.white, fontSize: 16),
                    ),
                    Text(
                      TIM_t("我的好友"),
                      style:
                          const TextStyle(color: AidaBaseColors.white, fontSize: 16),
                    )
                  ],
                ),
              ),
            Container(
              color: AidaBaseColors.whiteWithOpacity01,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              child: TextButton(
                  onPressed: () async {
                    final remark = _nickNameController.text;
                    final addWording = _verficationController.text;
                    final friendGroup = TIM_t("我的好友");

                    if (widget.lifeCycle?.shouldAddFriend != null &&
                        await widget.lifeCycle!.shouldAddFriend(userID, remark,
                                friendGroup, addWording, context) ==
                            false) {
                      return;
                    }

                    final res = await _friendshipServices.addFriend(
                        userID: userID,
                        addType: FriendTypeEnum.V2TIM_FRIEND_TYPE_BOTH,
                        remark: remark,
                        addWording: addWording,
                        friendGroup: friendGroup);

                    if (res.code == 0 && res.data?.resultCode == 0) {
                      onTIMCallback(TIMCallback(
                          type: TIMCallbackType.INFO,
                          infoRecommendText: TIM_t("好友添加成功"),
                          infoCode: 6661202));
                      if (widget.addResult != null) widget.addResult!(TIM_t("好友添加成功"));
                    } else if (res.code == 0 && res.data?.resultCode == 30539) {
                      onTIMCallback(TIMCallback(
                          type: TIMCallbackType.INFO,
                          infoRecommendText: TIM_t("好友申请已发出"),
                          infoCode: 6661203));
                      if (widget.addResult != null) widget.addResult!(TIM_t("好友申请已发出"));
                    } else if (res.code == 0 && res.data?.resultCode == 30515) {
                      onTIMCallback(TIMCallback(
                          type: TIMCallbackType.INFO,
                          infoRecommendText: TIM_t("当前用户在黑名单"),
                          infoCode: 6661204));
                      if (widget.addResult != null) widget.addResult!(TIM_t("当前用户在黑名单"));
                    }
                  },
                  child: Text(TIM_t("发送"))),
            )
          ],
        ),
      );
    }

    return TUIKitScreenUtils.getDeviceWidget(
        context: context,
        desktopWidget: Container(
          padding: const EdgeInsets.only(top: 10),
          color: theme.weakBackgroundColor,
          child: sendApplicationBody(),
        ),
        defaultWidget: Scaffold(
          backgroundColor: Colors.transparent,
          body: sendApplicationBody(),
        ));
  }
}
