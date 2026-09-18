import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/bike.dart';
import '../../domain/entities/bike_category.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/station.dart';

class SupabaseDataSource {
  final SupabaseClient client;

  SupabaseDataSource(this.client);

  // --------------------------------------------------------------------------
  // STATIONS
  // --------------------------------------------------------------------------
  Future<List<Station>> getStations({String? city}) async {
    var query = client.from('stations').select();
    if (city != null) {
      query = query.ilike('city', city);
    }
    final response = await query.order('name', ascending: true);
    final list = response as List<dynamic>;

    return list.map((json) {
      final map = json as Map<String, dynamic>;
      return Station(
        id: map['id'] as String,
        code: map['code'] as String,
        name: map['name'] as String,
        address: map['address'] as String,
        landmark: map['landmark'] as String? ?? '',
        city: map['city'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        operatingHours: map['operating_hours'] as String? ?? '06:00 AM - 11:00 PM',
        contactPhone: map['contact_phone'] as String? ?? '',
        totalCapacity: (map['total_capacity'] as num?)?.toInt() ?? 20,
        availableBikesCount: (map['available_bikes_count'] as num?)?.toInt() ?? 0,
        isActive: map['is_active'] as bool? ?? true,
      );
    }).toList();
  }

  // --------------------------------------------------------------------------
  // CATEGORIES
  // --------------------------------------------------------------------------
  Future<List<BikeCategory>> getCategories() async {
    final response = await client.from('bike_categories').select().order('name', ascending: true);
    final list = response as List<dynamic>;

    return list.map((json) {
      final map = json as Map<String, dynamic>;
      return BikeCategory(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        fuelType: (map['fuel_type'] == 'electric') ? FuelType.electric : FuelType.petrol,
        icon: map['icon'] as String?,
      );
    }).toList();
  }

  // --------------------------------------------------------------------------
  // BIKES
  // --------------------------------------------------------------------------
  Future<List<Bike>> getBikes({
    String? categoryId,
    String? stationId,
    bool onlyAvailable = true,
  }) async {
    var query = client.from('bikes').select();
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (stationId != null) {
      query = query.eq('current_station_id', stationId);
    }
    if (onlyAvailable) {
      query = query.eq('status', 'available');
    }

    final response = await query.order('hourly_rate', ascending: true);
    final list = response as List<dynamic>;

    return list.map((json) => _mapBike(json as Map<String, dynamic>)).toList();
  }

  Future<Bike?> getBikeById(String id) async {
    final response = await client.from('bikes').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return _mapBike(response);
  }

  Bike _mapBike(Map<String, dynamic> map) {
    BikeStatus status;
    switch (map['status']) {
      case 'reserved':
        status = BikeStatus.reserved;
        break;
      case 'in_use':
        status = BikeStatus.inUse;
        break;
      case 'maintenance':
        status = BikeStatus.maintenance;
        break;
      case 'retired':
        status = BikeStatus.retired;
        break;
      default:
        status = BikeStatus.available;
    }

    final featuresJson = map['features'];
    List<String> features = [];
    if (featuresJson is List) {
      features = featuresJson.map((e) => e.toString()).toList();
    }

    return Bike(
      id: map['id'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String,
      model: map['model'] as String,
      registrationNumber: map['registration_number'] as String,
      categoryId: map['category_id'] as String,
      currentStationId: map['current_station_id'] as String,
      status: status,
      batteryPercentage: (map['battery_percentage'] as num?)?.toInt(),
      rangeKm: (map['range_km'] as num).toInt(),
      hourlyRate: (map['hourly_rate'] as num).toDouble(),
      dailyRate: (map['daily_rate'] as num).toDouble(),
      securityDeposit: (map['security_deposit'] as num).toDouble(),
      imageUrl: map['image_url'] as String,
      features: features,
      odometerKm: (map['odometer_km'] as num?)?.toInt() ?? 0,
    );
  }

  // --------------------------------------------------------------------------
  // BOOKINGS
  // --------------------------------------------------------------------------
  Future<List<Booking>> getUserBookings(String customerId) async {
    final response = await client
        .from('bookings')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    final list = response as List<dynamic>;
    return list.map((json) => _mapBooking(json as Map<String, dynamic>)).toList();
  }

  Future<Booking> createBooking({
    required String customerId,
    required String bikeId,
    required String pickupStationId,
    required String returnStationId,
    required DateTime startTime,
    required DateTime endTime,
    required PricingBreakdown pricing,
  }) async {
    final bookingNumber = 'VR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final insertData = {
      'booking_number': bookingNumber,
      'customer_id': customerId,
      'bike_id': bikeId,
      'pickup_station_id': pickupStationId,
      'return_station_id': returnStationId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': 'confirmed',
      'rental_fare': pricing.rentalFare,
      'gst_amount': pricing.gstAmount,
      'security_deposit': pricing.securityDeposit,
      'discount_amount': pricing.discountAmount,
      'total_payable': pricing.totalPayable,
      'deposit_status': 'held',
    };

    final response = await client.from('bookings').insert(insertData).select().single();
    return _mapBooking(response);
  }

  Future<Booking> recordPickup(String bookingId, int startingOdometer) async {
    final response = await client
        .from('bookings')
        .update({
          'status': 'active',
          'actual_pickup_time': DateTime.now().toIso8601String(),
          'starting_odometer': startingOdometer,
        })
        .eq('id', bookingId)
        .select()
        .single();

    return _mapBooking(response);
  }

  Future<Booking> recordReturn(String bookingId, int endingOdometer, String returnStationId) async {
    final response = await client
        .from('bookings')
        .update({
          'status': 'completed',
          'actual_return_time': DateTime.now().toIso8601String(),
          'ending_odometer': endingOdometer,
          'return_station_id': returnStationId,
          'deposit_status': 'refund_initiated',
        })
        .eq('id', bookingId)
        .select()
        .single();

    return _mapBooking(response);
  }

  Future<Booking> cancelBooking(String bookingId, String reason) async {
    final response = await client
        .from('bookings')
        .update({
          'status': 'cancelled',
          'cancellation_reason': reason,
          'deposit_status': 'refund_initiated',
        })
        .eq('id', bookingId)
        .select()
        .single();

    return _mapBooking(response);
  }

  Booking _mapBooking(Map<String, dynamic> map) {
    BookingStatus status;
    switch (map['status']) {
      case 'active':
        status = BookingStatus.active;
        break;
      case 'completed':
        status = BookingStatus.completed;
        break;
      case 'cancelled':
        status = BookingStatus.cancelled;
        break;
      case 'pending_payment':
        status = BookingStatus.pendingPayment;
        break;
      default:
        status = BookingStatus.confirmed;
    }

    SecurityDepositStatus depositStatus;
    switch (map['deposit_status']) {
      case 'pending':
        depositStatus = SecurityDepositStatus.pending;
        break;
      case 'refund_initiated':
        depositStatus = SecurityDepositStatus.refundInitiated;
        break;
      case 'refunded':
        depositStatus = SecurityDepositStatus.refunded;
        break;
      case 'deducted':
        depositStatus = SecurityDepositStatus.deducted;
        break;
      default:
        depositStatus = SecurityDepositStatus.held;
    }

    final pricing = PricingBreakdown(
      rentalFare: (map['rental_fare'] as num).toDouble(),
      gstAmount: (map['gst_amount'] as num).toDouble(),
      securityDeposit: (map['security_deposit'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      totalPayable: (map['total_payable'] as num).toDouble(),
    );

    return Booking(
      id: map['id'] as String,
      bookingNumber: map['booking_number'] as String,
      customerId: map['customer_id'] as String,
      bikeId: map['bike_id'] as String,
      pickupStationId: map['pickup_station_id'] as String,
      returnStationId: map['return_station_id'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      actualPickupTime: map['actual_pickup_time'] != null
          ? DateTime.parse(map['actual_pickup_time'] as String)
          : null,
      actualReturnTime: map['actual_return_time'] != null
          ? DateTime.parse(map['actual_return_time'] as String)
          : null,
      status: status,
      pricing: pricing,
      depositStatus: depositStatus,
      startingOdometer: (map['starting_odometer'] as num?)?.toInt(),
      endingOdometer: (map['ending_odometer'] as num?)?.toInt(),
      cancellationReason: map['cancellation_reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
