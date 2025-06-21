import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Used in placeholder data and for date formatting
import 'dart:async'; // Import for Timer
import '../../data/models/weather_data.dart';
import '../../../../services/location_service.dart'; // Corrected import path
import '../../data/services/alert_service.dart'; // Import AlertService
import '../../domain/repositories/weather_repository.dart'; // Import WeatherRepository
import '../../../../services/firestore_service.dart'; // Import CacheType and FirestoreService

class WeatherState extends ChangeNotifier {
  String _currentLocation = ''; // Default to empty string
  WeatherInfo? _currentWeatherInfo;
  List<WeatherAlert> _alerts = [];
  bool _isLoading = false;
  List<String> _suggestions = [];
  final TextEditingController searchController = TextEditingController();

  // New state variables for administrative division and update time
  String? _administrativeDivision;
  DateTime? _administrativeDivisionLastUpdated;
  Timer? _locationUpdateTimer;
  Timer? _alertUpdateTimer; // Timer for alerts

  // --- Placeholder data for location suggestions ---
  final List<String> _allLocations = [
    '臺北市 中正區', '臺北市 大同區', '臺北市 中山區', '臺北市 松山區', '臺北市 大安區', '臺北市 萬華區',
    '臺北市 信義區', '臺北市 士林區', '臺北市 北投區', '臺北市 內湖區', '臺北市 南港區', '臺北市 文山區',
    '新北市 萬里區', '新北市 金山區', '新北市 板橋區', '新北市 汐止區', '新北市 深坑區', '新北市 石碇區',
    '新北市 瑞芳區', '新北市 平溪區', '新北市 雙溪區', '新北市 貢寮區', '新北市 新店區', '新北市 坪林區',
    '新北市 烏來區', '新北市 永和區', '新北市 中和區', '新北市 土城區', '新北市 三峽區', '新北市 樹林區',
    '新北市 鶯歌區', '新北市 三重區', '新北市 新莊區', '新北市 泰山區', '新北市 林口區', '新北市 蘆洲區',
    '新北市 五股區', '新北市 八里區', '新北市 淡水區', '新北市 三芝區', '新北市 石門區',
    '桃園市 中壢區', '桃園市 平鎮區', '桃園市 龍潭區', '桃園市 楊梅區', '桃園市 新屋區', '桃園市 觀音區',
    '桃園市 桃園區', '桃園市 龜山區', '桃園市 八德區', '桃園市 大溪區', '桃園市 復興區', '桃園市 大園區',
    '桃園市 蘆竹區',
    '臺中市 中區', '臺中市 東區', '臺中市 南區', '臺中市 西區', '臺中市 北區', '臺中市 西屯區',
    '臺中市 南屯區', '臺中市 北屯區', '臺中市 豐原區', '臺中市 東勢區', '臺中市 大甲區', '臺中市 清水區',
    '臺中市 沙鹿區', '臺中市 梧棲區', '臺中市 后里區', '臺中市 神岡區', '臺中市 大雅區', '臺中市 潭子區',
    '臺中市 大肚區', '臺中市 龍井區', '臺中市 烏日區', '臺中市 霧峰區', '臺中市 太平區', '臺中市 大里區',
    '臺中市 和平區', '臺中市 石岡區', '臺中市 新社區', '臺中市 外埔區', '臺中市 大安區',
    '臺南市 中西區', '臺南市 東區', '臺南市 南區', '臺南市 北區', '臺南市 安平區', '臺南市 安南區',
    '臺南市 永康區', '臺南市 歸仁區', '臺南市 新化區', '臺南市 左鎮區', '臺南市 玉井區', '臺南市 楠西區',
    '臺南市 南化區', '臺南市 仁德區', '臺南市 關廟區', '臺南市 龍崎區', '臺南市 官田區', '臺南市 麻豆區',
    '臺南市 佳里區', '臺南市 西港區', '臺南市 七股區', '臺南市 將軍區', '臺南市 學甲區', '臺南市 北門區',
    '臺南市 新營區', '臺南市 後壁區', '臺南市 白河區', '臺南市 東山區', '臺南市 六甲區', '臺南市 下營區',
    '臺南市 柳營區', '臺南市 鹽水區', '臺南市 善化區', '臺南市 大內區', '臺南市 山上區', '臺南市 新市區',
    '臺南市 安定區',
    '高雄市 新興區', '高雄市 前金區', '高雄市 苓雅區', '高雄市 鹽埕區', '高雄市 鼓山區', '高雄市 旗津區',
    '高雄市 前鎮區', '高雄市 三民區', '高雄市 左營區', '高雄市 楠梓區', '高雄市 小港區', '高雄市 鳳山區',
    '高雄市 大寮區', '高雄市 鳥松區', '高雄市 林園區', '高雄市 岡山區', '高雄市 路竹區', '高雄市 阿蓮區',
    '高雄市 田寮區', '高雄市 燕巢區', '高雄市 橋頭區', '高雄市 梓官區', '高雄市 彌陀區', '高雄市 永安區',
    '高雄市 湖內區', '高雄市 大樹區', '高雄市 旗山區', '高雄市 美濃區', '高雄市 六龜區', '高雄市 甲仙區',
    '高雄市 杉林區', '高雄市 內門區', '高雄市 茂林區', '高雄市 桃源區', '高雄市 那瑪夏區',
    '基隆市 仁愛區', '基隆市 信義區', '基隆市 中正區', '基隆市 中山區', '基隆市 安樂區', '基隆市 暖暖區',
    '基隆市 七堵區',
    '新竹市 東區', '新竹市 北區', '新竹市 香山區',
    '嘉義市 東區', '嘉義市 西區',
    '新竹縣 竹北市', '新竹縣 竹東鎮', '新竹縣 新埔鎮', '新竹縣 關西鎮', '新竹縣 湖口鄉', '新竹縣 新豐鄉',
    '新竹縣 芎林鄉', '新竹縣 寶山鄉', '新竹縣 北埔鄉', '新竹縣 峨眉鄉', '新竹縣 尖石鄉', '新竹縣 五峰鄉',
    '苗栗縣 竹南鎮', '苗栗縣 頭份市', '苗栗縣 苗栗市', '苗栗縣 通霄鎮', '苗栗縣 苑裡鎮', '苗栗縣 卓蘭鎮',
    '苗栗縣 大湖鄉', '苗栗縣 公館鄉', '苗栗縣 銅鑼鄉', '苗栗縣 南庄鄉', '苗栗縣 頭屋鄉', '苗栗縣 三義鄉',
    '苗栗縣 西湖鄉', '苗栗縣 造橋鄉', '苗栗縣 三灣鄉', '苗栗縣 獅潭鄉', '苗栗縣 泰安鄉',
    '彰化縣 彰化市', '彰化縣 員林市', '彰化縣 和美鎮', '彰化縣 鹿港鎮', '彰化縣 福興鄉', '彰化縣 線西鄉',
    '彰化縣 伸港鄉', '彰化縣 秀水鄉', '彰化縣 花壇鄉', '彰化縣 芬園鄉', '彰化縣 大村鄉', '彰化縣 埔心鄉',
    '彰化縣 溪湖鎮', '彰化縣 埔鹽鄉', '彰化縣 二水鄉', '彰化縣 北斗鎮', '彰化縣 田中鎮', '彰化縣 社頭鄉',
    '彰化縣 二林鎮', '彰化縣 竹塘鄉', '彰化縣 芳苑鄉', '彰化縣 大城鄉', '彰化縣 埤頭鄉', '彰化縣 永靖鄉',
    '南投縣 南投市', '南投縣 埔里鎮', '南投縣 草屯鎮', '南投縣 竹山鎮', '南投縣 集集鎮', '南投縣 名間鄉',
    '南投縣 鹿谷鄉', '南投縣 中寮鄉', '南投縣 魚池鄉', '南投縣 國姓鄉', '南投縣 水里鄉', '南投縣 信義鄉',
    '南投縣 仁愛鄉',
    '雲林縣 斗六市', '雲林縣 斗南鎮', '雲林縣 虎尾鎮', '雲林縣 西螺鎮', '雲林縣 土庫鎮', '雲林縣 北港鎮',
    '雲林縣 麥寮鄉', '雲林縣 東勢鄉', '雲林縣 褒忠鄉', '雲林縣 臺西鄉', '雲林縣 崙背鄉', '雲林縣 刺桐鄉',
    '雲林縣 林內鄉', '雲林縣 古坑鄉', '雲林縣 大埤鄉', '雲林縣 莿桐鄉', '雲林縣 褒忠鄉', '雲林縣 元長鄉',
    '雲林縣 四湖鄉', '雲林縣 口湖鄉', '雲林縣 水林鄉',
    '嘉義縣 太保市', '嘉義縣 朴子市', '嘉義縣 布袋鎮', '嘉義縣 大林鎮', '嘉義縣 民雄鄉', '嘉義縣 溪口鄉',
    '嘉義縣 新港鄉', '嘉義縣 六腳鄉', '嘉義縣 東石鄉', '嘉義縣 義竹鄉', '嘉義縣 鹿草鄉', '嘉義縣 水上鄉',
    '嘉義縣 中埔鄉', '嘉義縣 竹崎鄉', '嘉義縣 梅山鄉', '嘉義縣 番路鄉', '嘉義縣 大埔鄉', '嘉義縣 阿里山鄉',
    '屏東縣 屏東市', '屏東縣 潮州鎮', '屏東縣 東港鎮', '屏東縣 恆春鎮', '屏東縣 萬丹鄉', '屏東縣 長治鄉',
    '屏東縣 麟洛鄉', '屏東縣 九如鄉', '屏東縣 里港鄉', '屏東縣 鹽埔鄉', '屏東縣 高樹鄉', '屏東縣 萬巒鄉',
    '屏東縣 內埔鄉', '屏東縣 竹田鄉', '屏東縣 新埤鄉', '屏東縣 枋寮鄉', '屏東縣 崁頂鄉', '屏東縣 林邊鄉',
    '屏東縣 南州鄉', '屏東縣 佳冬鄉', '屏東縣 新園鄉', '屏東縣 琉球鄉', '屏東縣 車城鄉', '屏東縣 滿州鄉',
    '屏東縣 枋山鄉', '屏東縣 三地門鄉', '屏東縣 霧臺鄉', '屏東縣 瑪家鄉', '屏東縣 泰武鄉', '屏東縣 來義鄉',
    '屏東縣 春日鄉', '屏東縣 獅子鄉', '屏東縣 牡丹鄉',
    '宜蘭縣 宜蘭市', '宜蘭縣 羅東鎮', '宜蘭縣 蘇澳鎮', '宜蘭縣 頭城鎮', '宜蘭縣 礁溪鄉', '宜蘭縣 壯圍鄉',
    '宜蘭縣 員山鄉', '宜蘭縣 冬山鄉', '宜蘭縣 五結鄉', '宜蘭縣 三星鄉', '宜蘭縣 大同鄉', '宜蘭縣 南澳鄉',
    '花蓮縣 花蓮市', '花蓮縣 鳳林鎮', '花蓮縣 玉里鎮', '花蓮縣 新城鄉', '花蓮縣 吉安鄉', '花蓮縣 壽豐鄉',
    '花蓮縣 光復鄉', '花蓮縣 豐濱鄉', '花蓮縣 瑞穗鄉', '花蓮縣 富里鄉', '花蓮縣 秀林鄉', '花蓮縣 萬榮鄉',
    '花蓮縣 卓溪鄉',
    '臺東縣 臺東市', '臺東縣 成功鎮', '臺東縣 關山鎮', '臺東縣 卑南鄉', '臺東縣 大武鄉', '臺東縣 太麻里鄉',
    '臺東縣 東河鄉', '臺東縣 長濱鄉', '臺東縣 鹿野鄉', '臺東縣 池上鄉', '臺東縣 綠島鄉', '臺東縣 延平鄉',
    '臺東縣 海端鄉', '臺東縣 達仁鄉', '臺東縣 金峰鄉', '臺東縣 蘭嶼鄉',
    '澎湖縣 馬公市', '澎湖縣 湖西鄉', '澎湖縣 白沙鄉', '澎湖縣 西嶼鄉', '澎湖縣 望安鄉', '澎湖縣 七美鄉',
    '金門縣 金城鎮', '金門縣 金湖鎮', '金門縣 金沙鎮', '金門縣 金寧鄉', '金門縣 烈嶼鄉', '金門縣 烏坵鄉',
    '連江縣 南竿鄉', '連江縣 北竿鄉', '連江縣 莒光鄉', '連江縣 東引鄉'
  ];

  // Service instances
  final LocationService _locationService = LocationService();
  final AlertService _alertService = AlertService(); // Instantiate AlertService
  final WeatherRepository _weatherRepository; // New: Declare WeatherRepository

  // --- Getters ---
  String get currentLocation => _currentLocation;
  WeatherInfo? get currentWeatherInfo => _currentWeatherInfo;
  List<WeatherAlert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  List<String> get suggestions => _suggestions;
  String? get administrativeDivision => _administrativeDivision;
  DateTime? get administrativeDivisionLastUpdated => _administrativeDivisionLastUpdated;

  // Initialize WeatherRepository in the constructor
  WeatherState() : _weatherRepository = WeatherRepositoryImpl(FirestoreService()) {
    _initialize();
  }

  void _initialize() {
    _fetchWeatherAlerts(); // Fetch initial alerts
    _startAlertUpdateTimer(); // Start the alert update timer
    _updateLocationAndAdministrativeDivision(); // Initial location fetch and real weather data from Firebase
    // Set up timer to update location every 10 minutes
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 10), (Timer t) => _updateLocationAndAdministrativeDivision());
  }

  void _startAlertUpdateTimer() {
     _alertUpdateTimer = Timer.periodic(const Duration(minutes: 10), (Timer t) {
      _fetchWeatherAlerts();
    });
  }

  // Fetch and update administrative division based on current location and Firebase weather data
  Future<void> _updateLocationAndAdministrativeDivision() async {
    try {
      final position = await _locationService.getCurrentLocation();
      final adminDivision = await _locationService.getAdministrativeDivision(position.latitude, position.longitude);

      _administrativeDivision = adminDivision; // e.g., "南投縣 中寮鄉"
      _administrativeDivisionLastUpdated = DateTime.now();
      
      if (adminDivision != null) {
        _currentLocation = adminDivision; // Set current location to GPS location on initial load
        // Convert "南投縣 中寮鄉" to "南投縣_中寮鄉" for Firebase document ID
        final firebaseLocationId = adminDivision.replaceAll(' ', '_'); 
        _currentWeatherInfo = await _weatherRepository.getWeatherDataForLocation(firebaseLocationId, type: CacheType.currentLocation);
        print("Fetched Firebase Weather Info for $firebaseLocationId: $_currentWeatherInfo");
      }

    } catch (e) {
      // Handle errors (e.g., permissions denied)
      print('Error updating location and administrative division: $e');
      _administrativeDivision = '無法取得地點資訊';
      _administrativeDivisionLastUpdated = null;
      _currentWeatherInfo = null; // Clear weather info on error
      _currentLocation = '無法取得地點資訊'; // Set current location to error state
    }
    notifyListeners(); // Notify listeners after updating location info and weather forecast
  }

  // --- Data Fetching and State Updates ---

  Future<void> fetchWeatherData(String location, {bool isInitialLoad = false}) async {
    // _currentLocation is already updated by handleSuggestionTap or _updateLocationAndAdministrativeDivision
    if (!isInitialLoad) {
      _isLoading = true;
      notifyListeners();
    }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // --- Generate Comprehensive Placeholder Data (from original HomeScreen) ---
    // 這個方法目前仍使用模擬數據來填充 _currentWeatherInfo。
    // 鑑於 handleSuggestionTap 將直接從 Firebase 獲取數據，
    // 您可以選擇在這裡調用 WeatherRepository 來獲取真實數據，
    // 特別是當用戶從搜尋欄選擇一個地點時 (即 `location` 參數是搜尋結果)。
    //
    // 如果從 Firebase 沒有獲取到數據，則可以保留原有的模擬數據邏輯作為備用。
    // 或者，您可以直接將 _currentWeatherInfo 設為 null 或一個錯誤狀態，具體取決於 UI 處理方式。
    
    // For now, keeping the placeholder data generation as requested.
    // If you uncomment the Firebase fetch logic in handleSuggestionTap,
    // and want to remove placeholder data from here, you must ensure
    // that either _updateLocationAndAdministrativeDivision covers the initial load
    // or you directly handle the case where firebaseLocationId might not yield data.

    // final firebaseLocationId = location.replaceAll(' ', '_');
    // final fetchedWeatherInfo = await _weatherRepository.getWeatherDataForLocation(firebaseLocationId, type: CacheType.searchResult);
    // if (fetchedWeatherInfo != null) {
    //   _currentWeatherInfo = fetchedWeatherInfo;
    //   print("Fetched Weather Info for search location $location: $_currentWeatherInfo");
    // } else {
    //   print("No Firebase data found for search location: $location. Falling back to placeholder.");
    //   // Fallback to placeholder if Firebase data is not found for the searched location
    // }


    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    _currentWeatherInfo = WeatherInfo(
        locationName: location,
        lastUpdated: now,
        condition: '晴朗',
        iconCode: '01d', // Sunny day
        temperature: 26.0,
        feelsLike: 38.0,
        tempHigh: 32.0,
        tempLow: 24.0,
        tempYesterdayHigh: 33.0,
        tempYesterdayLow: 25.0,
        windSpeed: 4.0,
        humidity: 68,
        precipitationChance: 10,
        aqi: 42,
        aqiLevel: '良好',
        uvIndex: 5,
        uvLevel: '中等',
        clothingAdvice: '舒適',
        clothingIndexValue: 4,
        umbrellaAdvice: '良好',
        umbrellaIndexValue: 3,
        activityAdvice: '適宜',
        activityIndexValue: 5,
        aiSummary: '今天天氣溫和適中，天氣晴朗。下午可能會有些短暫陣雨，外出時可攜帶輕便雨具。空氣品質良好，適合進行戶外活動。',
        sunrise: const TimeOfDay(hour: 5, minute: 38),
        sunset: const TimeOfDay(hour: 18, minute: 42),
        hourlyForecasts: List.generate(12, (index) {
          final forecastTime = now.add(Duration(hours: index + 3));
          return HourlyForecast(
            time: forecastTime,
            iconCode: (index % 4 == 0) ? '01d' : (index % 4 == 1) ? '02d' : (index % 4 == 2) ? '03d' : '10d',
            temperature: 26.0 - index * 0.5,
            precipitationChance: (index % 4 == 3) ? 40 : 10,
          );
        }),
        dailyForecasts: List.generate(7, (index) {
          final forecastDate = today.add(Duration(days: index));
          final String dayName;
          if (index == 0) {
             dayName = '今天';
          } else if (index == 1) {
             dayName = '明天';
          } else {
             dayName = DateFormat('EEEE', 'zh_TW').format(forecastDate);
          }
          return DailyForecast(
            date: forecastDate,
            dayName: dayName,
            dayIconCode: (index % 3 == 0) ? '01d' : (index % 3 == 1) ? '04d' : '10d',
            dayPrecipitationChance: (index * 10 + 5) % 100,
            dayTempHigh: 32.0 - index * 0.8,
            dayTempLow: 22.0 - index * 0.5,
            nightIconCode: (index % 2 == 0) ? '01n' : '04n',
            nightPrecipitationChance: (index * 5 + 2) % 100,
            nightTempHigh: 25.0 - index * 0.6,
            nightTempLow: 18.0 - index * 0.4,
          );
        }),
    );
    // --- End Placeholder Data / Firebase Data Mapping ---

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchWeatherAlerts() async { // Made async
    try {
      _alerts = await _alertService.fetchAlerts(); // Use AlertService
      notifyListeners(); // Notify listeners after alerts are fetched
    } catch (e) {
      print('Error fetching weather alerts: $e');
      _alerts = []; // Clear alerts on error
      notifyListeners();
    }
  }

  void updateSuggestions(String query) {
    if (query.isEmpty) {
      _suggestions = [];
    } else {
      _suggestions = _allLocations
          .where((location) => location.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void handleSuggestionTap(String suggestion, BuildContext context) async { // Make it async
    searchController.text = suggestion;
    _isLoading = true; // Set loading to true
    notifyListeners(); // Notify to show loading state

    final firebaseLocationId = suggestion.replaceAll(' ', '_');
    _currentLocation = suggestion; // Update current location for UI display

    try {
      final fetchedData = await _weatherRepository.getWeatherDataForLocation(firebaseLocationId, type: CacheType.searchResult);
      if (fetchedData != null) {
        _currentWeatherInfo = fetchedData;
        print("Fetched Firebase Weather Info for tapped suggestion $suggestion: $_currentWeatherInfo");
      } else {
        print("No Firebase data found for tapped suggestion: $suggestion. Falling back to placeholder.");
        // If no data from Firebase, you can keep the current placeholder or set to null
        // For now, I'll call fetchWeatherData with the suggestion to generate placeholder
        // if Firebase data is not found, as per the original request's "review fetchWeatherData" step.
        await fetchWeatherData(suggestion, isInitialLoad: false); // Use placeholder generation
      }
    } catch (e) {
      print('Error fetching weather data for suggestion $suggestion: $e');
      _currentWeatherInfo = null; // Clear weather info on error
      // Optionally, show an error message to the user
    } finally {
      _isLoading = false;
      _suggestions = []; // Clear suggestions after selection
      notifyListeners(); // Notify listeners for final state update
      FocusScope.of(context).unfocus(); // Hide keyboard
    }
  }

  void clearSuggestions() {
     _suggestions = [];
     notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    _locationUpdateTimer?.cancel(); // Cancel the location timer
    _alertUpdateTimer?.cancel(); // Cancel the alert timer
    super.dispose();
  }
}
