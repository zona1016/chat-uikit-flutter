import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_base_button.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/color.dart';

class GroupAddOptWidget extends StatefulWidget {
  final Function(int allowType)? callback;

  const GroupAddOptWidget({super.key, this.callback});

  @override
  State<GroupAddOptWidget> createState() => _GroupAddOptWidgetState();
}

class _GroupAddOptWidgetState extends State<GroupAddOptWidget> {
  final actionList = [
    {"label": TIM_t("禁止加群"), "id": GroupAddOptType.V2TIM_GROUP_ADD_FORBID},
    {"label": TIM_t("自动审批"), "id": GroupAddOptType.V2TIM_GROUP_ADD_ANY},
    {"label": TIM_t("管理员审批"), "id": GroupAddOptType.V2TIM_GROUP_ADD_AUTH}
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Column(
            children: actionList
                .map((e) => typeWidget(e["id"] as int, e["label"] as String))
                .toList(),
          ),
          ChatBaseButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            text: TIM_t('取消'),
          )
        ],
      ),
    );
  }

  Widget typeWidget(int type, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () {
          if (widget.callback != null) widget.callback!(type);
          Navigator.of(context).pop();
        },
        child: Container(
          height: 60,
          color: AidaBaseColors.whiteWithOpacity01,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AidaBaseColors.primaryColor,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
