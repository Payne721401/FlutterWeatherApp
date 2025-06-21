import 'dart:async';
import 'dart:typed_data';
import 'dart:math'; // For Point
import 'package:flutter/material.dart';
// Remove geolocator import
import 'package:geolocator/geolocator.dart';

import '../../data/models/map_layer_type.dart';
import '../../data/services/radar_image_service.dart';
import '../../../../services/location_service.dart'; // Import LocationService

// Constants moved here for proximity to their usage in state
const double radarLatMin = 17.75;
const double radarLatMax = 29.25;
const double radarLonMin = 115.00;
const double radarLonMax = 126.50;
const double radarImageWidth = 3600.0; // Pixels
const double radarImageHeight = 3600.0; // Pixels

class RadarState with ChangeNotifier {
  final RadarImageService _imageService = RadarImageService();
  final LocationService _locationService = LocationService(); // LocationService instance

  MapLayerType _selectedView = MapLayerType.radarEcho;
  List<String> _radarImageUrls = [];
  List<Uint8List?> _radarImageBytes = [];
  int _currentRadarFrame = 0;
  Timer? _animationTimer;
  bool _isPlaying = false;
  double _sliderValue = 0.0; // Slider is primarily for Radar animation
  bool _isLoadingRadarImages = false;

  // *** New: QPF Image State and Loading ***
  List<Uint8List?> _qpfImageBytes = [];
  bool _isLoadingQpfImages = false;
  // We can share the cache duration with the service, but keep timestamp in state
  // to control state-level cache validation.
  DateTime? _lastFetchTimeQpf; 
  final Duration _cacheDurationQpf = const Duration(minutes: 10); 

  bool _isFetchingLocation = false;
  Position? _currentPosition;
  String? _locationError;
  String? _administrativeDivision; // State variable for administrative division

  // Cache related (Radar)
  DateTime? _lastFetchTimeRadar;
  final Duration _cacheDurationRadar = const Duration(minutes: 10);

  // QPF Page Index State
  int _currentQpfPage = 0;

  // AI Analysis Visibility State
  bool _showAiAnalysis = false;

  final TransformationController _transformationController = TransformationController();
  final PageController _qpfPageController = PageController();

  // --- Getters for UI ---
  MapLayerType get selectedView => _selectedView;
  List<String> get radarImageUrls => _radarImageUrls;
  List<Uint8List?> get radarImageBytes => _radarImageBytes;
  int get currentRadarFrame => _currentRadarFrame;
  bool get isPlaying => _isPlaying;
  double get sliderValue => _sliderValue;
  bool get isLoadingRadarImages => _isLoadingRadarImages;

  // *** New: QPF Getters ***
  List<Uint8List?> get qpfImageBytes => _qpfImageBytes;
  bool get isLoadingQpfImages => _isLoadingQpfImages;

  bool get isFetchingLocation => _isFetchingLocation;
  Position? get currentPosition => _currentPosition;
  String? get locationError => _locationError;
  String? get administrativeDivision => _administrativeDivision; // Getter for administrative division
  TransformationController get transformationController => _transformationController;
  PageController get qpfPageController => _qpfPageController;
  int get currentQpfPage => _currentQpfPage;
  bool get showAiAnalysis => _showAiAnalysis;

  // Modified rainAlertMessage getter
  String get rainAlertMessage {
    if (_administrativeDivision != null) {
      return "${_administrativeDivision!} 未來1小時內無降雨";
    }
    return "定位中或無法取得定位 未來1小時內無降雨"; // Default message
  }

  // Getters that use the service (URLs are static for QPF)
  List<String> get qpfImageUrls => _imageService.getQpfImageUrls();
  String getQpfLabel(int index) => _imageService.getQpfLabel(index);
  String getFrameTimestampLabel(int frameIndex) => _imageService.getFrameTimestampLabel(frameIndex, _radarImageUrls);


  RadarState() {
    // Initial fetch or load from cache based on default view
    if (_selectedView == MapLayerType.radarEcho) {
      _fetchRadarImagesIfNeeded();
    } else { // Assuming the default view is not QPF initially, this might not be called
      // If default is QPF, call _fetchQpfImagesIfNeeded();
      // Since default is radar, QPF is fetched when user switches.
    }
    determinePosition();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _qpfPageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  // --- Location Fetching Logic ---
  Future<void> determinePosition() async {
    // bool serviceEnabled;
    // LocationPermission permission;

    _isFetchingLocation = true;
    _locationError = null;
    _administrativeDivision = null; // Clear previous division on new attempt
    notifyListeners();

    try {
      // Use LocationService to get current location
      final position = await _locationService.getCurrentLocation();
      _currentPosition = position;

      // Fetch administrative division using LocationService
      _administrativeDivision = await _locationService.getAdministrativeDivision(
          position.latitude,
          position.longitude,
      );

      _isFetchingLocation = false;
      _locationError = null; // Clear any previous location errors on success
      notifyListeners();
      centerOnUserLocation(); // Consider if map centering should still rely on position or be removed/modified
    } catch (e) {
      _locationError = 'Failed to get location: $e';
      _isFetchingLocation = false;
      // Remove clearing _currentPosition
      _currentPosition = null; // Clear position on error
      _administrativeDivision = null; // Clear administrative division on error
      notifyListeners();
    }
  }

  // --- Data Fetching (Radar Images) Logic ---
  Future<void> _fetchRadarImagesIfNeeded({bool forceRefresh = false}) async {
    final now = DateTime.now();
    // Check cache validity in State before calling service
    if (!forceRefresh && 
        _lastFetchTimeRadar != null && 
        now.difference(_lastFetchTimeRadar!) < _cacheDurationRadar && 
        _radarImageBytes.isNotEmpty && // Also check if we actually have data cached
        _radarImageBytes.any((bytes) => bytes != null)) { // And if the cached data is valid
      print("Radar images loaded from state cache.");
      // notifyListeners(); // Re-notify if needed to update UI based on state change detection
      return;
    }

    print(forceRefresh ? "Forcing radar image refresh." : "Fetching new radar images (state cache expired or empty).");
    _isLoadingRadarImages = true;
    // Clear current data only if forcing refresh or data is completely empty/invalid
    if(forceRefresh || _radarImageBytes.isEmpty || !_radarImageBytes.any((bytes) => bytes != null)){
        _radarImageBytes = [];
        _radarImageUrls = [];
        _currentRadarFrame = 0; // Reset frame and slider
        _sliderValue = 0.0;
    }

    _showAiAnalysis = false; // Hide AI panel on refresh
    stopAnimation(); // Stop animation on refresh
    notifyListeners(); // Notify to show loading state and clear old images

    try {
      // Call the service method - the service also has internal cache logic
      _radarImageUrls = await _imageService.fetchRadarImageUrls(forceRefresh: forceRefresh);
      if (_radarImageUrls.isNotEmpty) {
        _radarImageBytes = await _imageService.loadRadarImages(_radarImageUrls, forceRefresh: forceRefresh);
        _lastFetchTimeRadar = DateTime.now(); // Update state-level cache timestamp on success

        // Find the index of the last valid (non-null) image to set initial frame
        int lastValidFrame = _radarImageBytes.lastIndexWhere((bytes) => bytes != null);

        if (lastValidFrame != -1) {
          _currentRadarFrame = lastValidFrame;
          _sliderValue = lastValidFrame.toDouble();
        } else {
          // Handle case where no images loaded successfully
          _currentRadarFrame = 0;
          _sliderValue = 0.0;
        }
      } else {
        // Handle case where no URLs were fetched or they are empty
        _radarImageBytes = [];
        _currentRadarFrame = 0;
        _sliderValue = 0.0;
      }
    } catch (e) {
      print("Error fetching radar images: $e");
      // Optionally clear old data on error during forced refresh or if data was invalid/empty
       if(forceRefresh || _radarImageBytes.isEmpty || !_radarImageBytes.any((bytes) => bytes != null)){
        _radarImageUrls = [];
        _radarImageBytes = [];
        _currentRadarFrame = 0;
        _sliderValue = 0.0;
        _lastFetchTimeRadar = null; // Invalidate state cache on error during force refresh
       }
    } finally {
      _isLoadingRadarImages = false;
      notifyListeners(); // Notify to hide loading state
    }
  }

  // Public method for UI to call for refreshing Radar
  Future<void> refreshRadarImages() async {
    await _fetchRadarImagesIfNeeded(forceRefresh: true);
  }

  // *** New: Data Fetching (QPF Images) Logic ***
   Future<void> _fetchQpfImagesIfNeeded({bool forceRefresh = false}) async {
    final now = DateTime.now();
    // Check cache validity in State before calling service
    if (!forceRefresh &&
        _lastFetchTimeQpf != null &&
        now.difference(_lastFetchTimeQpf!) < _cacheDurationQpf &&
        _qpfImageBytes.isNotEmpty && // Also check if we actually have data cached
        _qpfImageBytes.any((bytes) => bytes != null)) { // And if the cached data is valid
      print("QPF images loaded from state cache.");
      // notifyListeners(); // Re-notify if needed
      return;
    }

    print(forceRefresh ? "Forcing QPF image refresh." : "Fetching new QPF images (state cache expired or empty).");
    _isLoadingQpfImages = true;
     // Clear current data only if forcing refresh or data is completely empty/invalid
    if(forceRefresh || _qpfImageBytes.isEmpty || !_qpfImageBytes.any((bytes) => bytes != null)){
         _qpfImageBytes = [];
    }
    _showAiAnalysis = false; // Hide AI panel on refresh
    notifyListeners(); // Notify to show loading state and potentially clear old images

    try {
      // Call the service method - the service has its own internal cache logic too
      _qpfImageBytes = await _imageService.loadQpfImages(forceRefresh: forceRefresh);
      _lastFetchTimeQpf = DateTime.now(); // Update state-level cache timestamp on success
    } catch (e) {
      print("Error fetching QPF images: $e");
      // Optionally clear QPF images on error during force refresh or if data was invalid/empty
       if(forceRefresh || _qpfImageBytes.isEmpty || !_qpfImageBytes.any((bytes) => bytes != null)){
           _qpfImageBytes = [];
           _lastFetchTimeQpf = null; // Invalidate state cache on error during force refresh
       }
    } finally {
      _isLoadingQpfImages = false;
      notifyListeners(); // Notify to hide loading state
    }
  }

  // *** New: Public method for UI to call for refreshing QPF ***
  Future<void> refreshQpfImages() async {
     await _fetchQpfImagesIfNeeded(forceRefresh: true);
  }

  Point<double>? convertLatLngToPixel(double lat, double lon) {
    final double latRatio = (lat - radarLatMin) / (radarLatMax - radarLatMin);
    final double lonRatio = (lon - radarLonMin) / (radarLonMax - radarLonMin);

    if (latRatio < 0 || latRatio > 1 || lonRatio < 0 || lonRatio > 1) {
        print("Warning: Location ($lat, $lon) is outside the radar image bounds.");
        return null;
    }
    final double pixelX = lonRatio * radarImageWidth;
    final double pixelY = (1.0 - latRatio) * radarImageHeight;
    return Point(pixelX, pixelY);
  }

  // --- Animation and Controls Logic (Primarily for Radar) ---
  void startAnimation() {
    if (_radarImageBytes.where((bytes) => bytes != null).length < 2) return;
    _isPlaying = true;
    notifyListeners();

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
       int nextFrame = _currentRadarFrame;
       int startFrame = _currentRadarFrame; // Keep track of starting point
       do {
           nextFrame = (nextFrame + 1) % _radarImageBytes.length;
           // If we've looped back to start without finding a valid frame, stop
           if (nextFrame == startFrame) break;
       } while (_radarImageBytes[nextFrame] == null);

       if (_radarImageBytes[nextFrame] != null && nextFrame != startFrame) {
          _currentRadarFrame = nextFrame;
          // *** Note: Slider is only relevant for Radar animation ***
          // If you add animation/slider for QPF, you'd need separate state/logic
          _sliderValue = _currentRadarFrame.toDouble(); 
          notifyListeners();
       } else {
          stopAnimation(); // Stop if we loop and only find nulls or only have one valid frame
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

  // Step frame is primarily for Radar
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
         // If we've looped back to the start without finding a valid frame, break
         if (targetFrame == previousTarget) break;
      } while (_radarImageBytes[targetFrame] == null);

       // If the loop completes without finding a valid frame, break outer loop
       if (_radarImageBytes[targetFrame] == null || targetFrame == previousTarget) {
          targetFrame = previousTarget; // Revert to last known good frame
          break;
       }
    }

    if (_radarImageBytes[targetFrame] != null && targetFrame != _currentRadarFrame) {
       _currentRadarFrame = targetFrame;
       _sliderValue = _currentRadarFrame.toDouble();
       notifyListeners();
    }
  }

  // onSliderChanged is primarily for Radar
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
           print("Cannot select invalid frame $frame");
           // Revert slider smoothly if user tries to land on invalid frame
           _sliderValue = _currentRadarFrame.toDouble();
           notifyListeners(); // Notify to visually snap back
       }
    }
  }

  // --- View Selection Logic ---
  void setSelectedView(MapLayerType view) {
     if (_selectedView != view) {
        _selectedView = view;
        stopAnimation(); // Stop radar animation when switching view
        _showAiAnalysis = false; // Hide AI panel when switching view type

        // *** New: Fetch images based on selected view ***
        if (view == MapLayerType.radarEcho) {
            _fetchRadarImagesIfNeeded(); // Check state cache or fetch for radar
        } else { // Assuming MapLayerType.qpf is the other option
             _fetchQpfImagesIfNeeded(); // Check state cache or fetch for QPF
        }
        notifyListeners();
     }
  }

  // --- QPF Page Navigation Logic ---
  void setQpfPage(int index) {
    if (_currentQpfPage != index && index >= 0 && index < qpfImageUrls.length) {
      _currentQpfPage = index;
      notifyListeners();
    }
  }

  // --- AI Analysis Toggle Logic ---
  void toggleAiAnalysis(bool show) {
    if (_showAiAnalysis != show) {
      _showAiAnalysis = show;
      notifyListeners();
    }
  }

  // --- Map Centering Logic ---
  void centerOnUserLocation() {
    // This method now relies on _currentPosition which was removed.
    // Depending on the UI, this method might need to be removed,
    // or modified to accept a Position object if centering is still needed.
    // For now, commenting out its body as _currentPosition is gone.

    if (_currentPosition == null) {
      determinePosition(); // Re-fetch if no position
    }
    // Optional: Add actual map centering logic using TransformationController
    // This requires converting lat/lon to pixel and translating the view
    if (_currentPosition != null) {
       Point<double>? userPixel = convertLatLngToPixel(_currentPosition!.latitude, _currentPosition!.longitude);
       if (userPixel != null) {
           // Example: Center the view on the user's location with a certain scale
           final Matrix4 matrix = Matrix4.identity()
               ..translate(-userPixel.x * 1.0 + (radarImageWidth / 4), -userPixel.y * 1.0 + (radarImageHeight / 4)) // Adjust scale/offset as needed
               ..scale(1.0);
           _transformationController.value = matrix; // Uncomment to enable centering
            print("User location centered (pixel: ${userPixel.x.round()}, ${userPixel.y.round()})");
       } else {
           print("User location is outside radar bounds, cannot center.");
       }
    } else {
       print("User location not available yet.");
    }
  }
}
