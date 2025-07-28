import '../../data/models/location_data.dart';
import '../repositories/location_repository.dart';

class SaveLocationUseCase {
  final LocationRepository repository;

  SaveLocationUseCase(this.repository);

  Future<void> call(LocationData location) {
    return repository.saveLocation(location);
  }
}