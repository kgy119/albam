import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/subscription_limit_service.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/workplace_model.dart';
import '../controllers/workplace_detail_controller.dart';

class AddEmployeeController extends GetxController {
  final StorageService _storageService = StorageService();

  // 폼 컨트롤러들
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final wageController = TextEditingController();
  final bankNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final SubscriptionLimitService _limitService = SubscriptionLimitService();


  // 폼 키
  final formKey = GlobalKey<FormState>();

  // 사업장 정보
  late Workplace workplace;

  // 기존 직원 목록 (중복 확인용)
  List<String> existingEmployeeNames = [];

  // 이미지 관련
  Rxn<File> selectedImage = Rxn<File>();
  final ImagePicker _picker = ImagePicker();

  // 로딩 상태
  RxBool isLoading = false.obs;
  RxBool isImageUploading = false.obs;

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments;
    if (arguments is Map<String, dynamic>) {
      workplace = arguments['workplace'];
      final existingEmployees = arguments['existingEmployees'] as List<dynamic>?;
      if (existingEmployees != null) {
        existingEmployeeNames = existingEmployees
            .map((emp) => emp.name.toString().trim().toLowerCase())
            .toList();
      }
    } else {
      workplace = arguments as Workplace;
    }

    // 현재 날짜 기준 최저시급 설정
    wageController.text = AppConstants.getCurrentMinimumWage().toString();
  }

  String? validateWage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '시급을 입력해주세요';
    }

    final wage = int.tryParse(value.trim());
    final currentMinWage = AppConstants.getCurrentMinimumWage();

    if (wage == null || wage < currentMinWage) {
      return '최저시급(${NumberFormat.currency(locale: 'ko_KR', symbol: '').format(currentMinWage)}원) 이상을 입력해주세요';
    }

    return null;
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    wageController.dispose();
    bankNameController.dispose();
    accountNumberController.dispose();
    super.onClose();
  }

  /// 이미지 선택
  Future<void> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
        print('✅ 이미지 선택 완료: ${image.path}');
      }
    } catch (e) {
      print('❌ 이미지 선택 오류: $e');
      SnackbarHelper.showError('이미지를 선택할 수 없습니다.');
    }
  }

  /// 이미지 선택 방법 다이얼로그 표시
  void showImageSourceDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('근로계약서 이미지'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Get.back();
                pickImage(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Get.back();
                pickImage(source: ImageSource.gallery);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  /// 이미지 Supabase Storage에 업로드
  Future<String?> _uploadImage() async {
    if (selectedImage.value == null) return null;

    try {
      isImageUploading.value = true;

      print('Storage 업로드 시작');

      final imageUrl = await _storageService.uploadContractImage(
        workplaceId: workplace.id,
        imageFile: selectedImage.value!,
      );

      print('이미지 업로드 완료: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('이미지 업로드 오류: $e');
      SnackbarHelper.showError('이미지 업로드에 실패했습니다. 다시 시도해주세요.'); // 수정
      return null;
    } finally {
      isImageUploading.value = false;
    }
  }

  /// 직원 추가
  Future<void> addEmployee() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // 이름 중복 확인
    final trimmedName = nameController.text.trim().toLowerCase();
    if (existingEmployeeNames.contains(trimmedName)) {
      SnackbarHelper.showWarning('이미 등록된 직원 이름입니다.');
      return;
    }

    if (isLoading.value || isImageUploading.value) {
      return;
    }

    try {
      isLoading.value = true;

      // 1. 직원 추가 가능 여부 확인 (한도 체크)
      final checkResult = await _limitService.canAddEmployee(workplace.id);

      if (!(checkResult['can_add'] as bool)) {
        isLoading.value = false;
        _showEmployeeLimitDialog(checkResult);
        return;
      }

      // 2. 이미지가 선택된 경우 업로드
      String? imageUrl;
      if (selectedImage.value != null) {
        isImageUploading.value = true;
        imageUrl = await _storageService.uploadContractImage(
          workplaceId: workplace.id,
          imageFile: selectedImage.value!,
        );
        isImageUploading.value = false;
      }

      // 3. 직원 추가
      final controller = Get.find<WorkplaceDetailController>();
      final success = await controller.addEmployee(
        name: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        hourlyWage: int.parse(wageController.text.trim()),
        contractImageUrl: imageUrl,
        bankName: bankNameController.text.trim().isEmpty
            ? null
            : bankNameController.text.trim(),
        accountNumber: accountNumberController.text.trim().isEmpty
            ? null
            : accountNumberController.text.trim(),
      );

      if (success) {
        Get.back(result: {
          'success': true,
          'employeeName': nameController.text.trim(),
        });
      }
    } catch (e) {
      print('직원 추가 오류: $e');
      SnackbarHelper.showError('직원 추가에 실패했습니다.');
    } finally {
      isLoading.value = false;
      isImageUploading.value = false;
    }
  }

  /// 직원 추가 한도 초과 다이얼로그
  void _showEmployeeLimitDialog(Map<String, dynamic> checkResult) {
    final currentCount = checkResult['current_count'] as int;
    final maxEmployees = checkResult['max_employees'] as int;
    final tier = checkResult['tier'] as String;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber[700]),
            const SizedBox(width: 8),
            const Text('직원 추가 제한'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tier == 'free'
                  ? '무료 회원은 사업장당 최대 3명의 직원만 등록할 수 있습니다.'
                  : '사업장당 직원 등록 한도($maxEmployees명)에 도달했습니다.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '현재 등록된 직원',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$currentCount / $maxEmployees명',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
            if (tier == 'free') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.amber[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '프리미엄 혜택',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildBenefitItem('사업장 최대 10개'),
                    _buildBenefitItem('사업장당 직원 20명까지'),
                    _buildBenefitItem('무제한 근무 스케줄 관리'),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          if (tier == 'free')
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.toNamed('/account-settings');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('프리미엄 구독하기'),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.amber[700], size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 이미지 제거
  void removeImage() {
    selectedImage.value = null;
  }

  /// 전화번호 포맷팅
  String formatPhoneNumber(String phone) {
    String numbers = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.length == 11) {
      return '${numbers.substring(0, 3)}-${numbers.substring(3, 7)}-${numbers.substring(7)}';
    }

    return phone;
  }

  /// 폼 유효성 검사
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해주세요';
    }

    // 기존 직원 이름과 중복 확인
    if (existingEmployeeNames.contains(value.trim().toLowerCase())) {
      return '이미 등록된 직원 이름입니다';
    }

    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '전화번호를 입력해주세요';
    }

    String numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length != 11 || !numbers.startsWith('010')) {
      return '올바른 전화번호를 입력해주세요 (010-XXXX-XXXX)';
    }

    return null;
  }
}