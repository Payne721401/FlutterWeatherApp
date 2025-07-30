import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/location_data.dart';
import '../state/location_search_state.dart';
import '../../../weather/presentation/state/weather_data_state.dart';

// Enum to explicitly manage the view state
enum SearchViewState { defaults, searching }

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final FocusNode _focusNode = FocusNode();
  SearchViewState _viewState = SearchViewState.defaults;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationSearchState>().searchController.clear();
    });
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _switchToSearch() {
    if (_viewState != SearchViewState.searching) {
      setState(() {
        _viewState = SearchViewState.searching;
      });
    }
  }

  void _switchToDefault() {
    if (_viewState != SearchViewState.defaults) {
      setState(() {
        _viewState = SearchViewState.defaults;
        FocusScope.of(context).unfocus();
      });
    }
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
    // After toggling, force a rebuild to update the icon state
    setState(() {});
  }

  Future<void> _selectLocationAndGoBack(LocationData location) async {
    final locationSearchState = context.read<LocationSearchState>();
    final weatherDataState = context.read<WeatherDataState>();
    
    await locationSearchState.addRecentSearch(location);
    await weatherDataState.fetchDataForSearchedLocation(location); 
    
    if (mounted) {
      Navigator.of(context).popUntil(ModalRoute.withName('/home'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('新增地點'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: _switchToDefault,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(context),
              const SizedBox(height: 24),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final locationSearchState = context.read<LocationSearchState>();
    return Material(
      elevation: 1.0,
      borderRadius: BorderRadius.circular(30.0),
      color: Colors.white,
      child: TextField(
        controller: locationSearchState.searchController,
        focusNode: _focusNode,
        onTap: _switchToSearch,
        onChanged: (query) {
           locationSearchState.searchLocations(query);
        },
        decoration: InputDecoration(
          hintText: '查詢地點...',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildContent() {
    final locationSearchState = context.watch<LocationSearchState>();
    final query = locationSearchState.searchController.text;

    if (_viewState == SearchViewState.searching) {
      if (query.isNotEmpty) {
        return _buildSearchResults(locationSearchState);
      } else {
        return _buildRecentSearches(locationSearchState);
      }
    } else {
      return _buildDefaultView(context);
    }
  }
  
  Widget _buildDefaultView(BuildContext context) {
    final weatherDataState = context.watch<WeatherDataState>();
    final locationSearchState = context.watch<LocationSearchState>();
    
    final currentLocationName = weatherDataState.currentLocationName;
    final currentLocationData = locationSearchState.getLocationDataByName(currentLocationName);

    return ListView(
      children: [
        _buildSectionHeader('現在地點', Icons.my_location, Colors.blue),
        const SizedBox(height: 8),
        if (currentLocationData != null)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: LocationSearchItem(
              location: currentLocationData,
              onSelect: _selectLocationAndGoBack,
              onToggleFavorite: _toggleFavorite,
              isSaved: locationSearchState.isLocationSaved(currentLocationData),
            ),
          ),
        const SizedBox(height: 24),

        _buildSectionHeader('我的最愛', Icons.favorite, Colors.red),
        const SizedBox(height: 8),
        if (locationSearchState.savedLocations.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('點擊愛心收藏地點'),
          ))
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: locationSearchState.savedLocations.map((location) {
                return Column(
                  children: [
                    LocationSearchItem(
                      location: location,
                      onSelect: _selectLocationAndGoBack,
                      onToggleFavorite: _toggleFavorite,
                      isSaved: true,
                    ),
                    if (location != locationSearchState.savedLocations.last)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResults(LocationSearchState locationSearchState) {
    if (locationSearchState.filteredLocations.isEmpty) {
      return const Center(child: Text('找不到符合的地點'));
    }
    return ListView.builder(
      itemCount: locationSearchState.filteredLocations.length,
      itemBuilder: (context, index) {
        final location = locationSearchState.filteredLocations[index];
        final isSaved = locationSearchState.isLocationSaved(location);
        return LocationSearchItem(
          key: ValueKey(location.name),
          location: location,
          onSelect: _selectLocationAndGoBack,
          onToggleFavorite: _toggleFavorite,
          isSaved: isSaved,
        );
      },
    );
  }

  Widget _buildRecentSearches(LocationSearchState locationSearchState) {
    if (locationSearchState.recentSearches.isEmpty) {
      return const Center(child: Text('沒有最近搜尋紀錄'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('最近搜尋', Icons.history, Colors.orange),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: locationSearchState.recentSearches.length,
            itemBuilder: (context, index) {
              final location = locationSearchState.recentSearches[index];
              final isSaved = locationSearchState.isLocationSaved(location);
              return LocationSearchItem(
                key: ValueKey(location.name),
                location: location,
                onSelect: _selectLocationAndGoBack,
                onToggleFavorite: _toggleFavorite,
                isSaved: isSaved,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
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
                    Text(district, style: const TextStyle(fontSize: 16.0, color: Colors.black87, fontWeight: FontWeight.w500)),
                    if (city.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(city, style: const TextStyle(fontSize: 14.0, color: Colors.grey)),
                      ),
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
