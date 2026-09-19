import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/booking.dart';
import '../../common/providers/repository_providers.dart';
import '../../customer/my_bookings/my_bookings_screen.dart';
import 'admin_dispatch_view.dart';

class AdminReturnView extends ConsumerStatefulWidget {
  const AdminReturnView({super.key});

  @override
  ConsumerState<AdminReturnView> createState() => _AdminReturnViewState();
}

class _AdminReturnViewState extends ConsumerState<AdminReturnView> {
  final TextEditingController _endingOdometerController = TextEditingController();
  bool _helmetReturned = true;
  bool _keyReturned = true;
  bool _noNewDamages = true;
  bool _isProcessing = false;

  @override
  void dispose() {
    _endingOdometerController.dispose();
    super.dispose();
  }

  Future<void> _handleReturn(Booking booking) async {
    final startOdo = booking.startingOdometer ?? 4210;
    final endOdo = int.tryParse(_endingOdometerController.text.trim()) ?? (startOdo + 35);

    setState(() => _isProcessing = true);
    try {
      await ref.read(bookingRepositoryProvider).recordReturn(booking.id, endOdo, booking.returnStationId);
      ref.invalidate(allBookingsFutureProvider);
      ref.invalidate(userBookingsFutureProvider);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                SizedBox(width: 8),
                Text('Vehicle Returned & Trip Closed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking ID: ${booking.bookingNumber}'),
                const SizedBox(height: 6),
                Text('Total Distance Traveled: ${endOdo - startOdo} km'),
                const SizedBox(height: 6),
                Text('Security Deposit: ${CurrencyFormatter.format(booking.pricing.securityDeposit)} refunded to customer source account.'),
                const SizedBox(height: 10),
                const Text(
                  'Tax Invoice & Rental Receipt dispatched via Email (Resend).',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Return processing failed: $e'),
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
            'Vehicle Return & Inspection Desk',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 4),
          const Text(
            'Inspect returned vehicle, verify odometer readings, checklist intake, and initiate security deposit release.',
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Active Trips in Progress
          bookingsAsync.when(
            data: (bookings) {
              final activeTrips = bookings.where((b) => b.status == BookingStatus.active).toList();

              if (activeTrips.isEmpty) {
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
                        Icon(Icons.park_rounded, size: 48, color: AppColors.primaryLight),
                        SizedBox(height: 12),
                        Text('No active on-road trips pending return', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('All customer rentals are completed or at confirmed status.', style: TextStyle(color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: activeTrips.map((booking) {
                  final startOdo = booking.startingOdometer ?? 4210;
                  if (_endingOdometerController.text.isEmpty) {
                    _endingOdometerController.text = '${startOdo + 45}';
                  }

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
                                      color: AppColors.success.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.two_wheeler_rounded, color: AppColors.success, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(booking.bookingNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('Trip Started: ${booking.actualPickupTime != null ? dateFormat.format(booking.actualPickupTime!) : "In Progress"}', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Trip in Progress',
                                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 24),

                          // Intake Form
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
                                const Text('Vehicle Return Inspection Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  title: const Text('Helmet Returned in Clean Condition', style: TextStyle(fontSize: 13)),
                                  value: _helmetReturned,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) => setState(() => _helmetReturned = val ?? false),
                                ),
                                CheckboxListTile(
                                  title: const Text('Physical Key & Smart Card Returned', style: TextStyle(fontSize: 13)),
                                  value: _keyReturned,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) => setState(() => _keyReturned = val ?? false),
                                ),
                                CheckboxListTile(
                                  title: const Text('Zero Structural / Body Damages Reported', style: TextStyle(fontSize: 13)),
                                  value: _noNewDamages,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) => setState(() => _noNewDamages = val ?? false),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text('Start Odo: $startOdo km', style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                                    const SizedBox(width: 24),
                                    const Text('Ending Odometer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 100,
                                      child: TextField(
                                        controller: _endingOdometerController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('km', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Deposit Refund & Complete Action
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: _isProcessing
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                                : Text('Accept Return & Release Deposit (${CurrencyFormatter.format(booking.pricing.securityDeposit)})'),
                            onPressed: _isProcessing ? null : () => _handleReturn(booking),
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
