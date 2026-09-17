import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/booking.dart';
import '../../common/providers/repository_providers.dart';
import '../bike_details/bike_details_screen.dart';
import '../explore/explore_screen.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String bikeId;

  const BookingScreen({super.key, required this.bikeId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _selectedHours = 4;
  String? _pickupStationId;
  String? _returnStationId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final bikeAsync = ref.watch(bikeDetailsFutureProvider(widget.bikeId));
    final stationsAsync = ref.watch(stationsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Rental', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: bikeAsync.when(
        data: (bike) {
          if (bike == null) return const Center(child: Text('Bike not found'));

          _pickupStationId ??= bike.currentStationId;
          _returnStationId ??= bike.currentStationId;

          // Pricing calculation (Server-authoritative matching formula)
          final double rentalFare = _selectedHours >= 24
              ? (_selectedHours / 24).ceil() * bike.dailyRate
              : _selectedHours * bike.hourlyRate;
          final double gstAmount = (rentalFare * 0.18);
          final double totalPayable = rentalFare + gstAmount + bike.securityDeposit;

          final pricing = PricingBreakdown(
            rentalFare: rentalFare,
            gstAmount: gstAmount,
            securityDeposit: bike.securityDeposit,
            totalPayable: totalPayable,
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bike Summary Mini Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightSurfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                bike.imageUrl,
                                width: 70,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 70,
                                  height: 50,
                                  color: AppColors.primaryLight,
                                  child: const Icon(Icons.two_wheeler, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(bike.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text('${bike.brand} • ${bike.model}', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text('Select Rental Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [4, 8, 12, 24, 48].map((hours) {
                          final isSelected = _selectedHours == hours;
                          final label = hours >= 24 ? '${hours ~/ 24} Day(s)' : '$hours Hours';
                          return ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedHours = hours;
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Station Pickers
                      const Text('Pickup & Drop Hubs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      stationsAsync.when(
                        data: (stations) => Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _pickupStationId,
                              decoration: const InputDecoration(
                                labelText: 'Pickup Hub',
                                prefixIcon: Icon(Icons.trip_origin_rounded, color: AppColors.primary),
                              ),
                              items: stations.map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text('${s.name} (${s.city})'),
                              )).toList(),
                              onChanged: (val) {
                                setState(() => _pickupStationId = val);
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _returnStationId,
                              decoration: const InputDecoration(
                                labelText: 'Return Hub',
                                prefixIcon: Icon(Icons.pin_drop_rounded, color: AppColors.secondary),
                              ),
                              items: stations.map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text('${s.name} (${s.city})'),
                              )).toList(),
                              onChanged: (val) {
                                setState(() => _returnStationId = val);
                              },
                            ),
                          ],
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => const SizedBox(),
                      ),

                      const SizedBox(height: 24),

                      // Price Breakdown
                      const Text('Fare Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.lightSurfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(
                          children: [
                            _FareRow(label: 'Rental Fare ($_selectedHours hrs)', amount: rentalFare),
                            const SizedBox(height: 8),
                            _FareRow(label: 'GST (18% Govt. Tax)', amount: gstAmount),
                            const SizedBox(height: 8),
                            _FareRow(
                              label: 'Refundable Security Deposit',
                              amount: bike.securityDeposit,
                              isHighlighted: true,
                              subtitle: 'Refunded on safe return',
                            ),
                            const Divider(height: 24),
                            _FareRow(
                              label: 'Total Payable Now',
                              amount: totalPayable,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Confirmation Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.lightSurface,
                  border: Border(top: BorderSide(color: AppColors.lightBorder)),
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () async {
                      setState(() => _isSubmitting = true);
                      try {
                        final bookingRepo = ref.read(bookingRepositoryProvider);
                        final now = DateTime.now();
                        final booking = await bookingRepo.createBooking(
                          customerId: 'usr_demo_customer',
                          bikeId: bike.id,
                          pickupStationId: _pickupStationId ?? bike.currentStationId,
                          returnStationId: _returnStationId ?? bike.currentStationId,
                          startTime: now.add(const Duration(minutes: 30)),
                          endTime: now.add(Duration(hours: _selectedHours, minutes: 30)),
                          pricing: pricing,
                        );

                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AppColors.success),
                                  SizedBox(width: 8),
                                  Text('Booking Confirmed!'),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Booking ID: ${booking.bookingNumber}'),
                                  const SizedBox(height: 8),
                                  Text('Bike: ${bike.name} (${bike.registrationNumber})'),
                                  const SizedBox(height: 8),
                                  Text('Total: ${CurrencyFormatter.format(totalPayable)}'),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Your reservation is active. Please proceed to the hub for pickup.',
                                    style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                                  ),
                                ],
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    context.go('/my-bookings');
                                  },
                                  child: const Text('View My Bookings'),
                                ),
                              ],
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                    },
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Confirm Booking • ${CurrencyFormatter.format(totalPayable)}'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, s) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;
  final bool isHighlighted;
  final String? subtitle;

  const _FareRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
    this.isHighlighted = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : (isHighlighted ? FontWeight.w600 : FontWeight.normal),
                fontSize: isTotal ? 16 : 14,
                color: isTotal ? AppColors.textPrimaryLight : (isHighlighted ? AppColors.primary : AppColors.textSecondaryLight),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 11, color: AppColors.success),
              ),
          ],
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 18 : 14,
            color: isTotal ? AppColors.primary : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
