import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../weather/presentation/state/weather_data_state.dart';
import '../state/location_search_state.dart';
import '../../data/models/location_data.dart';
import './add_location_screen.dart';

class ManageSavedLocationsScreen extends StatefulWidget {
  const ManageSavedLocationsScreen({super.key});

  @override
  State<ManageSavedLocationsScreen> createState() =>
      _ManageSavedLocationsScreenState();
}

class _ManageSavedLocationsScreenState
    extends State<ManageSavedLocationsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialLocations();
    });
  }
  
  Future<void> _loadInitialLocations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    await context.read<LocationSearchState>().loadSavedLocations();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeLocation(LocationData location) async {
    await context.read<LocationSearchState>().removeSavedLocation(location);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${location.name} 已移除')));
    }
  }

  Future<void> _selectLocationAndGoBack(LocationData location) async {
    final weatherDataState = context.read<WeatherDataState>();
    await weatherDataState.fetchDataForSearchedLocation(location);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherDataState = context.watch<WeatherDataState>();
    final locationSearchState = context.watch<LocationSearchState>();

    final currentLocationName = weatherDataState.currentLocationName;
    final favoriteLocations = locationSearchState.savedLocations
        .where((loc) => loc.name != currentLocationName)
        .toList();

    final currentLocationData = locationSearchState.getLocationDataByName(currentLocationName);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('管理地點'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            // MODIFICATION: Changed icon from add to search.
            icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddLocationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Currently Displayed Location Section
                  if (currentLocationData != null) ...[
                    const Text(
                      '目前地點',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SavedLocationItem(
                      location: currentLocationData,
                      temperature: weatherDataState.temperature,
                      condition: weatherDataState.condition,
                      windSpeed: weatherDataState.observation?.observations?.windSpeedAsDouble,
                      onSelect: (loc) {},
                      onRemove: null, 
                      isCurrent: true,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Favorite Locations Section
                  const Text(
                    '我的最愛',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (favoriteLocations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('您還沒有儲存任何其他地點。'),
                    )
                  else
                    ...favoriteLocations.map((location) {
                      return SavedLocationItem(
                        location: location,
                        temperature: null,
                        condition: null,
                        windSpeed: null,
                        onSelect: _selectLocationAndGoBack,
                        onRemove: _removeLocation,
                        isCurrent: false,
                      );
                    }).toList(),
                ],
              ),
    );
  }
}

class SavedLocationItem extends StatelessWidget {
  final LocationData location;
  final double? temperature;
  final String? condition;
  final double? windSpeed;
  final Function(LocationData) onSelect;
  final Function(LocationData)? onRemove;
  final bool isCurrent;

  const SavedLocationItem({
    super.key,
    required this.location,
    this.temperature,
    this.condition,
    this.windSpeed,
    required this.onSelect,
    required this.onRemove,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasWeatherData = temperature != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 1.0,
          color: isCurrent ? Colors.blue.shade50 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: isCurrent ? BorderSide(color: Theme.of(context).primaryColor, width: 1.5) : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => onSelect(location),
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          location.name,
                          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasWeatherData)
                        Text(
                          '${temperature!.round()}°',
                          style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (hasWeatherData)
                    Row(
                      children: [
                        Text(
                          condition ?? 'N/A',
                          style: TextStyle(fontSize: 16.0, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.air, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${windSpeed?.toStringAsFixed(1) ?? '--'} m/s',
                          style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
                        ),
                      ],
                    )
                  else if (!isCurrent)
                    Text('點擊以查看天氣', style: TextStyle(fontSize: 14.0, color: Theme.of(context).primaryColor)),
                ],
              ),
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 0,
            right: -4,
            child: InkWell(
              onTap: () => onRemove!(location),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade300,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.grey.shade700,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
