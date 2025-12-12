import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../controllers/workplace_detail_controller.dart';
import '../../../data/models/employee_model.dart';

class EditEmployeeView extends StatefulWidget {
  const EditEmployeeView({super.key});

  @override
  State<EditEmployeeView> createState() => _EditEmployeeViewState();
}

class _EditEmployeeViewState extends State<EditEmployeeView> {
  final WorkplaceDetailController controller = Get.find<WorkplaceDetailController>();
  bool _isImageDeleted = false;

  late Employee employee;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _wageController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;

  File? _newContractImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isImageUploading = false;

  @override
  void initState() {
    super.initState();
    employee = Get.arguments as Employee;
    _nameController = TextEditingController(text: employee.name);
    _phoneController = TextEditingController(text: employee.phoneNumber);
    _wageController = TextEditingController(text: employee.hourlyWage.toString());
    _bankNameController = TextEditingController(text: employee.bankName ?? '');
    _accountNumberController = TextEditingController(text: employee.accountNumber ?? '');

    // Firestore에서 최신 정보 가져오기
    _loadLatestEmployeeInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _wageController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestEmployeeInfo() async {
    try {
      final employeeArg = Get.arguments as Employee;

      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.employeesCollection)
          .doc(employeeArg.id)
          .get();

      if (doc.exists) {
        setState(() {
          employee = Employee.fromFirestore(doc);
          _nameController.text = employee.name;
          _phoneController.text = employee.phoneNumber;
          _wageController.text = employee.hourlyWage.toString();
          _bankNameController.text = employee.bankName ?? '';
          _accountNumberController.text = employee.accountNumber ?? '';
        });
      }
    } catch (e) {
      print('최신 직원 정보 로드 오류: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _newContractImage = File(image.path);
          _isImageDeleted = false;
        });
      }
    } catch (e) {
      SnackbarHelper.showError('이미지를 선택할 수 없습니다.');
    }
  }

  Future<String?> _uploadImage() async {
    if (_newContractImage == null) return null;

    try {
      setState(() {
        _isImageUploading = true;
      });

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'contracts/${controller.workplace.id}/${timestamp}_contract.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'workplaceId': controller.workplace.id,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(_newContractImage!, metadata);
      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      print('이미지 업로드 완료: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('이미지 업로드 오류: $e');
      SnackbarHelper.showError('이미지 업로드에 실패했습니다. 다시 시도해주세요.');
      return null;
    } finally {
      setState(() {
        _isImageUploading = false;
      });
    }
  }

  void _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? newImageUrl = employee.contractImageUrl;

      if (_isImageDeleted && employee.contractImageUrl != null) {
        await _deleteContractImage(employee.contractImageUrl!);
        newImageUrl = null;
      }

      if (_newContractImage != null) {
        if (employee.contractImageUrl != null && !_isImageDeleted) {
          await _deleteContractImage(employee.contractImageUrl!);
        }

        final uploadedUrl = await _uploadImage();
        if (uploadedUrl != null) {
          newImageUrl = uploadedUrl;
        } else {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final success = await controller.updateEmployee(
        employeeId: employee.id,
        name: _nameController.text.trim(),
        phoneNumber: controller.formatPhoneNumber(_phoneController.text.trim()),
        hourlyWage: int.parse(_wageController.text.trim()),
        contractImageUrl: newImageUrl,
        bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim().isEmpty ? null : _accountNumberController.text.trim(),
      );

      if (success) {
        final employeeName = _nameController.text.trim();

        if (mounted) {
          Navigator.of(context).pop(true);
        }

        SnackbarHelper.showSuccess('$employeeName 직원 정보가 수정되었습니다.');
      }
    } catch (e) {
      print('직원 수정 오류: $e');
      SnackbarHelper.showError('직원 정보 수정에 실패했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'ko_KR', symbol: '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('직원 정보 수정'),
        actions: [
          TextButton(
            onPressed: _isLoading || _isImageUploading ? null : _updateEmployee,
            child: _isLoading || _isImageUploading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              '저장',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 기본 정보 카드
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

                // 계좌정보 카드
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '계좌정보',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 은행명
                        TextFormField(
                          controller: _bankNameController,
                          decoration: const InputDecoration(
                            labelText: '은행명',
                            prefixIcon: Icon(Icons.account_balance),
                            hintText: '예) 국민은행',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 계좌번호
                        TextFormField(
                          controller: _accountNumberController,
                          decoration: const InputDecoration(
                            labelText: '계좌번호',
                            prefixIcon: Icon(Icons.credit_card),
                            hintText: '123456-78-901234',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 근로계약서 카드
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
                                    _newContractImage!,
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
                        ] else if (employee.contractImageUrl != null && !_isImageDeleted) ...[
                          // 기존 이미지 (삭제 표시되지 않은 경우만)
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
                                  child: Image.network(
                                    employee.contractImageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
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
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.white),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: _showDeleteImageDialog,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // 이미지 없음 (삭제된 경우도 여기 표시)
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[50],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image_not_supported, size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  _isImageDeleted
                                      ? '근로계약서가 삭제 예정입니다\n(저장 시 완전 삭제)'
                                      : '근로계약서가 등록되지 않았습니다',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isImageDeleted ? Colors.orange[700] : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isImageUploading ? null : _pickImage,
                            icon: _isImageUploading
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Icons.photo_library),
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
      ),
    );
  }

  void _showDeleteImageDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('근로계약서 삭제'),
        content: const Text('첨부된 근로계약서를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              setState(() {
                _isImageDeleted = true;
              });
              SnackbarHelper.showWarning(
                '근로계약서가 삭제 표시되었습니다. 저장 버튼을 눌러주세요.',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContractImage(String imageUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
      print('Firebase Storage에서 이미지 삭제 완료');
    } catch (e) {
      print('이미지 삭제 오류 (무시 가능): $e');
    }
  }
}