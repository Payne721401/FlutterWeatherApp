import '../repositories/location_repository.dart';

class RemoveLocationUseCase {
  final LocationRepository repository;

  RemoveLocationUseCase(this.repository);

  Future<void> call(String locationName) {
    return repository.removeLocation(locationName);
  }
}