class Station {
  final String id;
  final String name;
  final String code;
  final String address;
  final String landmark;
  final String city;
  final double latitude;
  final double longitude;
  final String operatingHours;
  final String contactPhone;
  final int totalCapacity;
  final int availableBikesCount;
  final bool isActive;

  const Station({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.landmark,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.operatingHours,
    required this.contactPhone,
    this.totalCapacity = 20,
    this.availableBikesCount = 0,
    this.isActive = true,
  });
}
