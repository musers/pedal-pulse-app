import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../common/providers/auth_state_provider.dart';

enum AuthStep {
  phoneInput,
  otpVerification,
  profileSetup,
}

class AuthModal extends ConsumerStatefulWidget {
  final String? redirectTitle;
  final VoidCallback? onSuccess;

  const AuthModal({
    super.key,
    this.redirectTitle,
    this.onSuccess,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? redirectTitle,
    VoidCallback? onSuccess,
  }) {
    if (ResponsiveLayout.isDesktop(context)) {
      return showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AuthModal(redirectTitle: redirectTitle, onSuccess: onSuccess),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.lightSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: AuthModal(redirectTitle: redirectTitle, onSuccess: onSuccess),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends ConsumerState<AuthModal> {
  AuthStep _step = AuthStep.phoneInput;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  int _resendTimerSeconds = 30;
  Timer? _resendTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendTimerSeconds = 30);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimerSeconds > 0) {
        setState(() => _resendTimerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedPhone {
    final raw = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (raw.startsWith('91') && raw.length == 12) {
      return '+$raw';
    }
    return '+91$raw';
  }

  Future<void> _handleSendOtp() async {
    final raw = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (raw.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).sendOtp(_formattedPhone);
      _startResendTimer();
      setState(() {
        _step = AuthStep.otpVerification;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ref.read(authControllerProvider.notifier).verifyOtp(
            _formattedPhone,
            otp,
          );

      if (user.fullName.isEmpty || user.fullName == 'New Customer') {
        setState(() {
          _step = AuthStep.profileSetup;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          widget.onSuccess?.call();
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleSaveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            fullName: name,
            email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          );

      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.electric_bolt_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppConstants.appName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        widget.redirectTitle ?? 'Quick Phone Login',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondaryLight),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Error Banner if present
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Step 1: Phone Number Input
          if (_step == AuthStep.phoneInput) ...[
            const Text(
              'Enter your Indian Mobile Number',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'We will send a 6-digit OTP for instant verification.',
              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🇮🇳', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 6),
                      Text('+91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: const InputDecoration(
                      hintText: '98765 00000',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                    onSubmitted: (_) => _handleSendOtp(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            // Demo hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.info),
                  SizedBox(width: 6),
                  Text(
                    'Demo test login: Use 9876500000 (OTP: 123456)',
                    style: TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOtp,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Get OTP via SMS'),
            ),
          ],

          // Step 2: OTP Verification
          if (_step == AuthStep.otpVerification) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Verify 6-Digit OTP',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                TextButton(
                  onPressed: () => setState(() => _step = AuthStep.phoneInput),
                  child: const Text('Change Number', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            Text(
              'Sent to $_formattedPhone',
              style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                hintText: '123456',
                prefixIcon: Icon(Icons.lock_clock_outlined, size: 20),
              ),
              onSubmitted: (_) => _handleVerifyOtp(),
            ),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_resendTimerSeconds > 0)
                  Text(
                    'Resend OTP in ${_resendTimerSeconds}s',
                    style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                  )
                else
                  TextButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Resend OTP'),
                    onPressed: _handleSendOtp,
                  ),
                Text(
                  'Test OTP: 123456',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleVerifyOtp,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Verify & Proceed'),
            ),
          ],

          // Step 3: First-time Profile Setup
          if (_step == AuthStep.profileSetup) ...[
            const Text(
              'Welcome to VeloRide!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            const Text(
              'Please tell us your name to set up your rental account.',
              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                hintText: 'e.g. Ramesh Kumar',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address (for invoices & receipts)',
                hintText: 'e.g. ramesh@gmail.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSaveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Complete Setup'),
            ),
          ],
        ],
      ),
    );
  }
}
