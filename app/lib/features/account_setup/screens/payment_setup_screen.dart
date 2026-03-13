import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/repositories/account_setup_repository.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/setup_scaffold.dart';

/// Account Setup / Payment - Add payment method
class PaymentSetupScreen extends StatefulWidget {
  const PaymentSetupScreen({super.key});

  @override
  State<PaymentSetupScreen> createState() => _PaymentSetupScreenState();
}

class _PaymentSetupScreenState extends State<PaymentSetupScreen> {
  int _selectedPayment = 0; // 0=PayPal, 1=Card, 2=Visa
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      title: 'Add payment method',
      description: 'You can update this later in settings.',
      progress: 1.0,
      showSkip: true,
      onNext: _saving ? null : _onComplete,
      nextLabel: _saving ? 'Saving...' : 'Complete',
      child: Column(
        children: [
          _buildPaymentOptions(),
          const SizedBox(height: 24),
          if (_selectedPayment == 1) ...[
            AppTextField(
              controller: _cardController,
              hintText: 'Card number',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.credit_card, size: 20, color: AppColors.greyBarelyMedium),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _expiryController,
                    hintText: 'MM/YY',
                    prefixIcon: const Icon(Icons.calendar_today, size: 20, color: AppColors.greyBarelyMedium),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: AppTextField(
                    controller: _cvcController,
                    hintText: 'CVC',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock, size: 20, color: AppColors.greyBarelyMedium),
                  ),
                ),
              ],
            ),
          ] else if (_selectedPayment == 0) ...[
            Container(
              height: 70,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greySoft1,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                  const SizedBox(width: 16),
                  Text(
                    'Connect PayPal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _onComplete() async {
    final method = _selectedPayment == 0
        ? 'paypal'
        : _selectedPayment == 1
            ? 'card'
            : 'visa';
    if (method == 'card' && (_cardController.text.trim().isEmpty || _expiryController.text.trim().isEmpty || _cvcController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete card details.')),
      );
      return;
    }

    setState(() => _saving = true);
    final ok = await AccountSetupRepository().savePayment(
      method: method,
      cardNumber: _cardController.text.trim(),
      expiry: _expiryController.text.trim(),
      cvc: _cvcController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      context.go(AppRoutes.home);
    }
  }

  Widget _buildPaymentOptions() {
    return Row(
      children: [
        _PaymentChip(
          label: 'PayPal',
          isSelected: _selectedPayment == 0,
          onTap: () => setState(() => _selectedPayment = 0),
        ),
        const SizedBox(width: 10),
        _PaymentChip(
          label: 'Card',
          isSelected: _selectedPayment == 1,
          onTap: () => setState(() => _selectedPayment = 1),
        ),
        const SizedBox(width: 10),
        _PaymentChip(
          label: 'Visa',
          isSelected: _selectedPayment == 2,
          onTap: () => setState(() => _selectedPayment = 2),
        ),
      ],
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.greySoft1,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}
