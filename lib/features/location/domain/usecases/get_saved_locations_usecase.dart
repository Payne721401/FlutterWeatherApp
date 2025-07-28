import '../../data/models/location_data.dart';
import '../repositories/location_repository.dart';

class GetSavedLocationsUseCase {
  final LocationRepository repository;

  GetSavedLocationsUseCase(this.repository);

  Future<List<LocationData>> call() {
    return repository.getSavedLocations();
  }
}