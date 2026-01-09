import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/add_employee_controller.dart';

class AddEmployeeView extends GetView<AddEmployeeController> {
  const AddEmployeeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${controller.workplace.name} 직원 추가'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 스크롤 가능한 폼 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이름 입력
                      _buildNameField(),
                      const SizedBox(height: 16),

                      // 전화번호 입력
                      _buildPhoneField(),
                      const SizedBox(height: 16),

                      // 시급 입력
                      _buildWageField(),
                      const SizedBox(height: 24),

                      // 계좌정보 입력
                      _buildBankInfoFields(),
                      const SizedBox(height: 24),

                      // 근로계약서 섹션
                      _buildContractSection(),
                    ],
                  ),
                ),
              ),
            ),

            // 하단 고정 추가 버튼
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value || controller.isImageUploading.value
                        ? null
                        : controller.addEmployee,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isLoading.value || controller.isImageUploading.value
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          controller.isImageUploading.value
                              ? '근로계약서 업로드 중...'
                              : '직원 등록 중...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                        : const Text(
                      '직원 추가',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이름 *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.nameController,
          validator: controller.validateName,
          decoration: const InputDecoration(
            hintText: '직원 이름을 입력하세요',
            prefixIcon: Icon(Icons.person),
          ),
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            // 실시간 유효성 검사를 위해 폼 상태 업데이트
            controller.formKey.currentState?.validate();
          },
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '전화번호 *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.phoneController,
          validator: controller.validatePhone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: const InputDecoration(
            hintText: '01012345678',
            prefixIcon: Icon(Icons.phone),
          ),
          onChanged: (value) {
            // 자동 포맷팅
            if (value.length == 11) {
              controller.phoneController.text = controller.formatPhoneNumber(value);
              controller.phoneController.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.phoneController.text.length),
              );
            }

            // 실시간 유효성 검사를 위해 폼 상태 업데이트
            controller.formKey.currentState?.validate();
          },
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildWageField() {
    final currencyFormatter = NumberFormat.currency(locale: 'ko_KR', symbol: '');
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMinWage = AppConstants.getCurrentMinimumWage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '시급 *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.wageController,
          validator: controller.validateWage,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: currentMinWage.toString(),
            prefixIcon: const Icon(Icons.monetization_on),
            suffixText: '원',
            helperText: '$currentYear년 최저시급: ${currencyFormatter.format(currentMinWage)}원',
          ),
          onChanged: (value) {
            controller.formKey.currentState?.validate();
          },
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildBankInfoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '계좌정보 (선택사항)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // 은행명
        TextFormField(
          controller: controller.bankNameController,
          decoration: const InputDecoration(
            hintText: '예) 국민은행',
            prefixIcon: Icon(Icons.account_balance),
            labelText: '은행명',
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // 계좌번호
        TextFormField(
          controller: controller.accountNumberController,
          decoration: const InputDecoration(
            hintText: '123456-78-901234',
            prefixIcon: Icon(Icons.credit_card),
            labelText: '계좌번호',
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildContractSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '근로계약서',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '근로계약서 이미지를 첨부하면 나중에 확인할 수 있습니다. (선택사항)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),

        Obx(() {
          if (controller.selectedImage.value != null) {
            return _buildImagePreview();
          }
          return _buildImagePicker();
        }),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () => _showImageSourceBottomSheet(), // ✅ context 제거
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              '이미지 선택',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            Text(
              '터치하여 카메라 또는 갤러리 선택',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceBottomSheet() { // ✅ context 파라미터 제거
    showModalBottomSheet(
      context: Get.context!, // ✅ Get.context 사용
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 타이틀
                const Text(
                  '근로계약서 이미지',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // 카메라 버튼
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    '카메라로 촬영',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    '지금 바로 촬영하기',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    controller.pickImage(source: ImageSource.camera);
                  },
                ),

                // 구분선
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.grey[300],
                ),

                // 갤러리 버튼
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: Colors.green[700],
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    '갤러리에서 선택',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    '저장된 사진 선택하기',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    controller.pickImage(source: ImageSource.gallery);
                  },
                ),

                const SizedBox(height: 10),

                // 취소 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              controller.selectedImage.value!,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: controller.removeImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Obx(() => ElevatedButton(
        onPressed: controller.isLoading.value || controller.isImageUploading.value
            ? null
            : controller.addEmployee,
        child: controller.isLoading.value || controller.isImageUploading.value
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              controller.isImageUploading.value
                  ? '근로계약서 업로드 중...'
                  : '직원 등록 중...',
            ),
          ],
        )
            : const Text(
          '직원 추가',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      )),
    );
  }
}