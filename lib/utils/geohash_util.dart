import 'package:dart_geohash/dart_geohash.dart';
import 'dart:math';

class GeohashUtil {
  // Calculates the geohash length needed for a given radius in kilometers.
  // This is an approximation and might need fine-tuning based on your data distribution and desired accuracy.
  static int getGeohashLengthForRadius(double radiusKm) {
    if (radiusKm <= 0.005) return 9; // ~5 meters
    if (radiusKm <= 0.03) return 8; // ~30 meters
    if (radiusKm <= 0.15) return 7; // ~150 meters
    if (radiusKm <= 0.6) return 6; // ~600 meters
    if (radiusKm <= 2.4) return 5; // ~2.4 km
    if (radiusKm <= 20) return 4; // ~20 km
    if (radiusKm <= 160) return 3; // ~160 km
    if (radiusKm <= 1250) return 2; // ~1250 km
    return 1;
  }

  // Generates the geohash for given latitude and longitude with specified precision.
  static String encode(double latitude, double longitude, {int precision = 9}) {
    final geoHasher = GeoHasher();
    return geoHasher.encode(longitude, latitude, precision: precision);
  }

  // Decodes a geohash to its central latitude and longitude.
  static List<double> decode(String geohash) {
    final geoHasher = GeoHasher();
    final List<double> decodedCoordinates = geoHasher.decode(geohash); // 正確的型別是 List<double>
  return [decodedCoordinates[1], decodedCoordinates[0]]; // [latitude, longitude]
}

  // Finds all geohashes that cover a circular area.
  // This uses the dart_geohash library's neighbor function.
  static List<String> getGeohashNeighbors(double latitude, double longitude, int precision) {
    final geoHasher = GeoHasher();
    final centerGeohash = geoHasher.encode(longitude, latitude, precision: precision);
    
    // Get the neighbors as a Map, then extract values to a Set
    final Map<String, String> neighborsMap = geoHasher.neighbors(centerGeohash);
    final Set<String> neighborsSet = neighborsMap.values.toSet(); // Extract values and convert to Set
    neighborsSet.add(centerGeohash); // Add the center geohash

    return neighborsSet.toList();
  }

  // Haversine formula to calculate distance between two points in kilometers.
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Pi/180
    const c = cos;
    final a = 0.5 - c((lat2 - lat1) * p) / 2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
