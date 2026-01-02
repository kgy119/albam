import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/minimum_wage_model.dart';
import '../config/supabase_config.dart';

class MinimumWageService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 캐시된 최저시급 데이터
  final RxMap<int, int> _wageCache = <int, int>{}.obs;

  // 기본값 (Supabase 연결 실패 시)
  static const int defaultWage2025 = 10030;
  static const int defaultWage2026 = 10320;

  Future<MinimumWageService> init() async {
    await loadMinimumWages();
    return this;
  }

  /// Supabase에서 모든 최저시급 데이터 로드
  Future<void> loadMinimumWages() async {
    try {
      print('최저시급 데이터 로드 시작');

      final response = await _supabase
          .from(SupabaseConfig.minimumWagesTable)
          .select()
          .order('year', ascending: true);

      _wageCache.clear();

      for (var json in response as List) {
        final wageData = MinimumWageModel.fromJson(json as Map<String, dynamic>);
        _wageCache[wageData.year] = wageData.wage;
      }

      print('최저시급 데이터 로드 완료: ${_wageCache.length}개');
      print('로드된 데이터: $_wageCache');
    } catch (e) {
      print('최저시급 데이터 로드 실패: $e');
      // 기본값으로 초기화
      _initializeDefaultWages();
    }
  }

  /// 기본값으로 초기화
  void _initializeDefaultWages() {
    _wageCache[2025] = defaultWage2025;
    _wageCache[2026] = defaultWage2026;
    print('기본 최저시급 데이터 설정: $_wageCache');
  }

  /// 현재 날짜 기준 최저시급 반환
  int getCurrentMinimumWage() {
    final now = DateTime.now();
    return getMinimumWageByYear(now.year);
  }

  /// 연도별 최저시급 조회
  int getMinimumWageByYear(int year) {
    // 캐시에서 조회
    if (_wageCache.containsKey(year)) {
      return _wageCache[year]!;
    }

    // 캐시에 없으면 가장 최근 연도의 시급 반환
    if (_wageCache.isEmpty) {
      _initializeDefaultWages();
    }

    // 요청한 연도보다 작거나 같은 가장 최근 연도 찾기
    int? closestYear;
    for (var cacheYear in _wageCache.keys) {
      if (cacheYear <= year) {
        if (closestYear == null || cacheYear > closestYear) {
          closestYear = cacheYear;
        }
      }
    }

    return closestYear != null ? _wageCache[closestYear]! : defaultWage2026;
  }

  /// 특정 날짜의 최저시급 조회
  int getMinimumWageByDate(DateTime date) {
    return getMinimumWageByYear(date.year);
  }

  /// 관리자용: 최저시급 추가/업데이트
  Future<void> updateMinimumWage({
    required int year,
    required int wage,
    required DateTime effectiveDate,
  }) async {
    try {
      print('최저시급 업데이트 시작: $year년 - $wage원');

      final wageData = MinimumWageModel(
        year: year,
        wage: wage,
        effectiveDate: effectiveDate,
      );

      // upsert: 있으면 업데이트, 없으면 삽입
      await _supabase
          .from(SupabaseConfig.minimumWagesTable)
          .upsert(wageData.toJson());

      // 캐시 업데이트
      _wageCache[year] = wage;

      print('최저시급 업데이트 완료: $year년 - $wage원');
    } catch (e) {
      print('최저시급 업데이트 실패: $e');
      throw Exception('최저시급 업데이트 실패');
    }
  }

  /// 모든 최저시급 데이터 조회 (관리자용)
  Future<List<MinimumWageModel>> getAllMinimumWages() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.minimumWagesTable)
          .select()
          .order('year', ascending: false);

      return (response as List)
          .map((json) => MinimumWageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('전체 최저시급 조회 오류: $e');
      return [];
    }
  }
}