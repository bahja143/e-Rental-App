import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/centered_header_bar.dart';
import '../data/models/transaction_history_item.dart';
import '../data/repositories/transaction_repository.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<TransactionHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = TransactionRepository().getTransactionHistory();
  }

  void _reload() {
    setState(() {
      _historyFuture = TransactionRepository().getTransactionHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<TransactionHistoryItem>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final items = snapshot.data ?? const <TransactionHistoryItem>[];
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  _HistoryHeader(onRefresh: _reload),
                  const SizedBox(height: 37),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 36,
                        color: Color(0xFFF1F1F3),
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _HistoryTile(
                          item: item,
                          onTap: () => context.push(
                            item.hasDispute
                                ? AppRoutes.transactionDisputeRoute(item.id)
                                : AppRoutes.transactionDetailRoute(item.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return CenteredHeaderBar(
      title: 'Transaction History',
      trailing: HeaderCircleButton(
        icon: Icons.history_toggle_off_rounded,
        onTap: onRefresh,
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.onTap,
  });

  final TransactionHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = item.isIncome ? const Color(0xFF7BCB2A) : const Color(0xFFEF5DA8);
    final amountPrefix = item.isIncome ? '\$' : '- \$';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.greySoft1,
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(
              item.isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.dateLabel,
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFA2A2A7),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$amountPrefix${_formatAmount(item.amount)}',
            style: GoogleFonts.raleway(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E1E2D),
              height: 1,
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

