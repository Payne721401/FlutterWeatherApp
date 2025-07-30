import '../../data/models/location_data.dart';
import '../repositories/location_repository.dart';

class GetRecentSearchesUseCase {
  final LocationRepository repository;

  GetRecentSearchesUseCase(this.repository);

  Future<List<LocationData>> call() async {
    return await repository.getRecentSearches();
  }
}
