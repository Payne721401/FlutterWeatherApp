import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:developer';

class RadarImageService {
  // --- Cache variables ---
  List<String>? _cachedRadarImageUrls;
  List<Uint8List?>? _cachedRadarImages;
  DateTime? _lastFetchTimeRadar;

  List<String>? _cachedQpfImageUrls; // Though QPF URLs are static, let's treat images similarly
  List<Uint8List?>? _cachedQpfImages;
  DateTime? _lastFetchTimeQpf;

  final Duration _cacheDuration = const Duration(minutes: 10);

  // --- Radar Image Fetching Logic ---
  Future<List<String>> fetchRadarImageUrls({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedRadarImageUrls != null &&
        _lastFetchTimeRadar != null &&
        now.difference(_lastFetchTimeRadar!) < _cacheDuration) {
      log("[RadarService] Using cached radar image URLs.");
      return _cachedRadarImageUrls!;
    }

    log("[RadarService] Fetching new radar image URLs from CWA.");
    final nowUtc = DateTime.now().toUtc();
    final nowUtcPlus8 = nowUtc.add(const Duration(hours: 8));

    List<String> urls = [];
    final DateFormat formatter = DateFormat('yyyyMMddHHmm');

    final roundedDownMinute = nowUtcPlus8.minute - (nowUtcPlus8.minute % 10);
    DateTime latestTimestampUtcPlus8 = DateTime(
        nowUtcPlus8.year, nowUtcPlus8.month, nowUtcPlus8.day,
        nowUtcPlus8.hour, roundedDownMinute);
    DateTime latestAvailableTimestampUtcPlus8 = latestTimestampUtcPlus8.subtract(const Duration(minutes: 10));
    DateTime currentTimestampUtcPlus8 = latestAvailableTimestampUtcPlus8.subtract(const Duration(minutes: 50));

    for (int i = 0; i < 6; i++) {
      final formattedTime = formatter.format(currentTimestampUtcPlus8);
      final url = "https://www.cwa.gov.tw/Data/radar/CV1_3600_${formattedTime}.png";
      urls.add(url);
      currentTimestampUtcPlus8 = currentTimestampUtcPlus8.add(const Duration(minutes: 10));
    }

    _cachedRadarImageUrls = urls;
    _lastFetchTimeRadar = now; // Update timestamp after fetching URLs
    _cachedRadarImages = null; // Invalidate image cache when URLs are new

    log("[RadarService] Generated radar image URLs: ${urls.join(', ')}");
    return urls;
  }

  Future<List<Uint8List?>> loadRadarImages(List<String> radarImageUrls, {bool forceRefresh = false}) async {
     final now = DateTime.now();
    if (!forceRefresh &&
        _cachedRadarImages != null &&
        _lastFetchTimeRadar != null && // Use the same timestamp as URLs
        now.difference(_lastFetchTimeRadar!) < _cacheDuration) {
      log("[RadarService] Using cached radar images.");
      return _cachedRadarImages!;
    }
    log("[RadarService] Loading new radar images from network.");

    List<Uint8List?> loadedBytes = [];

    for (String url in radarImageUrls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final Uint8List bytes = response.bodyBytes;
          if (bytes.isNotEmpty) {
            loadedBytes.add(bytes);
            
            // --- 新增這些除錯資訊 ---
            log("[RadarService] Image size: ${bytes.length} bytes");
            log("[RadarService] First 10 bytes: ${bytes.take(10).toList()}");
            
            // 檢查是否為有效的 PNG 檔案
            if (bytes.length >= 8) {
              final pngHeader = [137, 80, 78, 71, 13, 10, 26, 10]; // PNG 檔頭
              final actualHeader = bytes.take(8).toList();
              final isPng = actualHeader.toString() == pngHeader.toString();
              log("[RadarService] Is valid PNG: $isPng");
              log("[RadarService] Actual header: $actualHeader");

              // 檢查PNG的IHDR chunk來獲取圖片信息
              // PNG結構：8字節PNG簽名 + 4字節chunk長度 + 4字節"IHDR" + IHDR數據
              if (bytes.length >= 25) { // Adjusted from 24 to 25 to safely access bytes[24]
                final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
                final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
                final bitDepth = bytes[24];
                final colorType = bytes[25];
                
                log("[RadarService] PNG Info - Width: $width, Height: $height, BitDepth: $bitDepth, ColorType: $colorType");
                
                // ColorType: 0=灰階, 2=RGB, 3=調色盤, 4=灰階+Alpha, 6=RGB+Alpha
                if (colorType == 3) {
                  log("[RadarService] Warning: Image uses palette (indexed color) - may need special handling");
                }
              }
            }
            
            log("[RadarService] Successfully loaded radar image: $url");

          } else {
            log("[RadarService] Warning: Empty image data received for $url");
            loadedBytes.add(null);
          }
        } else {
          log("[RadarService] Error loading radar image $url: Status code ${response.statusCode}.");
          loadedBytes.add(null);
        }
      } catch (e) {
        log("[RadarService] Exception loading radar image $url: $e");
        loadedBytes.add(null);
      }
    }
    _cachedRadarImages = loadedBytes;
    if (forceRefresh || _lastFetchTimeRadar == null || now.difference(_lastFetchTimeRadar!) >= _cacheDuration) {
        _lastFetchTimeRadar = now;
    }
    log("[RadarService] Finished attempting to load radar images. Loaded ${loadedBytes.where((b) => b != null).length} out of ${loadedBytes.length} images.");
    return loadedBytes;
  }

   String getFrameTimestampLabel(int frameIndex, List<String> radarImageUrls) {
       if (radarImageUrls.isEmpty || frameIndex < 0 || frameIndex >= radarImageUrls.length) {
           return "---";
       }
       try {
           String url = radarImageUrls[frameIndex];
           // Extract the timestamp string (YYYYMMDDHHmm)
           String timeStr = url.substring(url.length - 16, url.length - 4);

           // Manually parse the components to avoid potential DateFormat.parse issues
           int year = int.parse(timeStr.substring(0, 4));
           int month = int.parse(timeStr.substring(4, 6));
           int day = int.parse(timeStr.substring(6, 8));
           int hour = int.parse(timeStr.substring(8, 10));
           int minute = int.parse(timeStr.substring(10, 12));

           DateTime dt = DateTime(year, month, day, hour, minute);
           return DateFormat('HH:mm').format(dt);
       } catch (e) {
           log("[RadarService] Error formatting timestamp for frame $frameIndex (URL: ${radarImageUrls[frameIndex]}): $e");
           return "Error";
       }
   }

  final List<String> _staticQpfImageUrls = const [
    'https://cwaopendata.s3.ap-northeast-1.amazonaws.com/Forecast/F-C0035-015.png', // 0-12h
    'https://cwaopendata.s3.ap-northeast-1.amazonaws.com/Forecast/F-C0035-017.png', // 12-24h
    'https://cwaopendata.s3.ap-northeast-1.amazonaws.com/Forecast/F-C0035-023.png', // 24-36h (Corrected from 024)
    'https://cwaopendata.s3.ap-northeast-1.amazonaws.com/Forecast/F-C0035-024.png'  // 36-48h
  ];

  List<String> getQpfImageUrls() => _staticQpfImageUrls;

  Future<List<Uint8List?>> loadQpfImages({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedQpfImages != null &&
        _lastFetchTimeQpf != null &&
        now.difference(_lastFetchTimeQpf!) < _cacheDuration) {
      log("[RadarService] Using cached QPF images.");
      return _cachedQpfImages!;
    }
    log("[RadarService] Loading new QPF images from network.");

    List<Uint8List?> loadedBytes = [];
    for (String url in _staticQpfImageUrls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          loadedBytes.add(response.bodyBytes);
          log("[RadarService] Successfully loaded QPF image: $url");
        } else {
          log("[RadarService] Error loading QPF image $url: Status code ${response.statusCode}");
          loadedBytes.add(null);
        }
      }
      catch (e) {
        log("[RadarService] Exception loading QPF image $url: $e");
        loadedBytes.add(null);
      }
    }
    _cachedQpfImages = loadedBytes;
    _lastFetchTimeQpf = now;
    log("[RadarService] Finished attempting to load QPF images. Loaded ${loadedBytes.where((b) => b != null).length} out of ${loadedBytes.length} images.");
    return loadedBytes;
  }

  Future<Uint8List> loadEnsembleImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        log('Error loading ensemble image $url: Status code ${response.statusCode}', name: 'RadarImageService');
        throw Exception('Failed to load ensemble image: status code ${response.statusCode}');
      }
    } catch (e) {
      log('Exception loading ensemble image $url: $e', name: 'RadarImageService');
      rethrow;
    }
  }

  String getQpfLabel(int index) {
    switch(index) {
      case 0: return "未來 0-12 小時降水預報";
      case 1: return "未來 12-24 小時降水預報";
      case 2: return "未來 24-36 小時降水預報";
      case 3: return "未來 36-48 小時降水預報";
      default: return "定量降水預報";
    }
  }
}
