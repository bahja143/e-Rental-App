import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/centered_header_bar.dart';

class WithdrawBalanceScreen extends StatefulWidget {
  const WithdrawBalanceScreen({super.key});

  @override
  State<WithdrawBalanceScreen> createState() => _WithdrawBalanceScreenState();
}

class _WithdrawBalanceScreenState extends State<WithdrawBalanceScreen> {
  final _amountController = TextEditingController(text: '5000');
  String _selectedMethod = 'paypal';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            const CenteredHeaderBar(
              title: 'Withdraw Balance',
              titleSpacing: 0.42,
            ),
            const SizedBox(height: 35),
            const _WithdrawProfileHeader(),
            const SizedBox(height: 34),
            Center(
              child: Container(
                width: 164,
                height: 92,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.greySoft2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '\$50,000',
                      style: GoogleFonts.lato(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Available Balance',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.greyMedium,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 35),
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.greySoft1,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Amount',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.36,
                      ),
                    ),
                  ),
                  Container(
                    width: 117,
                    height: 27,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFDFD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _amountController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: 0.36,
                      ),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'Withdraw Method',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.54,
              ),
            ),
            const SizedBox(height: 20),
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
                    gradient: const [Color(0xFFE7B904), Color(0xFF4D805B)],
                    onTap: () => setState(() => _selectedMethod = 'mastercard'),
                  ),
                  const SizedBox(width: 10),
                  _WalletMethodCard(
                    title: '•••••••• 1542',
                    balance: '\$ 54,200',
                    trailing: 'VISA',
                    selected: _selectedMethod == 'visa',
                    gradient: const [Color(0xFF597A8D), Color(0xFF25516A)],
                    onTap: () => setState(() => _selectedMethod = 'visa'),
                  ),
                  const SizedBox(width: 10),
                  _WalletMethodCard(
                    title: '••••••an@\nemail.com',
                    balance: '\$ 12,290',
                    trailing: 'PP',
                    selected: _selectedMethod == 'paypal',
                    gradient: const [Color(0xFF1F4C6B), Color(0xFFE7B904)],
                    onTap: () => setState(() => _selectedMethod = 'paypal'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 56),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = _amountController.text.trim();
                        context.push(AppRoutes.withdrawSummaryRoute(amount: amount, method: _selectedMethod));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Next',
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
              ],
            ),
          ],
        ),
      ),
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
