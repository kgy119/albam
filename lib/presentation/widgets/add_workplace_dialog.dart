import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/snackbar_helper.dart';
import '../controllers/workplace_controller.dart';

class AddWorkplaceDialog extends StatelessWidget {
  AddWorkplaceDialog({super.key});

  final TextEditingController _nameController = TextEditingController();
  final WorkplaceController _controller = Get.find<WorkplaceController>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 사업장 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '사업장 이름',
              hintText: '예: 메가커피 일광',
            ),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addWorkplace(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('취소'),
        ),
        Obx(() => ElevatedButton(
          onPressed: _controller.isAdding.value
              ? null
              : _addWorkplace,
          child: _controller.isAdding.value
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('추가'),
        )),
      ],
    );
  }

  void _addWorkplace() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      SnackbarHelper.showWarning('사업장 이름을 입력해주세요.'); // 수정
      return;
    }

    Navigator.of(Get.context!).pop();

    await Future.delayed(const Duration(milliseconds: 200));
    await _controller.addWorkplace(name);
  }

}