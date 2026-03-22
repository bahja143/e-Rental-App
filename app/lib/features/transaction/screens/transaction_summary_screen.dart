import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
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
  int _selectedPayment = 0;

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
      backgroundColor: Colors.white,
      body: FutureBuilder<BookingSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final summary = snapshot.data ??
              const BookingSummary(
                propertyTitle: 'Sky Dandelions Apartment',
                location: 'Jakarta, Indonesia',
                category: 'Apartment',
                imageUrl: '',
                price: 220,
                duration: '2 month',
                discount: 88,
                total: 31250,
                paymentLabel: '••••••an@email.com',
              );
          return SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'Transaction summary',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => context.pop(),
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: AppColors.greySoft1,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _SummaryListingCard(summary: summary),
                        const SizedBox(height: 35),
                        Text(
                          'Payment Detail',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.54,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SummaryPaymentDetailCard(summary: summary),
                        const SizedBox(height: 35),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment Method',
                              style: GoogleFonts.lato(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.54,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showChangePaymentSheet(context),
                              child: Text(
                                'change',
                                style: GoogleFonts.lato(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBackground,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: AppColors.greySoft2),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedPayment == 0 ? Icons.account_balance_wallet_outlined : Icons.credit_card_rounded,
                                color: _selectedPayment == 0 ? const Color(0xFF016FD0) : AppColors.textPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 15),
                              Text(
                                _selectedPayment == 0 ? summary.paymentLabel : '•••• 1542',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.greyMedium,
                                  letterSpacing: 0.36,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _confirmBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _submitting ? 'Confirming...' : 'Confirm Booking',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.48,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(27),
                        elevation: 8,
                        shadowColor: AppColors.primary.withValues(alpha: 0.35),
                        child: InkWell(
                          onTap: _submitting ? null : _confirmBooking,
                          borderRadius: BorderRadius.circular(27),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.textPrimary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangePaymentSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 427,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 27, 24, 24),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6E6A99),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 31),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Change Payment',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 31),
                    SizedBox(
                      height: 180,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _PaymentOptionCard(
                            title: '•••••••• 1222',
                            balance: '\$ 31,250',
                            selected: _selectedPayment == 1,
                            color: AppColors.primary,
                            trailing: 'MC',
                            onTap: () => setModalState(() => _selectedPayment = 1),
                          ),
                          const SizedBox(width: 10),
                          _PaymentOptionCard(
                            title: '•••••••• 1542',
                            balance: '\$ 54,200',
                            selected: _selectedPayment == 2,
                            color: AppColors.primaryBackground,
                            trailing: 'VISA',
                            onTap: () => setModalState(() => _selectedPayment = 2),
                          ),
                          const SizedBox(width: 10),
                          _PaymentOptionCard(
                            title: '••••••an@email.com',
                            balance: '\$ 12,290',
                            selected: _selectedPayment == 0,
                            color: const Color(0xFF567D94),
                            trailing: 'PP',
                            onTap: () => setModalState(() => _selectedPayment = 0),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          context.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(70),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Select Payment',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.48,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryListingCard extends StatelessWidget {
  const _SummaryListingCard({required this.summary});

  final BookingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 168,
                    height: 140,
                    child: summary.imageUrl.isEmpty
                        ? Container(color: const Color(0xFFDCE3F1))
                        : Image.network(
                            summary.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: const Color(0xFFDCE3F1)),
                          ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border_rounded, size: 14, color: AppColors.textPrimary),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColoredBox(
                      color: const Color(0xB01F4C6B),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Text(
                          summary.category,
                          style: GoogleFonts.raleway(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: 0.24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    summary.propertyTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.5,
                      letterSpacing: 0.36,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 10, color: Color(0xFFFA712D)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          summary.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 8,
                            fontWeight: FontWeight.w400,
                            color: AppColors.greyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'Rent',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPaymentDetailCard extends StatelessWidget {
  const _SummaryPaymentDetailCard({required this.summary});

  final BookingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.greySoft2),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 23, 15, 23),
            child: Column(
              children: [
                _PaymentLine(label: 'Period time', value: summary.duration),
                const SizedBox(height: 15),
                _PaymentLine(label: 'Monthly payment', value: '\$ ${_money(summary.price)}'),
                const SizedBox(height: 15),
                _PaymentLine(label: 'Discount', value: '- \$${_money(summary.discount)}'),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: const BoxDecoration(
              color: AppColors.greySoft1,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.54,
                  ),
                ),
                Text(
                  '\$ ${_money(summary.total)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _money(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }
}

class _PaymentLine extends StatelessWidget {
  const _PaymentLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.greyMedium,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.title,
    required this.balance,
    required this.selected,
    required this.color,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String balance;
  final bool selected;
  final Color color;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 159,
        height: 180,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, size: 14, color: AppColors.primaryBackground)
                    : const SizedBox.shrink(),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.54,
                ),
              ),
              const Spacer(),
              Text(
                'Balance',
                style: GoogleFonts.lato(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.24,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    balance,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.36,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    trailing,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
