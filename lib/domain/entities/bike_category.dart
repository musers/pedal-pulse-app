enum FuelType { electric, petrol }

class BikeCategory {
  final String id;
  final String name;
  final String description;
  final FuelType fuelType;
  final String? icon;

  const BikeCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.fuelType,
    this.icon,
  });
}
