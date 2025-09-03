import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../core/constants/app_constants.dart';
import '../../controllers/workplace_detail_controller.dart';
import '../../../data/models/employee_model.dart';

class EditEmployeeView extends StatefulWidget {
  const EditEmployeeView({super.key});

  @override
  State<EditEmployeeView> createState() => _EditEmployeeViewState();
}

class _EditEmployeeViewState extends State<EditEmployeeView> {
  final WorkplaceDetailController controller = Get.find<WorkplaceDetailController>();

  late Employee employee;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _wageController;

  XFile? _newContractImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    employee = Get.arguments as Employee;
    _nameController = TextEditingController(text: employee.name);
    _phoneController = TextEditingController(text: employee.phoneNumber);
    _wageController = TextEditingController(text: employee.hourlyWage.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newContractImage = image;
      });
    }
  }

  void _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    // 새 이미지 업로드 처리
    String? newImageUrl;
    if (_newContractImage != null) {
      // TODO: Firebase Storage 업로드 로직
      // newImageUrl = await uploadImage(_newContractImage!);
    }

    await controller.updateEmployee(
      employeeId: employee.id,
      name: _nameController.text.trim(),
      phoneNumber: controller.formatPhoneNumber(_phoneController.text.trim()),
      hourlyWage: int.parse(_wageController.text.trim()),
      contractImageUrl: newImageUrl ?? employee.contractImageUrl,
    );

    Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'ko_KR', symbol: '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('직원 정보 수정'),
        actions: [
          TextButton(
            onPressed: _updateEmployee,
            child: const Text(
              '저장',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '기본 정보',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 이름
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '이름',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '이름을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 전화번호
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: '전화번호',
                          prefixIcon: Icon(Icons.phone),
                          hintText: '010-0000-0000',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '전화번호를 입력해주세요';
                          }
                          String numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (numbers.length != 11 || !numbers.startsWith('010')) {
                            return '올바른 전화번호를 입력해주세요';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (value.length == 11) {
                            _phoneController.text = controller.formatPhoneNumber(value);
                            _phoneController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _phoneController.text.length),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // 시급
                      TextFormField(
                        controller: _wageController,
                        decoration: InputDecoration(
                          labelText: '시급',
                          prefixIcon: const Icon(Icons.monetization_on),
                          suffixText: '원',
                          helperText: '2025년 최저시급: ${currencyFormatter.format(AppConstants.minimumWage)}원',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '시급을 입력해주세요';
                          }
                          final wage = int.tryParse(value);
                          if (wage == null || wage < AppConstants.minimumWage) {
                            return '최저시급(${currencyFormatter.format(AppConstants.minimumWage)}원) 이상을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 근로계약서
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '근로계약서',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_newContractImage != null) ...[
                        // 새로 선택한 이미지
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_newContractImage!.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _newContractImage = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (employee.contractImageUrl != null) ...[
                        // 기존 이미지
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              employee.contractImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline, size: 48),
                                      SizedBox(height: 8),
                                      Text('이미지를 불러올 수 없습니다'),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ] else ...[
                        // 이미지 없음
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 48),
                                SizedBox(height: 8),
                                Text('근로계약서가 등록되지 않았습니다'),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: Text(_newContractImage != null ? '다른 이미지 선택' : '이미지 선택'),
                        ),
                      ),
                    ],
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