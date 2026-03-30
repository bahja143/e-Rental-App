class TransactionDetailData {
  const TransactionDetailData({
    required this.id,
    required this.listingId,
    required this.propertyTitle,
    required this.location,
    required this.category,
    required this.imageUrl,
    required this.statusLabel,
    required this.statusAccentValue,
    required this.sellerName,
    required this.sellerAvatarUrl,
    required this.sellerLocation,
    required this.sellerRating,
    required this.sellerSoldCount,
    required this.buyerName,
    required this.buyerAvatarUrl,
    required this.buyerLocation,
    required this.checkInLabel,
    required this.checkOutLabel,
    required this.ownerName,
    required this.transactionType,
    required this.periodLabel,
    required this.monthlyPayment,
    required this.discount,
    required this.total,
    required this.paymentLabel,
    required this.issueOptions,
    required this.selectedIssue,
    required this.disputeDescription,
    required this.evidenceUrls,
    required this.hasDispute,
    required this.canAddReview,
  });

  final String id;
  final String listingId;
  final String propertyTitle;
  final String location;
  final String category;
  final String imageUrl;
  final String statusLabel;
  final int statusAccentValue;
  final String sellerName;
  final String sellerAvatarUrl;
  final String sellerLocation;
  final double sellerRating;
  final int sellerSoldCount;
  final String buyerName;
  final String buyerAvatarUrl;
  final String buyerLocation;
  final String checkInLabel;
  final String checkOutLabel;
  final String ownerName;
  final String transactionType;
  final double monthlyPayment;
  final double discount;
  final double total;
  final String periodLabel;
  final String paymentLabel;
  final List<String> issueOptions;
  final String selectedIssue;
  final String disputeDescription;
  final List<String> evidenceUrls;
  final bool hasDispute;
  final bool canAddReview;
}
