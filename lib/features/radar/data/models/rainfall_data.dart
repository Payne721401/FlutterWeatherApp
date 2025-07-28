import 'package:flutter/foundation.dart';

/// 雨量等級的列舉 (Enum)
/// 用於標準化雨量狀態，方便在程式中傳遞與判斷。
enum RainfallLevel {
  noRain,       // 無雨
  lightRain,    // 小雨
  moderateRain, // 中雨
  heavyRain,    // 大雨
  torrentialRain, // 暴雨
  unknown,      // 未知狀態 (資料載入中或錯誤)
}

/// 從 R2 下載的 JSON 資料的 Dart 物件模型。
class RainfallData {
  /// 包含了網格定義的元數據 (起始經緯度、解析度等)。
  final Map<String, dynamic> metadata;
  
  /// 包含所有網格點雨量值的一維陣列。
  final List<double> rainfallGrid;

  RainfallData({required this.metadata, required this.rainfallGrid});

  /// 一個工廠建構函式 (Factory Constructor)，用於從解析後的 JSON (Map) 建立 RainfallData 物件。
  /// 這樣可以將解析邏輯封裝在此模型中。
  factory RainfallData.fromJson(Map<String, dynamic> json) {
    // 從 JSON 的 'rainfall_grid' 欄位讀取資料，
    // 並安全地將 List<dynamic> 轉換為 List<double>。
    final grid = (json['rainfall_grid'] as List<dynamic>)
        .map((value) => (value as num).toDouble())
        .toList();
    
    return RainfallData(
      metadata: json['metadata'],
      rainfallGrid: grid,
    );
  }
}
