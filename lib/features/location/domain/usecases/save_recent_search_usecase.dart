import '../../data/models/location_data.dart';
import '../repositories/location_repository.dart';

class SaveRecentSearchUseCase {
  final LocationRepository repository;

  SaveRecentSearchUseCase(this.repository);

  Future<void> call(LocationData location) async {
    return await repository.saveRecentSearch(location);
  }
}
