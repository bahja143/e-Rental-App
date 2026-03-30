import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/remote_image.dart';
import '../data/models/transaction_detail_data.dart';
import '../data/repositories/transaction_repository.dart';

class DisputeDetailScreen extends StatefulWidget {
  const DisputeDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  late Future<TransactionDetailData> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = TransactionRepository().getTransactionDetail(widget.transactionId);
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

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load dispute',
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
                          _detailFuture = TransactionRepository().getTransactionDetail(widget.transactionId);
                        });
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    children: [
                      _DisputeHeader(onBack: () => context.pop()),
                      const SizedBox(height: 20),
                      _ListingCard(data: data),
                      const SizedBox(height: 35),
                      _ParticipantCard(
                        title: 'Seller Information',
                        name: data.sellerName,
                        avatarUrl: data.sellerAvatarUrl,
                        detail: _SellerMeta(
                          rating: data.sellerRating,
                          soldCount: data.sellerSoldCount,
                        ),
                        onChat: () => context.push(
                          AppRoutes.chatDetail('seller-${data.id}', name: data.sellerName),
                        ),
                      ),
                      const SizedBox(height: 35),
                      _ParticipantCard(
                        title: 'Buyer Information',
                        name: data.buyerName,
                        avatarUrl: data.buyerAvatarUrl,
                        detail: _BuyerMeta(location: data.buyerLocation),
                        onChat: () => context.push(
                          AppRoutes.chatDetail('buyer-${data.id}', name: data.buyerName),
                        ),
                      ),
                      const SizedBox(height: 35),
                      const _SectionTitle('Transaction Detail'),
                      const SizedBox(height: 24),
                      _InfoCard(
                        rows: [
                          _InfoRow(label: 'Check in', value: data.checkInLabel),
                          _InfoRow(label: 'Check out', value: data.checkOutLabel),
                          _InfoRow(label: 'Owner name', value: data.ownerName),
                          _InfoRow(label: 'Transaction type', value: data.transactionType),
                        ],
                      ),
                      const SizedBox(height: 35),
                      const _SectionTitle('Payment Detail'),
                      const SizedBox(height: 24),
                      _PaymentDetailCard(data: data),
                      const SizedBox(height: 35),
                      const _SectionTitle('Payment Method'),
                      const SizedBox(height: 20),
                      _PaymentMethodCard(label: data.paymentLabel),
                      const SizedBox(height: 35),
                      const _SectionTitle('What issue are you experiencing?'),
                      const SizedBox(height: 20),
                      _IssueRow(label: data.selectedIssue),
                      const SizedBox(height: 35),
                      const _SectionTitle('Describe the Issue'),
                      const SizedBox(height: 18),
                      Text(
                        data.disputeDescription,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                          letterSpacing: 0.48,
                          height: 1.375,
                        ),
                      ),
                      const SizedBox(height: 35),
                      const _SectionTitle('Upload Evidence'),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _EvidenceTile(
                              url: data.evidenceUrls.isNotEmpty ? data.evidenceUrls[0] : '',
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _EvidenceTile(
                              url: data.evidenceUrls.length > 1 ? data.evidenceUrls[1] : '',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
                _BottomActionBar(
                  onRefund: () => _showPendingAction('Refund Buyer'),
                  onClose: () => _showPendingAction('Close Dispute'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showPendingAction(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is not connected to a backend endpoint yet.')),
    );
  }
}

class _DisputeHeader extends StatelessWidget {
  const _DisputeHeader({required this.onBack});

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
                        : RemoteImage(
                            url: data.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: Container(color: const Color(0xFFE0E4EF)),
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
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: AppColors.primaryBackground.withValues(alpha: 0.69),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                      child: Text(
                        data.category,
                        style: GoogleFonts.lato(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: AppColors.greySoft1,
                          letterSpacing: 0.24,
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
                padding: const EdgeInsets.only(top: 8, right: 9, bottom: 8),
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
                        letterSpacing: 0.36,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 10, color: Color(0xFFFA712D)),
                        const SizedBox(width: 2),
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
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Disputed',
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                            letterSpacing: 0.3,
                          ),
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

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.title,
    required this.name,
    required this.avatarUrl,
    required this.detail,
    required this.onChat,
  });

  final String title;
  final String name;
  final String avatarUrl;
  final Widget detail;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.fromLTRB(32, 12, 15, 13),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.54,
            ),
          ),
          const SizedBox(height: 23),
          Row(
            children: [
              _Avatar(name: name, avatarUrl: avatarUrl),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.42,
                      ),
                    ),
                    const SizedBox(height: 10),
                    detail,
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onChat,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Start Chat',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.42,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.avatarUrl});

  final String name;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child: avatarUrl.isEmpty
            ? Container(
                color: const Color(0xFFDCE3F1),
                alignment: Alignment.center,
                child: Text(
                  name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              )
            : RemoteImage(
                url: avatarUrl,
                fit: BoxFit.cover,
                errorWidget: Container(color: const Color(0xFFDCE3F1)),
              ),
      ),
    );
  }
}

class _SellerMeta extends StatelessWidget {
  const _SellerMeta({
    required this.rating,
    required this.soldCount,
  });

  final double rating;
  final int soldCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 10, color: Color(0xFFE7B904)),
            const SizedBox(width: 2),
            Text(
              rating.toStringAsFixed(rating.truncateToDouble() == rating ? 0 : 1),
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.greyMedium,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        Row(
          children: [
            const Icon(Icons.home_rounded, size: 10, color: AppColors.greyMedium),
            const SizedBox(width: 2),
            Text(
              '$soldCount',
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.greyMedium,
                height: 1,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              'Sold',
              style: GoogleFonts.raleway(
                fontSize: 8,
                fontWeight: FontWeight.w400,
                color: AppColors.greyMedium,
                height: 1.25,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BuyerMeta extends StatelessWidget {
  const _BuyerMeta({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on, size: 10, color: Color(0xFFFA712D)),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 8,
              fontWeight: FontWeight.w400,
              color: AppColors.greyMedium,
              height: 1.25,
            ),
          ),
        ),
      ],
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

class _InfoRow {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.greySoft2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Row(
              children: [
                Text(
                  rows[i].label,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.greyMedium,
                    letterSpacing: 0.36,
                  ),
                ),
                const Spacer(),
                Text(
                  rows[i].value,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyMedium,
                    letterSpacing: 0.36,
                  ),
                ),
              ],
            ),
            if (i != rows.length - 1) const SizedBox(height: 15),
          ],
        ],
      ),
    );
  }
}

class _PaymentDetailCard extends StatelessWidget {
  const _PaymentDetailCard({required this.data});

  final TransactionDetailData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 23, 15, 23),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.greySoft2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              _PaymentRow(label: 'Period time', value: data.periodLabel),
              const SizedBox(height: 15),
              _PaymentRow(label: 'Monthly payment', value: '\$ ${_formatMoney(data.monthlyPayment)}'),
              const SizedBox(height: 15),
              _PaymentRow(label: 'Discount', value: '-\$ ${_formatMoney(data.discount)}'),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: const BoxDecoration(
            color: AppColors.greySoft1,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
          child: Row(
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
              const Spacer(),
              Text(
                '\$ ${_formatMoney(data.total)}',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatMoney(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
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

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.greySoft2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Text(
            'P',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0070BA),
            ),
          ),
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

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0x33E7B904),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
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
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 161,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greySoft1, width: 3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: url.isEmpty
            ? Container(color: const Color(0xFFE0E4EF))
            : RemoteImage(
                url: url,
                fit: BoxFit.cover,
                errorWidget: Container(color: const Color(0xFFE0E4EF)),
              ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onRefund,
    required this.onClose,
  });

  final VoidCallback onRefund;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom > 0 ? bottom : 24),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Refund Buyer',
              backgroundColor: AppColors.primary,
              onTap: onRefund,
            ),
          ),
          const SizedBox(width: 21),
          Expanded(
            child: _ActionButton(
              label: 'Close Dispute',
              backgroundColor: const Color(0xFF8BC83F),
              onTap: onClose,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.48,
          ),
        ),
      ),
    );
  }
}
