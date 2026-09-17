import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/booking.dart';
import '../../common/providers/repository_providers.dart';

final userBookingsFutureProvider = FutureProvider<List<Booking>>((ref) {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getUserBookings('usr_demo_customer');
});

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('No bookings yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Find a ride and reserve your bike today', style: TextStyle(color: AppColors.textSecondaryLight)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userBookingsFutureProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _BookingCard(booking: booking);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, s) => Center(child: Text('Error loading bookings: $err')),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return AppColors.info;
      case BookingStatus.active:
        return AppColors.success;
      case BookingStatus.completed:
        return AppColors.primary;
      case BookingStatus.cancelled:
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Confirmed / Ready for Pickup';
      case BookingStatus.active:
        return 'Trip in Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.bookingNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(booking.status),
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 8),
                Text(
                  '${dateFormat.format(booking.startTime)} → ${dateFormat.format(booking.endTime)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Paid: ${CurrencyFormatter.format(booking.pricing.totalPayable)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'Deposit: ${booking.depositStatus.name.toUpperCase()}',
                  style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            // Action Buttons for Pickup / Return Simulation
            if (booking.status == BookingStatus.confirmed) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Record Hub Pickup (Start Trip)'),
                onPressed: () async {
                  await ref.read(bookingRepositoryProvider).recordPickup(booking.id, 5000);
                  ref.invalidate(userBookingsFutureProvider);
                },
              ),
            ],
            if (booking.status == BookingStatus.active) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Return Bike to Hub (End Trip)'),
                onPressed: () async {
                  await ref.read(bookingRepositoryProvider).recordReturn(booking.id, 5045, booking.returnStationId);
                  ref.invalidate(userBookingsFutureProvider);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
