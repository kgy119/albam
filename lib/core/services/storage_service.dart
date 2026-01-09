import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 근로계약서 이미지 업로드
  Future<String> uploadContractImage({
    required String workplaceId,
    required File imageFile,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${timestamp}_contract.$fileExtension';
      final filePath = '$workplaceId/$fileName';

      print('📤 Storage 업로드 시작: $filePath');

      if (!await imageFile.exists()) {
        throw Exception('파일이 존재하지 않습니다');
      }

      final fileBytes = await imageFile.readAsBytes();
      print('📦 파일 크기: ${fileBytes.length} bytes');

      await _supabase.storage
          .from(SupabaseConfig.contractsBucket)
          .uploadBinary(
        filePath,
        fileBytes,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: true,
          contentType: 'image/$fileExtension',
        ),
      );

      print('✅ Storage 업로드 완료');

      // ✅ Signed URL 생성 (7일 유효)
      final signedUrl = await _supabase.storage
          .from(SupabaseConfig.contractsBucket)
          .createSignedUrl(filePath, 60 * 60 * 24 * 7); // 7일

      print('🔗 생성된 Signed URL: $signedUrl');

      return signedUrl;
    } catch (e) {
      print('❌ Storage 업로드 오류: $e');
      throw Exception('이미지 업로드 실패: $e');
    }
  }

  /// 저장된 이미지 URL을 새로운 Signed URL로 변환
  Future<String> getSignedImageUrl(String imageUrl) async {
    try {
      // 이미 signed URL인지 확인 (token 파라미터가 있는지)
      if (imageUrl.contains('token=')) {
        // signed URL에서 파일 경로 추출
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;

        // .../object/sign/contracts/...에서 contracts 이후 경로 추출
        int signIndex = pathSegments.indexOf('sign');
        if (signIndex != -1 && signIndex < pathSegments.length - 1) {
          final bucketIndex = signIndex + 1;
          if (pathSegments[bucketIndex] == SupabaseConfig.contractsBucket) {
            final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

            // 새로운 Signed URL 생성
            final newSignedUrl = await _supabase.storage
                .from(SupabaseConfig.contractsBucket)
                .createSignedUrl(filePath, 60 * 60 * 24 * 7);

            print('🔄 Signed URL 갱신: $newSignedUrl');
            return newSignedUrl;
          }
        }
      } else {
        // public URL 형식인 경우
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;

        final bucketIndex = pathSegments.indexOf(SupabaseConfig.contractsBucket);
        if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
          throw Exception('잘못된 이미지 URL 형식');
        }

        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

        // Signed URL 생성
        final signedUrl = await _supabase.storage
            .from(SupabaseConfig.contractsBucket)
            .createSignedUrl(filePath, 60 * 60 * 24 * 7);

        print('🔗 Signed URL 생성: $signedUrl');
        return signedUrl;
      }

      return imageUrl;
    } catch (e) {
      print('⚠️ Signed URL 생성 오류: $e');
      return imageUrl; // 실패하면 원본 URL 반환
    }
  }

  /// 근로계약서 이미지 삭제
  Future<void> deleteContractImage(String imageUrl) async {
    try {
      // URL에서 파일 경로 추출
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      String filePath;

      // signed URL 형식 확인
      if (imageUrl.contains('token=')) {
        int signIndex = pathSegments.indexOf('sign');
        if (signIndex != -1 && signIndex < pathSegments.length - 1) {
          final bucketIndex = signIndex + 1;
          if (pathSegments[bucketIndex] == SupabaseConfig.contractsBucket) {
            filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          } else {
            throw Exception('잘못된 이미지 URL 형식');
          }
        } else {
          throw Exception('잘못된 이미지 URL 형식');
        }
      } else {
        // public URL 형식
        final bucketIndex = pathSegments.indexOf(SupabaseConfig.contractsBucket);
        if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
          throw Exception('잘못된 이미지 URL 형식');
        }
        filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      }

      print('🗑️ Storage 삭제 시작: $filePath');

      await _supabase.storage
          .from(SupabaseConfig.contractsBucket)
          .remove([filePath]);

      print('✅ Storage 삭제 완료');
    } catch (e) {
      print('⚠️ Storage 삭제 오류 (무시 가능): $e');
    }
  }

  /// 특정 사업장의 모든 근로계약서 이미지 삭제
  Future<void> deleteAllContractImages(String workplaceId) async {
    try {
      print('🗑️ 사업장 $workplaceId의 모든 이미지 삭제 시작');

      final files = await _supabase.storage
          .from(SupabaseConfig.contractsBucket)
          .list(path: workplaceId);

      if (files.isEmpty) {
        print('ℹ️ 삭제할 파일 없음');
        return;
      }

      final filePaths = files
          .map((file) => '$workplaceId/${file.name}')
          .toList();

      print('🗑️ 삭제할 파일 수: ${filePaths.length}');

      await _supabase.storage
          .from(SupabaseConfig.contractsBucket)
          .remove(filePaths);

      print('✅ 모든 이미지 삭제 완료');
    } catch (e) {
      print('⚠️ 일괄 이미지 삭제 오류 (무시 가능): $e');
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