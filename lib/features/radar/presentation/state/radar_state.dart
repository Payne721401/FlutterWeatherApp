import 'dart:async';
import 'dart:typed_data';
import 'dart:math'; // For Point
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/map_layer_type.dart';
import '../../data/models/rainfall_data.dart';
import '../../data/services/radar_image_service.dart';
import '../../data/services/radar_forecast_service.dart';
import '../../utils/rainfall_calculator.dart';
import '../../../../services/location_service.dart';

// --- CONSTANTS ---
const double radarLatMin = 17.75;
const double radarLatMax = 29.25;
const double radarLonMin = 115.00;
const double radarLonMax = 126.50;
const double radarImageWidth = 3600.0;
const double radarImageHeight = 3600.0;

class RadarState with ChangeNotifier {
  final RadarImageService _imageService = RadarImageService();
  final LocationService _locationService = LocationService();
  final RadarForecastService _forecastService;

  // --- State Variables ---
  MapLayerType _selectedView = MapLayerType.radarEcho;
  bool _isLoadingRadarImages = false;
  bool _isLoadingQpfImages = false;
  bool _isFetchingLocation = false;
  
  Position? _currentPosition;
  String? _locationError;
  String? _administrativeDivision;
  
  RainfallLevel _rainfallLevel = RainfallLevel.unknown;
  String _rainfallForecastMessage = '正在取得降雨預報...';
  
  List<Uint8List?> _radarImageBytes = [];
  List<String> _radarImageUrls = [];
  int _currentRadarFrame = 0;
  Timer? _animationTimer;
  bool _isPlaying = false;
  double _sliderValue = 0.0;
  List<Uint8List?> _qpfImageBytes = [];
  DateTime? _lastFetchTimeQpf;
  final Duration _cacheDurationQpf = const Duration(minutes: 10);
  DateTime? _lastFetchTimeRadar;
  final Duration _cacheDurationRadar = const Duration(minutes: 10);
  int _currentQpfPage = 0;
  bool _showAiAnalysis = false;
  final TransformationController _transformationController = TransformationController();
  final PageController _qpfPageController = PageController();

  // --- Getters ---
  MapLayerType get selectedView => _selectedView;
  bool get isLoadingRadarImages => _isLoadingRadarImages;
  bool get isLoadingQpfImages => _isLoadingQpfImages;
  bool get isFetchingLocation => _isFetchingLocation;
  String? get locationError => _locationError;
  String? get administrativeDivision => _administrativeDivision;
  String get rainfallForecastMessage => _rainfallForecastMessage;
  Position? get currentPosition => _currentPosition;
  List<Uint8List?> get radarImageBytes => _radarImageBytes;
  int get currentRadarFrame => _currentRadarFrame;
  bool get isPlaying => _isPlaying;
  double get sliderValue => _sliderValue;
  List<Uint8List?> get qpfImageBytes => _qpfImageBytes;
  TransformationController get transformationController => _transformationController;
  PageController get qpfPageController => _qpfPageController;
  int get currentQpfPage => _currentQpfPage;
  bool get showAiAnalysis => _showAiAnalysis;
  List<String> get qpfImageUrls => _imageService.getQpfImageUrls();
  String getQpfLabel(int index) => _imageService.getQpfLabel(index);
  String getFrameTimestampLabel(int frameIndex) => _imageService.getFrameTimestampLabel(frameIndex, _radarImageUrls);

  RadarState({required RadarForecastService forecastService})
      : _forecastService = forecastService {
    _forecastService.addListener(_updateRainfallForecast);
    _fetchRadarImagesIfNeeded();
    determinePosition();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _qpfPageController.dispose();
    _transformationController.dispose();
    _forecastService.removeListener(_updateRainfallForecast);
    super.dispose();
  }

  /// **MODIFIED**: This logic now correctly uses the service's isLoading and hasError states.
  void _updateRainfallForecast() {
    final rainfallData = _forecastService.rainfallData;
    final bool isServiceLoading = _forecastService.isLoading;
    final bool hasServiceError = _forecastService.hasError;

    if (_isFetchingLocation) {
        _rainfallForecastMessage = '正在取得您的位置...';
    } else if (_currentPosition == null) {
      _rainfallForecastMessage = '請開啟定位以取得即時降雨預報';
    } else if (isServiceLoading) {
      _rainfallForecastMessage = '正在下載雨量資料...';
    } else if (hasServiceError || rainfallData == null) {
      _rainfallForecastMessage = '無法載入雨量資料，請稍後再試';
    } else {
      _rainfallLevel = RainfallCalculator.getLevelAt(
        data: rainfallData,
        userLat: _currentPosition!.latitude,
        userLon: _currentPosition!.longitude,
      );
      
      final district = _administrativeDivision ?? '目前位置';
      _rainfallForecastMessage = '$district：${_getForecastMessageFromLevel(_rainfallLevel)}';
    }
    
    notifyListeners();
  }
  
  String _getForecastMessageFromLevel(RainfallLevel level) {
    switch (level) {
      case RainfallLevel.noRain:
        return '未來1小時內無降雨';
      case RainfallLevel.lightRain:
        return '未來1小時內有小雨';
      case RainfallLevel.moderateRain:
        return '未來1小時內有中雨';
      case RainfallLevel.heavyRain:
        return '未來1小時內有大雨';
      case RainfallLevel.torrentialRain:
        return '未來1小時內有暴雨';
      case RainfallLevel.unknown:
      default:
        return '降雨預報資料分析中...';
    }
  }

  Future<void> determinePosition() async {
    _isFetchingLocation = true;
    _locationError = null;
    _administrativeDivision = null;
    _updateRainfallForecast(); 
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();
      _currentPosition = position;
      _administrativeDivision = await _locationService.getAdministrativeDivision(
          position.latitude,
          position.longitude,
      );
      _locationError = null;
    } catch (e) {
      _locationError = '無法取得位置: $e';
      _currentPosition = null;
      _administrativeDivision = null;
    } finally {
      _isFetchingLocation = false;
      _updateRainfallForecast();
      notifyListeners();
    }
  }
  
  Future<void> _fetchRadarImagesIfNeeded({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastFetchTimeRadar != null &&
        now.difference(_lastFetchTimeRadar!) < _cacheDurationRadar &&
        _radarImageBytes.isNotEmpty &&
        _radarImageBytes.any((bytes) => bytes != null)) {
      return;
    }
    _isLoadingRadarImages = true;
    if(forceRefresh || _radarImageBytes.isEmpty || !_radarImageBytes.any((bytes) => bytes != null)){
        _radarImageBytes = [];
        _radarImageUrls = [];
        _currentRadarFrame = 0;
        _sliderValue = 0.0;
    }
    _showAiAnalysis = false;
    stopAnimation();
    notifyListeners();

    try {
      _radarImageUrls = await _imageService.fetchRadarImageUrls(forceRefresh: forceRefresh);
      if (_radarImageUrls.isNotEmpty) {
        _radarImageBytes = await _imageService.loadRadarImages(_radarImageUrls, forceRefresh: forceRefresh);
        _lastFetchTimeRadar = DateTime.now();
        int lastValidFrame = _radarImageBytes.lastIndexWhere((bytes) => bytes != null);
        if (lastValidFrame != -1) {
          _currentRadarFrame = lastValidFrame;
          _sliderValue = lastValidFrame.toDouble();
        } else {
          _currentRadarFrame = 0;
          _sliderValue = 0.0;
        }
      } else {
        _radarImageBytes = [];
        _currentRadarFrame = 0;
        _sliderValue = 0.0;
      }
    } catch (e) {
       if(forceRefresh || _radarImageBytes.isEmpty || !_radarImageBytes.any((bytes) => bytes != null)){
        _radarImageUrls = [];
        _radarImageBytes = [];
        _currentRadarFrame = 0;
        _sliderValue = 0.0;
        _lastFetchTimeRadar = null;
       }
    } finally {
      _isLoadingRadarImages = false;
      notifyListeners();
    }
  }

  Future<void> refreshRadarImages() async {
    await _fetchRadarImagesIfNeeded(forceRefresh: true);
  }

   Future<void> _fetchQpfImagesIfNeeded({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastFetchTimeQpf != null &&
        now.difference(_lastFetchTimeQpf!) < _cacheDurationQpf &&
        _qpfImageBytes.isNotEmpty &&
        _qpfImageBytes.any((bytes) => bytes != null)) {
      return;
    }
    _isLoadingQpfImages = true;
    if(forceRefresh || _qpfImageBytes.isEmpty || !_qpfImageBytes.any((bytes) => bytes != null)){
         _qpfImageBytes = [];
    }
    _showAiAnalysis = false;
    notifyListeners();

    try {
      _qpfImageBytes = await _imageService.loadQpfImages(forceRefresh: forceRefresh);
      _lastFetchTimeQpf = DateTime.now();
    } catch (e) {
       if(forceRefresh || _qpfImageBytes.isEmpty || !_qpfImageBytes.any((bytes) => bytes != null)){
           _qpfImageBytes = [];
           _lastFetchTimeQpf = null;
       }
    } finally {
      _isLoadingQpfImages = false;
      notifyListeners();
    }
  }

  Future<void> refreshQpfImages() async {
     await _fetchQpfImagesIfNeeded(forceRefresh: true);
  }

  Point<double>? convertLatLngToPixel(double lat, double lon) {
    final double latRatio = (lat - radarLatMin) / (radarLatMax - radarLatMin);
    final double lonRatio = (lon - radarLonMin) / (radarLonMax - radarLonMin);

    if (latRatio < 0 || latRatio > 1 || lonRatio < 0 || lonRatio > 1) {
        return null;
    }
    final double pixelX = lonRatio * radarImageWidth;
    final double pixelY = (1.0 - latRatio) * radarImageHeight;
    return Point(pixelX, pixelY);
  }

  void startAnimation() {
    if (_radarImageBytes.where((bytes) => bytes != null).length < 2) return;
    _isPlaying = true;
    notifyListeners();

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
       int nextFrame = _currentRadarFrame;
       int startFrame = _currentRadarFrame;
       do {
           nextFrame = (nextFrame + 1) % _radarImageBytes.length;
           if (nextFrame == startFrame) break;
       } while (_radarImageBytes[nextFrame] == null);

       if (_radarImageBytes[nextFrame] != null && nextFrame != startFrame) {
          _currentRadarFrame = nextFrame;
          _sliderValue = _currentRadarFrame.toDouble();
          notifyListeners();
       } else {
          stopAnimation();
       }
    });
  }

  void stopAnimation() {
    _animationTimer?.cancel();
    if (_isPlaying) {
       _isPlaying = false;
       notifyListeners();
    }
  }

  void stepFrame(int delta) {
    if (_radarImageBytes.where((bytes) => bytes != null).isEmpty) return;
    stopAnimation();

    int targetFrame = _currentRadarFrame;
    int steps = delta.abs();
    int direction = delta.sign;

    for(int i=0; i<steps; ++i){
      int previousTarget = targetFrame;
      do {
        targetFrame = (targetFrame + direction);
         if (targetFrame < 0) {
             targetFrame = _radarImageBytes.length - 1;
         } else {
              targetFrame %= _radarImageBytes.length;
         }
         if (targetFrame == previousTarget) break;
      } while (_radarImageBytes[targetFrame] == null);

       if (_radarImageBytes[targetFrame] == null || targetFrame == previousTarget) {
          targetFrame = previousTarget;
          break;
       }
    }

    if (_radarImageBytes[targetFrame] != null && targetFrame != _currentRadarFrame) {
       _currentRadarFrame = targetFrame;
       _sliderValue = _currentRadarFrame.toDouble();
       notifyListeners();
    }
  }

  void onSliderChanged(double value) {
    if (_radarImageBytes.isEmpty) return;
    int frame = value.round();
    if (frame >= 0 && frame < _radarImageBytes.length) {
       if (_radarImageBytes[frame] != null) {
          if (frame != _currentRadarFrame) {
            stopAnimation();
            _currentRadarFrame = frame;
            _sliderValue = value;
            notifyListeners();
          }
       } else {
           _sliderValue = _currentRadarFrame.toDouble();
           notifyListeners();
       }
    }
  }

  void setSelectedView(MapLayerType view) {
     if (_selectedView != view) {
        _selectedView = view;
        stopAnimation();
        _showAiAnalysis = false;

        if (view == MapLayerType.radarEcho) {
            _fetchRadarImagesIfNeeded();
        } else {
             _fetchQpfImagesIfNeeded();
        }
        notifyListeners();
     }
  }

  void setQpfPage(int index) {
    if (_currentQpfPage != index && index >= 0 && index < qpfImageUrls.length) {
      _currentQpfPage = index;
      notifyListeners();
    }
  }

  void toggleAiAnalysis(bool show) {
    if (_showAiAnalysis != show) {
      _showAiAnalysis = show;
      notifyListeners();
    }
  }

  void centerOnUserLocation() {
    if (_currentPosition == null) {
      determinePosition();
      return;
    }
    Point<double>? userPixel = convertLatLngToPixel(_currentPosition!.latitude, _currentPosition!.longitude);
    if (userPixel != null) {
       final Matrix4 matrix = Matrix4.identity()
           ..translate(-userPixel.x * 1.0 + (radarImageWidth / 4), -userPixel.y * 1.0 + (radarImageHeight / 4))
           ..scale(1.0);
       _transformationController.value = matrix;
    }
  }
}
