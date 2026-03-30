import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/centered_header_bar.dart';

class WithdrawSummaryScreen extends StatefulWidget {
  const WithdrawSummaryScreen({
    super.key,
    required this.amount,
    required this.method,
  });

  final String amount;
  final String method;

  @override
  State<WithdrawSummaryScreen> createState() => _WithdrawSummaryScreenState();
}

class _WithdrawSummaryScreenState extends State<WithdrawSummaryScreen> {
  late String _selectedMethod = widget.method;

  @override
  Widget build(BuildContext context) {
    final amountValue = double.tryParse(widget.amount.replaceAll(',', '')) ?? 5000;
    final chargePercent = 10;
    final total = amountValue * 0.9;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              const CenteredHeaderBar(
                title: 'Withdraw Balance',
                titleSpacing: 0.42,
              ),
              const SizedBox(height: 35),
              const _WithdrawProfileHeader(),
              const SizedBox(height: 34),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Withdraw Detail',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.54,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _WithdrawDetailCard(
                amount: amountValue,
                chargePercent: chargePercent,
                total: total,
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Text(
                    'Withdraw Method',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.54,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showChangeMethodSheet,
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
              _SelectedWithdrawMethodTile(method: _selectedMethod),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.withdrawSuccess),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Withdraw',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.48,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeMethodSheet() {
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
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6E6A99),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Change Method',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _WalletMethodCard(
                            title: '•••••••• 1222',
                            balance: '\$ 31,250',
                            trailing: 'MC',
                            selected: _selectedMethod == 'mastercard',
                            gradient: const [Color(0xFFE7B904), Color(0xFF937702)],
                            onTap: () => setModalState(() => _selectedMethod = 'mastercard'),
                          ),
                          const SizedBox(width: 10),
                          _WalletMethodCard(
                            title: '•••••••• 1542',
                            balance: '\$ 54,200',
                            trailing: 'VISA',
                            selected: _selectedMethod == 'visa',
                            gradient: const [Color(0xFF234F68), Color(0xFF234F68)],
                            onTap: () => setModalState(() => _selectedMethod = 'visa'),
                          ),
                          const SizedBox(width: 10),
                          _WalletMethodCard(
                            title: '••••••an@\nemail.com',
                            balance: '\$ 12,290',
                            trailing: 'PP',
                            selected: _selectedMethod == 'paypal',
                            gradient: const [Color(0xFFE7B904), Color(0xFF6B601F)],
                            onTap: () => setModalState(() => _selectedMethod = 'paypal'),
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
                          minimumSize: const Size.fromHeight(70),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Select Method',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

class _WithdrawProfileHeader extends StatelessWidget {
  const _WithdrawProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: AppColors.greySoft1,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            'M',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mathew Adam',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.42,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'mathew@email.com',
              style: GoogleFonts.lato(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.greyMedium,
                decoration: TextDecoration.underline,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WithdrawDetailCard extends StatelessWidget {
  const _WithdrawDetailCard({
    required this.amount,
    required this.chargePercent,
    required this.total,
  });

  final double amount;
  final int chargePercent;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greySoft2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 31),
            child: Column(
              children: [
                _WithdrawLine(label: 'Amount', value: '\$${_formatNumber(amount)}'),
                const SizedBox(height: 10),
                _WithdrawLine(label: 'Withdraw Charge', value: '$chargePercent%'),
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
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${_formatNumber(total)}',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }
}

class _WithdrawLine extends StatelessWidget {
  const _WithdrawLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.greyMedium,
            letterSpacing: 0.36,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.greyMedium,
            letterSpacing: 0.36,
          ),
        ),
      ],
    );
  }
}

class _SelectedWithdrawMethodTile extends StatelessWidget {
  const _SelectedWithdrawMethodTile({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final label = switch (method) {
      'mastercard' => '•••••• 1222',
      'visa' => '•••••• 1542',
      _ => '••••••an@email.com',
    };
    final icon = switch (method) {
      'mastercard' => 'MC',
      'visa' => 'VISA',
      _ => 'PP',
    };

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greySoft2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Text(
            icon,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: method == 'paypal' ? AppColors.primaryBackground : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 15),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.greyMedium,
              letterSpacing: 0.36,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletMethodCard extends StatelessWidget {
  const _WalletMethodCard({
    required this.title,
    required this.balance,
    required this.trailing,
    required this.selected,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String balance;
  final String trailing;
  final bool selected;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 159,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 25,
              height: 25,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 16, color: AppColors.primaryBackground)
                  : null,
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.54,
                height: 1.05,
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
    );
  }
}
