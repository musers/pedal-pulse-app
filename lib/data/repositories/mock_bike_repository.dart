import '../../domain/entities/bike.dart';
import '../../domain/entities/bike_category.dart';
import '../../domain/repositories/bike_repository.dart';
import '../datasources/mock_data_source.dart';

class MockBikeRepository implements BikeRepository {
  @override
  Future<List<BikeCategory>> getCategories() async {
    // Simulate brief network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return MockDataSource.categories;
  }

  @override
  Future<List<Bike>> getBikes({
    String? categoryId,
    String? stationId,
    bool onlyAvailable = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return MockDataSource.bikes.where((bike) {
      if (categoryId != null && bike.categoryId != categoryId) return false;
      if (stationId != null && bike.currentStationId != stationId) return false;
      if (onlyAvailable && !bike.isAvailable) return false;
      return true;
    }).toList();
  }

  @override
  Future<Bike?> getBikeById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return MockDataSource.bikes.firstWhere((bike) => bike.id == id);
    } catch (_) {
      return null;
    }
  }
}
