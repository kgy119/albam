import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarHelper {
  /// 성공 메시지
  static void showSuccess(String message, {String title = '완료'}) {
    _showSnackbar(message, Colors.green);
  }

  /// 경고 메시지
  static void showWarning(String message, {String title = '알림'}) {
    _showSnackbar(message, Colors.orange, duration: 3);
  }

  /// 에러 메시지
  static void showError(String message, {String title = '오류'}) {
    _showSnackbar(message, Colors.red, duration: 3);
  }

  /// 정보 메시지
  static void showInfo(String message, {String title = '안내'}) {
    _showSnackbar(message, Colors.blue);
  }

  /// 복사 완료 메시지
  static void showCopied(String message) {
    _showSnackbar(message, Colors.green);
  }

  /// Flutter 기본 스낵바 사용 (안정적)
  static void _showSnackbar(
      String message,
      Color backgroundColor, {
        int duration = 2,
      }) {
    Future.delayed(const Duration(milliseconds: 400), () {
      final context = Get.key.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: Duration(seconds: duration),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    });
  }
}