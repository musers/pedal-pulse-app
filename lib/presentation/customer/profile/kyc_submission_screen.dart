import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user_profile.dart';
import '../../common/providers/auth_state_provider.dart';

class KycSubmissionScreen extends ConsumerStatefulWidget {
  const KycSubmissionScreen({super.key});

  @override
  ConsumerState<KycSubmissionScreen> createState() => _KycSubmissionScreenState();
}

class _KycSubmissionScreenState extends ConsumerState<KycSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dlNumberController = TextEditingController();
  bool _isSubmitting = false;
  bool _docUploaded = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value;
    if (user?.drivingLicenseNumber != null) {
      _dlNumberController.text = user!.drivingLicenseNumber!;
      _docUploaded = true;
    }
  }

  @override
  void dispose() {
    _dlNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitKyc() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_docUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a photo of your Indian Driving License front side.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cleanDl = _dlNumberController.text.trim().toUpperCase();
      await ref.read(authControllerProvider.notifier).updateProfile(
            drivingLicenseNumber: cleanDl,
            drivingLicenseDocUrl: 'https://storage.veloride.in/kyc/dl_${cleanDl.replaceAll(' ', '_')}.jpg',
            kycStatus: KycStatus.verified, // Instant auto-verification for demo MVP
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driving License verified successfully! You are ready to ride.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final isVerified = user?.isKycVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driving License Verification (KYC)', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isVerified
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isVerified ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                          color: isVerified ? AppColors.success : AppColors.secondary,
                          size: 36,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isVerified ? 'KYC Status: Verified' : 'KYC Status: Verification Required',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isVerified ? AppColors.success : AppColors.secondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isVerified
                                    ? 'Your driving license is approved. You can reserve any vehicle immediately.'
                                    : 'Indian Motor Vehicle Act requires a valid Two-Wheeler Driving License before rental dispatch.',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Guidelines Info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Requirements for Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('• Valid Indian Driving License with MCWG (Motor Cycle with Gear) or MCWOG approval.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                        SizedBox(height: 4),
                        Text('• Clear front photo showing DL Number, Date of Birth, and Expiry date.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // DL Number Field
                  const Text('Driving License (DL) Number *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dlNumberController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'e.g. KA01 20220049210 or DL-0420110012345',
                      prefixIcon: Icon(Icons.credit_card_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your driving license number';
                      }
                      if (val.trim().length < 8) {
                        return 'DL Number must be at least 8 characters long';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // DL Document Upload Section
                  const Text('Upload Driving License Photo (Front Side) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setState(() => _docUploaded = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Driving license document attached successfully!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _docUploaded
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : AppColors.lightSurfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _docUploaded ? AppColors.primary : AppColors.lightBorder,
                          width: _docUploaded ? 2 : 1,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _docUploaded ? Icons.task_alt_rounded : Icons.cloud_upload_outlined,
                            size: 40,
                            color: _docUploaded ? AppColors.primary : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _docUploaded ? 'DL Document Uploaded (Tap to replace)' : 'Tap to browse or take photo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _docUploaded ? AppColors.primary : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'JPEG, PNG or PDF (Max 5MB)',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmitKyc,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isVerified ? 'Update Driving License' : 'Submit & Verify KYC'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
