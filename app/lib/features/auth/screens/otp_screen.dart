import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/repositories/auth_repository.dart';
import '../../../shared/widgets/app_button.dart';

/// Register / Form - OTP verification
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.email = 'jonathan@email.com'});

  final String email;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController(text: '2');
  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildBackButton(context),
              const SizedBox(height: 50),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 25,
                        color: AppColors.textPrimary,
                      ),
                  children: const [
                    TextSpan(text: 'Enter the '),
                    TextSpan(
                      text: 'code',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Enter the 4 digit code that we just sent to',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.greyMedium),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 56),
              _buildOtpField(),
              const SizedBox(height: 60),
              Center(
                child: AppButton(
                  label: _loading ? 'Verifying...' : 'Verify',
                  isLoading: _loading,
                  onPressed: _loading ? null : _verify,
                ),
              ),
              const Spacer(),
              Center(child: _buildTimerPill()),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _resending ? null : _resendOtp,
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.greyMedium),
                      children: [
                        const TextSpan(text: 'Didn’t receive the OTP? '),
                        TextSpan(
                          text: _resending ? 'Resending...' : 'Resend OTP',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 72),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildOtpField() {
    return Row(
      children: [
        _OtpBox(value: _otpController.text, selected: true),
        const SizedBox(width: 10),
        const _OtpBox(),
        const SizedBox(width: 10),
        const _OtpBox(),
        const SizedBox(width: 10),
        const _OtpBox(),
      ],
    );
  }

  Widget _buildTimerPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(
            '00.21',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;
    setState(() => _loading = true);
    final ok = await AuthRepository().verifyOtp(
      email: widget.email,
      otp: otp,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      context.go(AppRoutes.accountSetupUser);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _resending = true);
    final ok = await AuthRepository().resendOtp(widget.email);
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'OTP resent.' : 'Could not resend OTP.')),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({this.value = '', this.selected = false});

  final String value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74.25,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(10),
        border: selected ? Border.all(color: AppColors.textSecondary, width: 1.6) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontSize: 28,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
