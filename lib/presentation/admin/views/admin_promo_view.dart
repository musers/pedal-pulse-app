import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../domain/entities/promo_code.dart';
import '../../common/providers/repository_providers.dart';

final adminPromosFutureProvider = FutureProvider<List<PromoCode>>((ref) {
  final repo = ref.watch(promoRepositoryProvider);
  return repo.getAllPromos();
});

class AdminPromoView extends ConsumerStatefulWidget {
  const AdminPromoView({super.key});

  @override
  ConsumerState<AdminPromoView> createState() => _AdminPromoViewState();
}

class _AdminPromoViewState extends ConsumerState<AdminPromoView> {
  @override
  Widget build(BuildContext context) {
    final promosAsync = ref.watch(adminPromosFutureProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      body: promosAsync.when(
        data: (promos) {
          final totalCount = promos.length;
          final activeCount = promos.where((p) => p.isCurrentlyValid).length;
          final totalRedemptions = promos.fold<int>(0, (sum, p) => sum + p.usedCount);
          final expiringSoonCount = promos.where((p) =>
            p.isCurrentlyValid && p.validUntil.difference(DateTime.now()).inDays <= 14
          ).length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminPromosFutureProvider),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Title and "Create Coupon" Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dynamic Promo & Coupon Engine',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage time-bound discounts, percentage caps, and usage limits across Bengaluru.',
                            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Create New Coupon'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showCreatePromoDialog(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Metric Stat Cards Row
                  Row(
                    children: [
                      _StatCard(
                        title: 'Total Coupons',
                        value: '$totalCount',
                        icon: Icons.confirmation_number_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 14),
                      _StatCard(
                        title: 'Active & Valid',
                        value: '$activeCount',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 14),
                      _StatCard(
                        title: 'Total Redemptions',
                        value: '$totalRedemptions',
                        icon: Icons.loyalty_outlined,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 14),
                      _StatCard(
                        title: 'Expiring (<14 Days)',
                        value: '$expiringSoonCount',
                        icon: Icons.timer_outlined,
                        color: AppColors.warning,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Configured Coupon Codes & Campaigns',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (promos.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No coupon codes configured yet. Tap "Create New Coupon" to start.'),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: promos.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final promo = promos[index];
                        return _PromoItemCard(
                          promo: promo,
                          onToggleActive: (val) async {
                            await ref.read(promoRepositoryProvider).togglePromoStatus(promo.id, val);
                            ref.invalidate(adminPromosFutureProvider);
                          },
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Coupon Code?'),
                                content: Text('Are you sure you want to permanently delete coupon "${promo.code}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref.read(promoRepositoryProvider).deletePromo(promo.id);
                              ref.invalidate(adminPromosFutureProvider);
                            }
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, s) => Center(child: Text('Error loading promo codes: $err')),
      ),
    );
  }

  void _showCreatePromoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CreatePromoDialog(
        onCreated: () => ref.invalidate(adminPromosFutureProvider),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoItemCard extends StatelessWidget {
  final PromoCode promo;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;

  const _PromoItemCard({
    required this.promo,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isExpired = promo.isExpired;
    final isExhausted = promo.isUsageExhausted;

    Color statusColor = AppColors.success;
    String statusLabel = 'ACTIVE';

    if (!promo.isActive) {
      statusColor = AppColors.textSecondaryLight;
      statusLabel = 'DISABLED';
    } else if (isExpired) {
      statusColor = AppColors.error;
      statusLabel = 'EXPIRED';
    } else if (isExhausted) {
      statusColor = AppColors.warning;
      statusLabel = 'LIMIT REACHED';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: promo.isActive && !isExpired ? AppColors.brandGradient : null,
              color: !promo.isActive || isExpired ? AppColors.lightSurfaceCard : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: promo.isActive && !isExpired ? AppColors.primaryLight : AppColors.lightBorder,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  promo.code,
                  style: TextStyle(
                    color: promo.isActive && !isExpired ? Colors.white : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  promo.discountType == DiscountType.percentage
                      ? '${promo.discountValue.toInt()}% OFF'
                      : '₹${promo.discountValue.toInt()} FLAT',
                  style: TextStyle(
                    color: promo.isActive && !isExpired ? AppColors.secondaryLight : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      promo.description,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lightSurfaceCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        promo.applicableType.name.toUpperCase(),
                        style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          'Valid: ${dateFormat.format(promo.validFrom)} → ${dateFormat.format(promo.validUntil)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isExpired ? AppColors.error : AppColors.textSecondaryLight,
                            fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          'Min Order: ${CurrencyFormatter.format(promo.minOrderAmount)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                    if (promo.maxDiscountAmount != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.vertical_align_top_rounded, size: 14, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            'Max Cap: ${CurrencyFormatter.format(promo.maxDiscountAmount!)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Usage Progress Bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: promo.usageLimit > 0 ? (promo.usedCount / promo.usageLimit).clamp(0.0, 1.0) : 0.05,
                          minHeight: 6,
                          backgroundColor: AppColors.lightBorder,
                          color: isExhausted ? AppColors.warning : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      promo.usageLimit > 0
                          ? '${promo.usedCount} / ${promo.usageLimit} redeemed'
                          : '${promo.usedCount} redeemed (Unlimited)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Actions: Active Switch & Delete Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: promo.isActive,
                activeThumbColor: AppColors.primary,
                onChanged: onToggleActive,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                tooltip: 'Delete Coupon',
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreatePromoDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const _CreatePromoDialog({required this.onCreated});

  @override
  State<_CreatePromoDialog> createState() => _CreatePromoDialogState();
}

class _CreatePromoDialogState extends State<_CreatePromoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minOrderController = TextEditingController(text: '0');
  final _maxCapController = TextEditingController();
  final _usageLimitController = TextEditingController(text: '100');

  DiscountType _discountType = DiscountType.percentage;
  PromoApplicableType _applicableType = PromoApplicableType.all;
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    _descController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    _maxCapController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.discount_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Text('Create Time-Bound Coupon Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coupon Code Input (Auto-Uppercase)
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Coupon Code *',
                    hintText: 'e.g. MONSOON30, DIWALI50',
                    prefixIcon: Icon(Icons.vpn_key_rounded, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Coupon code is required';
                    if (val.trim().length < 3) return 'Code must be at least 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Campaign Description *',
                    hintText: 'e.g. 20% off for daily Bengaluru office commuters',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Description is required';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Discount Type Selector (Percentage vs Flat)
                Row(
                  children: [
                    const Text('Discount Type:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Percentage (%)'),
                      selected: _discountType == DiscountType.percentage,
                      onSelected: (_) => setState(() => _discountType = DiscountType.percentage),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Flat INR (₹)'),
                      selected: _discountType == DiscountType.flat,
                      onSelected: (_) => setState(() => _discountType = DiscountType.flat),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Discount Value & Max Cap Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _discountValueController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _discountType == DiscountType.percentage ? 'Discount % *' : 'Flat Discount (₹) *',
                          hintText: _discountType == DiscountType.percentage ? '20' : '150',
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null || double.parse(val) <= 0) {
                            return 'Enter valid value';
                          }
                          if (_discountType == DiscountType.percentage && double.parse(val) > 100) {
                            return 'Max 100%';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_discountType == DiscountType.percentage) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _maxCapController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max Discount Cap (₹)',
                            hintText: 'e.g. 250 (optional)',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Minimum Order Value & Usage Limit Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minOrderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min Order Amount (₹)',
                          hintText: '0 for no minimum',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _usageLimitController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Usage Limit',
                          hintText: '0 for unlimited',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Applicable Type Dropdown
                DropdownButtonFormField<PromoApplicableType>(
                  initialValue: _applicableType,
                  decoration: const InputDecoration(
                    labelText: 'Applicable To',
                  ),
                  items: const [
                    DropdownMenuItem(value: PromoApplicableType.all, child: Text('All Bookings & Subscriptions')),
                    DropdownMenuItem(value: PromoApplicableType.rental, child: Text('Hourly / Daily Rentals Only')),
                    DropdownMenuItem(value: PromoApplicableType.subscription, child: Text('Weekly / Monthly Subscriptions Only')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _applicableType = val);
                  },
                ),
                const SizedBox(height: 16),

                // Time-Bound Validity Date Range Pickers
                const Text(
                  'Time-Bound Validity Window *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text('From: ${dateFormat.format(_validFrom)}', style: const TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _validFrom,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _validFrom = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event_busy_rounded, size: 16, color: AppColors.secondary),
                        label: Text('Until: ${dateFormat.format(_validUntil)}', style: const TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _validUntil,
                            firstDate: _validFrom,
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _validUntil = picked.add(const Duration(hours: 23, minutes: 59)));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitCoupon,
          child: _isSubmitting
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Publish Coupon Code'),
        ),
      ],
    );
  }

  Future<void> _submitCoupon() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ProviderScope.containerOf(context).read(promoRepositoryProvider);
      final newPromo = PromoCode(
        id: '',
        code: _codeController.text.trim().toUpperCase(),
        description: _descController.text.trim(),
        discountType: _discountType,
        discountValue: double.parse(_discountValueController.text.trim()),
        minOrderAmount: double.tryParse(_minOrderController.text.trim()) ?? 0.0,
        maxDiscountAmount: double.tryParse(_maxCapController.text.trim()),
        validFrom: _validFrom,
        validUntil: _validUntil,
        usageLimit: int.tryParse(_usageLimitController.text.trim()) ?? 0,
        applicableType: _applicableType,
        isActive: true,
      );

      await repo.createPromo(newPromo);
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create coupon: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
