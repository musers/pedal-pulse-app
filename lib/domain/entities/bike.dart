enum BikeStatus {
  available,
  reserved,
  inUse,
  maintenance,
  retired,
}

class Bike {
  final String id;
  final String name;
  final String brand;
  final String model;
  final String registrationNumber;
  final String categoryId;
  final String currentStationId;
  final BikeStatus status;
  final int? batteryPercentage; // For EV
  final int rangeKm;
  final double hourlyRate;
  final double dailyRate;
  final double securityDeposit;
  final String imageUrl;
  final List<String> features;
  final int odometerKm;

  const Bike({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.registrationNumber,
    required this.categoryId,
    required this.currentStationId,
    this.status = BikeStatus.available,
    this.batteryPercentage,
    required this.rangeKm,
    required this.hourlyRate,
    required this.dailyRate,
    required this.securityDeposit,
    required this.imageUrl,
    this.features = const [],
    this.odometerKm = 0,
  });

  bool get isAvailable => status == BikeStatus.available;
}
