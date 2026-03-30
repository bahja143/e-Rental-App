import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/centered_header_bar.dart';
import '../../../shared/widgets/remote_image.dart';
import '../data/models/booking_summary.dart';
import '../data/repositories/transaction_repository.dart';

class TransactionSummaryScreen extends StatefulWidget {
  const TransactionSummaryScreen({super.key, this.estateId});

  final String? estateId;

  @override
  State<TransactionSummaryScreen> createState() => _TransactionSummaryScreenState();
}

class _TransactionSummaryScreenState extends State<TransactionSummaryScreen> {
  late Future<BookingSummary> _summaryFuture;
  late final TextEditingController _checkInController;
  late final TextEditingController _checkOutController;
  late final TextEditingController _noteController;

  bool _submitting = false;
  _VoucherData? _selectedVoucher;
  final List<_VoucherData> _availableVouchers = const <_VoucherData>[];

  @override
  void initState() {
    super.initState();
    _summaryFuture = TransactionRepository().getBookingSummary(estateId: widget.estateId);
    final now = DateTime.now();
    final checkIn = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final checkOut = checkIn.add(const Duration(days: 60));
    _checkInController = TextEditingController(text: _formatDate(checkIn));
    _checkOutController = TextEditingController(text: _formatDate(checkOut));
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _checkInController.dispose();
    _checkOutController.dispose();
    _noteController.dispose();
    super.dispose();
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
      const SnackBar(content: Text('Could not confirm booking.')),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}/${value.year}';
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

          if (snapshot.hasError || !snapshot.hasData) {
            return SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load booking summary',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greyMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _summaryFuture = TransactionRepository().getBookingSummary(estateId: widget.estateId);
                        });
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final summary = snapshot.data!;

          return SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  const CenteredHeaderBar(
                    title: 'Transaction review',
                    titleSpacing: 0.42,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _SummaryListingCard(summary: summary),
                        const SizedBox(height: 35),
                        _SectionTitle(title: 'Period'),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _DateField(
                                controller: _checkInController,
                                hint: 'Check In',
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: _DateField(
                                controller: _checkOutController,
                                hint: 'Check Out',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 35),
                        _SectionTitle(title: 'Note for Owner'),
                        const SizedBox(height: 20),
                        _NoteField(controller: _noteController),
                        const SizedBox(height: 35),
                        _SectionTitle(title: 'Payment Method'),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 180,
                          child: _PaymentOptionCard(
                            title: summary.paymentLabel,
                            balance: '\$ ${summary.total.toStringAsFixed(summary.total == summary.total.roundToDouble() ? 0 : 2)}',
                            selected: true,
                            gradient: const [Color(0xFF618092), Color(0xFF245069)],
                            trailing: '',
                            onTap: () {},
                          ),
                        ),
                        if (_availableVouchers.isNotEmpty) ...[
                          const SizedBox(height: 35),
                          Row(
                            children: [
                              _SectionTitle(title: 'Have a voucher?'),
                              const Spacer(),
                              GestureDetector(
                                onTap: _showVoucherSheet,
                                child: Text(
                                  _selectedVoucher == null ? 'click in here' : 'change voucher',
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
                          if (_selectedVoucher != null) ...[
                            const SizedBox(height: 20),
                            _VoucherCard(voucher: _selectedVoucher!),
                            const SizedBox(height: 24),
                          ],
                          if (_selectedVoucher == null) const SizedBox(height: 24),
                        ] else
                          const SizedBox(height: 24),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: Text(
                              _submitting ? 'Confirming...' : 'Next',
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
          );
        },
      ),
    );
  }

  void _showVoucherSheet() {
    final voucherController = TextEditingController(text: _selectedVoucher?.code ?? '');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 527,
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
                    const SizedBox(height: 34),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add Voucher',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              height: 70,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.greySoft1,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.confirmation_num_outlined, color: AppColors.textPrimary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: voucherController,
                                      style: GoogleFonts.lato(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.36,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Type your voucher',
                                        border: InputBorder.none,
                                        hintStyle: GoogleFonts.lato(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.greyBarelyMedium,
                                          letterSpacing: 0.36,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 35),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Your Available vouchers',
                                style: GoogleFonts.lato(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.54,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            for (final voucher in _availableVouchers) ...[
                              GestureDetector(
                                onTap: () {
                                  voucherController.text = voucher.code;
                                  setModalState(() => _selectedVoucher = voucher);
                                },
                                child: _VoucherSelectionTile(voucher: voucher),
                              ),
                              if (voucher != _availableVouchers.last) const SizedBox(height: 10),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _VoucherData? match;
                          for (final item in _availableVouchers) {
                            if (item.code == voucherController.text.trim()) {
                              match = item;
                              break;
                            }
                          }
                          setState(() => _selectedVoucher = match ?? _selectedVoucher);
                          context.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(70),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Apply Voucher',
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
    ).whenComplete(() => voucherController.dispose());
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.54,
      ),
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
        borderRadius: BorderRadius.circular(25),
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
                        : RemoteImage(
                            url: summary.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: Container(color: const Color(0xFFDCE3F1)),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      summary.category,
                      style: GoogleFonts.lato(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.24,
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
                      fontWeight: FontWeight.w700,
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.36,
              ),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.greyBarelyMedium,
                  letterSpacing: 0.36,
                ),
              ),
            ),
          ),
          const Icon(Icons.calendar_month_outlined, color: AppColors.textPrimary, size: 20),
        ],
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.36,
              ),
              decoration: InputDecoration(
                hintText: 'Write your note in here',
                border: InputBorder.none,
                hintStyle: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.greyBarelyMedium,
                  letterSpacing: 0.36,
                ),
              ),
            ),
          ),
          const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textPrimary, size: 20),
        ],
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.title,
    required this.balance,
    required this.selected,
    required this.gradient,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String balance;
  final bool selected;
  final List<Color> gradient;
  final String trailing;
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
                  ? const Icon(Icons.check_rounded, size: 14, color: AppColors.primaryBackground)
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

class _VoucherSelectionTile extends StatelessWidget {
  const _VoucherSelectionTile({required this.voucher});

  final _VoucherData voucher;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.confirmation_num_outlined, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                voucher.code,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.54,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Click to use this voucher',
                style: GoogleFonts.lato(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: AppColors.greyMedium,
                  letterSpacing: 0.27,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({required this.voucher});

  final _VoucherData voucher;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBackground.withValues(alpha: 0.1),
            const Color(0xFFEEF6E8),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 53,
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(17),
            ),
            alignment: Alignment.center,
            child: Text(
              voucher.code,
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.54,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher.title,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.36,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  voucher.subtitle,
                  style: GoogleFonts.lato(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: AppColors.greyMedium,
                    letterSpacing: 0.27,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherData {
  const _VoucherData({
    required this.code,
    required this.title,
    required this.subtitle,
  });

  final String code;
  final String title;
  final String subtitle;
}
