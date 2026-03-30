class TransactionHistoryItem {
  const TransactionHistoryItem({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.amount,
    required this.isIncome,
    this.hasDispute = false,
  });

  final String id;
  final String title;
  final String dateLabel;
  final double amount;
  final bool isIncome;
  final bool hasDispute;
}
