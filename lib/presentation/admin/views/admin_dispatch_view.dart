import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/booking.dart';
import '../../common/providers/repository_providers.dart';
import '../../customer/my_bookings/my_bookings_screen.dart';

final allBookingsFutureProvider = FutureProvider<List<Booking>>((ref) {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getUserBookings('usr_demo_customer_01');
});

class AdminDispatchView extends ConsumerStatefulWidget {
  const AdminDispatchView({super.key});

  @override
  ConsumerState<AdminDispatchView> createState() => _AdminDispatchViewState();
}

class _AdminDispatchViewState extends ConsumerState<AdminDispatchView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  bool _helmetIssued = true;
  bool _keyHandedOver = true;
  bool _preTripInspectionDone = true;
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _handlePickup(Booking booking) async {
    final odo = int.tryParse(_odometerController.text.trim()) ?? 4210;

    setState(() => _isProcessing = true);
    try {
      await ref.read(bookingRepositoryProvider).recordPickup(booking.id, odo);
      ref.invalidate(allBookingsFutureProvider);
      ref.invalidate(userBookingsFutureProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle dispatched! Trip started for ${booking.bookingNumber}.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dispatch failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(allBookingsFutureProvider);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Hub Dispatch & Customer Check-in Desk',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scan customer QR / search booking number, verify Driving License, and dispatch vehicle.',
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Search Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by Booking Number (e.g. VR-BLR-8921) or Customer Mobile...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan QR'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera QR code scanner active')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Ready for Dispatch Section
          const Text(
            'Reservations Ready for Vehicle Handover',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),

          bookingsAsync.when(
            data: (bookings) {
              final readyBookings = bookings.where((b) => b.status == BookingStatus.confirmed).toList();

              if (readyBookings.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.done_all_rounded, size: 48, color: AppColors.success),
                        SizedBox(height: 12),
                        Text('No pending vehicle handovers at this hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('All reserved bikes are dispatched or returned.', style: TextStyle(color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: readyBookings.map((booking) {
                  _odometerController.text = '${booking.startingOdometer ?? 4210}';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.lightBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(booking.bookingNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('Reserved: ${dateFormat.format(booking.startTime)}', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Ready for Handover',
                                  style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 24),

                          // Customer & Security Verification Row
                          Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 18),
                              const SizedBox(width: 8),
                              const Text('Customer DL: KA-01-2022-0049210 (Verified)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const Spacer(),
                              Text('Deposit Held: ${CurrencyFormatter.format(booking.pricing.securityDeposit)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Checklist & Odometer
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.lightSurfaceCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.lightBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pre-Handover Verification Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  title: const Text('ISI Approved Helmet Handed Over to Rider', style: TextStyle(fontSize: 13)),
                                  value: _helmetIssued,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) => setState(() => _helmetIssued = val ?? false),
                                ),
                                CheckboxListTile(
                                  title: const Text('Vehicle Physical Key & Smart Card Issued', style: TextStyle(fontSize: 13)),
                                  value: _keyHandedOver,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) => setState(() => _keyHandedOver = val ?? false),
                                ),
                                CheckboxListTile(
                                  title: const Text('Pre-trip 360° Scratch & Dent Inspection Completed', style: TextStyle(fontSize: 13)),
                                  value: _preTripInspectionDone,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) => setState(() => _preTripInspectionDone = val ?? false),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Text('Starting Odometer (km):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 120,
                                      child: TextField(
                                        controller: _odometerController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Action Dispatch Button
                          ElevatedButton.icon(
                            icon: const Icon(Icons.key_rounded, size: 18),
                            label: _isProcessing
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                                : const Text('Complete Handover & Start Customer Trip'),
                            onPressed: _isProcessing ? null : () => _handlePickup(booking),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}
