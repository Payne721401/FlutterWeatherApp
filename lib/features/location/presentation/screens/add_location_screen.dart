import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/location_data.dart';
import '../state/location_search_state.dart';
import '../../../weather/presentation/state/weather_data_state.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  late LocationSearchState _locationSearchState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationSearchState>().searchController.clear();
      context.read<LocationSearchState>().clearFilteredLocations();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locationSearchState = context.watch<LocationSearchState>();
  }

  Future<void> _toggleFavorite(LocationData location) async {
    final locationSearchState = context.read<LocationSearchState>();
    final isCurrentlySaved = locationSearchState.isLocationSaved(location);
    
    if (isCurrentlySaved) {
      await locationSearchState.removeSavedLocation(location);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${location.name} 已從我的最愛移除')),
        );
      }
    } else {
      await locationSearchState.saveNewLocation(location);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${location.name} 已加入我的最愛')),
        );
      }
    }
  }

  Future<void> _selectLocationAndGoBack(LocationData location) async {
    final weatherDataState = context.read<WeatherDataState>();
    context.read<LocationSearchState>().clearFilteredLocations();
    context.read<LocationSearchState>().searchController.clear();
    
    await weatherDataState.fetchDataForSearchedLocation(location); 
    if (mounted) {
      Navigator.of(context).popUntil(ModalRoute.withName('/home'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherDataState = context.read<WeatherDataState>();
    final currentLocationName = weatherDataState.currentLocationName;
    
    final currentLocationData = context.read<LocationSearchState>().getLocationDataByName(currentLocationName);
    final currentLocation = currentLocationData ?? (currentLocationName != null ? LocationData(name: currentLocationName) : null);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('搜尋地點'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              elevation: 1.0,
              borderRadius: BorderRadius.circular(30.0),
              color: Colors.white,
              child: TextField(
                controller: _locationSearchState.searchController,
                onChanged: (query) {
                  _locationSearchState.searchLocations(query);
                },
                decoration: InputDecoration(
                  hintText: '查找位置...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_locationSearchState.filteredLocations.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _locationSearchState.filteredLocations.length,
                  itemBuilder: (context, index) {
                    final location = _locationSearchState.filteredLocations[index];
                    final isAlreadySaved = _locationSearchState.isLocationSaved(location);
                    return LocationSearchItem(
                      location: location,
                      onSelect: _selectLocationAndGoBack,
                      onToggleFavorite: _toggleFavorite,
                      isSaved: isAlreadySaved,
                    );
                  },
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    _buildSectionHeader('現在地點', Icons.location_on, Colors.blue),
                    const SizedBox(height: 8),
                    if (currentLocation != null)
                      // MODIFICATION: Replaced LocationCurrentItem with a styled LocationSearchItem
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: LocationSearchItem(
                          location: currentLocation,
                          onSelect: _selectLocationAndGoBack,
                          onToggleFavorite: _toggleFavorite,
                          isSaved: _locationSearchState.isLocationSaved(currentLocation),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('熱門位置', Icons.whatshot, Colors.deepOrange),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: _locationSearchState.popularLocations.map((location) {
                          final isAlreadySaved = _locationSearchState.isLocationSaved(location);
                          return Column(
                            children: [
                              LocationSearchItem(
                                location: location,
                                onSelect: _selectLocationAndGoBack,
                                onToggleFavorite: _toggleFavorite,
                                isSaved: isAlreadySaved,
                              ),
                              if (location != _locationSearchState.popularLocations.last)
                                const Divider(height: 1, indent: 16, endIndent: 16),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class LocationSearchItem extends StatelessWidget {
  final LocationData location;
  final Function(LocationData) onSelect;
  final Function(LocationData) onToggleFavorite;
  final bool isSaved;

  const LocationSearchItem({
    super.key,
    required this.location,
    required this.onSelect,
    required this.onToggleFavorite,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    // MODIFICATION: Swapped title and subtitle logic
    final parts = location.name.split(' ');
    final district = parts.length > 1 ? parts.sublist(1).join(' ') : parts.first;
    final city = parts.length > 1 ? parts.first : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(location),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MODIFICATION: District is now the main title
                    Text(district, style: const TextStyle(fontSize: 16.0, color: Colors.black87, fontWeight: FontWeight.bold)),
                    // MODIFICATION: City is now the subtitle
                    if (city.isNotEmpty)
                      Text(city, style: const TextStyle(fontSize: 14.0, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  color: isSaved ? Colors.red : Colors.grey,
                ),
                onPressed: () => onToggleFavorite(location),
                tooltip: isSaved ? '從我的最愛移除' : '加入我的最愛',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
