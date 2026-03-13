import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/models/booking_summary.dart';
import '../data/repositories/transaction_repository.dart';

class TransactionSummaryScreen extends StatefulWidget {
  const TransactionSummaryScreen({super.key, this.estateId});

  final String? estateId;

  @override
  State<TransactionSummaryScreen> createState() => _TransactionSummaryScreenState();
}

class _TransactionSummaryScreenState extends State<TransactionSummaryScreen> {
  late final Future<BookingSummary> _summaryFuture;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = TransactionRepository().getBookingSummary(estateId: widget.estateId);
  }

  Future<void> _confirmBooking() async {
    setState(() => _submitting = true);
    final ok = await TransactionRepository().confirmBooking(estateId: widget.estateId);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      context.push(AppRoutes.transactionSuccess);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not confirm booking. Please try again.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<BookingSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final summary = snapshot.data ??
              const BookingSummary(
                propertyTitle: 'Modern Apartment',
                location: 'Mogadishu',
                price: 190,
                duration: '1 month',
                serviceFee: 19,
                paymentLast4: '4242',
              );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.propertyTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.greyBarelyMedium),
                          const SizedBox(width: 4),
                          Text(summary.location, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      _SummaryRow(label: 'Rent', value: '\$${summary.price.toInt()} ${AppStrings.perMonth}'),
                      _SummaryRow(label: 'Duration', value: summary.duration),
                      _SummaryRow(label: 'Service fee', value: '\$${summary.serviceFee.toInt()}'),
                      const Divider(),
                      _SummaryRow(
                        label: 'Total',
                        value: '\$${summary.total.toInt()}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Payment method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.greySoft1,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, color: AppColors.primary),
                      const SizedBox(width: 16),
                      Expanded(child: Text('•••• ${summary.paymentLast4}')),
                      TextButton(onPressed: () {}, child: Text('Change', style: Theme.of(context).textTheme.labelLarge)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                AppButton(
                  label: _submitting ? 'Confirming...' : 'Confirm Booking',
                  onPressed: _submitting ? null : _confirmBooking,
                  width: double.infinity,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.isBold = false});

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
