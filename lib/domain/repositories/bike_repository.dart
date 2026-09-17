import '../entities/bike.dart';
import '../entities/bike_category.dart';

abstract class BikeRepository {
  Future<List<BikeCategory>> getCategories();
  Future<List<Bike>> getBikes({
    String? categoryId,
    String? stationId,
    bool onlyAvailable = true,
  });
  Future<Bike?> getBikeById(String id);
}
