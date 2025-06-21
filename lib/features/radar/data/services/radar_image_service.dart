import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
      // print("Using cached radar image URLs");
      return _cachedRadarImageUrls!;
    }

    // print("Fetching new radar image URLs");
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

    return urls;
  }

  Future<List<Uint8List?>> loadRadarImages(List<String> radarImageUrls, {bool forceRefresh = false}) async {
     final now = DateTime.now();
    // Check cache only if URLs haven't changed (which would invalidate _cachedRadarImages)
    // and forceRefresh is false
    if (!forceRefresh &&
        _cachedRadarImages != null &&
        _lastFetchTimeRadar != null && // Use the same timestamp as URLs
        now.difference(_lastFetchTimeRadar!) < _cacheDuration) {
      // print("Using cached radar images");
      return _cachedRadarImages!;
    }
    // print("Loading new radar images from network");

    List<Uint8List?> loadedBytes = [];
    for (String url in radarImageUrls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final Uint8List bytes = response.bodyBytes;
          if (bytes.isNotEmpty) {
            loadedBytes.add(bytes);
          } else {
            // print("Warning: Empty image data received for $url");
            loadedBytes.add(null);
          }
        } else {
          // print("Error loading radar image $url: Status code ${response.statusCode}. Check if UTC+8 URL is valid.");
          loadedBytes.add(null);
        }
      } catch (e) {
        // print("Error loading radar image $url: $e");
        loadedBytes.add(null);
      }
    }
    _cachedRadarImages = loadedBytes;
    // _lastFetchTimeRadar is already updated when URLs were fetched,
    // or should be updated here if we decide to cache images independently of URLs
    // For simplicity, we tie image cache validity to URL cache validity.
    // If URLs are new, images are always re-fetched.
    if (forceRefresh || _lastFetchTimeRadar == null || now.difference(_lastFetchTimeRadar!) >= _cacheDuration) {
        _lastFetchTimeRadar = now;
    }

    return loadedBytes;
  }

  // --- Timestamp Label Logic (Unchanged for now but uses URLs that might be cached) ---
   String getFrameTimestampLabel(int frameIndex, List<String> radarImageUrls) {
       // This method now implicitly benefits from cached URLs if fetchRadarImageUrls was called without forceRefresh
       if (radarImageUrls.isEmpty || frameIndex < 0 || frameIndex >= radarImageUrls.length) {
           return "---";
       }
       try {
           String url = radarImageUrls[frameIndex];
           String timeStr = url.substring(url.length - 16, url.length - 4);
           DateTime dt = DateFormat('yyyyMMddHHmm').parse(timeStr);
           return DateFormat('HH:mm').format(dt);
       } catch (e) {
           // print("Error formatting timestamp for frame $frameIndex (timeStr: ${radarImageUrls[frameIndex].substring(radarImageUrls[frameIndex].length - 16, radarImageUrls[frameIndex].length - 4)}): $e");
           return "Error";
       }
   }

  // --- QPF URL and Image Loading with Cache ---
  final List<String> _staticQpfImageUrls = const [ // Renamed to avoid confusion
    'https://cwaopendata.s3.ap-northeast-1.amazonaws.com/Forecast/F-C0035-015.png', // 0-12h
    'https://cwaopendata.s3.ap-northeast-1.amazonaws.com/Forecast/F-C0035-017.png', // 12-24h
    'https://cwaopendata.s3.ap-northeast-1.amazonaws.com/Forecast/F-C0035-024.png', // 24-36h // Assuming this is correct
    'https://cwaopendata.s3.ap-northeast-1.amazonaws.com/Forecast/F-C0035-024.png'  // 36-48h - Assuming this is correct
  ];

  List<String> getQpfImageUrls() => _staticQpfImageUrls; // Public getter for static URLs

  Future<List<Uint8List?>> loadQpfImages({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedQpfImages != null &&
        _lastFetchTimeQpf != null &&
        now.difference(_lastFetchTimeQpf!) < _cacheDuration) {
      // print("Using cached QPF images");
      return _cachedQpfImages!;
    }
    // print("Loading new QPF images from network");

    List<Uint8List?> loadedBytes = [];
    for (String url in _staticQpfImageUrls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          loadedBytes.add(response.bodyBytes);
        } else {
          // print("Error loading QPF image $url: Status code ${response.statusCode}");
          loadedBytes.add(null);
        }
      } catch (e) {
        // print("Error loading QPF image $url: $e");
        loadedBytes.add(null);
      }
    }
    _cachedQpfImages = loadedBytes;
    _lastFetchTimeQpf = now;
    return loadedBytes;
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
