import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 근로계약서 이미지 업로드
  ///
  /// [workplaceId]: 사업장 ID
  /// [imageFile]: 업로드할 이미지 파일
  ///
  /// Returns: 업로드된 이미지의 공개 URL
  Future<String> uploadContractImage({
    required String workplaceId,
    required File imageFile,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = imageFile.path.split('.').last;
      final fileName = '${timestamp}_contract.$fileExtension';
      final filePath = '$workplaceId/$fileName';

      print('Storage 업로드 시작: $filePath');

      // 파일 업로드
      await _supabase.storage
          .from(SupabaseConfig.contractsBucket)
          .upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      print('Storage 업로드 완료');

      // 공개 URL 생성
      final publicUrl = _supabase.storage
          .from(SupabaseConfig.contractsBucket)
          .getPublicUrl(filePath);

      print('공개 URL 생성: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('Storage 업로드 오류: $e');
      throw Exception('이미지 업로드 실패: $e');
    }
  }

  /// 근로계약서 이미지 삭제
  ///
  /// [imageUrl]: 삭제할 이미지의 URL
  Future<void> deleteContractImage(String imageUrl) async {
    try {
      // URL에서 파일 경로 추출
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // 경로 형식: /storage/v1/object/public/contracts/{workplaceId}/{filename}
      final bucketIndex = pathSegments.indexOf(SupabaseConfig.contractsBucket);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        throw Exception('잘못된 이미지 URL 형식');
      }

      // workplaceId/filename 추출
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      print('Storage 삭제 시작: $filePath');

      await _supabase.storage
          .from(SupabaseConfig.contractsBucket)
          .remove([filePath]);

      print('Storage 삭제 완료');
    } catch (e) {
      print('Storage 삭제 오류 (무시 가능): $e');
      // 이미지 삭제 실패는 치명적이지 않으므로 예외를 던지지 않음
    }
  }

  /// 이미지 URL에서 파일 경로 추출
  String _getFilePathFromUrl(String imageUrl) {
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;

    // URL 형식: https://{project}.supabase.co/storage/v1/object/public/contracts/{path}
    final bucketIndex = pathSegments.indexOf(SupabaseConfig.contractsBucket);

    if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
      throw Exception('잘못된 이미지 URL 형식');
    }

    return pathSegments.sublist(bucketIndex + 1).join('/');
  }

  /// 특정 사업장의 모든 근로계약서 이미지 삭제
  ///
  /// [workplaceId]: 사업장 ID
  Future<void> deleteAllContractImages(String workplaceId) async {
    try {
      print('사업장 $workplaceId의 모든 이미지 삭제 시작');

      // 해당 사업장 폴더의 모든 파일 조회
      final files = await _supabase.storage
          .from(SupabaseConfig.contractsBucket)
          .list(path: workplaceId);

      if (files.isEmpty) {
        print('삭제할 파일 없음');
        return;
      }

      // 파일 경로 리스트 생성
      final filePaths = files
          .map((file) => '$workplaceId/${file.name}')
          .toList();

      print('삭제할 파일 수: ${filePaths.length}');

      // 일괄 삭제
      await _supabase.storage
          .from(SupabaseConfig.contractsBucket)
          .remove(filePaths);

      print('모든 이미지 삭제 완료');
    } catch (e) {
      print('일괄 이미지 삭제 오류 (무시 가능): $e');
    }
  }

  /// 이미지 URL이 유효한지 확인
  bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.pathSegments.contains(SupabaseConfig.contractsBucket);
    } catch (e) {
      return false;
    }
  }
}