import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/add_employee_controller.dart';

class AddEmployeeView extends GetView<AddEmployeeController> {
  const AddEmployeeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${controller.workplace.name} 직원 추가'),
      ),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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

              // 근로계약서 섹션
              _buildContractSection(),
              const SizedBox(height: 32),

              // 추가 버튼
              _buildAddButton(),
            ],
          ),
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
          },
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildWageField() {
    final currencyFormatter = NumberFormat.currency(locale: 'ko_KR', symbol: '');

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
            hintText: '10030',
            prefixIcon: const Icon(Icons.monetization_on),
            suffixText: '원',
            helperText: '2025년 최저시급: ${currencyFormatter.format(10030)}원',
          ),
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
      onTap: controller.pickImage,
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
              Icons.cloud_upload,
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
              '터치하여 갤러리에서 선택',
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
            Text(controller.isImageUploading.value ? '이미지 업로드 중...' : '직원 추가 중...'),
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