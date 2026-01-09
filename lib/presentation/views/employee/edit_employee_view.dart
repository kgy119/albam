import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
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
  final StorageService _storageService = StorageService();

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

  // ✅ Signed URL 저장
  String? _displayImageUrl;
  bool _isLoadingImageUrl = false;

  @override
  void initState() {
    super.initState();
    employee = Get.arguments as Employee;
    _nameController = TextEditingController(text: employee.name);
    _phoneController = TextEditingController(text: employee.phoneNumber);
    _wageController = TextEditingController(text: employee.hourlyWage.toString());
    _bankNameController = TextEditingController(text: employee.bankName ?? '');
    _accountNumberController = TextEditingController(text: employee.accountNumber ?? '');

    // ✅ 이미지 URL을 signed URL로 변환
    if (employee.contractImageUrl != null) {
      _convertToSignedUrl();
    }

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

  // ✅ Signed URL 변환
  Future<void> _convertToSignedUrl() async {
    if (employee.contractImageUrl == null) return;

    setState(() {
      _isLoadingImageUrl = true;
    });

    try {
      final signedUrl = await _storageService.getSignedImageUrl(
        employee.contractImageUrl!,
      );

      if (mounted) {
        setState(() {
          _displayImageUrl = signedUrl;
          _isLoadingImageUrl = false;
        });
      }
    } catch (e) {
      print('Signed URL 변환 오류: $e');
      if (mounted) {
        setState(() {
          _displayImageUrl = employee.contractImageUrl;
          _isLoadingImageUrl = false;
        });
      }
    }
  }


  Future<void> _loadLatestEmployeeInfo() async {
    try {
      final latestEmployee = await controller.getLatestEmployeeInfo(employee.id);

      if (latestEmployee != null && mounted) {
        setState(() {
          employee = latestEmployee;
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
    await _showImageSourceBottomSheet();
  }

  Future<void> _showImageSourceBottomSheet() async {
    await showModalBottomSheet(
      context: context,
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
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImageFromSource(ImageSource.camera);
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
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImageFromSource(ImageSource.gallery);
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

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
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

      print('Storage 업로드 시작');

      // StorageService를 통해 업로드
      final imageUrl = await _storageService.uploadContractImage(
        workplaceId: controller.workplace.id,
        imageFile: _newContractImage!,
      );

      print('이미지 업로드 완료: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('이미지 업로드 오류: $e');
      SnackbarHelper.showError('이미지 업로드에 실패했습니다. 다시 시도해주세요.');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isImageUploading = false;
        });
      }
    }
  }

  void _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? newImageUrl = employee.contractImageUrl;

      // 기존 이미지 삭제 처리
      if (_isImageDeleted && employee.contractImageUrl != null) {
        await _storageService.deleteContractImage(employee.contractImageUrl!);
        newImageUrl = null;
      }

      // 새 이미지 업로드 처리
      if (_newContractImage != null) {
        // 기존 이미지가 있고 삭제 표시가 안 되어 있으면 기존 이미지 삭제
        if (employee.contractImageUrl != null && !_isImageDeleted) {
          await _storageService.deleteContractImage(employee.contractImageUrl!);
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
        bankName: _bankNameController.text.trim().isEmpty
            ? null
            : _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim().isEmpty
            ? null
            : _accountNumberController.text.trim(),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 스크롤 가능한 폼 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Form(
                  key: _formKey,
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

                              // 시급 필드
                              TextFormField(
                                controller: _wageController,
                                decoration: InputDecoration(
                                  labelText: '시급',
                                  prefixIcon: const Icon(Icons.monetization_on),
                                  suffixText: '원',
                                  helperText: '${DateTime.now().year}년 최저시급: ${currencyFormatter.format(AppConstants.getCurrentMinimumWage())}원',
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
                                  final currentMinWage = AppConstants.getCurrentMinimumWage();

                                  if (wage == null || wage < currentMinWage) {
                                    return '최저시급(${currencyFormatter.format(currentMinWage)}원) 이상을 입력해주세요';
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
                                // ✅ 기존 이미지 (Signed URL 사용)
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
                                        child: _isLoadingImageUrl
                                            ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                            : _displayImageUrl != null
                                            ? Image.network(
                                          _displayImageUrl!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            print('이미지 로드 오류: $error');
                                            return Container(
                                              color: Colors.grey[100],
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                                  const SizedBox(height: 8),
                                                  const Text(
                                                    '이미지를 불러올 수 없습니다',
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '다시 업로드해주세요',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  ElevatedButton.icon(
                                                    onPressed: _pickImage,
                                                    icon: const Icon(Icons.refresh, size: 16),
                                                    label: const Text('다시 선택'),
                                                    style: ElevatedButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                            : const Center(
                                          child: CircularProgressIndicator(),
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
                                // 이미지 없음
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

            // 하단 고정 저장 버튼
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
                  child: ElevatedButton(
                    onPressed: _isLoading || _isImageUploading ? null : _updateEmployee,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading || _isImageUploading
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
                          _isImageUploading ? '이미지 업로드 중...' : '저장 중...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                        : const Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteImageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('근로계약서 삭제'),
          content: const Text('첨부된 근로계약서를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
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
        );
      },
    );
  }
}