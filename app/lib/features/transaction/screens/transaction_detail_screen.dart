import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/transaction_detail_data.dart';
import '../data/repositories/transaction_repository.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Future<TransactionDetailData> _detailFuture;
  String? _selectedIssue;
  final _issueController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _detailFuture = TransactionRepository().getTransactionDetail(widget.transactionId);
  }

  @override
  void dispose() {
    _issueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<TransactionDetailData>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final data = snapshot.data ?? TransactionDetailData.fallback(widget.transactionId);
            _selectedIssue ??= data.issueOptions.first;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    children: [
                      _DetailHeader(onBack: () => context.pop()),
                      const SizedBox(height: 20),
                      _ListingCard(data: data),
                      const SizedBox(height: 16),
                      _SellerCard(data: data),
                      const SizedBox(height: 20),
                      _SectionTitle('Transaction Detail'),
                      const SizedBox(height: 20),
                      _InfoCard(
                        rows: [
                          _InfoRowData(label: 'Check in', value: data.checkInLabel),
                          _InfoRowData(label: 'Check out', value: data.checkOutLabel),
                          _InfoRowData(label: 'Owner name', value: data.ownerName),
                          _InfoRowData(label: 'Transaction type', value: data.transactionType),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle('Payment Detail'),
                      const SizedBox(height: 20),
                      _PaymentDetailCard(data: data),
                      const SizedBox(height: 20),
                      _SectionTitle('Payment Method'),
                      const SizedBox(height: 20),
                      _PaymentMethodCard(label: data.paymentLabel),
                      const SizedBox(height: 30),
                      _SectionTitle('What issue are you experiencing?'),
                      const SizedBox(height: 18),
                      ...data.issueOptions.map(
                        (issue) => _IssueOption(
                          label: issue,
                          selected: _selectedIssue == issue,
                          onTap: () => setState(() => _selectedIssue = issue),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _InputBox(
                        controller: _issueController,
                        hint: 'Write Here',
                        maxLines: 1,
                      ),
                      const SizedBox(height: 30),
                      _SectionTitle('Describe the Issue'),
                      const SizedBox(height: 18),
                      _InputBox(
                        controller: _descriptionController,
                        hint: 'Write your experience in here (optional)',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 30),
                      _SectionTitle('Upload Evidence'),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: _EvidenceTile(url: data.imageUrl)),
                          const SizedBox(width: 9),
                          const Expanded(child: _EvidenceTile(url: '')),
                        ],
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
                if (data.canAddReview)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.submitReviewRoute(data.listingId)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Add Review',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.48,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Transaction Detail',
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
                onTap: onBack,
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
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.data});

  final TransactionDetailData data;

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
                    child: data.imageUrl.isEmpty
                        ? Container(color: const Color(0xFFE0E4EF))
                        : Image.network(
                            data.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE0E4EF)),
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
                          data.category,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.propertyTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 10, color: Color(0xFFFA712D)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data.location,
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
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        data.statusLabel,
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(data.statusAccentValue),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.data});

  final TransactionDetailData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seller Information',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.54,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                backgroundImage: data.sellerAvatarUrl.isNotEmpty ? NetworkImage(data.sellerAvatarUrl) : null,
                child: data.sellerAvatarUrl.isEmpty
                    ? Text(
                        data.sellerName.isEmpty ? 'A' : data.sellerName[0].toUpperCase(),
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.sellerName,
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.42,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 12, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          data.sellerRating.toStringAsFixed(0),
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greyMedium,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.home_rounded, size: 12, color: AppColors.greyMedium),
                        const SizedBox(width: 3),
                        Text(
                          '${data.sellerSoldCount} Sold',
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0.54,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.greySoft2),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      row.label,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.greyMedium,
                      ),
                    ),
                    Text(
                      row.value,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PaymentDetailCard extends StatelessWidget {
  const _PaymentDetailCard({required this.data});

  final TransactionDetailData data;

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
                _PaymentRow(label: 'Period time', value: data.periodLabel),
                const SizedBox(height: 15),
                _PaymentRow(label: 'Monthly payment', value: '\$ ${_formatAmount(data.monthlyPayment)}'),
                const SizedBox(height: 15),
                _PaymentRow(label: 'Discount', value: '- \$${_formatAmount(data.discount)}'),
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
                  '\$ ${_formatAmount(data.total)}',
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

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
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

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.greySoft2),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFF016FD0)),
          const SizedBox(width: 15),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: AppColors.greyMedium,
              letterSpacing: 0.36,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueOption extends StatelessWidget {
  const _IssueOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : const Color(0xFFD9D9D9),
                shape: BoxShape.circle,
              ),
              child: selected
                  ? const Center(
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  letterSpacing: 0.48,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.controller,
    required this.hint,
    required this.maxLines,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        minLines: maxLines,
        maxLines: maxLines,
        style: GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.5,
          letterSpacing: 0.36,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
          border: InputBorder.none,
          prefixIcon: maxLines > 1
              ? const Padding(
                  padding: EdgeInsets.only(left: 16, right: 10, bottom: 68),
                  child: Icon(Icons.message_outlined, size: 20, color: AppColors.greyMedium),
                )
              : const Padding(
                  padding: EdgeInsets.only(left: 16, right: 10),
                  child: Icon(Icons.message_outlined, size: 20, color: AppColors.greyMedium),
                ),
          prefixIconConstraints: const BoxConstraints(minHeight: 20, minWidth: 20),
          hintText: hint,
          hintStyle: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.greyBarelyMedium,
            letterSpacing: 0.36,
          ),
        ),
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 159 / 161,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greySoft1, width: 3),
                borderRadius: BorderRadius.circular(25),
              ),
              child: url.isEmpty
                  ? Container(color: const Color(0xFFE8ECF5))
                  : Image.network(
                      url,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE8ECF5)),
                    ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.primaryBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRowData {
  const _InfoRowData({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
