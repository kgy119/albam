import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../data/models/workplace_model.dart';
import '../controllers/workplace_detail_controller.dart';

class AddEmployeeController extends GetxController {
  // 폼 컨트롤러들
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final wageController = TextEditingController();

  // 폼 키
  final formKey = GlobalKey<FormState>();

  // 사업장 정보
  late Workplace workplace;

  // 이미지 관련
  Rxn<File> selectedImage = Rxn<File>();
  final ImagePicker _picker = ImagePicker();

  // 로딩 상태
  RxBool isLoading = false.obs;
  RxBool isImageUploading = false.obs;

  @override
  void onInit() {
    super.onInit();
    workplace = Get.arguments as Workplace;

    // 기본 최저시급 설정 (2025년 기준 10,030원)
    wageController.text = '10030';
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    wageController.dispose();
    super.onClose();
  }

  /// 이미지 선택
  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar('오류', '이미지를 선택할 수 없습니다.');
    }
  }

  /// 이미지 제거
  void removeImage() {
    selectedImage.value = null;
  }

  /// 이미지 Firebase Storage에 업로드
  Future<String?> _uploadImage() async {
    if (selectedImage.value == null) return null;

    try {
      isImageUploading.value = true;

      final fileName = 'contracts/${workplace.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putFile(selectedImage.value!);
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('이미지 업로드 오류: $e');
      Get.snackbar('오류', '이미지 업로드에 실패했습니다.');
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
      // 이미지 업로드 (있는 경우)
      String? contractImageUrl;
      if (selectedImage.value != null) {
        contractImageUrl = await _uploadImage();
        if (contractImageUrl == null) {
          isLoading.value = false;
          return; // 이미지 업로드 실패시 중단
        }
      }

      // WorkplaceDetailController 찾기
      final workplaceController = Get.find<WorkplaceDetailController>();

      final success = await workplaceController.addEmployee(
        name: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        hourlyWage: int.parse(wageController.text.trim()),
        contractImageUrl: contractImageUrl,
      );

      if (success) {
        Get.back(); // 이전 화면으로 돌아가기
      }
    } catch (e) {
      print('직원 추가 오류: $e');
      Get.snackbar('오류', '직원 추가에 실패했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  /// 전화번호 포맷팅
  String formatPhoneNumber(String phone) {
    // 숫자만 추출
    String numbers = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.length == 11) {
      // 010-1234-5678 형태로 포맷팅
      return '${numbers.substring(0, 3)}-${numbers.substring(3, 7)}-${numbers.substring(7)}';
    }

    return phone;
  }

  /// 폼 유효성 검사
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해주세요';
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

  String? validateWage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '시급을 입력해주세요';
    }

    final wage = int.tryParse(value.trim());
    if (wage == null || wage < 10030) { // 2025년 최저시급
      return '최저시급(10,030원) 이상을 입력해주세요';
    }

    return null;
  }
}