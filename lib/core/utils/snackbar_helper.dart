import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarHelper {
  /// 성공 메시지
  static void showSuccess(String message, {String title = '완료'}) {
    _showSnackbar(message, Colors.green, 2);
  }

  /// 경고 메시지
  static void showWarning(String message, {String title = '알림'}) {
    _showSnackbar(message, Colors.orange, 3);
  }

  /// 에러 메시지
  static void showError(String message, {String title = '오류'}) {
    _showSnackbar(message, Colors.red, 3);
  }

  /// 정보 메시지
  static void showInfo(String message, {String title = '안내'}) {
    _showSnackbar(message, Colors.blue, 2);
  }

  /// 복사 완료 메시지
  static void showCopied(String message) {
    _showSnackbar(message, Colors.green, 2);
  }

  /// Flutter 기본 ScaffoldMessenger 사용 + 강제 타이머
  static void _showSnackbar(String message, Color backgroundColor, int seconds) {
    Future.delayed(const Duration(milliseconds: 100), () {
      final context = Get.context;
      if (context != null && context.mounted) {
        // 기존 스낵바 제거
        ScaffoldMessenger.of(context).clearSnackBars();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: backgroundColor,
            duration: Duration(seconds: seconds),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // ✅ 강제로 닫기 타이머 추가
        Future.delayed(Duration(seconds: seconds), () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
        });
      }
    });
  }
}