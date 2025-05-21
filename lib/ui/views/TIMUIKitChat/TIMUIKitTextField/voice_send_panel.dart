import 'package:flutter/material.dart';

enum SlideStatus { left, center, right }

class VoiceSendPanel extends StatelessWidget {
  final SlideStatus slideStatus;

  const VoiceSendPanel({Key? key, required this.slideStatus}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 半圆背景
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'images/record_bottom_bg.png',
              width: double.infinity,
              height: 95,
              fit: BoxFit.fill,
              package: 'tencent_cloud_chat_uikit',
            ),
          ),
          Positioned(
            bottom: 30,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(Icons.mic, color: Colors.black),
            ),
          ),
          Positioned(
            bottom: 105,
            child: Text(
              slideStatus == SlideStatus.left
                  ? "松开取消"
                  : slideStatus == SlideStatus.right
                  ? "松开发送翻译"
                  : "松开发送",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          // 左右按钮
          Positioned(
            bottom: 90,
            left: 40,
            child: _circleButton(Icons.close),
          ),
          // Positioned(
          //   bottom: 90,
          //   right: 40,
          //   child: _circleButton(Icons.translate),
          // ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
