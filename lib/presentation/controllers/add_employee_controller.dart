import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
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
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      String? contractImageUrl;
      if (selectedImage.value != null) {
        contractImageUrl = await _uploadImage();
        if (contractImageUrl == null) {
          isLoading.value = false;
          return;
        }
      }

      final workplaceController = Get.find<WorkplaceDetailController>();

      final success = await workplaceController.addEmployee(
        name: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        hourlyWage: int.parse(wageController.text.trim()),
        contractImageUrl: contractImageUrl,
        bankName: bankNameController.text.trim().isEmpty
            ? null
            : bankNameController.text.trim(),
        accountNumber: accountNumberController.text.trim().isEmpty
            ? null
            : accountNumberController.text.trim(),
      );

      if (success) {
        print('직원 추가 성공 - 화면 이동');

        Get.back(result: {
          'success': true,
          'employeeName': nameController.text.trim(),
        });
      } else {
        print('직원 추가 실패');
      }
    } catch (e) {
      print('직원 추가 예외 오류: $e');
      SnackbarHelper.showError('직원 추가 중 오류가 발생했습니다.'); // 수정
    } finally {
      isLoading.value = false;
    }
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