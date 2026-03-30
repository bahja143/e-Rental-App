import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/repositories/account_setup_repository.dart';

class PaymentSetupScreen extends StatefulWidget {
  const PaymentSetupScreen({super.key});

  @override
  State<PaymentSetupScreen> createState() => _PaymentSetupScreenState();
}

class _PaymentSetupScreenState extends State<PaymentSetupScreen> {
  int _selectedPayment = 0;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AccountSetupRepository().getCurrentUserInfo();
    if (!mounted || user == null) return;
    _nameController.text = '${user['name'] ?? ''}';
    _emailController.text = '${user['email'] ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              SizedBox(
                height: 50,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: _TopCircleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.pop(),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.go(AppRoutes.home),
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.greySoft1,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'skip',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF3A3F67),
                                letterSpacing: 0.36,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.lato(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.6,
                      letterSpacing: 0.75,
                    ),
                    children: const [
                      TextSpan(text: 'Add your\n'),
                      TextSpan(
                        text: 'payment method',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'You can edit this later on your account setting.',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.greyMedium,
                    letterSpacing: 0.42,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _PaymentPreviewCard(
                name: _nameController.text.trim().isEmpty ? 'Olivia Johns' : _nameController.text.trim(),
                paymentIndex: _selectedPayment,
                cardSuffix: _cardController.text.trim().isEmpty ? '1234' : _last4(_cardController.text),
              ),
              const SizedBox(height: 26),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _PaymentOptionChip(
                      label: 'Paypal',
                      leading: const Text('P', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF016FD0))),
                      selected: _selectedPayment == 0,
                      onTap: () => setState(() => _selectedPayment = 0),
                    ),
                    const SizedBox(width: 10),
                    _PaymentOptionChip(
                      label: 'Mastercard',
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircleAvatar(radius: 6, backgroundColor: Color(0xFFEA001B)),
                          SizedBox(width: 2),
                          CircleAvatar(radius: 6, backgroundColor: Color(0xFFF79E1B)),
                        ],
                      ),
                      selected: _selectedPayment == 1,
                      onTap: () => setState(() => _selectedPayment = 1),
                    ),
                    const SizedBox(width: 10),
                    _PaymentOptionChip(
                      label: 'Visa',
                      leading: Text(
                        'VISA',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1A1F71),
                        ),
                      ),
                      selected: _selectedPayment == 2,
                      onTap: () => setState(() => _selectedPayment = 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _selectedPayment == 0 ? _buildPaypalForm() : _buildCardForm(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 100,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4E8D4D), Color(0xFFE0C9FF)],
                  ),
                ),
              ),
              const SizedBox(height: 11),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(63),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _saving ? 'Saving...' : 'Next',
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
      ),
    );
  }

  List<Widget> _buildPaypalForm() {
    return [
      _PaymentInputField(
        controller: _nameController,
        hintText: 'Jonathan',
        icon: Icons.person_outline_rounded,
      ),
      const SizedBox(height: 15),
      _PaymentInputField(
        controller: _emailController,
        hintText: 'jonathan@email.com',
        icon: Icons.mail_outline_rounded,
        keyboardType: TextInputType.emailAddress,
      ),
    ];
  }

  List<Widget> _buildCardForm() {
    return [
      _PaymentInputField(
        controller: _nameController,
        hintText: 'Jonathan Anderson',
        icon: Icons.person_outline_rounded,
      ),
      const SizedBox(height: 15),
      _PaymentInputField(
        controller: _cardController,
        hintText: '1222 3443 9881 1222',
        icon: Icons.credit_card_outlined,
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 15),
      Row(
        children: [
          Expanded(
            child: _PaymentInputField(
              controller: _expiryController,
              hintText: '11/05/2023',
              icon: Icons.calendar_today_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PaymentInputField(
              controller: _cvcController,
              hintText: 'CVV',
              icon: Icons.account_balance_wallet_outlined,
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _onComplete() async {
    final method = _selectedPayment == 0
        ? 'paypal'
        : _selectedPayment == 1
            ? 'card'
            : 'visa';
    if (_nameController.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the account holder name.')),
      );
      return;
    }
    if (method == 'paypal' && _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the PayPal email.')),
      );
      return;
    }
    if (method != 'paypal' &&
        (_cardController.text.trim().isEmpty || _expiryController.text.trim().isEmpty || _cvcController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete card details.')),
      );
      return;
    }

    setState(() => _saving = true);
    final ok = await AccountSetupRepository().savePayment(
      method: method,
      holderName: _nameController.text.trim(),
      email: _emailController.text.trim(),
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

  String _last4(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) return '1234';
    return digits.substring(digits.length - 4);
  }
}

class _TopCircleButton extends StatelessWidget {
  const _TopCircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: AppColors.greySoft1,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _PaymentPreviewCard extends StatelessWidget {
  const _PaymentPreviewCard({
    required this.name,
    required this.paymentIndex,
    required this.cardSuffix,
  });

  final String name;
  final int paymentIndex;
  final String cardSuffix;

  @override
  Widget build(BuildContext context) {
    final gradient = paymentIndex == 0
        ? const [Color(0xFF4B9AD7), Color(0xFFE7B904)]
        : paymentIndex == 1
            ? const [Color(0xFF4B9AD7), Color(0xFFE7B904)]
            : const [Color(0xFF577E96), Color(0xFF234F68)];

    return Container(
      height: 186,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5C349),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.fingerprint, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Icon(Icons.wifi_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                _MiniPayBadge(label: 'Pay'),
                const SizedBox(width: 8),
                _MiniPayBadge(label: 'G Pay'),
              ],
            ),
            const Spacer(),
            Text(
              '**** **** **** $cardSuffix',
              style: GoogleFonts.robotoMono(
                fontSize: 24,
                color: Colors.white,
                shadows: const [Shadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2))],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'VALID\nTHRU',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '01/22',
                  style: GoogleFonts.robotoMono(
                    fontSize: 18,
                    color: Colors.white,
                    shadows: const [Shadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                ),
                const Spacer(),
                Row(
                  children: const [
                    CircleAvatar(radius: 10, backgroundColor: Colors.white70),
                    SizedBox(width: 2),
                    CircleAvatar(radius: 10, backgroundColor: Colors.white38),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                shadows: const [Shadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2))],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPayBadge extends StatelessWidget {
  const _MiniPayBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _PaymentOptionChip extends StatelessWidget {
  const _PaymentOptionChip({
    required this.label,
    required this.leading,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBackground : AppColors.greySoft1,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : AppColors.greyMedium,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentInputField extends StatelessWidget {
  const _PaymentInputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.36,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.greyBarelyMedium,
            letterSpacing: 0.36,
          ),
          suffixIcon: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
