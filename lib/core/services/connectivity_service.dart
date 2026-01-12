import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../utils/snackbar_helper.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('연결 상태 확인 오류: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      isConnected.value = false;
      _showNoConnectionMessage();
      return;
    }

    final hasConnection = results.any((result) =>
    result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet
    );

    if (!hasConnection && isConnected.value) {
      _showNoConnectionMessage();
    } else if (hasConnection && !isConnected.value) {
      _showConnectionRestoredMessage();
    }

    isConnected.value = hasConnection;
  }

  void _showNoConnectionMessage() {
    SnackbarHelper.showError(
      '인터넷 연결이 끊어졌습니다.\nWi-Fi 또는 데이터 연결을 확인해주세요.',
    );
  }

  void _showConnectionRestoredMessage() {
    SnackbarHelper.showSuccess(
      '인터넷 연결이 복구되었습니다.',
    );
  }

  /// 인터넷 연결 확인 후 작업 실행
  Future<T?> executeWithConnectivity<T>(Future<T> Function() action) async {
    if (!isConnected.value) {
      SnackbarHelper.showError(
        '인터넷 연결이 필요합니다.\n연결 상태를 확인해주세요.',
      );
      return null;
    }

    try {
      return await action();
    } catch (e) {
      print('작업 실행 오류: $e');
      rethrow;
    }
  }
}