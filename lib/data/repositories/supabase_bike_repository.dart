import '../../domain/entities/bike.dart';
import '../../domain/entities/bike_category.dart';
import '../../domain/repositories/bike_repository.dart';
import '../datasources/supabase_data_source.dart';

class SupabaseBikeRepository implements BikeRepository {
  final SupabaseDataSource dataSource;

  SupabaseBikeRepository(this.dataSource);

  @override
  Future<List<BikeCategory>> getCategories() => dataSource.getCategories();

  @override
  Future<List<Bike>> getBikes({
    String? categoryId,
    String? stationId,
    bool onlyAvailable = true,
  }) =>
      dataSource.getBikes(
        categoryId: categoryId,
        stationId: stationId,
        onlyAvailable: onlyAvailable,
      );

  @override
  Future<Bike?> getBikeById(String id) => dataSource.getBikeById(id);
}
