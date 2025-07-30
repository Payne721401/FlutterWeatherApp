import 'package:flutter/material.dart';
import '../../data/models/location_data.dart';
import '../../domain/usecases/get_saved_locations_usecase.dart';
import '../../domain/usecases/save_location_usecase.dart';
import '../../domain/usecases/remove_location_usecase.dart';
import '../../../../utils/taiwan_township_coordinates.dart';
import '../../domain/usecases/get_recent_searches_usecase.dart';
import '../../domain/usecases/save_recent_search_usecase.dart';

class LocationSearchState extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  final GetSavedLocationsUseCase _getSavedLocationsUseCase;
  final SaveLocationUseCase _saveLocationUseCase;
  final RemoveLocationUseCase _removeLocationUseCase;
  final GetRecentSearchesUseCase _getRecentSearchesUseCase;
  final SaveRecentSearchUseCase _saveRecentSearchUseCase;

  List<LocationData> _filteredLocations = [];
  List<LocationData> _savedLocations = [];
  List<LocationData> _recentSearches = [];

  LocationSearchState({
    required GetSavedLocationsUseCase getSavedLocationsUseCase,
    required SaveLocationUseCase saveLocationUseCase,
    required RemoveLocationUseCase removeLocationUseCase,
    required GetRecentSearchesUseCase getRecentSearchesUseCase,
    required SaveRecentSearchUseCase saveRecentSearchUseCase,
  })  : _getSavedLocationsUseCase = getSavedLocationsUseCase,
        _saveLocationUseCase = saveLocationUseCase,
        _removeLocationUseCase = removeLocationUseCase,
        _getRecentSearchesUseCase = getRecentSearchesUseCase,
        _saveRecentSearchUseCase = saveRecentSearchUseCase {
    searchController.addListener(_onSearchChanged);
    loadSavedLocations();
    loadRecentSearches();
  }

  // --- Getters ---
  List<LocationData> get filteredLocations => _filteredLocations;
  List<LocationData> get savedLocations => _savedLocations;
  List<LocationData> get recentSearches => _recentSearches;

  bool isLocationSaved(LocationData location) {
    return _savedLocations.any((saved) => saved.name == location.name);
  }

  LocationData? getLocationDataByName(String? name) {
    if (name == null) return null;
    try {
      // First, try to find in saved locations for full data
      final savedLocation = _savedLocations.firstWhere((loc) => loc.name == name);
      return savedLocation;
    } catch (e) {
      // If not in saved, try to find in recent searches
      try {
        final recentLocation = _recentSearches.firstWhere((loc) => loc.name == name);
        return recentLocation;
      } catch (e) {
        // If not found anywhere, create a new one from all coordinates
        final coords = TaiwanTownshipCoordinate[name.replaceAll(' ', '')];
        if (coords != null) {
          return LocationData(name: name, latitude: coords['latitude'], longitude: coords['longitude']);
        }
        return null;
      }
    }
  }

  // --- Public Methods for Managing Saved Locations ---
  Future<void> loadSavedLocations() async {
    final saved = await _getSavedLocationsUseCase();
    _savedLocations = saved.map((loc) {
      if (loc.latitude == null || loc.longitude == null) {
        final coords = TaiwanTownshipCoordinate[loc.name.replaceAll(' ', '')];
        return LocationData(
          name: loc.name,
          latitude: coords?['latitude'],
          longitude: coords?['longitude'],
        );
      }
      return loc;
    }).toList();
    notifyListeners();
  }

  Future<void> saveNewLocation(LocationData location) async {
    if (!isLocationSaved(location)) {
      LocationData locationToSave = location;
      if (location.latitude == null || location.longitude == null) {
        final coords = TaiwanTownshipCoordinate[location.name.replaceAll(' ', '')];
        locationToSave = LocationData(
            name: location.name,
            latitude: coords?['latitude'],
            longitude: coords?['longitude']);
      }
      _savedLocations.add(locationToSave);
      await _saveLocationUseCase(locationToSave);
      notifyListeners();
    }
  }

  Future<void> removeSavedLocation(LocationData location) async {
    _savedLocations.removeWhere((l) => l.name == location.name);
    await _removeLocationUseCase(location.name);
    notifyListeners();
  }
  
  // --- Methods for Recent Searches ---
  Future<void> loadRecentSearches() async {
    _recentSearches = await _getRecentSearchesUseCase();
    notifyListeners();
  }

  Future<void> addRecentSearch(LocationData location) async {
    await _saveRecentSearchUseCase(location);
    // Optimistic update
    _recentSearches.removeWhere((l) => l.name == location.name);
    _recentSearches.insert(0, location);
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }
    notifyListeners();
  }


  // --- Public Methods for Searching ---
  void searchLocations(String query) {
    if (query.isEmpty) {
      _filteredLocations = [];
    } else {
      // MODIFICATION: Normalize query and location names for better matching.
      final normalizedQuery = query.toLowerCase().replaceAll('台', '臺');
      
      _filteredLocations = _allLocations
          .where((locationName) {
            final normalizedLocation = locationName.toLowerCase().replaceAll('台', '臺');
            return normalizedLocation.contains(normalizedQuery);
          })
          .map((name) {
            final coords = TaiwanTownshipCoordinate[name.replaceAll(' ', '')];
            return LocationData(
              name: name,
              latitude: coords?['latitude'],
              longitude: coords?['longitude'],
            );
          })
          .toList();
    }
    notifyListeners();
  }
  
  void clearFilteredLocations() {
    _filteredLocations = [];
    notifyListeners();
  }

  // --- Private Methods & Lifecycle ---
  void _onSearchChanged() {
    searchLocations(searchController.text);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  // --- Static Data ---
  // FIX: Removed duplicate entries from the list.
  final List<String> _allLocations = const [
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
    '雲林縣 麥寮鄉', '雲林縣 東勢鄉', '雲林縣 褒忠鄉', '雲林縣 臺西鄉', '雲林縣 崙背鄉', '雲林縣 莿桐鄉',
    '雲林縣 林內鄉', '雲林縣 古坑鄉', '雲林縣 大埤鄉', '雲林縣 元長鄉', '雲林縣 四湖鄉', '雲林縣 口湖鄉', 
    '雲林縣 水林鄉',
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
}
